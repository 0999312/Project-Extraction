# Minimal Vector Theme Design

> Version 0.1 – 2026-03-30

## 1. Overview

`minimal_vector.tres` is the project's **default global UI theme**. It is assigned in `project.godot` via `[gui] theme/custom`, so standard Godot controls inherit it automatically unless a scene or script overrides the style locally.

This theme is intended to provide a **high-contrast, readable, stylized vector UI** with:

- strong black outlines
- flat colour surfaces instead of textured skins
- bright arcade-like accent colours
- stable button states that stay visually consistent across menus

## 2. Scope

The theme currently defines shared styling for these control families:

| Control | Theme Coverage |
|---|---|
| `Button` | full state styling (`normal`, `hover`, `pressed`, `focus`, `disabled`) |
| `Label` | font colour + outline |
| `LineEdit` | normal/focus/read-only surfaces, cursor, selection |
| `Panel` | general warm surface panel |
| `PanelContainer` | general container surface |
| `ProgressBar` | background + fill |
| `TabContainer` | panel + tab states |
| `HScrollBar` / `VScrollBar` | track + grabber states |

## 3. What This Theme Does **Not** Own

Several gameplay-specific UI elements intentionally use **script-level `StyleBoxFlat` overrides** instead of relying on the global theme:

- inventory grid cells (`scripts/game/ui/inventory_slot.gd`)
- HUD hotbar slots (`scripts/game/ui/player_hud.gd`)
- inventory-menu hotbar slots and equipment placeholder slots (`scripts/game/ui/inventory_menu.gd`)

This separation is intentional:

- `minimal_vector.tres` controls the **shared application skin**
- gameplay slot visuals remain **explicit, local, and easy to tune per feature**

When changing inventory or hotbar visuals, edit those scripts first rather than the global theme.

## 4. Core Design Goals

### 4.1 Readability First

Most major controls use:

- thick black borders
- bright foreground/background separation
- outlined text for legibility on saturated backgrounds

### 4.2 Flat Vector Look

The theme avoids textured chrome. The look is built from:

- `StyleBoxFlat`
- bold contour lines
- solid fill colours
- rounded corners only where softness is desired

### 4.3 Stable Button Language

Buttons are treated as a **locked visual language**:

- **normal**: white fill, black border
- **hover / focus**: bright green fill
- **pressed / disabled**: red fill variants

Recent palette passes explicitly left the button colours unchanged while adjusting non-button surfaces.

## 5. Palette Structure

The current palette is organized by UI role rather than by a single monochrome colour ramp.

| UI Role | Representative Value | Intent |
|---|---|---|
| Button normal | `Color(1, 1, 1, 1)` | neutral interactive baseline |
| Button hover/focus | `Color(0.4, 0.8, 0, 1)` | immediate interactive feedback |
| Button pressed/disabled | `Color(0.9, 0, 0, 1)` | strong action / blocked state |
| Panel surface | `Color(0.8588, 0.4706, 0.0706, 1)` | warm orange-brown structural background |
| PanelContainer surface | `Color(0.4392, 0.6392, 0.1804, 1)` | earthy green container block |
| Tab panel | `Color(0.2706, 0.6706, 0.9020, 1)` | bright cyan-blue content surface |
| Selected tab | `Color(1, 0.8392, 0.2392, 1)` | saturated yellow active emphasis |
| Hovered tab | `Color(0.9647, 0.7216, 0.1804, 1)` | warm amber transitional emphasis |
| Unselected tab | `Color(0.4392, 0.6196, 0.8784, 1)` | cooler blue resting state |
| Scrollbar track | `Color(0.1490, 0.5490, 0.7804, 1)` | cyan-blue rail |
| Scrollbar pressed grabber | `Color(0.7412, 0.3922, 0.0824, 1)` | warm brown pressed accent |
| LineEdit normal | `Color(1, 1, 0.9608, 1)` | near-white editable field |
| LineEdit focus | `Color(1, 0.9686, 0.8784, 1)` | warmer focus state |
| LineEdit selection | `Color(0.0902, 0.7412, 0.9490, 0.45)` | cyan highlight with transparency |
| Progress background | `Color(0.9804, 0.9294, 0.7216, 1)` | pale cream buffer surface |
| Progress fill | `Color(0, 0.9, 0.1050, 1)` | vivid green progress readout |

