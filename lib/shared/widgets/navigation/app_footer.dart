import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../config/routes/route_paths.dart';
import '../../../core/constants/asset_paths.dart';
import '../../../core/utils/responsive/breakpoints.dart';
import '../../../features/support/presentation/pages/support_page.dart' show displayEmail, kSupportEmail;
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/toast.dart';

const String kFacebookPageUrl = 'https://www.facebook.com/share/1DmKrjfshc/';

/// Marketing footer shown below a top-level page's content at tablet/desktop
/// width — FAQ accordion, shop/company/contact links and a secure-checkout
/// note. A no-op below [AppBreakpoints.mobile]: this much link/content
/// density belongs on a wide, browsable page, not under a phone's bottom
/// nav, where the drawer and Account screen already cover the same ground.
///
/// Self-gating on width (not platform) so it behaves exactly like
/// [DesktopSidebar]/[DesktopBody] — it also shows on a native tablet app at
/// this width, which keeps this page consistent with the rest of the wide
/// layout rather than leaving it with a sidebar but no footer.
///
/// Drop this as the last child of a top-level page's own scrollable
/// (`ListView`/similar) content — it needs to scroll with that content, not
/// sit outside it, so it isn't wired in by [DesktopBody] itself.
class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= AppBreakpoints.mobile;
    if (!isWide) return const SizedBox.shrink();

    final hairline = AppColors.textSecondary.withValues(alpha: 0.15);

    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.xl),
      decoration: BoxDecoration(color: AppColors.inputFill, border: Border(top: BorderSide(color: hairline))),
      // A Material ancestor, not just the Container above — ListTile (inside
      // the FAQ's ExpansionTile) paints its background/ink splashes on the
      // nearest Material, and the decorated Container in between would
      // otherwise hide them. Same fix as DesktopSidebar.
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _FooterFaq(),
              const SizedBox(height: AppSpacing.xl),
              Divider(height: 1, color: hairline),
              const SizedBox(height: AppSpacing.xl),
              const _FooterColumns(),
              const SizedBox(height: AppSpacing.xl),
              const _SecureCheckoutNote(),
              const SizedBox(height: AppSpacing.lg),
              Divider(height: 1, color: hairline),
              const SizedBox(height: AppSpacing.md),
              const _FooterBottomBar(),
            ],
          ),
        ),
      ),
    );
  }
}

class _FooterFaq extends StatelessWidget {
  const _FooterFaq();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('footer.faq_title'.tr(), style: AppTextStyles.headline),
        const SizedBox(height: AppSpacing.xs),
        Text('footer.faq_subtitle'.tr(), style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: AppSpacing.sm),
        _FaqTile(question: 'footer.faq_q1'.tr(), answer: 'footer.faq_a1'.tr()),
        _FaqTile(question: 'footer.faq_q2'.tr(), answer: 'footer.faq_a2'.tr()),
        _FaqTile(question: 'footer.faq_q3'.tr(), answer: 'footer.faq_a3'.tr()),
        _FaqTile(question: 'footer.faq_q4'.tr(), answer: 'footer.faq_a4'.tr()),
      ],
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: AppSpacing.sm),
        iconColor: AppColors.primary,
        collapsedIconColor: AppColors.textSecondary,
        title: Text(question, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(answer, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary, height: 1.4)),
          ),
        ],
      ),
    );
  }
}

/// Brand / Shop / Company / Contact, laid out as a [Wrap] so it reflows from
/// four columns down to two (or one) at tablet width instead of squeezing.
class _FooterColumns extends StatelessWidget {
  const _FooterColumns();

  static const double _brandWidth = 260;
  static const double _shopWidth = 160;
  static const double _companyWidth = 190;
  static const double _contactWidth = 260;
  static const double _spacing = AppSpacing.xl;

  /// The width the four columns need side by side in a single row — above
  /// this, [Wrap] keeps them on one line; below it, [Wrap] drops at least
  /// one down to a second row on its own. There's no way to ask a [Wrap]
  /// after the fact whether it wrapped, so this mirrors its own math to
  /// decide the same thing ahead of time, for [_BrandColumn]'s social
  /// button below.
  static const double _singleRowWidth = _brandWidth + _shopWidth + _companyWidth + _contactWidth + 3 * _spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final singleRow = constraints.maxWidth >= _singleRowWidth;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: _spacing,
              runSpacing: AppSpacing.lg,
              children: [
                SizedBox(width: _brandWidth, child: _BrandColumn(showSocial: singleRow)),
                const SizedBox(width: _shopWidth, child: _ShopColumn()),
                const SizedBox(width: _companyWidth, child: _CompanyColumn()),
                const SizedBox(width: _contactWidth, child: _ContactColumn()),
              ],
            ),
            // Tucked inside the brand column when everything fits on one
            // row (it reads fine right under the blurb there), but moved
            // below all four once they wrap to more than one row — left
            // there, it would land awkwardly between whichever column
            // follows the brand column and the row below it.
            if (!singleRow) ...[
              const SizedBox(height: AppSpacing.lg),
              _SocialButton(label: 'footer.follow_us'.tr(), url: kFacebookPageUrl),
            ],
          ],
        );
      },
    );
  }
}

