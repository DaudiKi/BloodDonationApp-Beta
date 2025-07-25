// File: MainView.swift
// Project: BloodDonationApp
// Purpose: Serve as the root view to determine which view to display based on the user's authentication status and role
// Created by Student1 on 29/04/2025

// Import SwiftUI for building the user interface
import SwiftUI

// Define MainView, a SwiftUI View that acts as the entry point for the app's navigation
struct MainView: View {
    // Access the shared AuthManager to monitor authentication state and user data
    @EnvironmentObject var authManager: AuthManager

    // Define the main UI structure of the view
    var body: some View {
        // Use a Group to conditionally render different views based on authentication and role
        Group {
            // Check if a user is authenticated
            if let user = authManager.user {
                // Switch between views based on the user's role
                switch user.role {
                case "admin":
                    // Display the AdminDashboardView for users with the "admin" role
                    AdminDashboardView()
                        // Pass the authManager to the AdminDashboardView for authentication-related operations
                        .environmentObject(authManager)
                default:
                    // Display the DonorDashboardView for users with any other role (e.g., "donor")
                    DonorDashboardView()
                        // Pass the authManager to the DonorDashboardView for authentication-related operations
                        .environmentObject(authManager)
                }
            } else {
                // Display the ContentView (likely a login or sign-up screen) if no user is authenticated
                ContentView()
                    // Pass the authManager to the ContentView for authentication-related operations
                    .environmentObject(authManager)
            }
        }
    }
}

// Provide a preview of the MainView for SwiftUI's canvas
#Preview {
    MainView()
        // Provide a mock AuthManager for preview purposes
        .environmentObject(AuthManager())
}


































































































/*//
//  MainView.swift
//  BloodDonationApp
//
//  Created by Student1 on 29/04/2025.
//

import SwiftUI

struct MainView: View {
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        Group {
            if let user = authManager.user {
                switch user.role {
                case "admin":
                    AdminDashboardView()
                        .environmentObject(authManager) // Added: Pass authManager
                default:
                    DonorDashboardView()
                        .environmentObject(authManager) // Added: Pass authManager
                }
            } else {
                ContentView()
                    .environmentObject(authManager) // Added: Pass authManager
            }
        }
    }
}

#Preview {
    MainView()
        .environmentObject(AuthManager())
}*/
