//
//  CheckInView.swift
//  New Members Check In
//
//  Created by Asher Pope on 1/13/23.
//


import SwiftUI

struct CheckInView: View {
    @EnvironmentObject var user: AirtableUser
    @EnvironmentObject var airtable: Airtable

    @State private var dateSelection: Record = defaultRecord
    @StateObject var checklist = ChecklistModel()
    @State private var showingErrorAlert = false
    @State private var errorAlertMessage = ""
    @State private var showingLogoutAlert = false
    @StateObject var searchbarModel = SearchbarModel()
    @State var toastModel: ToastModel
    
    @FocusState private var keyboardFocus: KeyboardFocus?
    
    // Find out if there is a date record in Airtable matching the current date
    func airtableCurrentDate() -> Record {
        var airtableToday = defaultRecord
        for date in airtable.listOfAllDates {
            if date.fields.date == currentDate.isoFormat {
                airtableToday = date
            } else {
                continue
            }
        }
        return airtableToday
    }
    
    // Create a list of people who have not checked in today
    var listOfUncheckedMembers: [Record] {
        var notCheckedIn = [Record]()
        for member in airtable.listOfAllMembers {
            if airtableCurrentDate().fields.newMembers.contains(member.id) {
                continue
            } else {
                notCheckedIn.append(member)
            }
        }
        return notCheckedIn
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 10) {
                if airtable.listOfAllDates != [defaultRecord] {
                    if listOfUncheckedMembers != [] {
                        VStack(spacing: 20) {
                            Searchbar(searchModel: searchbarModel)
                                .focused($keyboardFocus, equals: .searchbar)
                                .onSubmit {
                                    keyboardFocus = nil
                                }
                            ScrollView {
                                LazyVStack(spacing: 0) {
                                    ForEach(listOfUncheckedMembers, id: \.self) { member in
                                        
                                        // If there is a search:
                                        if searchbarModel.searchText != "" {
                                            if member.fields.fullName.lowercased().contains(searchbarModel.searchText.lowercased()) {
                                                ChecklistView(record: member, appendMethod: checklist.append, removeMethod: checklist.remove)
                                            }
                                            
                                        // If there isn't a search, load all unchecked members
                                        } else {
                                            ChecklistView(record: member, appendMethod: checklist.append, removeMethod: checklist.remove)
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
                                    
                                    // Make sure there is date record in Airtable matching the current date
                                    let airtableToday = airtableCurrentDate()
                                    if airtableToday == defaultRecord {
                                        errorAlertMessage = "There is no class scheduled for today."
                                        showingErrorAlert = true
                                        return
                                    }
                                    
                                    // Add today's date to selected members' attendance records
                                    var loc = 0
                                    var runLoop = true
                                    while runLoop {
                                        checklist.selectedMembers[loc].fields.attendance.append(airtableToday.id)
                                        loc += 1
                                        if checklist.selectedMembers.count == 1 || loc == (checklist.selectedMembers.endIndex) {
                                            runLoop = false
                                        }
                                    }
                                    
                                    // Push it up to the Airtable server with a PATCH request
                                    await airtable.updateRecords(for: checklist.selectedMembers, user: user)
                                    
                                    // Load listOfAllDates using data from Airtable
                                    await airtable.loadDates(user: user)
                                    
                                    checklist.selectedMembers = []
                                    searchbarModel.searchText = ""
                                    
                                    print("airtable.updateRecords: Successfully updated records!")
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
                            
                            // The most complicated string possible
                            Text(
                                checklist.selectedMembers.count == 0 ?
                                "Select a name to see most recent check in date." :
                                    "\(checklist.selectedMembers.last?.fields.fullName ?? "Unknown Name") last checked in on \(checklist.selectedMembers.last?.fields.attendance.last?.identifyDate(in: airtable.listOfAllDates) ?? "unknown")")
                            .foregroundColor(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 18)
                        
                        .onChange(of: searchbarModel.searchText) { newText in
                            if newText.lowercased() == "airtable.logout" {
                                showingLogoutAlert.toggle()
                            }
                        }
                        
                        .alert("Do you really want to log out of Airtable?", isPresented: $showingLogoutAlert) {
                            Text("You will have to re-enter your API key.")
                            
                            Button("Cancel", role: .cancel) { }
                            
                            Button("Log Out") {
                                user.apiToken = ""
                                UserDefaults.standard.set("", forKey: "localAPIToken")
                                user.isAuthenticated = false
                                user.isCurrentlyViewing = .loginView
                            }
                        }
                        
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
                // Load listOfAllMembers using data from Airtable endpoint "New Members"
                await airtable.loadMembers(user: user)
                print("Loading members...")
            }
            .task {
                // Load listOfAllDates using data from Airtable endpoint "Attendance"
                await airtable.loadDates(user: user)
                print("Loading dates...")
            }
            .onAppear {
                Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { timer in
                    Task {
                        await airtable.loadMembers(user: user)
                        await airtable.loadDates(user: user)
                        print("Refreshed Attendance \(Date.now.formatted(date: .omitted, time: .standard))")
                    }
                    if user.isCurrentlyViewing != .checkInView {
                        timer.invalidate()
                    }
                }
            }
        }
    }
}


struct CheckInView_Preview: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
