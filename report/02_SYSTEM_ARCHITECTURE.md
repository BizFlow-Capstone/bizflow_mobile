# 🏗️ SYSTEM ARCHITECTURE

**Kiến trúc hệ thống - Cập nhật mỗi phase**

---

## 📦 SYSTEM ARCHITECTURE DIAGRAM

```
┌─────────────────────────────────────────────────────────┐
│                   BIZFLOW MOBILE APP                    │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │         PRESENTATION LAYER (UI)                  │  │
│  │  Features: Auth, Home, Profile                  │  │
│  │  Screens, Widgets, Pages                        │  │
│  └────────────────────┬─────────────────────────────┘  │
│                       │                                │
│  ┌────────────────────▼─────────────────────────────┐  │
│  │      STATE MANAGEMENT LAYER (Bloc)               │  │
│  │  AuthBloc, HomeBloc, ProfileBloc                │  │
│  │  States, Events, Cubits                         │  │
│  └────────────────────┬─────────────────────────────┘  │
│                       │                                │
│  ┌────────────────────▼─────────────────────────────┐  │
│  │        BUSINESS LOGIC LAYER (Core)               │  │
│  │  ├─ Network: API Services                        │  │
│  │  ├─ Storage: Local Database                      │  │
│  │  ├─ Localization: Multi-language support         │  │
│  │  ├─ Routing: Navigation management               │  │
│  │  ├─ Config: App configuration                    │  │
│  │  └─ Theme: Design system                         │  │
│  └────────────────────┬─────────────────────────────┘  │
│                       │                                │
│  ┌────────────────────▼─────────────────────────────┐  │
│  │       DATA LAYER & REPOSITORIES                  │  │
│  │  Models, DTOs, Database Entities                │  │
│  └────────────────────┬─────────────────────────────┘  │
│                       │                                │
│  ┌────────────────────▼─────────────────────────────┐  │
│  │     EXTERNAL SERVICES & RESOURCES               │  │
│  │  ├─ REST API (Backend Server)                    │  │
│  │  ├─ Local Storage (SQLite/SharedPrefs)           │  │
│  │  ├─ Firebase (Analytics, Notifications)          │  │
│  │  └─ Google Sign-In                               │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

## 📂 FOLDER STRUCTURE

```
lib/
├── main.dart                           # App entry point
├── core/                               # Business logic layer
│   ├── config/                         # App configuration
│   ├── network/                        # API & network services
│   ├── storage/                        # Local database & caching
│   ├── localization/                   # Multi-language support
│   ├── routing/                        # Navigation & routing
│   ├── theme/                          # Design system & themes
│   └── notification/                   # Push notifications
├── features/                           # Feature modules
│   ├── auth/                           # Authentication feature
│   │   ├── bloc/                       # State management
│   │   ├── models/                     # Data models
│   │   ├── repositories/               # Data access
│   │   ├── screens/                    # UI pages
│   │   └── widgets/                    # Local widgets
│   ├── home/                           # Home feature
│   ├── profile/                        # Profile feature
│   └── [other_features]/
└── shared/                             # Shared components
    ├── dialogs/                        # Dialog widgets
    ├── extensions/                     # Extension methods
    ├── utils/                          # Utility functions
    └── widgets/                        # Reusable components
```

---

## 🔄 MODULE INTERACTIONS

```
┌─────────────────────────────────────────────────────┐
│              FEATURE: AUTHENTICATION                │
├─────────────────────────────────────────────────────┤
│                                                     │
│  screens/signup_screen.dart                        │
│         ↓                                           │
│  bloc/auth_bloc.dart → AuthState, AuthEvent        │
│         ↓                                           │
│  repositories/auth_repository.dart                 │
│         ↓                                           │
│  core/network/auth_service.dart                    │
│         ↓                                           │
│  Backend API (REST)                                │
│                                                     │
└─────────────────────────────────────────────────────┘
```

---

## 🔐 CORE MODULES DESCRIPTION

### 1. **config/** - Configuration Module
- App configuration constants
- Environment settings
- Build configurations

### 2. **network/** - Network Module
- API service classes
- HTTP client setup (Dio)
- Request/Response interceptors
- Error handling

### 3. **storage/** - Storage Module
- Local database setup (SQLite/Hive)
- SharedPreferences wrapper
- Data persistence layer
- Cache management

### 4. **localization/** - Localization Module
- i18n/l10n setup
- Translation files (.json)
- Multi-language support
- Language switching logic

### 5. **routing/** - Routing Module
- Route definitions
- Navigation management
- Deep linking support
- Route transitions

### 6. **theme/** - Theme Module
- Design system tokens
- Color palette
- Typography definitions
- Dark/Light mode support

### 7. **notification/** - Notification Module
- Push notification setup (Firebase)
- Local notification management
- Notification handlers

---

## 📊 LAYER INTERACTION & DATA FLOW DIAGRAM

### Complete Data Flow Between Layers

```
╔════════════════════════════════════════════════════════════════════════╗
║                     BIZFLOW MOBILE - LAYER INTERACTION                ║
╚════════════════════════════════════════════════════════════════════════╝

