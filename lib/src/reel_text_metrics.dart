part of 'reel_text.dart';

class _TextRunMetrics {
  const _TextRunMetrics({
    required this.widths,
    required this.width,
    required this.height,
  });

  final List<double> widths;
  final double width;
  final double height;

  double widthAt(int index) {
    if (index < 0 || index >= widths.length) {
      return 0;
    }
    return widths[index];
  }

  static _TextRunMetrics of({
    required BuildContext context,
    required InlineSpan span,
    required TextDirection textDirection,
    required Locale? locale,
    required StrutStyle? strutStyle,
    required String text,
  }) {
    final textScaler =
        MediaQuery.maybeTextScalerOf(context) ?? TextScaler.noScaling;
    final painter = TextPainter(
      text: span,
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

    final totalWidth = widths.fold<double>(0, (sum, width) => sum + width);
    return _TextRunMetrics(
      widths: widths,
      width: totalWidth,
      height: painter.size.height,
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
}

Alignment _inlineStartAlignment(TextDirection textDirection) {
  return textDirection == TextDirection.rtl
      ? Alignment.centerRight
      : Alignment.centerLeft;
}
