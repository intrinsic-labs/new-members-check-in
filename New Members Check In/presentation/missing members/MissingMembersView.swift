//
//  MissingMembersView.swift
//  New Members Check In
//
//  Created by Asher Pope on 1/13/23.
//

import SwiftUI

struct MissingMembersView: View {
    @EnvironmentObject var user: AuthUser
    @ObservedObject private var repository = AttendanceRepository.shared

    @State private var dateSelection: AttendanceDate?
    @State private var missingMembers: [Member] = []
    @State private var showErrorAlert = false
    @State private var errorMessage = ""

    var body: some View {
        VStack(spacing: 20) {
            if !repository.dates.isEmpty {
                let pastDates = datesBeforeToday()

                // Here is the date picker
                VStack {
                    HStack(spacing: 0) {
                        if let selectedDate = dateSelection {
                            Text(
                                "The members listed below did not check in on \(selectedDate.classDate)."
                            )
                            .foregroundColor(.white)
                        } else {
                            Text("Select a date to view attendance.")
                                .foregroundColor(.white)
                        }

                        Spacer()

                        Picker("Select a date", selection: $dateSelection) {
                            ForEach(pastDates, id: \.id) { date in
                                Text(date.classDate)
                                    .tag(date as AttendanceDate?)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(.orange)
                        .cornerRadius(10, antialiased: true)
                    }.padding()
                }
                .frame(height: 50)
                .background(Color(hex: "354959"))
                .cornerRadius(10, antialiased: true)
                .padding(.horizontal, 18)
                .padding(.top, 7)

                if !missingMembers.isEmpty {
                    // This is the list of names
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            ForEach(missingMembers, id: \.id) { member in
                                ZStack {
                                    Color(hex: "354959")
                                    //Build out item text
                                    HStack {
                                        VStack(spacing: 0) {
                                            Spacer()
                                            HStack(spacing: 5) {
                                                Text(member.fullName)
                                                    .foregroundColor(.white)
                                                Text("•")
                                                    .foregroundColor(.white)
                                                Text("No attendance record for this date")
                                                    .foregroundColor(.white.opacity(0.6))
                                                Spacer()
                                            }
                                            Spacer()
                                            Spacer()

                                            //Add row divider
                                            Color.gray
                                                .frame(height: 0.5)
                                                .opacity(0.5)

                                        }
                                        .padding()
                                        .frame(height: 50)
                                    }
                                }
                            }
                        }
                    }
                    .background(Color(hex: "354959"))
                    .cornerRadius(10, antialiased: true)
                    .padding(.horizontal, 18)
                    .padding(.bottom, 20)
                } else {
                    Spacer()
                    Text("All members checked in on this date.")
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
            await loadData()
        }
        .onChange(of: dateSelection) { newSelection in
            Task {
                if let dateId = newSelection?.id {
                    await loadMissingMembers(for: dateId)
                } else {
                    missingMembers = []
                }
            }
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Helper Methods

    func datesBeforeToday() -> [AttendanceDate] {
        let todayString = currentDate.isoFormat
        return repository.dates.filter { date in
            date.classDate <= todayString
        }
    }

    func loadData() async {
        do {
            try await repository.loadMembers()
            try await repository.loadDates()
            // Auto-select the most recent past date
            dateSelection = datesBeforeToday().last
        } catch {
            errorMessage = "Failed to load data: \(error.localizedDescription)"
            showErrorAlert = true
            print("❌ Error loading data in MissingMembersView: \(error)")
        }
    }

    func loadMissingMembers(for dateId: Int) async {
        do {
            // Get all members who checked in for this date
            let checkedInIds = try await repository.getAttendanceForDate(dateId: dateId)

            // Filter to get only those who didn't check in
            missingMembers = repository.members.filter { member in
                !checkedInIds.contains(member.id)
            }

            print(
                "📊 For date ID \(dateId): \(checkedInIds.count) checked in, \(missingMembers.count) missing"
            )
        } catch {
            errorMessage = "Failed to load attendance: \(error.localizedDescription)"
            showErrorAlert = true
            print("❌ Error loading missing members: \(error)")
            missingMembers = []
        }
    }
}

struct MissingMembersView_Preview: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
