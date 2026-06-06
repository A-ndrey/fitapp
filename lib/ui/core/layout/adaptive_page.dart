import 'package:flutter/material.dart';

import 'responsive_layout.dart';

abstract final class AppPageSpacing {
  static const double horizontalMin = 20;
  static const double sectionGap = 24;
  static const double headerContentGap = 12;
  static const double itemGap = 12;
  static const double compactGap = 8;
}

class AppPageSectionGap extends StatelessWidget {
  const AppPageSectionGap({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(height: AppPageSpacing.sectionGap);
  }
}

class AppPageHeaderContentGap extends StatelessWidget {
  const AppPageHeaderContentGap({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(height: AppPageSpacing.headerContentGap);
  }
}

class AdaptivePage extends StatelessWidget {
  const AdaptivePage({
    required this.children,
    super.key,
    this.padding,
    this.maxWidth = 1280,
    this.fillRemaining,
  });

  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  final double maxWidth;
  final Widget? fillRemaining;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = responsivePageHorizontalPadding(
          constraints.maxWidth,
          minPadding: AppPageSpacing.horizontalMin,
        );
        final contentMaxWidth = responsivePageMaxWidth(
          constraints.maxWidth,
          upperBound: maxWidth,
        );

        final resolvedPadding =
            padding ??
            EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: AppPageSpacing.sectionGap,
            );

        if (fillRemaining != null) {
          final textDirection = Directionality.of(context);
          final edgeInsets = resolvedPadding.resolve(textDirection);

          return SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: contentMaxWidth),
                child: CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.only(
                        left: edgeInsets.left,
                        top: edgeInsets.top,
                        right: edgeInsets.right,
                      ),
                      sliver: SliverList.list(children: children),
                    ),
                    SliverFillRemaining(
                      hasScrollBody: true,
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: edgeInsets.left,
                          right: edgeInsets.right,
                          bottom: edgeInsets.bottom,
                        ),
                        child: fillRemaining,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: contentMaxWidth),
              child: ListView(padding: resolvedPadding, children: children),
            ),
          ),
        );
      },
    );
  }
}
