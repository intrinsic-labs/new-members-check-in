//
//  CheckInViewModel.swift
//  New Members Check In
//
//  Created by AI Assistant on Phase 3 Refactor
//

import SwiftUI

/// ViewModel for the CheckInView, handling all business logic and state management.
/// This separates concerns and makes the view purely focused on UI rendering.
@MainActor
class CheckInViewModel: ObservableObject {

    // MARK: - Dependencies

    let repository: AttendanceRepositoryProtocol

    // MARK: - Published State

    /// Search text for filtering members
    @Published var searchText: String = ""

    /// Members currently selected for check-in
    @Published var selectedMembers: [Member] = []

    /// Set of member IDs who have already checked in today
    @Published private(set) var checkedInMemberIds: Set<Int> = []

    /// Whether to show the error alert
    @Published var showingErrorAlert: Bool = false

    /// The error message to display in the alert
    @Published var errorAlertMessage: String = ""

    /// Whether to show the logout confirmation alert
    @Published var showLogoutAlert: Bool = false

    // MARK: - Initialization

    init(repository: AttendanceRepositoryProtocol = AttendanceRepository.shared) {
        self.repository = repository
        print("🏗️ CheckInViewModel initialized")
    }

    // MARK: - Computed Properties

    /// Find today's date record in the repository
    var todayDate: AttendanceDate? {
        let today = currentDate.isoFormat
        let dateRecord = repository.dates.first { date in
            date.classDate == today
        }
        return dateRecord
    }

    /// List of members who have not checked in today
    var uncheckedMembers: [Member] {
        repository.members.filter { member in
            !checkedInMemberIds.contains(member.id)
        }
    }

    /// Filtered list of unchecked members based on search text
    var filteredMembers: [Member] {
        if searchText.isEmpty {
            return uncheckedMembers
        } else {
            return uncheckedMembers.filter { member in
                member.fullName.lowercased().contains(searchText.lowercased())
            }
        }
    }

    /// Whether all members have checked in for today
    var allMembersCheckedIn: Bool {
        !repository.dates.isEmpty && uncheckedMembers.isEmpty
    }

    /// Whether we're still loading initial data
    var isLoading: Bool {
        repository.dates.isEmpty
    }

    /// Status text to display at the bottom of the view
    var statusText: String {
        if selectedMembers.isEmpty {
            return "Select a name to check them in."
        } else {
            let count = selectedMembers.count
            return "Check in \(count) member\(count == 1 ? "" : "s")"
        }
    }

    // MARK: - Public Methods

    /// Load initial data from the repository
    func loadData() async {
        do {
            try await repository.loadMembers()
            print("✅ ViewModel: Members loaded")
        } catch {
            print("❌ ViewModel: Failed to load members - \(error)")
            errorAlertMessage = "Failed to load members: \(error.localizedDescription)"
            showingErrorAlert = true
        }

        do {
            try await repository.loadDates()
            print("✅ ViewModel: Dates loaded")
        } catch {
            print("❌ ViewModel: Failed to load dates - \(error)")
            errorAlertMessage = "Failed to load dates: \(error.localizedDescription)"
            showingErrorAlert = true
        }

        // Load today's attendance after data is loaded
        await loadTodaysAttendance()
    }

    /// Start realtime synchronization with the backend
    func startRealtimeSync() async {
        await repository.startRealtimeSync()
        print("🔄 ViewModel: Started realtime sync")
    }

    /// Stop realtime synchronization
    func stopRealtimeSync() {
        repository.stopRealtimeSync()
        print("⏸️ ViewModel: Stopped realtime sync")
    }

    /// Toggle selection of a member for check-in
    func toggleMemberSelection(_ member: Member) {
        if let index = selectedMembers.firstIndex(where: { $0.id == member.id }) {
            selectedMembers.remove(at: index)
        } else {
            selectedMembers.append(member)
        }
    }

