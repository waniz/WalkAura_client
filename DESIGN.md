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

## Top HUD — Dark Chrome Treatment

The top HUD persists across every screen. It's the most-seen UI in the game and
sets the visual register for everything below it. Previous flat-gray placeholder
treatment is replaced by **dark chrome with gold ornamentation**.

### Bar Structure (96px tall)
- 3-column grid: `[avatar 76px | player_info flex | minimap 76px]`, 10px padding,
  10px gap.
- Background: vertical gradient `#0e1018 → #1a1a25 (60%) → #14141e`.
- Bottom border: 1px `var(--gold-glow)` (`rgba(255,200,66,0.18)`) + 2px black
  drop-shadow + inset gold sheen on the bottom edge.
- Subtle radial gold haze at top-center (`radial-gradient(ellipse at 50% 0%,
  rgba(255,200,66,0.06), transparent 60%)`).

### Avatar Frame
- 76×76, `r-md` (8px) corners, `COL_PANEL_DARK` bg, **2px gold border**.
- Inner 1px black inset shadow + outer 0/0/12px gold glow.
- Diagonal sheen overlay top-left (135deg gold → transparent at 40%).
- **Level badge:** 26×26 circle, anchored bottom-center half outside frame.
  Radial brown-black fill, 2px gold border, `JANDA_FONT` 13px gold.

### Resource Bars (HP / Shield / MP)
- **3-bar HUD is default** (HUD is 104px tall, each bar 11px). Stack order
  top-to-bottom: HP / Shield / MP. Player has all three at all times.
- Each bar: 3px corners, 1px black border, inset shadow simulating painted
  metal track.
- Fills (2-stop vertical gradient):
  - HP: `#d04545 → #8a1c1c`
  - Shield: `#6dd5e8 → #2978a0`
  - MP: `#4a90d8 → #1e4880`
- Inner highlight on top edge + inset darken on bottom.
- Animated shimmer pass `linear-gradient(90deg, transparent, rgba(255,255,255,0.18), transparent)` cycles every ~3s on the fill.
- Value label `"HP 160 / 150"` centered, 9-10px bold white with prefix +
  current / max, drop-shadow for readability.

### Alternate: Layered HP+Shield (2-bar HUD)
When vertical space is at premium (e.g. landscape, deep popups), HP and
Shield can occupy one bar: Shield paints over HP from the right edge with
1px white-divider seam at the boundary. Result: a single 14px bar where
the cyan slice on top of red shows current Shield. MP stays as second bar.
Total HUD height drops to 88px. Use only when 3-bar doesn't fit.

### Minimap Frame
- 76×76, identical chrome treatment to avatar (gold border, glow, inner shadow).
- Painted minimap image fills the frame.
- **Location label** bottom strip: `JANDA_FONT` 9px gold, centered, with
  shadow. Reads the current location name.
- **Tier badge "D"** anchored bottom-center half outside frame (mirrors level
  badge on avatar side).

### Why Chrome Over Parchment Here
The top HUD overlays every painted scene (location, rift, combat). Parchment
would compete with the painted backgrounds and read as "paper sheet pasted on
top." Chrome reads as forged frame and lets the painted world breathe behind.

## Bottom Nav — 5 Tabs

Fixed 78px-tall bar, dark chrome (same family as top HUD).

### Structure
- 5 equal columns: **Profile · Inventory · Location · Skills · Quests**.
- Each tab: 40×40 painted icon tile + 10px `JANDA_FONT` label below.
- Inactive: muted brown text `#8a7e68`, icon tile `COL_PANEL_DARK`.
- **Active state:** gold border on icon tile, radial brown-glow background,
  outer gold glow, label gold with gold text-shadow, 2px gold rim on the top
  edge of the tab spanning 60% width.

### Notification Pip
- Quests tab supports an 8×8 offense-red pip in top-right of the icon tile.
- Triggers: any quest is `ready_to_turn_in`. Also for Daily refresh: pip flashes
  for 5s on daily rollover.
- 1.5px solid `#0a0a10` ring around pip so it stays legible on gold-active state.

## Painted Pill Tabs (Sub-Tab Family)

Generic blue web-style pill tabs are removed. Two families replace them:

### Chrome Pills (dark family — Inventory/Gear, Skills/Talents)
- Bar background: `var(--panel-darker)`. Each tab fills equally.
- Inactive: vertical gradient `#14141e → #0a0a10`, muted brown label
  (`JANDA_FONT` 13px), 1px black right divider between tabs.
- Active: gold label, vertical gradient `#2a1f08 → #14100a`, 2px gold bottom
  edge with 8px gold glow.

### Parchment Pills (parchment family — Attributes/Professions/Achievements)
- Cream `var(--parchment-bg)` bar with 8px top padding.
- Inactive: muted parchment label `JANDA_FONT` 12px.
- Active: dark `parchment-section-hdr` label + 2px gold bottom-border
  underline.

Rule: chrome pill goes on dark-bg screens, parchment pill goes on parchment-bg
screens. Don't mix.

## Location Hub — Redesigned (2026-05-16)

The painted location backgrounds (Dragon Lair etc.) were being defaced by UI
overlay. Redesign separates **scenery** (painted) from **action** (chrome panels
below).

### Layout (top to bottom, inside the 696px body area)

1. **Hero painted region — 280px contained.**
   - Painted location art fills the region with `object-position: center 30%`.
   - **No actionable UI overlaid on the painting** beyond:
     - Four 28×28 ornate gold L-corner brackets (with gold glow filter).
     - Two 36×36 round travel-nav arrows (left/right, gold border, dark
       translucent fill, backdrop blur). They sit vertically centered, edge-aligned.
     - Bottom-center location identity stack: tier-color tag pill
       (`"TIER 3 · HARD"` in tier color) + location name in `JANDA_FONT`
       22px gold with deep shadow + gold haze.
   - Bottom 40% of hero gets a `transparent → rgba(10,10,16,0.85)` linear
     gradient so the identity stack reads regardless of underlying art.
   - 2px gold bottom-border separates hero from action stack below.

2. **Action stack — fills remaining ~416px, scrollable.**

   Padding 12px, gap 10px between cards. All cards live in `panel-darker`
   background.

   **(a) Quest tracker pill** (always present, swaps state):
   - Tier-bordered (tier of active quest). Story quests get gold border.
   - 3-col grid `[36px icon | meta | chevron]`.
   - Eyebrow "ACTIVE QUEST" in tier color, 9px `JANDA_FONT`.
   - Title 13px, truncated.
   - 4px thin progress bar + count "4 / 10" in tier color.
   - **Empty state:** gold border, eyebrow "NO ACTIVE QUEST", title "Browse
     quests at Northwatch", chevron opens the quest screen.
   - Tap → opens Quest detail (or Quest list if empty).

   **(b) Active activity card** (visible only when activity is running):
   - Border-left 3px `BUTTON_SUCCESS` green. Subtle green glow.
   - 3-col grid `[52px activity icon | info | 36px stop button]`.
   - Eyebrow "GATHERING · ACTIVE" in success green.
   - Name 14px `JANDA_FONT`. 8px progress bar with green gradient fill +
     glow, count "220 / 500" right-aligned.
   - Stop button: red square, 36×36, "STOP" `JANDA_FONT` 11px bold.

   **(c) Activity picker:**
   - Section header row: "AVAILABLE HERE" gold `JANDA_FONT` 12px + right-side
     "N unlocked" count.
   - **3-column grid of activity cards.** Each card 48px ring + name + level.
   - Ring uses SVG circle stroke for XP progress; color matches activity
     accent (herbalism green, mining gold, hunting offense-red, alchemy purple,
     rift arcane, forester gold).
   - Active activity: green border + green glow + green name.
   - Locked activity: 40% opacity, lock emoji overlay, "Lv 12 req" instead of
     current level.
   - Tap → starts the activity (or opens its dedicated screen for crafting).

