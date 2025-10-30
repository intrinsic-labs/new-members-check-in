import Foundation
import Supabase

/// Pure data source for Supabase operations.
/// This class handles only data fetching and mutations - no state management.
/// The repository layer will handle state, caching, and error handling.
@MainActor
class SupabaseDataSource {
    private let supabase = SupabaseConfig.shared.client

    // MARK: - Fetch Methods

    /// Fetch all members from Supabase, ordered by last name
    /// - Returns: Array of members
    /// - Throws: If the network request or decoding fails
    func fetchMembers() async throws -> [Member] {
        let response =
            try await supabase
            .from("members")
            .select("*")
            .order("last_name", ascending: true)
            .execute()

        let decoder = JSONDecoder()
        let members = try decoder.decode([Member].self, from: response.data)
        print("✅ Fetched \(members.count) members from Supabase")
        return members
    }

    /// Fetch all dates from Supabase, ordered by date descending
    /// - Returns: Array of attendance dates
    /// - Throws: If the network request or decoding fails
    func fetchDates() async throws -> [AttendanceDate] {
        let response =
            try await supabase
            .from("dates")
            .select("*")
            .order("class_date", ascending: false)
            .execute()

        let decoder = JSONDecoder()
        let dates = try decoder.decode([AttendanceDate].self, from: response.data)
        print("✅ Fetched \(dates.count) dates from Supabase")
        return dates
    }

    /// Fetch attendance records for a specific date
    /// - Parameter dateId: The ID of the date to query
    /// - Returns: Set of member IDs who are checked in for this date
    /// - Throws: If the network request or decoding fails
    func fetchAttendanceForDate(dateId: Int) async throws -> Set<Int> {
        let response =
            try await supabase
            .from("attendance")
            .select("member_id")
            .eq("date_id", value: dateId)
            .execute()

        let decoder = JSONDecoder()
        let records = try decoder.decode([AttendanceRecord].self, from: response.data)
        return Set(records.map { $0.memberId })
    }

    // MARK: - Mutation Methods

    /// Insert an attendance record for a member on a specific date
    /// - Parameters:
    ///   - memberId: The ID of the member to check in
    ///   - dateId: The ID of the date to check in for
    /// - Throws: If the insertion fails (except for duplicate check-ins, which are treated as success)
    func insertAttendance(memberId: Int, dateId: Int) async throws {
        do {
            try await supabase
                .from("attendance")
                .insert(["member_id": memberId, "date_id": dateId])
                .execute()

            print("✅ Inserted attendance: member \(memberId), date \(dateId)")
        } catch {
            // Check if it's a unique constraint error (duplicate check-in)
            // In this case, we treat it as success since the member is already checked in
            if error.localizedDescription.contains("23505")
                || error.localizedDescription.contains("duplicate")
            {
                print(
                    "⚠️ Member \(memberId) already checked in for date \(dateId) - treating as success"
                )
                return  // Don't throw - duplicate is OK
            }

            // For other errors, re-throw
            throw error
        }
    }

    // MARK: - Realtime Subscription Setup

    /// Create a realtime channel for members table changes
    /// - Parameter onChange: Callback fired when members table changes
    /// - Returns: The realtime subscription for lifecycle management
    func createMembersSubscription(onChange: @escaping @Sendable () -> Void) async throws
        -> RealtimeSubscription
    {
        let channel = supabase.realtimeV2.channel("members_channel")

        let subscription = channel.onPostgresChange(
            AnyAction.self,
            schema: "public",
            table: "members"
        ) { change in
            Task { @MainActor in
                print("📡 Members table changed")
                onChange()
            }
        }

        try await channel.subscribeWithError()
        print("✅ Subscribed to members table changes")
        return subscription
    }

    /// Create a realtime channel for attendance table changes
    /// - Parameter onChange: Callback fired when attendance table changes
    /// - Returns: The realtime subscription for lifecycle management
    func createAttendanceSubscription(onChange: @escaping @Sendable () -> Void) async throws
        -> RealtimeSubscription
    {
        let channel = supabase.realtimeV2.channel("attendance_channel")

        let subscription = channel.onPostgresChange(
            AnyAction.self,
            schema: "public",
            table: "attendance"
        ) { change in
            Task { @MainActor in
                print("📡 Attendance table changed")
                onChange()
            }
        }

        try await channel.subscribeWithError()
        print("✅ Subscribed to attendance table changes")
        return subscription
    }
}