    /// Check if a member is currently selected
    func isMemberSelected(_ member: Member) -> Bool {
        selectedMembers.contains { $0.id == member.id }
    }

    /// Perform the check-in operation for all selected members
    func performCheckIn() async {
        // Validate selection count
        if selectedMembers.count > 10 {
            errorAlertMessage = "You cannot check more than 10 people in at once."
            showingErrorAlert = true
            return
        }

        if selectedMembers.isEmpty {
            errorAlertMessage = "You haven't made any selection."
            showingErrorAlert = true
            return
        }

        // Make sure there is a date record for today
        guard let todayDate = todayDate else {
            errorAlertMessage = "There is no class scheduled for today."
            showingErrorAlert = true
            return
        }

        // Check in each selected member, tracking successes and failures
        let countToCheckIn = selectedMembers.count
        var successfulMembers: [Member] = []
        var failedMembers: [Member] = []

        for memberRecord in selectedMembers {
            do {
                try await repository.checkInMember(memberId: memberRecord.id, dateId: todayDate.id)
                successfulMembers.append(memberRecord)
                print("✅ ViewModel: Checked in \(memberRecord.fullName)")
            } catch {
                failedMembers.append(memberRecord)
                print("❌ ViewModel: Failed to check in member \(memberRecord.fullName) - \(error)")
            }
        }

        // Always reload attendance (even if some failed) to show any successful check-ins
        await loadTodaysAttendance()

        // Remove only successfully checked-in members from selection
        for successMember in successfulMembers {
            selectedMembers.removeAll { $0.id == successMember.id }
        }

        // Clear search only if all members were successful
        if failedMembers.isEmpty {
            searchText = ""
        }

        // Show appropriate message based on results
        if failedMembers.isEmpty {
            // Complete success
            print("✅ ViewModel: Successfully checked in \(countToCheckIn) members!")
        } else if successfulMembers.isEmpty {
            // Complete failure
            let memberNames = failedMembers.map { $0.fullName }.joined(separator: ", ")
            errorAlertMessage =
                "Failed to check in: \(memberNames). Please check your internet connection and try again."
            showingErrorAlert = true
            print("❌ ViewModel: All check-ins failed (\(failedMembers.count) members)")
        } else {
            // Partial success
            let failedNames = failedMembers.map { $0.fullName }.joined(separator: ", ")
            errorAlertMessage =
                "Successfully checked in \(successfulMembers.count) member(s), but failed for: \(failedNames). Please try again."
            showingErrorAlert = true
            print(
                "⚠️ ViewModel: Partial success - \(successfulMembers.count) succeeded, \(failedMembers.count) failed"
            )
        }
    }

    /// Check if the search text is the logout command and trigger alert if so
    func checkForLogoutCommand() {
        if searchText == "/logout" {
            showLogoutAlert = true
        }
    }

    /// Reload today's attendance data (called on realtime updates)
    func loadTodaysAttendance() async {
        guard let todayDate = todayDate else {
            checkedInMemberIds = []
            return
        }

        do {
            checkedInMemberIds = try await repository.getAttendanceForDate(dateId: todayDate.id)
            print(
                "📋 ViewModel: Today's attendance - \(checkedInMemberIds.count) members checked in")
        } catch {
            print("❌ ViewModel: Failed to load today's attendance - \(error)")
            // Don't show error alert for this, just log it
            checkedInMemberIds = []
        }
    }

    /// Called when dates change to reload attendance
    func handleDatesChanged() {
        print("📅 ViewModel: Dates changed, reloading attendance...")
        Task {
            await loadTodaysAttendance()
        }
    }

    /// Called when attendance updates via realtime sync
    func handleAttendanceUpdated() {
        print("🔔 ViewModel: Attendance update detected from onChange!")
        print("🔄 ViewModel: Reloading today's check-ins...")
        Task {
            await loadTodaysAttendance()
        }
    }
}
