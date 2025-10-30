# New Members Check In - Unit Tests

This directory contains unit tests for the New Members Check In app, focusing on the MVVM architecture introduced in Phase 3.

## 📋 What's Tested

### CheckInViewModel Tests
- ✅ **Initialization** - Proper initial state
- ✅ **Data Loading** - Success and failure scenarios
- ✅ **Member Selection** - Single and multiple selections
- ✅ **Check-In Flow** - Complete success, partial failure, complete failure
- ✅ **Validation** - No selection, too many members, no date scheduled
- ✅ **Computed Properties** - todayDate, uncheckedMembers, filteredMembers, etc.
- ✅ **Search/Filter** - Member filtering by name
- ✅ **Special Features** - Logout command detection
- ✅ **Graceful Error Handling** - Network failures, partial successes

**Total Tests: 20+**

---

## 🚀 Setting Up Tests in Xcode

### Step 1: Add Test Target (If Not Already Added)

1. Open your project in **Xcode**
2. Click on the **project** in the navigator (top of file list)
3. At the bottom of the targets list, click the **"+"** button
4. Select **"Unit Testing Bundle"** (NOT UI Testing)
5. Configure:
   - Product Name: `New Members Check InTests`
   - Target to be Tested: `New Members Check In`
   - Language: Swift
6. Click **Finish**

### Step 2: Add Test Files to Target

1. In the Project Navigator, find the `New Members Check InTests` folder
2. Make sure these files are included:
   - `CheckInViewModelTests.swift`
   - `MockAttendanceRepository.swift`
   - `README.md` (this file)

3. For each file, check the **File Inspector** (right sidebar)
4. Under "Target Membership", ensure `New Members Check InTests` is checked

### Step 3: Enable Testability

1. Select your **app target** (`New Members Check In`)
2. Go to **Build Settings** tab
3. Search for: `Enable Testability`
4. Set to **Yes** for the **Debug** configuration

### Step 4: Configure Test Target Build Settings

1. Select the **test target** (`New Members Check InTests`)
2. Go to **Build Phases** tab
3. Expand **"Link Binary With Libraries"**
4. Ensure `XCTest.framework` is present
5. Go to **Build Settings** tab
6. Search for: `Other Swift Flags`
7. Add: `-enable-testing` (if not already present)

---

## ▶️ Running Tests

### Run All Tests

**Option 1: Using Test Navigator**
1. Press `⌘ + 6` (or View → Navigators → Show Test Navigator)
2. Click the ▶️ button next to `New Members Check InTests`

**Option 2: Using Menu**
1. Product → Test (or press `⌘ + U`)

**Option 3: Using Keyboard**
- Press `⌘ + U` anywhere in Xcode

### Run Specific Test Class

1. Open `CheckInViewModelTests.swift`
2. Click the diamond icon in the gutter next to the class name
3. Or: `⌘ + U` while viewing the file

### Run Single Test Method

1. Click the diamond icon in the gutter next to a specific test method
2. Or: Place cursor in the test method and press `⌘ + U`

---

## 🎯 Test Results

### Viewing Results

After running tests, you'll see:
- ✅ **Green checkmarks** = Tests passed
- ❌ **Red X marks** = Tests failed
- Test duration for each test
- Overall pass/fail count

### Test Output

Open the **Report Navigator** (`⌘ + 9`) to see:
- Detailed test logs
- Print statements from tests
- Failure messages and stack traces

---

## 📝 Understanding the Tests

### Mock Repository Pattern

We use `MockAttendanceRepository` to simulate the data layer without hitting real APIs:

```swift
// Create mock with test data
let mockRepo = MockAttendanceRepository()
mockRepo.members = [/* test members */]
mockRepo.dates = [/* test dates */]

// Inject into ViewModel
let viewModel = CheckInViewModel(repository: mockRepo)

// Simulate errors
mockRepo.shouldThrowError = true
await viewModel.performCheckIn()
// Now we can test error handling!
```

### Test Structure

