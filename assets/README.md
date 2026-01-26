# Assets Folder Structure

This folder contains all static assets for the BizFlow Mobile App.

## Organization

```
assets/
├── images/
│   ├── logos/           (App logos, icons)
│   ├── illustrations/   (Illustrations, graphics)
│   ├── backgrounds/     (Background images)
│   └── icons/          (Custom icons, SVGs)
├── icons/
│   └── google.png      (Google icon for sign-up)
├── animations/         (Lottie animations)
└── fonts/             (Custom fonts)
```

## Image Naming Convention

- **logos**: `app_logo_*.png`, `bizflow_logo_*.png`
- **illustrations**: `auth_illustration_*.png`, `empty_state_*.png`
- **icons**: `icon_*.png`, `*.svg`
- **backgrounds**: `bg_*.png`, `bg_*.jpg`

## Supported Formats

- Images: `.png`, `.jpg`, `.jpeg`, `.gif`, `.webp`
- Icons: `.svg`, `.png`
- Animations: `.json` (Lottie)

## Usage Example

```dart
// Load image from assets
Image.asset('assets/images/logos/app_logo.png')

// Load SVG icon
SvgPicture.asset('assets/images/icons/custom_icon.svg')

// Load background image
Image.asset(
  'assets/images/backgrounds/bg_register.png',
  fit: BoxFit.cover,
)
```

## Adding New Images

1. Place image file in appropriate subfolder
2. Update `pubspec.yaml` if adding new file types
3. Use in code with: `Image.asset('assets/path/to/image.png')`

## Performance Tips

- Use `.webp` format for better compression
- Optimize images before adding (use TinyPNG, etc.)
- Use appropriate resolution (2x, 3x for different screens)
- Lazy load images when possible