### What This Solves
- **Progress bar no longer overlays painted background.** Painting is scenery,
  progress lives in chrome card below.
- **Activity hierarchy is real.** You can see all 6 professions at a glance,
  with progress, with level, with locked/active state.
- **Quest entry point exists.** Quest tracker is the first thing you see after
  the painting — quests get prime real estate.
- **Travel improves.** Left/right travel arrows replace "tap minimap → navigate
  away" friction.

## World Map — Waypoint Tooltip (2026-06-03)

The full world map (`scenes/support_screens/map_hud.gd`) shows a hover/touch
tooltip per waypoint. It lists the location's activities and whether THIS player
can do each one. Family: **dark chrome** — it floats over the painted map and
updates with live player state.

### Panel
- `COL_PANEL_BG` background, 2px `COL_PRIMARY` gold border, corner radius 8,
  `COL_GOLD_GLOW` shadow (size 6), 8px content padding.
- Follows the pointer; clamped to the viewport.

### Header
- Location name, `JANDA_FONT` 15px, `COL_PRIMARY` gold, black outline.
- Gold hairline below (1px, gold at 35%) separating header from rows. Same
  separator language as the NPC offer frame.

### Activity rows
Each row: `[accent dot] [status glyph] [name]`, `QUADRAT_FONT` 13px.
- **Accent dot:** 8px circle (stylebox, never a glyph) colored by activity —
  herbalism green, mining gold, woodcutting forester-green, fishing frost,
  hunting offense-red, alchemy arcane-purple, rift arcane. Ties the tooltip into
  the game's activity-color identity.
- **Availability is carried by COLOR + OPACITY** (always renders), with a `✓` /
  `🔒` glyph as a secondary cue in a default-font label (graceful fallback if the
  themed font lacks the glyph — no tofu).
  - **Available:** bright. `✓` green `rgba(60,200,100)`, name cream
    `rgba(245,240,219)`.
  - **Locked:** whole row dimmed to 60% alpha. `🔒` grey, name + `· Lv N`
    (required level) in muted brown.

Mirrors the Location Hub activity picker's locked/available language and the
Requirement Indicators (`✓`/`✗`) spec, so the map and the location screen read
the same way.

### Interaction (info-first, no accidental travel)
- **Touch:** first tap on a waypoint shows its tooltip (info); a second tap on
  the same waypoint opens the travel-confirm dialog. Tapping a different
  waypoint switches the tooltip without traveling. This stops a single tap from
  instantly popping travel.
- **Desktop:** hover shows the tooltip and arms travel, so a single click still
  travels in one go. Gated on `DisplayServer.is_touchscreen_available()` so
  emulated mouse events on phones never arm travel.

## Quest UI — New (2026-05-16)

Quests are a top-level system. Bottom nav gains a Quests tab (with notification
pip support). Two main views: List and Detail.

### Family Choice: Dark Chrome
Quests is a battle-adjacent system (slay, gather, story progression). Lives on
dark chrome bg, NOT parchment. Quest cards use tier color edges matching the
rift/location tier system, not the codex family.

### Quest List View

**Filter chip row** (top, sticky):
- 4 chips: **Active · Available · Daily · Done**.
- Each chip shows count inline (`"Active 3"`). Active chip gets gold border +
  gold glow.
- Daily chip carries an offense-red pip when something refreshed since last view.

**Optional daily reset banner:**
- Visible when Daily filter has unclaimed quests OR within 1h of daily reset.
- Light defense-blue background tint, 11px text "Daily quests reset in [timer]"
  with countdown in `JANDA_FONT` defense-blue.

**Quest card structure:**
- Background `#181822 → #0e0e16` linear gradient, 1px panel border, `r-md`
  corners, 2px shadow.
- **3px tier-color left edge.** Tier 1 green / Tier 2 blue / Tier 3 purple /
  Story gold.
- 12px padding, 8px row gap inside.

**Quest card row 1 — head:**
- 3-col grid `[40px quest icon | title block | level]`.
- Icon: 40×40 `r-sm`, radial fill in quest-type tint (kill=offense-red,
  gather=success-green, story=gold).
- Title block: 9px eyebrow in tier/type color (`"SLAY · TIER 3"`,
  `"GATHER · TIER 2"`, `"CHAPTER 3 · STORY"`) + 14px quest name in
  `JANDA_FONT`.
- Level: 11px `JANDA_FONT` gold, right-aligned, e.g. `"Lvl 17"`.

**Quest card row 2 — progress** (one of two shapes):
- **Multi-objective (gather, kill multiple types):** vertical list of
  objectives. Each: 14×14 check square + label + count. Done objectives strike
  through + green text + green-filled check.
- **Single-objective:** flat 6px progress bar with gold fill + glow + count
  text.

**Quest card row 3 — rewards strip:**
- Horizontal chip row, wraps to 2 lines on small phones.
- XP chip + gold chip in gold, item chips in quality color.
- Chip format: `[icon] [value]`, 10px text, 3px border-radius.

**Quest card row 4 — meta footer:**
- Left: giver name in gold-soft (e.g. `"Captain Vorr"`).
- Right: turn-in location in muted brown (e.g. `"Dragon Lair"`).
- 10px font, dotted top border.

**Special states:**
- **Tracked:** small gold `"TRACKED"` flag in top-left corner (8px font, gold
  bg, dark text). Tracked quest is the one shown in the location hub quest
  tracker pill.
- **Ready to turn in:** gold border on the whole card, gold glow, gold
  `"READY"` pill in top-right corner. Card stands out at any list density.

**Section headers within the list:**
- `JANDA_FONT` 11px uppercase, letter-spacing 1.4px, gold-soft, with gold
  underline at 35% opacity.
- Format: `"⭐ Story"`, `"⚔ Active"`, `"📜 Available"`.

### Quest Detail View

**Header bar:**
- 3-col `[back chevron | quest title block | level]`.
- Title block: tier-color eyebrow + 17px gold quest name.

