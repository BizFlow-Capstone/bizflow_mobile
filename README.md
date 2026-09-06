# bizflow_mobile

## Project Documentation

- [Setup and Mobile UI Guide](Setup%20and%20Mobile%20UI%20Guide.md)

# Flutter System Design – Instruction File

Tài liệu này dùng như **kim chỉ nam** cho toàn bộ dự án Flutter: ai vào code cũng phải theo. Không giải thích lan man, chỉ nêu **quy tắc + cấu trúc + cách dùng**.

---

## 1. Nguyên tắc bắt buộc (Rules)

### 1.1 Kiến trúc

* Feature-first (theo nghiệp vụ)
* UI dùng **composition**, không dùng inheritance
* Shared **không biết business**
* Core **không phụ thuộc feature**

❌ Không code theo màn hình
❌ Không để logic nghiệp vụ trong shared

---

## 2. Cấu trúc thư mục CHUẨN

```
lib/
├── core/                # Hạ tầng – nền móng
│   ├── theme/           # Design system
│   ├── routing/         # Điều hướng
│   ├── localization/    # Đa ngôn ngữ
│   ├── notification/    # Push / Local notify
│   ├── network/         # HTTP, interceptor
│   ├── storage/         # Secure / local storage
│   └── config/          # Remote config, feature flag
│
├── shared/              # Tái sử dụng – không business
│   ├── widgets/
│   ├── dialogs/
│   ├── utils/
│   └── extensions/
│
├── features/            # Nghiệp vụ
│   ├── auth/
│   │   ├── presentation/
│   │   ├── domain/
│   │   └── data/
│   ├── home/
│   └── profile/
│
├── app.dart             # App root
└── main.dart            # Entry point
```

---

## 3. Design System (core/theme)

### 3.1 Quy tắc

* Không hardcode màu, font, spacing
* Dùng **semantic name** (primary, danger, success)

### 3.2 Bắt buộc có

```
core/theme/
├── app_theme.dart
├── app_colors.dart
├── app_text_styles.dart
└── app_spacing.dart
```

---

## 4. Shared Widgets (shared/widgets)

### 4.1 Quy tắc

* Stateless nếu có thể
* Nhận config qua constructor
* Không import bloc / provider / api

### 4.2 Ví dụ

* AppButton
* AppTextField
* AppForm

> Shared chỉ render – không xử lý nghiệp vụ

---

## 5. Feature Module (features/*)

### 5.1 Cấu trúc chuẩn 1 feature

```
features/auth/
├── presentation/    # UI + state
│   ├── pages/
│   ├── widgets/
│   └── auth_page.dart
├── domain/          # Business rule
│   ├── entities/
│   └── usecases/
└── data/            # API / repository
    ├── auth_api.dart
    └── auth_repository.dart
```

### 5.2 Quy tắc

* Feature tự quản state
* Feature quyết định text, màu theo ngữ cảnh

---

## 6. Điều hướng (Routing)

### 6.1 Quy tắc

* Không push route string trực tiếp
* Tất cả route khai báo tập trung

```
core/routing/app_router.dart
```

### 6.2 Flow

* UI → Router
* Router → Page

---

## 7. Đa ngôn ngữ (Localization)

### 7.1 Quy tắc

* Không viết text cứng trong UI
* Shared dùng text trung tính

```
core/localization/
├── vi.json
├── en.json
└── app_localizations.dart
```

---

## 8. Thông báo (Notification)

### 8.1 Quy tắc

* Notification chỉ là trigger
* Logic xử lý nằm trong feature

```
core/notification/
├── notification_service.dart
├── fcm_handler.dart
```

---

## 9. Remote Config

### 9.1 Dùng cho

* Bật / tắt feature
* Đổi text nhỏ

❌ Không update UI phức tạp

---

## 10. State Management

### 10.1 Khuyến nghị

* Bloc hoặc Riverpod
* State đặt trong feature

❌ Không state global trừ auth / app state

---

