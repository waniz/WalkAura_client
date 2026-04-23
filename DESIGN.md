# Design System — WalkAura

## Product Context
- **What this is:** Mobile RPG where real-world steps drive in-game progression
- **Who it's for:** Mobile RPG players who walk/run and want game progression tied to physical activity
- **Space/industry:** Mobile RPG, step-tracking fitness gamification
- **Project type:** Godot 4.6 mobile game (Android)

## Aesthetic Direction
- **Direction:** Dark Fantasy RPG, Semi-Realistic Painted
- **Mood:** Warm-toned, painterly style with visible brushwork. Equipment and characters feel hand-painted, not photorealistic. Think Diablo 2 character screen meets modern mobile polish. Dark UI frames the art, gold accents signal importance and progression.
- **Decoration level:** Intentional. Dark panels with subtle borders, quality-colored accents on interactive elements.

## Art Style — Character & Equipment
- **Style:** Semi-realistic painted, warm lighting from upper-left
- **Palette:** Earth-tone base (browns, tans, dark greens, aged metals)
- **Metal rendering:** Visible highlights, worn edges, patina on lower-quality items
- **Lighting:** Consistent warm directional light, upper-left source
- **Canvas spec:** All character/equipment overlays share identical dimensions (512x1024 recommended, calibrate to viewport)
- **Character pose:** Front-facing, neutral, slight T-pose (arms away from body for overlay layering)
- **Format:** Transparent PNG
- **Style references:** Existing equipment icons (chest_0.png, feet_0.png, main_hand/sword/0.png)
- **Quality progression:** Lower quality items look simpler and more worn. Higher quality items have more detail, brighter metals, subtle glow effects, and richer color saturation.

## Color System
All colors defined in `scripts/globals/styler.gd`. This is the source of truth.

### Primary
- **Gold (COL_PRIMARY):** `#FFC842` / `rgba(255, 200, 66)` — primary accent, gold text, important labels
- **Offense:** `#FF785A` / `rgba(255, 120, 90)` — attack stats, damage numbers
- **Defense:** `#40B4FF` / `rgba(64, 180, 255)` — defense stats, primary action buttons

### Surfaces
- **Panel BG:** `#101218` at 86% opacity — main panel backgrounds
- **Panel Dark:** `#1C1E28` — darker surface, section separators
- **Panel Border:** `#FFFFFF` at 12% opacity — subtle panel edges
- **Panel Gray:** `#6E6060` — muted interactive elements

### Quality Tiers
| Tier | Name | Color | Hex |
|------|------|-------|-----|
| 0 | Poor | Gray | `#9E9E9E` |
| 1 | Common | White | `#FFFFFF` |
| 2 | Uncommon | Green | `#1FFF00` |
| 3 | Rare | Blue | `#0070DE` |
| 4 | Epic | Purple | `#A336ED` |
| 5 | Legendary | Orange | `#FF8000` |
| 6 | Mythic | Gold | `#E6CC33` |

### Stat Colors (Ring Progress)
- Strength: `#E664A0`, Agility: `#E6A028`, Vitality: `#A01E1E`
- Intellect: `#963CF0`, Spirit: `#1E32A0`, Luck: `#1E7832`

### Semantic
- Success: `#3CC850` / Error: `#DC5050`
- Button Primary (Cyan): `#40B4FF`
- Button Secondary (Gold): `#FFC842`
- Button Destructive: `#B43C3C`
- Button Success: `#3C8246`

### Element Colors
- Fire: `#FF8000`, Frost: `#4D99FF`, Holy: `#FFD94D`
- Utility: `#99CC80`, Dark: `#8033B3`, Arcane: `#4DB3E6`
- Blood: `#8C1428`

## Typography
Godot's built-in font system. Sizes defined in Styler.gd.

- **Title:** Bold, 24px — screen headers, section titles
- **Subtitle:** Bold, 18px — sub-sections, card headers
- **Body/Label:** 14px — stat labels, slot names, descriptions
- **Small:** 12px — secondary info, tooltips
- **Values:** 14px, gold color (`#FFC842`) — numeric values, quantities
- **Quality text:** Colored to match quality tier

