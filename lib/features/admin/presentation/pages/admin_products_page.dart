import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../shared/widgets/coming_soon_view.dart';

/// Product management (CRUD + photo upload) — next up after the shell.
class AdminProductsPage extends StatelessWidget {
  const AdminProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ComingSoonView(
      icon: Icons.inventory_2_outlined,
      title: 'admin.nav_products'.tr(),
      message: 'admin.section_coming_soon'.tr(),
    );
  }
}
