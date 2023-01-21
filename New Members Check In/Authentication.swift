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
    
    @State private var localAPIKey = UserDefaults.standard.string(forKey: "localAPIKey")
    @State private var showingError = false
    @FocusState private var currentFocus: KeyboardFocus?
    
    //    FOR TESTING:
    //    API Key: keyeDeAlkBJKqIH7q
    
    var body: some View {
            VStack(spacing: 30) {
                Text("Airtable API Key")
                    .cccSubtitle(italic: false)
                    .foregroundColor(.white)
                
                SecureField("", text: $user.apiKey)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: 330, maxHeight: 45)
                    .background(Color(hex: "354959"))
                    .cornerRadius(10, antialiased: true)
                    .focused($currentFocus, equals: .apiKeyField)

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
                if localAPIKey != nil {
                    user.apiKey = localAPIKey ?? ""
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
