// File: BloodDonationApp.swift
// Purpose: Serve as the main entry point for the Blood Donation App, initializing Firebase and setting up the root view

// Import FirebaseCore for initializing Firebase services
import FirebaseCore
// Import SwiftUI for building the app's user interface
import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication
            .LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

// Define BloodDonationApp as the main app structure, conforming to the App protocol
@main
struct BloodDonationApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    // Define the main scene of the app
    var body: some Scene {
        // Create a WindowGroup to manage the app's primary window
        WindowGroup {
            // Set MainView as the root view of the app
            MainView()
                // Provide an instance of AuthManager as an environment object for authentication management
                .environmentObject(AuthManager())
        }
    }
}

/*// BloodDonationApp.swift
import SwiftUI
import FirebaseCore
import FirebaseAppCheck

@main
struct BloodDonationApp: App {
    init() {
        FirebaseApp.configure()
        AppCheck.setAppCheckProviderFactory(nil) // Disable App Check for development
        print("Firebase configured: \(FirebaseApp.app() != nil)")
    }

    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(AuthManager())
        }
    }
}*/

/*//
//  BloodDonationApp.swift
//  BloodDonationApp
//
//  Created by Student1 on 29/04/2025.
//

import SwiftUI
import FirebaseCore

@main
struct BloodDonationApp: App {
    init() {
        FirebaseApp.configure()
        print("Firebase configured: \(FirebaseApp.app() != nil)")
    }

    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(AuthManager())
        }
    }
}*/
