# 📋 Refactoring Plan: New Members Check In App

## Current State Analysis

### 🔴 **Major Issues Identified**

1. **No Repository Layer**: Views directly instantiate and call `SupabaseService` 
   - `CheckInView` creates its own instance: `@StateObject var supabase = SupabaseService()`
   - `MissingMembersView` does the same
   - Each view has its own separate instance (not shared state!)
   - Impossible to mock for testing

2. **CheckInView is Massive** (~220 lines doing everything):
   - Data fetching
   - State management (7+ @State properties)
   - Business logic (filtering, date matching)
   - Realtime subscription management
   - UI rendering
   - Violates Single Responsibility Principle

3. **Mixed Concerns**:
   - `SupabaseService` is an `ObservableObject` mixing data fetching with UI state
   - `AuthUser` handles both authentication AND navigation state
   - Data models (`Member`, `AttendanceDate`) defined inside service file

4. **Tight Coupling**:
   - Views know about Supabase implementation details
   - Can't swap data sources without rewriting views
   - No abstraction layer

5. **Realtime Subscriptions Managed in Views**:
   - Views calling `subscribeToMembers()`, `unsubscribeAll()` directly
   - Should be internal to repository

6. **Dead Code**:
   - `Airtable.swift` and `Records.swift` (old implementation)
   - Empty `data/cache` and `data/service` folders

---

## 🎯 Refactoring Goals

✅ **Create clean Repository layer** that abstracts all Supabase operations  
✅ **Build proper CheckInViewModel** with all business logic  
✅ **Separate authentication from navigation**  
✅ **Enable testability** through dependency injection  
✅ **Keep data in memory** (offline support out of scope)  
✅ **Maintain current functionality** (zero regressions)

---

## 🏗️ Target Architecture

```
┌─────────────────────────────────────┐
│   App Entry Point                   │
│   New_Members_Check_InApp.swift     │
└────────────┬────────────────────────┘
             │
┌────────────▼────────────────────────┐
│   PRESENTATION LAYER                │
│   ├─ Views (SwiftUI)                │
│   ├─ ViewModels (business logic)    │
│   └─ Coordinators (navigation)      │
└────────────┬────────────────────────┘
             │
┌────────────▼────────────────────────┐
│   DOMAIN LAYER                      │
│   ├─ Models (Member, Attendance)    │
│   ├─ Services (Authentication)      │
│   └─ Repository Protocols           │
└────────────┬────────────────────────┘
             │
┌────────────▼────────────────────────┐
│   DATA LAYER                        │
│   ├─ Repository Implementations     │
│   ├─ Data Sources (Supabase)        │
│   └─ Utilities (Keychain, Config)   │
└─────────────────────────────────────┘
```

---

## 📝 Implementation Plan

### **Phase 1: Extract Domain Models** ✅
*Create clean separation of concerns*

**New Files to Create:**
```
domain/
  models/
    - Member.swift              [Extract from Supabase.swift]
    - AttendanceDate.swift      [Extract from Supabase.swift]  
    - Attendance.swift          [Extract from Supabase.swift]
```

**What to do:**
- Move `Member`, `AttendanceDate`, `Attendance`, `AttendanceRecord` structs
- Keep them pure data models (Codable, Identifiable)
- Add any computed properties or helpers

---

### **Phase 2: Create Repository Layer**
*Abstract all data access behind clean interface*

**New Files to Create:**
```
domain/
  repositories/
    - AttendanceRepositoryProtocol.swift   [Interface/Protocol]

data/
  repositories/
    - AttendanceRepository.swift           [Concrete implementation]
  datasources/
    - SupabaseDataSource.swift             [Refactored SupabaseService]
```

**AttendanceRepositoryProtocol.swift** should define:
```swift
protocol AttendanceRepositoryProtocol {
    // Observable data
    var members: [Member] { get }
    var dates: [AttendanceDate] { get }
    var membersPublisher: Published<[Member]>.Publisher { get }
    var datesPublisher: Published<[AttendanceDate]>.Publisher { get }
    
    // Data operations
    func loadMembers() async throws
    func loadDates() async throws
    func getAttendanceForDate(dateId: Int) async throws -> Set<Int>
    func checkInMember(memberId: Int, dateId: Int) async throws
    
    // Lifecycle
    func startRealtimeSync() async
    func stopRealtimeSync()
}
```

**AttendanceRepository.swift** (Singleton):
- Implements the protocol
- Holds in-memory arrays of members and dates
- Uses `SupabaseDataSource` internally
- Manages realtime subscriptions (hidden from views)
- Thread-safe with `@MainActor`
- Single source of truth

**SupabaseDataSource.swift**:
- Rename/refactor current `SupabaseService`
- Remove `@Published` properties (repository handles that)
- Make methods throw instead of returning Bool
- Pure data fetching, no state

---

### **Phase 3: Build CheckInViewModel**
*Move ALL business logic out of the view*

**New File to Create:**
```
presentation/
  check in/
    - CheckInViewModel.swift
```

**CheckInViewModel.swift** responsibilities:
```swift
@MainActor
class CheckInViewModel: ObservableObject {
    // Dependencies (injected)
    private let repository: AttendanceRepositoryProtocol
    
    // Published state for the view
    @Published var searchText: String = ""
    @Published var selectedMembers: [Member] = []
    @Published var checkedInMemberIds: Set<Int> = []
    @Published var showingErrorAlert: Bool = false
    @Published var errorAlertMessage: String = ""
    @Published var showToast: Bool = false
    @Published var showLogoutAlert: Bool = false
    
    // Computed properties (business logic)
    var todayDate: AttendanceDate? { ... }
    var uncheckedMembers: [Member] { ... }
    var filteredMembers: [Member] { ... }
    var allMembersCheckedIn: Bool { ... }
    
    // Actions
    func loadData() async { ... }
    func toggleMemberSelection(_ member: Member) { ... }
    func performCheckIn() async { ... }
    func checkForLogoutCommand() { ... }
}
```

