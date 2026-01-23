# 🏗️ SYSTEM ARCHITECTURE & DATA FLOW

**Define toàn bộ logic xử lý data và tương tác giữa các files**

---

## 📊 SYSTEM OVERVIEW

### Layered Architecture
```
┌─────────────────────────────────────────────┐
│           PRESENTATION LAYER                 │
│   (UI - Pages, Widgets, Dialogs)            │
├─────────────────────────────────────────────┤
│         DOMAIN LAYER (Business Logic)       │
│   (Entities, Usecases, Interfaces)          │
├─────────────────────────────────────────────┤
│           DATA LAYER (API/DB)               │
│   (Repositories, APIs, Models)              │
├─────────────────────────────────────────────┤
│         CORE LAYER (Infrastructure)         │
│   (Network, Storage, Routing, Theme, etc.)  │
├─────────────────────────────────────────────┤
│          SHARED LAYER (Utilities)           │
│   (Widgets, Extensions, Validators, etc.)   │
└─────────────────────────────────────────────┘
```

---

## 🔄 DATA FLOW ARCHITECTURE

### Tổng Quát
```
User Action (UI)
       ↓
   Page/Widget
       ↓
   Bloc/Provider (State Management)
       ↓
   Usecase (Business Logic)
       ↓
   Repository (Data Management)
       ↓
   API Client / Local Storage
       ↓
   Network / Database
       ↓
   Response back to UI
```

### Chi Tiết Từng Bước

#### 1. User Interaction Layer
```
┌─ Presentation Layer ────────────────────┐
│                                         │
│  User clicks button on Page             │
│         ↓                               │
│  Page calls Bloc.add(Event)             │
│         ↓                               │
│  Event dispatched to Bloc               │
│                                         │
└─────────────────────────────────────────┘
```

**Files involved:**
- `features/*/presentation/pages/*.dart` - Page definition
- `features/*/presentation/widgets/*.dart` - Custom widgets
- `shared/widgets/*.dart` - Shared UI components

---

#### 2. State Management Layer
```
┌─ Bloc/Provider Layer ──────────────────┐
│                                         │
│  Bloc receives Event                    │
│         ↓                               │
│  mapEventToState() called               │
│         ↓                               │
│  Call Usecase                           │
│         ↓                               │
│  Emit state (Loading, Success, Error)   │
│         ↓                               │
│  UI rebuilds based on new state         │
│                                         │
└─────────────────────────────────────────┘
```

**Files involved:**
- `features/*/presentation/bloc/*.dart` - BLoC definitions (to be created)
- Events, States definitions

---

#### 3. Business Logic Layer
```
┌─ Domain Layer (Usecase) ───────────────┐
│                                         │
│  Usecase receives parameters            │
│         ↓                               │
│  Validate input (if needed)             │
│         ↓                               │
│  Call Repository method                 │
│         ↓                               │
│  Process data (transform, filter, etc.) │
│         ↓                               │
│  Return result/entity                   │
│                                         │
└─────────────────────────────────────────┘
```

**Files involved:**
- `features/*/domain/usecases/*.dart` - Usecase implementations
- `features/*/domain/entities/*.dart` - Entity definitions

---

#### 4. Data Access Layer
```
┌─ Repository Layer ─────────────────────┐
│                                         │
│  Repository receives request            │
│         ↓                               │
│  Check if data in cache/local storage   │
│         ├─ Yes: Return cached data      │
│         └─ No: Call API                 │
│         ↓                               │
│  Call API Client / Local Storage        │
│         ↓                               │
│  Parse response to Entity               │
│         ↓                               │
│  Save to local storage (optional)       │
│         ↓                               │
│  Return Entity                          │
│                                         │
└─────────────────────────────────────────┘
```

**Files involved:**
- `features/*/data/repositories/*.dart` - Repository implementations
- `features/*/data/*_api.dart` - API client wrappers

---

#### 5. Infrastructure Layer
```
┌─ Core Layer (API Client) ──────────────┐
│                                         │
│  HTTP Request initiated                 │
│         ↓                               │
│  Add headers (token, content-type)      │
│         ↓                               │
│  Interceptor processes request          │
│         ↓                               │
│  Send HTTP call                         │
│         ↓                               │
│  Receive response                       │
│         ↓                               │
│  Check status code                      │
│  ├─ 200-299: Parse & return             │
│  ├─ 401: Refresh token & retry          │
│  ├─ 4xx/5xx: Throw ApiException         │
│  └─ Network error: Throw NetworkError   │
│         ↓                               │
│  Return parsed JSON                     │
│                                         │
└─────────────────────────────────────────┘
```