**Painted illustration:**
- 130px tall, full-width, `r-md` corners, panel border.
- Soft top-to-bottom dark gradient on lower 70% so lore text reads.
- **Lore text overlay** bottom strip: 12px italic `FONDAMENTO` (or
  Godot fallback) cream, 1.5 line-height. One sentence of quest flavor.

**Giver block:**
- 40×40 portrait circle in dark-chrome frame.
- Eyebrow `"GIVEN BY"` 9px muted + name in gold.
- Right-aligned location.

**Objectives section:**
- Section header `"Objectives"` gold `JANDA_FONT` 11px with gold underline.
- Each objective: 36px type-icon + name + thin progress bar + count
  (`"4/10"` in gold).
- Type icon tinted by what's tracked (red for kill, green for gather, etc.).

**Rewards section:**
- 2-col grid for XP and gold (icon + label + value).
- Item rewards full-width, with quality-bordered icon + quality-colored name +
  iLvl note on the right.

**Action buttons:**
- Two equal-width buttons at the bottom: **UNTRACK** (gold chrome) +
  **ABANDON** (red destructive).
- If the quest is `ready_to_turn_in`, a third button **TURN IN** appears
  above these two, gold-filled with strong glow, full width.

### Quest Types (server-defined, displayed consistently)
- `slay` — kill X of monster Y. Single-objective progress bar.
- `gather` — collect N of items A/B/C. Multi-objective checklist.
- `craft` — produce N of recipe X. Single-objective.
- `explore` — reach location L or complete rift R. Single-objective.
- `delivery` — bring item I to NPC N. Single-objective with NPC marker.
- `story` — multi-step chained quest, always tracked, gold edge.

### References
- Diablo Immortal: tier-bordered quest cards, ready-to-turn-in glow.
- Lost Ark: dark quest log with sectioned filters + reward strip.
- Genshin Impact: painted illustration + lore on quest detail.

### Quest Available Tab — NPC Offer Frames (2026-06-02)

The **Available** filter does not render flat quest cards like Active/Done.
Instead it groups offerable quests by the NPC who gives them, so the player
sees *who* to talk to and *what* they offer in one frame. Data comes from the
server `get_available_quests` endpoint (NPCs at the current location + their
offerable quests with full detail). Family: dark chrome, same as the rest of
the quest screen.

**NPC Offer Frame** (one per NPC that has ≥1 offer):
- Card: `#181822 → #0e0e16` gradient, 1px panel border (`COL_PANEL_BORDER`),
  `r-md` corners, 12px padding, 10px row gap. No tier-color left edge here —
  the frame is NPC-scoped, not quest-scoped.
- **Header row** — 3-col `[48px face | name block | _]`:
  - **Face circle:** 48×48, dark-chrome frame, 2px gold border
    (`COL_PRIMARY`), outer gold glow, inner 1px black inset. Same treatment as
    the top-HUD avatar and quest-detail giver portrait. Holds the NPC face
    (codex-authored SVG, `res://assets/npcs/<uid>.svg`; emoji fallback glyph
    when no art).
  - **Name block:** eyebrow `"QUEST GIVER"` 9px `JANDA_FONT` muted brown +
    NPC name 16px `JANDA_FONT` gold (`COL_PRIMARY`).
  - Gold hairline (gold at ~35% opacity) under the header, full width.
- **Offered-quest rows** (stacked, 8px gap, dotted divider between):
  - Row head: 36px type-tint icon (story=gold, craft/gather=success-green,
    slay=offense-red) + title 14px `JANDA_FONT` + level `"Lv.1"` 11px gold
    right-aligned.
  - Eyebrow: 9px type/repeat tag (`"CRAFT"`, `"DAILY · CRAFT"`) in type color.
  - Description: 12px muted brown `rgba(140,130,110)`, clamp 2 lines.
  - Reward strip: existing quest reward chip row (XP/gold in gold, item chips
    in quality color, 10px text, 3px radius).
  - **Accept button:** gold embossed gradient (`var(--gold) → #c89030`), dark
    text `#14100a`, `JANDA_FONT` 12px, ~96px wide, right-aligned. The
    primary-CTA emboss pattern (same as "ENTER THE REALM"). Tap →
    `accept_quest`; on success the quest leaves Available and appears in
    Active.
- **Empty state:** `"No quest givers here.\nExplore to find more."` (muted
  brown, centered) when the location has no offerable quests.

**Section header:** reuse `"📜 Available"` (`JANDA_FONT` 11px uppercase,
letter-spacing 1.4px, gold-soft, gold underline at 35%).

**Why NPC-grouped, not flat cards:** Available quests are a *discovery* surface
("who can I talk to, what's on offer"), distinct from Active/Done which track
quests you already own. Grouping by giver mirrors the in-world act of visiting
an NPC, and scales cleanly as locations gain more NPCs.

## Activity Sub-Badge (Under Avatar)

When the player is mid-activity that has its own screen-context (Rift Explorer,
Crafting in progress), a small chip appears under the avatar in the top HUD:

- 16px circular activity icon (radial gradient in activity accent color) +
  10px `JANDA_FONT` activity name.
- Background: black at 40%, 1px gold-glow border, 10px corners.
- Tap → opens the activity's screen (e.g. tap "RIFT EXPLORER" → opens Rift Active).
- Replaces the floating orange "Rift Explorer" label currently in client.

## Login Screen

The login is the first painted impression. Painted forest-path background
fills the screen edge-to-edge with bottom-aligned card and top-aligned title.

### Title Mark (top center)
- 44px `JANDA_FONT` gold "WalkAura" with strong shadow + outer gold glow +
  outer gold haze. Flanked by `✦` ornament glyphs in gold-soft.
- Tagline below: 14px `FONDAMENTO` italic cream "Walk · Explore · Grow".
- Anchored ~80px from top.

### Ornate Card (bottom area)
- Anchored 90px from bottom, 16px side margins.
- Background: vertical gradient near-black (`rgba(20,22,30,0.94) → rgba(10,12,18,0.96)`).
- 1px gold border, 12px outer gold glow, inset 1px gold sheen on top.
- 4× corner brackets (24px L-shaped, 2px gold, drop-shadow gold glow) on all
  corners. Same treatment as location hero corners.
- Inputs: gold-soft left edge (2px), inset shadow track, focus state ramps to
  full gold + gold glow.
- Input label: 10px `JANDA_FONT` gold-soft uppercase.

### Primary CTA — "ENTER THE REALM"
- Full-width 14px button, gold gradient `var(--gold) → #c89030`, embossed
  (light top sheen + dark bottom border), gold halo.
- 14px `JANDA_FONT` letter-spacing 1.5px, dark text `#14100a`, sword `⚔`
  glyph prefix.
- Replaces flat green "Play" button.

### Secondary CTA — "Create New Account"
- Outlined gold-soft border, transparent fill, gold-soft 11px text.
- "OR" divider with hairline-rules on either side.

### Atmospheric Motes
- 4-5 small 1-3px gold dots scattered over the painting with `box-shadow`
  glow. Float/drift animation in Godot. Sells "magic" without altering art.

