part of 'reel_text.dart';

class _SettledReelText extends StatelessWidget {
  const _SettledReelText({
    super.key,
    required this.text,
    required this.style,
    required this.textDirection,
    required this.locale,
    required this.strutStyle,
  });

  final String text;
  final TextStyle style;
  final TextDirection textDirection;
  final Locale? locale;
  final StrutStyle? strutStyle;

  @override
  Widget build(BuildContext context) {
    final runMetrics = _TextRunMetrics.of(
      context: context,
      style: style,
      textDirection: textDirection,
      locale: locale,
      strutStyle: strutStyle,
      text: text,
    );
    return SizedBox(
      height: runMetrics.height,
      child: Row(
        key: const ValueKey('reel_text_settled_glyphs'),
        mainAxisSize: MainAxisSize.min,
        textDirection: textDirection,
        children: [
          for (final (index, glyph) in text.characters.indexed)
            _SettledGlyphSlot(
              glyph,
              width: runMetrics.widthAt(index),
              height: runMetrics.height,
              style: style,
              textDirection: textDirection,
              locale: locale,
              strutStyle: strutStyle,
            ),
        ],
      ),
    );
  }
}

class _SettledGlyphSlot extends StatelessWidget {
  const _SettledGlyphSlot(
    this.glyph, {
    required this.width,
    required this.height,
    required this.style,
    required this.textDirection,
    required this.locale,
    required this.strutStyle,
  });

  final String glyph;
  final double width;
  final double height;
  final TextStyle style;
  final TextDirection textDirection;
  final Locale? locale;
  final StrutStyle? strutStyle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Align(
        alignment: _inlineStartAlignment(textDirection),
        child: _GlyphFace(
          glyph,
          width: width,
          height: height,
          style: style,
          textDirection: textDirection,
          locale: locale,
          strutStyle: strutStyle,
        ),
      ),
    );
  }
}

class _GlyphSlot extends StatelessWidget {
  const _GlyphSlot({
    required this.slot,
    required this.fromMetrics,
    required this.toMetrics,
    required this.progressMs,
    required this.style,
    required this.textDirection,
    required this.locale,
    required this.strutStyle,
  });

  final _SlotPlan slot;
  final _TextRunMetrics fromMetrics;
  final _TextRunMetrics toMetrics;
  final double progressMs;
  final TextStyle style;
  final TextDirection textDirection;
  final Locale? locale;
  final StrutStyle? strutStyle;

  @override
  Widget build(BuildContext context) {
    final metrics = _GlyphMetrics(
      fromWidth: slot.from.isEmpty ? 0 : fromMetrics.widthAt(slot.index),
      toWidth: slot.to.isEmpty ? 0 : toMetrics.widthAt(slot.index),
      height: math.max(fromMetrics.height, toMetrics.height),
    );

    if (!slot.changed) {
      return SizedBox(
        width: metrics.toWidth,
        height: metrics.height,
        child: _GlyphFace(
          slot.to,
          width: metrics.toWidth,
          height: metrics.height,
          style: style,
          textDirection: textDirection,
          locale: locale,
          strutStyle: strutStyle,
        ),
      );
    }
    final width = ui.lerpDouble(
      metrics.fromWidth,
      metrics.toWidth,
      slot.widthT(progressMs),
    )!;
    final textColor =
        style.color ?? DefaultTextStyle.of(context).style.color ?? Colors.black;
    final incomingColor = slot.color == null
        ? textColor
        : Color.lerp(slot.color, textColor, slot.colorT(progressMs))!;

    return ClipRect(
      clipper: const _VerticalSlotClipper(),
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        width: width,
        height: metrics.height,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: _inlineStartAlignment(textDirection),
          children: [
            if (slot.from.isNotEmpty)
              Opacity(
                opacity: slot.outOpacity(progressMs),
                child: Transform.translate(
                  offset: Offset(0, slot.outY(progressMs, metrics.height)),
                  child: Transform.rotate(
                    angle: -slot.tiltRadians * slot.outT(progressMs),
                    child: _GlyphFace(
                      slot.from,
                      width: metrics.fromWidth,
                      height: metrics.height,
                      style: style,
                      textDirection: textDirection,
                      locale: locale,
                      strutStyle: strutStyle,
                    ),
                  ),
                ),
              ),
            if (slot.to.isNotEmpty)
              Transform.translate(
                offset: Offset(0, slot.inY(progressMs, metrics.height)),
                child: Transform.rotate(
                  angle: slot.tiltRadians * (1 - slot.inT(progressMs)),
                  child: _GlyphFace(
                    slot.to,
                    width: metrics.toWidth,
                    height: metrics.height,
                    style: style.copyWith(color: incomingColor),
                    textDirection: textDirection,
                    locale: locale,
                    strutStyle: strutStyle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _VerticalSlotClipper extends CustomClipper<Rect> {
  const _VerticalSlotClipper();

  @override
  Rect getClip(Size size) {
    const horizontalBleed = 100000.0;
    return Rect.fromLTRB(
      -horizontalBleed,
      0,
      size.width + horizontalBleed,
      size.height,
    );
  }

  @override
  bool shouldReclip(covariant _VerticalSlotClipper oldClipper) => false;
}

class _GlyphFace extends StatelessWidget {
  const _GlyphFace(
    this.text, {
    required this.width,
    required this.height,
    required this.style,
    required this.textDirection,
    required this.locale,
    required this.strutStyle,
  });

  final String text;
  final double width;
  final double height;
  final TextStyle style;
  final TextDirection textDirection;
  final Locale? locale;
  final StrutStyle? strutStyle;

  @override
  Widget build(BuildContext context) {
    return OverflowBox(
      alignment: _inlineStartAlignment(textDirection),
      minWidth: width,
      maxWidth: width,
      minHeight: height,
      maxHeight: height,
      child: Align(
        alignment: _inlineStartAlignment(textDirection),
        child: _GlyphText(
          text,
          style: style,
          textDirection: textDirection,
          locale: locale,
          strutStyle: strutStyle,
        ),
      ),
    );
  }
}

class _GlyphText extends StatelessWidget {
  const _GlyphText(
    this.text, {
    required this.style,
    required this.textDirection,
    required this.locale,
    required this.strutStyle,
  });

  final String text;
  final TextStyle style;
  final TextDirection textDirection;
  final Locale? locale;
  final StrutStyle? strutStyle;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: style,
      textDirection: textDirection,
      locale: locale,
      strutStyle: strutStyle,
      softWrap: false,
    );
  }
}
