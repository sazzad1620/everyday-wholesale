# Product images

How product photos are shown and prepared. Photos come from admins as plain-background packshots (pure white, off-white, light grey, with very different built-in margins) and the occasional full-bleed photo.

## Display — one tile, one padding rule

Every product photo goes through [`ProductImage`](../lib/shared/widgets/product_image.dart): a **white tile**, the photo fitted inside it with `BoxFit.contain` (never cropped), with **8 % of the tile's shorter side** as space on every edge (`ProductImage.insetFraction`). Because the inset is a ratio, a 44 px search thumbnail, a 64 px cart thumbnail and a 600 px detail image have the same proportional breathing room.

- `radius` + `bordered: true` → standalone tiles (detail page, cart, order/review lists, search, admin picker): rounded, with a hairline border so the white tile doesn't dissolve into the white page.
- Defaults (`radius: 0`, no border) → inside `ProductCard`, where the card's own rounding/shadow is the frame.
- Categories do **not** use this — they keep their tinted-tile look (`CategoryImage`).

To change the spacing everywhere, change `insetFraction` only.

## Upload — cleanup so the padding is the only margin

The admin product form runs every picked photo through [`ProductImageCleaner`](../lib/core/utils/product_image_cleaner.dart) before the normal resize/JPEG step:

1. If the photo is a product on a **plain light background**: the background connected to the edges is flood-filled to pure white (white *inside* the product, e.g. a label, is untouched), then the empty margin is trimmed.
2. **Full-bleed photos** (lifestyle shots, dark/busy backgrounds, a product filling the frame) are left exactly as they are.

Cleaned uploads carry the Storage metadata `bgClean: 1`.

## Existing photos — one-time re-process

`lib/tools/optimize_images.dart` has a checkbox **"Product photos: whiten plain backgrounds + trim margins"**:

```
flutter run -t lib/tools/optimize_images.dart -d chrome
```

Sign in as admin, tick the box, **start with a dry run** (it logs, per photo, whether it would be cleaned or left alone), then run for real. It writes new files and updates each product's `images`/`thumbnails`; old files stay in Storage because past orders reference their URLs. Photos already carrying `bgClean: 1` are skipped, so it is safe to re-run.

Tuning knobs live at the top of the cleaner (`_tolerance`, `_minBackgroundBrightness`, `_minBorderMatch`, `_contentThreshold`); tests in `test/core/utils/product_image_cleaner_test.dart`.
