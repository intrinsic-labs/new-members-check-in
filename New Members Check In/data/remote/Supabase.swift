import Foundation
import Supabase

// Domain models are now in domain/models/
// (No import needed - same module/target)

@MainActor
class SupabaseService: ObservableObject {
    @Published var listOfAllMembers: [Member] = []
    @Published var listOfAllDates: [AttendanceDate] = []
    @Published var errorMessage: String = ""
    @Published var attendanceDidUpdate: Bool = false

    private let supabase = SupabaseConfig.shared.client
    private var membersSubscription: RealtimeSubscription?
    private var attendanceSubscription: RealtimeSubscription?

    // MARK: - Load Methods

    /// Fetch all members from Supabase, ordered by last name
    func loadMembers(user: AuthUser) async {
        do {
            let response =
                try await supabase
                .from("members")
                .select("*")
                .order("last_name", ascending: true)
                .execute()

            let decoder = JSONDecoder()
            let members: [Member] = try decoder.decode(Array<Member>.self, from: response.data)
            self.listOfAllMembers = members
            print("✅ Loaded \(members.count) members")
        } catch {
            await handleError("Failed to load members: \(error)")
            print("Error loading members: \(error)")
        }
    }

    /// Fetch all dates from Supabase, ordered by date descending
    func loadDates(user: AuthUser) async {
        do {
            let response =
                try await supabase
                .from("dates")
                .select("*")
                .order("class_date", ascending: false)
                .execute()

            let decoder = JSONDecoder()
            let dates: [AttendanceDate] = try decoder.decode(
                Array<AttendanceDate>.self, from: response.data)
            self.listOfAllDates = dates
            print("✅ Loaded \(dates.count) dates")
        } catch {
            await handleError("Failed to load dates: \(error)")
            print("Error loading dates: \(error)")
        }
    }

    // MARK: - Update Methods

    /// Fetch attendance records for a specific date
    func getAttendanceForDate(dateId: Int) async -> Set<Int> {
        do {
            let response =
                try await supabase
                .from("attendance")
                .select("member_id")
                .eq("date_id", value: dateId)
                .execute()

            let decoder = JSONDecoder()
            let records: [AttendanceRecord] = try decoder.decode(
                Array<AttendanceRecord>.self, from: response.data)
            return Set(records.map { $0.memberId })
        } catch {
            print("Error fetching attendance for date: \(error)")
            return Set()
        }
    }

    /// Check in a member for a specific date
    func updateAttendance(memberId: Int, dateId: Int, user: AuthUser) async -> Bool {
        do {
            // Insert attendance record
            try await supabase
                .from("attendance")
                .insert(["member_id": memberId, "date_id": dateId])
                .execute()

            print("✅ Checked in member \(memberId) for date \(dateId)")
            return true
        } catch {
            // Check if it's a unique constraint error (duplicate check-in)
            if error.localizedDescription.contains("23505")
                || error.localizedDescription.contains("duplicate")
            {
                print("⚠️ Member already checked in for this date")
                return true  // Treat as success (already checked in)
            }

            await handleError("Failed to check in member: \(error)")
            print("Error updating attendance: \(error)")
            return false
        }
    }

    // MARK: - Real-Time Subscriptions

    /// Subscribe to member table changes
    func subscribeToMembers(user: AuthUser) async {
        let channel = supabase.realtimeV2.channel("members_channel")

        // Subscribe to all changes on the members table
        membersSubscription = channel.onPostgresChange(
            AnyAction.self,
            schema: "public",
            table: "members"
        ) { [weak self] _ in
            // When members change, reload the list
            Task { @MainActor in
                print("📡 Received members update")
                // just reload members and dates cause if
                // members change during class, might as
                // well check for new class dates too
                await self?.loadMembers(user: user)
                await self?.loadDates(user: user)
            }
        }

        do {
            try await channel.subscribeWithError()
            print("Subscribed to members changes")
        } catch {
            print("❌ Error subscribing to members: \(error)")
        }
    }

    /// Subscribe to attendance table changes
    func subscribeToAttendance(user: AuthUser) async {
        let channel = supabase.realtimeV2.channel("attendance_channel")

        attendanceSubscription = channel.onPostgresChange(
            AnyAction.self,
            schema: "public",
            table: "attendance"
        ) { [weak self] change in
            // When attendance changes, signal that cache is out of date
            Task { @MainActor in
                print("📡 Received attendance update: \(change.rawMessage.event)")
                self?.attendanceDidUpdate.toggle()
            }
        }

        do {
            try await channel.subscribeWithError()
            print("🔄 Subscribed to attendance changes on table 'attendance'")
        } catch {
            print("❌ Error subscribing to attendance: \(error)")
        }
    }

    /// Unsubscribe from all channels
    func unsubscribeAll() {
        print("Unsubscribing from all channels...")
        membersSubscription?.cancel()
        attendanceSubscription?.cancel()
        print("Unsubscribed from all channels.")
    }

    // MARK: - Helper Methods

    private func handleError(_ message: String) async {
        self.errorMessage = message
        print("❌ \(message)")
    }
}

// MARK: - Data Models
// Models have been moved to domain/models/
