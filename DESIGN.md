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

## Decisions Log
| Date | Decision | Rationale |
|------|----------|-----------|
| 2026-04-10 | Initial design system created | Created by /design-consultation. Codifies existing Styler.gd patterns + art direction for paper doll character view. |
| 2026-04-10 | Semi-realistic painted art style | Matches existing AI-generated equipment icons. Diablo 2 meets mobile polish. |
| 2026-04-10 | Dark UI + gold accents | Category standard for RPGs. Users expect it. |
| 2026-04-10 | 512x1024 overlay canvas | Recommended base, calibrate to actual mobile viewport after testing. |
