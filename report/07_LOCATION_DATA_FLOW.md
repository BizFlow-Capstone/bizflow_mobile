# Location Management - Data Flow & Architecture

## 🏗️ Clean Architecture Layers

```
┌─────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                        │
│  (Pages, Widgets, BLoC - User Interface & Logic)            │
│                                                              │
│  ┌──────────────────┐  ┌──────────────────┐                │
│  │ LocationManagement│  │ AddEditLocation  │                │
│  │     Page         │  │     Page         │                │
│  │  (SC-LOC-01)     │  │  (SC-LOC-03)     │                │
│  └────────┬─────────┘  └────────┬─────────┘                │
│           │                     │                            │
│           └──────────┬──────────┘                            │
│                      │                                        │
│              ┌───────▼────────┐                              │
│              │  LocationBloc  │                              │
│              │ (State Manager)│                              │
│              └───────┬────────┘                              │
│                      │                                        │
│              ┌───────▼────────┐                              │
│              │ LocationCard   │                              │
│              │ (Reusable UI)  │                              │
│              └────────────────┘                              │
└─────────────────────────────────────────────────────────────┘
                        │
                        │ (Events → States)
                        ▼
┌─────────────────────────────────────────────────────────────┐
│                    DOMAIN LAYER                              │
│  (Business Logic, Entities, Use Cases)                       │
│                                                              │
│              ┌──────────────────┐                            │
│              │ LocationEntity   │                            │
│              │ (Data Model)     │                            │
│              └──────────────────┘                            │
│                                                              │
│  Properties:                                                 │
│  - id: String                                               │
│  - name: String                                             │
│  - address: String                                          │
│  - managerId: String                                        │
│  - managerName: String                                      │
│  - isActive: bool                                           │
│  - createdAt/updatedAt: DateTime                            │
└─────────────────────────────────────────────────────────────┘
                        │
                        │ (Repository Interface)
                        ▼
┌─────────────────────────────────────────────────────────────┐
│                    DATA LAYER                                │
│  (Repositories, DataSources, API, Local DB)                 │
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │     API      │  │   Local DB   │  │ Preferences  │      │
│  │ DataSource   │  │ DataSource   │  │ DataSource   │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│                                                              │
│  └──────── LocationRepository (Implementation) ─────────┘   │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔄 Data Flow - Load Locations

```
User Action (App Start)
         │
         ▼
   LoadLocationsRequested (Event)
         │
         ├─────────────────────────────────────────┐
         │                                         │
         ▼                                         ▼
  LocationLoading (State)                 [BLoC Processing]
  (UI shows spinner)                              │
                                                  │
                                        ┌─────────▼──────────┐
                                        │  Repository Call   │
                                        │ (Future Implementation)
                                        └─────────┬──────────┘
                                                  │
                                    ┌─────────────▼──────────────┐
                                    │  Mock Data (Currently)      │
                                    │  - Kho Quận 1 (Active)     │
                                    │  - Kho Thủ Đức (Active)    │
                                    └─────────────┬──────────────┘
                                                  │
                                                  ▼
                                        LocationsLoaded (State)
                                                  │
                                                  ▼
                                        [UI Renders List]
                                        - LocationCard widgets
                                        - Toggle switches
                                        - Edit buttons
```

---

## 🔄 Data Flow - Toggle Location Status

```
User taps Toggle Switch
         │
         ▼
ToggleLocationStatusRequested (Event)
  - locationId: '1'
  - isActive: false
         │
         ├──────────────────────────────────────┐
         │                                      │
         ▼                                      ▼
LocationToggleInProgress (State)    [BLoC Processing]
(UI disables switch)                         │
                                            │
                                  ┌─────────▼──────────┐
                                  │ Repository.toggle  │
                                  │ (Future Call)      │
                                  └─────────┬──────────┘
                                           │
                                           ▼
                                  Success/Failure
                                           │
                    ┌─────────────────────┬──────────────────┐
                    │                     │                  │
                    ▼                     ▼                  ▼
            LocationToggleSuccess   LocationFailure    LocationError
            (Show success message)   (Show error)      (Show error)
                    │
                    ▼
            Update local state
            location.isActive = false
                    │
                    ▼
            LocationsLoaded (Re-render)
                    │
                    ▼
            [UI Updates]
            - Switch shows new state
            - Card becomes disabled (gray)
            - onTap becomes null
```

---

## 🔄 Data Flow - Add Location

```
User fills form and taps "Tạo kho"
         │
         ▼
   AddLocationRequested (Event)
         │
         ├─────────────────────────────────────┐
         │                                     │
         ▼                                     ▼
LocationAddInProgress (State)      [BLoC Processing]
(Button shows loading spinner)                │
                                             │
                                   ┌────────▼─────────┐
                                   │ Validation Check │
                                   │ (name, address)  │
                                   └────────┬─────────┘
                                           │
                        ┌──────────────────┴──────────────────┐
                        │                                     │
                 Validation Failed                    Validation OK
                        │                                     │
                        ▼                                     ▼
                LocationFailure                    Repository.add()
                (Show error toast)                  (Future Call)
                                                            │
                                                            ▼
                                                    Create LocationEntity
                                                    with isActive=true
                                                            │
                                                            ▼
                                                    LocationAddSuccess
                                                            │
                                                            ▼
                                                    Navigate back
                                                    (LocationsLoaded)
                                                            │
                                                            ▼
                                                    [List Updates]
                                                    New location appears
