---
name: The Digital Curator
colors:
  surface: '#f8f9fa'
  surface-dim: '#d9dadb'
  surface-bright: '#f8f9fa'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f1f3f4'
  surface-container: '#edeeef'
  surface-container-high: '#e7e8e9'
  surface-container-highest: '#e1e3e4'
  on-surface: '#191c1d'
  on-surface-variant: '#424654'
  inverse-surface: '#2e3132'
  inverse-on-surface: '#f0f1f2'
  outline: '#747782'
  outline-variant: rgba(25, 28, 29, 0.2)
  surface-tint: '#3e5ba4'
  primary: '#001848'
  on-primary: '#ffffff'
  primary-container: '#0056d2'
  on-primary-container: '#7996e3'
  inverse-primary: '#b2c5ff'
  secondary: '#435b9f'
  on-secondary: '#ffffff'
  secondary-container: '#9cb4fe'
  on-secondary-container: '#2a4486'
  tertiary: '#390c00'
  on-tertiary: '#ffffff'
  tertiary-container: '#5c1900'
  on-tertiary-container: '#e17d5a'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#dae2ff'
  primary-fixed-dim: '#b2c5ff'
  on-primary-fixed: '#001848'
  on-primary-fixed-variant: '#23438b'
  secondary-fixed: '#dbe1ff'
  secondary-fixed-dim: '#b4c5ff'
  on-secondary-fixed: '#00174a'
  on-secondary-fixed-variant: '#2a4386'
  tertiary-fixed: '#ffdbd0'
  tertiary-fixed-dim: '#ffb59d'
  on-tertiary-fixed: '#390c00'
  on-tertiary-fixed-variant: '#7b2e12'
  background: '#f8f9fa'
  on-background: '#191c1d'
  surface-variant: '#e1e3e4'
  marex-blue: '#0000A5'
  marex-red: '#E63946'
typography:
  display-lg:
    fontFamily: Manrope
    fontSize: 56px
    fontWeight: '700'
    lineHeight: '1.1'
    letterSpacing: -0.02em
  display-lg-mobile:
    fontFamily: Manrope
    fontSize: 36px
    fontWeight: '700'
    lineHeight: '1.2'
    letterSpacing: -0.01em
  headline-md:
    fontFamily: Manrope
    fontSize: 28px
    fontWeight: '600'
    lineHeight: '1.3'
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: '1.6'
  label-md:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '500'
    lineHeight: '1.0'
    letterSpacing: 0.01em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  xs: 0.25rem
  sm: 0.5rem
  md: 1.5rem
  lg: 2.75rem
  xl: 5.5rem
---

## Brand & Style

The design system is built upon "The Digital Curator" aesthetic—a high-end editorial approach tailored for authoritative production and educational environments. It rejects the cluttered "data-dump" nature of traditional enterprise tools in favor of a sophisticated, literary atmosphere.

The personality is **authoritative, intellectual, and serene**. It leverages professional blues and expansive whitespace to create a state of "focused calm." The visual style is a blend of **Minimalism** and **Glassmorphism**, characterized by:
- **Intentional Asymmetry:** Breaking rigid grid patterns to guide the eye dynamically.
- **Architectural Breathing Room:** Using white space as a structural element rather than a void.
- **Tonal Layering:** Defining hierarchy through subtle color shifts instead of containment lines.
- **Editorial Polish:** High-contrast typography and premium translucent effects that suggest a curated, premium experience.

## Colors

The palette is rooted in "Professional Blues" derived from the brand's heritage, balanced with a sophisticated range of monochromatic surfaces. 

### The "No-Line" Rule
Explicitly avoid 1px solid borders for sectioning or layout containment. Boundaries must be defined solely through background color shifts. A `surface-container-low` section should sit directly against a `surface` background; the "edge" is the color change itself.