### Version Tag
- Bottom-right, 9px muted gold on transparent. `JANDA_FONT`. Format:
  `"v0.2.6.78 · Server 0.2.6"`.

## Skills Screen — Updated

Family: dark chrome (same surface as Talents/Inventory).

### Equipped Row
- "EQUIPPED" header row 10px gold `JANDA_FONT` + inline instruction "Tap a
  spell below to slot · Long-press to remove" in muted brown.
- 6 equal slots, aspect 1:1, 1.5px gold-soft border, gold-glow outer halo.
- Each slot has a hotkey number badge top-left (1-6).
- Equipped slot recolors to school: fire-bordered + fire glow, frost-bordered
  + frost glow, etc.
- Empty slots: dashed white-12% border, 50% opacity, no glow.

### Class Tabs
- Parchment-style underline tabs above school chips: Mage · Paladin · Utility
  · Blood · Dark · Arcane. Active class = gold label + gold underline.

### School Filter Chips
- Rounded pill row (horizontal scroll). Each chip: 8px school-color dot +
  school name in `JANDA_FONT`.
- Inactive: panel-dark bg, muted brown text.
- Active: school-tinted bg + matching color text + matching border.
- "All" chip uses gold treatment.
- Multi-select (multiple schools can be active at once).

### Spell Card (2-col grid)
- 44px school-bordered icon + name (school-colored) + 1-line cost row +
  1-line effect.
- Cost row mini-chips: `M 6` (frost-color), `⏱ 1.5s` (gold-soft),
  `CD 0s` (offense), `HP 4` (blood) — colors signal cost type.
- Effect line in success-green for damage, defense-blue for shield, etc.
- Equipped spell: 2px school left-edge + gold-glow outer halo + gold `★`
  corner badge.

## Talents Screen — DRAFT (not approved)

> Status: 2026-05-16 — user reviewed mockup, not sure on radial vs grid.
> Section kept for reference only. Do not implement until direction picked.


Family: dark chrome with radial dark backdrop. Removes prior loose tree.

### Header Panel (50px tall)
- 2-stat block: SPENT (success-green) + AVAILABLE (gold), 10px label +
  18px value `JANDA_FONT`.
- Right: 3 buttons — `+ 1`, `+ 5`, `RESPEC` (destructive-red outline).
- Replaces loud `[- 0 +]` cluster + green "94 spent" pill.

### Class Emblem (center)
- 64×64 circle, gold border, radial dark fill, 24px gold glow halo, inner
  gold sheen.
- Centered icon (e.g. 🔮 for Mage) + class name "MAGE" 11px `JANDA_FONT`
  letter-spacing 1.5px gold.
- Replaces the mystery black ring with nothing inside.

### Radial Branches (4)
- FIRE (top) / FROST (right) / ARCANE (bottom) / DARK (left).
- Branch labels at canvas edges, 10px `JANDA_FONT` uppercase, letter-spacing
  1.5px, colored to school.
- 2-3 nodes per branch, arranged in arc-like positions.

### Connector Lines (SVG)
- Solid 2px school-colored line for active/learned paths.
- Dashed 1.5px muted line for unlearned/locked paths.

### Talent Nodes
- 52×52 square, `r-sm` corners, icon centered.
- States:
  - **Locked:** 35% opacity + grayscale, no glow.
  - **Available:** full color, panel border, soft hover scale.
  - **Partial (some ranks invested):** school-colored border + soft school glow.
  - **Maxed:** gold border + radial brown bg + 12px gold glow + inner
    gold sheen.
- **Rank chip:** small 8px-padding pill above the node showing `"2/3"` or
  `"3/3"`. Maxed = filled gold; partial = gold outline; locked = grey.
- Name label below node: 9px `JANDA_FONT` gold-soft, drop-shadow.

### Hint Footer
- Bottom strip: "Tap node to invest · Long-press for details" in 10px
  muted brown.

## Attributes — 3 Sub-Tabs Spec

Family: parchment (codex/study). The Attributes tab gets 4 sub-tabs:
**OFFENSIVE · DEFENSIVE · STEPS · SUSTAIN**.

### Primary Stat Strip
Persisted on every sub-tab. 3x2 grid of compact cells (STR/AGI/VIT row 1,
INT/SPI/LCK row 2). Each cell: 26px stat-color radial icon + label + value
`+ bonus` (bonus in success-green). 2px stat-color left edge.

### Sub-Tab Bar
4-segment painted control (chrome-tinted in their own colors):
- OFFENSIVE: gradient `var(--offense) → #c84020`, white text on active.
- DEFENSIVE: gradient `var(--defense) → #1e7ab0`, white text on active.
- STEPS: gradient `var(--gold) → #c89030`, dark text on active.
- SUSTAIN: gradient `var(--btn-success) → #2a601e`, white text on active.
- Each tab has an icon glyph + uppercase label.

### Summary Bar (per sub-tab)
- 3-cell horizontal grid showing the 3 most-used high-level stats for the
  current sub-tab. Cream gradient bg, 3px gold left edge.
- Examples:
  - Offensive: Phys ATK / Magic ATK / Crit %
  - Defensive: Phys DEF / Magic DEF / Dodge %
  - Steps: Total / Buffer / Avg
  - Sustain: HP Regen / Life Steal / Heal Power

### Rating Rows
- Sectioned with 10px gold underlined `JANDA_FONT` headers (e.g. "⚔ Combat
  Ratings", "✨ Damage Amplifiers", "🛡 Mitigation", "🌈 Resistances",
  "⚕ Regeneration", "🩹 Combat Sustain", "🌿 Healing").
- Each row: 22px icon + name + value `JANDA_FONT` + percent.
- 2px sub-tab-color left edge (offensive=red, defensive=blue, etc.).
- **Zero values dim to 55% opacity** so non-zero stats jump out.
- **Hi values (notable highs) get success-green value text** so player
  spots their strongest stats.
- Element-tinted rows (Damage Amplifiers, Resistances) use element colors
  as left-edge (fire/frost/arcane/dark/blood/holy) — matches school colors
  used in Skills.

## Rift Suite — Updates (2026-05-16)

Builds on existing rift spec. Refines hero treatment, encounter card, fight
result, replay, and history per latest implementation review.

### Entry Screen
- Painted portal art **capped to 200px** (not 40% of viewport), with
  tier-colored corner brackets (4× L-corners, 22px, glow-tinted).
- Tier pill + rift name overlay bottom-center of art with deep shadow +
  tier-tinted glow.
- Painted close `×` button top-right, 28×28, destructive red.
- Lore inset block moves to **directly below art** (not buried under reqs).
- Requirement cards stay 2-col with green/red border by met/unmet state,
  prominent `✓` / `✗` glyph on right, `JANDA_FONT` value bold.
- Summary row: encounter count + steps left of `Gear Score X–Y` in gold.
- Big tier-colored ENTER button with gradient + emboss + glow (replaces
  flat green). "RIFT HISTORY" downgrades to text link.

