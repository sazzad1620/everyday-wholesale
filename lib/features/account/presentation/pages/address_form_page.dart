import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/di/injection_container.dart';
import '../../../../core/utils/responsive/breakpoints.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_input_style.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/utils/toast.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../shared/widgets/navigation/app_header.dart';
import '../../../auth/domain/entities/address_entity.dart';
import '../../../auth/presentation/bloc/account_bloc.dart';
import '../../../auth/presentation/bloc/account_event.dart';
import '../../../auth/presentation/bloc/account_state.dart';
import '../widgets/desktop_account_body.dart';
import '../widgets/desktop_account_nav.dart';
import 'account_page.dart';

/// The app's one saved-address editor — reached both from Account > Address
/// and from the checkout delivery-address card's "Edit" link, since there's
/// only ever one address to edit, not an address book. Pre-fills from
/// [AccountBloc]'s current user if one is already saved; otherwise starts
/// blank (first-time save).
class AddressFormPage extends StatefulWidget {
  const AddressFormPage({super.key});

  @override
  State<AddressFormPage> createState() => _AddressFormPageState();
}

class _AddressFormPageState extends State<AddressFormPage> {
  final _formKey = GlobalKey<FormState>();

  late final AddressEntity? _initial = getIt<AccountBloc>().state.user?.address;

  late final _receiverNameController = TextEditingController(
    text: _initial?.receiverName ?? '',
  );
  late final _phoneController = TextEditingController(
    text: _initial?.phoneNumber ?? '',
  );
  late final _postalCodeController = TextEditingController(
    text: _initial?.postalCode ?? '',
  );
  late final _stateController = TextEditingController(
    text: _initial?.state ?? '',
  );
  late final _cityController = TextEditingController(
    text: _initial?.city ?? '',
  );
  late final _streetController = TextEditingController(
    text: _initial?.street ?? '',
  );
  late final _chomeBanchiGoController = TextEditingController(
    text: _initial?.chomeBanchiGo ?? '',
  );
  late final _buildingNameController = TextEditingController(
    text: _initial?.buildingName ?? '',
  );

  @override
  void dispose() {
    _receiverNameController.dispose();
    _phoneController.dispose();
    _postalCodeController.dispose();
    _stateController.dispose();
    _cityController.dispose();
    _streetController.dispose();
    _chomeBanchiGoController.dispose();
    _buildingNameController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;

    final building = _buildingNameController.text.trim();
    getIt<AccountBloc>().add(
      AccountAddressUpdateRequested(
        AddressEntity(
          receiverName: _receiverNameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          postalCode: _postalCodeController.text.trim(),
          state: _stateController.text.trim(),
          city: _cityController.text.trim(),
          street: _streetController.text.trim(),
          chomeBanchiGo: _chomeBanchiGoController.text.trim(),
          buildingName: building.isEmpty ? null : building,
        ),
      ),
    );
  }

  String? _requiredValidator(String? value, String errorKey) =>
      (value == null || value.trim().isEmpty) ? errorKey.tr() : null;

  @override
  Widget build(BuildContext context) {
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
                  } else if (state.addressUpdated) {
                    AppToast.show(
                      context,
                      'address.saved'.tr(),
                      type: ToastType.success,
                    );
                    context.pop();
                  }
                },
                builder: (context, state) {
                  final isWide =
                      MediaQuery.sizeOf(context).width >= AppBreakpoints.mobile;

                  final receiverName = TextFormField(
                    controller: _receiverNameController,
                    decoration: AppInputStyle.decoration(
                      hintText: 'address.receiver_name_hint'.tr(),
                      radius: 14,
                    ),
                    validator: (value) => _requiredValidator(
                      value,
                      'address.error_receiver_name_required',
                    ),
                  );
                  final phone = TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: AppInputStyle.decoration(
                      hintText: 'address.phone_hint'.tr(),
                      radius: 14,
                    ),
                    validator: (value) => _requiredValidator(
                      value,
                      'address.error_phone_required',
                    ),
                  );
                  final postalCode = TextFormField(
                    controller: _postalCodeController,
                    decoration: AppInputStyle.decoration(
                      hintText: 'address.postal_code_hint'.tr(),
                      radius: 14,
                    ),
                    validator: (value) => _requiredValidator(
                      value,
                      'address.error_postal_code_required',
                    ),
                  );
                  final stateField = TextFormField(
                    controller: _stateController,
                    decoration: AppInputStyle.decoration(
                      hintText: 'address.state_hint'.tr(),
                      radius: 14,
                    ),
                    validator: (value) => _requiredValidator(
                      value,
                      'address.error_state_required',
                    ),
                  );
                  final city = TextFormField(
                    controller: _cityController,
                    decoration: AppInputStyle.decoration(
                      hintText: 'address.city_hint'.tr(),
                      radius: 14,
                    ),
                    validator: (value) => _requiredValidator(
                      value,
                      'address.error_city_required',
                    ),
                  );
                  final street = TextFormField(
                    controller: _streetController,
                    decoration: AppInputStyle.decoration(
                      hintText: 'address.street_hint'.tr(),
                      radius: 14,
                    ),
                    validator: (value) => _requiredValidator(
                      value,
                      'address.error_street_required',
                    ),
                  );
                  final chomeBanchiGo = TextFormField(
                    controller: _chomeBanchiGoController,
                    decoration: AppInputStyle.decoration(
                      hintText: 'address.chome_banchi_go_hint'.tr(),
                      radius: 14,
                    ),
                    validator: (value) => _requiredValidator(
                      value,
                      'address.error_chome_banchi_go_required',
                    ),
                  );
                  final buildingName = TextFormField(
                    controller: _buildingNameController,
                    decoration: AppInputStyle.decoration(
                      hintText: 'address.building_hint'.tr(),
                      radius: 14,
                    ),
                  );

                  return DesktopAccountBody(
                    current: AccountNavItem.address,
                    child: Form(
                      key: _formKey,
                      child: ListView(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        children: [
                          Text(
                            'address.title'.tr(),
                            style: AppTextStyles.headline,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          _fieldPair(isWide, receiverName, phone),
                          const SizedBox(height: AppSpacing.sm),
                          _fieldPair(isWide, postalCode, stateField),
                          const SizedBox(height: AppSpacing.sm),
                          _fieldPair(isWide, city, street),
                          const SizedBox(height: AppSpacing.sm),
                          _fieldPair(isWide, chomeBanchiGo, buildingName),
                          const SizedBox(height: AppSpacing.lg),
                          PrimaryButton(
                            label: 'address.save'.tr(),
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

/// Two fields side by side at tablet/desktop width instead of always
/// stacked — phone keeps the original single-column form untouched.
Widget _fieldPair(bool isWide, Widget a, Widget b) {
  if (!isWide) {
    return Column(
      children: [
        a,
        const SizedBox(height: AppSpacing.sm),
        b,
      ],
    );
  }
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(child: a),
      const SizedBox(width: AppSpacing.sm),
      Expanded(child: b),
    ],
  );
}
