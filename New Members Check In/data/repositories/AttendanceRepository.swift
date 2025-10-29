import Foundation
import Supabase

/// Concrete implementation of AttendanceRepositoryProtocol.
/// This singleton manages the in-memory cache of attendance data and handles
/// real-time synchronization with Supabase.
@MainActor
class AttendanceRepository: ObservableObject, AttendanceRepositoryProtocol {

    // MARK: - Singleton

    static let shared = AttendanceRepository()

    // MARK: - Published Properties

    @Published private(set) var members: [Member] = []
    @Published private(set) var dates: [AttendanceDate] = []
    @Published private(set) var attendanceDidUpdate: Bool = false

    // MARK: - Private Properties

    private let dataSource = SupabaseDataSource()
    private var membersChannel: RealtimeChannelV2?
    private var attendanceChannel: RealtimeChannelV2?
    private var isRealtimeSyncActive = false

    // MARK: - Initialization

    private init() {
        print("🏗️ AttendanceRepository initialized")
    }

    // MARK: - Data Operations

    func loadMembers() async throws {
        do {
            let fetchedMembers = try await dataSource.fetchMembers()
            self.members = fetchedMembers
            print("✅ Repository: Loaded \(fetchedMembers.count) members")
        } catch {
            print("❌ Repository: Failed to load members - \(error)")
            throw error
        }
    }

    func loadDates() async throws {
        do {
            let fetchedDates = try await dataSource.fetchDates()
            self.dates = fetchedDates
            print("✅ Repository: Loaded \(fetchedDates.count) dates")
        } catch {
            print("❌ Repository: Failed to load dates - \(error)")
            throw error
        }
    }

    func getAttendanceForDate(dateId: Int) async throws -> Set<Int> {
        do {
            let attendanceSet = try await dataSource.fetchAttendanceForDate(dateId: dateId)
            print(
                "✅ Repository: Fetched attendance for date \(dateId) - \(attendanceSet.count) members"
            )
            return attendanceSet
        } catch {
            print("❌ Repository: Failed to fetch attendance for date \(dateId) - \(error)")
            throw error
        }
    }

    func checkInMember(memberId: Int, dateId: Int) async throws {
        do {
            try await dataSource.insertAttendance(memberId: memberId, dateId: dateId)
            print("✅ Repository: Checked in member \(memberId) for date \(dateId)")
        } catch {
            print("❌ Repository: Failed to check in member \(memberId) - \(error)")
            throw error
        }
    }

    // MARK: - Realtime Sync

    func startRealtimeSync() async {
        guard !isRealtimeSyncActive else {
            print("⚠️ Realtime sync already active")
            return
        }

        print("🚀 Starting realtime sync...")

        do {
            // Subscribe to members table changes
            membersChannel = try await dataSource.createMembersSubscription { [weak self] in
                Task { @MainActor in
                    guard let self = self else { return }
                    // When members change, reload both members and dates
                    // (dates might also change during class time)
                    try? await self.loadMembers()
                    try? await self.loadDates()
                }
            }

            // Subscribe to attendance table changes
            attendanceChannel = try await dataSource.createAttendanceSubscription { [weak self] in
                Task { @MainActor in
                    guard let self = self else { return }
                    // Toggle the flag to signal views to refresh attendance
                    self.attendanceDidUpdate.toggle()
                }
            }

            isRealtimeSyncActive = true
            print("✅ Realtime sync started successfully")
        } catch {
            print("❌ Failed to start realtime sync: \(error)")
        }
    }

    func stopRealtimeSync() {
        guard isRealtimeSyncActive else {
            print("⚠️ Realtime sync not active")
            return
        }

        print("🛑 Stopping realtime sync...")

        Task { @MainActor in
            await membersChannel?.unsubscribe()
            await attendanceChannel?.unsubscribe()
            membersChannel = nil
            attendanceChannel = nil
            isRealtimeSyncActive = false
            print("✅ Realtime sync stopped")
        }
    }

    // MARK: - Lifecycle

    deinit {
        print("🗑️ AttendanceRepository deallocated")
    }
}
