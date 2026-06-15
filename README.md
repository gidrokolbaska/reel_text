# reel_text

Dependency-light Flutter text roll animation for short labels, counters, status
text, and command buttons.

`reel_text` brings the DOM text-roll idea from
[Danilaa1's original package](https://github.com/Danilaa1/slot-text) to
Flutter: every glyph gets its own measured slot, changed glyphs slide
vertically, optional color flashes fade back to the inherited text color, and
imperative `flash()` calls are safe for rapid button taps.

![reel_text showcase](assets/showcase.webp)

[Live demo](https://kicknext.github.io/reel_text/)

## Install

```yaml
dependencies:
  reel_text: ^0.1.0
```

## Quick Start

```dart
import 'package:reel_text/reel_text.dart';

const ReelText('Copy');
```

For the classic `Copy -> Copied -> Copy` interaction:

```dart
final controller = ReelTextController(initialText: 'Copy');

ReelText.controller(controller: controller);

controller.flash(
  'Copied',
  options: ReelTextFlashOptions(
    enter: ReelTextOptions(colorBuilder: chromatic()),
  ),
);
```

## API

### Declarative

```dart
ReelText(
  copied ? 'Copied' : 'Copy',
  options: ReelTextOptions(
    direction: copied ? ReelTextDirection.up : ReelTextDirection.down,
    colorBuilder: copied ? chromatic() : null,
  ),
);
```

### Imperative

```dart
final label = ReelTextController(initialText: 'Copy');

label.set('Copied');
label.set(
  'Copy',
  options: const ReelTextOptions(direction: ReelTextDirection.down),
);
label.flash('Copied');
label.dispose();
```

`flash()` captures the resting text on the first flash in a burst, resets the
revert timer on repeated calls, and rolls back once after the last flash.
Calling `set()` cancels a pending revert.

For async operations, use `runWhile()`:

```dart
final exportLabel = ReelTextController(initialText: 'Export');

await exportLabel.runWhile(
  exportFile,
  waiting: 'Exporting',
  success: 'Exported',
  failure: 'Failed',
  waitingOptions: const ReelTextOptions(color: Color(0xffffb84d)),
  successOptions: const ReelTextOptions(color: Color(0xff38bdf8)),
  failureOptions: const ReelTextOptions(color: Color(0xffe11d48)),
);
```

`runWhile()` starts the waiting loop before invoking the operation, emits the
success label on completion, and emits the failure label before rethrowing an
error. For lower-level frame control, `startProgress()` and `startWaiting()`
still return a `ReelTextProgress` handle.

For rotating labels, use `ReelText.sequence` instead of managing a controller
and timer yourself:

```dart
ReelText.sequence(
  values: const ['CRAFT', 'DRAFT', 'DRIFT'],
  interval: const Duration(milliseconds: 2400),
  optionsBuilder: (index, value) => ReelTextOptions(
    direction: index.isEven ? ReelTextDirection.up : ReelTextDirection.down,
  ).withChromatic(from: 70 + index * 54),
);
```

### Waiting (idle) animations

For the common case you don't need to invent frames: `startWaiting()` loops a
designed idle animation until its handle is resolved.

```dart
final label = ReelTextController(initialText: 'Export');

final handle = label.startWaiting('Exporting');
try {
  await exportFile();
  handle.complete('Exported');
} catch (_) {
  handle.fail('Failed');
}
```

Pick the look with a `ReelWaiting` preset:

```dart
// Trailing dots: Exporting -> Exporting. -> Exporting.. -> Exporting...
label.startWaiting('Exporting', waiting: const ReelWaiting.ellipsis());

// The label stays readable and periodically "breathes": one stagger wave of
// self-rolls sweeps across the glyphs, then the word rests.
label.startWaiting(
  'Exporting',
  waiting: const ReelWaiting.wave(rest: Duration(milliseconds: 1200)),
);

// Scramble a suffix while periodically returning to the readable label.
label.startWaiting(
  'Exporting',
  waiting: const ReelWaiting.scramble(protectedPrefix: 6),
);
```

All presets compile down to the same roll engine. Each preset ships with
designed motion defaults — `ellipsis` ticks on a steady, metronome-like beat
derived from the roll duration, and `wave` uses a calm, non-springy curve with
almost no tilt so the loop reads as a ripple instead of a glitch. Pass your own
`ReelTextOptions` to take full control of direction, curve, stagger, and color.

### Reduced motion

When the platform requests reduced motion
(`MediaQuery.disableAnimationsOf(context)`), `ReelText` snaps to the target
text instantly instead of rolling. Opt out per widget with
`respectDisableAnimations: false`.

### Text layout, selection, and emoji

`ReelText` keeps the same single-line layout box as Flutter `Text` for the
current target string, including during a roll. It does not add extra vertical
padding for the animation. `textAlign` is visible when a parent gives the widget
a real width, such as `SizedBox` or `Expanded`; loose max-width constraints keep
the intrinsic text width:

```dart
const SizedBox(
  width: 160,
  child: ReelText('Copied', textAlign: TextAlign.end),
);
```

Inside a `SelectionArea`, `ReelText` exposes one selectable surface for the full
current string while the animated glyphs stay visual-only. Extended emoji and
joined emoji sequences are treated as whole glyph clusters:

```dart
SelectionArea(
  child: ReelText('Ready 👨‍👩‍👧‍👦🧑🏽‍💻👍🏽'),
);
```

Use `ReelText.rich` when the changing phrase needs inline styles. The widget
still rolls by grapheme cluster and exposes one selectable plain-text surface:

```dart
ReelText.rich(
  const TextSpan(
    children: [
      TextSpan(text: 'Draft: ', style: TextStyle(color: Colors.redAccent)),
      TextSpan(text: 'rewrite with evidence'),
    ],
  ),
);
```

For editable surfaces, use `ReelTextEditingController`. It extends Flutter's
`TextEditingController` and renders temporary replacements inside the same
`EditableText` layout, so caret, selection, wrapping, and scroll geometry stay
owned by Flutter:

```dart
final controller = ReelTextEditingController(text: 'Please recieve teh file.');

controller.animateReplacements(
  replacements: [
    const ReelTextEditReplacement(
      range: TextRange(start: 7, end: 14),
      replacement: 'receive',
      options: ReelTextOptions(color: Color(0xff84cc16)),
    ),
  ],
  commitAfter: const Duration(milliseconds: 760),
);
```

The example editor uses this controller with a `SpellCheckService` pipeline:
LanguageTool for online suggestions, Flutter's native spellcheck service where
the platform exposes one, and a deterministic fallback for offline demo text.

### Dynamic fonts

`ReelText` measures glyph slots from the active Flutter text layout. If your app
loads fonts asynchronously, preload them before the first `ReelText` frame so
initial slot widths are measured with the final font:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.archivoBlack();
  await GoogleFonts.pendingFonts();
  runApp(const App());
}
```

## Options

| Option | Default | Description |
| --- | --- | --- |
| `direction` | `ReelTextDirection.down` | Roll direction. |
| `stagger` | `45ms` | Delay between glyph starts. |
| `duration` | `300ms` | Per-glyph slide duration. |
| `exitOffset` | `50ms` | Delay before incoming glyphs chase outgoing glyphs. |
| `curve` | springy cubic | Slide curve. |
| `bounce` | `0.6` | Per-glyph timing/tilt variation and settle-overshoot depth. |
| `color` | null | Flat incoming glyph tint. |
| `colorBuilder` | null | Per-glyph incoming tint, such as `chromatic()`. |
| `colorFade` | `280ms` | Tint fade-back duration. |
| `skipUnchanged` | `true` | Keeps identical same-index glyphs static. |
| `interrupt` | `true` | Interrupt in-flight rolls or queue the latest target. |

## Example

Run the included example:

```bash
cd example
flutter run
```

The example has three pages: **Home** is a self-running, choreographed
presentation that walks through the core capabilities one focal animation at a
time — brand reveal, state labels, counters, waiting presets, the async
lifecycle, and inline corrections — backed by a few tap-anywhere live demos;
**Recipes** pairs live, working previews with copy-ready code for the most
common situations, including layout parity, selection, and emoji; **Editor**
shows a selectable document where typo corrections roll inline in the body copy.
