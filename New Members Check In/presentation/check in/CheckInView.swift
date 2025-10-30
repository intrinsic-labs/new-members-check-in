//
//  CheckInView.swift
//  New Members Check In
//
//  Created by Asher Pope on 1/13/23.
//  Refactored: Phase 3 - MVVM Architecture
//

import SwiftUI

struct CheckInView: View {
    @EnvironmentObject var user: AuthUser
    @StateObject private var viewModel = CheckInViewModel()
    @StateObject private var searchbarModel = SearchbarModel()
    @ObservedObject private var repository = AttendanceRepository.shared

    @State var toastModel: ToastModel
    @FocusState private var keyboardFocus: KeyboardFocus?
    @State private var isInitialLoad = true

    var body: some View {
        NavigationStack {
            VStack(spacing: 10) {
                if viewModel.isLoading {
                    // Loading state
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if viewModel.allMembersCheckedIn {
                    // All members checked in
                    Spacer()
                    Text("All members have checked in for \(currentDate.fullFormat).")
                        .foregroundColor(.white)
                        .font(.title3)
                    Spacer()
                } else {
                    // Main check-in interface
                    VStack(spacing: 20) {
                        // Search bar
                        Searchbar(searchModel: searchbarModel)
                            .focused($keyboardFocus, equals: .searchbar)
                            .onSubmit {
                                keyboardFocus = nil
                                viewModel.checkForLogoutCommand()
                            }

                        // Members list
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                ForEach(viewModel.filteredMembers, id: \.id) { member in
                                    MemberChecklistRow(
                                        member: member,
                                        isSelected: viewModel.isMemberSelected(member),
                                        onTap: {
                                            viewModel.toggleMemberSelection(member)
                                        }
                                    )
                                }
                            }
                            .animation(.default, value: viewModel.filteredMembers.count)
                        }
                        .background(Color(hex: "354959"))
                        .cornerRadius(10, antialiased: true)

                        // Check-in button
                        Button(action: {
                            keyboardFocus = nil
                            Task {
                                await viewModel.performCheckIn()

                                // Show toast on complete success (no errors, all members checked in)
                                if viewModel.activeAlert == nil && viewModel.selectedMembers.isEmpty
                                {
                                    withAnimation {
                                        toastModel.isPresented.toggle()
                                    }
                                }
                                // Note: Search clearing is handled by ViewModel (synced via onChange)
                            }
                        }) {
                            Text("CHECK IN")
                                .foregroundColor(Color(hex: "1C3040"))
                                .cccBody(fontSize: 25)
                                .frame(maxWidth: .infinity, maxHeight: 60)
                                .background(.white)
                                .cornerRadius(10, antialiased: true)
                        }

                        // Status text
                        Text(viewModel.statusText)
                            .foregroundColor(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 18)
                }
            }
            .task {
                // Load data on view appear
                await viewModel.loadData()
            }
            .onAppear {
                // Start realtime sync
                Task {
                    await viewModel.startRealtimeSync()
                }
            }
            .onDisappear {
                // Stop realtime sync when leaving view
                viewModel.stopRealtimeSync()
            }
            .onChange(of: searchbarModel.searchText) { newValue in
                // Sync search text to ViewModel
                viewModel.searchText = newValue
            }
            .onChange(of: viewModel.searchText) { newValue in
                // Sync search text back to searchbar (e.g., when cleared by ViewModel)
                if newValue != searchbarModel.searchText {
                    searchbarModel.searchText = newValue
                }
            }
            .onChange(of: repository.dates) { _ in
                // Skip reload on initial load (already loaded in loadData)
                guard !isInitialLoad else {
                    isInitialLoad = false
                    return
                }
                // Reload attendance when dates change after initial load
                viewModel.handleDatesChanged()
            }
            .onChange(of: repository.attendanceDidUpdate) { _ in
                // Reload attendance when realtime update received
                viewModel.handleAttendanceUpdated()
            }
            .alert(item: $viewModel.activeAlert) { alertType in
                switch alertType {
                case .error(let message):
                    return Alert(
                        title: Text("Error"),
                        message: Text(message),
                        dismissButton: .default(Text("OK"))
                    )
                case .logout:
                    return Alert(
                        title: Text("Log out?"),
                        message: Text("You will have to sign in again to use the app."),
                        primaryButton: .destructive(Text("Log Out")) {
                            Task { await user.signOut() }
                        },
                        secondaryButton: .cancel()
                    )
                }
            }
        }
    }
}

// MARK: - Member Checklist Row Component

private struct MemberChecklistRow: View {
    let member: Member
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                isSelected ? Color.white.opacity(0.32) : Color(hex: "354959")

                HStack {
                    Text(
                        isSelected
                            ? Image(systemName: "circle.inset.filled") : Image(systemName: "circle")
                    )
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(.horizontal)

                    VStack(spacing: 0) {
                        Spacer()
                        HStack(spacing: 5) {
                            Text(member.fullName)
                                .foregroundColor(.white)
                            Spacer()
                        }
                        Spacer()

                        // Row divider
                        Color.gray
                            .frame(height: 0.5)
                            .opacity(0.5)
                    }
                    .frame(height: 50)
                }
            }
        }
    }
}

// MARK: - Preview

struct CheckInView_Preview: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