### Inside Rift (Active)
- Hero art **further shrunk to 140px** — player is inside, art is contextual.
- Progress bar: 16px tall, painted (inset shadow track, gradient fill with
  inner highlight + outer tier glow). Meta line below: "2,000 / 4,000 steps"
  left, "50% · Milestone 0/4" tier-colored right.
- **Node path moved into its own bordered chrome panel.** Was floating
  unframed. Diamond glyphs sized up (22px), current node pulses with
  tier-color glow.
- **Active activity sub-badge** appears under avatar in top HUD when the
  player is in a rift ("RIFT EXPLORER" pill, see Activity Sub-Badge above).
- **PAUSE / EXIT buttons** shrink to single-row, color-coded (amber pause,
  red exit), no longer dominate vertical space.

### Encounter Card (Inside, when pending fight)
- 2px offense-red border + 12px red glow + inset red sheen — eye-grab.
- Header: "⚔ ENCOUNTER #N" in offense red `JANDA_FONT` 14px with red
  text-glow + enemy count on right.
- Enemy rows: 32px icon + name + Lv + role pill (DPS/TANK/HEALER, colored).
- Resist chip row: small element-tinted chips ("🌑 DARK" purple).
- "⚔ FIGHT NOW" CTA: full-width red embossed + red glow. Primary action.
- Stops the floating "+2000 steps" floating debug text in the existing
  screen — kill it.

### Victory / Fight Result
- "VICTORY" mark: 32px `JANDA_FONT` gold with gold halo +
  flanking gold rule lines (mini fanfare, not celebration overkill).
- "DEFEATED" mark: same treatment in error-red.
- Sub-line: 12px `FONDAMENTO` italic flavor ("Encounter #N · The breach
  quiets").
- **HP / XP / Gold deltas in 3-cell row.** Currently 2 stacked rows of
  small text — gives the moment visual weight.
- Combat Stats: 2-col label/value grid, value-colored by impact (damage=red,
  taken=blue, gold=gold, neutral=grey).
- **Loot row is the upgrade**: quality-bordered 40px icon + quality-color
  name + stats line + iLvl. Currently shows only "1 equipment dropped!" —
  underselling rewards.
- Node path at bottom shows updated rift progress.
- Full-width gold CONTINUE button.

### Battle Replay (parchment family)
- Header: "BATTLE REPLAY" + "Encounter #N · VICTORY/LOSS" subhead with
  semantic color.
- **Combat snapshot strip** (new): both portraits + HP/Shield mini-bars
  with values, VS glyph between. Persistent during replay so player tracks
  state at a glance.
- **Tick progress bar** (new): playback head shown as a gold bar.
- Log entries: 38px tick column + 22px event-icon column + structured
  description with color-coded actors (`player` green, `enemy` red, `spell
  name` purple italic) + right-aligned resource state (P:160 M:82).
- Crits: gold-tinted row bg + bold gold damage.
- Dodges: defense-blue text + 💨 icon.
- Deaths: red-tinted row bg + bold red text.
- Controls: Pause / Restart / Speed (1x/2x/4x toggle) / Tick info, in
  parchment-darker footer.

### Fight Log (Detailed, parchment)
- Same family + log treatment as replay, minus controls.
- Header includes "Watch Replay" purple button → opens replay screen.

### Rift History (chrome family)
- Sticky search + filter chips top (All/Won/Died/Abandoned).
- Cards **grouped by date headers** (gold `JANDA_FONT` underlined
  "TODAY · 2026-05-16", "APR 17", etc.). Replaces wall of identical
  uniform cards.
- Card: tier-colored left edge + 32px tier-radial icon + rift name + Lv
  + inline "Fights N/M · Won X · Deaths Y" + status pill on right.
- Status pills: CLEARED (success green), ABANDONED (amber), DIED (error red).
- Tap card → opens detail with fight list (existing pattern).

## Gear Screen — Redesign (2026-05-16)

Family: parchment (codex/study, like Inventory). Hero is the player's
character + their equipment state. Two surfaces collide in the current
implementation (decorative slot colors vs quality colors); spec collapses
to a single semantic: **slot color = equipped item's quality**.

### Layout (top to bottom)

1. **Gear Score Ribbon** (60px)
   - 3-col grid: left meta / center gold disc / right meta.
   - Left: "Slotted N/16" + "Avg iLvl X".
   - **Center disc:** 2px gold border, radial brown bg, gold glow halo. "GEAR
     SCORE" 9px gold-soft label + 26px `JANDA_FONT` gold weight 700 value
     with gold text-glow. This is the hero stat — eye-grabbing.
   - Right: "Upgrades: ↑ N in bag" (success-green when > 0) + "Empty: N slots".
   - When comparing (item picked from inventory), the score preview animates
     to the projected new value ("142 → 156 +14") in success-green.

2. **Paper Doll Row** (320px) — 3-col grid: `[56px slots | doll viewport | 56px slots]`
   - Left col, top to bottom: Head · Shoulder · Back · Chest · Wrist · Ring · Trinket · Main Hand
   - Right col: Neck · Gloves · Belt · Legs · Feet · Ring · Trinket · Off Hand

3. **Stat Preview Card** — "From Gear" — 6 derived stats from equipped items

### Equipment Slot (56×64)
- Parchment-card bg, 1.5px border, `r-sm` corners, light inner sheen.
- **Quality-tinted border + glow** based on equipped item's tier (q1 white,
  q2 green, q3 blue, q4 purple, q5 orange, q6 gold). No equipped item =
  dashed 18%-black border, transparent bg.
- 24-26px item icon centered.
- **Label below** (8px `JANDA_FONT`), colored to match quality.
- **iLvl pip** corner: small `#2a1f08` chip with gold border showing item
  level (e.g. "22") top-right.
- **Gemmed mark**: `✦` arcane-purple glyph bottom-right when socketed.
- **Upgrade badge**: green `↑` circle top-left when a better-iLvl item of
  matching type exists in inventory.
- **Empty silhouette**: 18% opacity grayscale icon of expected item type
  (faded helmet for Head, faded ring for Ring slots, etc.).

### Slot ↔ Quality Color Bridge
This is the rule that fixes the current "two color systems collide" problem:

- **The slot's visual decoration is fully driven by the equipped item's
  quality.** Empty slot = neutral dashed. Equipped epic = purple border +
  purple glow + purple label.
- Slot semantic colors that exist in current implementation (decorative
  per-slot tints) are removed.
- Player can scan the whole doll and instantly count "I have 2 purples,
  1 mythic, 3 commons" without reading any text.

### Doll Viewport
- Painted character image, drop-shadow grounding.
- Subtle radial gold glow under doll feet to anchor figure.
- No floating UI controls over the doll — the painting reads cleanly.

### Stat Preview
- "⚔ From Gear" gold-edged card with 6-stat grid (Phys ATK / Magic ATK /
  Phys DEF / Dodge / Crit / Haste — most-relevant 6 derived stats from gear).
- Each value: base value + delta chip when comparing (`+3` success-green
  for upgrade, `-2` error for downgrade).
