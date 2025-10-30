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
    private var membersSubscription: RealtimeSubscription?
    private var attendanceSubscription: RealtimeSubscription?

    // MARK: - Initialization

    private init() {
        // Start realtime subscriptions - keep active for app lifetime
        Task {
            await startRealtimeSync()
        }
    }

    // MARK: - Data Operations

    func loadMembers() async throws {
        do {
            let fetchedMembers = try await dataSource.fetchMembers()
            self.members = fetchedMembers
        } catch {
            print("❌ Failed to load members - \(error)")
            throw error
        }
    }

    func loadDates() async throws {
        do {
            let fetchedDates = try await dataSource.fetchDates()
            self.dates = fetchedDates
        } catch {
            print("❌ Failed to load dates - \(error)")
            throw error
        }
    }

    func getAttendanceForDate(dateId: Int) async throws -> Set<Int> {
        do {
            let attendanceSet = try await dataSource.fetchAttendanceForDate(dateId: dateId)
            return attendanceSet
        } catch {
            print("❌ Failed to fetch attendance for date \(dateId) - \(error)")
            throw error
        }
    }

    func checkInMember(memberId: Int, dateId: Int) async throws {
        do {
            try await dataSource.insertAttendance(memberId: memberId, dateId: dateId)
        } catch {
            print("❌ Failed to check in member \(memberId) - \(error)")
            throw error
        }
    }

    // MARK: - Realtime Sync

    private func startRealtimeSync() async {
        do {
            // Subscribe to members table changes
            membersSubscription = try await dataSource.createMembersSubscription { [weak self] in
                Task { @MainActor in
                    guard let self = self else { return }
                    // When members change, reload both members and dates
                    // (dates might also change during class time)
                    try? await self.loadMembers()
                    try? await self.loadDates()
                }
            }

            // Subscribe to attendance table changes
            attendanceSubscription = try await dataSource.createAttendanceSubscription {
                [weak self] in
                Task { @MainActor in
                    guard let self = self else { return }
                    // Toggle the flag to signal views to refresh attendance
                    self.attendanceDidUpdate.toggle()
                }
            }
        } catch {
            print("❌ Failed to start realtime sync: \(error)")
        }
    }

    // Clean up subscriptions (called on deinit if needed)
    private func stopRealtimeSync() {
        membersSubscription?.cancel()
        attendanceSubscription?.cancel()
        membersSubscription = nil
        attendanceSubscription = nil
        print("Canceled all realtime subscriptions")
    }

    // MARK: - Lifecycle

    deinit {
        Task { [weak self] in
            await self?.stopRealtimeSync()
        }
    }
}