```

---

## 🔄 Data Flow - Edit Location

```
User taps Edit button → Navigate to AddEditLocationPage
         │
         ▼
   Form pre-filled with current data
         │
         ▼
User modifies and taps "Cập nhật"
         │
         ▼
EditLocationRequested (Event)
         │
         ├────────────────────────────────────┐
         │                                    │
         ▼                                    ▼
LocationEditInProgress             [BLoC Processing]
(Button shows loading)                      │
                                           │
                              ┌────────────▼──────────┐
                              │  Repository.update()  │
                              │  (Future Call)        │
                              └────────────┬──────────┘
                                           │
                                           ▼
                              LocationEditSuccess
                                           │
                                           ▼
                              Navigate back
                              (LocationsLoaded)
                                           │
                                           ▼
                              [List Updates]
                              Card displays new data
```

---

## 🎯 State Management Flow

```
┌──────────────────────────────────────────────────────────┐
│                   LocationBloc                            │
│                                                           │
│  Initial State: LocationInitial                          │
│                                                           │
│  ┌─────────────────────────────────────────────────┐    │
│  │ Event Handlers (on<EventName>)                  │    │
│  │                                                  │    │
│  │ 1. on<LoadLocationsRequested>                   │    │
│  │    → LocationLoading                            │    │
│  │    → [API Call]                                 │    │
│  │    → LocationsLoaded(locations)                 │    │
│  │                                                  │    │
│  │ 2. on<ToggleLocationStatusRequested>            │    │
│  │    → LocationToggleInProgress                   │    │
│  │    → [API Call]                                 │    │
│  │    → LocationToggleSuccess                      │    │
│  │    → LocationsLoaded (with updated list)        │    │
│  │                                                  │    │
│  │ 3. on<AddLocationRequested>                     │    │
│  │    → LocationAddInProgress                      │    │
│  │    → [Validation]                               │    │
│  │    → [API Call]                                 │    │
│  │    → LocationAddSuccess                         │    │
│  │    → LocationsLoaded (with new location)        │    │
│  │                                                  │    │
│  │ 4. on<EditLocationRequested>                    │    │
│  │    → LocationEditInProgress                     │    │
│  │    → [API Call]                                 │    │
│  │    → LocationEditSuccess                        │    │
│  │    → LocationsLoaded (with updated location)    │    │
│  │                                                  │    │
│  │ 5. on<DeleteLocationRequested>                  │    │
│  │    → LocationDeleteInProgress                   │    │
│  │    → [API Call]                                 │    │
│  │    → LocationDeleteSuccess                      │    │
│  │    → LocationsLoaded (without deleted location) │    │
│  └─────────────────────────────────────────────────┘    │
│                                                           │
│  Error Handling:                                          │
│  Any Exception → LocationFailure(message)                │
│  Emits → LocationError(message) to stop stream           │
└──────────────────────────────────────────────────────────┘
```

---

## 📱 UI Update Flow

```
LocationsLoaded State
         │
         ▼
BlocBuilder<LocationBloc, LocationState>
         │
    ┌────┴────┐
    │          │
    ▼          ▼
 Check    [locations list]
 State        │
    │         ▼
    ├─→ ListView.builder
    │        │
    │        ├─→ LocationCard(
    │        │     location: location,
    │        │     onTap: () { navigate to products }
    │        │     onToggleStatus: () { add ToggleEvent }
    │        │     onEdit: () { navigate to edit page }
    │        │     onAddManager: () { show dialog }
    │        │   )
    │        │
    │        └─→ [Rebuild UI for each location]
    │
    └─→ Show Empty State (if no locations)
```

---

## 🔌 Integration Points (Future)

### 1. **API Integration**
```dart
// Replace mock data in LocationBloc._locations
// with real API calls:
Future<List<LocationEntity>> getLocations() {
  return locationRepository.getLocations();
}
```

### 2. **Database Integration**
```dart
// Cache locations in local DB:
Future<void> saveLocationsLocally(
  List<LocationEntity> locations
) {
  return localDataSource.saveLocations(locations);
}
```

### 3. **Navigation Integration**
```dart
// Implement navigation routes:
onTap: () {
  Navigator.pushNamed(
    context, 
    '/products',
    arguments: {'locationId': location.id}
  );
}
```

### 4. **Dialog Integration**
```dart
// Add manager assignment:
onAddManager: () {
  showDialog(
    context: context,
    builder: (context) => AddManagerDialog(
      locationId: location.id,
    ),
  );
}
```

---

## 📊 Entity Relationships

```
LocationEntity
├── id (Primary Key)
├── name
├── address
├── managerId (Foreign Key → User/Manager)
├── managerName (Denormalized for display)
├── isActive (Status flag)
└── timestamps (createdAt, updatedAt)

[Future]
├── ManagerEntity
│   ├── id
│   ├── name
│   ├── email
│   └── phone
│
└── ProductEntity
    ├── id
    ├── name
    ├── locationId (Foreign Key)
    ├── price
    └── quantity
```

---

## 🎯 Key Design Decisions

1. **Separation of Concerns**: UI, Business Logic, Data - hoàn toàn tách biệt
2. **Mock Data**: Dễ dàng thay thế bằng API calls sau
3. **Equatable**: Value equality cho Events/States (so sánh dễ dàng)
4. **Immutability**: Entities sử dụng copyWith để tránh mutations
5. **Error Handling**: Centralized error handling trong BLoC

---

**Diagram Created**: January 29, 2026  
**For**: Location Management Feature (SC-LOC)  
**Architecture**: Clean Architecture + BLoC Pattern