Each test follows the **Arrange-Act-Assert** pattern:

```swift
func testPerformCheckInSuccess() async throws {
    // Arrange (Given): Set up test data
    await viewModel.loadData()
    viewModel.toggleMemberSelection(member)
    
    // Act (When): Perform the action
    await viewModel.performCheckIn()
    
    // Assert (Then): Verify the results
    XCTAssertTrue(mockRepository.wasCheckedIn(...))
    XCTAssertTrue(viewModel.selectedMembers.isEmpty)
}
```

---

## 🔧 Adding New Tests

### 1. Add Test Method

```swift
func testMyNewFeature() async throws {
    // Given: Setup
    
    // When: Action
    
    // Then: Assertions
    XCTAssertEqual(expected, actual)
}
```

### 2. Common Assertions

```swift
// Equality
XCTAssertEqual(value1, value2)
XCTAssertNotEqual(value1, value2)

// Boolean
XCTAssertTrue(condition)
XCTAssertFalse(condition)

// Nil checking
XCTAssertNil(value)
XCTAssertNotNil(value)

// Errors
XCTAssertThrowsError(try function())
XCTAssertNoThrow(try function())

// Custom messages
XCTAssertEqual(a, b, "Values should match")
```

### 3. Async Testing

For async functions, use `async throws`:

```swift
func testAsyncOperation() async throws {
    await viewModel.performCheckIn()
    // Assertions after async completes
}
```

---

## 🐛 Troubleshooting

### "No such module 'New_Members_Check_In'"

**Solution:**
1. Go to app target → Build Settings
2. Search: "Enable Testability"
3. Set to **Yes** for Debug
4. Clean build folder: `⌘ + Shift + K`
5. Rebuild: `⌘ + B`

### Tests Not Found

**Solution:**
1. Ensure test files have `New Members Check InTests` in Target Membership
2. Test class must inherit from `XCTestCase`
3. Test methods must start with `test`
4. Clean and rebuild

### "Cannot find 'Member' in scope"

**Solution:**
- Add `@testable import New_Members_Check_In` at top of test file
- Make sure models are `public` or `internal` (not `private`)

### Simulator Issues

**Solution:**
- Choose a simulator: Product → Destination → iPhone 15 Pro
- Reset simulator: Device → Erase All Content and Settings

---

## 📊 Test Coverage

### Current Coverage

- ✅ CheckInViewModel: ~90% code coverage
- ⏸️ CheckInView: Not tested (SwiftUI views require UI tests)
- ⏸️ Repository: Tested indirectly via ViewModel tests
- ⏸️ DataSource: Not tested (would require integration tests)

### Future Test Additions

Consider adding tests for:
- [ ] MissingMembersView functionality
- [ ] Authentication flow
- [ ] Real repository with mocked SupabaseDataSource
- [ ] UI tests for critical user flows

---

## 🎓 Best Practices

### DO ✅

- Keep tests fast (< 1 second each)
- Test one thing per test method
- Use descriptive test names (`testPerformCheckInWithNoSelection`)
- Reset state in `setUp()` and `tearDown()`
- Use mocks for external dependencies

### DON'T ❌

- Make real network calls in unit tests
- Test SwiftUI view rendering (use UI tests instead)
- Depend on test execution order
- Leave commented-out tests
- Test implementation details (test behavior, not internals)

---

## 📚 Resources

- [XCTest Documentation](https://developer.apple.com/documentation/xctest)
- [Testing in Swift](https://www.swift.org/blog/testing/)
- [Async Testing Guide](https://developer.apple.com/documentation/xctest/asynchronous_tests_and_expectations)

---

## ✅ Success Criteria

Your tests are working correctly when:
- ✅ All tests pass (green checkmarks)
- ✅ Tests run in < 5 seconds total
- ✅ Can run `⌘ + U` anytime and tests pass
- ✅ Tests catch bugs when you break the code
- ✅ Tests document how the ViewModel should behave

---

**Status:** Tests ready to run! Press `⌘ + U` to get started. 🚀