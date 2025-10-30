//
//  CheckInViewModelTests.swift
//  New Members Check InTests
//
//  Created for Testing - Phase 3
//

import XCTest

@testable import New_Members_Check_In

@MainActor
final class CheckInViewModelTests: XCTestCase {

    var viewModel: CheckInViewModel!
    var mockRepository: MockAttendanceRepository!

    // MARK: - Setup & Teardown

    override func setUp() async throws {
        try await super.setUp()

        // Create mock repository with test data
        mockRepository = MockAttendanceRepository()

        // Setup test members
        mockRepository.members = [
            Member(id: 1, firstName: "John", lastName: "Doe"),
            Member(id: 2, firstName: "Jane", lastName: "Smith"),
            Member(id: 3, firstName: "Bob", lastName: "Johnson"),
            Member(id: 4, firstName: "Alice", lastName: "Williams"),
        ]

        // Setup test date (today)
        let today = Date.now.ISO8601Format(.iso8601.year().month().day())
        mockRepository.dates = [
            AttendanceDate(id: 100, classDate: today)
        ]

        // Create ViewModel with mock repository
        viewModel = CheckInViewModel(repository: mockRepository)
    }

    override func tearDown() async throws {
        viewModel = nil
        mockRepository = nil
        try await super.tearDown()
    }

    // MARK: - Initialization Tests

    func testViewModelInitialization() {
        // Given/When: ViewModel is initialized (in setUp)

        // Then: Initial state is correct
        XCTAssertTrue(viewModel.searchText.isEmpty)
        XCTAssertTrue(viewModel.selectedMembers.isEmpty)
        XCTAssertTrue(viewModel.checkedInMemberIds.isEmpty)
        XCTAssertFalse(viewModel.showingErrorAlert)
        XCTAssertFalse(viewModel.showLogoutAlert)
    }

    // MARK: - Data Loading Tests

    func testLoadDataSuccess() async throws {
        // Given: Mock repository with members and dates

        // When: Load data
        await viewModel.loadData()

        // Then: Repository methods called
        XCTAssertEqual(mockRepository.loadMembersCallCount, 1)
        XCTAssertEqual(mockRepository.loadDatesCallCount, 1)
        XCTAssertEqual(mockRepository.getAttendanceCallCount, 1)

        // And: No errors shown
        XCTAssertFalse(viewModel.showingErrorAlert)
    }

    func testLoadDataMembersFailure() async throws {
        // Given: Repository that fails on loadMembers
        mockRepository.shouldThrowError = true

        // When: Load data
        await viewModel.loadData()

        // Then: Error alert shown
        XCTAssertTrue(viewModel.showingErrorAlert)
        XCTAssertFalse(viewModel.errorAlertMessage.isEmpty)
        print("VM Error Message ~~~> " + viewModel.errorAlertMessage)
        XCTAssertTrue(viewModel.errorAlertMessage.contains("Failed to load members"))
    }

    // MARK: - Member Selection Tests

    func testToggleMemberSelection() {
        // Given: A member
        let member = mockRepository.members[0]

        // When: Toggle selection
        viewModel.toggleMemberSelection(member)

        // Then: Member is selected
        XCTAssertEqual(viewModel.selectedMembers.count, 1)
        XCTAssertTrue(viewModel.isMemberSelected(member))

        // When: Toggle again
        viewModel.toggleMemberSelection(member)

        // Then: Member is deselected
        XCTAssertEqual(viewModel.selectedMembers.count, 0)
        XCTAssertFalse(viewModel.isMemberSelected(member))
    }

    func testSelectMultipleMembers() {
        // Given: Multiple members
        let member1 = mockRepository.members[0]
        let member2 = mockRepository.members[1]
        let member3 = mockRepository.members[2]

        // When: Select multiple
        viewModel.toggleMemberSelection(member1)
        viewModel.toggleMemberSelection(member2)
        viewModel.toggleMemberSelection(member3)

        // Then: All are selected
        XCTAssertEqual(viewModel.selectedMembers.count, 3)
        XCTAssertTrue(viewModel.isMemberSelected(member1))
        XCTAssertTrue(viewModel.isMemberSelected(member2))
        XCTAssertTrue(viewModel.isMemberSelected(member3))
    }

    // MARK: - Check-In Tests

