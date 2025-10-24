//
//  HomepageView.swift
//  New Members Check In
//
//  Created by Asher Pope on 1/13/23.
//


import SwiftUI

struct HomepageView: View {
    @EnvironmentObject var user: AuthUser

    @StateObject var toast = ToastModel()
    
    var body: some View {
        ZStack {
            NavigationStack {
                ZStack {
                    Color(hex: "1C3040")
                        .ignoresSafeArea()
                VStack {
                    if user.isCurrentlyViewing == .missingMembersView {
                        Spacer(minLength: 25)
                        HStack {
                            CCCTitleView(
                                showMessage: false,
                                viewStyle: .horizontal
                            ).transition(.opacity)
                            Spacer()
                        }
                        MissingMembersView()
                            .transition(.opacity)
                    }
                    
                    if user.isCurrentlyViewing == .checkInView {
                        Spacer(minLength: 25)
                        HStack {
                            CCCTitleView(
                                showMessage: false,
                                viewStyle: .horizontal
                            ).transition(.opacity)
                            Spacer()
                        }
                        CheckInView(toastModel: toast)
                            .transition(.opacity)
                        Spacer()
                    }
                    
                    if user.isCurrentlyViewing == .nothing {
                        EmptyView()
                    }
                }
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
