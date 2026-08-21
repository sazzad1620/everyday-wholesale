import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../shared/widgets/coming_soon_view.dart';

class WishlistPage extends StatelessWidget {
  const WishlistPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('wishlist.title'.tr())),
      body: ComingSoonView(
        icon: Icons.favorite_border_rounded,
        title: 'wishlist.empty_title'.tr(),
        message: 'wishlist.empty_message'.tr(),
      ),
    );
  }
}
