//
//  HomepageView.swift
//  New Members Check In
//
//  Created by Asher Pope on 1/13/23.
//


import SwiftUI

struct HomepageView: View {
    @EnvironmentObject var user: AirtableUser
    @EnvironmentObject var airtable: Airtable
    
    @State private var flipButtonText = false
    @StateObject var toast = ToastModel()
    
    var body: some View {
        ZStack {
            NavigationStack {
                ZStack {
                    Color(hex: "1C3040")
                        .ignoresSafeArea()
                VStack {
                    if user.isCurrentlyViewing == .missingMembersView {
                        Spacer(minLength: 30)
                        CCCTitleView(
                            message: "Review Missing Members for a Class Date",
                            messageSize: 24,
                            omitTagline: true,
                            viewStyle: .vertical
                        ).transition(.opacity)
                        MissingMembersView()
                            .transition(.opacity)
                    }
                    
                    if user.isCurrentlyViewing == .checkInView {
                        Spacer()
                        CCCTitleView(
                            message: "New Members Class",
                            messageSize: 22,
                            omitTagline: true,
                            viewStyle: .vertical
                        ).transition(.opacity)
                        CheckInView(toastModel: toast)
                            .transition(.opacity)
                        Spacer()
                    }
                    
                    if user.isCurrentlyViewing == .nothing {
                        EmptyView()
                    }
                }
                .padding(.vertical, 30)
                .toolbar {
                    ToolbarItemGroup(placement: .bottomBar) {
                        HStack {
                            if user.isCurrentlyViewing == .checkInView {
                                Button("\(Image(systemName: "list.bullet.clipboard.fill")) View Records") {
                                    withAnimation {
                                        user.isCurrentlyViewing = .nothing
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                            withAnimation {
                                                user.isCurrentlyViewing = .missingMembersView
                                            }
                                        }
                                    }
                                }
                                .tint(.gray)
                            } else {
                                Button("\(Image(systemName: "checklist")) Check In") {
                                    withAnimation {
                                        user.isCurrentlyViewing = .nothing
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                            withAnimation {
                                                user.isCurrentlyViewing = .checkInView
                                            }
                                        }
                                    }
                                }
                                .tint(.gray)
                            }
                            
                            Spacer()
                            
                            Text(currentDate.fullFormat)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            }
            
            VStack {
                if toast.isPresented {
                    ZStack {
                        Color.black.opacity(0.5)
                        SuccessToast(toastModel: toast)
                    }
                }
            }.ignoresSafeArea()
        }.onTapGesture {
            self.hideKeyboard()
        }
    }
}



struct HomepageView_Preview: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
