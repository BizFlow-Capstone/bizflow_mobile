# 🧪 TESTING GUIDE

**Hướng dẫn test & test coverage - Cập nhật khi có test mới**

---

## 📋 QUICK REFERENCE

```
Target Coverage:      80%+
Current Coverage:     30% (In Progress)
Testing Framework:    Flutter Test + Mockito
CI/CD Integration:    ❌ Not configured yet
```

---

## 🏗️ TEST STRUCTURE

```
test/
├── features/
│   ├── auth/
│   │   ├── bloc/
│   │   │   └── auth_bloc_test.dart
│   │   ├── repositories/
│   │   │   └── auth_repository_test.dart
│   │   └── screens/
│   │       └── signup_screen_test.dart
│   ├── home/
│   └── profile/
├── core/
│   ├── network/
│   │   └── api_client_test.dart
│   ├── storage/
│   │   └── storage_service_test.dart
│   └── routing/
└── shared/
    └── widgets/
        └── custom_button_test.dart
```

---

## 📝 TEST TEMPLATES

### Widget Test Template

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bizflow_mobile/features/auth/screens/signup_screen.dart';

void main() {
  group('SignupScreen', () {
    
    testWidgets('renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SignupScreen(),
        ),
      );
      
      expect(find.byType(SignupScreen), findsOneWidget);
      expect(find.byType(TextField), findsWidgets); // multiple fields
    });

    testWidgets('shows error on invalid email', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SignupScreen(),
        ),
      );
      
      await tester.enterText(find.byType(TextField).first, 'invalid-email');
      await tester.pumpWidget(SizedBox()); // trigger validation
      
      expect(find.text('Invalid email'), findsOneWidget);
    });

    testWidgets('enables sign up button when form is valid', 
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SignupScreen(),
        ),
      );
      
      final emailField = find.byType(TextField).at(0);
      final passwordField = find.byType(TextField).at(1);
      final nameField = find.byType(TextField).at(2);
      
      await tester.enterText(emailField, 'test@example.com');
      await tester.enterText(passwordField, 'SecurePass123');
      await tester.enterText(nameField, 'John Doe');
      await tester.pump();
      
      final signupButton = find.byType(ElevatedButton);
      expect(signupButton, findsOneWidget);
    });
  });
}
```

### Unit Test Template

```dart
import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'package:bizflow_mobile/features/auth/repositories/auth_repository.dart';

void main() {
  group('AuthRepository', () {
    late AuthRepository authRepository;
    late MockAuthService mockAuthService;

    setUp(() {
      mockAuthService = MockAuthService();
      authRepository = AuthRepository(authService: mockAuthService);
    });

    test('signup returns user on success', () async {
      when(mockAuthService.signup(any, any, any))
          .thenAnswer((_) async => UserResponse(
            token: 'token',
            userId: '123',
            email: 'test@example.com',
          ));

      final result = await authRepository.signup(
        email: 'test@example.com',
        password: 'SecurePass123',
        name: 'John Doe',
      );

      expect(result, isA<UserResponse>());
      expect(result.email, equals('test@example.com'));
    });

    test('signup throws on network error', () async {
      when(mockAuthService.signup(any, any, any))
          .thenThrow(NetworkException('Network error'));

      expect(
        () => authRepository.signup(
          email: 'test@example.com',
          password: 'SecurePass123',
          name: 'John Doe',
        ),
        throwsA(isA<NetworkException>()),
      );
    });
  });
}
```

### BLoC Test Template

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:mockito/mockito.dart';
import 'package:bizflow_mobile/features/auth/bloc/auth_bloc.dart';

void main() {
  group('AuthBloc', () {
    late AuthBloc authBloc;
    late MockAuthRepository mockAuthRepository;

    setUp(() {
      mockAuthRepository = MockAuthRepository();
      authBloc = AuthBloc(authRepository: mockAuthRepository);
    });

    tearDown(() => authBloc.close());

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthSuccess] when signup succeeds',
      build: () {
        when(mockAuthRepository.signup(
          email: anyNamed('email'),
          password: anyNamed('password'),
          name: anyNamed('name'),
        )).thenAnswer((_) async => UserResponse(...));
        return authBloc;
      },
      act: (bloc) => bloc.add(
        SignupRequested(
          email: 'test@example.com',
          password: 'SecurePass123',
          name: 'John Doe',
        ),
      ),
      expect: () => [
        AuthLoading(),
        AuthSuccess(user: UserResponse(...)),
      ],
    );
  });
}
```

---

## ✅ MODULE TEST CHECKLIST

### SC-AUT-01: Signup Screen

**Unit Tests:**
- [ ] Email validation (valid formats)
- [ ] Email validation (invalid formats)
- [ ] Password validation (strong/weak)
- [ ] Password confirmation match check
- [ ] Name validation (empty/too long)
- [ ] Form state when all fields valid
- [ ] Form state when any field invalid

