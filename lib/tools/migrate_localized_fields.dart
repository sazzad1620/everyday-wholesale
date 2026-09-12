// One-off dev tool — NOT part of the shipped app, not wired into any route.
// Moves existing Firestore documents to the bilingual shape introduced in
// docs/JAPANESE_BILINGUAL_SUPPORT.md (§3, §7):
//
//   products    name, description : "text"  →  {en: "text", ja: ""}
//               condition         : "Dry / Packaged"  →  "dry_packaged"
//               origin            : "Bangladesh"      →  "BD"
//   categories  name, subcategories[].name            →  {en, ja}
//   orders      items[].name                          →  {en, ja}
//
// `reviews.productName` is deliberately NOT migrated: security rules make
// review docs immutable (`allow update: if false`, admins included), and the
// app's `LocalizedText.fromFirestore` reads the old plain-string shape fine —
// those snapshots simply keep showing the English name in Japanese mode.
//
// Idempotent: a document already in the new shape is skipped, so it's safe to
// run again. Existing Japanese text (if any) is never overwritten.
//
// Run with:
//   flutter run -t lib/tools/migrate_localized_fields.dart -d chrome
// Sign in with an ADMIN account — rules only let admins write to
// `categories` / `products` / `orders`.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../core/constants/countries.dart';
import '../features/product/domain/entities/product_condition.dart';
import '../firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const _MigrateApp());
}

class _MigrateApp extends StatelessWidget {
  const _MigrateApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: _MigratePage(), debugShowCheckedModeBanner: false);
  }
}

class _MigratePage extends StatefulWidget {
  const _MigratePage();

  @override
  State<_MigratePage> createState() => _MigratePageState();
}

class _MigratePageState extends State<_MigratePage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final List<String> _log = ['Enter an admin account, then run. Safe to re-run.'];
  bool _isRunning = false;
  bool _dryRun = true;

  void _append(String line) => setState(() => _log.add(line));

  Future<void> _run() async {
    setState(() {
      _isRunning = true;
      _log.clear();
    });
    try {
      _append('Signing in...');
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      final firestore = FirebaseFirestore.instance;
      if (_dryRun) _append('DRY RUN — nothing will be written.');

      await _migrate(firestore, 'products', _migrateProduct);
      await _migrate(firestore, 'categories', _migrateCategory);
      await _migrate(firestore, 'orders', _migrateOrder);

      _append(_dryRun ? 'Dry run complete. Untick "Dry run" and run again to apply.' : 'Done.');
    } catch (e) {
      _append('Error: $e');
    } finally {
      setState(() => _isRunning = false);
    }
  }

  /// Applies [transform] to every doc in [collection]; a `null` result means
  /// the doc is already in the new shape. Writes go out in batches of 400
  /// (Firestore caps a batch at 500 operations).
  Future<void> _migrate(
    FirebaseFirestore firestore,
    String collection,
    Map<String, dynamic>? Function(Map<String, dynamic> data) transform,
  ) async {
    _append('Scanning $collection...');
    final snapshot = await firestore.collection(collection).get();
    var changed = 0;
    var batch = firestore.batch();
    var inBatch = 0;
    for (final doc in snapshot.docs) {
      final update = transform(doc.data());
      if (update == null) continue;
      changed++;
      if (_dryRun) {
        _append('  ${doc.id}: ${update.keys.join(', ')}');
        continue;
      }
      batch.update(doc.reference, update);
      if (++inBatch == 400) {
        await batch.commit();
        batch = firestore.batch();
        inBatch = 0;
      }
    }
    if (!_dryRun && inBatch > 0) await batch.commit();
    _append('$collection: ${snapshot.size} scanned, $changed ${_dryRun ? 'would change' : 'updated'}.');
  }

  // --- per-collection transforms ------------------------------------------

  static Map<String, dynamic>? _migrateProduct(Map<String, dynamic> data) {
    final update = <String, dynamic>{};
    final name = _localize(data['name']);
    if (name != null) update['name'] = name;
    final description = _localize(data['description']);
    if (description != null) update['description'] = description;

    final rawCondition = data['condition'];
    if (rawCondition is String) {
      final code = ProductCondition.parse(rawCondition).code;
      if (code != rawCondition) update['condition'] = code;
    }
    final rawOrigin = data['origin'];
    if (rawOrigin is String) {
      final code = Countries.parse(rawOrigin);
      if (code != rawOrigin) update['origin'] = code;
    }
    return update.isEmpty ? null : update;
  }

  static Map<String, dynamic>? _migrateCategory(Map<String, dynamic> data) {
    final update = <String, dynamic>{};
    final name = _localize(data['name']);
    if (name != null) update['name'] = name;

    final rawSubs = data['subcategories'];
    if (rawSubs is List) {
      var touched = false;
      final subs = <Map<String, dynamic>>[];
      for (final raw in rawSubs) {
        final sub = Map<String, dynamic>.from(raw as Map);
        final subName = _localize(sub['name']);
        if (subName != null) {
          sub['name'] = subName;
          touched = true;
        }
        subs.add(sub);
      }
      // The array has to be rewritten whole — Firestore can't update one
      // element's field in place.
      if (touched) update['subcategories'] = subs;
    }
    return update.isEmpty ? null : update;
  }

  static Map<String, dynamic>? _migrateOrder(Map<String, dynamic> data) {
    final rawItems = data['items'];
    if (rawItems is! List) return null;
    var touched = false;
    final items = <Map<String, dynamic>>[];
    for (final raw in rawItems) {
      final item = Map<String, dynamic>.from(raw as Map);
      final name = _localize(item['name']);
      if (name != null) {
        item['name'] = name;
        touched = true;
      }
      items.add(item);
    }
    return touched ? {'items': items} : null;
  }

  /// A plain string becomes `{en: string, ja: ''}`; a map is already migrated
  /// (returns null so it's left untouched — never clobbers existing `ja`).
  static Map<String, String>? _localize(Object? raw) {
    if (raw is String) return {'en': raw, 'ja': ''};
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Everyday Wholesale — Migrate to bilingual fields')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Admin email'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Admin password'),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _dryRun,
                  onChanged: _isRunning ? null : (v) => setState(() => _dryRun = v ?? true),
                  title: const Text('Dry run (list what would change, write nothing)'),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: _isRunning ? null : _run,
                  child: Text(_isRunning ? 'Running...' : (_dryRun ? 'Preview changes' : 'Migrate Firestore')),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView(
                    children: [for (final line in _log) Text(line, style: const TextStyle(fontFamily: 'monospace'))],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