## Spacing
- **Base unit:** 8px
- **Density:** Comfortable for mobile touch targets
- **Touch target minimum:** 44px
- **Slot size (equipment):** 76x76px
- **Slot padding:** 10px
- **Grid slot size (inventory):** 80x110px
- **Grid padding:** 5px
- **Panel margin:** 8-16px
- **Tooltip margin:** 8px

## Layout
- **Approach:** Structured panels with dark backgrounds
- **Gear tab:** Left slot column | Center character paper doll | Right slot column
- **Inventory:** Filterable grid below equipment panel
- **Navigation:** Tab buttons (Inventory / Gear) with gold active state
- **Bottom HUD:** Fixed 108px from screen bottom

## Motion
- **Approach:** Minimal-functional
- **Equipment swap:** Texture replacement (instant)
- **Future:** Gyroscope parallax on paper doll layers (deferred)
- **Transitions:** Scene transitions via SceneManage autoload

## Paper Doll Spec
- **Scene tree:** 8 TextureRect nodes in draw order
- **Visible slots (7):** head, shoulder, chest, belt, gloves, legs, feet
- **Invisible slots (9):** neck, wrist, cloak, ring_left, ring_right, trinket_left, trinket_right, main_hand, off_hand
- **Empty state:** Base character body visible, no overlays
- **Draw order:** base_body > legs > chest > shoulder > head > gloves > feet > belt
- **Total overlays needed:** 50 (head 2, shoulder 2, chest 20, belt 20, gloves 2, legs 2, feet 2)

## AI Art Generation Prompt Guide
When generating character body or equipment overlays with AI:

**Base prompt elements:**
- "semi-realistic painted fantasy RPG"
- "warm directional lighting from upper-left"
- "earth tones, browns, aged metals"
- "transparent background"
- "front-facing, neutral pose"
- "512x1024 canvas, centered"
- "painterly brushwork, not photorealistic"

**Per-quality modifiers:**
- Poor/Common: "simple, worn, muted colors, minimal detail"
- Uncommon: "clean lines, slightly richer colors"
- Rare: "polished metal, blue-tinted accents, moderate detail"
- Epic: "ornate, purple crystal accents, high detail, subtle glow"
- Legendary: "masterwork, orange fire accents, intricate engravings"
- Mythic: "divine craftsmanship, golden trim, ethereal shimmer"

## Surface Treatment — Dark Chrome vs Parchment

Two surface families. Which one a panel uses is driven by *role*, not screen:

- **Dark chrome** (`Panel BG: #101218 at 86%`, gold accents, 12% white border) — ambient game HUD that overlays any screen: top resource bar, bottom tab bar, activity progress panel on the location hub, all rift screens. Anything that reads as "live game state" rather than screen content.
- **Parchment** — screen-content panels for non-combat exploration: inventory, character profile, crafting detail cards, tooltips. Scrollable, read-at-your-pace surfaces.

Rule of thumb: if the panel sits in front of the painted world and updates in real time, it's chrome (dark). If the panel *is* the screen and you're reading/managing items, it's parchment.

### Tier Color Temperature
The tier color tints headers, progress bars, and accent borders. The whole screen shifts feeling with difficulty.
- **Tier 1 (Easy):** Cool green `#1FFF00` — subtle green tint on header area
- **Tier 2 (Medium):** Warm blue `#0070DE` — blue tint on header area
- **Tier 3 (Hard):** Hot purple `#A336ED` — purple tint on header area

### Rift Tier Labels
- Tier 1: "TIER 1 - EASY", Tier 2: "TIER 2 - MEDIUM", Tier 3: "TIER 3 - HARD"
- Font: QUADRAT_FONT, 13px, uppercase, colored to match tier

### Requirement Indicators
- Met: green checkmark "✓" `rgba(60, 200, 100)`, font 16px
- Unmet: red cross "✗" `rgba(220, 80, 80)`, font 16px
- Display as compact card pairs (two side-by-side boxes with border matching met/unmet state)

### Lore Text Treatment
- Font: 14px, color `rgba(140, 130, 110)` (warm muted parchment tone)
- Wrapped in subtle inset panel: `bg_color = Color(0, 0, 0, 0.04)`, corner_radius 4, padding 6px

### Node Path Component (Reusable)
Horizontal encounter progress indicator used in Rift Active and Fight Result screens.
- **Completed node:** Filled diamond ◆, tier color
- **Current node:** Outlined diamond ◇, pulsing/highlighted, tier color
- **Future node:** Dim diamond ◇, `rgba(120, 120, 120)`
- **Connecting lines:** Solid between completed nodes, dashed to future
- Layout: centered horizontal row, evenly spaced, with encounter numbers below each node

