/// Which home page the shop shows.
///
/// `true` — banner, a small strip of category pictures, then product rows:
/// "Most Everyday" first, then one horizontally scrolling row per category
/// that has products (categories without products don't appear).
///
/// `false` — the original home page: banner, the big "Explore By Categories"
/// grid, then the Most Everyday product grid. Flip this and rebuild to go
/// back; nothing else needs to change (the rows' products aren't even loaded
/// in that mode).
const bool kHomeShowsCategoryRows = true;

/// What the bottom nav's "Category" tab does.
///
/// `true` — opens the Categories page: every category as a picture tile, a
/// category with subcategories opening them in place.
///
/// `false` — the original behaviour: slides the category list in from the
/// right as a side drawer (the page's route stays, it is just not linked).
const bool kCategoryTabOpensPage = true;

/// Most products one home-page row loads for a category; the row's last card
/// ("View all") opens the full category.
const int kHomeRowProductLimit = 10;