    func testPerformCheckInSuccess() async throws {
        // Given: Load initial data
        await viewModel.loadData()
        mockRepository.reset()  // Reset call counts

        // And: Select a member
        let member = mockRepository.members[0]
        viewModel.toggleMemberSelection(member)

        // When: Perform check-in
        await viewModel.performCheckIn()

        // Then: Check-in was successful
        XCTAssertEqual(mockRepository.checkInMemberCallCount, 1)
        XCTAssertTrue(mockRepository.wasCheckedIn(memberId: member.id, dateId: 100))

        // And: Member removed from selection
        XCTAssertTrue(viewModel.selectedMembers.isEmpty)

        // And: Search cleared
        XCTAssertTrue(viewModel.searchText.isEmpty)

        // And: Attendance reloaded
        XCTAssertEqual(mockRepository.getAttendanceCallCount, 1)

        // And: No error shown
        XCTAssertFalse(viewModel.showingErrorAlert)
    }

    func testPerformCheckInMultipleMembers() async throws {
        // Given: Load initial data
        await viewModel.loadData()
        mockRepository.reset()

        // And: Select multiple members
        let member1 = mockRepository.members[0]
        let member2 = mockRepository.members[1]
        viewModel.toggleMemberSelection(member1)
        viewModel.toggleMemberSelection(member2)

        // When: Perform check-in
        await viewModel.performCheckIn()

        // Then: Both members checked in
        XCTAssertEqual(mockRepository.checkInMemberCallCount, 2)
        XCTAssertTrue(mockRepository.wasCheckedIn(memberId: member1.id, dateId: 100))
        XCTAssertTrue(mockRepository.wasCheckedIn(memberId: member2.id, dateId: 100))

        // And: Selection cleared
        XCTAssertTrue(viewModel.selectedMembers.isEmpty)

        // And: No error
        XCTAssertFalse(viewModel.showingErrorAlert)
    }

    func testPerformCheckInNoSelection() async throws {
        // Given: Load initial data, no members selected
        await viewModel.loadData()

        // When: Try to check in
        await viewModel.performCheckIn()

        // Then: Error shown
        XCTAssertTrue(viewModel.showingErrorAlert)
        XCTAssertTrue(viewModel.errorAlertMessage.contains("haven't made any selection"))

        // And: No check-in attempted
        XCTAssertEqual(mockRepository.checkInMemberCallCount, 0)
    }

    func testPerformCheckInTooManyMembers() async throws {
        // Given: Load initial data
        await viewModel.loadData()

        // And: Select more than 10 members (simulate by adding to array)
        for i in 1...11 {
            viewModel.selectedMembers.append(Member(id: i, firstName: "Test", lastName: "User\(i)"))
        }

        // When: Try to check in
        await viewModel.performCheckIn()

        // Then: Error shown
        XCTAssertTrue(viewModel.showingErrorAlert)
        XCTAssertTrue(viewModel.errorAlertMessage.contains("cannot check more than 10"))

        // And: No check-in attempted
        XCTAssertEqual(mockRepository.checkInMemberCallCount, 0)
    }

    func testPerformCheckInNoDateScheduled() async throws {
        // Given: No dates available
        mockRepository.dates = []
        await viewModel.loadData()

        // And: Select a member
        let member = mockRepository.members[0]
        viewModel.toggleMemberSelection(member)

        // When: Try to check in
        await viewModel.performCheckIn()

        // Then: Error shown
        XCTAssertTrue(viewModel.showingErrorAlert)
        XCTAssertTrue(viewModel.errorAlertMessage.contains("no class scheduled"))

        // And: No check-in attempted
        XCTAssertEqual(mockRepository.checkInMemberCallCount, 0)
    }

    // MARK: - Graceful Error Handling Tests

    func testPerformCheckInPartialFailure() async throws {
        // Given: Load initial data
        await viewModel.loadData()
        mockRepository.reset()

        // And: Select two members
        let member1 = mockRepository.members[0]
        let member2 = mockRepository.members[1]
        viewModel.toggleMemberSelection(member1)
        viewModel.toggleMemberSelection(member2)

        // And: Repository will fail on second check-in
        var callCount = 0
        mockRepository.shouldThrowError = false

        // Simulate failure on second member by tracking calls
        // Note: This is simplified - in real test we'd need more sophisticated mocking

        // When: First succeeds, manually simulate second fails
        mockRepository.shouldThrowError = false
        try await mockRepository.checkInMember(memberId: member1.id, dateId: 100)

        mockRepository.shouldThrowError = true
        do {
            try await mockRepository.checkInMember(memberId: member2.id, dateId: 100)
            XCTFail("Should have thrown error")
        } catch {
            // Expected
        }

        // Then: Can verify partial state
        XCTAssertTrue(mockRepository.wasCheckedIn(memberId: member1.id, dateId: 100))
        XCTAssertFalse(mockRepository.wasCheckedIn(memberId: member2.id, dateId: 100))
    }

    // MARK: - Computed Properties Tests

