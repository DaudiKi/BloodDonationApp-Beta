// File: ContentView.swift
// Project: BloodDonationApp
// Purpose: Provide a user interface for signing in or signing up to the Blood Donation App
// Created by Student1 on 28/04/2025

import SwiftUI
import GoogleSignIn
import GoogleSignInSwift

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var errorMessage = ""
    @State private var isSignUpMode = false
    @State private var isGoogleSignIn = false // Track if Google Sign-In is in progress
    @State private var isGoogleButtonPressed = false // For tap animation
    
    private let deepRed = Color(red: 0.7, green: 0.1, blue: 0.1)
    private let cream = Color(red: 0.98, green: 0.96, blue: 0.9)
    
    var body: some View {
        NavigationStack {
            if let user = authManager.user {
                // Navigate based on user role
                Group {
                    if user.role == "admin" {
                        AdminDashboardView()
                            .environmentObject(authManager)
                    } else {
                        DonorDashboardView()
                            .environmentObject(authManager)
                    }
                }
            } else {
                ZStack {
                    cream
                        .ignoresSafeArea()
                    
                    VStack(spacing: 25) {
                        Image(systemName: "drop.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 80, height: 80)
                            .foregroundColor(deepRed)
                            .padding(.top, 30)
                        
                        Text("Blood Donation")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(deepRed)
                        
                        Text("Save Lives")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(deepRed.opacity(0.8))
                            .padding(.bottom, 20)
                        
                        VStack(spacing: 15) {
                            if isSignUpMode {
                                customTextField(title: "Name", text: $name, icon: "person.fill")
                            }
                            
                            customTextField(title: "Email", text: $email, icon: "envelope.fill")
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                            
                            if !isGoogleSignIn { // Hide password field during Google Sign-In
                                customSecureField(title: "Password", text: $password, icon: "lock.fill")
                            }
                            
                            if !errorMessage.isEmpty {
                                Text(errorMessage)
                                    .foregroundColor(.red)
                                    .font(.system(size: 14))
                                    .padding(.horizontal)
                                    .multilineTextAlignment(.center)
                            }
                            
                            Button(action: {
                                if isSignUpMode {
                                    validateAndSignUp()
                                } else {
                                    validateAndLogin()
                                }
                            }) {
                                Text(isSignUpMode ? "Create Account" : "Sign In")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(isFormValid ? deepRed : deepRed.opacity(0.4))
                                    .cornerRadius(10)
                            }
                            .disabled(!isFormValid)
                            .padding(.horizontal)
                            .padding(.top, 10)
                            
                            if isSignUpMode {
                                Button(action: {
                                    handleGoogleSignIn()
                                }) {
                                    HStack {
                                        Image(systemName: "g.circle.fill")
                                            .foregroundColor(.white)
                                            .font(.system(size: 20))
                                        Text("Sign in with Google")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.white)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        ZStack {
                                            // Glassy background
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color.white.opacity(0.3),
                                                    Color.gray.opacity(0.2)
                                                ]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                            .blur(radius: 10)
                                            // Subtle deepRed tint
                                            Color(deepRed).opacity(0.1)
                                        }
                                    )
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(deepRed.opacity(0.5), lineWidth: 1)
                                    )
                                    .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
                                    .scaleEffect(isGoogleButtonPressed ? 0.95 : 1.0)
                                    .animation(.easeInOut(duration: 0.2), value: isGoogleButtonPressed)
                                }
                                .padding(.horizontal)
                                .frame(height: 44)
                                .simultaneousGesture(
                                    DragGesture(minimumDistance: 0)
                                        .onChanged { _ in isGoogleButtonPressed = true }
                                        .onEnded { _ in isGoogleButtonPressed = false }
                                )
                            }
                            
                            Button(action: {
                                withAnimation {
                                    isSignUpMode.toggle()
                                    errorMessage = ""
                                    isGoogleSignIn = false
                                    name = ""
                                    email = ""
                                    password = ""
                                }
                            }) {
                                Text(isSignUpMode ? "Already have an account? Sign In" : "New user? Create Account")
                                    .foregroundColor(deepRed)
                                    .underline()
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .padding(.vertical)
                        }
                        .padding(.vertical, 20)
                        .padding(.horizontal, 15)
                        .background(Color.white)
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                        .padding(.horizontal, 20)
                        
                        Spacer()
                    }
                    .padding()
                }
            }
        }
    }
    
    private func customTextField(title: String, text: Binding<String>, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(deepRed)
                .frame(width: 20)
            
            TextField(title, text: text)
                .foregroundColor(.black)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(deepRed.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal)
    }
    
    private func customSecureField(title: String, text: Binding<String>, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(deepRed)
                .frame(width: 20)
            
            SecureField(title, text: text)
                .foregroundColor(.black)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(deepRed.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal)
    }
    
    private var isFormValid: Bool {
        if isSignUpMode {
            if isGoogleSignIn {
                return !name.isEmpty && !email.isEmpty && email.contains("@")
            } else {
                return !name.isEmpty && !email.isEmpty && email.contains("@") && password.count >= 6
            }
        } else {
            return !email.isEmpty && email.contains("@") && password.count >= 6
        }
    }
    
    private func validateAndLogin() {
        guard isFormValid else {
            errorMessage = "Please enter a valid email and a password with at least 6 characters."
            return
        }
        
        authManager.signIn(email: email, password: password) { error in
            if let error = error {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func validateAndSignUp() {
        guard isFormValid else {
            errorMessage = "Please fill all fields correctly. Ensure name is not empty, email is valid, and password is at least 6 characters."
            return
        }
        
        authManager.signUp(email: email, password: password, name: name, role: "donor") { error in
            if let error = error {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func handleGoogleSignIn() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            errorMessage = "Unable to initiate Google Sign-In."
            return
        }
        
        // Set Google Sign-In state
        isGoogleSignIn = true
        
        // Perform Google Sign-In with additional scopes
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController, hint: nil, additionalScopes: ["email", "profile"]) { signInResult, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    self.isGoogleSignIn = false
                    return
                }
                
                guard let signInResult = signInResult else {
                    self.errorMessage = "Google Sign-In failed."
                    self.isGoogleSignIn = false
                    return
                }
                
                let user = signInResult.user
                // Debug the type and value of user.accessToken
                print("DEBUG: user.accessToken type: \(type(of: user.accessToken))")
                print("DEBUG: user.accessToken value: \(user.accessToken)")
                
                // Use user.accessToken.tokenString directly, as it's non-optional
                let accessToken = user.accessToken.tokenString
                guard let idToken = user.idToken?.tokenString,
                      let email = user.profile?.email,
                      let name = user.profile?.name else {
                    self.errorMessage = "Failed to retrieve Google account details."
                    self.isGoogleSignIn = false
                    return
                }
                
                // Populate form fields with Google data
                self.name = name
                self.email = email
                
                // Directly create account using Google Sign-In data
                self.authManager.signInWithGoogle(idToken: idToken, accessToken: accessToken, email: email, name: name) { error in
                    if let error = error {
                        self.errorMessage = error.localizedDescription
                    }
                    self.isGoogleSignIn = false
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthManager())
}









































































































/*//
//  ContentView.swift
//  BloodDonationApp
//
//  Created by Student1 on 28/04/2025.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var role = "donor"
    @State private var errorMessage = ""
    @State private var isSignUpMode = false
    
    // App theme colors
    private let deepRed = Color(red: 0.7, green: 0.1, blue: 0.1)
    private let cream = Color(red: 0.98, green: 0.96, blue: 0.9)
    private let roles = ["donor", "admin"]
    
    var body: some View {
        if authManager.user != nil {
            MainView()
                .environmentObject(authManager)
        } else {
            NavigationStack {
                ZStack {
                    // Background
                    cream
                        .ignoresSafeArea()
                    
                    VStack(spacing: 25) {
                        // App Logo/Icon
                        Image(systemName: "drop.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 80, height: 80)
                            .foregroundColor(deepRed)
                            .padding(.top, 30)
                        
                        Text("Blood Donation")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(deepRed)
                        
                        Text("Save Lives")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(deepRed.opacity(0.8))
                            .padding(.bottom, 20)
                        
                        // Form Fields in a card
                        VStack(spacing: 15) {
                            if isSignUpMode {
                                customTextField(title: "Name", text: $name, icon: "person.fill")
                            }
                            
                            customTextField(title: "Email", text: $email, icon: "envelope.fill")
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                            
                            customSecureField(title: "Password", text: $password, icon: "lock.fill")
                            
                            if isSignUpMode {
                                // Role selection
                                HStack {
                                    Image(systemName: "person.badge.shield.checkmark.fill")
                                        .foregroundColor(deepRed)
                                        .frame(width: 20)
                                    
                                    Picker("Select Role", selection: $role) {
                                        ForEach(roles, id: \.self) { role in
                                            Text(role.capitalized).tag(role)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .foregroundColor(.black)
                                }
                                .padding(.horizontal)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            
                            // Error message
                            if !errorMessage.isEmpty {
                                Text(errorMessage)
                                    .foregroundColor(.red)
                                    .font(.system(size: 14))
                                    .padding(.horizontal)
                                    .multilineTextAlignment(.center)
                            }
                            
                            // Action Button
                            Button(action: {
                                if isSignUpMode {
                                    validateAndSignUp()
                                } else {
                                    validateAndLogin()
                                }
                            }) {
                                Text(isSignUpMode ? "Create Account" : "Sign In")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(isFormValid ? deepRed : deepRed.opacity(0.4))
                                    .cornerRadius(10)
                            }
                            .disabled(!isFormValid)
                            .padding(.horizontal)
                            .padding(.top, 10)
                            
                            // Toggle between sign in and sign up
                            Button(action: {
                                withAnimation {
                                    isSignUpMode.toggle()
                                    errorMessage = ""
                                }
                            }) {
                                Text(isSignUpMode ? "Already have an account? Sign In" : "New user? Create Account")
                                    .foregroundColor(deepRed)
                                    .underline()
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .padding(.vertical)
                        }
                        .padding(.vertical, 20)
                        .padding(.horizontal, 15)
                        .background(Color.white)
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                        .padding(.horizontal, 20)
                        
                        Spacer()
                    }
                    .padding()
                }
            }
        }
    }
    
    private func customTextField(title: String, text: Binding<String>, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(deepRed)
                .frame(width: 20)
            
            TextField(title, text: text)
                .foregroundColor(.black)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(deepRed.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal)
    }
    
    private func customSecureField(title: String, text: Binding<String>, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(deepRed)
                .frame(width: 20)
            
            SecureField(title, text: text)
                .foregroundColor(.black)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(deepRed.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal)
    }
    
    // Form validation logic
    private var isFormValid: Bool {
        if isSignUpMode {
            return !name.isEmpty && !email.isEmpty && email.contains("@") && password.count >= 6 && roles.contains(role)
        } else {
            return !email.isEmpty && email.contains("@") && password.count >= 6
        }
    }
    
    // Validation and login logic
    private func validateAndLogin() {
        guard isFormValid else {
            errorMessage = "Please enter a valid email and a password with at least 6 characters."
            return
        }
        
        authManager.signIn(email: email, password: password) { error in
            if let error = error {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    // Validation and signup logic
    private func validateAndSignUp() {
        guard isFormValid else {
            errorMessage = "Please fill all fields correctly. Ensure name is not empty, email is valid, password is at least 6 characters, and a valid role is selected."
            return
        }
        
        authManager.signUp(email: email, password: password, name: name, role: role) { error in
            if let error = error {
                errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthManager())
}*/












































/*import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager // Modified: Changed from @StateObject to @EnvironmentObject
    @State private var email = ""
    @State private var password = ""
    @State private var name = "" // For sign-up
    @State private var role = "donor" // Added: For role dropdown
    @State private var errorMessage = ""
    @State private var isSignUpMode = false // Toggle between login and sign-up

    // Added: Role options for dropdown
    private let roles = ["donor", "admin"]

    var body: some View {
        if authManager.user != nil {
            MainView()
                .environmentObject(authManager)
        } else {
            // Modified: Wrapped in NavigationStack for better navigation
            NavigationStack {
                VStack {
                    Text("Blood Donation App")
                        .font(.largeTitle)
                        .padding(.bottom, 20)

                    if isSignUpMode {
                        TextField("Name", text: $name)
                            .textFieldStyle(.roundedBorder)
                            .padding(.horizontal)
                            .padding(.bottom, 10)
                    }

                    TextField("Email", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding(.horizontal)
                        .padding(.bottom, 10)

                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal)
                        .padding(.bottom, 10)

                    // Added: Role dropdown for signup
                    if isSignUpMode {
                        Picker("Role", selection: $role) {
                            ForEach(roles, id: \.self) { role in
                                Text(role.capitalized).tag(role)
                            }
                        }
                        .pickerStyle(.menu)
                        .padding(.horizontal)
                        .padding(.bottom, 10)
                    }

                    // Modified: Show error message if present
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                            .padding(.bottom, 10)
                    }

                    // Modified: Added validation check to disable button
                    Button(isSignUpMode ? "Sign Up" : "Login") {
                        if isSignUpMode {
                            validateAndSignUp()
                        } else {
                            validateAndLogin()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!isFormValid)
                    .padding(.horizontal)
                    .padding(.bottom, 10)

                    Button(isSignUpMode ? "Switch to Login" : "Switch to Sign Up") {
                        isSignUpMode.toggle()
                        errorMessage = "" // Added: Clear error message on mode switch
                    }
                    .padding(.horizontal)
                }
                .padding()
            }
        }
    }

    // Added: Form validation logic
    private var isFormValid: Bool {
        if isSignUpMode {
            return !name.isEmpty && !email.isEmpty && email.contains("@") && password.count >= 6 && roles.contains(role)
        } else {
            return !email.isEmpty && email.contains("@") && password.count >= 6
        }
    }

    // Added: Validation and login logic
    private func validateAndLogin() {
        guard isFormValid else {
            errorMessage = "Please enter a valid email and a password with at least 6 characters."
            return
        }

        authManager.signIn(email: email, password: password) { error in
            if let error = error {
                errorMessage = error.localizedDescription
            }
        }
    }

    // Added: Validation and signup logic
    private func validateAndSignUp() {
        guard isFormValid else {
            errorMessage = "Please fill all fields correctly. Ensure name is not empty, email is valid, password is at least 6 characters, and a valid role is selected."
            return
        }

        authManager.signUp(email: email, password: password, name: name, role: role) { error in
            if let error = error {
                errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthManager())
}*/
