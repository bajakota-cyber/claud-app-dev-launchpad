# Flutter Rules

These rules document Flutter footguns that cost real session time. Flutter Web is silent about most layout constraint violations — they render as 0-height widgets or blank screens with NO error in the console. If a Flutter Web page renders blank or a widget is missing, suspect constraints FIRST.

## The ⭐ #1 footgun: `Size.fromHeight()` in a global ButtonThemeData

**This single line cost ODRP 8 fix attempts on the "wizard Continue button doesn't render" bug.**

```dart
filledButtonTheme: FilledButtonThemeData(
  style: FilledButton.styleFrom(
    minimumSize: Size.fromHeight(48),    // ← THIS LINE
    ...
  ),
),
```

`Size.fromHeight(48)` is `Size(double.infinity, 48)` — minimum WIDTH of infinity. This forces every `FilledButton` in the app to be full-width.

- In a `Column > FilledButton` (sign-in screen pattern), the button correctly fills the column width — looks great.
- In a `Row > [Spacer, FilledButton]` or `Row(mainAxisAlignment: spaceBetween, children: [BACK, FilledButton])` (typical wizard NavButtons pattern), the infinity-width FilledButton CONFLICTS with Spacer and rendering silently breaks. The button takes layout space (so `find` can locate it in semantics) but paints NOTHING visible. **No error, no warning.** Looks identical to a missing or invisible-disabled button.

### Fixes
- **Per-button override** (cleanest when you have a few mixed contexts):
  ```dart
  FilledButton(
    style: FilledButton.styleFrom(minimumSize: Size(140, 48)),  // bounded width
    ...
  )
  ```
- **OR fix the theme** to use a finite minimum width: `Size(120, 48)` instead of `Size.fromHeight(48)`. This is the right move if 100% of your FilledButton sites are in `Column` contexts (full-width by intent).
- **Anti-pattern to flag in code review:** any `Size.fromHeight()` or `Size.fromWidth()` inside a global `ButtonThemeData`. These create silent infinity-axis constraints that one day collide with a Row/Spacer layout and produce invisible buttons.

### Debugging trick that finally caught it
Wrap the suspected widget in `ColoredBox(color: Color(0xFFFF0000))`. If you see a red rectangle but no button content inside it, the layout is fine and the button is rendering invisibly — look at the global theme's button style for infinity-axis sizing.

### Verification trick before declaring done
Always navigate to the screen via Chrome MCP after a deploy:
1. Take a screenshot
2. Use `find` to locate the button in the semantic tree
3. **Click on the actual rendered pixels** (not the semantic ref) — if the click works, the button is visible AND positioned correctly. If the click does nothing, the button is in semantics but not painted.

## Layout Constraint Rules (Flutter Web especially)

### The `Center` vertical-inflation footgun (cost ODRP 4 fix attempts)
- **`Center` (and `Align` with default `heightFactor: null`) INFLATES vertically to fill all available space**, regardless of child intrinsic height. This is the documented behavior — `Align`'s docs say "if width/heightFactor is null, the widget will expand to fill all available space in that direction."
- **Real failure mode (verified via Chrome MCP):** a wizard with `Center > ConstrainedBox(maxWidth: 600) > Column(...)` as the root of `Scaffold.bottomNavigationBar` consumed the ENTIRE viewport height (Scaffold gives the bottomNavBar slot loose constraints with maxHeight = remaining screen). The body got 0px left. Widgets WERE laid out (input proxies were in the DOM at correct y-coordinates) but the canvas painted them to a 0-height area — appearing as a blank screen below the AppBar. No error, no warning.
- **Same trap inside body Columns:** a non-`Expanded` `Center` child of a Column also inflates vertically, eating sibling space.

### The fix: `Align(heightFactor: 1.0)` for horizontal-only centering
```dart
Widget hCenter(Widget child) => Align(
  alignment: Alignment.topCenter,
  heightFactor: 1.0,           // ← SHRINK-WRAP vertically
  child: ConstrainedBox(
    constraints: BoxConstraints(maxWidth: 600),
    child: child,
  ),
);
```
Use this anywhere you need "fill horizontally with a max-width cap, but shrink to the child's height vertically." Never use bare `Center` for that purpose.

### Other related rules
- **NEVER wrap a `Column` containing `Expanded` children inside a widget that passes LOOSE height constraints.** `Center` (no factor), `Align` (no factor), unbounded `ConstrainedBox`, etc. The `Expanded` child silently renders at 0 height.
- **Correct pattern for a wizard / multi-section screen:**
  - Put `Column` at the root of `Scaffold.body` (Scaffold passes TIGHT height).
  - Wrap individual children with the `hCenter` helper above for horizontal max-width.
  - Inline `NavButtons` at the bottom of the body Column. **Don't use `Scaffold.bottomNavigationBar` unless you fully understand its loose-height slot behavior** — its sizing is the most common silent screen-blanking trap.
- **Debugging trick:** wrap the suspected widget in `Container(color: Colors.red.withOpacity(0.3), ...)` — if the red overlay covers the entire screen, the widget is inflating; if 0-height, the parent's giving loose height to an Expanded.
- **Verification trick:** when the screen is blank, check `document.querySelector('flutter-view').getBoundingClientRect()` AND `document.querySelectorAll('input').length` in DevTools. If inputs exist with non-zero y but the canvas shows nothing, the layout ran but paint area is 0 → look for vertical-inflation traps (Centers, unbounded Aligns).

## Flutter Web Build & Deploy

- `flutter build web` succeeding does NOT mean the page renders. Build errors and layout errors are separate. Always verify the rendered page (open the URL, take a screenshot, or have user confirm) before declaring a fix done.
- Cloudflare Pages caches aggressively. After a deploy, instruct the user to hard-refresh (Ctrl+Shift+R / Cmd+Shift+R) before verifying — a normal refresh may serve stale JS.
- `--dart-define` values bake into the build output. Rotating a key requires a rebuild + redeploy, not just an env-var swap.

## State Management

- `setState` inside an `async` callback that may run after the widget is disposed throws "setState called after dispose". Always check `if (!mounted) return;` before `setState` in async callbacks.
- `BuildContext` captured before an `await` may be stale after. Either capture what you need before the await (e.g., `final navigator = Navigator.of(context);`) or check `if (!context.mounted) return;` after.

## Supabase + Flutter

- `Supabase.instance.client.auth.onAuthStateChange` fires on every auth event, including session refresh. Routing logic in that listener must be idempotent — guard against re-navigating to the same screen on token refresh.
- RLS errors from Supabase come back as `PostgrestException` with code `42501`, not as auth errors. Handle them as "permission denied" UX, not "log out".
