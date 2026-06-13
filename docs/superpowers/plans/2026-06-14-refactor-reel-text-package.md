# Reel Text Package Refactor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Split the monolithic ReelText package internals into focused Dart parts, add a test-first implementation for the currently unused `textAlign` public parameter, and verify package quality.

**Architecture:** Keep `lib/src/reel_text.dart` as the single exported library file and move implementation sections into `part` files so private names stay library-private. Use the existing widget tests as the behavior safety net for the structural refactor, then add a failing widget test for `textAlign` before implementing alignment.

**Tech Stack:** Flutter package, Dart 3.12, `flutter_test`, `flutter_lints`, `dart analyze`.

---

### Task 1: Split Internal Library Parts

**Files:**
- Modify: `lib/src/reel_text.dart`
- Create: `lib/src/reel_text_api.dart`
- Create: `lib/src/reel_text_controller.dart`
- Create: `lib/src/reel_text_widget.dart`
- Create: `lib/src/reel_text_glyphs.dart`
- Create: `lib/src/reel_text_metrics.dart`
- Create: `lib/src/reel_text_plan.dart`

- [ ] **Step 1: Preserve the public export file**

Keep `lib/reel_text.dart` exporting `src/reel_text.dart`.

- [ ] **Step 2: Convert `lib/src/reel_text.dart` to the library shell**

Replace the body with the shared imports and `part` directives:

```dart
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

part 'reel_text_api.dart';
part 'reel_text_controller.dart';
part 'reel_text_glyphs.dart';
part 'reel_text_metrics.dart';
part 'reel_text_plan.dart';
part 'reel_text_widget.dart';
```

- [ ] **Step 3: Move public API types to `lib/src/reel_text_api.dart`**

Move `ReelTextDirection`, `ReelTextColorBuilder`, `ReelTextOptions`, `ReelWaitingFrameBuilder`, `_ReelWaitingKind`, `ReelWaiting`, `ReelTextFlashOptions`, and `chromatic`.

- [ ] **Step 4: Move controller types to `lib/src/reel_text_controller.dart`**

Move `ReelTextController`, `ReelTextProgress`, and `_ReelTextCommand`.

- [ ] **Step 5: Move widget state to `lib/src/reel_text_widget.dart`**

Move `ReelText` and `_ReelTextState`.

- [ ] **Step 6: Move glyph widget tree to `lib/src/reel_text_glyphs.dart`**

Move `_SettledReelText`, `_SettledGlyphSlot`, `_GlyphSlot`, `_VerticalSlotClipper`, `_GlyphFace`, and `_GlyphText`.

- [ ] **Step 7: Move measurement helpers to `lib/src/reel_text_metrics.dart`**

Move `_TextRunMetrics`, `_GlyphMetrics`, and `_inlineStartAlignment`.

- [ ] **Step 8: Move roll planning helpers to `lib/src/reel_text_plan.dart`**

Move `_RollPlan`, `_SlotPlan`, `_linear`, `_smoothstep`, and `_wobble`.

- [ ] **Step 9: Verify structural refactor**

Run: `dart format lib/src test/reel_text_test.dart`

Run: `flutter test`

Expected: all existing tests pass.

---

### Task 2: Implement `textAlign`

**Files:**
- Modify: `test/reel_text_test.dart`
- Modify: `lib/src/reel_text_widget.dart`
- Create or modify: `lib/src/reel_text_alignment.dart`
- Modify: `lib/src/reel_text.dart`

- [ ] **Step 1: Write the failing settled alignment test**

Add a widget test that places `ReelText('Go', textAlign: TextAlign.end)` inside a fixed-width parent and asserts the internal glyph row is aligned to the trailing edge.

- [ ] **Step 2: Run the focused test and verify RED**

Run: `flutter test test/reel_text_test.dart --plain-name "textAlign end aligns settled glyphs inside bounded width"`

Expected: FAIL because the glyph row remains at the leading edge.

- [ ] **Step 3: Implement bounded-width alignment**

Add a private `_ReelTextAlignment` widget that uses `LayoutBuilder` to keep intrinsic width when unconstrained, and wraps the rendered reel in `Align` when `constraints.hasBoundedWidth`.

- [ ] **Step 4: Wire alignment from `ReelText.build`**

Wrap the settled or rolling child with `_ReelTextAlignment(textAlign: widget.textAlign ?? TextAlign.start, textDirection: direction, child: child)` before `Semantics`.

- [ ] **Step 5: Run the focused test and verify GREEN**

Run: `flutter test test/reel_text_test.dart --plain-name "textAlign end aligns settled glyphs inside bounded width"`

Expected: PASS.

- [ ] **Step 6: Add a rolling alignment regression test**

Add a widget test for `ReelText('Go' -> 'Gone', textAlign: TextAlign.center)` in a fixed-width parent and assert the rolling row is centered while animation is in progress.

- [ ] **Step 7: Run alignment tests**

Run: `flutter test test/reel_text_test.dart --plain-name textAlign`

Expected: all alignment tests pass.

---

### Task 3: Final Package Verification

**Files:**
- Modify: `README.md`
- Modify: `CHANGELOG.md`

- [ ] **Step 1: Document implemented alignment behavior**

Add a short README note that `textAlign` is honored when the widget receives bounded width, matching Flutter text layout expectations for short labels.

- [ ] **Step 2: Add changelog entry**

Add an unreleased note for the internal split and `textAlign` support.

- [ ] **Step 3: Run final gates**

Run: `dart format .`

Run: `dart analyze .`

Run: `flutter test`

Run: `flutter pub publish --dry-run`

Expected: analyze has no issues, tests pass, and publish dry-run completes without blocking package errors.

