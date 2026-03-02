# 🔗 Location Feature Navigation Flow

## 📱 Pages Connected

### 1. **LocationManagementPage** (SC-LOC-01)
↓
**Main page - Danh sách địa điểm kinh doanh**

#### Navigation Routes:
```
LocationManagementPage
├── [FAB Button - Add] → AddEditLocationPage (Create mode)
│
├── [LocationCard - onTap] → ProductManagementPage
│   └── Shows products for selected location
│
└── [LocationCard - onEdit] → AddEditLocationPage (Edit mode)
    └── Pre-filled with location data
```

---

## 🔄 Navigation Flows

### Flow 1: Thêm Địa Điểm Mới
```
LocationManagementPage
         ↓ [FAB Button]
    AddEditLocationPage
         ↓ [Form filled + Tạo kho button]
    BLoC: AddLocationRequested
         ↓ [Success]
    Back to LocationManagementPage
         ↓ [LocationsLoaded state]
    New location appears in list
```

### Flow 2: Sửa Địa Điểm
```
LocationManagementPage
         ↓ [LocationCard.onEdit]
    AddEditLocationPage (with location data)
         ↓ [Form modified + Cập nhật button]
    BLoC: EditLocationRequested
         ↓ [Success]
    Back to LocationManagementPage
         ↓ [LocationsLoaded state]
    Updated location appears in list
```

### Flow 3: Xem Sản Phẩm
```
LocationManagementPage
         ↓ [LocationCard.onTap] (only if isActive=true)
    ProductManagementPage
         ↓ locationId: location.id
         ↓ locationName: location.name
    [Back button] → LocationManagementPage
```

### Flow 4: Toggle Status
```
LocationManagementPage
         ↓ [LocationCard.Switch toggle]
    BLoC: ToggleLocationStatusRequested
         ↓ [Success]
    UI Updates immediately
    ↓ (if isActive=false)
    onTap becomes disabled
```

---

## 💻 Implementation Details

### LocationManagementPage Callbacks

```dart
// 1. onTap - Navigate to ProductManagementPage
LocationCard(
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductManagementPage(
          locationId: location.id,
          locationName: location.name,
        ),
      ),
    );
  },
)

// 2. onEdit - Navigate to AddEditLocationPage (Edit mode)
LocationCard(
  onEdit: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditLocationPage(
          location: location, // Pre-fill form
        ),
      ),
    );
  },
)

// 3. FAB - Navigate to AddEditLocationPage (Create mode)
FloatingActionButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEditLocationPage(),
      ),
    );
  },
)
```

### AddEditLocationPage

```dart
class AddEditLocationPage extends StatefulWidget {
  final LocationEntity? location; // null = Create mode

  const AddEditLocationPage({this.location});
}

// Logic:
if (widget.location != null) {
  // EDIT MODE
  // Form pre-filled with location data
  // Button shows "Cập nhật"
  // Event: EditLocationRequested
} else {
  // CREATE MODE
  // Empty form
  // Button shows "Tạo kho"
  // Event: AddLocationRequested
}
```

### ProductManagementPage

```dart
class ProductManagementPage extends StatefulWidget {
  final String locationId;      // For future product API calls
  final String locationName;    // Display in AppBar

  const ProductManagementPage({
    required this.locationId,
    required this.locationName,
  });
}

// Currently: Empty placeholder
// Future: Implement product list
```

---

## 🎯 User Journey

### Scenario 1: Create New Location
```
1. User taps FAB (+) button on LocationManagementPage
2. AddEditLocationPage opens (empty form)
3. User fills:
   - Tên Kho: "Kho Quận 7"
   - Địa Chỉ: "123 Đường ABC, Q.7"
   - Thêm Nhân Viên: "Nguyễn Văn C"
4. User taps "Tạo kho" button
5. BLoC: AddLocationRequested event
6. Success → Back to LocationManagementPage
7. New location appears at bottom of list
```

### Scenario 2: Edit Existing Location
```
1. User taps edit button (✏️) on LocationCard
2. AddEditLocationPage opens (form pre-filled)
3. User modifies:
   - Tên Kho: "Kho Quận 7 - Mở rộng"
4. User taps "Cập nhật" button
5. BLoC: EditLocationRequested event
6. Success → Back to LocationManagementPage
7. Updated location shows new info
```

### Scenario 3: View Products
```
1. User taps LocationCard body (only if isActive=true)
2. ProductManagementPage opens
3. Shows locationName in AppBar
4. Displays empty placeholder (ready for product list)
5. User taps back arrow
6. Returns to LocationManagementPage
```

### Scenario 4: Toggle Status
```
1. User taps toggle switch on LocationCard
2. Switch animates immediately
3. BLoC: ToggleLocationStatusRequested event
4. If isActive = false:
   - Card becomes grayed out
   - onTap callback disabled
5. Snackbar confirms: "Cập nhật trạng thái thành công"
```

---

## ✅ Navigation Status

| Route | Implementation | Status |
|-------|----------------|--------|
| LocationManagementPage → AddEditLocationPage (Create) | Navigator.push | ✅ Done |
| LocationManagementPage → AddEditLocationPage (Edit) | Navigator.push | ✅ Done |
| LocationManagementPage → ProductManagementPage | Navigator.push | ✅ Done |
| ProductManagementPage → LocationManagementPage | Navigator.pop (back) | ✅ Done |
| AddEditLocationPage → LocationManagementPage | Navigator.pop (success) | ✅ Done |

---

## 🚀 Future Enhancements

1. **Named Routes** - Replace Navigator.push with named routes
2. **Deep Linking** - Direct access via deep links
3. **Bottom Navigation** - Add to main navigation
4. **State Persistence** - Save form draft if back pressed
5. **Undo/Redo** - History for location changes

---

**Last Updated**: January 29, 2026  
**Feature**: Location Management Navigation  
**Status**: ✅ Fully Connected
