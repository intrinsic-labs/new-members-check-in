//
//  MockAttendanceRepository.swift
//  New Members Check InTests
//
//  Created for Testing - Phase 3
//

import Foundation

@testable import New_Members_Check_In

/// Mock implementation of AttendanceRepositoryProtocol for testing
@MainActor
class MockAttendanceRepository: AttendanceRepositoryProtocol, ObservableObject {

    // MARK: - Published Properties (Protocol Requirements)

    @Published var members: [Member] = []
    @Published var dates: [AttendanceDate] = []
    @Published var attendanceDidUpdate: Bool = false

    // MARK: - Test Configuration

    /// Set to true to simulate an error on the next operation
    var shouldThrowError = false

    /// The error to throw when shouldThrowError is true
    var errorToThrow: Error = NSError(
        domain: "TestError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])

    /// Tracks which members were checked in (for verification)
    var checkedInMembers: [(memberId: Int, dateId: Int)] = []

    /// Simulated attendance data (member IDs per date)
    var mockAttendanceData: [Int: Set<Int>] = [:]  // [dateId: Set<memberIds>]

    /// Tracks how many times each method was called
    var loadMembersCallCount = 0
    var loadDatesCallCount = 0
    var getAttendanceCallCount = 0
    var checkInMemberCallCount = 0
    var startRealtimeSyncCallCount = 0
    var stopRealtimeSyncCallCount = 0

    // MARK: - Initialization

    init(members: [Member] = [], dates: [AttendanceDate] = []) {
        self.members = members
        self.dates = dates
    }

    // MARK: - Protocol Methods

    func loadMembers() async throws {
        loadMembersCallCount += 1

        if shouldThrowError {
            throw errorToThrow
        }

        // Members are already set in init or by tests
        // This simulates loading from a data source
    }

    func loadDates() async throws {
        loadDatesCallCount += 1

        if shouldThrowError {
            throw errorToThrow
        }

        // Dates are already set in init or by tests
    }

    func getAttendanceForDate(dateId: Int) async throws -> Set<Int> {
        getAttendanceCallCount += 1

        if shouldThrowError {
            throw errorToThrow
        }

        return mockAttendanceData[dateId] ?? []
    }

    func checkInMember(memberId: Int, dateId: Int) async throws {
        checkInMemberCallCount += 1

        if shouldThrowError {
            throw errorToThrow
        }

        // Track the check-in
        checkedInMembers.append((memberId, dateId))

        // Update mock attendance data
        if mockAttendanceData[dateId] == nil {
            mockAttendanceData[dateId] = []
        }
        mockAttendanceData[dateId]?.insert(memberId)

        // Simulate realtime update
        attendanceDidUpdate.toggle()
    }

    func startRealtimeSync() async {
        startRealtimeSyncCallCount += 1
    }

    func stopRealtimeSync() {
        stopRealtimeSyncCallCount += 1
    }

    // MARK: - Test Helpers

    /// Reset all tracking data between tests
    func reset() {
        shouldThrowError = false
        checkedInMembers = []
        mockAttendanceData = [:]
        loadMembersCallCount = 0
        loadDatesCallCount = 0
        getAttendanceCallCount = 0
        checkInMemberCallCount = 0
        startRealtimeSyncCallCount = 0
        stopRealtimeSyncCallCount = 0
    }

    /// Helper to check if a specific member was checked in for a date
    func wasCheckedIn(memberId: Int, dateId: Int) -> Bool {
        return checkedInMembers.contains { $0.memberId == memberId && $0.dateId == dateId }
    }

    /// Helper to simulate checking in a member (for setup)
    func simulateCheckIn(memberId: Int, dateId: Int) {
        if mockAttendanceData[dateId] == nil {
            mockAttendanceData[dateId] = []
        }
        mockAttendanceData[dateId]?.insert(memberId)
    }
}
