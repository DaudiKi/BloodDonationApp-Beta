// File: User.swift
// Project: BloodDonationApp
// Purpose: Define the data model for a user in the Blood Donation App, representing both donors and admins
// Created by Student1 on 28/04/2025

// Import Foundation for basic Swift functionality and Codable support
import Foundation

// Define the AppUser struct to represent a user in the application
struct AppUser: Identifiable, Codable {
    // Unique identifier for the user, used to distinguish users in the database and UI
    let id: String
    // User's email address for authentication and identification
    let email: String
    // User's name for display purposes in the app
    let name: String
    // User's role, indicating whether they are a "donor" or an "admin"
    let role: String
    // Flag indicating whether the user's account is active or disabled
    let isActive: Bool
    // Number of donation streaks, representing approved donations for tracking user activity
    let streaks: Int
}


































































































/*//
//  User.swift
//  BloodDonationApp
//
//  Created by Student1 on 28/04/2025.
//

import Foundation

struct AppUser: Identifiable, Codable {
    let id: String
    let email: String
    let name: String
    let role: String // "donor" or "admin"
    let isActive: Bool
    let streaks: Int
}*/
