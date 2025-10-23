//
//  CheckInView.swift
//  New Members Check In
//
//  Created by Asher Pope on 1/13/23.
//


import SwiftUI

struct CheckInView: View {
    @EnvironmentObject var user: AuthUser
    @StateObject var supabase = SupabaseService()

    @StateObject var checklist = ChecklistModel()
    @State private var showingErrorAlert = false
    @State private var errorAlertMessage = ""
    @StateObject var searchbarModel = SearchbarModel()
    @State var toastModel: ToastModel
    @State private var checkedInMemberIds: Set<Int> = []

    @FocusState private var keyboardFocus: KeyboardFocus?

    /// Find today's date record in Supabase
    func todayDateRecord() -> AttendanceDate? {
        let today = currentDate.isoFormat
        let dateRecord = supabase.listOfAllDates.first(where: { date in
            date.classDate == today
        })
        print("Checking date: \(today) (today) vs \(dateRecord?.classDate ?? "nil")")
        return dateRecord
    }

    /// Create a list of members who have not checked in today
    var listOfUncheckedMembers: [Member] {
        supabase.listOfAllMembers.filter { member in
            !checkedInMemberIds.contains(member.id)
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 10) {
                if !supabase.listOfAllDates.isEmpty {
                    if !listOfUncheckedMembers.isEmpty {
                        VStack(spacing: 20) {
                            Searchbar(searchModel: searchbarModel)
                                .focused($keyboardFocus, equals: .searchbar)
                                .onSubmit {
                                    keyboardFocus = nil
                                }
                            ScrollView {
                                LazyVStack(spacing: 0) {
                                    ForEach(listOfUncheckedMembers, id: \.id) { member in
                                        // If there is a search:
                                        if searchbarModel.searchText != "" {
                                            if member.fullName.lowercased().contains(searchbarModel.searchText.lowercased()) {
                                                ChecklistViewNew(member: member, checklist: checklist)
                                            }
                                        // If there isn't a search, load all unchecked members
                                        } else {
                                            ChecklistViewNew(member: member, checklist: checklist)
                                        }
                                    }.animation(.default, value: listOfUncheckedMembers)
                                }
                            }
                            .background(Color(hex: "354959"))
                            .cornerRadius(10, antialiased: true)

                            Button(action: {
                                keyboardFocus = nil
                                Task {
                                    // Ensure selection is valid
                                    if checklist.selectedMembers.count > 10 {
                                        errorAlertMessage = "You cannot check more than 10 people in at once."
                                        showingErrorAlert = true
                                        return
                                    } else if checklist.selectedMembers.count == 0 {
                                        errorAlertMessage = "You haven't made any selection."
                                        showingErrorAlert = true
                                        return
                                    }

                                    // Make sure there is a date record for today
                                    guard let todayDate = todayDateRecord() else {
                                        errorAlertMessage = "There is no class scheduled for today."
                                        showingErrorAlert = true
                                        return
                                    }

                                    // Check in each selected member
                                    let countCheckedIn = checklist.selectedMembers.count
                                    for memberRecord in checklist.selectedMembers {
                                        let success = await supabase.updateAttendance(
                                            memberId: memberRecord.id,
                                            dateId: todayDate.id,
                                            user: user
                                        )
                                        if !success {
                                            errorAlertMessage = "Failed to check in one or more members."
                                            showingErrorAlert = true
                                            return
                                        }
                                    }

                                    // Reload today's attendance to update the filtered list
                                    await loadTodaysAttendance()

                                    checklist.selectedMembers = []
                                    searchbarModel.searchText = ""

                                    print("✅ Successfully checked in \(countCheckedIn) members!")
                                    withAnimation {
                                        toastModel.isPresented.toggle()
                                    }
                                }
                            }) {
                                Text("CHECK IN")
                                    .foregroundColor(Color(hex: "1C3040"))
                                    .cccBody(fontSize: 25)
                                    .frame(maxWidth: .infinity, maxHeight: 60)
                                    .background(.white)
                                    .cornerRadius(10, antialiased: true)
                            }
                            .alert(isPresented: $showingErrorAlert) {
                                Alert(
                                    title: Text("Error"),
                                    message: Text(errorAlertMessage),
                                    dismissButton: .default(Text("OK"))
                                )
                            }

                            // Status text
                            Text(
                                checklist.selectedMembers.count == 0 ?
                                "Select a name to check them in." :
                                    "Check in \(checklist.selectedMembers.count) member\(checklist.selectedMembers.count == 1 ? "" : "s")"
                            )
                            .foregroundColor(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 18)
                    } else {
                        Spacer()
                        Text("All members have checked in for \(currentDate.fullFormat).")
                            .foregroundColor(.white)
                            .font(.title3)
                        Spacer()
                    }
                } else {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            }
            .task {
                // Load members from Supabase
                await supabase.loadMembers(user: user)
                print("Loading members...")
            }
            .task {
                // Load dates from Supabase
                await supabase.loadDates(user: user)
                print("Loading dates...")
            }
            .onAppear {
                // Subscribe to real-time changes
                Task {
                    await supabase.subscribeToMembers(user: user)
                    await supabase.subscribeToAttendance(user: user)
                    await loadTodaysAttendance()
                }
            }
            .onDisappear {
                // Unsubscribe when leaving view
                supabase.unsubscribeAll()
            }
            .onChange(of: supabase.listOfAllDates) { _ in
                // Reload today's attendance when dates change
                Task {
                    await loadTodaysAttendance()
                }
            }
        }
    }

    func loadTodaysAttendance() async {
        guard let todayDate = todayDateRecord() else {
            checkedInMemberIds = []
            return
        }

        checkedInMemberIds = await supabase.getAttendanceForDate(dateId: todayDate.id)
        print("📋 Today's attendance: \(checkedInMemberIds.count) members checked in")
    }
}


struct CheckInView_Preview: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
