# Full-map activity info tooltip — design

## Context

The full world map (`scenes/support_screens/map_hud.tscn`) shows waypoints the
player can travel to. Hovering a waypoint currently shows a tooltip with the
location **name only**. Players can't tell what activities a location offers, or
whether they personally qualify for them, without travelling there first.

Goal: on waypoint hover, show a brief list of that location's activities, each
marked **available** (player meets the skill requirement) or **locked** (with the
required level).

## Requirements

- Tooltip lists every activity at the hovered location.
- Each activity shows availability state for THIS player: available vs locked.
- Locked rows show the required level.
- No extra network round-trips on hover (data must already be client-side).
- Works on desktop (hover) and mobile (touch).

## Data model

### Source of truth (already exists)
- `ServerParams.LOCATIONS[location_id]["activities"]` — array of activity dicts,
  each with `name`, `profession`, `req_skill` (confirmed at
  `location_hub.gd:223-224`). Sent in `login_params`.
- Server holds all player profession levels in `self.account.professions`
  (`{profession}_lvl` keys), already used for the lock check at
  `gathering_activity.py:57` and `battle_activity.py:69`
  (`prof["level"] < loc.req_skill`).

### Gap + fill
The client does not yet hold a `{profession: level}` map for the map tooltip.
**No server change is needed** — the account-data payload already carries the
full `professions` dict (`client_account.py:403 to_dict()` →
`account_manager.get_account_attrs`, where `d.professions` holds `{name}_lvl`
keys). login_params is pre-auth static data (`self.account` is `None` in
`open()`), so it is the wrong place; the seed point is account ingest.

1. **Client store** — hold `var profession_levels: Dictionary = {}` in
   `ServerParams`, alongside `LOCATIONS`.

2. **Seed on login** — in `account_manager.get_account_attrs` (after the
   profession bulk-set, ~line 317), clear and rebuild
   `ServerParams.profession_levels` from `d.professions`, stripping the `_lvl`
   suffix. Runs on every login (manual or token), so reconnect/auto-login both
   reseed.

3. **Freshness (in-session)** — profession levels rise while playing. The
   activity-progress stream already carries the active profession's new `level`
   (`gathering_activity.py:67`). On each progress tick, patch
   `ServerParams.profession_levels[active_profession] = level`. The active
   profession is the one most likely to change; others only change when played.
   App restart re-seeds from login_params. No extra round-trips.

### Availability rule (client)
Per activity, identical to the server rule:
```gdscript
var lvl = ServerParams.profession_levels.get(act.get("profession", ""), 1)
var available = lvl >= int(act.get("req_skill", 1))
```

## UI — tooltip expansion (`map_hud.gd`)

- Waypoint hover currently calls `_show_tooltip(display_name)`. Change the
  waypoint mouse-enter (and touch-down, see below) to pass the resolved
  `location_id` (via `ItemDB.WAYPOINT_LOCATION_IDS`) so the tooltip can build
  rich content.
- Reuse the existing tooltip `PanelContainer` from `_create_tooltip()`
  (gold-bordered dark panel) — do not create a new overlay. Replace its single
  Label with a VBox:
  - Header Label: location name (existing `_format_waypoint_name` style, gold).
  - One row Label per activity:
    - Available: `✓ {Name}` — bright/gold.
    - Locked: `🔒 {Name} · Lv {req_skill}` — dimmed (grey).
  - If `LOCATIONS[location_id]` has no activities, show only the header (no
    empty list).
- Styling per `WalkAura_client/DESIGN.md` and `styler.gd` (QUADRAT font, gold
  accent `Color(1.0, 0.78, 0.26)`, dim grey for locked). No new colors.
- Tooltip position/clamp logic (`_update_tooltip_pos`) is unchanged; it already
  clamps to the viewport — verify it still fits the taller multi-row panel.

### Touch support
Hover events don't fire reliably on touch. Trigger the tooltip on the waypoint
button's `button_down` (touch/press start) so tap-to-travel still works on
release; hide it when the travel-confirm dialog opens and on `mouse_exit` /
press cancel.

## Files touched (client only — no server change)
- `WalkAura_client/scripts/globals/base_classes/server_params.gd` — declare
  `profession_levels`.
- `WalkAura_client/scripts/globals/account_manager.gd` — seed `profession_levels`
  from `d.professions` in `get_account_attrs`; patch it from activity_progress
  ticks (id→profession via `_PROGRESS_ACTIVITY_PROF`).
- `WalkAura_client/scenes/support_screens/map_hud.gd` — tooltip content build
  (`_populate_tooltip_activities`) + touch (`button_down`) trigger.

GDScript: use `=`, never `:=` (project rule).

## Verification
1. Login, open full map, hover a waypoint with mixed activities → tooltip lists
   each activity, available ones marked `✓`, locked ones `🔒 … · Lv N` matching
   the player's actual profession levels.
2. Level up a profession in-session (gather until level-up), reopen map → that
   activity flips from locked to available without reconnect.
3. Mobile/touch: press-and-hold a waypoint shows the tooltip; releasing still
   opens travel confirm; tooltip hides when the dialog appears.
4. Location with zero activities → tooltip shows name only, no empty rows.
5. No server change, so server tests are unaffected; `cd WalkAura_server &&
   uv run pytest -k auth` stays green as a sanity check.
