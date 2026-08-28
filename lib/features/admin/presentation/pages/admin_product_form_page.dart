import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../config/di/injection_container.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_input_style.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/utils/toast.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../home/domain/entities/category_entity.dart';
import '../../../home/domain/usecases/get_categories_usecase.dart';
import '../../../product/domain/entities/product_entity.dart';
import '../../domain/usecases/upload_product_image_usecase.dart';
import '../bloc/admin_product_form_bloc.dart';
import '../bloc/admin_product_form_event.dart';
import '../bloc/admin_product_form_state.dart';
import '../widgets/product_image_picker.dart';

/// Add/edit form for a single product — pushed full-screen (root
/// navigator), same reasoning as [AdminCategoryFormPage]. `initial: null`
/// means add mode; a non-null [ProductEntity] means edit mode.
class AdminProductFormPage extends StatelessWidget {
  const AdminProductFormPage({super.key, this.initial});

  final ProductEntity? initial;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AdminProductFormBloc>(),
      child: _ProductFormView(initial: initial),
    );
  }
}

class _ProductFormView extends StatefulWidget {
  const _ProductFormView({this.initial});

  final ProductEntity? initial;

  @override
  State<_ProductFormView> createState() => _ProductFormViewState();
}

class _ProductFormViewState extends State<_ProductFormView> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.initial?.name ?? '');
  late final _priceController = TextEditingController(text: widget.initial?.price.toString() ?? '');
  late final _unitController = TextEditingController(text: widget.initial?.unit ?? '');
  late final _conditionController = TextEditingController(text: widget.initial?.condition ?? '');
  late final _originController = TextEditingController(text: widget.initial?.origin ?? '');
  late final _descriptionController = TextEditingController(text: widget.initial?.description ?? '');

  String? _selectedCategoryId;
  String? _selectedSubcategoryId;
  late bool _inStock = widget.initial?.inStock ?? true;
  late String? _imageUrl = widget.initial?.imageUrl;
  bool _isUploadingImage = false;

  List<CategoryEntity> _categories = [];
  bool _loadingCategories = true;

  bool get _isEditing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.initial?.categoryId;
    _selectedSubcategoryId = widget.initial?.subcategoryId;
    _loadCategories();
  }

  Future<void> _pickAndUploadImage(BuildContext context) async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 85);
    if (picked == null || !mounted) return;

    final bytes = await picked.readAsBytes();
    final extension = picked.name.contains('.') ? picked.name.split('.').last : 'jpg';
    if (!mounted) return;

    setState(() => _isUploadingImage = true);
    final result = await getIt<UploadProductImageUseCase>()(
      UploadProductImageParams(bytes: bytes, fileExtension: extension),
    );
    if (!mounted) return;
    setState(() => _isUploadingImage = false);

    result.match(
      (failure) => AppToast.show(context, failure.message, type: ToastType.error),
      (url) => setState(() => _imageUrl = url),
    );
  }

  Future<void> _loadCategories() async {
    final result = await getIt<GetCategoriesUseCase>()(const NoParams());
    if (!mounted) return;
    result.match(
      (failure) => setState(() => _loadingCategories = false),
      (categories) => setState(() {
        _categories = categories;
        _loadingCategories = false;
      }),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _unitController.dispose();
    _conditionController.dispose();
    _originController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  CategoryEntity? get _selectedCategory {
    for (final category in _categories) {
      if (category.id == _selectedCategoryId) return category;
    }
    return null;
  }

  void _onCategoryChanged(String? categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
      // A subcategory picked under the previous category rarely belongs to
      // the new one — drop it rather than silently keep an invalid pairing.
      _selectedSubcategoryId = null;
    });
  }

  void _submit(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;
    final category = _selectedCategory;
    if (category == null) {
      AppToast.show(context, 'admin.category_required'.tr(), type: ToastType.error);
      return;
    }

    final product = ProductEntity(
      id: widget.initial?.id ?? '',
      name: _nameController.text.trim(),
      price: int.parse(_priceController.text.trim()),
      unit: _unitController.text.trim(),
      categoryId: category.id,
      iconKey: category.iconKey,
      description: _descriptionController.text.trim(),
      condition: _conditionController.text.trim(),
      origin: _originController.text.trim(),
      subcategoryId: _selectedSubcategoryId,
      imageUrl: _imageUrl,
      inStock: _inStock,
      reviews: widget.initial?.reviews ?? const [],
    );

    context.read<AdminProductFormBloc>().add(
      AdminProductFormSubmitted(product: product, isEditing: _isEditing),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: Text(_isEditing ? 'admin.edit_product'.tr() : 'admin.add_product'.tr()),
      ),
      body: BlocConsumer<AdminProductFormBloc, AdminProductFormState>(
        listenWhen: (previous, current) => previous.isSubmitting && !current.isSubmitting,
        listener: (context, state) {
          if (state.errorMessage != null) {
            AppToast.show(context, state.errorMessage!, type: ToastType.error);
          } else if (state.success) {
            context.pop(true);
          }
        },
        builder: (context, state) {
          if (_loadingCategories) {
            return const Center(child: CircularProgressIndicator());
          }
          final subcategories = _selectedCategory?.subcategories ?? const [];
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                ProductImagePicker(
                  imageUrl: _imageUrl,
                  isUploading: _isUploadingImage,
                  onTap: () => _pickAndUploadImage(context),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  controller: _nameController,
                  decoration: AppInputStyle.decoration(hintText: 'admin.product_name_hint'.tr(), radius: 14),
                  validator: (value) =>
                      (value == null || value.trim().isEmpty) ? 'admin.error_product_name_required'.tr() : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        decoration: AppInputStyle.decoration(hintText: 'admin.product_price_hint'.tr(), radius: 14),
                        validator: (value) {
                          final parsed = int.tryParse(value?.trim() ?? '');
                          if (parsed == null || parsed < 0) return 'admin.error_product_price_invalid'.tr();
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: TextFormField(
                        controller: _unitController,
                        decoration: AppInputStyle.decoration(hintText: 'admin.product_unit_hint'.tr(), radius: 14),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty) ? 'admin.error_product_unit_required'.tr() : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategoryId,
                  decoration: AppInputStyle.decoration(hintText: 'admin.product_category_hint'.tr(), radius: 14),
                  items: [
                    for (final category in _categories)
                      DropdownMenuItem(value: category.id, child: Text(category.name)),
                  ],
                  onChanged: _onCategoryChanged,
                  validator: (value) => value == null ? 'admin.category_required'.tr() : null,
                ),
                if (subcategories.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedSubcategoryId,
                    decoration: AppInputStyle.decoration(
                      hintText: 'admin.product_subcategory_hint'.tr(),
                      radius: 14,
                    ),
                    items: [
                      for (final subcategory in subcategories)
                        DropdownMenuItem(value: subcategory.id, child: Text(subcategory.name)),
                    ],
                    onChanged: (value) => setState(() => _selectedSubcategoryId = value),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _conditionController,
                  decoration: AppInputStyle.decoration(hintText: 'admin.product_condition_hint'.tr(), radius: 14),
                  validator: (value) =>
                      (value == null || value.trim().isEmpty) ? 'admin.error_product_condition_required'.tr() : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _originController,
                  decoration: AppInputStyle.decoration(hintText: 'admin.product_origin_hint'.tr(), radius: 14),
                  validator: (value) =>
                      (value == null || value.trim().isEmpty) ? 'admin.error_product_origin_required'.tr() : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: AppInputStyle.decoration(hintText: 'admin.product_description_hint'.tr(), radius: 14),
                  validator: (value) =>
                      (value == null || value.trim().isEmpty) ? 'admin.error_product_description_required'.tr() : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _inStock,
                  onChanged: (value) => setState(() => _inStock = value),
                  activeThumbColor: AppColors.primary,
                  title: Text('admin.product_in_stock_label'.tr(), style: AppTextStyles.body),
                ),
                const SizedBox(height: AppSpacing.lg),
                PrimaryButton(
                  label: _isEditing ? 'admin.save_changes'.tr() : 'admin.add_product'.tr(),
                  isLoading: state.isSubmitting,
                  onTap: () => _submit(context),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
