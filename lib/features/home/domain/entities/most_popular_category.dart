import '../../../../core/constants/asset_paths.dart';
import '../../../../core/localization/localized_text.dart';
import 'category_entity.dart';

/// Reserved id of the storefront's virtual "Most Popular" category. It has
/// no `categories` doc — its products are whichever ones the admin flagged
/// `isMostPopular`, each still living in its own real category too. The id
/// is what goes in the URL (`/home/category/most_popular`), and the product
/// repository maps it to that flag query instead of a `categoryId` match.
const String mostPopularCategoryId = 'most_popular';

const CategoryEntity mostPopularCategory = CategoryEntity(
  id: mostPopularCategoryId,
  name: LocalizedText(en: 'Most Popular', ja: '人気商品'),
  iconKey: 'most_popular',
  imageUrl: AssetPaths.mostPopularCategoryImage,
);

/// The customer-facing category list: [mostPopularCategory] first when at
/// least one product is flagged, then the real categories. Any real doc that
/// happens to use the reserved id (e.g. from old seed data) is dropped so it
/// can't show up twice. Admin screens use the plain list, never this one.
List<CategoryEntity> withMostPopular(List<CategoryEntity> categories, {required bool hasMostPopular}) => [
  if (hasMostPopular) mostPopularCategory,
  ...categories.where((category) => category.id != mostPopularCategoryId),
];