### Encounter Card Component
Bordered panel for pending fight info on the active screen.
- **Fight ready:** Red border `rgba(200, 50, 50)`, with "FIGHT NOW" button inside
- **Default:** Tier-colored border
- Shows: enemy count, gear recommendation, fight button when ready

### Screen 1: Rift Detail (Entry)
- **Top 40%:** Rift portal art (painted illustration, one per rift or generic recolored per tier). Tier-tinted color overlay.
- **Below art:** Tier badge label, rift name (JANDA_FONT, 22px, tier color), description (body text)
- **Requirements:** Two compact card boxes side-by-side (Rift Lvl, Account Lvl) with green/red borders
- **Summary:** "N encounters · XXXX steps" + "Gear Score: X–Y" in gold
- **Lore:** Inset panel with warm muted text
- **CTA:** Full-width "ENTER RIFT" button, tier-colored, large. "RIFT HISTORY" as text link below.
- **Locked state:** "ENTER RIFT" becomes "LOCKED" (gray, disabled). Red requirement boxes show what's missing.
- **Enter timeout:** Button shows "Starting..." for up to 3s, toast "Could not enter rift" on failure.

### Screen 2: Rift Active (Progress)
- **Header:** Rift name (tier color, JANDA_FONT, 22px) + rift level
- **Progress bar:** Thick (32px+), tier-colored fill with subtle glow, dark track
- **Node path:** Horizontal diamond chain showing encounter progression (see Node Path Component)
- **Current encounter card:** When pending_fight is true, show a highlighted encounter card with enemy count, gear score, and large "FIGHT NOW" button
- **Completed encounters:** Collapsed result rows below: "✓ #N  WIN/LOSS  HP X→Y  Loot: Z"
- **Action buttons:** "PAUSE RIFT" (amber) + "EXIT RIFT" (red) at bottom
- **Fight history:** "Refresh" and "Battle Log" buttons in header row. Fight rows as styled buttons with result color.

### Screen 3: Fight Result (Post-encounter overlay)
- **Full overlay** after each fight completes (not buried in a list)
- **Header:** "VICTORY" (gold `#FFC842`) or "DEFEATED" (red `#DC5050`), large centered text
- **Subheader:** "Encounter #N Complete"
- **Enemy list:** Enemies defeated with names and levels
- **Resource delta:** HP/MP/Shield before → after with color (green if gained, red if lost)
- **XP gained:** Gold colored
- **Loot section:** Items dropped with quality-colored names
- **Node path:** At bottom showing updated progress
- **CTA:** "CONTINUE" button dismisses overlay

### Screen 4: Loadout (Pre-fight)
- **Header:** "ENCOUNTER #N" + enemy count
- **Enemy list:** Structured rows with role tags [TANK] [DPS] [CASTER] [HEALER] color-coded. Each row: name, level, HP.
- **Preparation section:** Gear score comparison (your score / recommended, ⚠ if below). Elemental resistance recommendations.
- **Player stats:** HP, MP, Shield as compact row
- **Buttons:** "Later" (muted gray) + "FIGHT!" (red, large). FIGHT is the primary action.

### Screen 5: Battle Replay
- **Grouped by turns** instead of flat text wall. Each turn is a card.
- **Player actions:** Right arrow "→", white text
- **Enemy actions:** Left arrow "←", muted text
- **Highlighted events:** Critical hits in gold `#FFC842`, deaths in red with "DEFEATED", spell casts named
- **Pagination:** 5-6 turns per page with prev/next navigation
- **Header:** "BATTLE REPLAY" + encounter number + result (VICTORY/LOSS)

### Screen 6: Fight Log (Detailed)
- **Summary card at top:** Duration (ticks), total damage dealt/taken, crits, dodges, spells cast, blocks. Most players only need this.
- **Tab navigation:** Summary (default) | Full Log | Stats
- **Full Log tab:** Tick-numbered entries with directional arrows, color-coded events
- **Stats tab:** Computed analytics: DPS/tick, damage taken/tick, hit rate %, crit rate %
- **Color coding:** Crits = gold, blocks = blue `#40B4FF`, deaths = red, heals = green

