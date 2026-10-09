import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

/// Makes a language switch take effect in place — instantly, with nothing
/// reloaded.
///
/// Most screens read their text with a context-free `'key'.tr()`, which tells
/// Flutter nothing about the language, and many of those widgets are `const`,
/// so Flutter would not rebuild them when the language changes. The app used
/// to deal with that by giving the whole `MaterialApp` a new key per language,
/// which **destroys and recreates everything**: the open menu closed, the
/// scroll position and screen state were lost, data and images reloaded, and
/// on Android the whole screen flashed black while it happened.
///
/// This widget instead keeps everything alive and just asks every widget below
/// it to rebuild once, in the same frame the new language arrives. Widgets
/// keep their state (menus stay open, lists stay scrolled, loaded data stays);
/// only the text and anything language-dependent is redrawn. Put it directly
/// above the app's navigator (`MaterialApp.builder`).
class RebuildOnLocaleChange extends StatefulWidget {
  const RebuildOnLocaleChange({super.key, required this.child});

  final Widget child;

  @override
  State<RebuildOnLocaleChange> createState() => _RebuildOnLocaleChangeState();
}

class _RebuildOnLocaleChangeState extends State<RebuildOnLocaleChange> {
  Locale? _locale;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reading the locale from the EasyLocalization scope makes Flutter call
    // this method whenever the language changes.
    final locale = context.locale;
    if (_locale != null && _locale != locale) _rebuildEverythingBelow();
    _locale = locale;
  }

  /// Marks every element below this widget dirty. Called while this widget is
  /// itself being rebuilt, which Flutter allows for descendants, so they are
  /// all rebuilt in the *same* frame (no frame showing the old language).
  void _rebuildEverythingBelow() {
    void markDirty(Element element) {
      element.markNeedsBuild();
      element.visitChildren(markDirty);
    }

    (context as Element).visitChildren(markDirty);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
