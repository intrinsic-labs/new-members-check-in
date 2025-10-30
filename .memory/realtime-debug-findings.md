# 🐛 Realtime Subscription Debugging - Findings & Fixes

**Date:** 2025-01-XX
**Issue:** App not receiving/reacting to real-time changes from Supabase

---

## 🔍 Problem Summary

The app was not receiving realtime updates when the Supabase database was modified from another location. Navigating away from and back to `CheckInView` would refresh the data (because everything reinitializes), but live updates while on the screen were not working.

**Neither subscription was working:**
- ❌ Members subscription (not working)
- ❌ Attendance subscription (not working)

---

## 📊 The Call Stack (How It's Supposed to Work)

1. **CheckInView.swift** (Line 104)
   - `.onAppear` → `await viewModel.startRealtimeSync()`

2. **CheckInViewModel.swift** (Line 127)
   - `startRealtimeSync()` → `await repository.startRealtimeSync()`

3. **AttendanceRepository.swift** (Lines 82-113)
   - `startRealtimeSync()` creates two subscriptions:
   - **Members subscription**: Callback reloads members & dates
   - **Attendance subscription**: Callback toggles `attendanceDidUpdate` boolean

4. **SupabaseDataSource.swift** (Lines 101 & 125)
   - `createMembersSubscription()` - Sets up channel & subscribes
   - `createAttendanceSubscription()` - Sets up channel & subscribes

5. **CheckInView.swift** (Lines 120-133)
   - `.onChange(of: repository.dates)` → triggers `viewModel.handleDatesChanged()`
   - `.onChange(of: repository.attendanceDidUpdate)` → triggers `viewModel.handleAttendanceUpdated()`

6. **CheckInViewModel.swift** (Lines 240-253)
   - `handleAttendanceUpdated()` → calls `await loadTodaysAttendance()`
   - This fetches fresh attendance data and updates `checkedInMemberIds`
   - SwiftUI reactivity causes the UI to update

---

## 🐛 Root Cause - THE REAL BUG: Discarded Subscription Objects

**Location:** `SupabaseDataSource.swift` Lines 107 & 130 (before fix)

### The Problem:
```swift
// WRONG - Subscription object is discarded! ❌
let _ = channel.onPostgresChange(
    AnyAction.self,
    schema: "public",
    table: "attendance"
) { change in
    // Callback here
}
```

**The subscription object returned by `onPostgresChange()` was being DISCARDED with `let _ =`**

### Why This Broke Everything:
- `onPostgresChange()` returns a `RealtimeSubscription` object
- **This object HOLDS the callback** - it's not just a reference
- When you discard it with `let _ =`, it gets deallocated immediately
- Once deallocated, the callback is destroyed and never fires
- You must store the `RealtimeSubscription` to keep it alive

### The Working Pattern (from old code):
```swift
// CORRECT - Store the subscription! ✅
membersSubscription = channel.onPostgresChange(
    AnyAction.self,
    schema: "public",
    table: "members"
) { [weak self] _ in
    // Callback here
}
```

---

## 🐛 Secondary Bug: View Observing Wrong Property

**Location:** `CheckInView.swift` Line 130 (before fix)

### The Problem:
```swift
// WRONG ❌
.onChange(of: viewModel.repository.attendanceDidUpdate) { _ in
    viewModel.handleAttendanceUpdated()
}

// CORRECT ✅
.onChange(of: repository.attendanceDidUpdate) { _ in
    viewModel.handleAttendanceUpdated()
}
```

**The view was trying to access `viewModel.repository`**, but:
- CheckInView already has a direct reference to `AttendanceRepository.shared`
- Both the view and viewModel are using the same shared instance
- This would have failed to observe changes properly

---

## 📚 Understanding the Two Supabase Realtime Patterns

The Supabase Swift SDK supports **two different patterns** for realtime subscriptions:

### Pattern 1: Async Stream (from documentation)
```swift
let changes = await myChannel.postgresChange(AnyAction.self, schema: "public")
await myChannel.subscribe()

for await change in changes {
  switch change {
  case .insert(let action): print(action)
  }
}
```

### Pattern 2: Callback-based (what you're using)
```swift
let subscription = channel.onPostgresChange(...) { change in
    // Handle change
}
await channel.subscribeWithError()
```

**Both patterns are valid!** The callback pattern is cleaner for SwiftUI apps because:
- No need to manage async loops
- Callbacks integrate well with `@Published` properties
- Easier to handle multiple subscriptions

**The critical requirement:** You MUST store the `RealtimeSubscription` object returned by `onPostgresChange()`

---

## ✅ Fixes Applied

### Fix #1: Store Subscription Objects (THE CRITICAL FIX)
**Files:** `SupabaseDataSource.swift` & `AttendanceRepository.swift`
- Changed return type from `RealtimeChannelV2` → `RealtimeSubscription`
- Store the subscription object: `let subscription = channel.onPostgresChange(...)`
- Return the subscription instead of discarding it
- Repository now stores `RealtimeSubscription` objects to keep callbacks alive
- Changed `stopRealtimeSync()` to call `subscription.cancel()` instead of `channel.unsubscribe()`

### Fix #2: Fix View Observation
**File:** `CheckInView.swift`
- Changed `viewModel.repository.attendanceDidUpdate` → `repository.attendanceDidUpdate`
- View now correctly observes the shared repository instance

### Fix #3: Enhanced Debug Logging
**Files:** `SupabaseDataSource.swift`
- Added comprehensive logging to both subscription methods
- Logs when channel is created
- Logs when subscription succeeds
- **Logs when realtime events are received** (this is key!)
- Logs when callbacks are invoked

