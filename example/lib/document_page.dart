import 'dart:async';

import 'package:flutter/material.dart';
import 'package:reel_text/reel_text.dart';

import 'studio.dart';

class AIDocumentPage extends StatefulWidget {
  const AIDocumentPage({super.key});

  @override
  State<AIDocumentPage> createState() => _AIDocumentPageState();
}

class _AIDocumentPageState extends State<AIDocumentPage> {
  static const _statuses = [
    'Calibrating tone',
    'Expanding scene',
    'Resolving citations',
    'Final polish',
  ];

  static const _phraseSets = [
    ['quiet launch', 'measured rollout', 'regional pilot', 'public beta'],
    ['thin notes', 'source-backed summary', 'editor memo', 'release brief'],
    ['manual review', 'policy pass', 'citation sweep', 'legal read'],
    ['rough ending', 'clean close', 'executive summary', 'next steps'],
  ];

  static const _pages = [
    _DocPage(
      title: 'Launch memo',
      section: '01 / strategy',
      lead:
          'The team needs a plan that keeps the launch small enough to learn from, '
          'but visible enough to produce real feedback. The model rewrites the '
          'opening around a ',
      tail:
          ', then trims claims that sound confident without evidence. Every edit '
          'keeps the page selectable so reviewers can copy exact passages.',
      body:
          'The first page is intentionally operational. It lists the audience, '
          'the first market, the success signal, and the risk owner. When a phrase '
          'rolls, the paragraph does not reflow more than Text would.',
    ),
    _DocPage(
      title: 'Research notes',
      section: '02 / evidence',
      lead: 'The second page turns scattered interview fragments into a ',
      tail:
          '. It preserves names of decisions, removes filler, and keeps the '
          'uncertain parts visible while the rest of the paragraph stays stable.',
      body:
          'Long passages remain ordinary selectable text. ReelText is reserved for '
          'the exact words being edited: labels, short claims, emoji markers, and '
          'status fragments that benefit from visible revision.',
    ),
    _DocPage(
      title: 'Risk register',
      section: '03 / control',
      lead:
          'Before the final pass, the assistant marks each unsupported claim for ',
      tail:
          '. The page keeps emoji-safe annotations like ✅, ⚠️, and 🧪 intact.',
      body:
          'This page simulates review work: duplicated claims are merged, deadlines '
          'are normalized, and owner names are left untouched. Reviewers can move '
          'between pages without losing the editing rhythm.',
    ),
    _DocPage(
      title: 'Final response',
      section: '04 / publish',
      lead: 'The last page replaces the draft conclusion with a ',
      tail:
          '. The animation is deliberately small: the document feels alive without '
          'turning long-form reading into a carousel of motion.',
      body:
          'A large document should still behave like a document. Layout stays exact, '
          'selection works through SelectionArea, and the animated phrases remain '
          'short enough to read while they change.',
    ),
  ];

  late final ReelTextController _status;
  late final List<ReelTextController> _phrases;
  late final PageController _pageController;
  Timer? _timer;
  int _tick = 0;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _status = ReelTextController(initialText: _statuses.first);
    _phrases = [
      for (final set in _phraseSets) ReelTextController(initialText: set.first),
    ];
    _pageController = PageController();
    _timer = Timer.periodic(const Duration(milliseconds: 1900), (_) {
      _tick++;
      _status.set(
        _statuses[_tick % _statuses.length],
        options: const ReelTextOptions(color: Studio.lime),
      );
      for (var i = 0; i < _phrases.length; i++) {
        _phrases[i].set(
          _phraseSets[i][_tick % _phraseSets[i].length],
          options: ReelTextOptions(colorBuilder: chromatic(from: 72 + i * 38)),
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _status.dispose();
    for (final phrase in _phrases) {
      phrase.dispose();
    }
    _pageController.dispose();
    super.dispose();
  }

  void _go(int delta) {
    final next = (_page + delta).clamp(0, _pages.length - 1);
    _pageController.animateToPage(
      next,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 860;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 16 : 28,
        vertical: 24,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StudioPanel(
                padding: const EdgeInsets.all(20),
                child: Wrap(
                  spacing: 18,
                  runSpacing: 14,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Neural editor',
                          style: Studio.mono(
                            size: 10.5,
                            color: Studio.muted,
                            weight: FontWeight.w700,
                            letterSpacing: 1.8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ReelText.controller(
                          controller: _status,
                          style: Studio.display(size: 24, letterSpacing: 0),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Page ${_page + 1} of ${_pages.length}',
                          style: Studio.mono(
                            color: Studio.text,
                            weight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton.outlined(
                          tooltip: 'Previous page',
                          onPressed: _page == 0 ? null : () => _go(-1),
                          icon: const Icon(Icons.chevron_left_rounded),
                        ),
                        const SizedBox(width: 6),
                        IconButton.outlined(
                          tooltip: 'Next page',
                          onPressed: _page == _pages.length - 1
                              ? null
                              : () => _go(1),
                          icon: const Icon(Icons.chevron_right_rounded),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (page) => setState(() => _page = page),
                  itemBuilder: (context, index) {
                    return _DocumentSheet(
                      page: _pages[index],
                      phrase: _phrases[index],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DocumentSheet extends StatelessWidget {
  const _DocumentSheet({required this.page, required this.phrase});

  final _DocPage page;
  final ReelTextController phrase;

  @override
  Widget build(BuildContext context) {
    final body = Studio.body(size: 16, height: 1.7, color: Studio.text);
    final phraseStyle = Studio.mono(
      size: 16,
      height: 1.35,
      color: Studio.lime,
      weight: FontWeight.w700,
    );

    return SelectionArea(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Studio.surfaceRaised,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Studio.borderBright),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 26, 28, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(page.section, style: Studio.mono(size: 11)),
              const SizedBox(height: 10),
              Text(
                page.title,
                style: Studio.display(size: 34, letterSpacing: 0),
              ),
              const SizedBox(height: 22),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(page.lead, style: body),
                  ReelText.controller(
                    controller: phrase,
                    options: const ReelTextOptions(
                      duration: Duration(milliseconds: 300),
                      stagger: Duration(milliseconds: 18),
                      exitOffset: Duration(milliseconds: 20),
                    ),
                    style: phraseStyle,
                  ),
                  Text(page.tail, style: body),
                ],
              ),
              const SizedBox(height: 20),
              Text(page.body, style: body),
              const SizedBox(height: 20),
              Text(
                'Reviewer note: drag across this page to select text; the animated phrase remains selectable as one full phrase.',
                style: Studio.body(size: 13, color: Studio.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DocPage {
  const _DocPage({
    required this.title,
    required this.section,
    required this.lead,
    required this.tail,
    required this.body,
  });

  final String title;
  final String section;
  final String lead;
  final String tail;
  final String body;
}
