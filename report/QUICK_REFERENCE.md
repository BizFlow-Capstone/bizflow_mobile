# ⚡ QUICK REFERENCE - CHEATSHEET

**Tra cứu nhanh - Dễ tìm kiếm**

---

## 🚀 QUICK START

### 1️⃣ Thêm Widget mới vào Shared

```bash
# Create file
lib/shared/widgets/my_widget.dart

# Code template
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  const MyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
```

### 2️⃣ Tạo Feature mới

```bash
features/feature_name/
├── presentation/
├── domain/
└── data/
```

### 3️⃣ Thêm Route mới

```dart
// core/routing/app_router.dart
class AppRoutes {
  static const String newFeature = '/new-feature';
}
```

### 4️⃣ Lấy dữ liệu từ API

```dart
// Step 1: Define entity
// Step 2: Create API
// Step 3: Create Repository
// Step 4: Create Usecase
// Step 5: Use in Page
```

---

## 🎨 DESIGN SYSTEM CHEATSHEET

### Colors
```dart
AppColors.primary
AppColors.secondary
AppColors.success
AppColors.warning
AppColors.danger
```

### Spacing
```dart
AppSpacing.xs, sm, md, lg, xl, xxl
```

### Text Styles
```dart
AppTextStyles.heading1, heading2, heading3
AppTextStyles.body1, body2
AppTextStyles.caption
```

---

## 📚 QUICK LINKS

- [System Architecture](01_SYSTEM_ARCHITECTURE.md)
- [Report Index](INDEX.md)
- [Report Template](TEMPLATE.md)
- [Changelog](CHANGELOG.md)

---

**Version:** 1.0  
**Status:** ✅ Ready to use
