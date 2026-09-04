import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../config/di/injection_container.dart';
import '../../../../../core/utils/slugify.dart';
import '../../../../../shared/theme/app_colors.dart';
import '../../../../../shared/theme/app_input_style.dart';
import '../../../../../shared/theme/app_spacing.dart';
import '../../../../../shared/theme/app_text_styles.dart';
import '../../../../../shared/utils/toast.dart';
import '../../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../home/domain/entities/category_entity.dart';
import '../../../../home/domain/entities/subcategory_entity.dart';
import '../../../../product/domain/usecases/upload_product_image_usecase.dart';
import '../../bloc/categories/category_form_bloc.dart';
import '../../bloc/categories/category_form_event.dart';
import '../../bloc/categories/category_form_state.dart';
import '../../widgets/product_image_picker.dart';

/// Add/edit form for a single category — pushed full-screen (root
/// navigator) rather than a dialog, since the variable-length subcategory
/// list needs real room, especially on desktop. `initial: null` means add
/// mode; a non-null [CategoryEntity] means edit mode.
///
/// Category/subcategory each get a real uploaded photo instead of the old
/// icon-picker — same upload path products already use
/// ([UploadProductImageUseCase], `product_images/` in Storage — the bucket
/// path name is a leftover from products being first, but Storage doesn't
/// care who uploads to it, so reusing it avoids a second Storage Rules
/// entry for what's functionally the same operation).
class AdminCategoryFormPage extends StatelessWidget {
  const AdminCategoryFormPage({super.key, this.initial});

  final CategoryEntity? initial;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CategoryFormBloc>(),
      child: _CategoryFormView(initial: initial),
    );
  }
}

class _SubcategoryDraft {
  _SubcategoryDraft({required this.id, required String name, this.imageUrl})
    : controller = TextEditingController(text: name);

  /// Empty for a subcategory newly added in this form — its id is derived
  /// from the name (via [slugify]) only at submit time. Fixed/unchanged for
  /// a subcategory that already existed, since products may reference it.
  final String id;
  final TextEditingController controller;
  String? imageUrl;
  bool isUploading = false;
}

class _CategoryFormView extends StatefulWidget {
  const _CategoryFormView({this.initial});

  final CategoryEntity? initial;

  @override
  State<_CategoryFormView> createState() => _CategoryFormViewState();
}

class _CategoryFormViewState extends State<_CategoryFormView> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.initial?.name ?? '');
  String? _imageUrl;
  bool _isUploadingImage = false;
  late final List<_SubcategoryDraft> _subcategories = [
    for (final s in widget.initial?.subcategories ?? const [])
      _SubcategoryDraft(id: s.id, name: s.name, imageUrl: s.imageUrl),
  ];

  bool get _isEditing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    _imageUrl = widget.initial?.imageUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final s in _subcategories) {
      s.controller.dispose();
    }
    super.dispose();
  }

  void _addSubcategory() => setState(() => _subcategories.add(_SubcategoryDraft(id: '', name: '')));

  void _removeSubcategory(int index) => setState(() {
    _subcategories[index].controller.dispose();
    _subcategories.removeAt(index);
  });

  Future<void> _pickAndUpload({
    required VoidCallback onStart,
    required VoidCallback onEnd,
    required ValueChanged<String> onUploaded,
  }) async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 85);
    if (picked == null || !mounted) return;

    final bytes = await picked.readAsBytes();
    final extension = picked.name.contains('.') ? picked.name.split('.').last : 'jpg';
    if (!mounted) return;

    onStart();
    final result = await getIt<UploadProductImageUseCase>()(
      UploadProductImageParams(bytes: bytes, fileExtension: extension),
    );
    if (!mounted) return;
    onEnd();

    result.match(
      (failure) => AppToast.show(context, failure.message, type: ToastType.error),
      onUploaded,
    );
  }

  void _submit(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final id = widget.initial?.id ?? slugify(name);
    final subcategories = [
      for (final draft in _subcategories)
        if (draft.controller.text.trim().isNotEmpty)
          SubcategoryEntity(
            id: draft.id.isNotEmpty ? draft.id : slugify(draft.controller.text.trim()),
            name: draft.controller.text.trim(),
            imageUrl: draft.imageUrl,
          ),
    ];

    context.read<CategoryFormBloc>().add(
      CategoryFormSubmitted(
        category: CategoryEntity(
          id: id,
          name: name,
          // No longer admin-picked — the customer-facing card only ever
          // showed `imageUrl` anyway (see `CategoryImage`), this is kept
          // only because `CategoryEntity`/existing docs still carry it.
          iconKey: widget.initial?.iconKey ?? id,
          imageUrl: _imageUrl,
          subcategories: subcategories,
        ),
        isEditing: _isEditing,
      ),
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
        title: Text(_isEditing ? 'admin.edit_category'.tr() : 'admin.add_category'.tr()),
      ),
      body: BlocConsumer<CategoryFormBloc, CategoryFormState>(
        listenWhen: (previous, current) => previous.isSubmitting && !current.isSubmitting,
        listener: (context, state) {
          if (state.errorMessage != null) {
            AppToast.show(context, state.errorMessage!, type: ToastType.error);
          } else if (state.success) {
            context.pop(true);
          }
        },
        builder: (context, state) {
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                ProductImagePicker(
                  imageUrl: _imageUrl,
                  isUploading: _isUploadingImage,
                  onTap: () => _pickAndUpload(
                    onStart: () => setState(() => _isUploadingImage = true),
                    onEnd: () => setState(() => _isUploadingImage = false),
                    onUploaded: (url) => setState(() => _imageUrl = url),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  controller: _nameController,
                  decoration: AppInputStyle.decoration(hintText: 'admin.category_name_hint'.tr(), radius: 14),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'admin.error_category_name_required'.tr();
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(child: Text('admin.subcategories_label'.tr(), style: AppTextStyles.title)),
                    IconButton(
                      icon: const Icon(Icons.add_circle_rounded, color: AppColors.primary),
                      onPressed: _addSubcategory,
                    ),
                  ],
                ),
                for (var i = 0; i < _subcategories.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ProductImagePicker(
                          size: 56,
                          imageUrl: _subcategories[i].imageUrl,
                          isUploading: _subcategories[i].isUploading,
                          onTap: () => _pickAndUpload(
                            onStart: () => setState(() => _subcategories[i].isUploading = true),
                            onEnd: () => setState(() => _subcategories[i].isUploading = false),
                            onUploaded: (url) => setState(() => _subcategories[i].imageUrl = url),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: TextFormField(
                            controller: _subcategories[i].controller,
                            decoration: AppInputStyle.decoration(
                              hintText: 'admin.subcategory_name_hint'.tr(),
                              radius: 14,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline_rounded, color: AppColors.error),
                          onPressed: () => _removeSubcategory(i),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: AppSpacing.lg),
                PrimaryButton(
                  label: _isEditing ? 'admin.save_changes'.tr() : 'admin.add_category'.tr(),
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
