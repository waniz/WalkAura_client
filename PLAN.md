# WalkAura Client — Design Implementation Plan

> Source of truth: `WalkAura_client/DESIGN.md` (updated 2026-05-16).
> Visual reference: `WalkAura_client/design-mockups/index.html`.
> Status legend: 🟢 approved · 🟡 partial · 🔴 draft (do not implement)

---

## Scope

Translate approved mockups into Godot 4.6 / GDScript across the WalkAura client.

**In scope:**
- Top HUD + bottom nav redesign (every screen feels the change)
- Location hub redesign
- Quest system (new screen, new nav tab unlock, new data subscription)
- Gear screen redesign (slot=quality bridge, compare overlay, stat preview)
- Login polish (gold mark, ornate card, Google sign-in)
- Skills screen redesign (equipped row, school chips, painted spell cards)
- Attributes sub-tab restyle (offensive/defensive/sustain)
- Rift suite polish (entry/inside/encounter/victory/replay/history)
- Inventory quality borders + filter row + empty-slot dashed

**Deferred / out of scope:**
- 🔴 Talents redesign — direction not picked, mockup is DRAFT
- Doll tools (rotate/zoom/transmog), loadouts, gear sets — explicitly cut
- Server-side quest plumbing (assumed delivered by quest_agent on server)
- New AI art assets (use existing painted assets; mark missing in `_prompts_missing_assets`)

---

## Architecture Notes

| Concept | Lives in |
|---|---|
| Color/font/spacing tokens | `scripts/globals/styler.gd` |
| Top HUD persistent overlay | `scenes/support_screens/character_hud.{tscn,gd}` |
| Bottom nav | `scenes/support_screens/bottom_hud.{tscn,gd}` |
| Page routing | `scenes/app_scenes_handler.{tscn,gd}` + `SceneManage` autoload |
| Quality color lookup | `Styler.QUALITY_COLORS` dict (already exists) |
| Account/inventory state | `AccountManager` autoload |
| Server messaging | `ServerConnector` autoload |
| Cross-system signals | `SignalManager` autoload |

`TOP_HUD_HEIGHT` in `styler.gd` is currently `195.0`. New design = 104px (3-bar)
or 88px (layered). **Layout reflow side-effect** — every page that respects this
constant will reposition. Verify each screen post-change.

---

## Phase 0 — Token + Foundation Pass

Lowest risk, unblocks everything else. Single PR.

### 0.1 `styler.gd` token additions
- Add: `COL_SHIELD = Color.from_rgba8(109, 213, 232)` + dark variant for fill gradient.
- Add: `COL_TIER_1 = #1FFF00`, `COL_TIER_2 = #0070DE`, `COL_TIER_3 = #A336ED` (or reuse RIFT tier colors — verify single source of truth).
- Add `COL_GOLD_GLOW = Color(1.0, 0.78, 0.26, 0.18)` for outer-glow helpers.
- Update `TOP_HUD_HEIGHT = 104.0` (was 195) and add `TOP_HUD_HEIGHT_LAYERED = 88.0` for shield-overlay mode.
- Add helper `make_glow_stylebox(color, radius)` for the gold-glow card treatment used in location hero, login card, gear score disc.
- Add helper `make_painted_progressbar(fill_top, fill_bot, track)` consolidating the gradient + inset + shimmer logic so HP/MP/Shield/rift-progress all share one path.

### 0.2 Layout reflow audit
After `TOP_HUD_HEIGHT` change, walk each top-level scene:
- `location_hub.tscn`, `character_inventory.tscn`, `character_profile.tscn`,
  `character_skills.tscn`, `rift_*.tscn`, `achievement_tab.tscn`,
  `profession_detail.tscn`.
- Verify `content_top` margin still produces a clean gap below HUD.
- Fix any anchor/offset hardcodes.

### 0.3 Naming hygiene
- Map `COL_BTN_SUCCESS/PRIMARY/DESTRUCTIVE` to mockup `--btn-*` names if any diverge.
- Document the surface-family rule (chrome vs parchment) at the top of `styler.gd` as a code comment so it survives refactors.

**Risk:** Low. Touch is localized; visual regression caught immediately by running each scene.
**Estimate:** 0.5 day.

---

## Phase 1 — HUD + Bottom Nav

