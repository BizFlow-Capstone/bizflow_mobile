# 📊 Auth Flow Diagram & Data Flow

## 1. User Journey Flow

```
START APP
    │
    ▼
Splash / Login Check
    │
    ├─→ Has Token? → HOME
    │
    └─→ No Token? → RegisterPage (SC-AUT-01)
         │
         ├─→ Name, Phone, Email, Password inputs
         │
         ├─→ Validate → Show Errors
         │
         ├─→ Register API
         │   ├─→ Create Account
         │   └─→ Generate OTP
         │
         └─→ VerifyOtpPage (SC-AUT-02)
              │
              ├─→ Input 6-digit OTP
              │
              ├─→ Auto-focus next field
              │
              ├─→ Countdown 60s timer
              │
              ├─→ Verify OTP API
              │
              └─→ HOME (Success)
```

---

## 2. SC-AUT-01: RegisterPage Data Flow

```
User Input
  ├─ Name
  ├─ Phone
  ├─ Email
  └─ Password (with toggle)
       │
       ▼
   Form Validation
   • Name required
   • Phone required
   • Email required
   • Password required
       │
       ├─ Invalid? → Show Error (SnackBar)
       │
       └─ Valid?
           │
           ▼
        Register API
        POST /auth/register
        {
          "name": "Nguyễn Văn A",
          "phone": "0987654321",
          "email": "user@example.com",
          "password": "SecurePass123!"
        }
           │
           ├─ Success → Navigate to VerifyOtpPage
           └─ Error → Show Error Message
```

---

## 3. SC-AUT-02: VerifyOtpPage Data Flow

```
Input: phoneNumber (from navigation)

State:
  ├─ 6 TextEditingControllers
  ├─ 6 FocusNodes
  ├─ _isLoading
  ├─ _canResend
  └─ _remainingSeconds = 60
       │
       ▼
   Timer: _startResendTimer()
       │
       ▼
   User Types OTP
       │
       ├─ _handleOtpInput()
       ├─ Auto-focus next field
       ├─ Auto-unfocus after complete
       └─ Backspace → focus previous
           │
           ▼
       Click "Xác thực OTP"
           │
           ├─ Validate: length == 6
           │
           ├─ Invalid? → Show Error
           │
           └─ Valid?
               │
               ▼
           Verify OTP API
           POST /auth/verify-otp
           {
             "phone": "0987654321",
             "otpCode": "123456"
           }
               │
               ├─ Success → Navigate to HOME
               └─ Error → Show Error
```

---

## 4. API Contracts

### Register Endpoint
```
POST /auth/register

Request:
{
  "name": "Nguyễn Văn A",
  "phone": "0987654321",
  "email": "user@example.com",
  "password": "SecurePass123!"
}

Response (200):
{
  "success": true,
  "message": "OTP sent to phone",
  "phone": "0987654321"
}

Response (400/500):
{
  "success": false,
  "message": "Email already exists",
  "code": "EMAIL_EXISTS"
}
```

### Verify OTP Endpoint
```
POST /auth/verify-otp

Request:
{
  "phone": "0987654321",
  "otpCode": "123456"
}

Response (200):
{
  "success": true,
  "message": "OTP verified",
  "token": "eyJhbGciOiJIUzI1NiIs...",
  "refreshToken": "eyJhbGciOiJIUzI1NiIs..."
}

Response (400/401):
{
  "success": false,
  "message": "Invalid OTP",
  "code": "INVALID_OTP"
}
```

### Resend OTP Endpoint
```
POST /auth/resend-otp

Request:
{
  "phone": "0987654321"
}

Response (200):
{
  "success": true,
  "message": "OTP resent",
  "expiresIn": 600
}

Response (429):
{
  "success": false,
  "message": "Too many requests",
  "code": "RATE_LIMITED",
  "retryAfter": 60
}
```

### Google Auth Endpoint
```
POST /auth/google-register

Request:
{
  "idToken": "eyJhbGciOiJSUzI1NiIs...",
  "email": "user@gmail.com",
  "name": "User Name"
}

Response (200):
{
  "success": true,
  "message": "Google signup success",
  "token": "eyJhbGciOiJIUzI1NiIs..."
}
```

---

## 5. Error Handling Strategy

```
Error Types:
├─ Input Validation Error
│  └─ Show SnackBar: "Vui lòng nhập..."
│
├─ Network Error
│  └─ Show: "Không có kết nối mạng"
│
├─ Server Error (5xx)
│  └─ Show: "Lỗi máy chủ, vui lòng thử lại"
│
├─ Client Error (4xx)
│  ├─ 400: "Dữ liệu không hợp lệ"
│  ├─ 401: "Xác thực thất bại"
│  ├─ 409: "Email đã tồn tại"
│  └─ 429: "Quá nhiều yêu cầu"
│
├─ Timeout Error
│  └─ Show: "Kết nối timeout"
│
└─ Unknown Error
   └─ Show: "Có lỗi xảy ra"
```

---

## 6. Focus Navigation Flow

```
RegisterPage:
Name → (Next) → Phone → (Next) → Email → (Next) → Password → (Done)

VerifyOtpPage:
[1] → [2] → [3] → [4] → [5] → [6] (auto-focus)
(Backspace) → go back to previous field
```

---

## 7. Timer Implementation

```
_startResendTimer():
  1. Delay 1 second
  2. Decrement _remainingSeconds--
  3. setState() → Update UI
  4. Check: if _remainingSeconds > 0 → Recurse
           else → _canResend = true (enable button)
  5. Mounted check → Prevent memory leaks
```

---

**Generated**: 26/01/2026
