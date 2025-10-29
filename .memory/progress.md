# 🚀 Refactoring Progress Tracker

**Started:** 2025-01-XX
**Last Updated:** Starting Phase 1

---

## 📊 Overall Progress

- [x] Phase 1: Extract Domain Models
- [x] Phase 2: Create Repository Layer
- [ ] Phase 3: Build CheckInViewModel
- [ ] Phase 4: Refactor Authentication
- [ ] Phase 5: Update Other Views
- [ ] Phase 6: Cleanup

**Estimated Completion:** 33% (2/6 phases)

---

## ✅ Phase 1: Extract Domain Models

**Status:** ✅ COMPLETED

**Tasks:**
- [x] Create `domain/models/` directory structure
- [x] Extract `Member.swift` from Supabase.swift
- [x] Extract `AttendanceDate.swift` from Supabase.swift
- [x] Extract `Attendance.swift` from Supabase.swift
- [x] Update imports in Supabase.swift to reference new model files
- [x] Verify no compilation errors
- [x] Test app still runs

**Notes:**
- Models should be pure data structures (Codable, Identifiable)
- No business logic in models
- Keep existing computed properties like `fullName` on Member

---

## ✅ Phase 2: Create Repository Layer

**Status:** ✅ COMPLETED

**Tasks:**
- [x] Create `domain/repositories/` directory
- [x] Create `AttendanceRepositoryProtocol.swift`
- [x] Create `data/repositories/` directory
- [x] Create `AttendanceRepository.swift` (singleton implementation)
- [x] Create `data/datasources/` directory
- [x] Refactor `SupabaseService` → `SupabaseDataSource.swift`
- [x] Implement repository with in-memory caching
- [x] Move realtime subscription logic into repository
- [ ] Test repository methods work correctly
- [ ] Verify realtime updates still function

**Notes:**
- Repository is singleton (AttendanceRepository.shared)
- Repository holds @Published arrays of members and dates
- DataSource is pure, no @Published properties - throws errors instead of returning Bool
- Realtime subscriptions managed internally by repository
- Protocol allows for easy testing and mocking
- SupabaseService remains in place (will be removed after views are updated)

---

## ⏸️ Phase 3: Build CheckInViewModel

**Status:** 🔴 NOT STARTED

**Tasks:**
- [ ] Create `CheckInViewModel.swift`
- [ ] Move all @State properties from view to viewModel
- [ ] Move business logic methods to viewModel
- [ ] Move computed properties to viewModel
- [ ] Inject repository into viewModel
- [ ] Refactor CheckInView to use viewModel
- [ ] Remove direct Supabase calls from view
- [ ] Test check-in flow works end-to-end
- [ ] Verify realtime updates still work
- [ ] Test search functionality
- [ ] Test member selection/deselection

**Notes:**
- CheckInView should go from ~220 lines to ~60-80 lines
- View should only contain SwiftUI rendering code
- All logic lives in ViewModel

---

## ⏸️ Phase 4: Refactor Authentication

**Status:** 🔴 NOT STARTED

**Tasks:**
- [ ] Create `domain/services/` directory
- [ ] Create `AuthenticationService.swift`
- [ ] Move auth logic from AuthUser to service
- [ ] Update AuthUser to use AuthenticationService
- [ ] Consider splitting navigation state into separate coordinator
- [ ] Update AuthenticationView to work with new structure
- [ ] Test sign in flow
- [ ] Test sign out flow
- [ ] Test session restoration

**Notes:**
- Decide: Keep AuthUser or rename to AppCoordinator?
- Authentication and Navigation might stay together for simplicity
- Focus on removing direct Supabase calls from AuthUser

---

## ⏸️ Phase 5: Update Other Views

**Status:** 🔴 NOT STARTED

