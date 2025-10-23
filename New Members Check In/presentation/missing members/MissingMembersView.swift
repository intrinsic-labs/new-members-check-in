//
//  MissingMembersView.swift
//  New Members Check In
//
//  Created by Asher Pope on 1/13/23.
//

import SwiftUI

struct MissingMembersView: View {
    @EnvironmentObject var user: AuthUser
    @StateObject var supabase = SupabaseService()
    @State private var dateSelection: AttendanceDate?

    var body: some View {
        VStack(spacing: 20) {
            if !supabase.listOfAllDates.isEmpty {
                let pastDates = datesBeforeToday()
                let missingMembers = membersMissingForDate(dateSelection?.id ?? 0)

                // Here is the date picker
                VStack {
                    HStack(spacing: 0) {
                        if let selectedDate = dateSelection {
                            Text("The members listed below did not check in on \(selectedDate.classDate).")
                                .foregroundColor(.white)
                        } else {
                            Text("Select a date to view attendance.")
                                .foregroundColor(.white)
                        }

                        Spacer()

                        Picker("Select a date", selection: $dateSelection) {
                            ForEach(pastDates, id: \.id) { date in
                                Text(date.classDate)
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
            await supabase.loadMembers(user: user)
        }
        .task {
            await supabase.loadDates(user: user)
            dateSelection = datesBeforeToday().last
        }
    }

    func datesBeforeToday() -> [AttendanceDate] {
        let todayString = currentDate.isoFormat
        return supabase.listOfAllDates.filter { date in
            date.classDate <= todayString
        }
    }

    func membersMissingForDate(_ dateId: Int) -> [Member] {
        // Fetch attendance records for this date
        // For now, return all members since we need to query attendance table
        // This will be improved once we implement proper attendance querying
        return supabase.listOfAllMembers
    }
}


struct MissingMembersView_Preview: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
