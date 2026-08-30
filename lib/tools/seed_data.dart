// One-off dev tool — NOT part of the shipped app, not wired into any route.
// Populates Firestore's `categories` and `products` collections with the
// same content the old mock datasources used to hardcode, now that real
// Firestore-backed datasources have replaced them (see docs/PLAN.md Phase 4).
//
// Run with:
//   flutter run -t lib/tools/seed_data.dart -d chrome
// Sign in with an existing ADMIN account (role: admin in Firestore) — the
// security rules only allow admins to write to `categories`/`products`, so
// seeding fails otherwise. Safe to run more than once; every write is a
// `.set()` keyed by a fixed doc ID, so it just overwrites with the same data.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const _SeedApp());
}

class _SeedApp extends StatelessWidget {
  const _SeedApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: _SeedPage(), debugShowCheckedModeBanner: false);
  }
}

class _SeedPage extends StatefulWidget {
  const _SeedPage();

  @override
  State<_SeedPage> createState() => _SeedPageState();
}

class _SeedPageState extends State<_SeedPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _status = 'Enter an admin account to seed Firestore with initial categories and products.';
  bool _isRunning = false;

  Future<void> _run() async {
    setState(() {
      _isRunning = true;
      _status = 'Signing in...';
    });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      setState(() => _status = 'Seeding categories...');
      final firestore = FirebaseFirestore.instance;
      final categoryBatch = firestore.batch();
      for (final category in _categories) {
        final id = category['id']! as String;
        final data = Map<String, dynamic>.from(category)..remove('id');
        categoryBatch.set(firestore.collection('categories').doc(id), data);
      }
      await categoryBatch.commit();

      setState(() => _status = 'Seeding products...');
      final productBatch = firestore.batch();
      for (final product in _products) {
        final id = product['id']! as String;
        final data = Map<String, dynamic>.from(product)..remove('id');
        productBatch.set(firestore.collection('products').doc(id), data);
      }
      await productBatch.commit();

      setState(() => _status = 'Done — seeded ${_categories.length} categories and ${_products.length} products.');
    } catch (e) {
      setState(() => _status = 'Error: $e');
    } finally {
      setState(() => _isRunning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Everyday Wholesale — Seed Data')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _isRunning ? null : _run,
                  child: Text(_isRunning ? 'Seeding...' : 'Seed Firestore'),
                ),
                const SizedBox(height: 20),
                Text(_status),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Same 9 categories the old home_mock_datasource.dart hardcoded.
final List<Map<String, dynamic>> _categories = [
  {'id': 'most_popular', 'name': 'Most Popular', 'iconKey': 'most_popular', 'imageUrl': null, 'subcategories': []},
  {
    'id': 'meat_fish',
    'name': 'Meat & Fish',
    'iconKey': 'meat_fish',
    'imageUrl': null,
    'subcategories': [
      {'id': 'beef', 'name': 'Beef'},
      {'id': 'mutton', 'name': 'Mutton'},
      {'id': 'chicken', 'name': 'Chicken'},
      {'id': 'fish_seafood', 'name': 'Fish & Seafood'},
    ],
  },
  {'id': 'fruits_vegetables', 'name': 'Fruits & Vegetables', 'iconKey': 'fruits_vegetables', 'imageUrl': null, 'subcategories': []},
  {
    'id': 'frozen_food',
    'name': 'Frozen Food',
    'iconKey': 'frozen_food',
    'imageUrl': null,
    'subcategories': [
      {'id': 'frozen_snacks', 'name': 'Frozen Snacks'},
      {'id': 'frozen_vegetables', 'name': 'Frozen Vegetables'},
      {'id': 'frozen_meat', 'name': 'Frozen Meat'},
    ],
  },
  {'id': 'beverages', 'name': 'Beverages', 'iconKey': 'beverages', 'imageUrl': null, 'subcategories': []},
  {
    'id': 'masala_spice',
    'name': 'Masala & Spice',
    'iconKey': 'masala_spice',
    'imageUrl': null,
    'subcategories': [
      {'id': 'whole_spices', 'name': 'Whole Spices'},
      {'id': 'masala_mixes', 'name': 'Masala Mixes'},
      {'id': 'cooking_paste', 'name': 'Cooking Paste'},
    ],
  },
  {'id': 'halal_products', 'name': 'Halal Products', 'iconKey': 'halal_products', 'imageUrl': null, 'subcategories': []},
  {'id': 'rice_grains', 'name': 'Rice & Grains', 'iconKey': 'rice_grains', 'imageUrl': null, 'subcategories': []},
  {'id': 'snacks', 'name': 'Snacks', 'iconKey': 'snacks', 'imageUrl': null, 'subcategories': []},
];

Map<String, dynamic> _product({
  required String id,
  required String name,
  required int price,
  required String unit,
  required String categoryId,
  required String iconKey,
  required String condition,
  required String origin,
  required String description,
  String? subcategoryId,
  String? imageUrl,
  bool inStock = true,
}) {
  return {
    'name': name,
    'price': price,
    'unit': unit,
    'categoryId': categoryId,
    'subcategoryId': subcategoryId,
    'iconKey': iconKey,
    'condition': condition,
    'origin': origin,
    'description': description,
    'imageUrl': imageUrl,
    'inStock': inStock,
    // No seeded rating/review data — real reviews start from real orders
    // now (see the `review` feature), so every product starts at 0/0.
    'ratingSum': 0,
    'reviewCount': 0,
    'id': id, // stripped before writing (used only as the doc ID below)
  };
}

// Same 25 products the old product_mock_datasource.dart hardcoded.
final List<Map<String, dynamic>> _products = [
  _product(
    id: 'mp_1',
    name: 'IBADAH Premium Chom Chom Sweet (500g)',
    price: 980,
    unit: '500g',
    categoryId: 'most_popular',
    iconKey: 'most_popular',
    condition: 'Freshly Prepared',
    origin: 'Bangladesh',
    description:
        'A rich, syrup-soaked Bengali sweet made the traditional way — soft, delicately sweet, and perfect '
        'for celebrations or an everyday treat.',
  ),
  _product(
    id: 'mp_2',
    name: 'Vegetable Samosa 10pcs',
    price: 480,
    unit: '400g',
    categoryId: 'most_popular',
    iconKey: 'most_popular',
    condition: 'Freshly Prepared',
    origin: 'Bangladesh',
    description: 'One of our best-selling picks, loved by regular customers for its quality and value.',
  ),
  _product(
    id: 'mp_3',
    name: 'Dal Puri 10pcs',
    price: 350,
    unit: '10pcs',
    categoryId: 'most_popular',
    iconKey: 'most_popular',
    condition: 'Freshly Prepared',
    origin: 'Bangladesh',
    description: 'One of our best-selling picks, loved by regular customers for its quality and value.',
  ),
  _product(
    id: 'mp_4',
    name: 'Aloo Puri 10pcs',
    price: 350,
    unit: '10pcs',
    categoryId: 'most_popular',
    iconKey: 'most_popular',
    condition: 'Freshly Prepared',
    origin: 'Bangladesh',
    description: 'One of our best-selling picks, loved by regular customers for its quality and value.',
  ),
  _product(
    id: 'mf_1',
    name: 'Whole Chicken',
    price: 890,
    unit: '1kg',
    categoryId: 'meat_fish',
    iconKey: 'meat_fish',
    subcategoryId: 'chicken',
    condition: 'Fresh',
    origin: 'Brazil',
    description:
        'Halal-certified whole chicken, expertly cut for convenience and sourced from trusted suppliers. Ideal '
        'for roasting, curries, or grilling, and a favourite among our regular customers.',
  ),
  _product(
    id: 'mf_2',
    name: 'Beef Cubes',
    price: 1200,
    unit: '500g',
    categoryId: 'meat_fish',
    iconKey: 'meat_fish',
    subcategoryId: 'beef',
    condition: 'Fresh',
    origin: 'Brazil',
    description: 'Sourced and prepared to strict Halal standards, ready for your favourite recipes.',
  ),
  _product(
    id: 'mf_3',
    name: 'Frozen Tilapia Fish',
    price: 750,
    unit: '1kg',
    categoryId: 'meat_fish',
    iconKey: 'meat_fish',
    subcategoryId: 'fish_seafood',
    condition: 'Fresh',
    origin: 'Brazil',
    description: 'Sourced and prepared to strict Halal standards, ready for your favourite recipes.',
  ),
  _product(
    id: 'mf_4',
    name: 'Goat Meat',
    price: 1650,
    unit: '1kg',
    categoryId: 'meat_fish',
    iconKey: 'meat_fish',
    subcategoryId: 'mutton',
    condition: 'Fresh',
    origin: 'Brazil',
    description: 'Sourced and prepared to strict Halal standards, ready for your favourite recipes.',
  ),
  _product(
    id: 'fv_1',
    name: 'Fresh Tomatoes',
    price: 320,
    unit: '1kg',
    categoryId: 'fruits_vegetables',
    iconKey: 'fruits_vegetables',
    condition: 'Fresh',
    origin: 'Bangladesh',
    description: 'Picked fresh and kept crisp, straight from trusted local suppliers.',
  ),
  _product(
    id: 'fv_2',
    name: 'Onions',
    price: 480,
    unit: '2kg',
    categoryId: 'fruits_vegetables',
    iconKey: 'fruits_vegetables',
    condition: 'Fresh',
    origin: 'Bangladesh',
    description: 'Picked fresh and kept crisp, straight from trusted local suppliers.',
  ),
  _product(
    id: 'fv_3',
    name: 'Potatoes',
    price: 420,
    unit: '2kg',
    categoryId: 'fruits_vegetables',
    iconKey: 'fruits_vegetables',
    condition: 'Fresh',
    origin: 'Bangladesh',
    description: 'Picked fresh and kept crisp, straight from trusted local suppliers.',
  ),
  _product(
    id: 'fv_4',
    name: 'Garlic',
    price: 380,
    unit: '500g',
    categoryId: 'fruits_vegetables',
    iconKey: 'fruits_vegetables',
    condition: 'Fresh',
    origin: 'Bangladesh',
    description: 'Picked fresh and kept crisp, straight from trusted local suppliers.',
  ),
  _product(
    id: 'ff_1',
    name: 'Frozen Paratha 10pcs',
    price: 560,
    unit: '10pcs',
    categoryId: 'frozen_food',
    iconKey: 'frozen_food',
    subcategoryId: 'frozen_snacks',
    condition: 'Frozen',
    origin: 'Bangladesh',
    description: 'Flash-frozen to lock in freshness — just heat and serve.',
  ),
  _product(
    id: 'ff_2',
    name: 'Frozen Mixed Vegetables',
    price: 420,
    unit: '1kg',
    categoryId: 'frozen_food',
    iconKey: 'frozen_food',
    subcategoryId: 'frozen_vegetables',
    condition: 'Frozen',
    origin: 'Bangladesh',
    description: 'Flash-frozen to lock in freshness — just heat and serve.',
  ),
  _product(
    id: 'ff_3',
    name: 'Frozen Spring Rolls 20pcs',
    price: 680,
    unit: '20pcs',
    categoryId: 'frozen_food',
    iconKey: 'frozen_food',
    subcategoryId: 'frozen_snacks',
    condition: 'Frozen',
    origin: 'Bangladesh',
    description: 'Flash-frozen to lock in freshness — just heat and serve.',
    inStock: false,
  ),
  _product(
    id: 'bv_1',
    name: 'Mango Juice',
    price: 350,
    unit: '1L',
    categoryId: 'beverages',
    iconKey: 'beverages',
    condition: 'Ambient',
    origin: 'Bangladesh',
    description: 'A refreshing pick for any time of day, stocked fresh at every restock.',
  ),
  _product(
    id: 'bv_2',
    name: 'Rooh Afza Syrup',
    price: 890,
    unit: '800ml',
    categoryId: 'beverages',
    iconKey: 'beverages',
    condition: 'Ambient',
    origin: 'Bangladesh',
    description: 'A refreshing pick for any time of day, stocked fresh at every restock.',
  ),
  _product(
    id: 'bv_3',
    name: 'Mineral Water 6-pack',
    price: 480,
    unit: '1.5L x 6',
    categoryId: 'beverages',
    iconKey: 'beverages',
    condition: 'Ambient',
    origin: 'Bangladesh',
    description: 'A refreshing pick for any time of day, stocked fresh at every restock.',
  ),
  _product(
    id: 'ms_1',
    name: 'MDH Chicken Curry Masala',
    price: 280,
    unit: '100g',
    categoryId: 'masala_spice',
    iconKey: 'masala_spice',
    subcategoryId: 'masala_mixes',
    condition: 'Dry / Packaged',
    origin: 'India',
    description: 'Carefully sourced and blended for authentic, consistent flavour in every batch.',
  ),
  _product(
    id: 'ms_2',
    name: 'Shan Biryani Masala',
    price: 260,
    unit: '100g',
    categoryId: 'masala_spice',
    iconKey: 'masala_spice',
    subcategoryId: 'masala_mixes',
    condition: 'Dry / Packaged',
    origin: 'India',
    description: 'Carefully sourced and blended for authentic, consistent flavour in every batch.',
  ),
  _product(
    id: 'ms_3',
    name: 'Whole Cumin Seeds',
    price: 340,
    unit: '200g',
    categoryId: 'masala_spice',
    iconKey: 'masala_spice',
    subcategoryId: 'whole_spices',
    condition: 'Dry / Packaged',
    origin: 'India',
    description: 'Carefully sourced and blended for authentic, consistent flavour in every batch.',
  ),
  _product(
    id: 'ms_4',
    name: 'Dry Red Chilli',
    price: 390,
    unit: '250g',
    categoryId: 'masala_spice',
    iconKey: 'masala_spice',
    subcategoryId: 'whole_spices',
    condition: 'Dry / Packaged',
    origin: 'India',
    description: 'Carefully sourced and blended for authentic, consistent flavour in every batch.',
  ),
  _product(
    id: 'hp_1',
    name: 'Halal Certified Beef Salami',
    price: 680,
    unit: '250g',
    categoryId: 'halal_products',
    iconKey: 'halal_products',
    condition: 'Frozen',
    origin: 'Brazil',
    description:
        'Halal-certified beef salami, thinly sliced and ready to serve — great for sandwiches, platters, or a '
        'quick snack.',
  ),
  _product(
    id: 'hp_2',
    name: 'Halal Chicken Nuggets',
    price: 720,
    unit: '500g',
    categoryId: 'halal_products',
    iconKey: 'halal_products',
    condition: 'Frozen',
    origin: 'Brazil',
    description: 'Halal-certified and prepared to the highest quality standards you can trust.',
  ),
  _product(
    id: 'hp_3',
    name: 'Halal Beef Sausages',
    price: 650,
    unit: '400g',
    categoryId: 'halal_products',
    iconKey: 'halal_products',
    condition: 'Frozen',
    origin: 'Brazil',
    description: 'Halal-certified and prepared to the highest quality standards you can trust.',
  ),
  _product(
    id: 'rg_1',
    name: 'Basmati Rice',
    price: 2400,
    unit: '5kg',
    categoryId: 'rice_grains',
    iconKey: 'rice_grains',
    condition: 'Dry / Packaged',
    origin: 'India',
    description:
        'Long-grain aromatic Basmati rice, aged for extra fragrance and fluffiness — a pantry essential for '
        'biryani, pulao, and everyday meals.',
  ),
  _product(
    id: 'rg_2',
    name: 'Puffed Rice',
    price: 380,
    unit: '1kg',
    categoryId: 'rice_grains',
    iconKey: 'rice_grains',
    condition: 'Dry / Packaged',
    origin: 'India',
    description: 'A pantry staple, sourced for consistent quality and great everyday value.',
  ),
  _product(
    id: 'rg_3',
    name: 'Red Lentils (Masoor Dal)',
    price: 420,
    unit: '1kg',
    categoryId: 'rice_grains',
    iconKey: 'rice_grains',
    condition: 'Dry / Packaged',
    origin: 'India',
    description: 'A pantry staple, sourced for consistent quality and great everyday value.',
  ),
  _product(
    id: 'rg_4',
    name: 'Chickpeas',
    price: 360,
    unit: '1kg',
    categoryId: 'rice_grains',
    iconKey: 'rice_grains',
    condition: 'Dry / Packaged',
    origin: 'India',
    description: 'A pantry staple, sourced for consistent quality and great everyday value.',
  ),
  _product(
    id: 'sn_1',
    name: 'Vegetable Samosa 10pcs (IBADAH)',
    price: 480,
    unit: '400g',
    categoryId: 'snacks',
    iconKey: 'snacks',
    condition: 'Ambient',
    origin: 'Bangladesh',
    description: 'A tasty, ready-to-cook snack the whole family will enjoy.',
  ),
];
