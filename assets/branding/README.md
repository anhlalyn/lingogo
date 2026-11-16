# LingoGo branding

Master: `lingogo_logo.png`, generated with the built-in imagegen tool.
Creative concept: white open book merged with a speech bubble, purple background,
small gold sparkle; no text so it remains readable as an app icon.

Final generation prompt:

> Use case: logo-brand. Asset type: production mobile app icon master for LingoGo, a friendly multilingual learning app. Create one polished original symbol, no text or letters: a white rounded speech bubble merged elegantly with the silhouette of an open book, a small warm yellow four-point sparkle near its upper right, inside a solid rich lavender-purple square background (#7566E8). Minimal bold vector-like geometric design, balanced and distinctive, crisp edges, strong legibility at 48 pixels, professional education app brand. Square 1024x1024 composition, full-bleed purple background with no rounded outer corners, no border, no shadow, no gradient, no watermark. Keep the white main symbol within the central 60% of the image, generous purple safe margin on all sides for Android adaptive circular masks. Flat icon, no perspective, no device mockup.

Native icons are derived by flutter_launcher_icons; splash artwork is resized and
padded by `tool/prepare_branding.dart`, preserving the master design.

Regenerate derivatives from the project root:

```sh
dart run tool/prepare_branding.dart
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```
