import Foundation

/// Protocol defining the interface for attendance data operations.
/// This abstraction allows for easy testing and swapping of data sources.
@MainActor
protocol AttendanceRepositoryProtocol: ObservableObject {
    // MARK: - Observable Data

    /// Current list of all members, ordered by last name
    var members: [Member] { get }

    /// Current list of all attendance dates, ordered by date descending
    var dates: [AttendanceDate] { get }

    /// Signal that attendance data has been updated (for cache invalidation)
    var attendanceDidUpdate: Bool { get }

    // MARK: - Data Operations

    /// Load all members from the data source
    func loadMembers() async throws

    /// Load all attendance dates from the data source
    func loadDates() async throws

    /// Get the set of member IDs who have checked in for a specific date
    /// - Parameter dateId: The ID of the date to query
    /// - Returns: Set of member IDs who are checked in
    func getAttendanceForDate(dateId: Int) async throws -> Set<Int>

    /// Check in a member for a specific date
    /// - Parameters:
    ///   - memberId: The ID of the member to check in
    ///   - dateId: The ID of the date to check in for
    func checkInMember(memberId: Int, dateId: Int) async throws


}
