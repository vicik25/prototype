import 'package:material_ui/material_ui.dart';

class Responsive {
  static bool isMobile(BuildContext context) => MediaQuery.sizeOf(context).width < 768;

  static bool isDesktop(BuildContext context) => MediaQuery.sizeOf(context).width >= 768;

  static double maxContentWidth(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width > 1200 ? 1200 : width;
  }
}