┌──────────────────────────────────────────────────────────────────────┐
│  LAYER 1: PRESENTATION LAYER (UI/Screens)                           │
├──────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐             │
│  │ signup_      │  │ otp_         │  │ home_        │             │
│  │ screen.dart  │  │ screen.dart   │  │ screen.dart  │             │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘             │
│         │                 │                 │                      │
│         └─────────────────┼─────────────────┘                      │
│                           │                                         │
│                  BUILD CONTEXT LISTENER                             │
│                           │                                         │
└───────────────────────────┼─────────────────────────────────────────┘
                            │
                            ▼
┌──────────────────────────────────────────────────────────────────────┐
│  LAYER 2: STATE MANAGEMENT LAYER (BLoC)                             │
├──────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌─────────────────────────────────────────────────────┐           │
│  │  AuthBloc / HomeBloc / ProfileBloc                  │           │
│  ├─────────────────────────────────────────────────────┤           │
│  │                                                     │           │
│  │  Receives: Events (SignupRequested, etc)           │           │
│  │  Processing: Business logic & validation           │           │
│  │  Outputs: States (Loading, Success, Failure)       │           │
│  │                                                     │           │
│  │  ┌─────────────────────────────────────┐           │           │
│  │  │ Event Handler                       │           │           │
│  │  ├─────────────────────────────────────┤           │           │
│  │  │ 1. Receive event from UI            │           │           │
│  │  │ 2. Validate input data              │           │           │
│  │  │ 3. Emit Loading state               │           │           │
│  │  │ 4. Call Repository method           │           │           │
│  │  │ 5. Emit Success/Failure state       │           │           │
│  │  └─────────────────────────────────────┘           │           │
│  │                                                     │           │
│  └─────────────────────────────────────────────────────┘           │
│         │                           │                              │
│         │ (Emits States)            │ (Calls)                     │
│         ▼                           ▼                              │
└───────────┬───────────────────────────────────────────────────────┘
            │
            ├──────────────────────────┬──────────────────┐
            │                          │                  │
            ▼ (sends updates to UI)    │                  │
                                       ▼ (requests data)  │
                                                         ▼
┌──────────────────────────────────────────────────────────────────────┐
│  LAYER 3: BUSINESS LOGIC LAYER (Core Services)                      │
├──────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌────────────────────┐  ┌────────────────────┐                    │
│  │ REPOSITORY LAYER   │  │ SERVICE LAYER      │                    │
│  ├────────────────────┤  ├────────────────────┤                    │
│  │                    │  │                    │                    │
│  │ AuthRepository     │  │ config/            │                    │
│  │ ├─ signup()        │  │ network/           │                    │
│  │ ├─ login()         │  │ ├─ auth_service.   │                    │
│  │ ├─ logout()        │  │ │ dart (API)       │                    │
│  │ └─ saveToken()     │  │ ├─ dio_client.     │                    │
│  │                    │  │ │ dart (HTTP)      │                    │
│  │ HomeRepository     │  │ ├─ interceptors    │                    │
│  │ ├─ getHome()       │  │ └─ error handling  │                    │
│  │ └─ getStats()      │  │                    │                    │
│  │                    │  │ storage/           │                    │
│  │ ProfileRepository  │  │ ├─ save_token()    │                    │
│  │ ├─ getUser()       │  │ ├─ get_token()     │                    │
│  │ └─ updateUser()    │  │ └─ cache()         │                    │
│  │                    │  │                    │                    │
│  │                    │  │ localization/      │                    │
│  │                    │  │ ├─ change_lang()   │                    │
│  │                    │  │ └─ translate()     │                    │
│  │                    │  │                    │                    │
│  └────────────────────┘  │ routing/           │                    │
│         │                │ ├─ navigate()      │                    │
│         │                │ └─ push_route()    │                    │
│         │                │                    │                    │
│         │                │ theme/             │                    │
│         │                │ ├─ get_colors()    │                    │
│         │                │ └─ get_fonts()     │                    │
│         │                │                    │                    │
│         └─────┬──────────│─────┬──────────────┘                    │
│               │          │     │                                    │
│    ┌──────────▼──────────▼─┐   │                                    │
│    │ MODELS & DTOs         │   │                                    │
│    ├───────────────────────┤   │                                    │
│    │ - UserRequest         │   │                                    │
│    │ - UserResponse        │   │                                    │
│    │ - SignupRequest       │   │                                    │
│    │ - HomeData            │   │                                    │
│    │ - ProfileData         │   │                                    │
│    └───────────┬───────────┘   │                                    │
│                │                │                                    │
└────────────────┼────────────────┼──────────────────────────────────┘
                 │                │
                 ▼                ▼
