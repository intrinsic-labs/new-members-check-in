//
//  AirtableLoginView.swift
//  New Members Check In
//
//  Created by Asher Pope on 1/13/23.
//

import SwiftUI

struct AirtableAuthenticationView: View {
    @EnvironmentObject var user: AirtableUser
    @EnvironmentObject var airtable: Airtable
    
    @State private var localAPIToken = UserDefaults.standard.string(forKey: "localAPIToken")
    @State private var showingError = false
    @FocusState private var currentFocus: KeyboardFocus?
    
    //    FOR TESTING:
    //    API Token: REDACTED_AIRTABLE_PAT
    
    var body: some View {
            VStack(spacing: 30) {
                Image(systemName: "lock.fill")
                    .foregroundColor(.white)
                    .font(.largeTitle)
                
                Text("Airtable API Token")
                    .cccSubtitle(italic: false)
                    .foregroundColor(.white)
                
                SecureField("", text: $user.apiToken)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: 330, maxHeight: 45)
                    .background(Color(hex: "354959"))
                    .cornerRadius(10, antialiased: true)
                    .focused($currentFocus, equals: .apiTokenField)

                Text(airtable.errorMessage)
                    .foregroundColor(.orange)
                    .opacity(showingError ? 1 : 0)

                
                Button("Submit") {
                    Task {
                        await authenticateUser()
                    }
                }
                .buttonStyle(.bordered)
                .tint(.white)
                
            }
            .onSubmit {
                currentFocus = nil
                Task {
                    await authenticateUser()
                }
            }
            .padding(.horizontal, 30)
            .onAppear {
                if localAPIToken != nil {
                    user.apiToken = localAPIToken ?? ""
                }
            }
            .onChange(of: user.isAuthenticated) { newValue in
                if newValue {
                    withAnimation {
                        user.isCurrentlyViewing = .nothing
                    }
                }
            }
        
    }
    
    func authenticateUser() async {
        Task {
            await airtable.authenticateUser(user)
            if !user.isAuthenticated {
                showingError = true
            }
        }
    }
}



struct AirtableLoginView_Preview: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
