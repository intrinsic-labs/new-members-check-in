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
        VStack(spacing: 20) {
            if airtable.listOfAllDates != [defaultRecord] {
                let pastDates = datesBeforeToday()
                let missingMembers = membersMissingForDate(dateSelection.fields.date)
                
                // Here is the date picker
                VStack {
                    HStack(spacing: 0) {
                        Text("The members listed below did not check in on \(dateSelection.fields.date.deciperDate()).")
                            .foregroundColor(.white)
                            //.font(.headline)
                        
                        Spacer()
                        
                        Picker("Select a date", selection: $dateSelection) {
                            ForEach(pastDates, id: \.self) {
                                Text("\($0.fields.date.deciperDate()) (Week \((airtable.listOfAllDates.firstIndex(of: $0) ?? 0)+1))")
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(.orange)
                        //.background(.white.opacity(0.2))
                        .cornerRadius(10, antialiased: true)
                        
                        //Spacer()
                    }.padding()
                }
                .frame(height: 50)
                .background(Color(hex: "354959"))
                .cornerRadius(10, antialiased: true)
                .padding(.horizontal, 18)
                .padding(.top, 7)
                

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
                                                if item.fields.attendance.last?.identifyDate(in: airtable.listOfAllDates) == nil {
                                                    Text("No attendance record")
                                                        .foregroundColor(.white.opacity(0.6))
                                                } else {
                                                    Text("Last checked in on \(item.fields.attendance.last?.identifyDate(in: airtable.listOfAllDates) ?? "unknown")")
                                                        .foregroundColor(.white.opacity(0.6))
                                                }
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
                    Text("All members checked in on \(dateSelection.fields.date.deciperDate()).")
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
            await airtable.loadMembers(user: user)
        }
        .task {
            await airtable.loadDates(user: user)
            dateSelection = datesBeforeToday().last ?? defaultRecord
        }
    }
    
    func datesBeforeToday() -> [Record] {
        var pastDates = [Record]()
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        
        for date in airtable.listOfAllDates {
            let decodedDate = formatter.date(from: date.fields.date)
            
            guard let decodedDate = decodedDate else {
                print("MissingMembersView.datesBeforeToday: Could not decode date from record.fields.date")
                continue
            }
            
            if decodedDate <= currentDate {
                pastDates.append(date)
            }
            
        }
        
        return pastDates
        
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
