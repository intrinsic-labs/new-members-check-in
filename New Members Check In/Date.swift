//
//  Date.swift
//  New Members Check In
//
//  Created by Asher Pope on 1/13/23.
//

import SwiftUI

let currentDate = Date.now

extension Date {

    var numericFormat: String {
        self.formatted(date: .numeric, time: .omitted)
    }
    var fullFormat: String {
        self.formatted(date: .abbreviated, time: .omitted)
    }
    var isoFormat: String {
        self.ISO8601Format(.iso8601.year().month().day())
    }
}

extension String {
    func deciperDate() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        
        if self != "[empty date]" {
            var date = formatter.date(from: self)!
            date = date.advanced(by: 86400)
            return date.fullFormat
        }
        
        return "[empty date]"
    }
}