**Files involved:**
- `core/network/api_client.dart` - HTTP client with interceptor
- `core/network/api_endpoints.dart` - Endpoint definitions
- `core/storage/*.dart` - Local/secure storage

---

## 🔗 FILE INTERACTION MAP

### By Feature Module (Example: Auth)

```
features/auth/
│
├── presentation/
│   ├── pages/
│   │   └── login_page.dart ◄─────┐
│   │       └── Uses AppButton,     │
│   │           AppTextField (shared)
│   │           └── Calls
│   │               Bloc.add(LoginEvent)
│   │                   │
│   └── bloc/                       │
│       ├── auth_bloc.dart          │
│       ├── auth_event.dart         │
│       └── auth_state.dart         │
│           └── Listens to state    │
│               └── Calls
│                   LoginUsecase.call()
│                       │
├── domain/
│   ├── entities/
│   │   └── user_entity.dart
│   │       ◄─ Defined by
│   │
│   └── usecases/
│       └── login_usecase.dart ◄───┤
│           └── Calls
│               AuthRepository.login()
│                   │
└── data/
    ├── repositories/
    │   └── auth_repository_impl.dart ◄──┤
    │       └── Calls
    │           AuthApi.login()
    │               │
    └── datasources/
        └── auth_remote_datasource.dart ◄┤
            └── Uses
                core/network/api_client.dart
                    └── Uses
                        core/network/api_endpoints.dart
```

---

## 📋 COMPLETE DATA FLOW EXAMPLE: USER LOGIN

```
STEP 1: User Interaction
────────────────────────────────────────
File: features/auth/presentation/pages/login_page.dart
Code:
  AppButton(
    onPressed: () {
      context.read<AuthBloc>().add(
        LoginEvent(email: email, password: password)
      );
    }
  )

STEP 2: Event Created
────────────────────────────────────────
File: features/auth/presentation/bloc/auth_event.dart
Code:
  abstract class AuthEvent {}
  class LoginEvent extends AuthEvent {
    final String email;
    final String password;
    LoginEvent({required this.email, required this.password});
  }

STEP 3: Bloc Processes Event
────────────────────────────────────────
File: features/auth/presentation/bloc/auth_bloc.dart
Code:
  Stream<AuthState> mapEventToState(AuthEvent event) async* {
    if (event is LoginEvent) {
      yield AuthLoading();
      try {
        final user = await loginUsecase(
          LoginParams(email: event.email, password: event.password)
        );
        yield AuthSuccess(user);
      } catch (e) {
        yield AuthError(e.toString());
      }
    }
  }

STEP 4: Usecase Processes Business Logic
────────────────────────────────────────
File: features/auth/domain/usecases/login_usecase.dart
Code:
  class LoginUsecase extends UseCase<UserEntity, LoginParams> {
    @override
    Future<UserEntity> call(LoginParams params) async {
      // Validation could happen here
      if (!isValidEmail(params.email)) {
        throw InvalidEmailException();
      }
      
      // Call repository
      return await repository.login(params.email, params.password);
    }
  }

STEP 5: Repository Gets Data
────────────────────────────────────────
File: features/auth/data/repositories/auth_repository_impl.dart
Code:
  class AuthRepositoryImpl implements AuthRepository {
    @override
    Future<UserEntity> login(String email, String password) async {
      // Try to get from cache first
      final cachedUser = await localDataSource.getUser();
      if (cachedUser != null) {
        return cachedUser;
      }
      
      // Call API
      final userModel = await remoteDataSource.login(email, password);
      
      // Save to local storage
      await localDataSource.saveUser(userModel);
      
      // Convert model to entity & return
      return userModel.toEntity();
    }
  }

STEP 6: API Client Makes HTTP Call
────────────────────────────────────────
File: features/auth/data/datasources/auth_remote_datasource.dart
Code:
  class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
    @override
    Future<UserModel> login(String email, String password) async {
      return await apiClient.post(
        endpoint: ApiEndpoints.login,
        body: {
          'email': email,
          'password': password,
        },
      );
    }
  }

STEP 7: Core Network Layer Handles Request
────────────────────────────────────────
File: core/network/api_client.dart
Code:
  Future<T> post<T>(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      // Add token to header
      headers['Authorization'] = 'Bearer ${await getToken()}';
      
      // Make request
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: jsonEncode(body),
      );
      
      // Handle response
      if (response.statusCode == 200) {
        return _parseResponse<T>(response.body);
      } else if (response.statusCode == 401) {
        // Try to refresh token
        await refreshToken();
        return post<T>(endpoint, body: body); // Retry
      } else {
        throw ApiException(response.statusCode, response.body);
      }
    } catch (e) {
      throw NetworkException(e.toString());
    }
  }

STEP 8: Endpoint Used
────────────────────────────────────────
File: core/network/api_endpoints.dart
Code:
  class ApiEndpoints {
    static const String baseUrl = 'https://api.example.com';
    static const String login = '/auth/login';
  }

STEP 9: Response Parsed & Returned
────────────────────────────────────────
Response: UserModel (JSON to Dart object)
  ├── Convert to Entity in Repository
  └── Save to Storage
      └── Return to Usecase
          └── Return to Bloc
              └── Emit AuthSuccess(user)
                  └── UI rebuilds with user data

STEP 10: UI Updates
────────────────────────────────────────
File: features/auth/presentation/pages/login_page.dart
Code:
  BlocBuilder<AuthBloc, AuthState>(
    builder: (context, state) {
      if (state is AuthLoading) {
        return LoadingWidget();
      } else if (state is AuthSuccess) {
        return HomePage();
      } else if (state is AuthError) {
        return ErrorWidget(message: state.message);
      }
    }
  )

UI shows success message and navigates to home
```