### 1.1 Top HUD chrome redesign — `character_hud.{tscn,gd}`
- Re-enable `shield_bar` (currently `visible = false` line ~33) and restyle to cyan gradient.
- Replace flat-gray Panel with vertical-gradient StyleBox (`#0e1018 → #1a1a25 → #14141e`), `r-md` corners, gold-glow bottom border + black drop-shadow.
- Restyle avatar frame: 2px gold border, inner black inset shadow, outer 12px gold glow. Diagonal sheen via `_draw()` overlay.
- Reposition level badge (26×26, half-outside frame, gold border, brown radial).
- Three bars (HP/Shield/MP) stacked, 11px tall, painted track + gradient fill + shimmer (use `Styler.make_painted_progressbar` helper).
- Bar label format change to `"HP 160 / 150"` (prefix added).
- Minimap frame matches avatar treatment (2px gold border, glow). Bottom strip with location name in `JANDA_FONT` 9px gold. "D" badge half-outside.

### 1.2 Activity sub-badge — same scene
- Existing `activity_label` + `texture_rect` repurposed as the activity sub-badge.
- Chip styling: pill shape (10px radius), black-40% bg, 1px gold-glow border. 16px circular icon + 10px `JANDA_FONT` activity name.
- Hook visibility to `AccountManager.current_activity_type` signal (already emitted today? — verify with grep, otherwise add).
- Tap → emit `signal_OpenActivityScreen` for SceneManage to route.

### 1.3 Bottom nav polish — `bottom_hud.{tscn,gd}`
- Existing 5-slot panel already supports Quests; flip `NAV_COUNT` from 4 to 5 (once Quests scene exists — Phase 3 unlocks this).
- Active-tab StyleBox: gold border on icon tile, radial brown-glow bg, outer gold glow, 2px gold rim above tab spanning 60% width.
- Add `pip` indicator node to Quests slot (8×8 offense-red circle, 1.5px black ring). Show when `AccountManager.has_ready_quest` true.

**Risk:** Medium. HUD layout change ripples; needs per-scene QA.
**Estimate:** 1.5 days.

---

## Phase 2 — Location Hub (highest user-visible win)

### 2.1 Layout restructure — `location_hub.{tscn,gd}`
Restructure to 4-region vertical stack:
- **Hero painted region (280px contained)** — TextureRect with `object-fit: cover` equivalent; 4× ornate corner brackets (Control nodes with custom `_draw()`); tier-color pill + location name overlay at bottom-center fade.
- **Travel arrows** — 36×36 round buttons on hero left/right; backdrop_blur via shader or 60%-alpha background; wired to `signal_TravelTo`.
- **Action stack (scrollable below hero)** — VBoxContainer in `panel-darker` bg with 12px padding + 10px gap.

### 2.2 Quest tracker pill (always present)
- Reusable Control: 3-col grid `[36px icon | meta | chevron]`.
- Variants: tier-bordered when active, gold-bordered empty state.
- Tap → opens Quests screen (Phase 3 dependency).

### 2.3 Active activity card (conditional)
- Visible when `AccountManager.has_active_activity`.
- Green-bordered, success-glow, 3-col `[52px icon | info | 36px STOP]`.
- Stop button → existing stop-activity flow.

### 2.4 Activity picker grid
- 3-col grid of activity cards (Herbalism, Mining, Forester, Fishing, Alchemy, Hunting, Rift, Enchanting).
- Each card: 48px ring (SVG-equivalent via `RadialProgress` already in codebase) + name + level.
- Ring color = activity accent (matches `RING_COLOR_*` in styler).
- Locked state (level gate): 40% opacity + lock glyph overlay.
- Active state: green border + glow + green name color.

### 2.5 Remove current overlays
- Strip activity progress bar from background painting (currently overlaid on cobblestone).
- Strip 3 floating profession buttons (replaced by grid above).

**Dependencies:** Phase 0 tokens. Phase 3 quest tracker tap-route can stub-out initially.
**Risk:** Medium. Most complex layout change.
**Estimate:** 2 days.

---

## Phase 3 — Quest System (CLIENT BOILERPLATE — server not ready)

Server quest endpoints not shipped. **Build client-side UI shell + stub data
layer.** When server lands, swap stub for real subscription.

### 3.1 Stub data layer — `scripts/globals/quest_stub.gd` (autoload)
- Static fixture data: 3 active quests, 5 available, 2 daily, 87 done (mixed types).
- Mirror eventual server shape so swap is mechanical: `quest_id`, `type`,
  `tier`, `name`, `level`, `objectives`, `rewards`, `giver`, `location`,
  `is_tracked`, `is_ready_to_turn_in`.
