// Example usage của Register & Verify OTP screens

/*
=== SC-AUT-01: RegisterPage ===
- Trang đăng ký với:
  • Họ và Tên (Name)
  • Số điện thoại (Phone)
  • Email
  • Mật khẩu (Password) - có nút show/hide
  • Nút đăng ký (nút teal #23C4C1)
  • Đường chia ngăn "Hoặc"
  • Nút đăng ký với Google
  • Link chuyển tới trang đăng nhập

Cách sử dụng:
```dart
import 'package:bizflow_mobile/features/auth/presentation/pages/register_page.dart';

Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const RegisterPage(),
  ),
);
```

=== SC-AUT-02: VerifyOtpPage ===
- Trang xác thực OTP với:
  • Icon lock
  • Tiêu đề "Xác minh số điện thoại"
  • Hiển thị số điện thoại cần xác thực
  • 6 ô nhập mã OTP
  • Nút xác thực OTP
  • Countdown timer để gửi lại mã (60 giây)
  • Link "Gửi lại" khi hết timeout

Cách sử dụng:
```dart
import 'package:bizflow_mobile/features/auth/presentation/pages/verify_otp_page.dart';

Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const VerifyOtpPage(
      phoneNumber: '0987654321',
    ),
  ),
);
```

=== AppOtpInput Widget (Shared) ===
- Widget OTP Input có thể tái sử dụng ở các màn hình khác
- Support length tùy chỉnh
- Callback khi hoàn thành và khi thay đổi

Cách sử dụng:
```dart
import 'package:bizflow_mobile/shared/widgets/app_otp_input.dart';

AppOtpInput(
  length: 6,
  onCompleted: (code) {
    print('OTP Code: $code');
  },
  onChanged: (code) {
    print('Current: $code');
  },
),
```
*/
