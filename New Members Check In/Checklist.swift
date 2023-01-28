//
//  Checklist.swift
//  New Members Check In
//
//  Created by Asher Pope on 1/13/23.
//

import SwiftUI

class ChecklistModel: ObservableObject {
    @Published var selectedMembers = [Record]()
    
    func append(_ record: Record) -> Void {
        selectedMembers.append(record)
    }
    
    func remove(_ record: Record) -> Void {
        var loc = 0
        for member in selectedMembers {
            if member == record {
                loc = selectedMembers.firstIndex(of: record) ?? 0
            }
        }
        selectedMembers.remove(at: loc)
    }
}

struct ChecklistView: View {
    var record: Record
    var appendMethod: (Record) -> Void
    var removeMethod: (Record) -> Void
    @State private var isSelected: Bool = false
    
    var body: some View {
        
        Button(action: {
            isSelected.toggle()
            isSelected ? appendMethod(record) : removeMethod(record)
        }) {
            ZStack {
                isSelected ? Color.white.opacity(0.32) : Color(hex: "354959")
                //Build out checklist text
                HStack {
                    Text(isSelected ? Image(systemName: "circle.inset.filled") : Image(systemName: "circle"))
                        .font(.title2)
                        .foregroundColor(isSelected ? .white : .white)
                        .padding(.horizontal)
                    VStack(spacing: 0) {
                        Spacer()
                        HStack(spacing: 5) {
                            if isSelected {
                                Text(record.fields.fullName)
                                    .foregroundColor(.white)
                                    //.bold()
                            } else {
                                Text(record.fields.fullName)
                                    .foregroundColor(.white)
                            }
                            Spacer()
                        }
                        
                        Spacer()
                        
                        //Add row divider
                        Color.gray
                            .frame(height: 0.5)
                            .opacity(0.5)
                        
                    }.frame(height: 50)
                    
                }
            }
        }
    }
}