- Same signals as future real path: `signal_QuestsUpdated`,
  `signal_QuestObjectiveProgress`, `signal_QuestReadyToTurnIn`.
- Debug menu toggle: cycle quest states to verify UI variants.
- TODO marker comment block: `# REPLACE WITH AccountManager.quests + ServerConnector hooks when quest_agent ships`.

### 3.2 New scene: `scenes/main_screens/character_quests.{tscn,gd}`
- 4 filter chips at top (Active/Available/Daily/Done) with counts + Daily pip.
- Daily reset timer banner (visible when relevant, hardcoded countdown for stub).
- Scrollable quest list with section headers (Story / Active / Available / Done).
- Quest card component (Phase 3.3).
- Data source: `QuestStub` autoload (Phase 3.1).

### 3.3 New component: `scenes/components/quest_card.{tscn,gd}`
- 4-row card: head (icon + title + level) / progress (multi-objective or single-bar) / rewards strip / meta footer.
- Tier-color left edge, story = gold edge.
- States: default, tracked (gold corner flag), ready-to-turn-in (gold glow + "READY" pill).
- Tap → opens detail (Phase 3.4).

### 3.4 New scene: `scenes/secondary_scenes/quest_detail.{tscn,gd}`
- Header: back chevron + tier-eyebrow + name + level.
- Painted illustration: placeholder (use existing rift portal art recolored, or
  generic painted scene from `location_backgrounds/`). Real art "will create later".
- Lore overlay (italic Fondamento fallback to `QUADRAT_FONT`).
- Giver block (portrait + name + turn-in location).
- Objectives list with per-objective progress.
- Rewards grid (XP + gold + items with quality borders).
- Actions: UNTRACK / ABANDON / TURN-IN (gold, only when ready). All stubbed to
  emit signal + log — no server call.

### 3.5 Bottom nav hookup
- Flip `bottom_hud.gd` `NAV_COUNT = 5`.
- Wire Quests tab → `character_quests.tscn` via `SceneManage`.
- Pip on Quests tab driven by `QuestStub.has_ready_quest` (later: `AccountManager.has_ready_quest`).

### 3.6 Location hub integration
- Quest tracker pill subscribes to `signal_QuestsUpdated` for tracked-quest selection.

### 3.7 Future swap checklist (do NOT do now, write as comment in stub)
- [ ] Replace `QuestStub` autoload with `AccountManager.quests` field.
- [ ] Wire `ServerConnector` message handlers: `quest_state`, `quest_offer`, `quest_turnin_result`.
- [ ] Wire UNTRACK/ABANDON/TURN-IN actions to real server calls.
- [ ] Remove debug menu cycle toggle.
- [ ] Replace placeholder quest art with commissioned painted assets.

**Dependencies:** none (deliberately stubbed). Server work happens later.
**Risk:** Medium. UI works in isolation; integration risk deferred.
**Estimate:** 3 days (was 4 — no server plumbing).

---

## Phase 4 — Inventory + Gear

### 4.1 Inventory quality borders — `character_inventory.{tscn,gd}`
- Modify slot renderer: 1.5px quality-color border + inset glow (8-12px) per `Styler.QUALITY_COLORS`.
- Empty slot: dashed 6%-white border, transparent bg (use `StyleBoxFlat` with dashed alternative or custom `_draw()`).
- Add "NEW" gold pip for items not yet inspected (track via `AccountManager.seen_item_ids`).
- Filter chips: horizontal scroll (`ScrollContainer` with `clip_contents`), chip restyle.

### 4.2 Gear screen redesign — `character_inventory.tscn` (Gear sub-tab)
- **Gear Score ribbon** (60px) — 3-col grid. Center disc = gold-bordered radial brown with gold-glow halo, 26px `JANDA_FONT` value.
- **Equipment slot restyle** — slot border color now driven by equipped item's `quality_tier` (not decorative slot color). Empty slot = dashed neutral.
- iLvl pip (gold corner chip) per filled slot.
- Empty-slot silhouette: 18%-opacity grayscale type icon (Head=helmet silhouette, etc.).
- Upgrade ↑ badge: green circle top-left when `Inventory.has_upgrade_for(slot_id)` returns true.
- Gemmed ✦ glyph bottom-right when socketed.

### 4.3 Stat Preview Card
- 6-stat grid: Phys ATK / Magic ATK / Phys DEF / Dodge / Crit / Haste.
- Pull from existing derived-stats computation (likely in `Account` class).
- Delta chips shown when compare-mode active.

