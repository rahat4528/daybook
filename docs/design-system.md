# DayBook Design System Specification

## 1. Visual Philosophy & Token Palette
DayBook implements a stark, distraction-free **OLED True-Black & Lime** aesthetic designed for maximum battery efficiency, cognitive focus, and visual authority.

### Color Tokens & Accessibility Contrast Matrix
| Token Name | Hex Code | Background | Contrast Ratio | WCAG Compliance |
|---|:---:|:---:|:---:|:---:|
| `bg` | `#000000` | N/A | N/A | True OLED Black |
| `surface-1` | `#0A0A0A` | `#000000` | N/A | Primary card container |
| `surface-2` | `#141414` | `#000000` | N/A | Elevated sheet / input container |
| `border` | `#262626` | `#000000` | N/A | 1px clean container boundary |
| `text-primary` | `#FFFFFF` | `#000000` | **21.0:1** | **Passes AAA** (Required: 7.0:1) |
| `text-primary` | `#FFFFFF` | `#0A0A0A` | **19.8:1** | **Passes AAA** |
| `text-secondary` | `#A3A3A3` | `#000000` | **7.4:1** | **Passes AAA** |
| `text-secondary` | `#A3A3A3` | `#0A0A0A` | **6.9:1** | **Passes AA** (Required: 4.5:1) |
| `accent-lime` | `#B6FF00` | `#000000` | **16.5:1** | **Passes AAA** |
| `accent-lime` | `#B6FF00` | `#0A0A0A` | **15.6:1** | **Passes AAA** |
| `text-on-lime` | `#000000` | `#B6FF00` | **16.5:1** | **Passes AAA** |
| `error-red` | `#FF4D4D` | `#000000` | **5.9:1** | **Passes AA** |

---

## 2. Usage & Hierarchy Rules

1. **The 15% Lime Rule**: Lime green (`#B6FF00`) is an electric accent that must not overwhelm the eye. It is strictly capped at ~15% of the screen real-estate.
2. **Lime Bold Allocations**:
   - Screen titles & major section headers.
   - Key numeric metrics (Day Score, streak counters, financial totals, alarm times).
   - Active bottom navigation destination.
   - Primary action buttons (`#B6FF00` fill, `#000000` bold text).
   - Dynamic progress rings & active streak heatmaps.
   - Emphasized words (`**bold**`) in markdown briefings and assistant replies.
3. **Typography**:
   - Tabular numerals enabled across all timers, clocks, coordinates, and monetary amounts (`FontFeature.tabularFigures()`).
   - Bangla typography (`Hind Siliguri` / `Noto Sans Bengali`) enforced with a minimum `height: 1.5` to prevent diacritic / vowel clipping.
   - Layouts engineered to support 200% system font scaling without text overflow.
4. **Error Handling**:
   - Error red (`#FF4D4D`) is the single exception outside the monochrome/lime palette.
   - **Never rely on color alone**: Every error or destructive element must include a descriptive icon and textual label.

---

## 3. Core Component Catalog

- **Card Container**: `surface-1` (`#0A0A0A`), 1px `border` (`#262626`), border radius 16px to 20px.
- **Heatmap Cell**: Lime `#B6FF00` rendered at 5 discrete opacity levels: `0% (empty)`, `25%`, `50%`, `75%`, `100% (peak)`.
- **Primary Button**: Background `#B6FF00`, text `#000000` bold, 48dp minimum touch target height.
- **Progress Ring**: Dual-track circular stroke with `#262626` base and `#B6FF00` active sweep.
- **Alarm Display**: Pure black backdrop, massive white tabular clock font, lime challenge status badge.
- **Undo Toast**: Dark container (`#141414`), white notification message, lime bold `UNDO` interactive action button.

