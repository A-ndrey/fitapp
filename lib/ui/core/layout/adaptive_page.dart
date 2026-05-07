import 'package:flutter/material.dart';

import 'responsive_layout.dart';

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
          minPadding: 20,
        );
        final contentMaxWidth = responsivePageMaxWidth(
          constraints.maxWidth,
          upperBound: maxWidth,
        );

        final resolvedPadding =
            padding ??
            EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 24);

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
