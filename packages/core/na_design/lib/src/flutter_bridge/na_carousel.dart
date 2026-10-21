import 'package:flutter/widgets.dart';
import 'package:na_design/src/theme/na_theme.dart';
import 'package:na_design/src/tokens/na_spacing.dart';
import 'package:na_design/src/values/na_values.dart';

extension type const NaPageIndex(int value) {}

final class NaCarousel extends StatefulWidget {
  const NaCarousel({
    required this.pages,
    required this.pageLabels,
    required this.backdrop,
    super.key,
  });

  static const double height = 180;

  final List<Widget> pages;
  final List<NaLabel> pageLabels;
  final NaBackdrop backdrop;

  @override
  State<NaCarousel> createState() => _NaCarouselState();
}

final class _NaCarouselState extends State<NaCarousel> {
  final PageController _controller = PageController();
  NaPageIndex _current = const NaPageIndex(0);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      SizedBox(
        height: NaCarousel.height,
        child: PageView(
          controller: _controller,
          onPageChanged: (page) => setState(() => _current = NaPageIndex(page)),
          children: List.unmodifiable(
            widget.pages.indexed.map(
              (entry) => Semantics(
                label: widget.pageLabels[entry.$1].value,
                child: entry.$2,
              ),
            ),
          ),
        ),
      ),
      if (widget.pages.length > 1)
        NaPageDots(
          count: NaPageIndex(widget.pages.length),
          current: _current,
          backdrop: widget.backdrop,
        ),
    ],
  );
}

final class NaPageDots extends StatelessWidget {
  const NaPageDots({
    required this.count,
    required this.current,
    required this.backdrop,
    super.key,
  });

  final NaPageIndex count;
  final NaPageIndex current;
  final NaBackdrop backdrop;

  @override
  Widget build(BuildContext context) {
    final colors = NaTheme.of(context).colors;
    final dot = switch (backdrop) {
      NaBackdrop.surface => colors.primary,
      NaBackdrop.primary => colors.onPrimary,
    };
    return ExcludeSemantics(
      child: Padding(
        padding: const EdgeInsets.only(top: Space.sm),
        child: Row(
          key: const Key('na-page-dots'),
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            count.value,
            (index) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.xs),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index == current.value
                      ? dot
                      : dot.withValues(alpha: 0.4),
                ),
                child: const SizedBox(width: 8, height: 8),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
