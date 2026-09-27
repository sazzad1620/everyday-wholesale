// One-off dev tool — NOT part of the shipped app, not wired into any route.
// Brings images uploaded before the image-optimization change up to the
// same standard as new uploads (see `ImageOptimizer`,
// `StorageUploadSettings`):
//
//   products     images[] → 1200px JPEG + 600px `thumbnails[]`, cached 1 year
//   categories   imageUrl, subcategories[].imageUrl → 600px JPEG, cached
//   banners      imageUrl → 1600px JPEG, cached (old file deleted)
//
// Old product/category files are deliberately LEFT in Storage: past orders
// snapshot the product image URL, so deleting them would break order
// history thumbnails. Banner files are only referenced by their own doc, so
// the old one is removed.
//
// Idempotent: an image whose Storage file already carries the new
// Cache-Control header (i.e. was uploaded or processed by the new code) is
// skipped, so it's safe to re-run — e.g. after a network hiccup.
//
// Run with:
//   flutter run -t lib/tools/optimize_images.dart -d chrome
// Sign in with an ADMIN account — rules only let admins write to
// `products` / `categories` / `banners` and their Storage folders.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/constants/storage_upload_settings.dart';
import '../core/utils/image_optimizer.dart';
import '../firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MaterialApp(home: _OptimizePage(), debugShowCheckedModeBanner: false));
}

class _OptimizePage extends StatefulWidget {
  const _OptimizePage();

  @override
  State<_OptimizePage> createState() => _OptimizePageState();
}

