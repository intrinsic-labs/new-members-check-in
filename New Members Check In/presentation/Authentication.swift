//
//  Authentication.swift
//  New Members Check In
//
//  Created by Asher Pope on 1/13/23.
//

import SwiftUI

struct AuthenticationView: View {
    @EnvironmentObject var user: AuthUser

    @State private var email = ""
    @State private var password = ""
    @FocusState private var currentFocus: KeyboardFocus?

    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "lock.fill")
                .foregroundColor(.white)
                .font(.largeTitle)

            Text("Sign In")
                .cccSubtitle(italic: false)
                .foregroundColor(.white)

            // Email field
            TextField("Email", text: $email)
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: 330, maxHeight: 45)
                .background(Color(hex: "354959"))
                .cornerRadius(10, antialiased: true)
                .focused($currentFocus, equals: .apiTokenField)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .disableAutocorrection(true)

            // Password field
            SecureField("Password", text: $password)
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: 330, maxHeight: 45)
                .background(Color(hex: "354959"))
                .cornerRadius(10, antialiased: true)

            // Error message
            if !user.errorMessage.isEmpty {
                Text(user.errorMessage)
                    .foregroundColor(.orange)
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }

            // Sign in button
            Button(action: {
                Task {
                    await signIn()
                }
            }) {
                if user.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Sign In")
                }
            }
            .buttonStyle(.bordered)
            .tint(.white)
            .disabled(email.isEmpty || password.isEmpty || user.isLoading)

            Spacer()
        }
        .onSubmit {
            currentFocus = nil
            Task {
                await signIn()
            }
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 50)
    }

    private func signIn() async {
        guard !email.isEmpty && !password.isEmpty else {
            return
        }

        await user.signIn(email: email, password: password)
    }
}

struct AuthenticationView_Preview: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
