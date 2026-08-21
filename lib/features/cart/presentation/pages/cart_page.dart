import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../shared/widgets/coming_soon_view.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('cart.title'.tr())),
      body: ComingSoonView(
        icon: Icons.shopping_bag_outlined,
        title: 'cart.empty_title'.tr(),
        message: 'cart.empty_message'.tr(),
      ),
    );
  }
}