**Modify CheckInView.swift**:
- Becomes ~50-80 lines (just SwiftUI)
- No business logic
- No direct Supabase calls
- Just observes ViewModel and calls methods

```swift
struct CheckInView: View {
    @StateObject private var viewModel: CheckInViewModel
    @EnvironmentObject var user: AuthUser
    
    init(repository: AttendanceRepositoryProtocol) {
        _viewModel = StateObject(wrappedValue: CheckInViewModel(repository: repository))
    }
    
    var body: some View {
        // Pure UI based on viewModel.* properties
    }
}
```

---

### **Phase 4: Refactor Authentication**
*Separate auth logic from navigation*

**New File to Create:**
```
domain/
  services/
    - AuthenticationService.swift
```

**AuthenticationService.swift**:
- Singleton managing auth state
- Uses SupabaseClient and KeychainManager
- Methods: `signIn()`, `signOut()`, `restoreSession()`
- Published properties: `isAuthenticated`, `userEmail`

**Modify AuthUser.swift**:
- **Option A**: Keep it as-is but inject `AuthenticationService`
- **Option B**: Rename to `AppCoordinator` and split authentication out entirely
- Remove direct Supabase calls
- Focus on navigation state only OR merge with authentication service

---

### **Phase 5: Update Other Views**
*Apply repository pattern consistently*

**Modify MissingMembersView.swift**:
- Remove `@StateObject var supabase`
- Inject shared `AttendanceRepository` instance
- Use repository methods
- Could create simple ViewModel if logic grows, but probably fine as-is

**Modify HomepageView.swift**:
- Inject repository to child views
- Clean up navigation patterns if needed

**Modify ContentView.swift**:
- Create repository singleton
- Inject into view hierarchy via `@EnvironmentObject` or direct passing
- Consider creating a DependencyContainer

---

### **Phase 6: Cleanup**
*Remove dead code and reorganize*

**Delete:**
- `data/remote/Airtable.swift` ❌
- `data/remote/Records.swift` ❌

**Move:**
- `data/remote/Config.swift` → `data/configuration/SupabaseConfig.swift`
- `data/remote/Supabase.swift` → becomes `SupabaseDataSource.swift`

**Folder structure cleanup:**
- Remove empty `data/cache` and `data/service` folders
- Organize by layer (domain, data, presentation)

---

## 📁 Final File Structure

```
New Members Check In/
├── New_Members_Check_InApp.swift
├── domain/
│   ├── models/
│   │   ├── Member.swift
│   │   ├── AttendanceDate.swift
│   │   └── Attendance.swift
│   ├── repositories/
│   │   └── AttendanceRepositoryProtocol.swift
│   └── services/
│       └── AuthenticationService.swift
├── data/
│   ├── repositories/
│   │   └── AttendanceRepository.swift
│   ├── datasources/
│   │   └── SupabaseDataSource.swift
│   ├── configuration/
│   │   └── SupabaseConfig.swift
│   └── utilities/
│       ├── KeychainManager.swift
│       ├── Date.swift
│       └── HexColorExtension.swift
└── presentation/
    ├── authentication/
    │   ├── AuthUser.swift (or AppCoordinator.swift)
    │   └── AuthenticationView.swift
    ├── check in/
    │   ├── CheckInView.swift (simplified)
    │   ├── CheckInViewModel.swift ⭐ NEW
    │   └── components/
    │       ├── CCCTitleView.swift
    │       ├── Checklist.swift
    │       ├── SearchbarView.swift
    │       └── SuccessToast.swift
    ├── missing members/
    │   └── MissingMembersView.swift
    ├── ContentView.swift
    └── HomepageView.swift
```

---

## 🎁 Benefits of This Refactor

✅ **Testability**: Can mock `AttendanceRepositoryProtocol` for unit tests  
✅ **Maintainability**: Each file has one clear responsibility  
✅ **Debuggability**: Repository is single source of truth, easier to debug  
✅ **Flexibility**: Can swap Supabase for different backend without touching views  
✅ **Readability**: CheckInView goes from 220 lines → ~60 lines  
✅ **Reusability**: Repository can be used by any view/ViewModel  
✅ **Type Safety**: Repository interface enforces consistent API  

---

## 🚀 Implementation Strategy

**Recommended Order:**
1. **Phase 1** (Models) - Low risk, no logic changes
2. **Phase 2** (Repository) - Core infrastructure, test thoroughly
3. **Phase 3** (CheckInViewModel) - Big win, lots of cleanup
4. **Phase 4** (Auth refactor) - Independent, can be done anytime
5. **Phase 5** (Other views) - Quick wins after repository exists
6. **Phase 6** (Cleanup) - Final polish

**Time Estimate:**
- Phase 1: 30-45 minutes
- Phase 2: 1.5-2 hours (most complex)
- Phase 3: 1-1.5 hours
- Phase 4: 45 minutes-1 hour
- Phase 5: 30-45 minutes
- Phase 6: 15-30 minutes

**Total: ~5-6 hours of focused work**

---

## ⚠️ Migration Notes

1. **Shared Repository Instance**: Create repository once at app level, share everywhere
2. **Realtime Subscriptions**: Start in repository on app launch, views just observe
3. **Error Handling**: Repository should throw specific errors, ViewModels catch and present
4. **Thread Safety**: Keep `@MainActor` on repository and ViewModels
5. **Testing**: Start writing tests for repository immediately after Phase 2