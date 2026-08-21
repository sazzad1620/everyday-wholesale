abstract final class AppBreakpoints {
  static const double mobile = 600;
  static const double tablet = 1024;
}

enum DeviceType { mobile, tablet, desktop }

DeviceType deviceTypeOf(double width) {
  if (width < AppBreakpoints.mobile) return DeviceType.mobile;
  if (width < AppBreakpoints.tablet) return DeviceType.tablet;
  return DeviceType.desktop;
}
