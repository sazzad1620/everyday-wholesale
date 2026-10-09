import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Tapping a bottom tab always opens that tab's top-level page (see
/// `MainBottomNavBar`). The page that was open inside that tab — a product, a
/// category list — is then popped, and its slide-out animation would play on
/// screen for a moment while the tab is already showing: the user would see the
/// old product page "at a glance" before Home appears.
///
/// [TabReset.run] marks that moment; [HiddenWhileTabReset] pages draw nothing
/// while it lasts, so the top-level page is simply there at once. The pages are
/// removed by the router as usual, just unseen.
abstract final class TabReset {
  static final ValueNotifier<bool> _active = ValueNotifier<bool>(false);
  static Timer? _timer;

  /// Longer than a page transition (~300 ms), short enough that a quick next tap
  /// on a product is never affected.
  static const Duration _hideFor = Duration(milliseconds: 420);

  static ValueListenable<bool> get active => _active;

  /// Runs [navigate] (the tab switch) with old pages hidden.
  static void run(VoidCallback navigate) {
    _active.value = true;
    _timer?.cancel();
    _timer = Timer(_hideFor, () => _active.value = false);
    navigate();
  }
}

/// Wrap a page that lives inside a tab (a category list, a product) so
/// [TabReset] can hide it while it is being closed by a tab switch.
class HiddenWhileTabReset extends StatelessWidget {
  const HiddenWhileTabReset({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: TabReset.active,
      // `maintainState`: the page keeps its state (scroll position, loaded
      // data) in case the tap was on the tab that is already open.
      builder: (context, resetting, child) => Visibility(visible: !resetting, maintainState: true, child: child!),
      child: child,
    );
  }
}
