//
//  ContentView.swift
//  New Members Check In
//
//  Created by Asher Pope on 1/13/23.
//

import SwiftUI
import Network

enum KeyboardFocus {
    case searchbar, apiTokenField
}

#if canImport(UIKit)
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif

struct ContentView: View {
    @StateObject var user = AirtableUser()
    @StateObject var airtable = Airtable()
    let monitor = NWPathMonitor()
    @State private var networkConnection = true
    
    var body: some View {
        ZStack {
            Color(hex: "1C3040")
                .ignoresSafeArea()
            if !networkConnection {
                VStack(spacing: 20) {
                    Text(Image(systemName: "wifi.slash"))
                        .font(.title)
                        .foregroundColor(.white)
                    Text("No Internet Connection")
                        .font(.title3)
                        .foregroundColor(.white)
                }
            } else if user.isCurrentlyViewing == .loginView {
                    AirtableAuthenticationView()
            } else {
                HomepageView()
            }
            
        }
        .environmentObject(user)
        .environmentObject(airtable)
        .onAppear {
            monitor.pathUpdateHandler = { path in
                if path.status == .satisfied {
                    networkConnection = true
                    print("Network connection established")
                } else {
                    networkConnection = false
                    print("No internet connection")
                }
            }
            
            let queue = DispatchQueue(label: "Monitor")
            monitor.start(queue: queue)
            
//            FOR TESTING ONLY (Comment out before archiving):
//            user.apiToken = "REDACTED_AIRTABLE_PAT"
//            Task {
//                await airtable.authenticateUser(user)
//            }
            
            let savedAPIToken = UserDefaults.standard.string(forKey: "localAPIToken")
            if let savedAPIToken = savedAPIToken {
                user.apiToken = savedAPIToken
                Task {
                    await airtable.authenticateUser(user)
                }
            }
        }
        .onChange(of: user.isAuthenticated) { newValue in
            if newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation {
                        user.isCurrentlyViewing = .checkInView
                    }
                }
            }
        }
    }
}




struct ContentView_Preview: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
