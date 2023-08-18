//
//  Records.swift
//  New Members Check In
//
//  Created by Asher Pope on 1/13/23.
//


struct SendableRecords: Codable {
    var records: [SendableRecord]
}

struct SendableRecord: Codable {
    var id: String
    var fields: SendableFields
}

struct SendableFields: Codable {
    var attendance: [String]
    
    enum CodingKeys: String, CodingKey {
        case attendance = "Attendance"
    }
}

struct Records: Codable {
    var records: [Record]
}

struct Record: Codable, Identifiable, Hashable {
    var id: String = "defaultRecord"
    var createdTime: String = "defaultRecord"
    var fields: Fields
}

struct Fields: Codable, Hashable {
    var lastName: String = "Default Record"
    var firstName: String = "Default Record"
    var fullName: String = "Loading Members..."
    var attendance: [String] = ["placeholderAttendanceRecordID"]
    
    var date: String = "[empty date]"
    var newMembers: [String] = ["placeholderNewMemberRecordID"]
    
    enum CodingKeys: String, CodingKey {
        case lastName = "Last Name"
        case firstName = "First Name"
        case fullName = "Full Name"
        case attendance = "Attendance"
        
        case date = "Date"
        case newMembers = "New Members"
    }
}

extension Fields {
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        lastName = try values.decodeIfPresent(String.self, forKey: .lastName) ?? "No last name found"
        firstName = try values.decodeIfPresent(String.self, forKey: .firstName) ?? "No first name found"
        fullName = try values.decodeIfPresent(String.self, forKey: .fullName) ?? "No full name found"
        attendance = try values.decodeIfPresent(Array.self, forKey: .attendance) ?? [String]()
        
        date = try values.decodeIfPresent(String.self, forKey: .date) ?? "No date found"
        newMembers = try values.decodeIfPresent(Array.self, forKey: .newMembers) ?? ["No members found"]
    }
}

// Quickly convert a date record id string into a human-readable date
extension String {
    func identifyDate(in dates: [Record]) -> String {
        for date in dates {
            if self == date.id {
                return date.fields.date.deciperDate()
            } else {
                continue
            }
        }
        return "[empty date]"
    }
}

let defaultFields = Fields()
let defaultRecord = Record(fields: defaultFields)
let defaultRecords = Records(records: [defaultRecord])
