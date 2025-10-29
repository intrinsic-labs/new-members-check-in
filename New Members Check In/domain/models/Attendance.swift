//
//  Attendance.swift
//  New Members Check In
//
//  Created by Refactoring on 1/13/25.
//

import Foundation

/// Represents a complete attendance record with ID
struct Attendance: Identifiable, Codable {
    let id: Int
    let memberId: Int
    let dateId: Int

    enum CodingKeys: String, CodingKey {
        case id
        case memberId = "member_id"
        case dateId = "date_id"
    }
}

/// Simplified attendance record used when fetching attendance by date
/// (Only contains member_id, used for building Set<Int> of checked-in members)
struct AttendanceRecord: Codable {
    let memberId: Int

    enum CodingKeys: String, CodingKey {
        case memberId = "member_id"
    }
}
