//
//  NewMembersAirtable.swift
//  New Members Check In
//
//  Created by Asher Pope on 1/13/23.
//

import SwiftUI

@MainActor
class AirtableUser: ObservableObject {
    
    enum CurrentView {
        case loginView, checkInView, missingMembersView, nothing
    }
    
    @Published var isCurrentlyViewing: CurrentView = .loginView
    @Published var isAuthenticated = false
    
//    FOR TESTING:
//    API Key: keyeDeAlkBJKqIH7q
//    Base ID: REDACTED_AIRTABLE_BASE_ID
    @Published var apiKey: String = ""
    let baseID: String = "REDACTED_AIRTABLE_BASE_ID"
    
}



@MainActor
class Airtable: ObservableObject {
    @Published var listOfAllMembers: [Record]
    @Published var listOfAllDates: [Record]
    @Published var errorMessage: String = ""
    
    init() {
        self.listOfAllMembers = [defaultRecord]
        self.listOfAllDates = [defaultRecord]
    }
    
    func loadMembers(user: AirtableUser) async {
        let url = URL(string: "https://api.airtable.com/v0/\(user.baseID)/New%20Members?view=Grid%20View")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(user.apiKey)", forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            if let decoded = try? JSONDecoder().decode(Records.self, from: data) {
                
                self.listOfAllMembers = decoded.records
                print("Success!")
            } else {
                print(String(data: data, encoding: .utf8) ?? "")
                print("Airtable.loadMembers: Undecodable data received.")
            }
            
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func loadDates(user: AirtableUser) async {
        let url = URL(string: "https://api.airtable.com/v0/\(user.baseID)/Attendance?view=Grid%20View")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(user.apiKey)", forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                print(error.localizedDescription)
            } else if let data = data {
                Task {
                    await MainActor.run {
                        if let decoded = try? JSONDecoder().decode(Records.self, from: data) {
                            // Update dates array
                            self.listOfAllDates = decoded.records
                        } else {
                            print(String(data: data, encoding: .utf8) ?? "")
                            print("Could not decode data.")
                        }
                    }
                }
            } else {
                print("Unidentifiable error")
            }
        }
        task.resume()
    }
    
        
    func updateRecords(for selection: [Record], user: AirtableUser) async {
            if selection != [defaultRecord] {
                let url = URL(string: "https://api.airtable.com/v0/\(user.baseID)/New%20Members")!
                var request = URLRequest(url: url)
                request.setValue("Bearer \(user.apiKey)", forHTTPHeaderField: "Authorization")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpMethod = "PATCH"
                
                // Convert the current selection array into sendable objects
                var nameSelectionSendableRecords = [SendableRecord]()
                for name in selection {
                    let sendableFields = SendableFields(attendance: name.fields.attendance)
                    let sendableRecord = SendableRecord(id: name.id, fields: sendableFields)
                    nameSelectionSendableRecords.append(sendableRecord)
                }
                let toEncode = SendableRecords(records: nameSelectionSendableRecords)
                print(toEncode.records.description)
                guard let encoded = try? JSONEncoder().encode(toEncode) else {
                    print("Airtable.updateRecords: could not encode let constant 'toEncode'")
                    return
                }
                // Make the HTTP request
                do {
                    let (data, _) = try await URLSession.shared.upload(for: request, from: encoded)
                    print(String(data: data, encoding: .utf8)!)
                   
                } catch {
                    print(error.localizedDescription)
                }
            } else {
                print("Airtable.updateRecords: provided selection is [defaultRecord].")
            }
        }
    
    func authenticateUser(_ user: AirtableUser) async {
        let url = URL(string: "https://api.airtable.com/v0/\(user.baseID)/New%20Members?maxRecords=1")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(user.apiKey)", forHTTPHeaderField: "Authorization")
        
        let session = URLSession.shared
        let dataTask = session.dataTask(with: request) { (_, response, error) in
            if let error = error {
                print(error.localizedDescription)
            }
            guard let response = response as? HTTPURLResponse else { return }
            
            if response.statusCode == 200 {
                Task {
                    await MainActor.run {
                        UserDefaults.standard.setValue(user.apiKey, forKey: "localAPIKey")
                        user.isAuthenticated = true
                    }
                }
            } else {
                print(response.statusCode)
                Task {
                    await MainActor.run {
                        self.errorMessage = "That API Key didn't work. Please try again."
                    }
                }
            }
        }
        
        dataTask.resume()
        
        
    }
}

