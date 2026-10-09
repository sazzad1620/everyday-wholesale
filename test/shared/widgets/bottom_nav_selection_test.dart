import 'package:everyday_wholesale/shared/widgets/navigation/main_bottom_nav_bar.dart';
import 'package:flutter_test/flutter_test.dart';

/// A tab lights up only on its own top-level page, not on pages opened from it.
void main() {
  test('top-level pages select their tab', () {
    expect(selectedTabIndex(branchIndex: 0, path: '/'), 0);
    expect(selectedTabIndex(branchIndex: 1, path: '/categories'), 1);
    expect(selectedTabIndex(branchIndex: 2, path: '/wishlist'), 2);
    expect(selectedTabIndex(branchIndex: 3, path: '/cart'), 3);
    expect(selectedTabIndex(branchIndex: 1, path: '/categories/'), 1, reason: 'trailing slash');
  });

  test('pages opened from a tab select nothing', () {
    expect(selectedTabIndex(branchIndex: 0, path: '/home/category/rice'), -1, reason: 'category page');
    expect(selectedTabIndex(branchIndex: 0, path: '/home/category/rice/browse/basmati'), -1, reason: 'subcategory');
    expect(selectedTabIndex(branchIndex: 0, path: '/home/category/rice/product/p1'), -1, reason: 'product');
  });

  test('outside the tab shell nothing is selected', () {
    expect(selectedTabIndex(branchIndex: null, path: '/account'), -1);
    expect(selectedTabIndex(branchIndex: -1, path: '/'), -1);
    expect(selectedTabIndex(branchIndex: 0, path: '/cart'), -1, reason: 'path of another tab than the stack');
  });
}
