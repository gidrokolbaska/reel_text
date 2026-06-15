part of 'reel_text.dart';

class _ReelTextContent {
  const _ReelTextContent({
    required this.span,
    required this.plainText,
    required this.glyphs,
  });

  final InlineSpan span;
  final String plainText;
  final List<_StyledGlyph> glyphs;

  factory _ReelTextContent.plain(String text, TextStyle style) {
    return _ReelTextContent(
      span: TextSpan(text: text, style: style),
      plainText: text,
      glyphs: [for (final glyph in text.characters) _StyledGlyph(glyph, style)],
    );
  }

  factory _ReelTextContent.rich(InlineSpan span, TextStyle style) {
    final glyphs = <_StyledGlyph>[];
    _collectGlyphs(span, style, glyphs);
    return _ReelTextContent(
      span: TextSpan(style: style, children: [span]),
      plainText: span.toPlainText(
        includeSemanticsLabels: false,
        includePlaceholders: false,
      ),
      glyphs: glyphs,
    );
  }

  _StyledGlyph? glyphAt(int index) {
    if (index < 0 || index >= glyphs.length) {
      return null;
    }
    return glyphs[index];
  }
}

class _StyledGlyph {
  const _StyledGlyph(this.text, this.style);

  final String text;
  final TextStyle style;
}

void _collectGlyphs(
  InlineSpan span,
  TextStyle inherited,
  List<_StyledGlyph> glyphs,
) {
  if (span is! TextSpan) {
    throw FlutterError(
      'ReelText.rich currently supports TextSpan trees only. '
      'WidgetSpan cannot be split into rolling glyphs.',
    );
  }

  final style = inherited.merge(span.style);
  final text = span.text;
  if (text != null && text.isNotEmpty) {
    for (final glyph in text.characters) {
      glyphs.add(_StyledGlyph(glyph, style));
    }
  }

  final children = span.children;
  if (children == null) {
    return;
  }
  for (final child in children) {
    _collectGlyphs(child, style, glyphs);
  }
}

TextSpan _transparentTextSpan(InlineSpan span) {
  if (span is! TextSpan) {
    throw FlutterError(
      'ReelText.rich currently supports TextSpan trees only. '
      'WidgetSpan cannot be used for the hidden selection surface.',
    );
  }

  final transparentStyle = (span.style ?? const TextStyle()).copyWith(
    color: Colors.transparent,
    decorationColor: Colors.transparent,
  );
  return TextSpan(
    text: span.text,
    style: transparentStyle,
    recognizer: span.recognizer,
    mouseCursor: span.mouseCursor,
    onEnter: span.onEnter,
    onExit: span.onExit,
    semanticsLabel: span.semanticsLabel,
    locale: span.locale,
    spellOut: span.spellOut,
    children: [
      for (final child in span.children ?? const <InlineSpan>[])
        _transparentTextSpan(child),
    ],
  );
}
