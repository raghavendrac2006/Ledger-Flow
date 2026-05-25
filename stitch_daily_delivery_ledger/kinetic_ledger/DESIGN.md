---
name: Kinetic Ledger
colors:
  surface: '#fbf8ff'
  surface-dim: '#dbd9e1'
  surface-bright: '#fbf8ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f5f2fb'
  surface-container: '#efecf5'
  surface-container-high: '#eae7ef'
  surface-container-highest: '#e4e1ea'
  on-surface: '#1b1b21'
  on-surface-variant: '#454652'
  inverse-surface: '#303036'
  inverse-on-surface: '#f2eff8'
  outline: '#767683'
  outline-variant: '#c6c5d4'
  surface-tint: '#4c56af'
  primary: '#000666'
  on-primary: '#ffffff'
  primary-container: '#1a237e'
  on-primary-container: '#8690ee'
  inverse-primary: '#bdc2ff'
  secondary: '#4c616c'
  on-secondary: '#ffffff'
  secondary-container: '#cfe6f2'
  on-secondary-container: '#526772'
  tertiary: '#380b00'
  on-tertiary: '#ffffff'
  tertiary-container: '#5c1800'
  on-tertiary-container: '#e17c5a'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#e0e0ff'
  primary-fixed-dim: '#bdc2ff'
  on-primary-fixed: '#000767'
  on-primary-fixed-variant: '#343d96'
  secondary-fixed: '#cfe6f2'
  secondary-fixed-dim: '#b4cad6'
  on-secondary-fixed: '#071e27'
  on-secondary-fixed-variant: '#354a53'
  tertiary-fixed: '#ffdbd0'
  tertiary-fixed-dim: '#ffb59d'
  on-tertiary-fixed: '#390c00'
  on-tertiary-fixed-variant: '#7b2e12'
  background: '#fbf8ff'
  on-background: '#1b1b21'
  surface-variant: '#e4e1ea'
typography:
  headline-xl:
    fontFamily: Hanken Grotesk
    fontSize: 32px
    fontWeight: '800'
    lineHeight: 40px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Hanken Grotesk
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
    letterSpacing: -0.01em
  headline-md:
    fontFamily: Hanken Grotesk
    fontSize: 20px
    fontWeight: '700'
    lineHeight: 28px
  body-lg:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 28px
  body-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  label-bold:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '700'
    lineHeight: 20px
  label-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
  data-tabular:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '600'
    lineHeight: 24px
rounded:
  sm: 0.125rem
  DEFAULT: 0.25rem
  md: 0.375rem
  lg: 0.5rem
  xl: 0.75rem
  full: 9999px
spacing:
  base: 8px
  xs: 4px
  sm: 12px
  md: 16px
  lg: 24px
  xl: 32px
  touch-target: 48px
  container-margin: 16px
---

## Brand & Style

The design system is engineered for high-stakes operational environments where speed and accuracy are paramount. The brand personality is **authoritative, utilitarian, and decisive**, catering to logistics professionals and sales leads who require instant data recognition under varying lighting conditions.

The visual style leverages **High-Contrast Modernism**. It eschews decorative flourishes in favor of extreme legibility and structured information density. By combining heavy strokes, a stark monochromatic base, and a singular powerful primary accent, the design system creates a UI that feels like a precision instrument—reliable, professional, and no-nonsense.

## Colors

The palette is anchored by a high-contrast relationship between **Pure Black text** and an **Off-White background**, ensuring maximum readability and reducing eye strain during extended use. 

- **Primary (Deep Indigo):** Used for primary actions, active navigation states, and brand-critical touchpoints. It conveys stability and corporate trust.
- **Success (Forest Green):** Reserved exclusively for 'Submit' actions, completed deliveries, and positive sales growth. Its high saturation ensures it is never missed.
- **Neutral/Surface:** We use a subtle off-white for the background to soften the glare of mobile screens, while using pure white for "Card" surfaces to create a clear layer of separation.

