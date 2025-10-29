# 🚀 Refactoring Progress Tracker

**Started:** 2025-01-XX
**Last Updated:** Starting Phase 1

---

## 📊 Overall Progress

- [x] Phase 1: Extract Domain Models
- [ ] Phase 2: Create Repository Layer
- [ ] Phase 3: Build CheckInViewModel
- [ ] Phase 4: Refactor Authentication
- [ ] Phase 5: Update Other Views
- [ ] Phase 6: Cleanup

**Estimated Completion:** 17% (1/6 phases)

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

## ⏸️ Phase 2: Create Repository Layer

**Status:** 🔴 NOT STARTED

**Tasks:**
- [ ] Create `domain/repositories/` directory
- [ ] Create `AttendanceRepositoryProtocol.swift`
- [ ] Create `data/repositories/` directory
- [ ] Create `AttendanceRepository.swift` (singleton implementation)
- [ ] Create `data/datasources/` directory
- [ ] Refactor `SupabaseService` → `SupabaseDataSource.swift`
- [ ] Implement repository with in-memory caching
- [ ] Move realtime subscription logic into repository
- [ ] Test repository methods work correctly
- [ ] Verify realtime updates still function

**Notes:**
- Repository is singleton, created once at app level
- Repository holds @Published arrays of members and dates
- DataSource is pure, no @Published properties
- DataSource methods should throw, not return Bool

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

*None yet*

---

## 💡 Ideas / Future Improvements

- Add unit tests for repository
- Add unit tests for ViewModels
- Consider adding a DependencyContainer for better DI
- Add error types instead of using generic Error
- Add logging service for better debugging

---

## 📝 Session Notes

### Session 1 (Current)
- Created refactoring plan
- Created progress tracker
- ✅ COMPLETED Phase 1: Extract Domain Models
  - Created `domain/models/` directory
  - Extracted `Member.swift` with fullName computed property
  - Extracted `AttendanceDate.swift` 
  - Extracted `Attendance.swift` and `AttendanceRecord`
  - Updated Supabase.swift to remove model definitions
  - No compilation errors - all models accessible within same module
  - Ready to start Phase 2