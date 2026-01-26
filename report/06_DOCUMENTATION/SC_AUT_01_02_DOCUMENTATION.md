# 📱 Auth Feature - SC-AUT-01 & SC-AUT-02 Documentation

## Tổng quan
Tạo 2 màn hình Auth (Đăng ký và Xác thực OTP) theo design mobile chuẩn với:
- **SC-AUT-01**: Trang đăng ký (Register Page)
- **SC-AUT-02**: Trang xác thực OTP (Verify OTP Page)

---

## 🎯 SC-AUT-01: Register Page (Đăng ký)

### 📋 Các trường nhập liệu
1. **Họ và Tên** (Name)
   - Placeholder: "Nhập họ và tên của bạn"
   - Keyboard: Name
   - Action: Next → Phone field

2. **Số điện thoại** (Phone)
   - Placeholder: "Nhập số điện thoại của bạn"
   - Keyboard: Phone
   - Action: Next → Email field

3. **Email** (Email)
   - Placeholder: "Nhập email của bạn"
   - Keyboard: Email
   - Action: Next → Password field

4. **Mật khẩu** (Password)
   - Placeholder: "Nhập mật khẩu của bạn"
   - Có nút Show/Hide mật khẩu
   - Keyboard: Default
   - Action: Done → Unfocus

### 🎨 UI Elements
- **Header Icon**: Business icon (lựa chọn, có thể thay đổi)
- **Tiêu đề**: "Tạo tài khoản"
- **Mô tả**: "Đăng ký để bắt đầu sử dụng BizFlow"
- **Nút Đăng ký**: Màu Teal (#23C4C1), Full width, Loading state

### 🔐 Tính năng bổ sung
- **Divider**: Đường chia ngăn "Hoặc"
- **Google Sign Up**: Nút đăng ký với Google (border style)
- **Link chuyển trang**: "Đã có tài khoản? Đăng nhập"

### 🔄 Tương tác
1. Validate các trường bắt buộc
2. Hiển thị error message nếu trống
3. Loading state khi đang gửi request
4. Navigate tới VerifyOtpPage sau khi thành công

---

## 🎯 SC-AUT-02: Verify OTP Page (Xác thực OTP)

### 📋 OTP Input
- **Số ô**: 6 ô nhập liệu
- **Kiểu**: Numeric input
- **Tương tác**:
  - Auto focus next field khi nhập 1 chữ số
  - Auto unfocus và gọi callback khi nhập đủ 6 số
  - Backspace quay lại field trước

### 🎨 UI Elements
- **AppBar**: Có nút back, title "Xác thực OTP"
- **Icon**: Teal circle với lock icon
- **Tiêu đề**: "Xác minh số điện thoại"
- **Mô tả**: Hiển thị số điện thoại được gửi OTP

### ⏱️ Tính năng Resend
1. **Countdown Timer**: 60 giây
   - Hiển thị: "Gửi lại mã sau 60s"
   - Disabled khi countdown chưa hết

2. **Resend Link** (sau 60s)
   - Hiển thị: "Không nhận được mã? Gửi lại"
   - Clickable khi hết timeout
   - Xóa OTP fields khi resend

### 🔄 Tương tác
1. Validate OTP là 6 chữ số
2. Loading state khi xác thực
3. Resend OTP khi click "Gửi lại"
4. Navigate tới next screen khi xác thực thành công

---

## 📁 Cấu trúc Files

```
lib/
├── features/auth/
│   └── presentation/
│       └── pages/
│           ├── register_page.dart
│           ├── verify_otp_page.dart
│           └── pages.dart
│
├── shared/widgets/
│   └── app_otp_input.dart
│
└── core/theme/
    └── app_colors.dart
```

---

## 🔧 Dependencies & Imports

### RegisterPage
```dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
```

### VerifyOtpPage
```dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
```

---

## 💡 Cách sử dụng

### 1. Mở trang đăng ký
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const RegisterPage(),
  ),
);
```

### 2. Mở trang xác thực OTP
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const VerifyOtpPage(phoneNumber: '0987654321'),
  ),
);
```

### 3. Sử dụng AppOtpInput widget
```dart
AppOtpInput(
  length: 6,
  onCompleted: (code) => print('OTP Code: $code'),
  onChanged: (code) => print('Current: $code'),
)
```

---

## 🎨 Design System Integration

### Colors
- **Teal Primary**: `#23C4C1`
- **Text Primary**: `#212121`
- **Text Secondary**: `#757575`
- **Divider**: `#E0E0E0`
- **White**: `#FFFFFF`

### Spacing (AppSpacing)
- **xs**: 4px
- **sm**: 8px
- **md**: 16px
- **lg**: 24px
- **xl**: 32px

### Border Radius
- **radiusMd**: 12px

---

## ✅ Features Implemented

### RegisterPage
- [x] 4 input fields (name, phone, email, password)
- [x] Show/hide password toggle
- [x] Form validation
- [x] Loading state
- [x] Google sign-up button
- [x] Link to login page
- [x] Error/Success messages
- [x] Keyboard navigation
- [x] Mobile-responsive layout

### VerifyOtpPage
- [x] 6 OTP input boxes
- [x] Auto-focus next field
- [x] Countdown timer (60s)
- [x] Resend OTP functionality
- [x] OTP validation
- [x] Loading state
- [x] Back button
- [x] Error/Success messages

### AppOtpInput Widget
- [x] Reusable OTP input
- [x] Configurable length
- [x] Callbacks support
- [x] Auto navigation
- [x] Clear method

---

## 🚀 Next Steps (Phase 2)

### RegisterPage
- [ ] Integrate Auth API (register endpoint)
- [ ] Add phone number format validation
- [ ] Add email format validation
- [ ] Integrate Google Sign-Up

### VerifyOtpPage
- [ ] Integrate Auth API (verify OTP endpoint)
- [ ] Integrate Auth API (resend OTP endpoint)
- [ ] Navigate to next screen

### General
- [ ] Add unit tests
- [ ] Add widget tests
- [ ] Add integration tests

---

**Generated**: 26/01/2026  
**Status**: ✅ COMPLETE