---

## 🗂️ FILE ORGANIZATION BY RESPONSIBILITY

### Data Entity Layer
```
features/auth/domain/entities/
├── user_entity.dart          ← Defines what User is
└── Other entities...
```
**Responsibility:** Define business entities (domain models)

### Business Logic Layer
```
features/auth/domain/usecases/
├── login_usecase.dart        ← Login business logic
├── register_usecase.dart     ← Register business logic
└── Other usecases...
```
**Responsibility:** Implement business rules and use cases

### Data Access Layer
```
features/auth/data/
├── datasources/
│   ├── auth_remote_datasource.dart    ← API calls
│   └── auth_local_datasource.dart     ← Local storage
├── models/
│   └── user_model.dart                ← API response model
└── repositories/
    └── auth_repository_impl.dart      ← Combine data sources
```
**Responsibility:** Handle data acquisition and transformation

### Presentation Layer
```
features/auth/presentation/
├── pages/
│   ├── login_page.dart              ← Login screen
│   ├── register_page.dart           ← Register screen
│   └── Other pages...
├── widgets/
│   ├── login_form.dart              ← Login form widget
│   └── Other local widgets...
├── bloc/
│   ├── auth_bloc.dart               ← BLoC logic
│   ├── auth_event.dart              ← Events
│   └── auth_state.dart              ← States
└── provider/ (if using Riverpod)
    └── auth_provider.dart
```
**Responsibility:** Handle UI rendering and user interaction

---

## 🔀 CROSS-LAYER DEPENDENCIES

### What Each Layer Can Access

```
Presentation Layer
    ↓ Can use
Domain Layer (Entities, Usecases)
    ↓ Can use
Data Layer (Repositories)
    ↓ Can use
Core Layer (API, Storage)
    ↓ Can use
Shared Layer (Utils, Extensions, Widgets)

Shared Layer
    ↑ Cannot access (no business logic)
```

### Forbidden Dependencies
```
❌ Presentation → Data (directly)
❌ Presentation → Core (directly, except navigation)
❌ Domain → Data
❌ Data → Presentation
❌ Shared → Domain
❌ Shared → Features
❌ Feature A → Feature B
```

---

## 💾 STORAGE & CACHING STRATEGY

### Data Flow with Cache
```
1. User Request Data
       ↓
2. Repository checks:
       ├─ Is data in cache? (memory) → Return
       ├─ Is data in local storage? → Return & cache
       └─ No → Call API
       ↓
3. API Response
       ↓
4. Repository:
       ├─ Cache in memory
       ├─ Save to local storage
       └─ Return to Usecase
```

### Cache Invalidation
```
When to invalidate cache:
├─ After create/update/delete operation
├─ On user logout
├─ Manually by user (refresh button)
└─ Time-based (old data)

Implementation:
  repository.clearCache() → Called when cache invalid
```

---

## 🔐 TOKEN & AUTH FLOW