    func testTodayDate() async throws {
        // Given: Load dates with today's date
        await viewModel.loadData()

        // When: Access todayDate
        let todayDate = viewModel.todayDate

        // Then: Returns today's date
        XCTAssertNotNil(todayDate)
        XCTAssertEqual(todayDate?.id, 100)
    }

    func testTodayDateNoDates() {
        // Given: No dates in repository
        mockRepository.dates = []

        // When: Access todayDate
        let todayDate = viewModel.todayDate

        // Then: Returns nil
        XCTAssertNil(todayDate)
    }

    func testUncheckedMembers() async throws {
        // Given: Load data with 4 members
        await viewModel.loadData()

        // And: Mark 2 as checked in
        mockRepository.simulateCheckIn(memberId: 1, dateId: 100)
        mockRepository.simulateCheckIn(memberId: 2, dateId: 100)
        await viewModel.loadTodaysAttendance()

        // When: Get unchecked members
        let unchecked = viewModel.uncheckedMembers

        // Then: Only 2 unchecked members
        XCTAssertEqual(unchecked.count, 2)
        XCTAssertTrue(unchecked.contains { $0.id == 3 })
        XCTAssertTrue(unchecked.contains { $0.id == 4 })
    }

    func testFilteredMembers() async throws {
        // Given: Load data
        await viewModel.loadData()

        // When: No search text
        var filtered = viewModel.filteredMembers

        // Then: All members returned
        XCTAssertEqual(filtered.count, 4)

        // When: Search for "john"
        viewModel.searchText = "john"
        filtered = viewModel.filteredMembers

        // Then: Only matching members
        XCTAssertEqual(filtered.count, 2)  // John Doe and Bob Johnson
        XCTAssertTrue(filtered.contains { $0.firstName == "John" })
        XCTAssertTrue(filtered.contains { $0.firstName == "Bob" })
    }

    func testAllMembersCheckedIn() async throws {
        // Given: Load data
        await viewModel.loadData()

        // When: Not all checked in
        var allCheckedIn = viewModel.allMembersCheckedIn

        // Then: Returns false
        XCTAssertFalse(allCheckedIn)

        // When: All members checked in
        for member in mockRepository.members {
            mockRepository.simulateCheckIn(memberId: member.id, dateId: 100)
        }
        await viewModel.loadTodaysAttendance()
        allCheckedIn = viewModel.allMembersCheckedIn

        // Then: Returns true
        XCTAssertTrue(allCheckedIn)
    }

    func testIsLoading() {
        // Given: Repository with no dates
        mockRepository.dates = []

        // When: Check loading state
        let isLoading = viewModel.isLoading

        // Then: Is loading
        XCTAssertTrue(isLoading)

        // When: Add dates
        let today = Date.now.ISO8601Format(.iso8601.year().month().day())
        mockRepository.dates = [AttendanceDate(id: 100, classDate: today)]

        // Then: Not loading
        XCTAssertFalse(viewModel.isLoading)
    }

    func testStatusText() {
        // Given: No members selected

        // When: Get status text
        var status = viewModel.statusText

        // Then: Shows selection prompt
        XCTAssertEqual(status, "Select a name to check them in.")

        // When: Select 1 member
        viewModel.toggleMemberSelection(mockRepository.members[0])
        status = viewModel.statusText

        // Then: Shows singular
        XCTAssertEqual(status, "Check in 1 member")

        // When: Select 2 members
        viewModel.toggleMemberSelection(mockRepository.members[1])
        status = viewModel.statusText

        // Then: Shows plural
        XCTAssertEqual(status, "Check in 2 members")
    }

    // MARK: - Special Feature Tests

    func testCheckForLogoutCommand() {
        // Given: Regular search text
        viewModel.searchText = "john"

        // When: Check for logout
        viewModel.checkForLogoutCommand()

        // Then: No logout alert
        XCTAssertFalse(viewModel.showLogoutAlert)

        // When: Enter logout command
        viewModel.searchText = "/logout"
        viewModel.checkForLogoutCommand()

        // Then: Logout alert shown
        XCTAssertTrue(viewModel.showLogoutAlert)
    }

    // MARK: - Realtime Sync Tests

    func testStartRealtimeSync() async {
        // When: Start realtime sync
        await viewModel.startRealtimeSync()

        // Then: Repository method called
        XCTAssertEqual(mockRepository.startRealtimeSyncCallCount, 1)
    }

    func testStopRealtimeSync() {
        // When: Stop realtime sync
        viewModel.stopRealtimeSync()

        // Then: Repository method called
        XCTAssertEqual(mockRepository.stopRealtimeSyncCallCount, 1)
    }
}