┌──────────────────────────────────────────────────────────────────────┐
│  LAYER 4: DATA LAYER (Sources)                                       │
├──────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌──────────────────┐  ┌──────────────────┐  ┌─────────────────┐  │
│  │ REMOTE DATA      │  │ LOCAL DATA       │  │ DEVICE DATA     │  │
│  ├──────────────────┤  ├──────────────────┤  ├─────────────────┤  │
│  │                  │  │                  │  │                 │  │
│  │ REST API         │  │ SQLite Database  │  │ SharedPrefs     │  │
│  │ ├─ auth/signup   │  │ ├─ users table   │  │ ├─ app_token    │  │
│  │ ├─ auth/login    │  │ ├─ sessions      │  │ ├─ user_lang    │  │
│  │ ├─ auth/verify   │  │ └─ cache table   │  │ ├─ theme_mode   │  │
│  │ ├─ home/data     │  │                  │  │ └─ settings     │  │
│  │ └─ users/{id}    │  │ Hive Storage     │  │                 │  │
│  │                  │  │ ├─ offline data  │  │ Firebase        │  │
│  │ Error Handling   │  │ └─ sync queue    │  │ ├─ Analytics    │  │
│  │ ├─ timeout       │  │                  │  │ ├─ Messaging    │  │
│  │ ├─ 4xx errors    │  │ File Storage     │  │ └─ Notifications│  │
│  │ └─ 5xx errors    │  │ ├─ images        │  │                 │  │
│  │                  │  │ └─ documents     │  │                 │  │
│  └──────────────────┘  └──────────────────┘  └─────────────────┘  │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

---

### Detailed Layer Interaction Flow

#### 1️⃣ USER INITIATES ACTION (Presentation → State Management)
```
User Input (Tap Button)
       ↓
BlocListener builds context
       ↓
Widget emits BLoC Event
       ↓
Event Example: SignupRequested(email, password, name)
```

#### 2️⃣ BLOC PROCESSES EVENT (State Management → Business Logic)
```
BLoC receives SignupRequested event
       ↓
1. Add event to event sink
2. Validate input data
3. Emit AuthLoading state
4. Call AuthRepository.signup()
       ↓
Waits for Repository response
```

#### 3️⃣ REPOSITORY ORCHESTRATES DATA (Business Logic → Data Layer)
```
AuthRepository.signup(request)
       ↓
1. Validate request
2. Call AuthService.signup(request)
3. Process response
4. Save token to storage
5. Return User object
       ↓
Response back to BLoC
```

#### 4️⃣ SERVICE COMMUNICATES WITH EXTERNAL SERVICES (Data Layer)
```
AuthService.signup(request)
       ↓
1. Create HTTP request
2. Add headers & auth
3. Send via Dio client
4. Handle response/error
5. Parse JSON response
       ↓
Response back to Repository
```

#### 5️⃣ BLOC EMITS NEW STATE (State Management → Presentation)
```
Receives response from Repository
       ↓
1. Create new State object
2. Add response data
3. Emit new state
       ↓
BlocListener receives state
       ↓
Widget rebuilds with new data
```

---

## 📊 DATA FLOW EXAMPLE: USER SIGNUP

