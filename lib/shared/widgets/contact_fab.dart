import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/routes/app_router.dart';
import '../../config/routes/route_paths.dart';
import '../../core/constants/asset_paths.dart';
import '../../core/utils/responsive/breakpoints.dart';
import '../theme/app_spacing.dart';

const String kMessengerUrl = 'https://www.messenger.com/t/746486148555290';
const String kWhatsAppUrl = 'https://wa.me/819040783160';

/// Wraps the whole app in [EverydayWholesaleApp]'s `MaterialApp.router`
/// `builder`, adding the floating "chat with us" buttons (WhatsApp +
/// Messenger), bottom-right, on every customer-facing page — web, Android
/// and iOS alike (unlike [AppFooter], there's no phone-width cutoff here:
/// this is exactly the kind of compact, always-useful control a phone app
/// would want).
///
/// Mounted once, as a single wrapper around [child] rather than wired into
/// every page, so it survives navigation without re-triggering its entrance
/// animation and no page needs to know it exists. It has to be a genuine
/// *wrapper* (not a sibling next to [child] in a bare `Stack`) for the
/// scroll-direction tracking below to work at all: a [NotificationListener]
/// only ever sees notifications bubbling up from its own descendants, and
/// the page's scroll view is one only once this sits above it in the tree.
///
/// Hidden during checkout (keep that flow distraction-free, same reasoning
/// as [AppFooter]) and on admin pages (an internal tool, not a storefront
/// surface) — checked against the single [appRouter] instance directly
/// rather than `GoRouter.of(context)`, since this sits above where go_router
/// establishes that lookup.
class ContactFabOverlay extends StatefulWidget {
  const ContactFabOverlay({super.key, required this.child});

  final Widget child;

  static const List<String> _hiddenPrefixes = [RoutePaths.checkout, RoutePaths.admin];

  @override
  State<ContactFabOverlay> createState() => _ContactFabOverlayState();
}

class _ContactFabOverlayState extends State<ContactFabOverlay> {
  bool _visible = true;

  bool _onNotification(ScrollNotification notification) {
    // Driven by the raw per-frame delta rather than the higher-level
    // [UserScrollNotification.direction]: hand-testing showed the latter
    // never fires for some scroll sources even though ordinary
    // start/update/end notifications do, making it the less reliable
    // signal of the two despite being the one built for this.
    if (notification is! ScrollUpdateNotification) return false;
    // Vertical only: a page's own scroll should drive this, not an
    // unrelated horizontal carousel/row (the home promo banner, a product
    // row) whose notifications bubble up through here too.
    if (notification.metrics.axis != Axis.vertical) return false;
    final delta = notification.scrollDelta;
    if (delta == null || delta == 0) return false;

    // Positive delta = scroll offset increasing = scrolling down the page
    // (content moving up); negative = scrolling back up.
    final visible = delta < 0;
    if (visible != _visible) setState(() => _visible = visible);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _onNotification,
      child: Stack(
        children: [
          widget.child,
          ListenableBuilder(
            listenable: appRouter.routerDelegate,
            builder: (context, _) {
              final open = appRouter.routerDelegate.currentConfiguration;
              final path = open.isEmpty ? '' : open.last.matchedLocation;
              if (ContactFabOverlay._hiddenPrefixes.any(path.startsWith)) return const SizedBox.shrink();
              return _PositionedFab(visible: _visible);
            },
          ),
        ],
      ),
    );
  }
}

class _PositionedFab extends StatelessWidget {
  const _PositionedFab({required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    // No floating bottom nav at this width to clear (StandaloneShellScaffold
    // only shows one below AppBreakpoints.mobile) — just enough margin to
    // sit comfortably off the screen edge. At phone width, cleared past the
    // floating pill nav's own rough footprint (see MainBottomNavBar) plus
    // its margin, so the two never overlap.
    final isWide = MediaQuery.sizeOf(context).width >= AppBreakpoints.mobile;
    final bottom = (isWide ? AppSpacing.lg : 88) + MediaQuery.paddingOf(context).bottom;

    return Positioned(
      right: AppSpacing.md,
      bottom: bottom,
      child: IgnorePointer(
        ignoring: !visible,
        child: AnimatedSlide(
          offset: visible ? Offset.zero : const Offset(0, 0.6),
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          child: AnimatedScale(
            scale: visible ? 1 : 0.4,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            child: AnimatedOpacity(
              opacity: visible ? 1 : 0,
              duration: const Duration(milliseconds: 180),
              child: const _FabButtons(),
            ),
          ),
        ),
      ),
    );
  }
}

class _FabButtons extends StatelessWidget {
  const _FabButtons();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _CircleContactButton(
          tooltip: 'contact.messenger_tooltip'.tr(),
          url: kMessengerUrl,
          color: const Color(0xFF0084FF),
          logoAsset: AssetPaths.messengerLogo,
        ),
        const SizedBox(height: AppSpacing.sm),
        _CircleContactButton(
          tooltip: 'contact.whatsapp_tooltip'.tr(),
          url: kWhatsAppUrl,
          color: const Color(0xFF25D366),
          logoAsset: AssetPaths.whatsappLogo,
        ),
      ],
    );
  }
}

class _CircleContactButton extends StatelessWidget {
  const _CircleContactButton({
    required this.tooltip,
    required this.url,
    required this.color,
    required this.logoAsset,
  });

  final String tooltip;
  final String url;
  final Color color;

  /// The brand's own mark (Simple Icons' SVGs, CC0 — see AssetPaths), not a
  /// generic Material icon standing in for it.
  final String logoAsset;

  static const double _size = 52;

  @override
  Widget build(BuildContext context) {
    // Not a Tooltip: it needs an Overlay ancestor, which lives inside the
    // Navigator — a sibling subtree to this button (see ContactFabOverlay's
    // doc comment), not an ancestor of it. Semantics gives the same label to
    // assistive tech without that dependency.
    return Semantics(
      label: tooltip,
      button: true,
      child: Material(
        color: color,
        shape: const CircleBorder(),
        elevation: 4,
        shadowColor: Colors.black45,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
          child: SizedBox(
            width: _size,
            height: _size,
            child: Padding(
              padding: const EdgeInsets.all(13),
              // The source SVGs are solid black marks; tinted white to read
              // against each button's brand-color circle, same treatment
              // every "chat with us" bubble like this gets.
              child: SvgPicture.asset(logoAsset, colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
            ),
          ),
        ),
      ),
    );
  }
}
