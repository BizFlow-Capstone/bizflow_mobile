# bizflow_mobile

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

## 11. Quy ước code

* File name: snake_case
* Widget: PascalCase
* 1 file ≤ 300 dòng
* 1 widget = 1 trách nhiệm

---

## 12. Checklist khi tạo feature mới

* [ ] Có folder feature riêng
* [ ] Không dùng widget từ feature khác
* [ ] Chỉ dùng shared / core
* [ ] Text dùng localization
* [ ] Màu từ design system

---

## 13. Câu chốt cuối

> **Không phá kiến trúc để code nhanh**

Tài liệu này dùng để:

* Onboard dev mới
* Review code
* Giữ app không nát khi scale

---

## 📊 REPORT & PROGRESS TRACKING (Bắt buộc đọc!)

### 📁 Vị trí Folder Report
```
bizflow_mobile/report/
├── 01_SYSTEM_ARCHITECTURE.md      (Thiết kế hệ thống)
├── INDEX.md                       (Hướng dẫn điều hướng)
├── TEMPLATE.md                    (Template cho reports)
├── CHANGELOG.md                   (Theo dõi tất cả thay đổi)
├── 03_PHASE_REPORTS/              (Tiến độ các phase)
├── 04_MODULE_REPORTS/             (Chi tiết các module)
├── 05_FEATURE_REPORTS/            (Trạng thái các tính năng)
├── 06_TESTING_REPORTS/            (Phạm vi kiểm thử)
├── 07_PERFORMANCE_REPORTS/        (Thước đo hiệu năng)
└── 08_ARCHIVE/                    (Các reports cũ)
```

### 🎯 TẠI SAO CẦN REPORTS?

Reports giúp bạn:
- ✅ Theo dõi tiến độ dự án
- ✅ Hiểu công việc đã hoàn thành
- ✅ Debug nhanh hơn (biết ai làm gì và tại sao)
- ✅ Onboard developers mới
- ✅ Duy trì kiến thức
- ✅ Theo dõi lịch sử dự án

### 📋 KHI NÀO TẠO REPORT

**Tạo report mới sau khi hoàn thành:**

1. **Một Phase** (ví dụ: phase State Management)
   - File: `report/03_PHASE_REPORTS/PHASE_[N]_[NAME].md`
   - Khi nào: Sau khi phase hoàn tất
   - Nội dung: Cái gì được implement, thống kê, vấn đề, bước tiếp theo

2. **Một Module** (ví dụ: Core Network module)
   - File: `report/04_MODULE_REPORTS/MODULE_[NAME].md`
   - Khi nào: Sau khi module được implement hoàn chỉnh
   - Nội dung: Chi tiết module, files được tạo, trạng thái kiểm thử

3. **Một Tính năng** (ví dụ: Auth feature)
   - File: `report/05_FEATURE_REPORTS/FEATURE_[NAME].md`
   - Khi nào: Sau khi tính năng hoàn thành và được kiểm thử
   - Nội dung: Tổng quan tính năng, màn hình, tích hợp API, kiểm thử

4. **Milestone Kiểm thử** (ví dụ: đạt được 80% coverage)
   - File: `report/06_TESTING_REPORTS/TEST_[NAME].md`
   - Khi nào: Sau khi milestone kiểm thử được đạt
   - Nội dung: Phạm vi kiểm thử, kết quả, vấn đề tìm được

5. **Tối ưu Hiệu năng**
   - File: `report/07_PERFORMANCE_REPORTS/[NAME].md`
   - Khi nào: Sau khi tối ưu hiệu năng
   - Nội dung: Thước đo hiệu năng, trước/sau, cải tiến

### 📝 CÁCH TẠO REPORT

#### Bước 1: Mở Template
```
Mở report/TEMPLATE.md
Copy toàn bộ nội dung vào file mới
Lưu trong folder thích hợp
```

#### Bước 2: Điền thông tin
```
- Thay đổi tiêu đề cho module/phase/tính năng của bạn
- Điền "Ngày hoàn thành"
- Điền section "Tóm tắt"
- Điền "Thống kê" với con số thực tế
- Thêm danh sách "Files thay đổi"
- Thêm kết quả "Kiểm thử"
- Thêm section "Vấn đề"
- Định nghĩa "Bước tiếp theo"
```

#### Bước 3: Cập nhật Tracking Files
```
Cập nhật report/CHANGELOG.md:
  - Thêm entry mới
  - Liệt kê cái gì được hoàn thành
  - Cập nhật progress bar
  
Cập nhật report/INDEX.md:
  - Thêm link tới report mới
  - Đánh dấu ✅ là hoàn thành
```

#### Bước 4: Xin phê duyệt
```
Code review ✅
Kiểm thử hoàn thành ✅
Tài liệu đầy đủ ✅
Report sẵn sàng gửi ✅
```

### 📊 CÁC SECTION TEMPLATE REPORT

Mỗi report nên có:

