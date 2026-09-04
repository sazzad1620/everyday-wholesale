import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/di/injection_container.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_input_style.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/utils/toast.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../shared/widgets/navigation/app_header.dart';
import '../../../auth/presentation/bloc/account_bloc.dart';
import '../../../auth/presentation/bloc/account_event.dart';
import '../../../auth/presentation/bloc/account_state.dart';
import '../widgets/desktop_account_body.dart';
import '../widgets/desktop_account_nav.dart';
import 'account_page.dart';

/// Only the display name is actually editable here — email/phone are tied
/// to the sign-in credential itself (changing either is a real Firebase
/// re-auth flow, not a plain field write). They're shown as normal-looking
/// fields (same style/size as every other field in the app, not a separate
/// "locked" look) that just can't be typed into — tapping either explains
/// why via a toast instead.
class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final _user = getIt<AccountBloc>().state.user;
  late final _nameController = TextEditingController(text: _user?.name ?? '');
  late final _emailController = TextEditingController(text: _user?.email ?? '');
  late final _phoneController = TextEditingController(text: _user?.phone ?? '');

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;
    getIt<AccountBloc>().add(
      AccountNameUpdateRequested(_nameController.text.trim()),
    );
  }

  void _showContactLockedToast(BuildContext context) {
    AppToast.show(
      context,
      'account.primary_contact_locked'.tr(),
      type: ToastType.info,
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasPhone = _user?.phone != null && _user!.phone!.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(
              showSearchBar: false,
              showBackButton: true,
              onMenuTap: () => context.pop(),
              onAccountTap: () => openAccountMenu(context),
            ),
            Expanded(
              child: BlocConsumer<AccountBloc, AccountState>(
                bloc: getIt<AccountBloc>(),
                listenWhen: (previous, current) =>
                    previous.isSubmitting && !current.isSubmitting,
                listener: (context, state) {
                  if (state.errorMessage != null) {
                    AppToast.show(
                      context,
                      state.errorMessage!,
                      type: ToastType.error,
                    );
                  } else if (state.nameUpdated) {
                    AppToast.show(
                      context,
                      'account.profile_updated'.tr(),
                      type: ToastType.success,
                    );
                    context.pop();
                  }
                },
                builder: (context, state) {
                  return DesktopAccountBody(
                    current: AccountNavItem.editProfile,
                    child: Form(
                      key: _formKey,
                      child: ListView(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        children: [
                          Text(
                            'account.edit_profile'.tr(),
                            style: AppTextStyles.headline,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          TextFormField(
                            controller: _nameController,
                            decoration: AppInputStyle.decoration(
                              hintText: 'account.name_hint'.tr(),
                              radius: 14,
                            ),
                            validator: (value) =>
                                (value == null || value.trim().isEmpty)
                                ? 'account.error_name_required'.tr()
                                : null,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          TextFormField(
                            controller: _emailController,
                            readOnly: true,
                            decoration: AppInputStyle.decoration(
                              hintText: 'account.email_label'.tr(),
                              radius: 14,
                            ),
                            onTap: () => _showContactLockedToast(context),
                          ),
                          if (hasPhone) ...[
                            const SizedBox(height: AppSpacing.sm),
                            TextFormField(
                              controller: _phoneController,
                              readOnly: true,
                              decoration: AppInputStyle.decoration(
                                hintText: 'account.phone_label'.tr(),
                                radius: 14,
                              ),
                              onTap: () => _showContactLockedToast(context),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.lg),
                          PrimaryButton(
                            label: 'account.save_profile'.tr(),
                            isLoading: state.isSubmitting,
                            onTap: () => _submit(context),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