### 4.4 Compare overlay
- New component: `scenes/components/gear_compare_card.{tscn,gd}`.
- Triggered by tapping inventory item while Gear tab active.
- 3-col `[equipped | → | candidate]` + delta-pill row + EQUIP button (quality-colored).
- Score preview animates in ribbon (142 → 156).
- Dismiss: tap outside or X.

### 4.5 Empty-slot tap flow
- Tap empty slot → set `inventory_filter = slot_type` + switch to Inventory tab.

**Risk:** Medium. Slot rendering touches a hot path.
**Estimate:** 2.5 days.

---

## Phase 5 — Login + Skills + Attributes + Rift Polish

Parallel-safe; each independent.

### 5.1 Login — `login_scene.{tscn,gd}`
- Title mark: "WalkAura" sized to 44px `JANDA_FONT` gold + flanking `✦` glyphs + outer gold glow.
- Tagline below in italic style.
- Card: 4× corner brackets via `_draw()`, 1px gold border, gold-glow halo, inset top sheen.
- Inputs: gold-soft left edge, focus → full gold + glow.
- `ENTER THE REALM` button: gold gradient, embossed, gold halo. Remove sword glyph.
- **Google sign-in button: PLACEHOLDER ONLY.** White bg, brand-correct G mark texture (conic-gradient or simple sprite), "Continue with Google". On tap → show "Coming soon" toast. No Android SDK integration. Future: wire to real Google Sign-In via `WalkAura_Androidplugin` (separate ticket when needed).
- Atmospheric motes: 4-5 gold particles via `CPUParticles2D`, drift up + fade.
- Version tag: muted gold bottom-right.

### 5.2 Skills — `character_skills.{tscn,gd}`
- Equipped row: 6 slots, hotkey badges (1-6), school-tinted glow on filled, dashed on empty.
- Class tabs: parchment underline tabs (Mage / Paladin / Utility / Blood / Dark / Arcane).
- School chips: rounded pills, multi-select, school-color dot + name. Horizontal scroll.
- Spell cards: 2-col grid, 44px school-bordered icon, school-tinted name, cost row chips, effect line in semantic color.
- Equipped spell: gold star corner + halo.

### 5.3 Attributes sub-tabs — `character_profile.{tscn,gd}` (Attributes tab)
- Primary stat strip: 3x2 compact cells (already exists in current screen — restyle).
- Sub-tab segmented control: 4 tabs with sub-tab-color fill on active (red/blue/gold/green).
- Summary bar (3 top stats per sub-tab).
- Sectioned rating rows: gold-underlined section headers, 2px sub-tab-color left edge, zero values dimmed to 55%, hi values green-text.
- Element rows (Damage Amplifiers / Resistances): element-color left edges (matches Skills schools).

### 5.4 Rift suite — `scenes/secondary_scenes/rift_*.{tscn,gd}`
Per DESIGN.md "Rift Suite — Updates" section:
- `rift_detail.tscn` — hero 200px cap + corner brackets + lore-below-art + req cards + tier-color CTA emboss.
- `rift_active.tscn` — hero shrink to 140px, painted progress bar (16px), node-path moved into bordered panel, encounter card upgrade (offense-red border + glow + structured enemy rows + resist chips + emboss FIGHT button), PAUSE/EXIT single row. Kill "+2000 steps" floating debug text.
- `rift_fight_result.tscn` / `rift_completion_screen.gd` — VICTORY mark with flanking gold rules, 3-cell deltas, combat-stats 2-col, loot row with quality-bordered icon.
- `rift_battle_replay.tscn` — combat snapshot strip (both portraits + HP/Shield mini-bars + VS), tick progress bar, structured log entries with color-coded actors + crit/dodge/death row tints, controls bar.
- `rift_history_screen.gd` — sticky search + filter chips, date-grouped cards, tier-color edge + status pills.

**Estimate:**
- 5.1 Login: 1 day (+ Android plugin dependency for Google)
- 5.2 Skills: 1.5 days
- 5.3 Attributes: 1 day
- 5.4 Rift: 2.5 days
**Total:** 6 days, parallelizable.

---

## Phase 6 — Polish + Defer

### 6.1 Achievement tab
Already close to spec per DESIGN.md `Achievements Tab — AAA Design Spec`. Audit
for: card spacing rhythm, gold-underline section headers, claim button states.
**Estimate:** 0.5 day.