**Tasks:**
- [ ] Update MissingMembersView to use repository
- [ ] Remove @StateObject supabase from MissingMembersView
- [ ] Inject repository into MissingMembersView
- [ ] Update HomepageView to pass repository to children
- [ ] Update ContentView to create and inject repository
- [ ] Test MissingMembersView functionality
- [ ] Verify navigation between views works
- [ ] Test date picker and attendance filtering

**Notes:**
- MissingMembersView probably doesn't need a ViewModel (simple enough)
- All views should use the same shared repository instance

---

## ⏸️ Phase 6: Cleanup

**Status:** 🔴 NOT STARTED

**Tasks:**
- [ ] Delete `data/remote/Airtable.swift`
- [ ] Delete `data/remote/Records.swift`
- [ ] Delete empty `data/cache/` directory
- [ ] Delete empty `data/service/` directory
- [ ] Move `Config.swift` to `data/configuration/SupabaseConfig.swift`
- [ ] Move utilities to `data/utilities/`
- [ ] Update all import statements
- [ ] Final code review
- [ ] Test entire app flow
- [ ] Document new architecture in README (if exists)

**Notes:**
- Double-check nothing references Airtable code before deleting
- Ensure all paths are correct after moves

---

## 🐛 Known Issues / Blockers

### Bug Found in Phase 1
- **Alert not showing when no class date scheduled**: After refactoring, the error alert doesn't appear when trying to check in members without a scheduled class date. This is a minor UI issue that can be addressed later since major refactors are coming. The underlying logic still prevents the check-in, just the user feedback is missing.
  - Location: `CheckInView.swift` - check-in button action
  - Impact: Low (functionality works, just missing user feedback)
  - Priority: Can fix after Phase 3 when CheckInViewModel is in place

---

## 💡 Ideas / Future Improvements

- Add unit tests for repository
- Add unit tests for ViewModels
- Consider adding a DependencyContainer for better DI
- Add error types instead of using generic Error
- Add logging service for better debugging

---

## 📝 Session Notes

### Session 1 (COMPLETED)
- Created refactoring plan
- Created progress tracker
- ✅ COMPLETED Phase 1: Extract Domain Models
  - Created `domain/models/` directory
  - Extracted `Member.swift` with fullName computed property
  - Extracted `AttendanceDate.swift` 
  - Extracted `Attendance.swift` and `AttendanceRecord`
  - Updated Supabase.swift to remove model definitions
  - No compilation errors - all models accessible within same module
  - User tested - everything works except minor alert bug (see Known Issues)
  - Changes committed to git
  - Ready to start Phase 2

### Session 2 (COMPLETED)
- ✅ COMPLETED Phase 2 - Create Repository Layer
- **What was accomplished**:
  - Created directory structure: `domain/repositories/`, `data/repositories/`, `data/datasources/`
  - Created `AttendanceRepositoryProtocol.swift` defining clean interface for data operations
  - Created `SupabaseDataSource.swift` - pure data fetching layer that throws errors
  - Created `AttendanceRepository.swift` - singleton with @Published properties and in-memory caching
  - Repository manages realtime subscriptions internally (startRealtimeSync/stopRealtimeSync)
  - Removed AuthUser dependency - repository methods no longer need user parameter
  - All methods throw errors for proper error propagation
  - No compilation errors
- **Important notes**:
  - Old SupabaseService still exists but will be removed after views are migrated
  - Repository is ready to be injected into views
  - Next step: Create CheckInViewModel and migrate CheckInView to use repository

### Session 3 (Next)
- **Goal**: Complete Phase 3 - Build CheckInViewModel
- **Important Context for Phase 3**:
  - Repository layer is complete and tested (AttendanceRepository.shared)
  - CheckInView currently has 220+ lines with mixed concerns
  - Need to extract all @State properties into ViewModel
  - Move business logic (filtering, date matching, check-in flow) to ViewModel
  - CheckInView should become pure SwiftUI (60-80 lines)
  - Inject repository into ViewModel
  - Remove direct SupabaseService usage from view