import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../shared/widgets/coming_soon_view.dart';

/// Order management (view/update status) — last of the four sections.
class AdminOrdersPage extends StatelessWidget {
  const AdminOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ComingSoonView(
      icon: Icons.receipt_long_outlined,
      title: 'admin.nav_orders'.tr(),
      message: 'admin.section_coming_soon'.tr(),
    );
  }
}
