// File: ContentView.swift
// Project: BloodDonationApp
// Purpose: Provide a user interface for signing in or signing up to the Blood Donation App
// Created by Student1 on 28/04/2025

// Import SwiftUI for building the user interface
import SwiftUI

// Define ContentView, a SwiftUI View that serves as the primary interface for user authentication
struct ContentView: View {
    // Access the shared AuthManager to handle authentication operations
    @EnvironmentObject var authManager: AuthManager
    // Store the email input entered by the user
    @State private var email = ""
    // Store the password input entered by the user
    @State private var password = ""
    // Store the name input entered by the user (used in sign-up mode)
    @State private var name = ""
    // Store the selected role for sign-up (defaults to "donor")
    @State private var role = "donor"
    // Store any error message to display to the user
    @State private var errorMessage = ""
    // Track whether the view is in sign-up mode (true) or sign-in mode (false)
    @State private var isSignUpMode = false
    
    // Define custom colors for consistent UI styling
    private let deepRed = Color(red: 0.7, green: 0.1, blue: 0.1)
    private let cream = Color(red: 0.98, green: 0.96, blue: 0.9)
    // Define available roles for user selection during sign-up
    private let roles = ["donor", "admin"]
    
    // Define the main UI structure of the view
    var body: some View {
        // Check if a user is already authenticated
        if authManager.user != nil {
            // Redirect to MainView if the user is authenticated
            MainView()
                // Pass the authManager to MainView for authentication-related operations
                .environmentObject(authManager)
        } else {
            // Display the authentication interface if no user is authenticated
            NavigationStack {
                // Use ZStack to layer the background color and content
                ZStack {
                    // Set a cream-colored background that extends to all edges, ignoring safe areas
                    cream
                        .ignoresSafeArea()
                    
                    // Arrange content vertically with spacing
                    VStack(spacing: 25) {
                        // Display the app logo/icon
                        Image(systemName: "drop.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 80, height: 80)
                            .foregroundColor(deepRed)
                            .padding(.top, 30)
                        
                        // Display the app title
                        Text("Blood Donation")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(deepRed)
                        
                        // Display a subtitle for the app
                        Text("Save Lives")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(deepRed.opacity(0.8))
                            .padding(.bottom, 20)
                        
                        // Create a form for user input
                        VStack(spacing: 15) {
                            // Show name input field in sign-up mode
                            if isSignUpMode {
                                customTextField(title: "Name", text: $name, icon: "person.fill")
                            }
                            
                            // Show email input field
                            customTextField(title: "Email", text: $email, icon: "envelope.fill")
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                            
                            // Show password input field
                            customSecureField(title: "Password", text: $password, icon: "lock.fill")
                            
                            // Show role selection picker in sign-up mode
                            if isSignUpMode {
                                HStack {
                                    // Display an icon for role selection
                                    Image(systemName: "person.badge.shield.checkmark.fill")
                                        .foregroundColor(deepRed)
                                        .frame(width: 20)
                                    
                                    // Provide a picker for selecting user role (donor or admin)
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
                            
                            // Display any error message if present
                            if !errorMessage.isEmpty {
                                Text(errorMessage)
                                    .foregroundColor(.red)
                                    .font(.system(size: 14))
                                    .padding(.horizontal)
                                    .multilineTextAlignment(.center)
                            }
                            
                            // Display the primary action button (Sign In or Create Account)
                            Button(action: {
                                if isSignUpMode {
                                    // Attempt to sign up if in sign-up mode
                                    validateAndSignUp()
                                } else {
                                    // Attempt to sign in if in sign-in mode
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
                            
                            // Provide a button to toggle between sign-in and sign-up modes
                            Button(action: {
                                // Toggle the mode and clear any error message with animation
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
                        
                        // Add spacing at the bottom
                        Spacer()
                    }
                    .padding()
                }
            }
        }
    }
    
    // Create a reusable text field component for form inputs
    private func customTextField(title: String, text: Binding<String>, icon: String) -> some View {
        // Display a text field with an icon and styled border
        HStack {
            // Show an icon associated with the input field
            Image(systemName: icon)
                .foregroundColor(deepRed)
                .frame(width: 20)
            
            // Provide a text field for user input
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
    
    // Create a reusable secure field component for password input
    private func customSecureField(title: String, text: Binding<String>, icon: String) -> some View {
        // Display a secure field for password input with an icon and styled border
        HStack {
            // Show an icon associated with the password field
            Image(systemName: icon)
                .foregroundColor(deepRed)
                .frame(width: 20)
            
            // Provide a secure field for password input to hide text
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
    
    // Validate the form inputs based on the current mode
    private var isFormValid: Bool {
        if isSignUpMode {
            // Ensure name, email, password, and role are valid for sign-up
            return !name.isEmpty && !email.isEmpty && email.contains("@") && password.count >= 6 && roles.contains(role)
        } else {
            // Ensure email and password are valid for sign-in
            return !email.isEmpty && email.contains("@") && password.count >= 6
        }
    }
    
    // Handle validation and login process
    private func validateAndLogin() {
        // Check if the form inputs are valid
        guard isFormValid else {
            errorMessage = "Please enter a valid email and a password with at least 6 characters."
            return
        }
        
        // Call the AuthManager to sign in the user
        authManager.signIn(email: email, password: password) { error in
            if let error = error {
                // Display any error message returned from the sign-in attempt
                errorMessage = error.localizedDescription
            }
        }
    }
    
    // Handle validation and sign-up process
    private func validateAndSignUp() {
        // Check if the form inputs are valid
        guard isFormValid else {
            errorMessage = "Please fill all fields correctly. Ensure name is not empty, email is valid, password is at least 6 characters, and a valid role is selected."
            return
        }
        
        // Call the AuthManager to sign up the user
        authManager.signUp(email: email, password: password, name: name, role: role) { error in
            if let error = error {
                // Display any error message returned from the sign-up attempt
                errorMessage = error.localizedDescription
            }
        }
    }
}

// Provide a preview of the ContentView for SwiftUI's canvas
#Preview {
    ContentView()
        // Provide a mock AuthManager for preview purposes
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
