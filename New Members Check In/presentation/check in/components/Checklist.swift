//
//  Checklist.swift
//  New Members Check In
//
//  Created by Asher Pope on 1/13/23.
//

import SwiftUI

class ChecklistModel: ObservableObject {
    @Published var selectedMembers = [Member]()

    func append(_ member: Member) -> Void {
        selectedMembers.append(member)
    }

    func remove(_ member: Member) -> Void {
        selectedMembers.removeAll { $0.id == member.id }
    }
}

struct ChecklistViewNew: View {
    var member: Member
    @ObservedObject var checklist: ChecklistModel
    @State private var isSelected: Bool = false

    var body: some View {
        Button(action: {
            isSelected.toggle()
            isSelected ? checklist.append(member) : checklist.remove(member)
        }) {
            ZStack {
                isSelected ? Color.white.opacity(0.32) : Color(hex: "354959")
                //Build out checklist text
                HStack {
                    Text(isSelected ? Image(systemName: "circle.inset.filled") : Image(systemName: "circle"))
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding(.horizontal)
                    VStack(spacing: 0) {
                        Spacer()
                        HStack(spacing: 5) {
                            Text(member.fullName)
                                .foregroundColor(.white)
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