- Subtitle "Tap inventory item to compare" when neutral.

### Compare Overlay (when inventory item picked)
- Anchored bottom of body area, 1px quality-bordered card with glow.
- Header: "COMPARE · [SLOT_NAME]" + close `×`.
- 3-col grid: `[equipped | → | candidate]`.
- Each side: small eyebrow (EQUIPPED / CANDIDATE · QUALITY), icon row,
  iLvl line, 3-stat table.
- Bottom: **delta pill row** — 3 most-impactful stat changes as colored
  pills (success-green for upgrades, error-red for downgrades, including
  computed gear-score delta).
- Big `EQUIP [ITEM NAME]` button colored to candidate's quality.
- Tapping outside dismisses.

### Empty-Slot Tap Flow
- Tap empty slot → opens Inventory tab pre-filtered to that slot type
  (Head shows only helmets, Ring shows only rings, etc.).
- Eliminates "scroll through 27 items hunting for a chestpiece" friction.

### References
- Diablo Immortal: paper doll + slot quality borders + stat preview pane
- WoW: empty-slot silhouettes + upgrade-available indicators

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
| 2026-05-16 | Top HUD chrome redesign | Replaced flat-gray placeholder bar with dark-chrome gradient + gold ornament. Avatar/minimap get 2px ornate gold frames with inner shadow + outer glow. HP/MP bars become painted (gradient fill, inset shadow track, animated shimmer). Bottom nav gains painted-icon active state with gold rim glow and notification pip support for Quests tab. Triggered by full-screen design audit revealing the gray placeholder HUD was the single biggest visual debt across every screen. |
| 2026-05-16 | Sub-tab pill split: chrome vs parchment | Generic blue web pills removed across Inventory/Gear, Skills/Talents, Attributes/Professions/Achievements. Two families: chrome pills (dark bg, gold underline glow) for dark-chrome screens; parchment pills (cream bg, gold underline) for parchment screens. Rule: pill family matches screen family — never mix. |
| 2026-05-16 | Location hub redesign | Painted location backgrounds were being defaced by overlaid UI (activity progress bar on cobblestone, loose profession icons floating). New layout: painted hero is contained 280px region with gold corner brackets, no actionable UI overlaid. Action stack lives in dark-chrome panels BELOW the hero: quest tracker → active activity card → 3-col activity picker grid with XP progress rings. Adds travel arrows on hero left/right for quick zone hop. Mockup: `WalkAura_client/design-mockups/location.html`. |
| 2026-05-16 | Quest system UI added | New top-level Quests tab with notification pip. List view: 4-chip filter (Active/Available/Daily/Done) with counts + Daily reset timer banner. Quest cards use tier-color left edge (matches rift/location tier system), 4-row layout (head/progress/rewards/meta), special states for tracked + ready-to-turn-in (gold glow). Detail view: painted illustration with lore overlay, giver block, objectives, rewards grid, Untrack/Abandon/Turn-in actions. Family: dark chrome (not parchment) — quests are battle-adjacent. References: Diablo Immortal, Lost Ark, Genshin. Mockup: `WalkAura_client/design-mockups/quests.html`. |
| 2026-05-16 | Inventory quality borders mandatory | Existing styler defines 7 quality tier colors but inventory was rendering all slots with plain dark frames. Spec now requires every inventory slot to apply 1.5px quality-color border + matching inset glow (8-12px based on tier). Empty slots use dashed 6%-white border, not solid frame. Single-cost change with biggest single-screen visual improvement. |
| 2026-05-16 | 3-bar HUD: HP / Shield / MP | HUD grows to 104px to fit a dedicated Shield bar (cyan gradient, between HP red and MP blue). Each bar 11px. Alternate layered mode (88px HUD, HP+Shield share one bar via right-painted shield overlay) defined for landscape/tight-space contexts. Triggered by user noting shield was missing from initial 2-bar mockup; shield is a first-class resource (shield_absorb, frost_shield, etc. all act on it). |
| 2026-05-16 | Skills screen redesign | Painted spell cards in 2-col grid (school-color border + tinted name), parchment class tabs above rounded school chips (with school-color dots), equipped row with hotkey labels + school-tinted glow, equipped spells get gold star + halo. Replaces dense list with no rhythm + bold-text school headers. |
| 2026-05-16 | Talents redesign: class emblem + radial branches | Mystery black ring at center replaced by gold-bordered glowing class emblem (icon + class name). 4 branches (Fire/Frost/Arcane/Dark) splay radially with cardinal-edge labels. SVG connector lines (solid school-color for learned, dashed muted for locked). Every node carries a "X/Y" rank chip — maxed=gold-filled, partial=outline, locked=grey. Header gains +1/+5/RESPEC buttons replacing loud `[- 0 +]` cluster. References: Path of Exile passive tree + WoW classic talent trees. |
| 2026-05-16 | Attributes sub-tab system (Off/Def/Steps/Sus) | Painted segmented sub-tab control where active tab fills with sub-tab's accent color (red/blue/gold/green). Each tab gets a 3-cell summary bar of top stats + sectioned rating rows with sub-tab-color left edges. Zero values dim to 55%, hi values get success-green text. Element rows use school colors as edges (matches Skills). Primary stat strip stays visible across all sub-tabs. Triggered by user adding Sustain + Defensive + Offensive screenshots which were undifferentiated plain text lists. |
| 2026-05-16 | Login screen polish | "WalkAura" title becomes ornate gold mark (44px Cinzel + flanking ✦ + outer gold glow). Form card gets 4 gold corner brackets + inner gold border + outer halo to match location hero treatment. "Play" button replaced by gold-embossed "ENTER THE REALM" with sword glyph. Fondamento italic tagline. Atmospheric gold motes scattered over painting. Replaces flat green Bootstrap-style button + plain rounded card. |
| 2026-05-16 | Activity sub-badge under avatar | Small pill under avatar shows current activity (e.g. "RIFT EXPLORER" with arcane icon) when player is mid-activity that has its own screen context. Replaces current floating orange "Rift Explorer" label that sits awkwardly between resource bars. Tap → opens activity screen. |
| 2026-05-16 | Rift entry/active/victory polish | Entry: hero art capped 200px with tier corner brackets + lore moved directly below art. Active: hero shrinks to 140px (player is inside, art is contextual), node path moves into its own bordered chrome panel, PAUSE/EXIT shrink to single row. Encounter card: 2px offense-red border + glow + structured enemy rows with role pills + resist chips. Victory: deltas become 3-cell row, loot row gets quality-bordered icon + colored name + ilvl (replaces "1 equipment dropped!" plain text). Kill the floating "+2000 steps" debug overlay. |
| 2026-05-16 | Battle Replay combat snapshot + tick progress | Replay screen gains persistent combat-snapshot strip at top (both portraits + HP/Shield mini-bars + VS glyph) + tick progress bar showing playback head. Log entries gain tick column + icon column + color-coded actors (player green, enemy red, spell purple italic). Crit rows gold-tinted, dodge rows blue, death rows red-tinted. Replaces unstructured text log. |
| 2026-05-16 | Rift History grouped + searchable | Replaces uniform "Infernal Rift × 9" cards with sticky search + filter chips + date-grouped cards. Each card: tier-colored left edge + tier-radial icon + Lv tag + inline metrics + status pill (CLEARED green / ABANDONED amber / DIED red). Triggered by current implementation being unscannable when player has many history entries. |
| 2026-06-10 | Activity status panel → slim 2-row HUD strip | Old panel: ~25% viewport, left-hugging label rows with dead right half, XP bar hidden until first tick, bright-red centered STOP blob. New: row 1 = gold title ("Hunting · 43") + full-width painted XP bar (always visible, even at 0) + inline XP text; row 2 = compact stat chips (Steps/Actions/XP, thousands-separated) + small dark-red square stop button (gold square glyph, gold-on-dark per destructive token) right-aligned. Reclaims ~200px vertical for the painted hero. Rationale: activity status is glanceable state, not a dashboard; vertical space is the scarcest mobile resource. |
| 2026-06-10 | Activity status → HUD capsule (supersedes 2-row strip for running state) | Sub-badge under HP/SH/MP bars becomes a tap-to-expand capsule: icon disc + "Hunting · 43" + 6px gold XP sliver. Tap → dark-chrome flyout with session chips (Steps/Actions/XP) + STOP (dark-red, deliberate). Hub's bottom panel demoted to travel progress + skill-lock warnings only; active-unlocked state never occupies the bottom of the screen. Stop guarded behind one tap = accidental-stop protection; capsule visible on every screen (HUD is global). Respects the 2026-05-16 "no actionable UI overlaid on painted hero" rule — flyout is opt-in and anchored to HUD chrome. |
| 2026-05-16 | Login: Google sign-in added; sword glyph removed | "Continue with Google" white button (conic-gradient G mark, brand correct) added between primary login and "Create New Account" so existing players skip the form. Sword `⚔` glyph removed from primary CTA — distracted from the gold mark + emboss treatment which is doing enough work on its own. User picked the ornate-framed variant; minimal-glass variant dropped from mockups. |
| 2026-05-16 | Talents spec marked DRAFT | User reviewed radial-branch mockup but uncertain on direction. DESIGN.md section flagged DRAFT until grid-vs-radial picked. Do not implement. |
| 2026-05-16 | Gear screen redesign: slot color = item quality | Current implementation has two color systems colliding (decorative per-slot tints AND item quality tiers). Spec collapses to one rule: **slot border/glow/label color is fully driven by equipped item's quality**. Adds Gear Score ribbon (hero stat with gold-disc treatment), iLvl pips per slot, empty-slot silhouettes at 18% opacity, upgrade indicator badges (green ↑ when better item in bag), 6-stat preview panel, and inventory compare overlay with delta pills + one-tap equip. Empty-slot tap pre-filters Inventory to that slot type. References: Diablo Immortal, WoW upgrade indicators. |
| 2026-05-16 | Gear: doll tools, loadouts, set bonuses dropped | User scoped down: rotate/zoom/hide-armor doll buttons removed (clean painting beats transmog preview at v1), loadout chips removed (YAGNI for solo mobile RPG without PvP build-swapping), set bonuses removed (gear system doesn't ship sets yet). Gear Score ribbon right-column reorganized: Upgrades + Empty slots replace Set Bonus + Upgrades. |
| 2026-06-07 | Location hub edge bars: Activities + People drawers | Activity picker grid and on-hub NPC discovery move off the vertical action stack into two independent right-edge drawers. Closed = thin gold vertical-text rails (ACTIVITIES top, PEOPLE bottom). Tap → drawer slides left over the painted hero with a 55% scrim (220ms ease-out). Activities drawer reuses the 3-col XP-ring picker verbatim; People drawer becomes the canonical NPC home reusing the NPC Offer Frame spec. Both drawers open independently (most-recently-opened on top, rear drawer's rail stays docked over the scrim, 8px left-offset keeps both rails reachable). Hub main column keeps only live state (quest tracker pill + active-activity card); painted hero reclaims the freed vertical space. Reconciles the May-16 "no UI on painting" rule → "no PERSISTENT UI on the painting; dismissable edge drawers may overlay while open." Full spec: "Location Hub — Edge Bars" section. |

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

### Tier Tabs (2026-06-07 — replaces stacked sections)
Tiers are now **tabs**, not stacked sections (mirrors the Skills screen). A
segmented parchment pill bar sits under the trophy wall; only the active tier's
cards render below it.
- Tabs (left → right): **Easy · Normal · Hard · Impossible · Hidden**, mapping to
  server tiers 1·2·3·4(Meta)·5(Secret). "Medium" displays as "Normal"; **Meta now
  gets its own "Impossible" tab** instead of folding into its parent tier.
- Pill style: parchment segmented (active = tier-accent fill + white text,
  inactive = cream `rgba(220,210,190)` + thin tinted border; first/last segments
  round out 4px). Accent per tab: Easy bronze, Normal silver, Hard gold,
  Impossible crimson (`COL_OFFENSE`), Hidden mythic-purple.
- Each tab shows its reward-hint subtitle above the cards; empty tiers show
  "No achievements in this tier yet." Secret cards still render as "Hidden
  Achievement", never `???`.

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

## Location Hub — Edge Bars (Activities + People) — 2026-06-07

**Family: dark chrome.** Two right-edge drawers replace the inline *discovery*
surfaces on the location hub. They sit in front of the painted world and update
with live player state, so they read as ambient game HUD, not screen content —
same chrome family as the top HUD and tab bar.

### Intent
The May-16 redesign moved discovery (activity picker grid, NPC offers) into a
tall vertical scroll BELOW the painted hero. That works but pushes the painting
up and buries the action. Edge bars pull discovery off the scroll and dock it on
the screen edge: **closed, they're two thin gold rails; open, they're full
sheets.** The hub's main column then carries only *live state* — the quest
tracker pill and the active-activity card — and the painted hero reclaims the
freed height.

Discovery (browse activities / meet people) lives on the edges. Live state
(what you're doing now) stays inline. That's the dividing rule.

### Anatomy

**1. Edge rail — closed (the dock)**
Two rails stacked on the right screen edge, splitting the body height: **Activities
rail = top band, People rail = bottom band.** Each rail ~36px wide.
- Surface: dark chrome `COL_PANEL_BG #101218` @ ~92% (a touch more opaque than
  panels — it rides the painting edge), 1px left border `COL_PRIMARY` @ 25%,
  gold hairline (@20%) splitting the two rails, top-left + bottom-left corner
  radius 8px only, `COL_GOLD_GLOW` shadow size 4 toward the painting.
- Content (rotated −90°, reads bottom-to-top):
  - 18px family icon at the outer (screen-edge) end.
  - Vertical label `"ACTIVITIES"` / `"PEOPLE"` (use PEOPLE, not NPCS — in-world
    + shorter), `JANDA_FONT` 12px, uppercase, letter-spacing 1.4px,
    `COL_PRIMARY` gold.
  - Left-pointing chevron `‹` 14px gold at the inner end — the "pull me" affordance.
  - Count disc near the icon: Activities rail = "N" unlocked-here count;
    People rail = quest-giver count. 14px dark disc, 1px gold border (reuse the
    "N unlocked" semantics from the picker header).
- Touch: visually 36px, hit area extended to 44px leftward (transparent) per the
  44px touch-min rule.
- Accent stub: 3px colored bar at the icon end. Activities rail = neutral gold;
  flips to `BUTTON_SUCCESS` green + soft glow when an activity is ACTIVE (mirrors
  the active-activity language). People rail = gold; pulses gold when a fresh /
  re-available offer exists.

**2. Drawer — open (the sheet)**
- Slides in from the right over the hero, **~25% of screen width** (a narrow side
  panel, hero stays mostly visible), with a 10px gap between the drawer and the
  rail so it reads as a floating frame, not flush to the edge. Slide 220ms
  ease-out (medium); close 180ms ease-in (Motion spec).
- Because the drawer is narrow, the marker grids are **2-column** (not the hub's
  old 3-col), keeping the 72px markers readable.
- Scrim: black @ 55%, fades 150ms. Tap scrim or the originating rail (now flush
  to the drawer's left) to close; Android back / Esc closes the top drawer.
- Surface: dark chrome panel `COL_PANEL_BG #101218` @ 90%, 2px left border
  `COL_PRIMARY` gold, `COL_GOLD_GLOW` shadow size 8, top-left + bottom-left
  corner radius 10, 12px content padding.
- Header: 3-col `[24px family icon | title JANDA_FONT 18px gold | close ✕ 28px]`,
  gold hairline (@35%) below (same separator language as the NPC frame + map
  tooltip).
- Body: vertical scroll.

**Activities drawer body** — the existing **Activity Picker** spec, lifted verbatim:
- Section header `"AVAILABLE HERE"` gold `JANDA_FONT` 12px + `"N unlocked"` right.
- 3-col grid of activity cards (48px XP ring + name + level), ring colored by
  activity accent (herb green, mine gold, hunt offense-red, alch arcane-purple,
  rift arcane, wood forester-green, fish frost). Active = green border + glow +
  green name; locked = 40% opacity + lock + `"Lv N req"`. Tap starts the activity
  (or opens its dedicated screen for crafting).
- Implementation: reparent the existing `_build_activity_grid()` panel from the
  hub `VBox` into the Activities drawer rather than rebuilding it.

**People drawer body** — the **NPC Offer Frame** spec, lifted verbatim. This is now
the **canonical NPC home** on the hub; the Quest screen's "Available" tab defers
to it later.
- One Offer Frame per NPC: 48px gold-bordered face circle + `"QUEST GIVER"`
  eyebrow + name 16px gold; gold hairline; stacked offered-quest rows (type-tint
  icon, title, `Lv.N` chip, type eyebrow, 2-line muted-brown desc, reward chip
  strip, gold-embossed `Accept` button).
- Empty state: `"No one's here.\nExplore to find more."` (muted brown, centered).
- Data: `SignalManager.signal_LocationNpcsReceived` (already wired in
  `location_hub.gd`) + `get_available_quests`.

**3. Both-open behavior** (decision: bars open *independently*)
- Each drawer owns its open/closed state; opening one does NOT close the other.
- Render order = most-recently-opened drawer on top (higher z); the shared scrim
  sits directly under the top drawer.
- A rear (open-but-covered) drawer keeps its rail docked at the screen's right
  edge ABOVE the scrim, so a tap brings it forward (swap z). Closing the front
  drawer reveals the one beneath.
- Only the frontmost drawer is interactive; the rear one is dimmed by the scrim.
- **Mobile mitigation** (the two-overlapping-sheets risk, flagged at decision
  time): the second drawer opens 8px right of the first so a sliver of the rear
  drawer + both rails always show. If width gets cramped, fall back to bringing
  the tapped drawer fully forward (single visible sheet) instead of true stacking.

### Hub main column after the move
- Painted hero region may grow — it no longer shares the body with a tall picker
  grid.
- Inline cards reduce to: **quest tracker pill** + **active-activity card** (live
  state stays on the page).
- The inline 3-col activity picker is REMOVED from the scroll stack (it lives in
  the Activities drawer now). The active-activity card stays inline because it's
  live state, not discovery.

### Tokens (all from `styler.gd`)
`COL_PRIMARY #FFC842` · `COL_PANEL_BG #101218` · `BUTTON_SUCCESS #3CC850` ·
activity accents per above · `JANDA_FONT` titles · `QUADRAT_FONT` body · 8px base
unit · 44px touch min.

### Why this works / what it costs
- **Reclaims the painting** (the May-16 goal): closed state is just two thin gold
  rails; discovery overlays only on demand and dismisses.
- **Discovery is one thumb-tap, always in the same place**, from anywhere on the hub.
- **Cost:** a drawer overlays the painting while open (accepted — it's
  dismissable, unlike the old persistent floating markers). Two-open mode adds
  z-order/close complexity, mitigated by the offset + pinned-rail model above.

### Anti-patterns rejected
- Persistent UI baked onto the painting (the exact debt May-16 removed).
- Two full-width sheets stacked with no offset (close targets get fiddly on a phone).
- A single mixed drawer that buries activities and NPCs under one ambiguous label.

### Scope update (2026-06-07, later)
**People drawer dropped.** The location hub now ships a **single** edge bar —
Activities only. NPCs are not shown on the hub; they stay reachable via the Quest
screen's Available tab (NPC Offer Frames). The `get_location_npcs` fetch and the
on-hub NPC markers were removed from `location_hub.gd`. The two-bar /
both-independent / rear-peek machinery below is retained in code (the drawer state
machine is generic) but only one drawer is instantiated. Rails switched from
`Panel`+`gui_input` to `Button`+`pressed` for reliable taps; drawer width is ~25%
of screen with a 10px gap to the rail.

### Implementation status (2026-06-07)
Shipped in `location_hub.gd` (`_build_edge_bars` and the drawer state machine):
overlay + scrim + two rails + two sliding drawers, both-independent open with
rear-peek, counts/empty-states, rail accent stub (green when an activity is
active). Activities drawer holds the existing circular activity markers; People
drawer holds the existing circular NPC face markers (tap → `signal_RequestNpcDialogue`).
**Deferred:** the People drawer does NOT yet render full NPC Offer Frames with
inline Accept buttons — that needs `get_available_quests` data wired into the hub
(today the hub only fetches `get_location_npcs` = name + face). Until then the
People bar is the in-world "who's here / talk to them" surface; the Quest screen's
Available tab remains the place to accept quests. Two cosmetic follow-ups: rail
labels use stacked-letter vertical text (rotation polish optional), and rail/header
icons use emoji glyphs (swap to `assets/` icons if the themed font lacks them).
