import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../config/di/injection_container.dart';
import '../../../../../core/utils/date_formatter.dart';
import '../../../../../shared/theme/app_colors.dart';
import '../../../../../shared/theme/app_spacing.dart';
import '../../../../../shared/theme/app_text_styles.dart';
import '../../../../../shared/utils/toast.dart';
import '../../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../../shared/widgets/dialogs/confirm_dialog.dart';
import '../../../../offer/domain/entities/offer_entity.dart';
import '../../../../product/domain/usecases/upload_product_image_usecase.dart';
import '../../bloc/offers/offer_form_bloc.dart';
import '../../widgets/bilingual_text_field.dart';
import '../../widgets/banner_image_picker.dart';

/// New-offer form — pushed full-screen like the category form. English title
/// and body are required, Japanese optional (customers fall back to
/// English). Image and expiry date are optional.
class AdminOfferFormPage extends StatelessWidget {
  const AdminOfferFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (_) => getIt<OfferFormBloc>(), child: const _OfferFormView());
  }
}

class _OfferFormView extends StatefulWidget {
  const _OfferFormView();

  @override
  State<_OfferFormView> createState() => _OfferFormViewState();
}

class _OfferFormViewState extends State<_OfferFormView> {
  final _formKey = GlobalKey<FormState>();
  final _title = BilingualController();
  final _body = BilingualController();
  String? _imageUrl;
  bool _isUploadingImage = false;
  DateTime? _expiresAt;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _pickAndUpload() async {
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
      (failure) => AppToast.show(context, failure.messageKey.tr(), type: ToastType.error),
      (uploaded) => setState(() => _imageUrl = uploaded.url),
    );
  }

  Future<void> _pickExpiry() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiresAt ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked == null) return;
    // End of the chosen day, so "expires today" still shows all day.
    setState(() => _expiresAt = DateTime(picked.year, picked.month, picked.day, 23, 59, 59));
  }

  Future<void> _submit(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    final bloc = context.read<OfferFormBloc>();
    // A push can't be recalled once sent, so ask first.
    final confirmed = await showConfirmDialog(
      context,
      title: 'admin.send_offer_confirm_title'.tr(),
      message: 'admin.send_offer_confirm_message'.tr(),
      confirmLabel: 'admin.send_offer_confirm'.tr(),
      cancelLabel: 'admin.cancel'.tr(),
      isDestructive: false,
    );
    if (!confirmed) return;
    bloc.add(
      OfferFormSubmitted(
        OfferEntity(
          id: '',
          title: _title.value,
          body: _body.value,
          // Replaced by the server timestamp on write.
          createdAt: DateTime.now(),
          imageUrl: _imageUrl,
          expiresAt: _expiresAt,
        ),
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
        title: Text('admin.add_offer'.tr()),
      ),
      body: BlocConsumer<OfferFormBloc, OfferFormState>(
        listenWhen: (previous, current) => previous.isSubmitting && !current.isSubmitting,
        listener: (context, state) {
          if (state.errorMessage != null) {
            AppToast.show(context, state.errorMessage!.tr(), type: ToastType.error);
          } else if (state.success) {
            context.pop(true);
          }
        },
        builder: (context, state) {
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md) +
                  EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
              children: [
                BannerImagePicker(
                  imageUrl: _imageUrl,
                  isUploading: _isUploadingImage,
                  onTap: _pickAndUpload,
                  onRemove: () => setState(() => _imageUrl = null),
                  placeholder: 'admin.offer_image_placeholder'.tr(),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'admin.offer_image_hint'.tr(),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.lg),
                BilingualTextField(
                  controller: _title,
                  hintText: 'admin.offer_title_hint'.tr(),
                  requiredError: 'admin.offer_title_required'.tr(),
                ),
                const SizedBox(height: AppSpacing.md),
                BilingualTextField(
                  controller: _body,
                  hintText: 'admin.offer_body_hint'.tr(),
                  requiredError: 'admin.offer_body_required'.tr(),
                  maxLines: 4,
                ),
                const SizedBox(height: AppSpacing.md),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event_outlined, color: AppColors.textSecondary),
                  title: Text(
                    _expiresAt == null
                        ? 'admin.offer_no_expiry'.tr()
                        : 'admin.offer_expires_on'.tr(namedArgs: {'date': formatShortDate(context, _expiresAt!)}),
                    style: AppTextStyles.body,
                  ),
                  trailing: _expiresAt == null
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => setState(() => _expiresAt = null),
                        ),
                  onTap: _pickExpiry,
                ),
                const SizedBox(height: AppSpacing.lg),
                PrimaryButton(
                  label: 'admin.send_offer'.tr(),
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
