// File: Donation.swift
// Purpose: Define the data model for a blood donation record in the Blood Donation App

// Import Foundation for basic Swift functionality and Codable support
import Foundation
// Import FirebaseFirestore for Firestore-specific data types like Timestamp
import FirebaseFirestore

// Define the Donation struct to represent a blood donation record in the application
struct Donation: Identifiable, Codable, Hashable {
    // Unique identifier for the donation, used to distinguish donation records in the database and UI
    let id: String
    // Identifier of the donor who made the donation, linking the donation to a specific user
    let donorId: String
    // Name of the hospital where the donation was made
    let hospital: String
    // Blood type of the donation (e.g., A+, O-, etc.)
    let bloodType: String
    // Date when the donation was made
    let date: Date
    // Status of the donation (e.g., "pending", "approved", "rejected", "used")
    let status: String
    
    // Define coding keys to map struct properties to Firestore document fields
    enum CodingKeys: String, CodingKey {
        case id
        case donorId
        case hospital
        case bloodType
        case date
        case status
    }
}


































































































/*// Donation.swift
import Foundation
import FirebaseFirestore

struct Donation: Identifiable, Codable {
    let id: String
    let donorId: String
    let hospital: String
    let bloodType: String
    let date: Date
    let status: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case donorId
        case hospital
        case bloodType
        case date
        case status
    }
}*/




















/*//
//  Donation.swift
//  BloodDonationApp
//
//  Created by Student1 on 28/04/2025.
//

import Foundation

struct Donation: Identifiable, Codable {
    let id: String
    let donorId: String
    let date: Date
    let hospital: String
    let bloodType: String
    let status: String // "pending", "approved", "rejected"
}*/