### Token Management
```
1. Login Success
       ↓
2. Token received from API
       ↓
3. Store in SecureStorage
       ↓
4. Each API request:
       ├─ Get token from SecureStorage
       ├─ Add to Authorization header
       └─ Send request
       ↓
5. Response:
       ├─ 200: Continue
       ├─ 401: Token expired
       │   ├─ Call refresh token API
       │   ├─ Save new token
       │   └─ Retry original request
       └─ Other error: Handle accordingly
       ↓
6. Logout:
       ├─ Delete token from SecureStorage
       └─ Clear cache
```

---

## 🧪 TESTING STRATEGY

### Test Layers

#### Unit Tests (Domain Layer)
```
Test usecases with mocked repositories
Test entities validation
Test business logic
```

#### Unit Tests (Data Layer)
```
Test repositories with mocked API/storage
Test data transformation
Test error handling
```

#### Widget Tests (Presentation Layer)
```
Test widgets rendering
Test user interactions
Test state changes (with mocked Bloc)
```

#### Integration Tests
```
Test complete flows
Test API integration
Test real Bloc behavior
```

---

## 📡 ERROR HANDLING FLOW

```
Error Occurs
    ↓
Layer catches error
    ├─ Data Layer: Convert to Repository Exception
    ├─ Domain Layer: Throw to Bloc
    └─ Presentation Layer: Convert to UI message
    ↓
Bloc catches and emits Error state
    ↓
UI displays error to user
    ├─ Show snackbar/dialog
    └─ Give option to retry
    ↓
User retries
    └─ Flow starts again
```

---

## 📊 STATE MANAGEMENT FLOW

### Bloc State Transitions
```
Initial State
    ↓
User Action → Event
    ↓
Bloc processes → emit Loading State
    ↓
Async operation
    ├─ Success → emit Success State
    └─ Error → emit Error State
    ↓
UI rebuilds based on state
    ↓
Next action → New event
```

---

## 🔌 API INTEGRATION

### Step-by-Step API Integration

#### 1. Define Endpoint
```dart
// core/network/api_endpoints.dart
static const String getUser = '/users/:id';
```

#### 2. Create Datasource
```dart
// features/user/data/datasources/user_remote_datasource.dart
Future<UserModel> getUser(String id) async {
  return await apiClient.get('/users/$id');
}
```

#### 3. Create Repository
```dart
// features/user/data/repositories/user_repository_impl.dart
Future<UserEntity> getUser(String id) async {
  final model = await remoteDataSource.getUser(id);
  return model.toEntity();
}
```

#### 4. Create Usecase
```dart
// features/user/domain/usecases/get_user_usecase.dart
Future<UserEntity> call(String id) async {
  return await repository.getUser(id);
}
```

#### 5. Create Bloc
```dart
// features/user/presentation/bloc/user_bloc.dart
mapEventToState(GetUserEvent event) async* {
  yield UserLoading();
  try {
    final user = await getUsecase(event.id);
    yield UserLoaded(user);
  } catch (e) {
    yield UserError(e.toString());
  }
}
```

#### 6. Use in UI
```dart
// features/user/presentation/pages/user_page.dart
BlocBuilder<UserBloc, UserState>(
  builder: (context, state) {
    if (state is UserLoading) return LoadingWidget();
    if (state is UserLoaded) return UserWidget(user: state.user);
    if (state is UserError) return ErrorWidget(message: state.message);
  }
)
```

---

## 📈 SCALABILITY CONSIDERATIONS

### Adding New Feature
```
1. Create feature folder structure
   features/new_feature/
   ├── presentation/
   ├── domain/
   └── data/

2. Define entities in domain/entities/

3. Create usecases in domain/usecases/

4. Create datasources in data/datasources/

5. Create repository in data/repositories/

6. Create BLoC/Provider in presentation/bloc or provider/

7. Create UI in presentation/pages/ and widgets/

8. Add routes to core/routing/app_router.dart

9. Write tests for each layer
```

---

## 🎯 QUICK REFERENCE: FILE DEPENDENCY

### If you need to change...

| You want to change | Edit these files | Don't touch |
|-------------------|------------------|-----------|
| UI layout | presentation/pages/*.dart | domain/, data/ |
| UI behavior | presentation/bloc/*.dart | domain/, data/ |
| Business logic | domain/usecases/*.dart | presentation/pages |
| API call | data/datasources/*_api.dart | presentation/ |
| Data storage | data/repositories/*.dart | presentation/ |
| Network config | core/network/*.dart | features/ |
| Theme | core/theme/*.dart | features/ |
| Route | core/routing/app_router.dart | features/ |

---

**Version:** 1.0  
**Last Updated:** 23/01/2026  
**Next Review:** When implementing first feature

---

**Hết - System Architecture & Data Flow**
