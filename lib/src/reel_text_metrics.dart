part of 'reel_text.dart';

class _TextRunMetrics {
  const _TextRunMetrics({required this.widths, required this.height});

  final List<double> widths;
  final double height;

  double widthAt(int index) {
    if (index < 0 || index >= widths.length) {
      return 0;
    }
    return widths[index];
  }

  static _TextRunMetrics of({
    required BuildContext context,
    required TextStyle style,
    required TextDirection textDirection,
    required Locale? locale,
    required StrutStyle? strutStyle,
    required String text,
  }) {
    if (text.isEmpty) {
      final metrics = _GlyphMetrics.of(
        context: context,
        style: style,
        textDirection: textDirection,
        locale: locale,
        strutStyle: strutStyle,
        from: ' ',
        to: ' ',
      );
      return _TextRunMetrics(widths: const <double>[], height: metrics.height);
    }

    final textScaler =
        MediaQuery.maybeTextScalerOf(context) ?? TextScaler.noScaling;
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: textDirection,
      textScaler: textScaler,
      locale: locale,
      strutStyle: strutStyle,
      maxLines: 1,
    )..layout();

    final chars = text.characters.toList();
    final offsets = <int>[0];
    var offset = 0;
    for (final char in chars) {
      offset += char.length;
      offsets.add(offset);
    }

    final widths = <double>[];
    for (var i = 0; i < chars.length; i++) {
      final start = _caretDx(painter, offsets[i]);
      final end = _caretDx(painter, offsets[i + 1]);
      final width = (end - start).abs();
      widths.add(width);
    }

    final measured = widths.fold<double>(0, (sum, width) => sum + width);
    if (widths.isNotEmpty && (measured - painter.size.width).abs() > 0.01) {
      widths[widths.length - 1] += painter.size.width - measured;
    }

    final textHeight = painter.size.height;
    final verticalBreathingRoom = math.max(6.0, textHeight * 0.18);
    return _TextRunMetrics(
      widths: widths,
      height: textHeight + verticalBreathingRoom * 2,
    );
  }

  static double _caretDx(TextPainter painter, int offset) {
    return painter
        .getOffsetForCaret(TextPosition(offset: offset), Rect.zero)
        .dx;
  }
}

class _GlyphMetrics {
  const _GlyphMetrics({
    required this.fromWidth,
    required this.toWidth,
    required this.height,
  });

  final double fromWidth;
  final double toWidth;
  final double height;

  static _GlyphMetrics of({
    required BuildContext context,
    required TextStyle style,
    required TextDirection textDirection,
    required Locale? locale,
    required StrutStyle? strutStyle,
    required String from,
    required String to,
  }) {
    final textScaler =
        MediaQuery.maybeTextScalerOf(context) ?? TextScaler.noScaling;
    final fromSize = _measure(
      text: from.isEmpty ? ' ' : from,
      style: style,
      textDirection: textDirection,
      locale: locale,
      strutStyle: strutStyle,
      textScaler: textScaler,
    );
    final toSize = _measure(
      text: to.isEmpty ? ' ' : to,
      style: style,
      textDirection: textDirection,
      locale: locale,
      strutStyle: strutStyle,
      textScaler: textScaler,
    );
    final textHeight = math.max(fromSize.height, toSize.height);
    final verticalBreathingRoom = math.max(6.0, textHeight * 0.18);
    return _GlyphMetrics(
      fromWidth: from.isEmpty ? 0 : fromSize.width,
      toWidth: to.isEmpty ? 0 : toSize.width,
      height: textHeight + verticalBreathingRoom * 2,
    );
  }

  static Size _measure({
    required String text,
    required TextStyle style,
    required TextDirection textDirection,
    required Locale? locale,
    required StrutStyle? strutStyle,
    required TextScaler textScaler,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: textDirection,
      textScaler: textScaler,
      locale: locale,
      strutStyle: strutStyle,
      maxLines: 1,
    )..layout();
    return painter.size;
  }
}

Alignment _inlineStartAlignment(TextDirection textDirection) {
  return textDirection == TextDirection.rtl
      ? Alignment.centerRight
      : Alignment.centerLeft;
}
