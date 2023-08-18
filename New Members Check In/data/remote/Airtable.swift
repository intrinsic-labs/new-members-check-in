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
    //    API Token: patd2M1JxX7MmxCY0.5b0678f6cbe5a823c9b41f3e4666ced64ebf4ffbd91efb96613f498d8587e57a
    //    Base ID: appOF6u4kcIz7OPNR
    @Published var apiToken: String = ""
    let baseID: String = "appM9E6gadZ36GN2Y"
    
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
        
        // build out url to Airtable base
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.airtable.com"
        components.path = "/v0/\(user.baseID)/New Members"
        components.queryItems = [
            URLQueryItem(name: "offset", value: "0"),
            URLQueryItem(name: "view", value: "Grid View")
        ]
        print(components.string ?? "error with url")
        
        var request = URLRequest(url: components.url!)
        request.setValue("Bearer \(user.apiToken)", forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            if let decoded = try? JSONDecoder().decode(Records.self, from: data) {
                
                self.listOfAllMembers = decoded.records
                print("Offset received: " + decoded.offest)
                
                if decoded.offest != "" { // if there are more records, get those too
                    print("Trying another request...")
                    components.queryItems = [
                        URLQueryItem(name: "offset", value: decoded.offest)
                    ]
                    request = URLRequest(url: components.url!)
                    request.setValue("Bearer \(user.apiToken)", forHTTPHeaderField: "Authorization")
                    request.httpMethod = "GET"
                    
                    
                    do {
                        let (data, _) = try await URLSession.shared.data(for: request)
                        if let decoded = try? JSONDecoder().decode(Records.self, from: data) {
                            
                            self.listOfAllMembers += decoded.records
                            //print(String(data: data, encoding: .utf8) ?? "")
                        }
                    } catch {
                        print(error.localizedDescription)
                    }
                    
                }
                
            } else {
                print(String(data: data, encoding: .utf8) ?? "")
                print("Airtable.loadMembers: Undecodable data received.")
            }
            
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func loadDates(user: AirtableUser) async {
        let urlStr = "https://api.airtable.com/v0/\(user.baseID)/Attendance?view=Grid%20View"
        let url = URL(string: urlStr)!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(user.apiToken)", forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            if let decoded = try? JSONDecoder().decode(Records.self, from: data) {
                
                // Update dates array
                self.listOfAllDates = decoded.records
                //print(String(data: data, encoding: .utf8) ?? "")
                
            } else {
                print(String(data: data, encoding: .utf8) ?? "")
                print("Could not decode data.")
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    
    func updateRecords(for selection: [Record], user: AirtableUser) async {
        if selection != [defaultRecord] {
            let url = URL(string: "https://api.airtable.com/v0/\(user.baseID)/New%20Members")!
            var request = URLRequest(url: url)
            request.setValue("Bearer \(user.apiToken)", forHTTPHeaderField: "Authorization")
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
        request.setValue("Bearer \(user.apiToken)", forHTTPHeaderField: "Authorization")
        
        let session = URLSession.shared
        let dataTask = session.dataTask(with: request) { (_, response, error) in
            if let error = error {
                print(error.localizedDescription)
            }
            guard let response = response as? HTTPURLResponse else { return }
            
            if response.statusCode == 200 {
                Task {
                    await MainActor.run {
                        UserDefaults.standard.setValue(user.apiToken, forKey: "localAPIToken")
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