### Art Assets Required
One rift portal illustration per tier (or one generic recolored). AI-generated following existing art style:
- **Prompt base:** "dark fantasy rift portal, glowing energy tear in reality, semi-realistic painted, [tier color] glow, dark atmosphere, 720x400px"
- **Tier 1:** Green energy, forest elements, natural feel
- **Tier 2:** Blue/orange energy, stone and metal elements, industrial feel
- **Tier 3:** Purple energy, chaotic elements, otherworldly feel

### References
- Diablo Immortal: rift entry atmosphere, dark panel UI, difficulty color coding
- Raid: Shadow Legends: dungeon stage node paths, champion role display, polished fight results
- AFK Arena: floor progression UI, compact encounter nodes, clean mobile layout

## Crafting Professions — AAA Design Spec

Crafting profession screens (alchemy, enchanting) use **parchment** treatment (non-combat).
Profession-specific accent colors tint XP bars, craft buttons, tier tab indicators, and expanded card borders.

### Profession Accent Colors
- **Alchemy:** `#3C8246` — earthy green (nature/potions)
- **Enchanting:** `#A336ED` — arcane purple
- **Default (gathering):** Gold `#FFC842`

### Tier Classification
Recipes grouped by `req_level`: 1–4 → T1, 5–9 → T2, 10–14 → T3, 15–19 → T4, 20+ → T5

### Screen 1: Profession Detail (Crafting)

**Header Section:**
- Profession icon (64x64) inside radial XP ring, accent-colored ring fill
- Name: JANDA_FONT 22px, accent color. Level badge beside it.
- XP progress bar: 20px thick, accent fill, dark track, corner_radius 6
- XP text: "3,200 / 5,000 XP" below bar, right-aligned

**Active Crafting Banner** (visible only when crafting this profession):
- Accent-colored left border (3px), subtle background
- Recipe icon (32x32) + "Crafting: [name]"
- Compact progress bar + "52/80 steps"
- Batch text: "Batch: 3/5" (if qty > 1)
- STOP button right-aligned

**Tier Filter Tabs** (horizontal row):
- "ALL" | "T1" | "T2" | "T3" | "T4" | "T5"
- Active tab: accent bottom border (3px) + accent text
- Locked tiers (above player level): dimmed 50% opacity

**Recipe List** (scrollable):
Compact card per recipe (~80px):
- Left: Status-colored left border (green=READY, amber=MISSING, gray=LOCKED)
- Output icon (48x48) in accent-bordered frame
- Center: Recipe name (QUADRAT 16px) + status badge
- Right: Ingredient thumbnails (24x24) with qty overlays
- Tap to expand

**Expanded Recipe Detail** (in-place accordion, one at a time):
- Accent border (2px all sides), corner_radius 8
- Large output icon (64x64) + name in accent color + effects (green)
- Ingredient slots grid: 44x44 icon per ingredient, green/red border (have/missing), "have/need" below
- Stats row: steps + XP + speedup %
- Quantity controls: [-] [qty] [+] [MAX] (44px touch targets)
- Full-width CRAFT button, accent-colored, 44px tall
- Tap header to collapse

### Sorting Order
1. Craftable (can_craft) → top
2. Unlocked but missing ingredients → middle
3. Locked → bottom
4. Within group: ascending req_level, then alphabetical

### References
- WoW Classic profession window (recipe list + detail split)
- Diablo Immortal crafting (dark panels, icon prominence)
- Existing WalkAura Rift screens (banner + progress + cards pattern)

## Rift Profession Hub — Battle UI Spec

Rift profession uses **dark panel** treatment (battle screen, not crafting).
Accent color: Offense red `#FF785A` from the existing color system.

### Dark Panel Treatment
- Background: `COL_PANEL_BG` (`#101218` at 86% opacity)
- Border: white at 12% opacity, corner_radius 4
- Text: white/light instead of dark
- All labels use light colors; status indicators use standard semantic colors

### Rift Hub Layout

**Header:** Same structure as crafting (icon ring + name + XP bar) but with:
- Red accent ring fill and XP bar
- White text (dark mode)
- XP computed from `ServerParams.ACTIVITY_PROGRESSION_LEVELS` (no server request)