## 6. Shape Language

### 6.1 Borders

Most major interactive or framed surfaces use **6 px borders**. This produces the thick cartoon/vector silhouette used across the UI.

Scrollbar tracks are lighter-weight and use **1 px borders**.

### 6.2 Corner Radius

The theme uses rounded corners selectively:

- buttons: `8 px`
- line edits: `8 px`
- progress bars: `8 px`
- tab panel: top `6 px`, bottom `8 px`

This keeps the UI playful without making every surface equally soft.

### 6.3 Text Outlines

Text readability depends heavily on outlines:

| Control | Outline Size |
|---|---|
| `Button` | `10` |
| `Label` | `6` |
| `LineEdit` | `10` |
| `ProgressBar` | `10` |

## 7. Control-by-Control Notes

### 7.1 Button

Buttons are the most opinionated part of the theme and should be changed cautiously.

- white = idle
- green = hover/focus
- red = pressed/disabled
- black outline remains constant

If the project is retuned again, button colours should only change as part of a deliberate full interaction-language redesign.

### 7.2 Panel vs PanelContainer

`Panel` and `PanelContainer` intentionally use **different surfaces**:

- `Panel` is the warmer orange-brown structural surface
- `PanelContainer` is the greener container surface

This gives layout nesting a visible hierarchy without introducing gradients or textures.

### 7.3 TabContainer

Tabs provide the strongest non-button colour choreography:

- blue/cyan content region
- blue resting tabs
- amber hover
- yellow selected tab

This makes active navigation states easy to scan.

### 7.4 ProgressBar

The default progress bars are tuned for readability and then recoloured per gameplay use when needed. For example, HUD bars can reuse the same shape/border language while overriding fill colour in script.

### 7.5 LineEdit

Line edits intentionally stay lighter than panels so typed content remains readable. The cyan selection colour adds feedback without fully obscuring the text underneath.

## 8. Relationship to Gameplay UI

The gameplay UI follows the same broad visual philosophy but is **not fully theme-driven**:

- hotbar slots use local black-bordered `StyleBoxFlat`
- inventory cells use local square `StyleBoxFlat`
- equipment placeholders use local dark surfaces with state-dependent borders

This means the project currently has two layers of UI styling:

1. **Global control theme** — `minimal_vector.tres`
2. **Gameplay interaction styling** — script-generated style boxes

Future cleanup could consolidate some of those gameplay styles into the theme, but that is not the current design.

## 9. Editing Guidelines

When modifying `minimal_vector.tres`, follow these rules:

1. **Preserve button colours unless the interaction language is intentionally being redesigned.**
2. **Prefer adjusting non-button surfaces first** when matching a new reference palette.
3. Keep black outlines and high contrast; they are a core part of the theme identity.
4. Update both English and Chinese docs when the theme's structure or palette changes.
5. If a visual issue is limited to inventory/hotbar/equipment slots, inspect the related gameplay UI scripts before changing the global theme.

## 10. File Manifest

| Path | Role |
|---|---|
| `project.godot` | assigns `minimal_vector.tres` as the default global theme |
| `resources/themes/minimal_vector.tres` | theme resource definition |
| `scripts/game/ui/player_hud.gd` | hotbar + progress-bar local visual overrides |
| `scripts/game/ui/inventory_slot.gd` | inventory cell local styling |
| `scripts/game/ui/inventory_menu.gd` | inventory hotbar + equipment slot local styling |
| `docs/PROGRESS.md` | high-level change log for palette passes |

