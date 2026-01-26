# 🧪 Testing Guide - SC-AUT-01 & SC-AUT-02

**Last Updated**: 26/01/2026

---

## 1. Manual Testing Checklist

### RegisterPage (SC-AUT-01)

#### Visual & Layout
- [ ] Logo/icon displays correctly (teal color)
- [ ] Title "Tạo tài khoản" centered
- [ ] Subtitle text visible
- [ ] All 4 input fields visible with labels
- [ ] Labels: Họ và Tên, Số điện thoại, Email, Mật khẩu
- [ ] Google button displays properly
- [ ] "Đã có tài khoản? Đăng nhập" link visible
- [ ] Button colors: Teal (#23C4C1)
- [ ] Responsive on different screen sizes

#### Input Validation
- [ ] Empty name → Error "Vui lòng nhập họ và tên"
- [ ] Empty phone → Error "Vui lòng nhập số điện thoại"
- [ ] Empty email → Error "Vui lòng nhập email"
- [ ] Empty password → Error "Vui lòng nhập mật khẩu"
- [ ] All filled → Can proceed

#### Input Fields
- [ ] Name field accepts text input
- [ ] Phone field accepts numeric input
- [ ] Email field accepts email input
- [ ] Password field hides text (dots)
- [ ] Password visibility toggle works (show/hide)

#### Focus Navigation
- [ ] Name field → Next → Phone field
- [ ] Phone field → Next → Email field
- [ ] Email field → Next → Password field
- [ ] Password field → Done → Unfocus

#### Loading State
- [ ] Click Register → Button shows spinner
- [ ] During loading → Button disabled
- [ ] After 2 seconds → Loading stops
- [ ] Success message shows

#### Google Button
- [ ] Click Google button → Triggers sign-up
- [ ] Visual style: Border button
- [ ] Responsive: Full width on mobile

#### Navigation
- [ ] Click "Đăng nhập" link → Navigate to login

---

### VerifyOtpPage (SC-AUT-02)

#### Visual & Layout
- [ ] AppBar with back button displays
- [ ] Title "Xác thực OTP" shows
- [ ] Lock icon in teal circle visible
- [ ] Phone number displays correctly
- [ ] 6 OTP input boxes aligned
- [ ] "Verify OTP" button full width
- [ ] Resend section displays
- [ ] Responsive on different screen sizes

#### OTP Input
- [ ] Type in box 1 → Auto-focus to box 2
- [ ] Type in box 2 → Auto-focus to box 3
- [ ] Type in box 3 → Auto-focus to box 4
- [ ] Type in box 4 → Auto-focus to box 5
- [ ] Type in box 5 → Auto-focus to box 6
- [ ] Type in box 6 → Auto-unfocus
- [ ] Only 1 digit per box

#### Backspace Navigation
- [ ] In box 2, backspace → Focus to box 1
- [ ] In box 3, backspace → Focus to box 2

#### Verification
- [ ] Type < 6 digits, click verify → Error message
- [ ] Type 6 digits, click verify → Loading spinner
- [ ] After 2 seconds → Success message
- [ ] Navigate to next screen

#### Timer & Resend
- [ ] Timer shows "Gửi lại mã sau 60s"
- [ ] Timer decrements each second
- [ ] At 0s → "Gửi lại" link enabled
- [ ] Click "Gửi lại" → All fields cleared
- [ ] Click "Gửi lại" → Timer resets to 60

---

## 2. Unit Test Templates

### RegisterPage Tests
```dart
testWidgets('should display all required fields', (tester) async {
  await tester.pumpWidget(const MaterialApp(home: RegisterPage()));
  
  expect(find.byType(AppTextField), findsWidgets);
  expect(find.text('Họ và Tên'), findsOneWidget);
  expect(find.text('Số điện thoại'), findsOneWidget);
  expect(find.text('Email'), findsOneWidget);
  expect(find.text('Mật khẩu'), findsOneWidget);
});

testWidgets('should show error when name is empty', (tester) async {
  await tester.pumpWidget(const MaterialApp(home: RegisterPage()));
  
  await tester.tap(find.byType(AppButton));
  await tester.pumpAndSettle();
  
  expect(find.text('Vui lòng nhập họ và tên'), findsOneWidget);
});

testWidgets('password visibility toggle works', (tester) async {
  await tester.pumpWidget(const MaterialApp(home: RegisterPage()));
  
  expect(find.byIcon(Icons.visibility_off), findsOneWidget);
  
  await tester.tap(find.byIcon(Icons.visibility_off));
  await tester.pumpAndSettle();
  
  expect(find.byIcon(Icons.visibility), findsOneWidget);
});
```

### VerifyOtpPage Tests
```dart
testWidgets('should display 6 OTP input boxes', (tester) async {
  await tester.pumpWidget(
    const MaterialApp(
      home: VerifyOtpPage(phoneNumber: '0987654321'),
    ),
  );
  
  expect(find.byType(TextField), findsNWidgets(6));
});

testWidgets('should auto-focus next field', (tester) async {
  await tester.pumpWidget(
    const MaterialApp(
      home: VerifyOtpPage(phoneNumber: '0987654321'),
    ),
  );
  
  final firstField = find.byType(TextField).first;
  await tester.tap(firstField);
  await tester.enterText(firstField, '1');
  await tester.pump();
  
  // Second field should be focused
});

testWidgets('should show error when OTP incomplete', (tester) async {
  await tester.pumpWidget(
    const MaterialApp(
      home: VerifyOtpPage(phoneNumber: '0987654321'),
    ),
  );
  
  // Only fill 3 digits
  for (int i = 0; i < 3; i++) {
    await tester.enterText(find.byType(TextField).at(i), '1');
  }
  
  await tester.tap(find.byType(AppButton));
  await tester.pumpAndSettle();
  
  expect(find.text('Vui lòng nhập đầy đủ mã OTP'), findsOneWidget);
});
```

---

## 3. Integration Test Template

```dart
testWidgets('Full registration and OTP verification flow', (tester) async {
  await tester.pumpWidget(const MyApp());
  
  // Navigate to RegisterPage
  await tester.tap(find.byText('Đăng ký'));
  await tester.pumpAndSettle();
  
  // Fill registration form
  await tester.enterText(find.byType(AppTextField).at(0), 'Nguyễn Văn A');
  await tester.enterText(find.byType(AppTextField).at(1), '0987654321');
  await tester.enterText(find.byType(AppTextField).at(2), 'user@example.com');
  await tester.enterText(find.byType(AppTextField).at(3), 'SecurePass123!');
  
  // Click Register
  await tester.tap(find.byType(AppButton));
  await tester.pumpAndSettle(const Duration(seconds: 3));
  
  // Should navigate to VerifyOtpPage
  expect(find.byType(VerifyOtpPage), findsOneWidget);
  
  // Enter OTP
  for (int i = 0; i < 6; i++) {
    await tester.enterText(find.byType(TextField).at(i), '1');
    await tester.pump();
  }
  
  // Verify OTP
  await tester.tap(find.byText('Xác thực OTP'));
  await tester.pumpAndSettle(const Duration(seconds: 3));
  
  // Should navigate to HomeScreen
  expect(find.byType(HomeScreen), findsOneWidget);
});
```

---

## 4. Performance Tests

### Build Time
```dart
testWidgets('RegisterPage should build quickly', (tester) async {
  final stopwatch = Stopwatch()..start();
  
  await tester.pumpWidget(const MaterialApp(home: RegisterPage()));
  
  stopwatch.stop();
  
  expect(stopwatch.elapsedMilliseconds, lessThan(1000)); // < 1 second
});
```

### Memory Usage
- Check memory before RegisterPage
- Navigate to RegisterPage
- Check memory increase (should be < 50MB)
- Dispose and check memory release

### Animations
- Password show/hide: Smooth transition
- Loading spinner: Consistent rotation
- SnackBar: Slide animation smooth

---

## 5. Accessibility Testing

### Semantic Labels
- [x] All input fields have labels
- [x] Button text is clear
- [x] Icons have meaningful labels

### Color Contrast
- [x] Text color vs background: WCAG AA
- [x] Error message: Visible color
- [x] Success message: Visible color

### Touch Targets
- [x] Button height: > 48dp
- [x] Input field height: > 48dp
- [x] Touch target padding: > 8dp

### Screen Reader
- [ ] All interactive elements announced
- [ ] Form labels associated with fields
- [ ] Error messages announced

---

## 6. Device Testing

### Screen Sizes
- [ ] Pixel 4a (5.8")
- [ ] Pixel 5 (6.0")
- [ ] Galaxy S21 (6.2")
- [ ] Tablet (7")
- [ ] Large tablet (10")

### Orientations
- [ ] Portrait mode
- [ ] Landscape mode
- [ ] Rotation handling

### System Settings
- [ ] Light theme
- [ ] Dark theme
- [ ] Large text size
- [ ] Bold text
- [ ] High contrast mode

---

## 7. Edge Cases

### RegisterPage
- [ ] Very long name (100+ chars)
- [ ] Very long password (100+ chars)
- [ ] Special characters in inputs
- [ ] Copy/paste phone number
- [ ] Rapid button clicks (prevent double submit)
- [ ] Network timeout
- [ ] Back button during loading

### VerifyOtpPage
- [ ] Paste all 6 digits at once
- [ ] Rapid digit input
- [ ] Rapid backspace
- [ ] Quick resend clicks
- [ ] Page navigate away during timer
- [ ] Back button with OTP filled
- [ ] Network timeout

---

## 8. Test Execution

### Run all tests
```bash
flutter test
```

### Run specific test file
```bash
flutter test test/features/auth/presentation/pages/register_page_test.dart
```

### Run with coverage
```bash
flutter test --coverage
```

### Generate coverage report
```bash
lcov --list coverage/lcov.info
```

---

## ✅ Checklist Before Deployment

- [ ] All manual tests passed
- [ ] Unit tests written & passing
- [ ] Widget tests written & passing
- [ ] Integration tests written & passing
- [ ] Performance acceptable
- [ ] Accessibility features working
- [ ] Device testing completed
- [ ] Edge cases handled
- [ ] No console errors
- [ ] Code coverage > 80%

---

**Status**: ✅ Test Guide Ready for Implementation  
**Last Updated**: 26/01/2026