```
1. TÓM TẮT NHANH
   - Cái gì được làm
   - Trạng thái (Hoàn thành/Đang tiến hành)
   - Thời lượng

2. THỐNG KÊ
   - Files được tạo/sửa
   - Dòng code
   - Phạm vi kiểm thử
   - Thời gian dành

3. MÔ TẢ CHI TIẾT
   - Thiết kế/kiến trúc
   - Chi tiết implement
   - Mẫu code

4. KIỂM THỬ
   - Kết quả kiểm thử
   - Tỷ lệ %
   - Vấn đề đã biết

5. VẤN ĐỀ GẶP PHẢI
   - Vấn đề đối mặt
   - Cách giải quyết
   - Cách ngăn chặn lần sau

6. FILES THAY ĐỔI
   - Danh sách tất cả files (new/modified/deleted)
   - Giải thích ngắn gọn

7. BƯỚC TIẾP THEO
   - Cái gì tiếp theo
   - Items bị block
   - Dependencies
```

### 🔍 CÁI GÌ NÊN BỎ VÀO REPORT

#### Ví dụ section Thống kê
```
Files Code Được Tạo:    5 files
Dòng Code Viết:         250 LOC
Classes Implement:      3
Methods Thêm:           12
Test Cases Thêm:        8
Phạm vi Kiểm thử:       75%
Thời gian Dành:         4 giờ
```

#### Ví dụ Files Thay đổi
```
✨ lib/core/network/api_client.dart         (150 dòng)
✨ lib/core/network/interceptor.dart        (80 dòng)
🔄 lib/core/network/api_endpoints.dart      (+20 dòng)
📝 report/04_MODULE_REPORTS/MODULE_NETWORK.md

Giải thích:
- Tạo API client với đầy đủ logic interceptor
- Thêm cơ chế refresh token
- Tạo interceptor để xử lý lỗi
- Thêm các loại lỗi toàn diện
```

#### Ví dụ section Vấn đề
```
Vấn đề 1: Token Refresh Loop
- Vấn đề: Token refresh được trigger nhiều lần
- Nguyên nhân: Không kiểm tra nếu refresh đã đang thực hiện
- Giải pháp: Thêm flag để ngăn chặn refresh đồng thời
- Ảnh hưởng Thời gian: 30 phút debug
- Ngăn chặn: Thêm các pattern flag tương tự ở nơi khác

Vấn đề 2: Hiệu năng với Danh sách Lớn
- Vấn đề: FPS giảm xuống 15 với 1000+ items
- Nguyên nhân: Rebuild toàn bộ danh sách khi thay đổi
- Giải pháp: Implement pagination + lazy loading
- Ảnh hưởng Thời gian: 1 giờ tối ưu
- Ngăn chặn: Dùng pagination từ đầu cho dữ liệu lớn
```

### 📎 CHECKLIST REPORT

Trước khi gửi report:
- [ ] File đặt tên đúng: `[PREFIX]_[NAME].md`
- [ ] Tất cả sections được điền
- [ ] Thống kê chính xác
- [ ] Danh sách files hoàn chỉnh
- [ ] Trạng thái được đánh dấu rõ (✅/⏳/❌)
- [ ] Bước tiếp theo được định nghĩa
- [ ] Vấn đề được ghi chép
- [ ] Thời gian dành được ghi lại
- [ ] CHANGELOG.md được cập nhật
- [ ] INDEX.md được cập nhật
- [ ] Kiểm tra lại lỗi chính tả

### 🎓 VÍ DỤ REPORT NHANH

#### Phase Report
```markdown
# 📊 PHASE 2 - REPORT STATE MANAGEMENT

**Ngày hoàn thành:** 02/02/2026
**Thời lượng:** 5 ngày
**Trạng thái:** ✅ Hoàn thành

## Tóm tắt
Thành công tích hợp state management Bloc.

## Thống kê
- Files Được Tạo: 15
- Dòng code: 1,200
- Phạm vi Kiểm thử: 85%
- Thời gian: 40 giờ

## Files Được Tạo
✨ features/auth/bloc/auth_bloc.dart
✨ features/auth/bloc/auth_event.dart
✨ features/auth/bloc/auth_state.dart
...

## Bước Tiếp Theo
- Phase 3: Implement tính năng
```

### 💡 TIPS CHÍNH

1. **Cụ thể hóa** - Bao gồm con số và chi tiết
2. **Ghi chép Vấn đề** - Cách giải quyết + ngăn chặn
3. **Bước Tiếp Theo Rõ ràng** - Cái gì, ai, khi nào
4. **Cập nhật Thường xuyên** - Rà soát hàng tháng + cập nhật CHANGELOG.md
5. **Lưu trữ Cũ** - Di chuyển reports cũ tới 08_ARCHIVE/

### 📚 TÀI LIỆU LIÊN QUAN

- [Kiến trúc Hệ thống](report/01_SYSTEM_ARCHITECTURE.md)
- [Report Index](report/INDEX.md)
- [Report Template](report/TEMPLATE.md)
- [Changelog](report/CHANGELOG.md)

---

