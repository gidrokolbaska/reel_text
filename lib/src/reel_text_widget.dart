part of 'reel_text.dart';

/// Text widget that rolls changed glyphs through clipped slots.
class ReelText extends StatefulWidget {
  /// Creates a declarative reel text widget.
  const ReelText(
    this.text, {
    super.key,
    this.options = const ReelTextOptions(),
    this.style,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.strutStyle,
    this.semanticsLabel,
    this.respectDisableAnimations = true,
  }) : controller = null;

  /// Creates an imperative reel text widget driven by [controller].
  const ReelText.controller({
    super.key,
    required ReelTextController this.controller,
    this.options = const ReelTextOptions(),
    this.style,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.strutStyle,
    this.semanticsLabel,
    this.respectDisableAnimations = true,
  }) : text = null;

  /// Target text in declarative mode.
  final String? text;

  /// Controller in imperative mode.
  final ReelTextController? controller;

  /// Default animation options.
  final ReelTextOptions options;

  /// Text style.
  final TextStyle? style;

  /// Text alignment.
  final TextAlign? textAlign;

  /// Text direction.
  final TextDirection? textDirection;

  /// Text locale.
  final Locale? locale;

  /// Strut style.
  final StrutStyle? strutStyle;

  /// Accessibility label. Defaults to the current value.
  final String? semanticsLabel;

  /// Snaps to the target text without rolling when the platform requests
  /// reduced motion ([MediaQuery.disableAnimationsOf]).
  final bool respectDisableAnimations;

  @override
  State<ReelText> createState() => _ReelTextState();
}

class _ReelTextState extends State<ReelText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late String _displayedText;
  String? _targetText;
  _RollPlan? _plan;
  _ReelTextCommand? _pending;

  String get _effectiveText => widget.controller?.value ?? widget.text ?? '';

  @override
  void initState() {
    super.initState();
    _displayedText = _effectiveText;
    _controller = AnimationController(vsync: this)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _finishRoll();
        }
      });
    widget.controller?.addListener(_handleControllerChange);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Snap an in-flight roll when the platform switches to reduced motion.
    if (_animationsDisabled && _targetText != null) {
      _controller.stop();
      _displayedText = _targetText!;
      _targetText = null;
      _plan = null;
      _pending = null;
    }
  }

  @override
  void didUpdateWidget(covariant ReelText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_handleControllerChange);
      widget.controller?.addListener(_handleControllerChange);
      _displayedText = _effectiveText;
      _targetText = null;
      _plan = null;
      _controller.stop();
    } else if (widget.controller == null && oldWidget.text != widget.text) {
      _rollTo(widget.text ?? '', widget.options);
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_handleControllerChange);
    _controller.dispose();
    super.dispose();
  }

  void _handleControllerChange() {
    if (!mounted) {
      return;
    }
    final command = widget.controller!._currentCommand;
    if (command == null) {
      return;
    }
    _rollTo(
      command.text,
      widget.options._merge(command.options),
      force: command.force,
    );
  }

  bool get _animationsDisabled =>
      widget.respectDisableAnimations &&
      (MediaQuery.maybeDisableAnimationsOf(context) ?? false);

  void _rollTo(String text, ReelTextOptions options, {bool force = false}) {
    if (_animationsDisabled) {
      _controller.stop();
      setState(() {
        _displayedText = text;
        _targetText = null;
        _plan = null;
        _pending = null;
      });
      return;
    }

    if (_controller.isAnimating && !options.interrupt) {
      if (force || text != _targetText) {
        _pending = _ReelTextCommand(text, options, force: force);
      }
      return;
    }

    if (_controller.isAnimating && options.interrupt && _targetText != null) {
      _controller.stop();
      _displayedText = _targetText!;
      _pending = null;
      _plan = null;
    }

    if (_displayedText == text && !force) {
      setState(() {
        _targetText = text;
      });
      return;
    }

    final plan = _RollPlan.create(
      fromText: _displayedText,
      toText: text,
      options: options,
    );

    setState(() {
      _targetText = text;
      _plan = plan;
    });

    if (!plan.hasMotion) {
      _finishRoll();
      return;
    }

    _controller.duration = plan.totalDuration;
    _controller.forward(from: 0);
  }

  void _finishRoll() {
    final finishedText = _targetText;
    if (finishedText == null) {
      return;
    }
    _controller.stop();
    setState(() {
      _displayedText = finishedText;
      _plan = null;
      _targetText = null;
    });

    final pending = _pending;
    _pending = null;
    if (pending != null && (pending.force || pending.text != _displayedText)) {
      _rollTo(
        pending.text,
        widget.options._merge(pending.options),
        force: pending.force,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final direction =
        widget.textDirection ??
        Directionality.maybeOf(context) ??
        TextDirection.ltr;
    final defaultStyle = DefaultTextStyle.of(context).style;
    final style = defaultStyle.merge(widget.style);
    final visibleText = _targetText ?? _displayedText;
    final plan = _plan;

    Widget child;
    if (plan == null) {
      child = _SettledReelText(
        text: _displayedText,
        key: const ValueKey('reel_text_settled'),
        style: style,
        textDirection: direction,
        locale: widget.locale,
        strutStyle: widget.strutStyle,
      );
    } else {
      child = AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final fromMetrics = _TextRunMetrics.of(
            context: context,
            style: style,
            textDirection: direction,
            locale: widget.locale,
            strutStyle: widget.strutStyle,
            text: plan.fromText,
          );
          final toMetrics = _TextRunMetrics.of(
            context: context,
            style: style,
            textDirection: direction,
            locale: widget.locale,
            strutStyle: widget.strutStyle,
            text: plan.toText,
          );
          return Row(
            key: const ValueKey('reel_text_rolling'),
            mainAxisSize: MainAxisSize.min,
            textDirection: direction,
            children: [
              for (final slot in plan.slots)
                _GlyphSlot(
                  slot: slot,
                  fromMetrics: fromMetrics,
                  toMetrics: toMetrics,
                  progressMs:
                      _controller.value * plan.totalDuration.inMilliseconds,
                  style: style,
                  textDirection: direction,
                  locale: widget.locale,
                  strutStyle: widget.strutStyle,
                ),
            ],
          );
        },
      );
    }

    child = _ReelTextAlignment(
      textAlign: widget.textAlign ?? TextAlign.start,
      textDirection: direction,
      child: child,
    );

    return Semantics(
      label: widget.semanticsLabel ?? visibleText,
      child: _ReelTextSelection(
        text: visibleText,
        style: style,
        textAlign: widget.textAlign ?? TextAlign.start,
        textDirection: direction,
        locale: widget.locale,
        strutStyle: widget.strutStyle,
        child: child,
      ),
    );
  }
}
