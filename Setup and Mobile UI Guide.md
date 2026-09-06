# BizFlow Project Setup and Mobile UI Guide

This document contains setup and run instructions for the complete BizFlow project, followed by the mobile application UI descriptions and screenshots.

## 1. Prerequisites

- Git
- Node.js 18 or newer and npm
- Flutter SDK and Android Studio
- Android SDK/API 36 and an Android emulator or physical device
- Docker Desktop

## 2. Project Repositories

- Web application: [BizFlow web application](https://github.com/BizFlow-Capstone/bizflow-web)
- Mobile application: [BizFlow mobile application](https://github.com/BizFlow-Capstone/bizflow_mobile)
- Backend: [BizFlow backend](https://github.com/BizFlow-Capstone/BizFlow-BE-Service)
- AI service: [BizFlow AI service](https://github.com/BizFlow-Capstone/BizFlow-AI-Service)

## 3. Setup and Run the Complete Project

### 3.1 Backend and AI services

1. Install and start Docker Desktop.
2. Configure the database, Firebase, Stripe, Cloudinary, and AI provider variables required by the repositories.
3. Start the backend and AI containers. The report references these image tags:

```bash
docker run -d --name bizflow-api -p 8080:8080 thienlm30/capstone:api
docker run -d --name bizflow-ai thienlm30/capstone:ai
```

4. Verify the backend at [http://localhost:8080/swagger/index.html](http://localhost:8080/swagger/index.html).

### 3.2 Web application

1. Clone the web repository and open it in VS Code.
2. Create `.env.local` with the variables required by the web repository.
3. Install dependencies and start the development server:

```bash
npm install
npm run dev
```

4. Open [http://localhost:3000](http://localhost:3000).
5. Set the web API base URL to `http://localhost:8080`.

### 3.3 Mobile application

1. Install Flutter, Android Studio, Android SDK/API 36, and Git.
2. Clone the mobile repository and open it in Android Studio or VS Code.
3. Configure the environment files and place `google-services.json` in `android/app/` when Firebase is enabled.
4. Check the device or emulator:

```bash
flutter doctor
flutter devices
```

5. Install packages and run the application:

```bash
flutter pub get
flutter run
```

6. On an Android emulator, use `10.0.2.2` instead of `localhost` for the backend host.

### 3.4 Recommended startup order

Start the database/backend, AI service, web application, and mobile application in that order. Verify Swagger and authentication before testing orders, accounting, OCR, voice input, or other AI features.

## 4. Mobile Application UI
### 4.1 Mobile Application (for Owner and Employee)

#### 3.2.1 User Register
- **Function Trigger:** Navigated to from the **User Login** screen by tapping the "Đăng ký" link.
- **Function Description:** Allows new users to create a BizFlow account. The actor is an unauthenticated visitor. The user provides required credentials (name, phone, password) and tax code. On success the system sends a verification OTP before activating the account.

 

**◆ Create a new account**
- Input fields: full name (required), email or Vietnamese phone number (required), password (required, min 6 characters), tax code.
- Tapping "Đăng Ký" submits the form.
- Inline validation errors are shown below each field on submit.
- On success: system dispatches a verification OTP → navigate to **OTP Verify** screen.
- On failure: error Snackbar displayed.

**◆  OTP Verify**
- Input fields: OTP number.
- Tapping "Xác thực" submits the form.
- Inline validation errors are shown below each field on submit.
- On success: navigate to the home screen.
- On failure: error Snackbar displayed.

 

 ![](Setup%20and%20Mobile%20UI%20Guide-images/image014.png) 

###### Figure 3.2.1.1: Register screen

 

#### 3.2.2 User Login
- **Function Trigger:** Displayed automatically from the Splash Page when no authenticated session is found, or navigated to from the Register / OTP Verify screens.
- **Function Description:** Allows registered users to authenticate using email/phone + password, or via Google OAuth. On success the system routes the user to the **Home Screen**. The Splash Page auto-directs authenticated users directly to Home, bypassing this screen.

**◆ Sign in with Email / Phone**
- Users enter email or Vietnamese phone number + password.
- Input format validated (email regex / phone regex) before submit.
- "Remember Me" checkbox persists the login session across app restarts.
- On success: navigate to **Home Screen**.
- On failure (wrong credentials, unverified account, network error): error Snackbar displayed.

 **◆ Sign in with Google**
- Tapping "Đăng nhập bằng Google" initiates Google OAuth flow.
- If no phone number is linked to the Google account (first-time): navigate to a phone-linking step.
- If no password is set on the account (first-time): navigate to **Reset Password** screen to set one.
- On success: navigate to **Home Screen**.

 

**◆ Navigate to Forgot Password**
- Tapping "Quên mật khẩu?" link navigates to the **Forgot Password** screen.

 

**◆ Navigate to Register**
- Tapping "Đăng ký" link at the bottom navigates to the **User Register** screen.

![](Setup%20and%20Mobile%20UI%20Guide-images/image015.png)

###### Figure 3.2.2.1: Login screen

 

 

 

#### 3.2.3 Reset Password
- **Function Trigger:** Navigated to automatically after:
  - Successful OTP verification in the **Forgot Password** flow.
  - First-time Google sign-in when the account has no password set.
- **Function Description:** Allows users to set a new password. Serves two sub-flows: (1) post-Forgot-Password OTP recovery, and (2) first-time Google sign-in password setup. Validates minimum length and field matching before submission.

 **◆ Enter new password**
- Two password input fields: "Mật khẩu mới" and "Xác nhận mật khẩu", each with a show/hide toggle.
- Validation rules: minimum 6 characters; both fields must match.
- Inline error messages shown per rule violation.

 **◆ Confirm Reset**
- Tapping "Đặt lại mật khẩu" / "Xác nhận" submits the new password.
- On success (Forgot Password flow): navigate to **User Login** with a success Snackbar.
- On success (Google first-time flow): navigate to **Home Screen**.
- On failure: error message displayed; form remains editable.

 

![](Setup%20and%20Mobile%20UI%20Guide-images/image016.png)

###### Figure 3.2.3.1: Set new password screen

 

#### 3.2.4 Forgot Password
- **Function Trigger:** Navigated to from the **User Login** screen by tapping "Quên mật khẩu?".
- **Function Description:** Allows users to recover account access by submitting their registered email or phone. The system dispatches an OTP or reset link; the user then proceeds to OTP verification before resetting their password.

**◆ Request Password Reset**
- Input field for registered email or Vietnamese phone number.
- Format validated (email regex / phone regex) before submit.
- Tapping "Gửi yêu cầu" submits the request.
- On success: system dispatches OTP → navigate to **OTP Verify** screen (Forgot Password context).
- On failure (unregistered contact, network error): error Snackbar displayed.

 ![](Setup%20and%20Mobile%20UI%20Guide-images/image017.png)

###### Figure 3.2.4.1 Forgot password screen

 

 

#### 3.2.5 OTP Verify
- **Function Trigger:** Navigated to automatically after:
  - Successful registration (account email/phone verification).
  - Forgot Password request submission.
  - Phone number linking (from Profile or Google phone-link flow).
- **Function Description:** Handles 6-digit one-time password verification for multiple authentication flows. Post-verification navigation differs per triggering context: registration → Home Screen; Forgot Password → Reset Password; Phone link → back to Profile.

**◆ Enter OTP Code**
- 6-digit OTP input (auto-advances per digit entered).
- The system validates the OTP against the backend upon completion.
- On success (registration): account verified → navigate to **Home Screen**.
- On success (Forgot Password): navigate to **Reset Password** screen.
- On success (phone-link): phone credential linked → navigate back to calling screen.
- On failure: error message shown below input; field cleared for retry.

 **◆ Resend OTP**
- "Gửi lại mã" button initially disabled; activates after a countdown timer (e.g., 60 seconds) expires.
- Tapping requests a fresh OTP from the backend; timer resets.
- Backend may enforce a maximum resend limit; error shown if exceeded.

 

 ![](Setup%20and%20Mobile%20UI%20Guide-images/image018.png)

###### Figure 3.2.5.1: OTP verify screen

 

#### 3.2.6 Home Screen
- **Function Trigger:** Displayed automatically after successful login. The Splash Page redirects here when an existing authenticated session is detected.
- **Function Description:** Main dashboard showing the currently selected business location context and quick-access entry points to all major modules. Owner sees all modules; Employee sees a role-limited view.

**◆ Display Current Business Location**
- Active location name shown at the top with a storefront icon.
- On first load: if the user owns locations, the first active one is auto-selected.
- Show dashboard summary following by day, week, month.
- If no locations exist: redirect to **Create a New Location**.

 **◆ Quick Actions**
- Four shortcut buttons:
  - "Tạo Đơn" → **Create Order Screen**.
  - "Đơn Hàng" → **Order List**.
  - "Công Nợ" → **Debt Customer List**.
  - "Báo Cáo" → **Accounting Management**.
- If no location is selected, tapping location-dependent actions shows a warning Snackbar.

**◆ Premium Upgrade Banner**
- Shown for free-tier users only.
- Tapping navigates to **Subscription**.

 **◆ Management Cards**
- Three tabs:
  - "Sản phẩm" → **Product List** for current location.
  - "Địa điểm" → **Business Location List**.
  - "Nhân viên" → **Employee List**.
- If no location is selected, tapping "Sản phẩm" or "Nhân viên" shows a warning Snackbar.

 

 ![](Setup%20and%20Mobile%20UI%20Guide-images/image019.png)       ![](Setup%20and%20Mobile%20UI%20Guide-images/image020.png) 

###### Figure 3.2.6.1: Home screen version Vietnamese

![](Setup%20and%20Mobile%20UI%20Guide-images/image021.png)         ![](Setup%20and%20Mobile%20UI%20Guide-images/image022.png) 

###### Figure 3.2.6.2: Home screen version English

 

#### 3.2.7 User Profile
- **Function Trigger:** Accessed from the Sidebar menu by tapping the user's name/avatar.
- **Function Description:** Displays the user's personal information and allows linking additional authentication credentials (Google, Email, Phone) to the account. Credential linking enables multi-method login and account recovery.

 

**◆ View Profile Info**
- Displays: initials-based avatar and full name.

**◆ Link Google Account**
- "Liên kết ngay" button shown next to the Google row if not yet linked.
- Tapping initiates Google OAuth linking flow.
- On success: row updates to display the linked Google account email.

**◆ Link Phone Number**
- Tapping "Liên kết ngay" next to the Phone row opens a bottom sheet with a phone input field.
- System sends OTP to the entered number → 6-digit OTP bottom sheet appears.
- On successful OTP verification: phone credential is linked.

**◆ Delete account**
- Tapping "Xóa tài khoản" to open dialog.
- Input fields for password, confirm password and  DELETE ACCOUNT  word.
- On success: navigate to login screen and delete account.
- On failure: error Snackbar displayed.

 

 ![](Setup%20and%20Mobile%20UI%20Guide-images/image023.png)

###### Figure 3.2.7.1: Profile screen

 

#### 3.2.8 Notification
- **Function Trigger:** Accessed from the notification bell icon in the AppBar (available on all main screens).
- **Function Description:** Lists all system notifications for the user: order confirmations, payment receipts, low-stock alerts, import completions. Unread notifications are visually differentiated. Role: any authenticated user.

 **◆ View Notifications**
- Scrollable list: icon (color-coded by type), title, body preview, relative timestamp.
- Unread notifications highlighted with a blue dot badge.
- Pull-to-refresh reloads the list.

**◆ Mark All as Read**
- "Đ nh dấu tất cả đ  đọc" button (shown only when unread notifications exist).
- Tapping marks all as read and removes blue dot badges.

 **◆ Tap to View Detail**
- Tapping any notification card marks it as read and navigates to **Notification Details**.

 ![](Setup%20and%20Mobile%20UI%20Guide-images/image024.png)

###### Figure 3.2.8.1: Notification screen

 

 

#### 3.2.9 Notification Details
- **Function Trigger:** Navigated to when the user taps a notification card on the **Notification** screen.
- **Function Description:** Displays the full content of a single notification: large colored icon, bold title, relative timestamp, and complete body text. Provides back navigation.

 

 **◆ View Notification Content**
- Large icon (color matches type: green = success, orange = warnings, red = alerts).
- Bold notification title and relative timestamp (e.g., "2 giờ trước").
- Full notification body text in a card with comfortable line spacing.

**◆ Navigate Back**
- Back arrow in AppBar returns to the **Notification** list.

 ![](Setup%20and%20Mobile%20UI%20Guide-images/image025.png)

###### Figure 3.29.1: Notification detail screen

 

 

#### 3.2.10 Order Management
- **Function Trigger:** Accessed from the "Đơn Hàng" quick action on the **Home Screen** or from the Sidebar.
- **Function Description:** Entry hub for all order-related operations. Provides navigation to the Order List and the Create Order flow. Role: Owner and Employee with role-based action restrictions.

 

**◆ Navigate to Order List**
- Displays the full order list for the current business location.

 

**◆ Navigate to Create Order**
- FAB "+" navigates to the **Create Order Screen**.

 

 

 

#### 3.2.11 Order List
- **Function Trigger:** Navigated to from the **Order Management** entry or the Home Screen "Đơn Hàng" quick action.
- **Function Description:** Displays all orders (Draft, Published, Cancelled, Completed) for the user's business location with filtering, search, and management capabilities. Pull-to-refresh and infinite scroll supported.

 

**◆ View Order List**
- Scrollable list of order cards: order ID, status badge, location name, total amount, creation date.
- Draft orders loaded by default.
- Pull-to-refresh reloads; infinite scroll loads more on scroll-to-bottom.

 

**◆ Filter Orders**
- Filter icon in AppBar opens a bottom sheet: filter by Status (Draft / Published / Cancelled / Completed) and Business Location.
- Active filter count badge shown on the icon.

 

**◆ Create New Order**
- FAB "+" navigates to **Create Order Screen**.

 

**◆ Publish Order**
- "Duyệt đơn" button on Draft order cards (Owner only).
- Confirmation dialog shown before publishing.
- On confirm: order moves Draft → Published.

 

**◆ Cancel Order**
- "Hủy" button on applicable order cards (Owner only).
- Confirmation dialog with optional cancellation reason.
- On confirm: order status set to Cancelled.

 ![](Setup%20and%20Mobile%20UI%20Guide-images/image026.png)

###### Figure 3.2.11.1: Order list screen

 

 

#### 3.2.12 Order Detail
- **Function Trigger:** Navigated to by tapping an order card on the **Order List**.
- **Function Description:** Full detail view of a single order: all line items, customer info, business location, payment method, status, and timestamps. Owner-only action buttons vary by the order's current status.

 

**◆ View Order Summary**
- Order ID, order code, status badge, business location name.
- Customer name and phone (or "Walk-in customer" if no profile).
- Creation and last-update timestamps; total amount.

 

**◆ View Order Line Items**
- Table: product name, quantity, unit price, line total.

 

**◆ Download Invoice**
- Download PDF order invoice.

 ![](Setup%20and%20Mobile%20UI%20Guide-images/image027.png)

###### Figure 3.2.12.1: Order detail screen

 

 

#### 3.2.13 Update Order
- **Function Trigger:** Navigated to from the **Order Detail** screen, or from the **Order Completion Confirmation** screen via the "Sửa đơn" button.
- **Function Description:** Allows editing an existing order's products, quantities, customer information, and payment method before final completion. Form is identical to **Create Manually** but pre-populated with existing order data.

 

**◆ Edit Line Items**
- Add, remove, or adjust quantities.
- Product search bar and barcode scanner available to add products.
- Minimum of 1 product required.

 

**◆ Edit Customer Information**
- Modify customer name/phone or switch between Walk-in and existing debtor.

 

**◆ Edit Order Notes**
- Update the memo/notes field.

 

**◆ Save Changes**
- "Lưu" / "Xác nhận" saves the updated order.
- On success: navigate back to **Order List** or proceed to payment flow.
- On failure: validation errors displayed.

 ![](Setup%20and%20Mobile%20UI%20Guide-images/image028.png)        ![](Setup%20and%20Mobile%20UI%20Guide-images/image029.png) 

###### Figure 3.2.13.1: Update order screen

 

 

#### 3.2.14 Create Order Screen
- **Function Trigger:** Accessed from the "Tạo Đơn" quick action on the **Home Screen** or the FAB "+" on the **Order List**.
- **Function Description:** Entry screen for creating a new order. Presents two creation methods: Manual entry and AI-assisted (Voice or Audio Upload). Role: Owner and Employee.

 

**◆ Create Manually**
- Tapping "Nhập thủ công" card navigates to the **Create Manually** screen.

 

**◆ Create via Voice Recording**
- Tapping "Đặt hàng bằng giọng nói" navigates to the voice recording screen.
- After AI processing, navigates to **Draft Order AI Screen** with parsed items.

 

**◆ Create via Audio Upload**
- Tapping "Tải lên file âm thanh" navigates to the audio upload screen.
- After AI processing, navigates to **Draft Order AI Screen** with parsed items.

 ![](Setup%20and%20Mobile%20UI%20Guide-images/image030.png)

###### Figure 3.2.14.1: Create order screen

 

 

#### 3.2.15 Create Manually
- **Function Trigger:** Navigated to from the **Create Order Screen** (manual option) or pre-populated from the **Draft Order AI Screen** after AI review.
- **Function Description:** A two-phase order form: (1) Product Selection   search and add products; (2) Review & Customer Info   review items, enter customer info, add notes, proceed to payment. Role: Owner and Employee.

 

**◆ Search and Add Products**
- Search bar filters products by name or barcode in real-time.
- Barcode scanner icon opens camera; matched product added instantly.
- Tapping a product adds it with a quantity stepper (+/−). Minimum quantity: 1.

 

**◆ Review Order Line Items**
- List of added products with quantities, unit prices, subtotals, and overall total at the bottom.

 

**◆ Enter Customer Information**
- Walk-in: name and phone entered manually (optional).
- Existing debtor: debtor picker opens to choose from Debt Customer List.
- "Tạo profile" opens **Create New Regular Customer** form (subscription-limited; quota checked before opening).
- AI-parsed customer name is auto-matched against the debtor list via fuzzy matching.

 

**◆ Add Order Notes**
- Optional notes/memo text field.

 

**◆ Proceed to Payment**
- "Tiếp theo" / "Thanh toán" validates form (at least 1 product required) and navigates to the **Order Payment** sub-flow screens.

 ![](Setup%20and%20Mobile%20UI%20Guide-images/image031.png)

###### Figure 3.2.15.1: Select product

![](Setup%20and%20Mobile%20UI%20Guide-images/image032.png)

###### Figure 3.2.15.2: Select payment method

![](Setup%20and%20Mobile%20UI%20Guide-images/image033.png)

###### Figure 3.2.15.3: Order processing

![](Setup%20and%20Mobile%20UI%20Guide-images/image034.png)

###### Figure 3.2.15.4: Preview invoice

 

 

#### 3.2.16 Draft Order AI Screen
- **Function Trigger:** Navigated to automatically after the AI service returns a parsed result from the voice recording or audio upload flow.
- **Function Description:** Presents AI-extracted order items for review and correction before confirming. Unmatched products are visually highlighted. Users can edit, delete, and add items freely before proceeding.

 

**◆ View AI-Parsed Items**
- List of extracted items: product name (matched / unmatched), quantity, unit price.
- Unmatched / low-confidence items flagged with a warning icon or highlighted border.

 

**◆ Edit Parsed Items**
- Editable quantity and price fields per row.
- Delete icon removes that item from the draft.

 

**◆ Add Missing Products**
- "Thêm sản phẩm" button opens a product search picker to add items the AI missed.

 

**◆ Confirm and Continue**
- "Xác nhận" / "Tiếp tục" passes the reviewed items to the **Create Manually** screen in review mode.

 

**◆ Discard and Retry**
- Back arrow or "Làm lại" discards the AI result and returns to the recording/upload screen.

 

 

 

#### 3.2.17 Completed Order
- **Function Trigger:** Navigated to automatically after successful order payment confirmation.
- **Function Description:** Confirmation screen displaying the finalized order summary after successful creation. Provides options to view/share the invoice or return to the order list. Role: Owner and Employee.

 

**◆ View Success Summary**
- Green checkmark icon and "Thanh toán thành công" title.
- Summary card: total amount, order ID/code, business location name, customer name and phone.

 

**◆ View / Share Invoice**
- "Xem hóa đơn" navigates to the **Order Invoice Preview** screen where the PDF can be shared or downloaded.

 

**◆ Return to Order List**
- "Về danh sách đơn hàng" navigates back to **Order List**, clearing intermediate screens from the stack.

 

 

 

#### 3.2.18 Debt Order
- **Function Trigger:** Navigated to from the **Create Manually** / payment flow when the selected payment method includes "Công nợ" (Debt).
- **Function Description:** Handles recording an order as debt (full or partial) against the selected debtor. Shows the order total, debtor info, and a credit limit warning if the new debt would exceed the debtor's configured limit.

 

**◆ Select Debt Type**
- "Toàn bộ công nợ" (Full Debt): entire amount recorded as debt, no upfront payment.
- "Một phần" (Partial): reveals an upfront payment amount field.

 

**◆ Enter Amount Paid (Partial mode)**
- Numeric input for "Số tiền trả ngay."
- Remaining debt calculated in real-time (total − amount paid).
- Validation: amount paid must be between 0 and total.

 

**◆ Select Payment Method for Partial Payment**
- Cash or bank transfer selector for the upfront portion.

 

**◆ Credit Limit Warning**
- If new debt exceeds the debtor's credit limit, a warning banner is displayed.
- User can still confirm; warning is logged.

 

**◆ Add Notes**
- Optional memo/notes field.

 

**◆ Confirm Debt**
- "Xác nhận" submits.
- Full Debt: displays debt summary confirmation.
- Partial with immediate payment: navigates to **Completed Order**.

 

 

 

#### 3.2.19 Debt Management
- **Function Trigger:** Accessed from the "Công Nợ" quick action on the **Home Screen** or from the Sidebar.
- **Function Description:** Entry point for Debt Management. Shows an overall debt summary for the business and provides navigation to the Debt Customer List.

 

**◆ Navigate to Debt Customer List**
- Tapping navigates to the **Debt Customer List**.

 

**◆ View Total Debt Summary**
- Two summary cards: total outstanding debt (VND) and total number of active debtors.

 

 

 

#### 3.2.20 Debt Customer List
- **Function Trigger:** Navigated to from the **Debt Management** entry screen.
- **Function Description:** Lists all registered debtors for the business. Supports search, status filtering, debtor creation, editing, debt adjustment, status toggle, and deletion. Each card is expandable to reveal action buttons.

 

**◆ View Debtor List**
- Scrollable list of debtor cards: name, phone, outstanding balance, status badge, location name.
- Tapping a card expands it to reveal action buttons and additional info (address, notes).

 

**◆ Search Debtors**
- Search bar filters by name or phone on Enter / submit.

 

**◆ Filter Debtors**
- Filter icon with active-count badge opens a bottom sheet.
- Filter options: Status (All / Active / Inactive); Business Location (shown if user has > 1 location).

 

**◆ Add New Debtor**
- FAB "+" or person\_add icon in AppBar opens a quick **Add Debtor bottom sheet** (name, phone, address, notes).

 

**◆ View Debtor Detail**
- "Xem chi tiết" in expanded card navigates to **Profile Detail & Debt History**.

 

**◆ Adjust Debt**
- "Điều chỉnh công nợ" in expanded card navigates to **Record Debt Collection**.

 

**◆ Edit Debtor**
- "Sửa" opens the edit form pre-filled with the debtor's data.

 

**◆ Toggle Debtor Status**
- "Vô hiệu hóa" / "kích hoạt" deactivates or reactivates the debtor record.

 

**◆ Delete Debtor**
- "Xóa" shows a confirmation dialog; on confirm the record is permanently deleted.

 ![](Setup%20and%20Mobile%20UI%20Guide-images/image035.png)

###### Figure 3.2.20.1: Debt list screen

 

 

#### 3.2.21 Create New Regular Customer
- **Function Trigger:** Navigated to from the **Debt Customer List** or from **Create Manually** when user taps "Tạo profile"
- **Function Description:** Full-page form to register a new debtor with extended contact details and an optional credit limit. More comprehensive than the quick "Add Debtor" bottom sheet available from the list.

 

**◆ Enter Customer Information**
- Required: full name, phone number.
- Optional: address, email, notes/memo.
- Inline validation errors shown on submission.

 

**◆ Set Credit Limit**
- Optional "Hạn mức tín dụng" numeric field.
- If set, the system warns when a new order would cause the debtor to exceed this limit.

 

**◆ Save Customer**
- "Lưu" / "Xác nhận" creates the debtor record.
- On success: Snackbar shown; navigate back to the previous screen with the new customer pre-selected (if called from **Create Manually**).
- On failure: error Snackbar displayed.

 ![](Setup%20and%20Mobile%20UI%20Guide-images/image036.png)

###### Figure 3.2.21.1: Create debt

 

 

#### 3.2.22 Debt Profile Detail
- **Function Trigger:** Navigated to from the **Debt Customer List** ("Xem chi tiết" button) or from the order debt confirmation flow.
- **Function Description:** Comprehensive view of a specific debtor: contact info, current outstanding balance, credit limit, and a chronological list of all debt transactions. Provides debt payment recording.

 

**◆ View Debtor Profile**
- Name, phone, address, notes.
- Current outstanding balance highlighted in a prominent card.
- Credit limit (if set) and remaining credit available.

 

**◆ View Transaction History**
- Chronological list: date, transaction type (debt added / payment made), amount, notes.
- Pull-to-refresh reloads.

 

**◆ Record a Payment**
- "Ghi nhận thanh toán" navigates to **Record Debt Collection** screen.

 

**◆ Navigate Back**
- Back arrow in AppBar returns to **Debt Customer List**.

 

 ![](Setup%20and%20Mobile%20UI%20Guide-images/image037.png)

###### Figure 3.2.22.1: Debt profile

 

#### 3.2.23 Record Debt Collection
- **Function Trigger:** Navigated to from **Profile Detail & Debt History** or from the **Debt Customer List** expanded card via "Điều chỉnh công nợ."
- **Function Description:** Dedicated page to record a debt payment received from a customer. Real-time projected balance preview as the payment amount is entered. Supports cash and bank transfer.

 

**◆ View Current Balance**
- Debtor's outstanding balance displayed prominently at the top.

 

**◆ Enter Payment Amount**
- Numeric input; projected remaining balance updates in real-time.
- Validation: amount > 0; a warning (not a block) shown if amount exceeds current balance (over-payment scenario).

 

**◆ Select Payment Method**
- Option chips: "Tiền mặt" (Cash) or "Chuyển khoản" (Bank Transfer). Recorded for GL accounting.

 

**◆ Enter Notes**
- Optional memo / payment reference field.

 

**◆Confirm Payment**
- "Xác nhận" submits the payment record.
- On success: debtor balance updated, transaction added to history → navigate back to **Profile Detail & Debt History** with refreshed data.
- On failure: error Snackbar displayed.

![](Setup%20and%20Mobile%20UI%20Guide-images/image038.png)

###### Figure 3.2.23.1: Record debt

 

 

 

#### 3.2.24 Import Management
- **Function Trigger:** Accessed from the Product Management AppBar (history icon or FAB "Nhập kho" option) or from the Sidebar.
- **Function Description:** Entry hub for stock import operations. Provides navigation to the Goods Received Notes List and the Create Import Receipt flow.

 

**◆ Navigate to Goods Received Notes List**
- Tapping navigates to the import history list.

 

**◆ Navigate to Create Import**
- FAB "+" navigates to **Create Import Receipt Screen**.

 

 

 

#### 3.2.25 Goods Received Notes List
- **Function Trigger:** Navigated to from the **Import Management** entry or the Product Management AppBar history icon.
- **Function Description:** Chronological list of all stock import records for the selected business location. Pull-to-refresh and infinite scroll supported.

 

**◆ View Import History**
- Scrollable list of import cards: date, total items, total value, import type (Invoice / Manual).
- Pull-to-refresh reloads from the beginning; infinite scroll loads more at the bottom.

 

**◆ Create New Import**
- FAB "+" navigates to **Create Import Receipt Screen**.

 

**◆ View Import Detail**
- Tapping an import card navigates to **Receipt Detail** (read-only view).

 ![](Setup%20and%20Mobile%20UI%20Guide-images/image039.png)

###### Figure 3.2.25.1: Import list

 

 

#### 3.2.26 Receipt Detail
- **Function Trigger:** Navigated to by tapping a confirmed import card on the **Goods Received Notes List**.
- **Function Description:** Read-only display of a confirmed import receipt: item list, quantities, cost prices, supplier info, notes, and total value.

 

**◆ View Import Header**
- Import date, import type (Invoice / Manual), supplier name, import notes.

 

**◆ View Item List**
- Table of all imported products: product name, quantity, cost price, line total.
- Total import value shown at the bottom.

 ![](Setup%20and%20Mobile%20UI%20Guide-images/image040.png)

###### Figure 3.2.26.1: Receipt detail

 

 

#### 3.2.27 Create Import Receipt Screen
- **Function Trigger:** Navigated to from the FAB on the **Goods Received Notes List** or from the **Import Management** entry.
- **Function Description:** A form to create a new stock import receipt. Supports two modes: Invoice (attach/scan image for OCR parsing → Draft Import Receipt) and Manual (select products directly → Confirm Import).

 

**◆ Select Import Type**
- Toggle between "Nhập theo hóa đơn" (Invoice) and "Nhập thủ công" (Manual).

 

**◆ Invoice Mode   Attach Invoice Image**
- Image picker button (camera or gallery) to attach one or more invoice images.
- On image attach: system sends to OCR API → navigate to **Draft Import Receipt** for review.

 

**◆ Manual Mode   Add Products**
- "Thêm sản phẩm" button opens product picker; selected products added with editable quantity and cost price.

 

**◆ Enter Supplier and Notes**
- Optional fields for supplier name and import notes.

 

**◆ Proceed**
- Manual mode: "Lưu" navigates to **Confirm Import** screen.
- Invoice mode: after image attach, system auto-navigates to **Draft Import Receipt**.

 ![](Setup%20and%20Mobile%20UI%20Guide-images/image041.png)        ![](Setup%20and%20Mobile%20UI%20Guide-images/image042.png) 

###### Figure 3.2.27.1: Create import

 

 

#### 3.2.28 Draft Import Receipt
- **Function Trigger:** Navigated to automatically after OCR processing of an invoice image in the **Create Import Receipt Screen**, or when a saved draft is reopened.
- **Function Description:** Displays OCR-parsed or partially completed import items for review and correction. Unmatched items are flagged. Users confirm, edit, or add items before proceeding to the final confirmation step.

 

**◆ View Draft Items**
- List of parsed items: product name (matched / unmatched), quantity, cost price.
- Unmatched / low-confidence items flagged visually.

 

**◆ Edit Import Items**
- Editable quantity and cost price fields per row; delete icon removes an item.

 

**◆ Match Unmatched Products**
- Product picker icon on unmatched rows opens a search dialog to link to an existing inventory product.

 

**◆ Add Items Manually**
- "Thêm sản phẩm" adds products the OCR missed.

 

**◆ Confirm and Proceed**
- "Xác nhận" / "Tiếp tục" to **Confirm Import**.

 ![](Setup%20and%20Mobile%20UI%20Guide-images/image043.png)

###### Figure 3.2.28.1: Draft import

 

 

#### 3.2.29 Confirm Import
- **Function Trigger:** Navigated to from **Draft Import Receipt** or from **Create Import Receipt Screen** after manual item entry.
- **Function Description:** Read-only final summary of the import receipt before officially committing the stock update to inventory. The user verifies all details before posting.

 

**◆ View Import Summary**
- Read-only: import date, supplier name, notes, list of all products with quantity and cost price, total import value.

 

**◆ Confirm Import**
- "Xác nhận nhập kho" commits the import.
- Stock levels updated for all included products; cost GL entries created.
- On success: Snackbar shown → navigate to **Goods Received Notes List**.

 

 

 

 

#### 3.2.30 Product Management
- **Function Trigger:** Accessed from the "Sản phẩm" tab on the **Home Screen** Management Cards, by tapping a location card on the **Business Location List**, or from the Sidebar.
- **Function Description:** Entry point for product catalog management for the currently selected business location. Provides navigation to the Product List and all product operations.

 

**◆ Navigate to Product List**
- Navigates to the **Product List** screen for the current location.

 

 

 

#### 3.2.31 Product List
- **Function Trigger:** Navigated to from the **Product Management** entry or by tapping a location card on the **Business Location List**.
- **Function Description:** Displays and manages all products for the selected business location. Supports search, filter, sort, add, bulk price adjustment, stock import, and quick stock adjustment.

 

**◆ View Product List**
- Scrollable list: product name, business type, stock quantity, cost price, selling price.
- Infinite scroll supported; pull-to-refresh reloads.

 

**◆ Search Products**
- Real-time text filter by name or barcode. Clear (" ") icon appears when text is entered.

 

**◆ Scan Barcode**
- Barcode scanner icon opens camera; scanned value populates the search field.

 

**◆ Filter & Sort Products**
- Filter icon opens a bottom sheet: filter by Status (Active/Inactive), Business Type; sort by Name, Price.
- Active filters show an indicator bar with a "Clear filters" button.

 

**◆ Add New Product**
- FAB menu "Thêm sản phẩm" navigates to **Create New Product Screen & Sell Item**.

 

**◆ Import Inventory**
- FAB menu "Nhập kho" or AppBar history icon navigates to the **Import Management** module.

 

**◆ Bulk Adjust Selling Price**
- Price icon in AppBar navigates to the bulk price adjustment view (see **Update Product**, section 3.8.4c).

 

**◆ Quick Stock Adjustment**
- Long-press or action button on a product card opens an inline dialog: stock quantity, cost price, memo.
- Saves without full navigation.

 ![](Setup%20and%20Mobile%20UI%20Guide-images/image044.png)

###### Figure 3.2.31.1: Product list screen

 

 

#### 3.2.32 Create New Product Screen & Sell Item
- **Function Trigger:** Navigated to from the FAB menu "Thêm sản phẩm" on the **Product List**.
- **Function Description:** Comprehensive form to add a new product: identity, pricing, initial stock, unit conversions (sell items/tiers), and image upload. All required fields are validated on submission.

 

**◆ Enter Product Details**
- Required: product name, sale price.
- Optional: barcode (manual entry or scanner), business type (dropdown), cost price, initial stock quantity and unit, description, manufacturer.

 

**◆ Scan Barcode**
- Scanner icon auto-fills the barcode field from camera scan.

 

**◆ Upload Product Image**
- Image picker opens device gallery or camera to select/capture a product photo.

 

**◆ Add Unit Conversion Tiers (Sell Items)**
- "Thêm đơn vị quy đổi" section adds multi-level conversions (e.g., 1 carton = 24 cans, each with its own selling price).

 

**◆ Save Product**
- "Lưu" in AppBar validates and creates the product.
- On success: Snackbar shown → navigate back to **Product List** (list refreshes).
- On failure: inline validation errors displayed.

 ![](Setup%20and%20Mobile%20UI%20Guide-images/image045.png)        ![](Setup%20and%20Mobile%20UI%20Guide-images/image046.png) 

###### Figure 3.2.32.1: Create product

 

 

#### 3.2.33 Update Product
- **Function Trigger:** Navigated to from the **Product Detail** screen (edit icon) or the **Product List** edit action.
- **Function Description:** Same form as **Create New Product Screen** but pre-populated with the existing product's data. All fields editable. Also encompasses the Bulk Adjust Selling Price functionality accessible from the **Product List** AppBar.

 

**◆ Edit Product Details**
- Pre-filled form; all fields editable. Same validation rules as creation.

 

**◆ Save Changes**
- "Lưu" sends updated data to the backend.
- On success: product detail/list refreshes.

 

**◆ Bulk Adjust Selling Price** (accessed via price icon in Product List AppBar)
- List of all products with checkboxes; "Select All" option.
- Input fields: increase or decrease amount (fixed VND value or percentage).
- "Áp dụng" shows a confirmation dialog before applying.
- On confirm: selling prices updated for all selected products.

 ![](Setup%20and%20Mobile%20UI%20Guide-images/image047.png)        ![](Setup%20and%20Mobile%20UI%20Guide-images/image048.png) 

###### Figure 3.2.33.1: Update product

 

 

#### 3.2.34 Product Detail
- **Function Trigger:** Navigated to by tapping a product card on the **Product List**.
- **Function Description:** Comprehensive detail view of a single product: all pricing tiers, stock per location, unit conversions, barcode, pricing history, and quick stock adjustment.

 

**◆ View Product Info**
- Product image (if available), name, business type, barcode, Active/Inactive status.

 

**◆ View Stock Information**
- Stock quantities listed per business location.

 

**◆ View Pricing Details**
- Cost price and sale price.
- Unit conversion tiers each with individual pricing.

 

**◆ View Pricing History**
- Chronological list of price changes with dates.

 

**◆ Edit Product**
- Edit icon in AppBar navigates to **Update Product** pre-filled with this product's data.

 

**![](Setup%20and%20Mobile%20UI%20Guide-images/image049.png)                   ![](Setup%20and%20Mobile%20UI%20Guide-images/image050.png)** 

###### Figure 3.2.34.1: Product detail

 

 

 

#### 3.2.35 Employee Management
- **Function Trigger:** Accessed from the "Nhân viên" tab on the **Home Screen** or from the Sidebar.
- **Function Description:** Entry point for employee management. Provides navigation to the Employee List. Role: Owner only.

 

**◆ Navigate to Employee List**
- Navigates to the **Employee List** screen.

 

 

 

#### 3.2.36 Employee List
- **Function Trigger:** Navigated to from the **Employee Management** entry or the Home Screen "Nhân viên" tab.
- **Function Description:** Lists all employees registered under the owner's business. Supports search, status-tab filtering, editing, and deletion. Role: Owner only.

 

 

**◆ View Employee Summary**
- Three stats above the list: Total, Active, Pending employees.

 

**◆ Search Employees**
- Search text field at the top filters in real-time.

 

**◆ Filter by Status (Tabs)**
- Three tabs: "Tất cả", "Đang hoạt động", "Chờ duyệt."

 

**◆ Add New Employee**
- FAB "+" navigates to **Invite Employee**.

 

**◆Edit Employee**
- Action button on a card opens a bottom sheet; "Edit" navigates to **Update Employee's Business Location**.

 

**◆ Delete Employee**
- "Delete" in the action sheet shows a confirmation dialog with the employee's name.
- On confirm: employee permanently removed.

 

 

 

#### 3.2.37 Invite Employee
- **Function Trigger:** FAB "+" on the **Employee List** screen.
- **Function Description:** A form to send an invitation to a user (by email or phone) to join the business as an employee. Owner sets name, contact info, and which business locations the employee can access. Role: Owner only.

 

**◆ Search Existing User**
- Search field looks up registered system users by email or phone to quickly populate the form.

 

**◆ Enter Personal Information**
- Required: full name, phone number.
- Optional: email address.
- Inline validation shown on submit.

 

**◆ Assign Location Permissions**
- Checkbox list of available business locations the new employee will have access to.

 

**◆ Send Invitation**
- "Xác nhận" submits the invitation.
- On success: navigate back to **Employee List**; invited user appears as "Chờ duyệt" (Pending).
- On failure: error Snackbar displayed.

 ![](Setup%20and%20Mobile%20UI%20Guide-images/image051.png)

###### Figure 3.2.37.1: Invite employee

![](Setup%20and%20Mobile%20UI%20Guide-images/image052.png)

###### Figure 3.2.37.2: Received invitation

 

 

#### 3.2.38 Assign Employee into Business Location
- **Function Trigger:** Accessed from the **Update Location** screen (Tab 2   Employee Management).
- **Function Description:** Allows the owner to assign one or more existing employees to a selected business location. Displays all active employees with checkboxes; current assignments are pre-checked.

 

**◆ View Available Employees**
- Full list of active employees; currently assigned employees pre-checked.

 

**◆ Toggle Assignment**
- Checking / unchecking assigns or removes the employee from the location.

 

**◆ Save Assignments**
- "Lưu" persists changes; location's employee list updated.

 

 ![](Setup%20and%20Mobile%20UI%20Guide-images/image053.png)

###### Figure 3.2.38.1: Assign employee

![](Setup%20and%20Mobile%20UI%20Guide-images/image054.png)

###### Figure 3.2.38.2: Assign employee

![](Setup%20and%20Mobile%20UI%20Guide-images/image055.png)

###### Figure 3.2.38.1: Assign employee

 

#### 3.2.39 View Employee's Business Location
- **Function Trigger:** Navigated to form the employee action sheet on the **Employee List**.
- **Function Description:** Allows the owner to view an employee's personal details and location assignments.

**◆ View Personal Information**
- View employee s information: name, email, and phone.

![](Setup%20and%20Mobile%20UI%20Guide-images/image056.png)

###### Figure 3.2.39.1: Employee s profile

 

 

#### 3.2.40 Accounting Management
- **Function Trigger:** Accessed from the "Báo Cáo" quick action on the **Home Screen** or from the Sidebar.
- **Function Description:** Comprehensive financial management hub with 4 tab: Accounting Period, General Ledger, Cost, Revenue. Role: Owner only for most write operations.

 

**◆ Accounting Period Tab**
- Configure: period type (Quarterly / Yearly), accounting method (Method 1 / 2), opening cash balance, period notes.
- "Lưu cài đặt" saves settings (requires confirmation dialog).

 

**◆ General Ledger Tab**
- List of GL entries: date, description, debit/credit amount, payment channel (Cash / Bank / Debt).
- Channel filter dropdown. "+" button opens Add GL Entry dialog (description, amount, channel, entry type).

 

**◆ Cost Tab**
- Lists manually entered cost items for the current period.
- Inline edit dialog per item (description and amount).

 

**◆ Revenue Tab**
- Lists manually entered revenue items for the current period.
- Inline edit dialog per item (description and amount).

![](Setup%20and%20Mobile%20UI%20Guide-images/image057.png)

###### Figure 3.2.40.1: Accounting screen

 

#### 3.2.41 Export Excel Report
- **Function Trigger:** Triggered from the **Accounting Books** export action.
- **Function Description:** Allows export of reporting data to Excel with an accounting book.

**◆ Export**
- "Xuất Excel" checks reportExport subscription permission.
- If success: generates .xlsx → system share sheet.
- If failure: error message shown.

![](Setup%20and%20Mobile%20UI%20Guide-images/image058.png)

###### Figure 3.2.41: Export excel

 

#### 3.2.42 Accounting Books
- **Function Trigger:** Accessed from the **Accounting Period** tab within the **Accounting Management** hub.
- **Function Description:** Lists all TT152 accounting books created for the current location and period. Shows status and last export date per book. Provides navigation to create, view, and manage individual books.

**◆ View Book List**
- List of book cards: name (e.g., S1A   Sổ chi tiết bán hàng), status (Active / Locked), last exported date.

**◆ Open a Book**
- Tapping a card navigates to the **Accounting Book Detail** view for that book.

**◆ Create New Book**
- "+" navigates to **Create an Accounting Book**.

![](Setup%20and%20Mobile%20UI%20Guide-images/image059.png)

###### Figure 3.2.42.1: Accounting book

 

#### 3.2.43 View Ledger Screen
- **Function Trigger:** Navigated from the **Cost** and **Revenue** in the **Accounting Management** hub for a full-screen view.
- **Function Description:** Full-screen view of entered Cost or Revenue items for the current accounting period. Allows adding and editing entries inline.

 

**◆ View Cost / Revenue Entries**
- Scrollable list: date, description, amount per entry.
- Togglable between Cost and Revenue views.

 

**◆ Add Entry**
- "+" opens an inline dialog: description, amount, date.

 

**◆ Edit Entry**
- Tap an entry to open the edit dialog pre-filled.

![](Setup%20and%20Mobile%20UI%20Guide-images/image060.png)

###### Figure 3.2.43.1: View Leger

 

#### 3.2.44 Create Accounting Book
- **Function Trigger:** Navigated to from the **Accounting Books** screen via the "+" / "Tạo sổ kế toán" button.
- **Function Description:** A form to create a new TT152 accounting book by selecting the accounting period, book template type, and business type (for multi-type locations).

 

**◆ Select Accounting Period**
- Dropdown of configured periods (e.g., Q1 2026, Year 2025).
- Only periods configured in the Accounting Period tab are available.

 

**◆ Select Book Template Type**
- List of TT152 types: S1A   Sổ chi tiết bán hàng, S2A   Sổ quỹ tiền mặt, S2D   Sổ tiền gửi ngân hàng, etc.
- Selection determines the columns and data mapping.

 

**◆ Confirm Creation**
- "Tạo sổ" / "Xác nhận" creates the book.
- On success: navigate to **View Ledger Screen** for the new book.

![](Setup%20and%20Mobile%20UI%20Guide-images/image061.png)

###### Figure 3.2.44.1: Create accounting book

  

 

#### 3.2.45 Location Switcher
- **Function Trigger:** Tapping the active location name / storefront icon at the top of the **Home Screen**, or via location pickers in any location-context-aware module.
- **Function Description:** Quick-access bottom sheet or screen to switch the active business location context without navigating to the full Location Management. All subsequent operations apply to the newly selected location.

 

**◆ View Available Locations**
- Scrollable list of all active locations the user has access to (owned + assigned as employee).
- Each row: location name, address, selected indicator for the current active location.

 

**◆ Switch Active Location**
- Tapping a row sets it as the active location context.
- Switcher closes; Home Screen header updates.
- All module data (products, orders, reports) reloads for the new location.

 

**◆ Navigate to Location Management**
- "Quản lý địa điểm" link at the bottom navigates to **Business Location List**.

 

 ![](Setup%20and%20Mobile%20UI%20Guide-images/image062.png)

###### Figure 3.2.45: Location switcher

 

#### 3.2.46 Business Location List
- **Function Trigger:** Accessed from the "Địa điểm" tab on the **Home Screen**, from the **Location Switcher**, or from the Sidebar.
- **Function Description:** Lists all business locations owned by the user: name, address, business type, status, employee count. Supports search, create, edit, toggle status, and delete.

 

**◆ View Location List**
- Scrollable list of location cards: name, address, status (Active/Inactive), business type.
- Tapping a card navigates to the **Product List** for that location.

 

**◆ Search Locations**
- Search bar at the top filters the list in real-time.

 

**◆ Create New Location**
- FAB "+" navigates to **Create a New Location**.

 

**◆ Edit Location**
- Edit icon navigates to **Update Location** pre-filled with existing data.

 

**◆ Toggle Location Status**
- Status toggle switch changes Active ↔ Inactive.
- Inactive locations are hidden from the Home Screen location selector.
- Success Snackbar shown after update.

 

**◆ Delete Location**
- Delete icon shows a confirmation dialog; on confirm location is permanently deleted.

 ![](Setup%20and%20Mobile%20UI%20Guide-images/image063.png)

###### Figure 3.2.46.1: Business Location

 

 

#### 3.2.47 Create a New Location
- **Function Trigger:** Navigated to from the FAB on the **Business Location List** or from the No-Location redirect on the **Home Screen**.
- **Function Description:** A two-tab form to create a new business location: Tab 1 captures location information; Tab 2 manages initial employee assignments.

 

**◆ Tab 1   Location Information**
- Required: location name, address.
- Optional: phone number, business type (dropdown), status toggle (Active/Inactive; defaults to Active).
- Validation errors shown inline on submit.

 

**◆ Tab 2   Employee Management**
- Checkbox list of existing employees to assign to the new location at creation time.

 

**◆ Save Location**
- "Lưu" / "Xác nhận" validates required fields and creates the location.
- On success: Snackbar shown → navigate back to **Business Location List**.
- On failure: inline errors shown.

 ![](Setup%20and%20Mobile%20UI%20Guide-images/image064.png)

###### Figure 3.2.47: Create location

 

 

#### 3.2.48 Update Location
- **Function Trigger:** Navigated to from the edit icon on a location card in the **Business Location List**.
- **Function Description:** Same two-tab form as **Create a New Location** but pre-filled with the existing location's data. All fields are editable.

**◆ Edit Location Information (Tab 1)**
- Pre-filled: name, address, phone, business type, status toggle. All editable.

 

**◆ Edit Employee Assignments (Tab 2)**
- Current assignments pre-checked; checkboxes can be added or removed.

 

**◆ Save Changes**
- "Lưu" updates the location → list refreshes with Snackbar on success.

 

 ![](Setup%20and%20Mobile%20UI%20Guide-images/image065.png)        ![](Setup%20and%20Mobile%20UI%20Guide-images/image066.png) 

###### Figure 3.2.48: Update location

 

#### 3.2.49 Active/Deactivate Location
- **Function Trigger:** Tapping the status toggle on a location card in the **Business Location List** or via the status field in **Update Location**.
- **Function Description:** Toggles the active/inactive status of a business location. Inactive locations are hidden from the Home Screen selector and all business features become inaccessible for them.

 

**◆ Activate Location**
- Inactive → Active: location becomes accessible again in the Home Screen selector.
- Success Snackbar shown.

 

**◆ Deactivate Location**
- Active → Inactive: location is hidden from the Home Screen selector; products, orders, and employee features for this location become inaccessible.
- Success Snackbar shown.

 

 

 

#### 3.2.50 Delete Location
- **Function Trigger:** Tapping the delete icon on a location card in the **Business Location List**.
- **Function Description:** Permanently deletes a business location and its associated data after explicit user confirmation.

 

**◆ Confirmation Dialog**
- Shows the location name and a clear warning that the action is permanent and irreversible.

 

**◆ On Confirm**
- Location and all associated data permanently deleted.
- Location removed from the list; success Snackbar shown.

 

**◆ On Cancel**
- Dialog closes; no changes made.

 

 

 

#### 3.2.51 Assign Employee
- **Function Trigger:** Accessed from the **Update Location** form (Tab 2   Employee Management).
- **Function Description:** Allows the owner to assign or unassign employees from a selected business location via a checkbox list.

 

**◆ View Employees**
- Full list of active employees; currently assigned employees pre-checked.

 

**◆ Toggle Assignment**
- Checking / unchecking assigns or removes the employee from the location.

 

**◆ Save**
- "Lưu" persists the updated employee-location assignments.

 

 

 

#### 3.2.52 Subscription
- **Function Trigger:** Accessed from the Premium Upgrade Banner on the **Home Screen**, from the Sidebar, or from the **Settings → Account** screen.
- **Function Description:** Displays the current active subscription plan with real-time usage statistics, and allows comparison and upgrade of plans. Owners can upgrade or view transaction history; employees see a read-only banner.

 

 

**◆ View Current Plan (Owner)**
- Plan card: name (Free / Premium / Business), status badge, expiry date (if applicable), price.
- Real-time Firestore usage stats: Locations, Products, Employees used vs. plan limits.

 

**◆ View Plan Comparison**
- Three plan cards: Free (current plan, button disabled), Premium (Popular badge), Business (contact-sales CTA).
- Each card lists included/excluded features with checkmark /   icons.

 

**◆ Benefits & FAQ**
- Three benefit highlight cards (fast, secure, support).
- Expandable FAQ items below the plan cards.

 

**◆ View Employee Banner (Employee)**
- Blue info banner: "Bạn đang xem gói đăng ký của chủ cơ sở cho địa điểm n y."

 

**◆ Upgrade to Premium (Owner)**
- "Nâng cấp ngay" on the Premium card navigates to **Payment** with plan details pre-filled.

 

**◆ View Transaction History (Owner)**
- "Lịch sử giao dịch" shows a paginated list of past subscription payment transactions.

 ![](Setup%20and%20Mobile%20UI%20Guide-images/image067.png)       

###### Figure 3.2.52.1: Current subscription

![](Setup%20and%20Mobile%20UI%20Guide-images/image068.png)

###### Figure 3.2.52.2: Subscription plan

 

 

#### 3.2.53 Payment
- **Function Trigger:** Navigated to from the **Subscription** screen when the user taps "Nâng cấp ngay."
- **Function Description:** Payment screen for processing subscription purchases or renewals. Presents plan details, available payment methods (QR/bank transfer, card), and handles the payment flow including post-redirect webhook retry logic.

  

**◆ Confirm Payment**
- "Xác nhận thanh toán" processes the payment.
- On success: subscription status updated; navigate to checkout result screen.
- On failure: error state with retry option.
- After gateway redirect: system retries fetching updated subscription up to 5 times (2 seconds apart) to handle webhook processing delay; stale cache cleared.

 

 

 

#### 3.2.54 Setting
- **Function Trigger:** Accessed from the Sidebar menu.
- **Function Description:** Main settings screen providing access to Invoice Template, Profile, and Account sub-screens, plus global app configuration (language, notifications, logout).

 

 

**◆ Switch Language**
- Toggle between Vietnamese and English.
- App UI updates immediately upon selection.

 

**◆ Manage Notifications**
- Configure which types of push notifications the user receives.

 

**◆ Navigate to Sub-screens**
- "Hóa đơn" → **Invoice Template**.
- "Hồ sơ" → **Profile**.
- "Tài khoản" → **Account**.

 

**◆ Logout**
- "Đăng xuất" shows a confirmation dialog.
- On confirm: session cleared → navigate to **User Login**.

 

 

 

#### 3.2.55 Invoice Template
- **Function Trigger:** Accessed from the **Settings** screen or from the Sidebar.
- **Function Description:** Allows the owner to view, select, and configure invoice/receipt templates for printing or sharing order receipts. Includes basic template selection and a detailed advanced configuration panel.

 

**◆ View and Select Template**
- Horizontal-scrollable template cards: Basic, Professional, Retail, F&B.
- Each card shows a miniature preview; tapping selects it.
- "Áp dụng" saves the selection for future printed invoices.

 

**◆ Advanced Configuration**
- "Cài đặt nâng cao" opens an advanced settings panel with:
  - Live invoice preview (updates in real-time as settings change).
  - **Business Information**: name, address, phone, email, tax code, logo URL   values appear in the printed invoice header.
  - **Invoice Table Columns**: eye-icon toggles for STT, Product Name, Qty, Unit, Unit Price, Discount, VAT, Total.
  - **Customer Info Columns**: toggles for Name, Phone, Address, Email, Tax ID.
  - **Display Options** : toggles for Total VAT, Total Discount, Subtotal, Footer Note (reveals a text input if enabled), Signature.
  - **Apply to Business Locations**: filter chips to select which locations use this template.
- "Lưu" in a sticky bottom bar saves all configuration with a success Snackbar.

 

 ![](Setup%20and%20Mobile%20UI%20Guide-images/image069.png)                       ![](Setup%20and%20Mobile%20UI%20Guide-images/image070.png) 

###### Figure 3.2.55.1: Invoice template

 

#### 3.2.56 Profile
- **Function Trigger:** Accessed from the **Settings** screen via the "Hồ sơ" / "Profile" menu item.
- **Function Description:** Displays and allows editing of the user's personal and business profile information. This is the Settings-scoped profile sub-screen (distinct from the **User Profile** credential-linking screen in section 3.3).

**◆ View and Edit Profile Info**
- Fields: full name, business name (if applicable), contact information.
- Edit mode via edit icon or "Chỉnh sửa" button.
- "Lưu" saves changes; Snackbar on success.

![](Setup%20and%20Mobile%20UI%20Guide-images/image071.png)

###### Figure 3.2.56.1: Profile

 

 

 

#### 3.2.57 Account
- **Function Trigger:** Accessed from the **Settings** screen via the "Tài khoản" menu item.
- **Function Description:** Manages account-level security and identity: changing password, managing linked login methods (Email, Google, Phone), and initiating account deletion.

 

 **◆ Change Password**
- "Đổi mật khẩu" opens a form with: current password, new password (min 6 chars), confirm new password.
- Validation: current password correct; new fields match; min length met.
- On success: Snackbar shown.

**◆ Manage Linked Login Methods**
- Rows for Google, Email, Phone   each showing linked status and a link/unlink action.
- Linking/unlinking follows the same flows as **User Profile** (section 3.3.1).

**◆ Delete Account**
- "Xóa tài khoản" button styled destructively.
- Confirmation dialog requires password entry or a typed confirmation phrase.
- On confirm: deletion request sent; local session cleared → navigate to **User Login**.
