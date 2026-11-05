# ADR-0007: Monochrome Sky Rendering, Weather Caching, and Today Home Architecture

## Context
DayBook's signature visual identity features a real-time, monochrome line-art sky canvas drawn directly on an OLED true-black `#000000` background. In low-end and mid-range devices commonly used in Bangladesh, animated backgrounds can cause battery drain and frame drops. Furthermore, internet access may be intermittent, requiring robust offline caching for weather data and solar calculations.

## Decision

### 1. Solar Phase & Astronomical Calculations
- Calculate solar elevation and sky phases (`dawn`, `day`, `goldenHour`, `dusk`, `night`) using standard solar coordinates or local clock relative to estimated or cached sunrise/sunset times (defaulting to Dhaka: $23.81^\circ\text{ N}, 90.41^\circ\text{ E}$).
- The visual elements are rendered using a custom `SkyCanvasPainter`:
  - **Sun**: Solid `#B6FF00` circle with thin geometric radiating rays.
  - **Moon**: Crescent/gibbous white outline with discrete starlight points.
  - **Clouds**: Minimalist geometric closed bezier curves in `#FFFFFF`.
  - **Rain & Thunder**: Downward slanted 1px strokes in `#B6FF00` or `#FFFFFF`, with zig-zag lightning bolts for thunderstorm codes.
  - **Fog**: Stacked horizontal dashed lines fading with depth.

### 2. WMO Weather Code Normalization
WMO weather codes from Open-Meteo are mapped to internal `WeatherType` and sky glyphs:
- `0`: Clear Sky (Sun or Moon)
- `1..3`: Clouds (Partly cloudy to Overcast)
- `45, 48`: Fog / Rime fog
- `51..57`: Drizzle (light, moderate, dense)
- `61..67`: Rain (slight, moderate, heavy)
- `80..82`: Showers
- `95..99`: Thunderstorm

Each `JournalEntry` and `DayPage` persists the computed `sky_code` string (e.g. `clear_night`, `rain_day`, `thunder_dusk`) to display a consistent mini glyph in the Book shelf and timeline.

### 3. Battery Preservation & Particle Throttling
- The sky canvas is wrapped in a `RepaintBoundary` to prevent unnecessary repainting when scrolling or interacting with other widgets.
- Active particles (e.g. rain drops) are hard-capped at 25 particles.
- When the screen is in the background or when battery saver is active, animation tickers pause, rendering a crisp static frame.

### 4. Offline Weather Caching
- `WeatherService` fetches current temperature and WMO codes from Open-Meteo.
- Responses are cached in persistent storage with a 30-minute TTL.
- If network requests fail or the device is offline, the last cached weather is served without blocking the UI. If no cache exists, a sensible default (Dhaka, 28°C, Clear) is provided.

### 5. Briefing & Evening Review
- **Morning Briefing**: Generated deterministically offline combining current weather, first alarm, top 3 priority tasks, and the Eat-the-Frog mission.
- **Evening Review**: Synthesizes completed tasks vs. rolled-over tasks, mood average, and prompts a 1-line evening gratitude/reflection.
- Both briefings are available in full Bengali and English, with TTS playback support.
