# Quest WebSocket Protocol Contract (C0)

Status: **authoritative** for client quest work (C1–C10). The server side is
already shipped + tested (quest_system, 155 tests). The client adopts the
**server's** verbs verbatim. The earlier client-side draft names
(`quest_state`, `quest_offer`, `quest_turnin_result`) are **superseded** — do
not use them.

All quest messages ride the existing WebSocket. Client→server frames carry a
`cmd` field; server→client frames carry `ok` + `cmd` + `data` (the standard
`_send` envelope). Every handler below is `@require_auth` — the client must be
logged in first. Errors come back as `{ok:false, cmd:"error", error:"<code>"}`;
the stable quest error codes are listed at the end.

Source of truth: `WalkAura_server/src/walkaura_server/server.py` (handlers) +
`quest_system/quest_agent.py` (payloads) + `quest_system/quest_event_listener.py`
(push events).

---

## 1. Request/response RPCs (client-initiated)

### `get_quests` — load the player's quests
- **send:** `{cmd:"get_quests"}` (rate limit 1/s)
- **recv:** `{ok:true, cmd:"quests", data:{...}}` where data is:
  ```
  {
    "active":            [<QuestView>, ...],   // full quest+objectives+progress
    "ready_to_turn_in":  [<QuestView>, ...],   // full
    "completed":         [{quest_uid, completed_at, last_completed_at, state_version, repeat_mode}, ...]
  }
  ```
  `completed` is intentionally a lighter shape (no objectives) so payload size
  doesn't grow with chain length.

### `accept_quest`
- **send:** `{cmd:"accept_quest", quest_uid:"<str>"}` (2/s)
- **recv:** `{ok:true, cmd:"quest_accepted", data:{quest:<QuestView>, accepted:<bool>}}`
  `accepted:false` = idempotent (already had it) — not an error; render the quest as-is.

### `turn_in_quest`
- **send:** `{cmd:"turn_in_quest", quest_uid:"<str>"}` (2/s)
- **recv:** `{ok:true, cmd:"quest_turned_in", data:{
    quest_uid, state, state_version,
    completed_at, last_completed_at,
    rewards_granted:[<reward>...], turn_in_mode}}`
  Show the reward modal (C6) from `rewards_granted`.

### `resolve_npc_dialogue` — what an NPC says right now + what it offers
- **send:** `{cmd:"resolve_npc_dialogue", npc_uid:"<str>"}` (5/s)
- **recv:** `{ok:true, cmd:"npc_dialogue", data:{
    npc_uid, line:"<str>", source:"quest_state"|"world_state"|"default",
    offers:[{quest_uid, title, level_requirement, repeat_mode}, ...]}}`
  `offers` = quests this NPC gives that the player can plausibly accept now
  (never-accepted + completed repeatables). It is the **only** way the client
  discovers acceptable quests — `get_quests` returns only already-accepted ones.
  The list is permissive; `accept_quest` is the authoritative gate (it returns
  `prereq_not_met`/`level_too_low`/`cooldown_active` if the player taps an
  offer they can't actually take yet). Render one "Accept" affordance per offer.

### `location_opened` — record a visit (drives `reach_location` objectives)
- **send:** `{cmd:"location_opened", location_uid:"<str>"}` (5/s)
- **recv:** `{ok:true, cmd:"location_opened_ack", data:{ack:true, location_uid}}`

---

## 2. Server push events (unsolicited — register handlers)

### `quest_progress` — an objective advanced / quest became ready
`{ok:true, cmd:"quest_progress", data:{quest_uid, progress:<dict>, state, state_version}}`
Update the matching quest in the local cache + HUD tracker (C5/C8). Use
`state_version` to drop stale/out-of-order pushes (ignore if <= cached version).

### `quest_completed_toast` — an `auto_with_toast` quest auto-completed mid-walk
`{ok:true, cmd:"quest_completed_toast", data:{quest_uid, result:{...turn_in payload...}}}`
Show the completion toast/modal; no `turn_in_quest` call needed for these.

---

## 3. `QuestView` shape (active / ready_to_turn_in entries)

```
{
  quest_uid, chain_id, sort_order, title, description,
  giver_npc_uid, giver_dialogue, turnin_dialogue,
  level_requirement, rewards:[<reward>...],
  repeat_mode, cooldown_seconds, turn_in_mode,
  objectives:[{objective_id, sort_order, objective_type, params, description}, ...],
  state, progress:{<objective_id>:{count, target, met, baseline?}}, state_version,
  accepted_at, last_completed_at
}
```
Progress is keyed by `objective_id` (string). Each objective's bar = `count/target`.

Reward shapes: `{type:"gold",amount}` · `{type:"xp",kind:"account"|"profession",amount,...}` ·
`{type:"item",item_uid,qty}` · `{type:"title",title_id}` · `{type:"world_state_flag",flag}`.

---

## 4. RESOLVED — `location_uid` convention (Option A)

The int-keyed `LOCATIONS` dict and the `loc_*` strings used by NPCs /
`reach_location` are now bridged server-side: the canonical string uid is
**`"loc_" + image_id`** (`locations.location_uid(id)` / `location_id_for_uid(uid)`).
Location 1 → `loc_starter_village` (matches the seeded NPCs).

- **`location_opened`** accepts either `location_uid` (string) OR `location_id`
  (int, mapped server-side). The client sends the **int** `location_id`.
- **`get_location_npcs`** — discover NPCs standing at a location (for markers):
  - **send:** `{cmd:"get_location_npcs", location_id:<int>}` (2/s)
  - **recv:** `{ok:true, cmd:"location_npcs", data:{location_id:<int>, npcs:[{npc_uid, name}, ...]}}`
  - The client renders a tappable marker per NPC; tapping emits
    `signal_RequestNpcDialogue(npc_uid)` → opens the dialogue popup.

`reach_location`/`gather` quest content is now unblocked (author params with the
`loc_*` uid).

---

## 5. Stable quest error codes (from `quest_config.py`)

`unknown_npc`, `unknown_objective`, `unknown_quest`, `prereq_not_met`,
`level_too_low`, `already_accepted`, `cooldown_active`, `wrong_state`,
`reward_grant_failed`, `objective_params_invalid`. Plus generic
`bad_request`, `unauthorized`, and per-handler `*_failed` fallbacks. Map these
to player-facing copy client-side; never display the raw code verbatim except in
debug builds.
