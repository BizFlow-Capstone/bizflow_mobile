# 💻 Usage Examples - Auth Screens & Components

---

## 1. RegisterPage (SC-AUT-01)

### Basic Usage
```dart
import 'package:bizflow_mobile/features/auth/presentation/pages/register_page.dart';

// Navigate to RegisterPage
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const RegisterPage(),
  ),
);
```

### With Callback (Future Implementation)
```dart
// When integrated with Bloc/Provider
BlocListener<AuthBloc, AuthState>(
  listener: (context, state) {
    if (state is AuthRegisterSuccess) {
      // Navigate to VerifyOtpPage
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VerifyOtpPage(phoneNumber: state.phoneNumber),
        ),
      );
    }
  },
  child: const RegisterPage(),
);
```

### Full Example with Navigation
```dart
class LoginScreenPage extends StatelessWidget {
  const LoginScreenPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RegisterPage(),
                  ),
                );
              },
              child: const Text('Đăng ký'),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 2. VerifyOtpPage (SC-AUT-02)

### Basic Usage
```dart
import 'package:bizflow_mobile/features/auth/presentation/pages/verify_otp_page.dart';

// Navigate to VerifyOtpPage with phone number
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const VerifyOtpPage(
      phoneNumber: '0987654321',
    ),
  ),
);
```

### With Callback (Future Implementation)
```dart
BlocListener<AuthBloc, AuthState>(
  listener: (context, state) {
    if (state is AuthVerifyOtpSuccess) {
      // Navigate to Home or Profile Setup
      Navigator.of(context).pushReplacementNamed('/home');
    }
  },
  child: const VerifyOtpPage(phoneNumber: '0987654321'),
);
```

### With Dynamic Phone Number
```dart
void navigateToOtpVerification(String phoneNumber) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => VerifyOtpPage(
        phoneNumber: phoneNumber,
      ),
    ),
  );
}

// Usage:
navigateToOtpVerification('0987654321');
```

---

## 3. AppOtpInput Widget (Shared)

### Basic 6-Digit OTP
```dart
import 'package:bizflow_mobile/shared/widgets/app_otp_input.dart';

AppOtpInput(
  length: 6,
  onCompleted: (code) {
    print('OTP Code: $code');
    // Verify OTP
  },
)
```

### With onChanged Callback
```dart
AppOtpInput(
  length: 6,
  onCompleted: (code) {
    print('Completed: $code');
    // Call verify API
  },
  onChanged: (code) {
    print('Current: $code');
    // Update UI (optional)
  },
)
```

### Custom Length (4-digit PIN)
```dart
AppOtpInput(
  length: 4,
  onCompleted: (code) {
    print('PIN: $code');
  },
)
```

### In Custom Screen
```dart
class CustomOtpScreen extends StatefulWidget {
  const CustomOtpScreen({Key? key}) : super(key: key);

  @override
  State<CustomOtpScreen> createState() => _CustomOtpScreenState();
}

class _CustomOtpScreenState extends State<CustomOtpScreen> {
  late AppOtpInputState _otpInputState;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify OTP')),
      body: Column(
        children: [
          AppOtpInput(
            length: 6,
            onCompleted: (code) => _verifyOtp(code),
            onChanged: (code) => setState(() {}),
          ),
          ElevatedButton(
            onPressed: () => _otpInputState.clear(),
            child: const Text('Clear OTP'),
          ),
        ],
      ),
    );
  }

  void _verifyOtp(String code) {
    print('Verifying: $code');
    // Call API
  }
}
```

---

## 4. Integration with Routing

### Using GoRouter (Recommended)
```dart
final router = GoRouter(
  routes: [
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterPage(),
    ),
    GoRoute(
      path: '/verify-otp/:phoneNumber',
      builder: (context, state) {
        final phoneNumber = state.pathParameters['phoneNumber']!;
        return VerifyOtpPage(phoneNumber: phoneNumber);
      },
    ),
  ],
);

// Navigation:
context.go('/register');
context.go('/verify-otp/0987654321');
```

### Using GetX
```dart
// Register routes
Get.toNamed('/register');
Get.toNamed('/verify-otp/0987654321');

// Define routes
GetPage(
  name: '/register',
  page: () => const RegisterPage(),
),
GetPage(
  name: '/verify-otp/:phoneNumber',
  page: () {
    final phoneNumber = Get.parameters['phoneNumber']!;
    return VerifyOtpPage(phoneNumber: phoneNumber);
  },
),
```

### Using Navigator 2.0
```dart
class AuthRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/register':
        return MaterialPageRoute(
          builder: (_) => const RegisterPage(),
        );
      case '/verify-otp':
        final phoneNumber = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => VerifyOtpPage(phoneNumber: phoneNumber),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const NotFoundPage(),
        );
    }
  }
}
```

---

## 5. Integration with State Management

### With Bloc
```dart
// In RegisterPage
ElevatedButton(
  onPressed: () {
    context.read<AuthBloc>().add(
      RegisterEvent(
        name: _nameController.text,
        phone: _phoneController.text,
        email: _emailController.text,
        password: _passwordController.text,
      ),
    );
  },
  child: const Text('Đăng ký'),
)