class _BrandColumn extends StatelessWidget {
  const _BrandColumn({required this.showSocial});

  /// False once [_FooterColumns] has moved the social button below all
  /// four columns instead (see there) — this column just skips it then.
  final bool showSocial;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(AssetPaths.logo, height: 32),
            const SizedBox(width: 6),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'header.brand_primary'.tr(),
                    style: const TextStyle(fontFamily: 'Oswald', fontWeight: FontWeight.w600),
                  ),
                  const TextSpan(text: ' '),
                  TextSpan(
                    text: 'header.brand_secondary'.tr(),
                    style: const TextStyle(fontFamily: 'Oswald', fontWeight: FontWeight.w300),
                  ),
                ],
              ),
              style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'footer.about_blurb'.tr(),
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary, height: 1.5),
        ),
        if (showSocial) ...[
          const SizedBox(height: AppSpacing.md),
          _SocialButton(label: 'footer.follow_us'.tr(), url: kFacebookPageUrl),
        ],
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({required this.label, required this.url});

  final String label;
  final String url;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
        borderRadius: BorderRadius.circular(20),
        child: const Padding(
          padding: EdgeInsets.all(8),
          child: DecoratedBox(
            decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
            child: Padding(padding: EdgeInsets.all(8), child: Icon(Icons.facebook, size: 18, color: Colors.white)),
          ),
        ),
      ),
    );
  }
}

class _ShopColumn extends StatelessWidget {
  const _ShopColumn();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('footer.shop_title'.tr(), style: AppTextStyles.title),
        const SizedBox(height: AppSpacing.sm),
        _FooterLink(label: 'nav.home'.tr(), onTap: () => context.go(RoutePaths.home)),
        _FooterLink(label: 'nav.category'.tr(), onTap: () => context.go(RoutePaths.categories)),
        _FooterLink(label: 'nav.wishlist'.tr(), onTap: () => context.go(RoutePaths.wishlist)),
        _FooterLink(label: 'nav.cart'.tr(), onTap: () => context.go(RoutePaths.cart)),
        _FooterLink(label: 'nav.offers'.tr(), onTap: () => context.push(RoutePaths.offers)),
      ],
    );
  }
}

class _CompanyColumn extends StatelessWidget {
  const _CompanyColumn();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('footer.company_title'.tr(), style: AppTextStyles.title),
        const SizedBox(height: AppSpacing.sm),
        _FooterLink(label: 'drawer.about'.tr(), onTap: () => context.push(RoutePaths.about)),
        _FooterLink(label: 'legal.privacy_title'.tr(), onTap: () => context.push(RoutePaths.privacyPolicy)),
        _FooterLink(label: 'legal.terms_title'.tr(), onTap: () => context.push(RoutePaths.termsConditions)),
        _FooterLink(label: 'legal.refunds_title'.tr(), onTap: () => context.push(RoutePaths.refundPolicy)),
        _FooterLink(label: 'support.title'.tr(), onTap: () => context.push(RoutePaths.support)),
      ],
    );
  }
}

class _ContactColumn extends StatelessWidget {
  const _ContactColumn();

  Future<void> _openMaps() {
    final query = Uri.encodeComponent('footer.address'.tr());
    return launchUrl(
      Uri.parse('https://www.google.com/maps/search/?api=1&query=$query'),
      mode: LaunchMode.externalApplication,
    );
  }

  Future<void> _copyEmail(BuildContext context) async {
    await Clipboard.setData(const ClipboardData(text: kSupportEmail));
    if (!context.mounted) return;
    AppToast.show(context, 'support.email_copied'.tr(), type: ToastType.success);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('footer.contact_title'.tr(), style: AppTextStyles.title),
        const SizedBox(height: AppSpacing.sm),
        _ContactLine(icon: Icons.location_on_outlined, text: 'footer.address'.tr(), onTap: _openMaps),
        const SizedBox(height: AppSpacing.xs),
        _ContactLine(icon: Icons.mail_outline_rounded, text: displayEmail(kSupportEmail), onTap: () => _copyEmail(context)),
      ],
    );
  }
}

class _ContactLine extends StatelessWidget {
  const _ContactLine({required this.icon, required this.text, required this.onTap});

  final IconData icon;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(text, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary, height: 1.3)),
            ),
          ],
        ),
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  const _FooterLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: onTap,
        child: Text(label, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
      ),
    );
  }
}

class _SecureCheckoutNote extends StatelessWidget {
  const _SecureCheckoutNote();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.lock_rounded, size: 18, color: AppColors.primary),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '${'footer.secure_checkout'.tr()}. ',
                  style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                ),
                TextSpan(
                  text: 'footer.secure_checkout_detail'.tr(),
                  style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        const Icon(Icons.credit_card_rounded, size: 20, color: AppColors.textSecondary),
      ],
    );
  }
}

class _FooterBottomBar extends StatelessWidget {
  const _FooterBottomBar();

  @override
  Widget build(BuildContext context) {
    return Text(
      'footer.copyright'.tr(namedArgs: {'year': '${DateTime.now().year}'}),
      textAlign: TextAlign.center,
      style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
    );
  }
}