---

## 🧪 Testing Instructions

### 1. Build and Run the App
- Open the app on your device/simulator
- Navigate to CheckInView
- Watch the Xcode console for subscription logs

**You should see:**
```
🎯 SupabaseDataSource: Creating members subscription channel...
📞 SupabaseDataSource: Calling subscribeWithError() for members...
🔄 SupabaseDataSource: ✅ Successfully subscribed to members table changes!

🎯 SupabaseDataSource: Creating attendance subscription channel...
📞 SupabaseDataSource: Calling subscribeWithError()...
🔄 SupabaseDataSource: ✅ Successfully subscribed to attendance table changes!
```

### 2. Test Attendance Realtime Updates
**From another device/browser:**
- Go to your Supabase dashboard
- Open the `attendance` table
- Manually insert a new attendance record (or update/delete one)

**Expected behavior:**
- Within 1-2 seconds, you should see console output:
```
🔥 SupabaseDataSource: RECEIVED REALTIME EVENT!
   Event type: [INSERT/UPDATE/DELETE]
📡 SupabaseDataSource: Calling onChange callback...
🔔 Repository: Attendance realtime update received!
🔔 Repository: attendanceDidUpdate toggled to [true/false]
✅ SupabaseDataSource: onChange callback completed
🔔 ViewModel: Attendance update detected from onChange!
🔄 ViewModel: Reloading today's check-ins...
📋 ViewModel: Today's attendance - X members checked in
```
- The CheckInView UI should update immediately (member disappears from unchecked list)

### 3. Test Members Realtime Updates
**From Supabase dashboard:**
- Add, update, or delete a member in the `members` table

**Expected behavior:**
- Console should show:
```
🔥 SupabaseDataSource: RECEIVED MEMBERS REALTIME EVENT!
📡 SupabaseDataSource: Members table changed, calling onChange callback...
✅ Repository: Loaded X members
✅ Repository: Loaded Y dates
```
- Member list should update in the app

### 4. Test Subscription Lifecycle
- Navigate away from CheckInView
- Should see: `⏸️ ViewModel: Stopped realtime sync`
- Navigate back to CheckInView
- Should see subscriptions restart

---

## 🚨 If It Still Doesn't Work

### Check Supabase Project Settings
1. Go to your Supabase project dashboard
2. Navigate to **Database** → **Replication**
3. Ensure realtime is **enabled** for:
   - `public.members` table
   - `public.attendance` table

### Check Console for Errors
Look for:
- ❌ Subscription errors
- Network errors
- Authentication issues

### Verify Network Connection
- Realtime uses WebSockets
- Some networks/firewalls block WebSocket connections
- Test on different networks (WiFi vs cellular)

### Check Supabase SDK Version
- Ensure you're using a recent version of `supabase-swift`
- The RealtimeV2 API is relatively new

---

## 📝 Architecture Notes

### Why the Toggle Pattern?
```swift
self.attendanceDidUpdate.toggle()
```

This is a clever pattern for triggering SwiftUI updates:
- SwiftUI's `.onChange()` fires when a value **changes**
- By toggling a Boolean, we guarantee a change every time
- The actual boolean value doesn't matter, just that it changed
- This signals the view to refetch attendance data

### Data Flow
```
Supabase DB Change
    ↓
WebSocket Event
    ↓
SupabaseDataSource callback
    ↓
AttendanceRepository toggles flag
    ↓
CheckInView observes change
    ↓
CheckInViewModel refetches data
    ↓
SwiftUI re-renders
```

### Why Not Update Data Directly?
You could reload attendance directly in the repository callback, but the current pattern has advantages:
- **Separation of concerns**: Repository just signals, ViewModel decides what to do
- **Flexibility**: Different views can react differently to the same event
- **Testability**: Easier to test the toggle signal vs. complex data fetching

---

## 🎯 Next Steps

1. **Test thoroughly** with the instructions above
2. If it works, **remove debug logging** (or reduce verbosity)
3. Consider adding **error handling** for subscription failures
4. Consider **retry logic** if subscription drops
5. Add **unit tests** for subscription callbacks

---

## 💡 Potential Improvements

### 1. More Granular Updates
Instead of toggling a boolean, you could pass the actual change:
```swift
@Published var latestAttendanceChange: AttendanceChange?

struct AttendanceChange {
    let action: ChangeAction // insert, update, delete
    let memberId: Int
    let dateId: Int
}
```
This would let you update the UI without refetching all data.

### 2. Connection Status
Add a published property to show connection state:
```swift
@Published var realtimeConnectionStatus: RealtimeStatus = .disconnected

enum RealtimeStatus {
    case connected
    case disconnected
    case connecting
    case error(String)
}
```

### 3. Automatic Reconnection
Handle network interruptions gracefully:
- Detect when subscription drops
- Automatically attempt to reconnect
- Show UI indicator when offline

---

## ✅ Summary

**Root cause:** Discarding the `RealtimeSubscription` objects returned by `onPostgresChange()` with `let _ =`

**Why it failed:** The subscription object holds the callback - when deallocated, callbacks stop firing

**Fix:** Store `RealtimeSubscription` objects in repository to keep them alive

**Testing:** Enhanced logging to verify events are received

**Expected result:** App should now receive and react to realtime changes immediately

**Key lesson:** In Supabase Swift SDK, you MUST keep a strong reference to `RealtimeSubscription` objects for callbacks to work!