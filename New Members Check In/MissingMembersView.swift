//
//  MissingMembersView.swift
//  New Members Check In
//
//  Created by Asher Pope on 1/13/23.
//

import SwiftUI

struct MissingMembersView: View {
    @EnvironmentObject var user: AirtableUser
    @EnvironmentObject var airtable: Airtable
    @State private var dateSelection: Record = defaultRecord
    
    //    FOR TESTING:
    //    API Key: keyeDeAlkBJKqIH7q
    
    var body: some View {
        VStack(spacing: 10) {
            if airtable.listOfAllDates != [defaultRecord] {
                let missingMembers = membersMissingForDate(dateSelection.fields.date)
                if missingMembers.count != 0 {
                    
                    // This is the list of names
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            ForEach(missingMembers, id: \.self) { item in
                                ZStack {
                                    Color(hex: "354959")
                                    //Build out item text
                                    HStack {
                                        VStack(spacing: 0) {
                                            Spacer()
                                            HStack(spacing: 5) {
                                                Text(item.fields.fullName)
                                                    .foregroundColor(.white)
                                                Text("•")
                                                    .foregroundColor(.white)
                                                Text("Last checked in on \(item.fields.attendance.last?.identifyDate(in: airtable.listOfAllDates) ?? "unknown")")
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
                    .padding(.horizontal)
                    
                    
                    
                } else {
                    Spacer()
                    Text("All members checked in on \(dateSelection.fields.date.deciperDate()).")
                        .foregroundColor(.white)
                        .font(.title3)
                    Spacer()
                }
                
                // Here is the date picker
                HStack {
                    Picker("Select a date", selection: $dateSelection) {
                        ForEach(airtable.listOfAllDates, id: \.self) {
                            Text("Week \((airtable.listOfAllDates.firstIndex(of: $0) ?? 0)+1): \($0.fields.date.deciperDate())")
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(Color(hex: "1C3040"))
                    .background(.white)
                    .cornerRadius(10, antialiased: true)
                }
                .cornerRadius(10, antialiased: true)
                .padding()
                
                
            } else {
                Spacer()
                ProgressView()
                Spacer()
            }
        }
        .task {
            await airtable.loadMembers(user: user)
        }
        .task {
            await airtable.loadDates(user: user)
            dateSelection = airtable.listOfAllDates[0]
        }
    }
    
    func membersMissingForDate(_ isoDate: String) -> [Record] {
        var missingMembers = [Record]()
        
        // Load the requested date from the Airtable list of dates.
        // If no date is found, use the defaultRecord.
        var requestedDate = defaultRecord
        for date in airtable.listOfAllDates {
            if date.fields.date == isoDate {
                requestedDate = date
            }
        }
        
        // Loop through the Airtable new members list and check
        // each member's attendance against requestedDate
        for member in airtable.listOfAllMembers {
            if member.fields.attendance.contains(requestedDate.id) {
                continue
            } else {
                // if member's attendance doesn't contain requestedDate,
                // add them to the missingMembers array
                missingMembers.append(member)
            }
        }
        return missingMembers
    }
}


struct MissingMembersView_Preview: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
