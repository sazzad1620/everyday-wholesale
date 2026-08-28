import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../shared/widgets/coming_soon_view.dart';

/// Category management (CRUD) — next up after products.
class AdminCategoriesPage extends StatelessWidget {
  const AdminCategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ComingSoonView(
      icon: Icons.category_outlined,
      title: 'admin.nav_categories'.tr(),
      message: 'admin.section_coming_soon'.tr(),
    );
  }
}
