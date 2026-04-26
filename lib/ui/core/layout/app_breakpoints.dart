class AppBreakpoints {
  const AppBreakpoints._();

  static const double compactMax = 599;
  static const double mediumMin = 600;
  static const double expandedMin = 840;
  static const double largeMin = 1200;

  static bool isCompact(double width) => width <= compactMax;

  static bool isMediumOrLarger(double width) => width >= mediumMin;

  static bool isExpandedOrLarger(double width) => width >= expandedMin;

  static bool isLarge(double width) => width >= largeMin;
}