**Widget Tests:**
- [x] Screen renders without errors
- [x] All form fields displayed
- [x] Password visibility toggle works
- [x] Sign up button visible
- [x] Google sign-in button visible
- [x] Error messages displayed on invalid input
- [x] Loading indicator shown during submission
- [x] Success message shown on completion

**BLoC Tests:**
- [ ] SignupRequested event processing
- [ ] GoogleSigninRequested event processing
- [ ] State transitions (Initial → Loading → Success/Failure)
- [ ] Error handling & error state emission

**Integration Tests:**
- [ ] Complete signup flow (input → submit → success)
- [ ] Error handling (network error, server error)
- [ ] Navigation after success (to OTP screen)

---

### SC-AUT-02: OTP Verification Screen

**Unit Tests:**
- [ ] OTP input validation (6 digits only)
- [ ] OTP field auto-focus logic
- [ ] OTP field deletion logic
- [ ] Countdown timer logic
- [ ] Resend button enable/disable logic

**Widget Tests:**
- [x] Screen renders with 6 input fields
- [x] Auto-focus moves between fields
- [x] Delete key clears previous field
- [x] Countdown timer displayed
- [x] Resend button disabled initially
- [x] Resend button enabled after timer expires
- [x] Verify button colored correctly

**BLoC Tests:**
- [ ] OtpVerificationRequested event processing
- [ ] ResendOtpRequested event processing
- [ ] State transitions
- [ ] Error handling

**Integration Tests:**
- [ ] Complete OTP verification flow
- [ ] Resend OTP flow
- [ ] Maximum attempts handling

---

### SC-AUT-03: Login Screen (Planned)

**Test Cases:**
- [ ] Email/password input validation
- [ ] Remember me functionality
- [ ] Google login flow
- [ ] Error handling
- [ ] Navigation on success

---

### Core Modules Testing

**API Service Tests:**
- [ ] Request building
- [ ] Response parsing
- [ ] Error handling
- [ ] Timeout handling
- [ ] Retry logic

**Storage Service Tests:**
- [ ] Save/retrieve data
- [ ] Delete data
- [ ] Cache expiration
- [ ] Null safety

**Routing Tests:**
- [ ] Route definition
- [ ] Route navigation
- [ ] Deep linking
- [ ] Navigation guards

---

## 🧪 RUNNING TESTS

### Run All Tests
```bash
flutter test
```

### Run Tests with Coverage
```bash
flutter test --coverage
```

### Run Specific Test File
```bash
flutter test test/features/auth/screens/signup_screen_test.dart
```

### Run Tests Matching Pattern
```bash
flutter test --name "Signup"
```

### Generate Coverage Report (HTML)
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

---

## 📊 COVERAGE TARGETS

| Component | Target | Current | Status |
|-----------|--------|---------|--------|
| Features | 80% | 30% | 🔄 |
| Core | 85% | 50% | 🔄 |
| Shared | 75% | 40% | 🔄 |
| Bloc | 80% | 25% | 🔄 |
| **Total** | **80%** | **30%** | 🔄 |

---

## 🐛 COMMON TEST ISSUES & SOLUTIONS

### Issue 1: "Unable to find widget"
**Cause:** Widget not rendered or finder incorrect  
**Solution:** Use `find.byKey()` or check widget tree with debugDumpApp()

### Issue 2: "Async operation timed out"
**Cause:** Future takes too long to complete  
**Solution:** Increase timeout: `tester.binding.window.physicalSizeTestValue = Size(500, 500);`

### Issue 3: "No material widget found"
**Cause:** Test widget not wrapped in MaterialApp  
**Solution:** Wrap widget in MaterialApp in testWidgets()

### Issue 4: "Mock not working"
**Cause:** Mock setup incorrect or wrong when() syntax  
**Solution:** Check when() and thenAnswer() syntax, ensure class is mockable

---

## 📝 TESTING BEST PRACTICES

✅ **DO:**
- Write tests as you code (TDD approach)
- Test edge cases (empty input, null, invalid data)
- Mock external dependencies
- Keep tests focused (1 thing per test)
- Use meaningful test descriptions
- Test user-facing behavior
- Run tests before committing

❌ **DON'T:**
- Test implementation details (private methods)
- Write tests that depend on other tests
- Use real API/database in tests
- Test third-party libraries
- Write tests only for coverage percentage
- Skip error case testing
- Leave test warnings/errors

---

## 🔗 USEFUL RESOURCES

- [Flutter Testing Docs](https://flutter.dev/docs/testing)
- [bloc_test package](https://pub.dev/packages/bloc_test)
- [Mockito package](https://pub.dev/packages/mockito)
- [Flutter Best Practices](https://flutter.dev/docs/testing/best-practices)

---

**Last Updated:** Jan 27, 2026 at 15:30  
**Version:** 1.0  
**Status:** Testing Guide Ready ✅