// Listen to state
BlocListener<AuthBloc, AuthState>(
  listener: (context, state) {
    if (state is AuthRegisterLoading) {
      // Show loading
    } else if (state is AuthRegisterSuccess) {
      Navigator.push(context, ...VerifyOtpPage...);
    } else if (state is AuthRegisterError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.message)),
      );
    }
  },
)
```

### With Riverpod
```dart
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

// In RegisterPage
Consumer(
  builder: (context, ref, child) {
    return ElevatedButton(
      onPressed: () {
        ref.read(authProvider.notifier).register(
          name: _nameController.text,
          phone: _phoneController.text,
          email: _emailController.text,
          password: _passwordController.text,
        );
      },
      child: const Text('Đăng ký'),
    );
  },
)
```

---

## 6. API Integration

### Register API Call
```dart
Future<void> _handleRegister() async {
  try {
    setState(() => _isLoading = true);
    
    final response = await _apiClient.post(
      '/auth/register',
      data: {
        'name': _nameController.text,
        'phone': _phoneController.text,
        'email': _emailController.text,
        'password': _passwordController.text,
      },
    );
    
    if (response.statusCode == 200) {
      final phoneNumber = response.data['phone'];
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VerifyOtpPage(phoneNumber: phoneNumber),
        ),
      );
    }
  } catch (e) {
    _showError('Registration failed: $e');
  } finally {
    setState(() => _isLoading = false);
  }
}
```

### Verify OTP API Call
```dart
Future<void> _handleVerify() async {
  try {
    setState(() => _isLoading = true);
    
    final otpCode = _getOtpCode();
    
    final response = await _apiClient.post(
      '/auth/verify-otp',
      data: {
        'phone': widget.phoneNumber,
        'otpCode': otpCode,
      },
    );
    
    if (response.statusCode == 200) {
      final token = response.data['token'];
      // Save token and navigate
      Navigator.of(context).pushReplacementNamed('/home');
    }
  } catch (e) {
    _showError('Verification failed: $e');
  } finally {
    setState(() => _isLoading = false);
  }
}
```

### Resend OTP API Call
```dart
Future<void> _handleResend() async {
  try {
    await _apiClient.post(
      '/auth/resend-otp',
      data: {'phone': widget.phoneNumber},
    );
    
    _showSuccess('OTP resent successfully');
    
    // Reset timer
    setState(() {
      _canResend = false;
      _remainingSeconds = 60;
    });
    _startResendTimer();
  } catch (e) {
    _showError('Failed to resend OTP: $e');
  }
}
```

---

## 7. Custom Styling

### Override Colors
```dart
// In AppColors
static const Color customTeal = Color(0xFF23C4C1);

// Use in widgets
AppButton(
  label: 'Đăng ký',
  type: AppButtonType.primary,
  // Colors automatically use customTeal from AppColors
)
```

### Custom Spacing
```dart
// Use AppSpacing constants
Padding(
  padding: const EdgeInsets.symmetric(
    horizontal: AppSpacing.md,
    vertical: AppSpacing.lg,
  ),
  child: AppButton(label: 'Đăng ký'),
)
```

---

## 8. Error Handling

### Show SnackBar Error
```dart
void _showError(String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: AppColors.danger,
      duration: const Duration(seconds: 3),
    ),
  );
}
```

### Show Dialog Error
```dart
void _showErrorDialog(String message) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Error'),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}
```

---

## 9. Testing Usage

### Test RegisterPage
```dart
testWidgets('Register with valid data', (WidgetTester tester) async {
  await tester.pumpWidget(const MyApp());
  
  // Navigate to RegisterPage
  await tester.tap(find.byText('Đăng ký'));
  await tester.pumpAndSettle();
  
  // Fill form
  await tester.enterText(
    find.byType(AppTextField).at(0),
    'Nguyễn Văn A',
  );
  
  // ... fill other fields
  
  // Submit
  await tester.tap(find.byType(AppButton));
  await tester.pumpAndSettle();
  
  // Verify
  expect(find.byType(VerifyOtpPage), findsOneWidget);
});
```

### Test VerifyOtpPage
```dart
testWidgets('Verify OTP with 6 digits', (WidgetTester tester) async {
  await tester.pumpWidget(
    const MaterialApp(
      home: VerifyOtpPage(phoneNumber: '0987654321'),
    ),
  );
  
  // Enter OTP
  for (int i = 0; i < 6; i++) {
    await tester.enterText(find.byType(TextField).at(i), '1');
  }
  
  // Submit
  await tester.tap(find.byType(AppButton));
  await tester.pumpAndSettle();
  
  // Verify navigation
  expect(find.byType(HomeScreen), findsOneWidget);
});
```

---

**Last Updated**: 26/01/2026  
**Status**: ✅ Ready for Use