class _OptimizePageState extends State<_OptimizePage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _scrollController = ScrollController();
  final List<String> _log = ['Sign in with an admin account, then run. Start with a dry run. Safe to re-run.'];
  bool _isRunning = false;
  bool _dryRun = true;
  int _bytesBefore = 0;
  int _bytesAfter = 0;

  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  void _append(String line) {
    setState(() => _log.add(line));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  Future<void> _signIn({required bool withGoogle}) async {
    if (FirebaseAuth.instance.currentUser != null) return;
    if (withGoogle) {
      await FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider());
    } else {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    }
  }

  Future<void> _run({required bool withGoogle}) async {
    setState(() {
      _isRunning = true;
      _log.clear();
      _bytesBefore = 0;
      _bytesAfter = 0;
    });
    try {
      _append('Signing in...');
      await _signIn(withGoogle: withGoogle);
      _append('Signed in as ${FirebaseAuth.instance.currentUser?.email ?? FirebaseAuth.instance.currentUser?.uid}');
      if (_dryRun) _append('DRY RUN — nothing will be uploaded or written.');

      await _optimizeProducts();
      await _optimizeCategories();
      await _optimizeBanners();

      _append('');
      _append('Done. Processed images: ${_kb(_bytesBefore)} → ${_kb(_bytesAfter)}'
          '${_dryRun ? ' (estimated — dry run)' : ''}');
    } catch (e) {
      _append('ERROR: $e');
    } finally {
      setState(() => _isRunning = false);
    }
  }

  // ---------------------------------------------------------------- products

  Future<void> _optimizeProducts() async {
    _append('');
    _append('== Products ==');
    final snapshot = await _firestore.collection('products').get();
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final name = _nameOf(data);
      final images = (data['images'] as List?)?.whereType<String>().toList() ?? const <String>[];
      final thumbnails = (data['thumbnails'] as List?)?.whereType<String>().toList() ?? const <String>[];
      if (images.isEmpty) continue;

      final newImages = <String>[];
      final newThumbnails = <String>[];
      var changed = false;

      for (var i = 0; i < images.length; i++) {
        final url = images[i];
        final hasThumb = i < thumbnails.length && thumbnails[i] != url;
        if (!_isStorageUrl(url) || (hasThumb && await _isAlreadyOptimized(url))) {
          newImages.add(url);
          newThumbnails.add(i < thumbnails.length ? thumbnails[i] : url);
          continue;
        }
        final result = await _reencode(
          url,
          folder: 'product_images',
          sizes: const [StorageUploadSettings.productFullSize, StorageUploadSettings.thumbnailSize],
          suffixes: const ['', '_thumb'],
          label: '$name #${i + 1}',
        );
        if (result == null) {
          newImages.add(url);
          newThumbnails.add(url);
        } else {
          newImages.add(result[0]);
          newThumbnails.add(result[1]);
          changed = true;
        }
      }

      if (changed && !_dryRun) {
        await doc.reference.update({'images': newImages, 'thumbnails': newThumbnails});
      }
    }
  }

  // -------------------------------------------------------------- categories

  Future<void> _optimizeCategories() async {
    _append('');
    _append('== Categories ==');
    final snapshot = await _firestore.collection('categories').get();
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final name = _nameOf(data);
      final update = <String, dynamic>{};

      final newImageUrl = await _optimizeTile(data['imageUrl'] as String?, label: name);
      if (newImageUrl != null) update['imageUrl'] = newImageUrl;

      final subcategories = [
        for (final raw in (data['subcategories'] as List? ?? const [])) Map<String, dynamic>.from(raw as Map),
      ];
      var subcategoriesChanged = false;
      for (final sub in subcategories) {
        final newUrl = await _optimizeTile(sub['imageUrl'] as String?, label: '$name › ${_nameOf(sub)}');
        if (newUrl != null) {
          sub['imageUrl'] = newUrl;
          subcategoriesChanged = true;
        }
      }
      if (subcategoriesChanged) update['subcategories'] = subcategories;

      if (update.isNotEmpty && !_dryRun) await doc.reference.update(update);
    }
  }

  /// New tile-sized URL for a category/subcategory photo, or null to keep it.
  Future<String?> _optimizeTile(String? url, {required String label}) async {
    if (url == null || !_isStorageUrl(url) || await _isAlreadyOptimized(url)) return null;
    final result = await _reencode(
      url,
      folder: 'product_images',
      sizes: const [StorageUploadSettings.thumbnailSize],
      suffixes: const ['_thumb'],
      label: label,
    );
    return result?.first;
  }

  // ----------------------------------------------------------------- banners

  Future<void> _optimizeBanners() async {
    _append('');
    _append('== Banners ==');
    final snapshot = await _firestore.collection('banners').orderBy('order').get();
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final url = data['imageUrl'] as String?;
      final oldPath = data['storagePath'] as String? ?? '';
      final label = 'Banner #${(data['order'] as num? ?? 0).toInt() + 1}';
      if (url == null || !_isStorageUrl(url) || await _isAlreadyOptimized(url)) {
        _append('  $label: already optimized');
        continue;
      }
      final newPath = 'banner_images/${DateTime.now().microsecondsSinceEpoch}.${ImageOptimizer.fileExtension}';
      final result = await _reencode(
        url,
        folder: 'banner_images',
        sizes: const [StorageUploadSettings.bannerSize],
        suffixes: const [''],
        label: label,
        exactPath: newPath,
      );
      if (result == null || _dryRun) continue;
      await doc.reference.update({'imageUrl': result.first, 'storagePath': newPath});
      if (oldPath.isNotEmpty) {
        try {
          await _storage.ref(oldPath).delete();
        } catch (_) {}
      }
    }
  }

  // ----------------------------------------------------------------- helpers

  /// Downloads [url], re-encodes it at each of [sizes] and (unless dry run)
  /// uploads the results. Returns the new download URLs in [sizes] order,
  /// or null if the image was skipped.
  Future<List<String>?> _reencode(
    String url, {
    required String folder,
    required List<int> sizes,
    required List<String> suffixes,
    required String label,
    String? exactPath,
  }) async {
    try {
      final original = await _storage.refFromURL(url).getData(30 * 1024 * 1024);
      if (original == null) {
        _append('  $label: could not download — skipped');
        return null;
      }
      final encoded = await ImageOptimizer.toJpegs(original, maxDimensions: sizes);
      if (encoded == null) {
        _append('  $label: format not supported here — skipped');
        return null;
      }
      _bytesBefore += original.length;
      _bytesAfter += encoded.fold<int>(0, (total, bytes) => total + bytes.length);
      _append('  $label: ${_kb(original.length)} → ${encoded.map((b) => _kb(b.length)).join(' + ')}');
      if (_dryRun) return List.filled(sizes.length, url);

      final base = exactPath?.replaceAll(RegExp(r'\.[^.]+$'), '') ??
          '$folder/${DateTime.now().microsecondsSinceEpoch}';
      return Future.wait([
        for (var i = 0; i < encoded.length; i++)
          _upload('$base${suffixes[i]}.${ImageOptimizer.fileExtension}', encoded[i]),
      ]);
    } catch (e) {
      _append('  $label: FAILED ($e) — left unchanged');
      return null;
    }
  }

  Future<String> _upload(String path, Uint8List bytes) async {
    final ref = _storage.ref(path);
    await ref.putData(
      bytes,
      SettableMetadata(contentType: ImageOptimizer.contentType, cacheControl: StorageUploadSettings.cacheControl),
    );
    return ref.getDownloadURL();
  }

  Future<bool> _isAlreadyOptimized(String url) async {
    try {
      final metadata = await _storage.refFromURL(url).getMetadata();
      return metadata.cacheControl == StorageUploadSettings.cacheControl;
    } catch (_) {
      return false;
    }
  }

  bool _isStorageUrl(String url) => url.startsWith('https://firebasestorage.googleapis.com/');

  String _nameOf(Map<String, dynamic> data) {
    final name = data['name'];
    if (name is Map) return (name['en'] as String?) ?? '?';
    return name?.toString() ?? '?';
  }

  String _kb(int bytes) => bytes >= 1024 * 1024
      ? '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB'
      : '${(bytes / 1024).round()} KB';

  // ---------------------------------------------------------------------- UI

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Optimize existing images')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Admin email')),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _dryRun,
                  onChanged: _isRunning ? null : (v) => setState(() => _dryRun = v ?? true),
                  title: const Text('Dry run (only report sizes, change nothing)'),
                ),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: _isRunning ? null : () => _run(withGoogle: false),
                        child: const Text('Run with email / password'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isRunning ? null : () => _run(withGoogle: true),
                        child: const Text('Run with Google sign-in'),
                      ),
                    ),
                  ],
                ),
                if (_isRunning) const Padding(padding: EdgeInsets.only(top: 12), child: LinearProgressIndicator()),
                const SizedBox(height: 12),
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(border: Border.all(color: Colors.black12)),
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(8),
                      itemCount: _log.length,
                      itemBuilder: (_, i) => Text(_log[i], style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                    ),
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
