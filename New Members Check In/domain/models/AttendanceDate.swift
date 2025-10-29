//
//  AttendanceDate.swift
//  New Members Check In
//
//  Created by Refactoring on 1/13/25.
//

import Foundation

/// Represents a class date when attendance can be recorded
struct AttendanceDate: Identifiable, Codable, Hashable {
    let id: Int
    let classDate: String  // ISO format date string: "2025-01-13"

    enum CodingKeys: String, CodingKey {
        case id
        case classDate = "class_date"
    }
}