**Active Rift Banner** (visible when player is in a rift):
- Rift name in tier color + progress bar (steps / total)
- Milestone indicator "Milestone 3/6"
- [CONTINUE] button → opens rift_active scene

**Rift Grid** (scrollable, grouped by tier):
- Tier headers: "TIER 1 · EASY" etc. in tier color (from RiftData.TIER_COLORS)
- 2-column grid of rift cards per tier

**Rift Card:**
- Tier-colored left border (met requirements) or gray (locked)
- Rift name in tier color (QUADRAT 16px)
- Requirements: "Rift Lv X" ✓/✗ + "Acct Lv Y" ✓/✗ (green/red)
- Stats: "N encounters · M steps" + gear score range
- Tap → closes hub, opens rift_detail/rift_active scene

## Decisions Log
| Date | Decision | Rationale |
|------|----------|-----------|
| 2026-04-10 | Initial design system created | Created by /design-consultation. Codifies existing Styler.gd patterns + art direction for paper doll character view. |
| 2026-04-10 | Semi-realistic painted art style | Matches existing AI-generated equipment icons. Diablo 2 meets mobile polish. |
| 2026-04-10 | Dark UI + gold accents | Category standard for RPGs. Users expect it. |
| 2026-04-10 | 512x1024 overlay canvas | Recommended base, calibrate to actual mobile viewport after testing. |
| 2026-04-16 | Rift screens AAA redesign | Dark panels (not parchment) for rift screens. Node path for encounter progression. Full fight result overlay. Turn-grouped battle replay. Tabbed fight log with summary. Tier color temperature system. References: Diablo Immortal, Raid Shadow Legends, AFK Arena. |
| 2026-04-16 | Rift portal art per tier | AI-generated painted portal illustrations, one per tier (green/blue/purple energy). Used as header image on rift detail entry screen. |
| 2026-04-16 | Node path component | Reusable horizontal diamond chain for encounter progression. Used in Rift Active and Fight Result screens. Pattern from Raid/AFK Arena dungeon stages. |
| 2026-04-16 | Crafting professions AAA redesign | Tier-tabbed recipe list, accordion expand for detail, profession accent colors (alchemy green, enchanting purple), ingredient slot grid with have/need indicators. WoW-inspired layout adapted for mobile. |
| 2026-04-16 | Rift profession hub | Dark-paneled battle UI for rift explorer profession. Red accent, tier-grouped rift cards, active rift banner with continue. All data client-side from RiftData + Account. |
| 2026-04-17 | Achievements tab — civic/study family | Parchment bg + dark-brown text to match Professions. Rejects dark-combat-panel family for codex/catalog screen. 3px tier-color left edge on cards (matches alchemy recipe-card rhythm). Gold-underlined section headers. Painted-wood trophy plaques (72×72) instead of plain icon tiles. Reward payoff line in gold ("Reward: +2 STR · ★ Title") mirroring alchemy's "Recovery HP +25" pattern. |
| 2026-04-18 | Surface treatment split: chrome vs parchment by role | Generalized dark-panel rule beyond rifts. Ambient game HUD (top bar, tab bar, location activity progress panel, rifts) uses dark `#101218@86%` chrome. Screen-content panels (inventory, profile, crafting, tooltips) stay parchment. Triggered by location hub activity progress panel looking misaligned with surrounding dark HUD — it was parchment-styled while everything around it was dark chrome. |

## Achievements Tab — AAA Design Spec

**Family: civic/study (parchment).** Achievements is a codex screen — players
browse it in peace, not combat. Belongs with Professions and Inventory, NOT with
Rift/Fight screens. Parchment cream background, dark-brown text, gold accents.
Matches profession_detail rhythm exactly.

### Header Bar
- Dark ornate bar at top (`COLOR_PANEL_DARK` 28,30,40, 240 alpha), 48px tall,
  2px gold bottom border. Mirrors the ALCHEMY header.
- Left: `ACHIEVEMENTS` in `JANDA_FONT` 22px, `COLOR_GOLD`.
- Right: metadata line `"7/15 claimed · 2 ready · +17 stats earned"` in
  `QUADRAT_FONT` 13px, warm light (220,210,180).

### Trophy Wall
- Horizontal scroll strip below header, 88px tall.
- Tile: 72×72 painted wooden plaque. Bg `Color(0.88, 0.82, 0.70)` warm wood
  tone, 2px tier-color border, 4px corner, subtle drop shadow.
