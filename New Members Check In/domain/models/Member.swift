//
//  Member.swift
//  New Members Check In
//
//  Created by Refactoring on 1/13/25.
//

import Foundation

/// Represents a member in the new members class
struct Member: Identifiable, Codable, Equatable {
    let id: Int
    let firstName: String
    let lastName: String

    enum CodingKeys: String, CodingKey {
        case id
        case firstName = "first_name"
        case lastName = "last_name"
    }

    var fullName: String {
        "\(firstName) \(lastName)"
    }
}
