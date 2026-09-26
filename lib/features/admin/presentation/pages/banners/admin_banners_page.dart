import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../config/di/injection_container.dart';
import '../../../../../shared/theme/app_colors.dart';
import '../../../../../shared/theme/app_spacing.dart';
import '../../../../../shared/theme/app_text_styles.dart';
import '../../../../../shared/utils/toast.dart';
import '../../../../../shared/widgets/coming_soon_view.dart';
import '../../../../../shared/widgets/dialogs/confirm_dialog.dart';
import '../../../../home/domain/entities/promo_banner_entity.dart';
import '../../../../home/presentation/widgets/home_promo_carousel.dart';
import '../../bloc/banners/banner_list_bloc.dart';
import '../../bloc/banners/banner_list_event.dart';
import '../../bloc/banners/banner_list_state.dart';

/// Home-page banner management — upload (straight from the picker, no form:
/// a banner is just an image), delete, and reorder. The list order here is
/// exactly the order customers see in [HomePromoCarousel].
class AdminBannersPage extends StatelessWidget {
  const AdminBannersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<BannerListBloc>()..add(const BannerListRequested()),
      child: const _BannerListView(),
    );
  }
}

class _BannerListView extends StatelessWidget {
  const _BannerListView();

  Future<void> _pickAndUpload(BuildContext context) async {
    final bloc = context.read<BannerListBloc>();
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 2400, imageQuality: 85);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    final extension = picked.name.contains('.') ? picked.name.split('.').last : 'jpg';
    bloc.add(BannerAddRequested(bytes: bytes, fileExtension: extension));
  }

  Future<void> _confirmDelete(BuildContext context, PromoBannerEntity banner) async {
    final bloc = context.read<BannerListBloc>();
    final confirmed = await showConfirmDialog(
      context,
      title: 'admin.delete_banner_title'.tr(),
      message: 'admin.delete_banner_message'.tr(),
      confirmLabel: 'admin.delete'.tr(),
      cancelLabel: 'admin.cancel'.tr(),
    );
    if (confirmed) bloc.add(BannerDeleteRequested(banner));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BannerListBloc, BannerListState>(
      listenWhen: (previous, current) => current.errorMessage != null && previous.errorMessage != current.errorMessage,
      listener: (context, state) => AppToast.show(context, state.errorMessage!.tr(), type: ToastType.error),
      builder: (context, state) {
        final canAdd = !state.isLoading && !state.isBusy && !state.isFull;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
              child: Row(
                children: [
                  Expanded(child: Text('admin.nav_banners'.tr(), style: AppTextStyles.headline)),
                  if (!state.isLoading)
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: Text(
                        '${state.banners.length}/${PromoBannerEntity.maxBanners}',
                        style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                  Material(
                    color: canAdd ? AppColors.primary : AppColors.textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: canAdd ? () => _pickAndUpload(context) : null,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              'admin.add_banner'.tr(),
                              style: AppTextStyles.body.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
              child: Text(
                state.isFull
                    ? 'admin.banners_full'.tr(namedArgs: {'max': '${PromoBannerEntity.maxBanners}'})
                    : 'admin.banners_hint'.tr(namedArgs: {'max': '${PromoBannerEntity.maxBanners}'}),
                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
              ),
            ),
            SizedBox(height: 3, child: state.isBusy ? const LinearProgressIndicator() : null),
            Expanded(child: _buildBody(context, state)),
          ],
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, BannerListState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.banners.isEmpty) {
      return ComingSoonView(
        icon: Icons.view_carousel_outlined,
        title: 'admin.banners_empty_title'.tr(),
        message: 'admin.banners_empty_message'.tr(),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = AppSpacing.md;
        final columns = (constraints.maxWidth / 460).ceil().clamp(1, 3);
        final tileWidth = (constraints.maxWidth - spacing * (columns + 1)) / columns;
        return GridView.builder(
          padding: const EdgeInsets.all(spacing),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            mainAxisExtent: tileWidth / bannerAspectRatio + _BannerTile.actionBarHeight,
          ),
          itemCount: state.banners.length,
          itemBuilder: (context, index) {
            final bloc = context.read<BannerListBloc>();
            return _BannerTile(
              banner: state.banners[index],
              position: index + 1,
              enabled: !state.isBusy,
              onMoveEarlier: index == 0 ? null : () => bloc.add(BannerMoved(from: index, to: index - 1)),
              onMoveLater: index == state.banners.length - 1
                  ? null
                  : () => bloc.add(BannerMoved(from: index, to: index + 1)),
              onDelete: () => _confirmDelete(context, state.banners[index]),
            );
          },
        );
      },
    );
  }
}

class _BannerTile extends StatelessWidget {
  const _BannerTile({
    required this.banner,
    required this.position,
    required this.enabled,
    required this.onMoveEarlier,
    required this.onMoveLater,
    required this.onDelete,
  });

  static const double actionBarHeight = 52;

  final PromoBannerEntity banner;
  final int position;
  final bool enabled;
  final VoidCallback? onMoveEarlier;
  final VoidCallback? onMoveLater;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.14), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: bannerAspectRatio,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  child: Image.network(
                    banner.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Center(child: Icon(Icons.image_outlined, size: 32, color: Colors.black26)),
                  ),
                ),
                Positioned(
                  left: AppSpacing.sm,
                  top: AppSpacing.sm,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '#$position',
                      style: AppTextStyles.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: actionBarHeight,
            child: Row(
              children: [
                IconButton(
                  tooltip: 'admin.move_earlier'.tr(),
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: enabled ? onMoveEarlier : null,
                ),
                IconButton(
                  tooltip: 'admin.move_later'.tr(),
                  icon: const Icon(Icons.arrow_forward_rounded),
                  onPressed: enabled ? onMoveLater : null,
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'admin.delete'.tr(),
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                  onPressed: enabled ? onDelete : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