### Surface Hierarchy
- **Base Canvas:** Use `neutral` (#f8f9fa) for the main application background.
- **Elevated Content:** Use `surface-container-lowest` (#ffffff) for primary content cards and lesson modules to provide maximum contrast.
- **Utility Layers:** Use `surface-container-high` (#e7e8e9) for sidebars or secondary navigation panels.

### Glass & Gradients
Apply glassmorphism to floating elements (navigation bars, progress trackers) using semi-transparent versions of the surface color with a `24px` backdrop-blur. For primary actions, utilize a 135° linear gradient transitioning from `primary` to `primary-container`.

## Typography

This design system pairs **Manrope** for headlines to provide geometric warmth and **Inter** for body text to ensure technical precision and readability.

- **Editorial Hierarchy:** Use size and weight to organize information. Large headlines should often be placed with asymmetrical padding to create a "magazine" feel.
- **Readability:** Content-heavy sections must utilize `body-lg` with a `1.6` line-height to reduce cognitive load during extended production or learning sessions.
- **Metadata:** Use `label-md` in `on-surface-variant` for secondary information like timestamps or status indicators to maintain clear visual separation from primary text.

## Layout & Spacing

The layout model is a **fluid grid** that prioritizes "Architectural Breathing Room." It uses an 8px base unit but encourages extreme variance to support the editorial narrative.

- **Generous Padding:** Use `xl` (5.5rem) spacing for top and bottom margins of major sections to create a sense of luxury and focus.
- **Asymmetry:** Align primary content to a standard column grid, but stagger metadata and secondary assets (like pull-quotes or status chips) to break the vertical rhythm.
- **Gutter Strategy:** Maintain large gutters (minimum 24px) to ensure that even dense data feels airy and manageable.
- **Mobile Reflow:** On mobile devices, asymmetry is reduced in favor of single-column stacks, though the generous vertical padding (`lg`) is preserved to maintain the brand's premium feel.

## Elevation & Depth

In alignment with the "No-Line" rule, depth is communicated through tonal shifts and environmental light rather than physical borders.

- **The Layering Principle:** "Elevate" an object by placing a lighter surface (e.g., `surface-container-lowest`) onto a darker surface (e.g., `surface-container-low`). The contrast in lightness creates a natural, soft lift.
- **Cloud Shadows:** For floating elements like Modals that require a shadow, use a highly diffused "Cloud Shadow": `0px 20px 40px rgba(25, 28, 29, 0.05)`.
- **Glassmorphism:** Navigation bars and sticky bottom bars use 80% opacity surface fills with a background blur. This allows content to bleed through during scrolling, maintaining a sense of spatial continuity.
- **Ghost Borders:** For interactive states (like input focus), use the `outline-variant` token at **20% opacity**.

## Shapes

The shape language is consistently **Rounded**, avoiding harsh corners to maintain a "friendly professional" tone.

- **Standard Elements:** Buttons and cards use a `0.5rem` radius.
- **Large Containers:** Content modules and featured hero cards use `rounded-lg` (1rem) or `rounded-xl` (1.5rem) to emphasize their role as distinct "containers" of information.
- **Interactive Indicators:** Small UI markers (like status dots or page indicators) may use pill shapes to distinguish them from structural elements.

## Components

### Buttons
- **Primary:** Features the 135° gradient from `primary` to `primary-container`. Use `rounded-md` (0.75rem) and no border. Text is `on-primary`.
- **Tertiary:** No background or border. Use `primary` text. On hover, apply a soft `surface-container-low` pill-shaped background.

### Inputs & Search
- **Default:** Use `surface-container-low` as a fill. No border.
- **Focus:** Transition background to `surface-container-lowest` and apply a 1px `primary` ghost-border at 30% opacity.

### Cards
- **Construction:** Built using `surface-container-lowest`. 
- **Internal Division:** Forbid divider lines. Separate card sections using internal padding (`md`). Use `surface-variant` as a subtle background for card footers or metadata strips.

### Specialized UI
- **The Progress Float:** A glassmorphic sticky bar at the bottom of the viewport using 80% surface opacity. The progress indicator uses the solid `primary` blue.
- **Feedback States:** Use `secondary-container` for successful knowledge checks and `error-container` for retry states, ensuring the tone remains non-punitive and soft.