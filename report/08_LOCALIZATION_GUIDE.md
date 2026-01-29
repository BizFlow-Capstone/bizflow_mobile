# Hướng dẫn Sử dụng Localization (Đa Ngôn Ngữ)

## 📱 Giới thiệu

BizFlow hỗ trợ đa ngôn ngữ bằng cách sử dụng `AppLocalizations` và các file JSON (vi.json, en.json).

Hiện tại hỗ trợ:
- 🇻🇳 **Tiếng Việt** (vi)
- 🇬🇧 **English** (en)

---

## 🗂️ Cấu trúc File

```
lib/core/localization/
├── app_localizations.dart      # Main localization class
├── vi.json                      # Vietnamese translations
└── en.json                      # English translations
```

---

## 📖 Các Key Có Sẵn

### 1. **Common** - Các text chung
```
common.ok
common.cancel
common.save
common.delete
common.edit
common.close
common.back
common.next
common.done
common.confirm
common.loading
common.retry
common.search
common.no_data
common.error
common.success
common.warning
```

### 2. **Auth** - Xác thực
```
auth.login
auth.logout
auth.register
auth.email
auth.password
auth.sign_up
auth.sign_in
auth.verify_otp_title
auth.verify_button
auth.resend_otp
... (và nhiều key khác)
```

### 3. **Location** - Quản lý địa điểm ⭐ NEW
```
location.title                    → "Quản lý địa điểm kinh doanh"
location.subtitle                 → "Quản lý các ĐDKD của bạn"
location.search_placeholder       → "Tìm kiếm địa điểm kinh doanh"
location.active_status            → "Đang hoạt động"
location.inactive_status          → "Không hoạt động"
location.no_locations             → "Chưa có địa điểm kinh doanh"
location.add_manager              → "Thêm Nhân Viên"
location.manage_products          → "Quản lý sản phẩm"
location.create_location_title    → "Tạo Kho Mới"
location.edit_location_title      → "Sửa Kho"
location.location_name            → "Tên Kho"
location.location_name_hint       → "Nhập tên kho"
location.location_address         → "Địa Chỉ"
location.location_address_hint    → "Nhập địa chỉ"
location.location_manager         → "Thêm Nhân Viên Quản Lý Kho"
location.location_manager_hint    → "Nhập tên nhân viên"
location.create_button            → "Tạo kho"
location.update_button            → "Cập nhật"
location.status_updated           → "Cập nhật trạng thái thành công"
location.location_added           → "Thêm địa điểm thành công"
location.location_updated         → "Cập nhật địa điểm thành công"
location.location_deleted         → "Xóa địa điểm thành công"
location.validation_error         → "Vui lòng điền đầy đủ thông tin"
```

---

## 💻 Cách Sử Dụng Trong Code

### 1. **Import AppLocalizations**
```dart
import '../../../../core/localization/app_localizations.dart';

class MyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Text(l10n.translate('location.title'));
  }
}
```

### 2. **Các Method Có Sẵn**

#### `translate(key)` - Lấy text theo key
```dart
final l10n = AppLocalizations.of(context);
final title = l10n.translate('location.title');
// Result (Vi): "Quản lý địa điểm kinh doanh"
// Result (En): "Business Location Management"
```

#### `translate(key, params)` - Với parameter
```dart
final message = l10n.translate('validation.password_min_length', {'min': '8'});
// Result: "Mật khẩu tối thiểu 8 ký tự"
```

### 3. **Ví Dụ Sử Dụng Trong Location Pages**

**location_management_page.dart**:
```dart
@override
Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  
  return Scaffold(
    appBar: AppBar(
      title: Text(l10n.translate('location.title')),
    ),
    body: TextField(
      decoration: InputDecoration(
        hintText: l10n.translate('location.search_placeholder'),
      ),
    ),
  );
}
```

**add_edit_location_page.dart**:
```dart
Text(
  isEditMode 
    ? l10n.translate('location.edit_location_title')
    : l10n.translate('location.create_location_title'),
),
TextField(
  decoration: InputDecoration(
    hintText: l10n.translate('location.location_name_hint'),
  ),
),
AppButton(
  label: isEditMode 
    ? l10n.translate('location.update_button')
    : l10n.translate('location.create_button'),
),
```

---

## 🌐 Cách Thêm Key Mới

### 1. **Thêm vào vi.json**
```json
{
  "location": {
    "my_new_key": "Chuỗi Tiếng Việt"
  }
}
```

### 2. **Thêm vào en.json**
```json
{
  "location": {
    "my_new_key": "English String"
  }
}
```

### 3. **Sử dụng trong code**
```dart
final l10n = AppLocalizations.of(context);
Text(l10n.translate('location.my_new_key'));
```

---

## 🔄 Chuyển Ngôn Ngữ Tại Runtime

### Thay đổi locale trong main.dart
```dart
MaterialApp(
  locale: const Locale('en'),  // English
  // hoặc
  locale: const Locale('vi'),  // Vietnamese
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
)
```

---

## 📋 Ngôn Ngữ Hỗ Trợ

| Ngôn Ngữ | Code | File |
|---------|------|------|
| Tiếng Việt | `vi` | `vi.json` |
| English | `en` | `en.json` |

---

## 🎯 Best Practices

### ✅ Nên
```dart
// ✅ Tốt: Sử dụng translate
final l10n = AppLocalizations.of(context);
Text(l10n.translate('location.title'))

// ✅ Tốt: Lưu l10n thành biến local
final l10n = AppLocalizations.of(context);
@override
Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  // Sử dụng l10n nhiều lần
}
```

### ❌ Không Nên
```dart
// ❌ Tệ: Hardcode text
Text('Quản lý địa điểm kinh doanh')

// ❌ Tệ: Gọi AppLocalizations.of() nhiều lần
Text(AppLocalizations.of(context).translate('location.title'))
Text(AppLocalizations.of(context).translate('location.subtitle'))
// Gọi lại: Text(AppLocalizations.of(context).translate('location.add_manager'))

// ✅ Tốt: Lưu vào biến
final l10n = AppLocalizations.of(context);
Text(l10n.translate('location.title'))
Text(l10n.translate('location.subtitle'))
Text(l10n.translate('location.add_manager'))
```

---

## 🔍 Testing Localization

### Thay đổi ngôn ngữ trong MaterialApp
```dart
class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale _locale = const Locale('vi');
  
  void _changeLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: _locale,
      // ... config ...
    );
  }
}
```

---

## 📊 Các File Location Đã Cập Nhật

✅ **location_management_page.dart** - Sử dụng l10n cho:
- AppBar title
- Search placeholder
- Empty state message
- Snackbar messages

✅ **add_edit_location_page.dart** - Sử dụng l10n cho:
- AppBar title (Create/Edit mode)
- Form labels
- Form hints
- Button labels
- Validation messages

✅ **product_management_page.dart** - Sử dụng l10n cho:
- AppBar title
- Empty state message

---

## 🚀 Bước Tiếp Theo

1. **Thêm ngôn ngữ mới** (nếu cần):
   - Tạo file `zh.json` cho Tiếng Trung
   - Thêm locale vào `AppLocalizations`

2. **Hoàn thiện translations**:
   - Kiểm tra tất cả keys có trong cả vi.json và en.json
   - Ensure consistency

3. **Language Switcher Widget**:
   - Đã có sẵn ở `shared/widgets/language_switcher.dart`
   - Có thể integrate vào Settings page

---

**Last Updated**: January 29, 2026  
**Feature**: Location Management Localization  
**Status**: ✅ Implemented