- Empty state: `"Your trophies will appear here"` in `COLOR_SECTION_HDR` 12px
  italic at 55% opacity, centered.

### Tier Section Headers
- Format: `EASY · +2 primary stat`
  - Title uppercase `QUADRAT_FONT` 16px `COLOR_SECTION_HDR` (dark brown).
  - Dot-subtitle 12px in tier color (bronze / silver / gold / mythic).
- 1px gold horizontal rule below at 35% opacity.
- Sections: EASY · MEDIUM · HARD · HIDDEN (never render as `???` in section
  title — secret cards within render as "Hidden Achievement" to distinguish
  intentional mystery from broken data).

### Achievement Card
Card size: min 108px tall. `Color(0.93, 0.89, 0.80)` warm cream bg (slightly
darker than page for visual separation), 4px corner radius, 10px inner padding.

Border strategy: StyleBoxFlat uses one border color. Tier signal comes from
a left-edge width of 3-4px with a tier-tinted border color at 50% alpha (30%
when claimed, 40% muted brown when locked or hidden). Ready-to-claim and
claimed states use the thicker 4px left edge.

Layout (left → right):
```
  ┌─ 3-4px tier-tinted edge ───────────────────────────────────────┐
  │ [56px icon]  Blooded                              [ CLAIM ]   │
  │              Complete 50 battle activities.                    │
  │              Progress: ▓▓▓▓▓░░░  25 / 50                       │
  │              Reward: +2 STR                                    │
  └────────────────────────────────────────────────────────────────┘
```

- **Icon**: 56×56 on the left, vertically shrunk-top.
- **Name**: 16px `QUADRAT_FONT` `COLOR_TEXT_DARK` bold-ish (dimmed to
  `Color(.45,.40,.30)` when locked or hidden).
- **Description**: 12px `QUADRAT_FONT` `Color(.30,.26,.20)`. Locked cards
  swap desc for `"Complete required achievements to unlock."` in muted red
  `(160,60,50)`.
- **Progress row**: `Progress:` lead label in `COLOR_SECTION_HDR` 12px,
  then 20px-thick tier-colored fill bar + value label in dark text on the
  right (`"25 / 50"`).
- **Reward line** (bottom of middle column): 13px `QUADRAT_FONT` `COLOR_GOLD`.
  Format: `"Reward: +2 STR   ★ Title   ◆ Frame"`. Hidden for secret
  pre-reveal. This is the visual loudest line — mirrors alchemy's
  `"Recovery HP +25.0"` green-payoff treatment.
- **Claim button**: right column, 96×44 min. Tier-color bg, `COLOR_GOLD`
  text. Inflight: button goes `"..."` and disabled, 5-second safety timer
  resets if server never responds.
- **Claimed stamp**: replaces button with `"✓ CLAIMED\nYYYY-MM-DD"` in muted
  green 12px `(80,120,60)` — same tint family as alchemy's "Recovery" line
  so the "reward applied" signal is consistent across the civic family.

### Meta tier placement
Meta cards (Path of the Novice/Journeyman/Master) render at the bottom of
their `meta_parent_tier` section. Server ships the field explicitly; client
uses it directly rather than sniffing prereq IDs.

### Secret (Completionist)
Renders in the HIDDEN section as a single card until claimed. Desc:
`"A secret awaits those who complete all others."` No progress bar, no
reward line. Muted purple left-edge `(128,60,140)`. After reveal, transitions
to a normal claimable card with full details populated.

### Motion
- Claim animation: 450ms total. Icon scales 1.0 → 1.15 → 1.0 ease-out.
  No screen flash, no particles, no vignette — the civic family stays calm.
- Trophy Wall on first claim: no auto-tween (card animates, trophy appears
  after server returns fresh payload).

### Accessibility
- Touch targets 44×44 min.
- Text contrast: dark brown on cream parchment tested against WCAG AA.
  Muted-red "locked" hint stays ≥4.5:1 against card bg.

### Anti-patterns explicitly rejected
- Dark combat-panel bg (family mismatch — that's for rifts/fights)
- Purple gradients, icon-in-colored-circle 3-column grids (generic AI slop)
- Screen flash / vignette / particles on claim (wrong family)
- `"???"` as section title (reads as missing data, not intentional mystery)
