import 'package:flutter/material.dart';

import 'app_breakpoints.dart';

class AdaptivePage extends StatelessWidget {
  const AdaptivePage({
    required this.children,
    super.key,
    this.padding,
    this.maxWidth = 1120,
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
        final horizontalPadding = AppBreakpoints.isCompact(constraints.maxWidth)
            ? 16.0
            : 24.0;

        final resolvedPadding =
            padding ??
            EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 24);

        if (fillRemaining != null) {
          final textDirection = Directionality.of(context);
          final edgeInsets = resolvedPadding.resolve(textDirection);

          return SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
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
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: ListView(padding: resolvedPadding, children: children),
            ),
          ),
        );
      },
    );
  }
}