### 6.2 Profession detail
Already spec'd. Verify XP ring + accent colors + recipe accordion still match.
**Estimate:** 0.25 day.

### 6.3 Step chart
Compact 2x3 primary-stat strip + painted bar chart with goal line + today
highlight in `step_stats_chart.{tscn,gd}` and `step_stats_chart_canvas.gd`.
**Estimate:** 0.5 day.

### 6.4 Drafts left alone
- 🔴 Talents — `character_skills.tscn` Talents sub-tab unchanged. Reopen when direction picked.

---

## Phase Ordering + Cut Points

Recommended ship sequence (user-locked):

1. **Phase 0** (foundation) — must land first.
2. **Phase 1** (HUD + nav) — every screen visibly improves immediately.
3. **Phase 5.1-5.4** (login + skills + attributes + rift polish) — parallel track, lots of breadth at once.
4. **Phase 4.1** (inventory quality borders) — cheap single-cost win.
5. **Phase 2** (location hub) — priority pain.
6. **Phase 3** (quests boilerplate, stub data) — UI shell ready for when server lands.
7. **Phase 4.2-4.5** (gear redesign) — depends on P4.1 borders being live.
8. **Phase 6** (polish) — last.

**Natural cut points** (ship between phases if scope tightens):
- After P1: HUD fresh, every screen reads better.
- After P5: most screens polished, quests still missing.
- After P2: location works, quest tracker can stay empty-state.
- P3 boilerplate ship even without server — UI demonstrable, swap later.

---

## Cross-Cutting Concerns

### Mobile testing
- Test on actual Android device (not just editor) after every phase — touch
  targets, scrollable areas, painted bg parallax under new HUD heights.
- Verify the 411×870 mockup viewport mostly matches real device aspect.

### Performance
- Painted progress bar shimmer animation: limit to active HP/MP/Shield bars
  only (not all bars on screen).
- Mote particles on login: CPU particles, max 5-8.
- Activity-ring SVG-equivalent: use cached textures or `RadialProgress` shader,
  don't redraw per frame.

### Backwards compat
- Don't bump server protocol unless quest data needs new fields. Cross-check
  with `quest_agent.py` on server before adding subscription fields.
- Existing screens (achievements, profession detail) should keep working
  through every phase — no breaking signal renames.

### Accessibility
- Touch target 44×44 minimum (per DESIGN.md).
- Text contrast: all gold-on-dark passes WCAG AA, all dark-brown-on-cream
  same. Verify with eyedropper if uncertain on a card.

### Asset gaps
- `quest_card.tscn` needs default quest icons per type (kill / gather / craft
  / explore / delivery / story). Stub with Unicode glyphs for v1, add to
  `_prompts_missing_assets` for later AI generation.
- Quest detail painted illustrations: stub with existing rift portals
  recolored. Real art deferred ("will create later").
- Login `✦` ornament glyphs — Unicode works for v1; commission painted
  texture later if needed.
- Empty-slot silhouettes for Gear — need monochrome icons per slot type
  (probably already in `general_icons/gear/`).
- Google G mark texture — conic-gradient or simple sprite, no licensing risk
  since button is placeholder + non-functional.

---

## Estimate Roll-Up

| Phase | Days |
|---|---|
| 0 Foundation | 0.5 |
| 1 HUD + Nav | 1.5 |
| 5 Login + Skills + Attr + Rift | 6 (parallelizable to ~3) |
| 4.1 Inventory borders | 0.5 |
| 2 Location | 2 |
| 3 Quests (boilerplate, stub data) | 3 |
| 4.2-4.5 Gear | 2 |
| 6 Polish | 1.25 |
| **Total** | **~16.75 days** sequential / **~12 days** with parallel |

CC + agent compression typically 5-10x — actual elapsed wall time materially
shorter; estimate above is conventional human-eng day equivalent.

---

## Locked Decisions (was Open Questions)

| # | Decision |
|---|---|
| 1 | **Talents:** skip. Stays DRAFT, untouched in code. |
| 2 | **Google sign-in:** placeholder button only, no real auth. Tap → "Coming soon" toast. |
| 3 | **Quests server:** not ready. Build client boilerplate with stub data layer; swap when server lands. |
| 4 | **Loadouts:** dropped, no revisit. |
| 5 | **Set bonuses:** dropped, no revisit. |
| 6 | **Quest illustration art:** stub with recolored rift portals; commission real art later. |