```
User Action:
┌─────────────────────────────────────────┐
│ User enters email/password & taps SIGN UP│
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│ SignupButton triggers AuthBloc event:   │
│ SignupRequested(email, password, name)  │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│ AuthBloc processes event:                │
│ - Validate input                         │
│ - Show loading state                     │
│ - Call AuthRepository.signup()           │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│ AuthRepository:                          │
│ - Call AuthService.signup(credentials)   │
│ - Handle response/error                  │
│ - Save token to local storage            │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│ AuthService (Network):                  │
│ - Make POST request to /auth/signup      │
│ - Return UserResponse or error           │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│ Backend Server Response:                 │
│ { token, user_id, email, ... }          │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│ AuthBloc emits SignupSuccess state:     │
│ - Store user data                        │
│ - Emit AuthAuthenticated state           │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│ UI rebuilds:                             │
│ - Navigate to home screen                │
│ - Show success message                   │
│ - Update user profile                    │
└─────────────────────────────────────────┘
```

---

## 🔌 EXTERNAL SERVICES INTEGRATION

### REST API
- **Base URL:** `https://api.bizflow.com`
- **Auth:** Bearer token in header
- **Endpoints:**
  - `POST /auth/signup` - User registration
  - `POST /auth/login` - User login
  - `POST /auth/otp-verify` - OTP verification
  - `GET /users/{id}` - Get user profile
  - `GET /home` - Get home data

### Local Storage
- **Database:** SQLite (floor) or Hive
- **Preferences:** SharedPreferences
- **Data:** User tokens, cached data, preferences

### Firebase Services
- **Authentication:** Email/Google sign-in
- **Analytics:** User behavior tracking
- **Messaging:** Push notifications
- **Firestore:** Real-time database (optional)

### Localization
- **Languages:** English, Vietnamese
- **Format:** .json files
- **Switching:** Runtime language change

---

## 🎯 DESIGN PATTERNS USED

### 1. **BLoC Pattern**
- Separate business logic from UI
- Event-driven state management
- Used in: Auth, Home, Profile features

### 2. **Repository Pattern**
- Abstract data sources
- Centralized data access
- Used in: All features

### 3. **Dependency Injection**
- Service locator (GetIt)
- Constructor injection
- Used in: All modules

### 4. **Singleton Pattern**
- Single instance of services
- Used in: Network, Storage, Config services

### 5. **Builder Pattern**
- Complex object creation
- Used in: API responses, Model construction

---

## ⚙️ TECH STACK

| Layer | Technology | Version |
|-------|-----------|---------|
| **Framework** | Flutter | 3.x+ |
| **Language** | Dart | 3.x+ |
| **State Mgmt** | Flutter Bloc | 8.x+ |
| **HTTP Client** | Dio | 5.x+ |
| **Local DB** | floor/hive | Latest |
| **Localization** | intl | 0.20.2 |
| **DI** | GetIt | 7.x+ |
| **Testing** | Test | Flutter |

---

## 🔗 MODULE DEPENDENCIES

```
features/auth/ depends on:
├── core/network/ (API calls)
├── core/storage/ (Token storage)
├── core/localization/ (Error messages)
├── core/routing/ (Navigation)
└── shared/ (Common widgets)

features/home/ depends on:
├── core/network/ (Home data API)
├── core/storage/ (Cache)
├── shared/ (Common widgets)
└── features/auth/ (User context)

features/profile/ depends on:
├── core/network/ (User API)
├── core/storage/ (User data)
├── shared/ (Common widgets)
└── features/auth/ (Authentication)
```

---

## 🔄 STATE MANAGEMENT FLOW

```
┌─────────────┐     ┌──────────────────┐     ┌──────────────┐
│   Widget    │────▶│   BLoC/Cubit     │────▶│   Repository │
│ (UI Layer)  │     │ (Logic Layer)     │     │ (Data Layer) │
└─────────────┘     └──────────────────┘     └──────────────┘
      ▲                     │                        │
      │                     │                        ▼
      │              ┌──────▼──────┐        ┌────────────────┐
      └──────────────│   State     │        │   Data Source  │
                     │  (Emitted)  │        │  (Local/Remote)│
                     └─────────────┘        └────────────────┘
```

---

**Last Updated:** Jan 27, 2026  
**Version:** 1.0  
**Status:** Current Architecture ✅