## Typography

This design system uses **Hanken Grotesk** for headings to provide a sharp, contemporary, and assertive voice. Its bold weights are utilized to establish an unmistakable visual hierarchy. 

**Inter** is the workhorse for all body text and data entry. It is chosen for its exceptional legibility at small sizes and its neutral, systematic feel. 

- **Data Legibility:** For sales figures and tracking IDs, always use the `data-tabular` style which employs tabular numbers to ensure columns of figures align perfectly for easy scanning.
- **Mobile Scale:** On mobile devices, `headline-xl` should be used sparingly for screen titles, while `headline-lg` serves as the primary container header.

## Layout & Spacing

The system follows an **8px grid** to ensure mathematical harmony across all screen sizes. The layout model is fluid but strictly contained within a **16px side margin** for mobile views.

- **Touch Targets:** All interactive elements (buttons, checkboxes, list items) must maintain a minimum height of **48px** to accommodate high-speed, "on-the-go" usage.
- **Data Density:** While the design is bold, information density is maintained through tight vertical spacing within data rows (8px–12px) and generous horizontal padding between columns to prevent data bleeding.
- **Safe Areas:** Ensure all bottom-fixed buttons account for mobile OS home indicators by adding 24px of additional bottom padding.

## Elevation & Depth

To maintain the utilitarian and professional tone, this design system avoids soft, ambient shadows. Instead, it uses **Tonal Layers** and **Low-Contrast Outlines** to define hierarchy.

- **Level 0 (Background):** #F8F9FA.
- **Level 1 (Cards/Containers):** Pure White (#FFFFFF) with a 1.5px solid border (#E0E0E0). This "Box" approach emphasizes the structural grid.
- **Level 2 (Active/Floating):** Use a "Hard Shadow" (2px offset, 0 blur, #000000 at 10% opacity) only for primary call-to-action buttons to make them feel tactile and pressed when interacted with.
- **Separators:** Use a 1px solid #EEEEEE for horizontal rules in lists and tables.

## Shapes

The shape language is **Soft (0.25rem)**. This slight rounding provides a professional, "industrial-chic" aesthetic that is cleaner than sharp 0px corners but more serious than highly rounded "pill" designs.

- **Inputs & Buttons:** Use the standard `rounded` (4px) setting.
- **Large Containers/Cards:** Use `rounded-lg` (8px) to softly frame large blocks of data.
- **Status Pills:** Small indicators for "Delivered" or "Pending" use `rounded-xl` (12px) to distinguish them from functional buttons.

## Components

### Buttons
- **Primary:** Deep Indigo background, White text. High-contrast, bold weight. Min height 52px.
- **Success (Submit):** Forest Green background, White text. Used for finality and confirmation.
- **Ghost:** Pure Black 2px border, No fill. Used for secondary actions like "Cancel" or "Edit."

### Input Fields
- **Default State:** 1.5px solid border (#BDBDBD). Label is always visible above the field (never hidden as placeholder).
- **Focus State:** 2px solid Deep Indigo border with a subtle light indigo background tint (#F0F2FF).
- **Auto-complete:** Suggestions appear in a high-contrast white dropdown with 1px black borders. Highlighted items use a Deep Indigo background with White text.

### Tables & Lists
- **Structure:** Clean, borderless rows with 1px horizontal dividers.
- **Typography:** Labels in `label-bold`, Data in `data-tabular`.
- **Zebra Striping:** Use a very light gray (#F5F5F5) for even rows in data-heavy sales tables to assist eye-tracking.

### Chips & Badges
- Used for status filtering (e.g., "In Transit," "Out for Delivery"). High-contrast text on light tinted backgrounds (e.g., Dark Green text on light green background).

### Touch Targets
- All list items in a tracking view must have a minimum vertical hit area of 56px to prevent "fat-finger" errors during rapid navigation.