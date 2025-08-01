// File: AuthManager.swift
// Purpose: Manage user authentication and user data operations using Firebase Authentication and Firestore

// Import FirebaseAuth for user authentication, FirebaseFirestore for database operations, and FirebaseFunctions for server-side functions
import FirebaseAuth
import FirebaseFirestore
import FirebaseFunctions
import GoogleSignIn
import GoogleSignInSwift

// Define AuthManager as an ObservableObject to handle authentication state and user data
class AuthManager: ObservableObject {
    // Published property to store the currently authenticated user, notifying the UI of changes
    @Published var user: AppUser?
    // Create a reference to the Firestore database for user data operations
    private let db = Firestore.firestore()
    // Create a reference to Firebase Functions for calling server-side logic
    private let functions = Functions.functions()

    // Handle user sign-in with email and password
    func signIn(email: String, password: String, completion: @escaping (Error?) -> Void) {
        // Attempt to sign in the user using Firebase Authentication
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            // Check for sign-in errors
            if let error = error {
                print("Sign-in error: \(error.localizedDescription)")
                completion(error)
                return
            }
            // Ensure a user ID is returned from the authentication result
            guard let userId = result?.user.uid else {
                let error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User ID not found"])
                print("Sign-in error: \(error.localizedDescription)")
                completion(error)
                return
            }
            // Fetch the user's data from Firestore after successful authentication
            self.fetchUser(userId, completion: completion)
        }
    }

    // Handle user sign-up with email, password, name, and role
    func signUp(email: String, password: String, name: String, role: String, completion: @escaping (Error?) -> Void) {
        // Create a new user account using Firebase Authentication
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            // Check for sign-up errors
            if let error = error {
                print("Sign-up error: \(error.localizedDescription)")
                completion(error)
                return
            }
            // Ensure a user ID is returned from the authentication result
            guard let userId = result?.user.uid else {
                let error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User ID not found"])
                print("Sign-up error: \(error.localizedDescription)")
                completion(error)
                return
            }
            // Create an AppUser object with the provided details
            let user = AppUser(id: userId, email: email, name: name, role: role, isActive: true, streaks: 0)
            do {
                // Encode the AppUser object to JSON and convert to a dictionary for Firestore
                let data = try JSONEncoder().encode(user)
                let dictionary = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
                // Save the user data to the Firestore "users" collection
                self.db.collection("users").document(userId).setData(dictionary) { error in
                    if let error = error {
                        print("Error saving user to Firestore: \(error.localizedDescription)")
                        completion(error)
                        return
                    }
                    // Call a Firebase Function to set the user's role as a custom claim
                    self.functions.httpsCallable("setUserRole").call(["userId": userId, "role": role]) { result, error in
                        if let error = error {
                            print("Error setting role for user \(userId): \(error.localizedDescription)")
                            completion(error)
                            return
                        }
                        // Set the user property to the newly created user and complete successfully
                        self.user = user
                        completion(nil)
                    }
                }
            } catch {
                // Handle errors during user data encoding
                print("Error encoding user data: \(error.localizedDescription)")
                completion(error)
            }
        }
    }

    // Fetch user data from Firestore for a given user ID
    func fetchUser(_ userId: String, completion: @escaping (Error?) -> Void) {
        // Retrieve the user document from the Firestore "users" collection
        db.collection("users").document(userId).getDocument { snapshot, error in
            if let error = error {
                print("Error fetching user data: \(error.localizedDescription)")
                completion(error)
                return
            }
            // Ensure user data exists in the snapshot
            guard let data = snapshot?.data() as [String: Any]? else {
                let error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User data not found"])
                print("Error fetching user data: \(error.localizedDescription)")
                completion(error)
                return
            }
            do {
                // Convert the Firestore data to JSON and decode it into an AppUser object
                let jsonData = try JSONSerialization.data(withJSONObject: data)
                let user = try JSONDecoder().decode(AppUser.self, from: jsonData)
                // Update the user property with the fetched data
                self.user = user
                completion(nil)
            } catch {
                // Handle errors during user data decoding
                print("Error decoding user data: \(error.localizedDescription)")
                completion(error)
            }
        }
    }

    // Handle user sign-out
    func signOut() {
        do {
            // Sign out the user from Firebase Authentication
            try Auth.auth().signOut()
            // Clear the user property to reflect the signed-out state
            self.user = nil
        } catch {
            // Handle errors during sign-out
            print("Sign-out error: \(error.localizedDescription)")
        }
    }
}


































































/*// File: AuthManager.swift
// Purpose: Manage user authentication and user data operations using Firebase Authentication and Firestore

// Import FirebaseAuth for user authentication, FirebaseFirestore for database operations, and FirebaseFunctions for server-side functions
import FirebaseAuth
import FirebaseFirestore
import FirebaseFunctions

// Define AuthManager as an ObservableObject to handle authentication state and user data
class AuthManager: ObservableObject {
    // Published property to store the currently authenticated user, notifying the UI of changes
    @Published var user: AppUser?
    // Create a reference to the Firestore database for user data operations
    private let db = Firestore.firestore()
    // Create a reference to Firebase Functions for calling server-side logic
    private let functions = Functions.functions()

    // Handle user sign-in with email and password
    func signIn(email: String, password: String, completion: @escaping (Error?) -> Void) {
        // Attempt to sign in the user using Firebase Authentication
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            // Check for sign-in errors
            if let error = error {
                print("Sign-in error: \(error.localizedDescription)")
                completion(error)
                return
            }
            // Ensure a user ID is returned from the authentication result
            guard let userId = result?.user.uid else {
                let error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User ID not found"])
                print("Sign-in error: \(error.localizedDescription)")
                completion(error)
                return
            }
            // Fetch the user's data from Firestore after successful authentication
            self.fetchUser(userId, completion: completion)
        }
    }

    // Handle user sign-up with email, password, name, and role
    func signUp(email: String, password: String, name: String, role: String, completion: @escaping (Error?) -> Void) {
        // Create a new user account using Firebase Authentication
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            // Check for sign-up errors
            if let error = error {
                print("Sign-up error: \(error.localizedDescription)")
                completion(error)
                return
            }
            // Ensure a user ID is returned from the authentication result
            guard let userId = result?.user.uid else {
                let error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User ID not found"])
                print("Sign-up error: \(error.localizedDescription)")
                completion(error)
                return
            }
            // Create an AppUser object with the provided details
            let user = AppUser(id: userId, email: email, name: name, role: role, isActive: true, streaks: 0)
            do {
                // Encode the AppUser object to JSON and convert to a dictionary for Firestore
                let data = try JSONEncoder().encode(user)
                let dictionary = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
                // Save the user data to the Firestore "users" collection
                self.db.collection("users").document(userId).setData(dictionary) { error in
                    if let error = error {
                        print("Error saving user to Firestore: \(error.localizedDescription)")
                        completion(error)
                        return
                    }
                    // Call a Firebase Function to set the user's role as a custom claim
                    self.functions.httpsCallable("setUserRole").call(["userId": userId, "role": role]) { result, error in
                        if let error = error {
                            print("Error setting role for user \(userId): \(error.localizedDescription)")
                            completion(error)
                            return
                        }
                        // Set the user property to the newly created user and complete successfully
                        self.user = user
                        completion(nil)
                    }
                }
            } catch {
                // Handle errors during user data encoding
                print("Error encoding user data: \(error.localizedDescription)")
                completion(error)
            }
        }
    }

    // Fetch user data from Firestore for a given user ID
    func fetchUser(_ userId: String, completion: @escaping (Error?) -> Void) {
        // Retrieve the user document from the Firestore "users" collection
        db.collection("users").document(userId).getDocument { snapshot, error in
            if let error = error {
                print("Error fetching user data: \(error.localizedDescription)")
                completion(error)
                return
            }
            // Ensure user data exists in the snapshot
            guard let data = snapshot?.data() as [String: Any]? else {
                let error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User data not found"])
                print("Error fetching user data: \(error.localizedDescription)")
                completion(error)
                return
            }
            do {
                // Convert the Firestore data to JSON and decode it into an AppUser object
                let jsonData = try JSONSerialization.data(withJSONObject: data)
                let user = try JSONDecoder().decode(AppUser.self, from: jsonData)
                // Update the user property with the fetched data
                self.user = user
                completion(nil)
            } catch {
                // Handle errors during user data decoding
                print("Error decoding user data: \(error.localizedDescription)")
                completion(error)
            }
        }
    }

    // Handle user sign-out
    func signOut() {
        do {
            // Sign out the user from Firebase Authentication
            try Auth.auth().signOut()
            // Clear the user property to reflect the signed-out state
            self.user = nil
        } catch {
            // Handle errors during sign-out
            print("Sign-out error: \(error.localizedDescription)")
        }
    }
}*/



































































































/*// AuthManager.swift
import FirebaseAuth
import FirebaseFirestore
import FirebaseFunctions

class AuthManager: ObservableObject {
    @Published var user: AppUser?
    private let db = Firestore.firestore()
    private let functions = Functions.functions()

    func signIn(email: String, password: String, completion: @escaping (Error?) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                print("Sign-in error: \(error.localizedDescription)")
                completion(error)
                return
            }
            guard let userId = result?.user.uid else {
                let error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User ID not found"])
                print("Sign-in error: \(error.localizedDescription)")
                completion(error)
                return
            }
            self.fetchUser(userId, completion: completion)
        }
    }

    func signUp(email: String, password: String, name: String, role: String, completion: @escaping (Error?) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                print("Sign-up error: \(error.localizedDescription)")
                completion(error)
                return
            }
            guard let userId = result?.user.uid else {
                let error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User ID not found"])
                print("Sign-up error: \(error.localizedDescription)")
                completion(error)
                return
            }
            let user = AppUser(id: userId, email: email, name: name, role: role, isActive: true, streaks: 0)
            do {
                let data = try JSONEncoder().encode(user)
                let dictionary = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
                self.db.collection("users").document(userId).setData(dictionary) { error in
                    if let error = error {
                        print("Error saving user to Firestore: \(error.localizedDescription)")
                        completion(error)
                        return
                    }
                    // Set custom claim for role
                    self.functions.httpsCallable("setUserRole").call(["userId": userId, "role": role]) { result, error in
                        if let error = error {
                            print("Error setting role for user \(userId): \(error.localizedDescription)")
                            completion(error)
                            return
                        }
                        self.user = user
                        completion(nil)
                    }
                }
            } catch {
                print("Error encoding user data: \(error.localizedDescription)")
                completion(error)
            }
        }
    }

    func fetchUser(_ userId: String, completion: @escaping (Error?) -> Void) {
        db.collection("users").document(userId).getDocument { snapshot, error in
            if let error = error {
                print("Error fetching user data: \(error.localizedDescription)")
                completion(error)
                return
            }
            guard let data = snapshot?.data() as [String: Any]? else {
                let error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User data not found"])
                print("Error fetching user data: \(error.localizedDescription)")
                completion(error)
                return
            }
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: data)
                let user = try JSONDecoder().decode(AppUser.self, from: jsonData)
                self.user = user
                completion(nil)
            } catch {
                print("Error decoding user data: \(error.localizedDescription)")
                completion(error)
            }
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            self.user = nil
        } catch {
            print("Sign-out error: \(error.localizedDescription)")
        }
    }
}*/






















































/*//
//  AuthManager.swift
//  BloodDonationApp
//
//  Created by Student1 on 29/04/2025.
//

import FirebaseAuth
import FirebaseFirestore

class AuthManager: ObservableObject {
    @Published var user: AppUser?
    private let db = Firestore.firestore()

    func signIn(email: String, password: String, completion: @escaping (Error?) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                completion(error)
                return
            }
            guard let userId = result?.user.uid else {
                completion(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User ID not found"]))
                return
            }
            self.fetchUser(userId, completion: completion)
        }
    }

    func signUp(email: String, password: String, name: String, role: String, completion: @escaping (Error?) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                completion(error)
                return
            }
            guard let userId = result?.user.uid else {
                completion(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User ID not found"]))
                return
            }
            let user = AppUser(id: userId, email: email, name: name, role: role, isActive: true, streaks: 0)
            // Modified: Added error handling for Firestore write
            do {
                let data = try JSONEncoder().encode(user)
                let dictionary = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
                self.db.collection("users").document(userId).setData(dictionary) { error in
                    if error == nil {
                        self.user = user
                    }
                    completion(error)
                }
            } catch {
                completion(error)
            }
        }
    }

    func fetchUser(_ userId: String, completion: @escaping (Error?) -> Void) {
        db.collection("users").document(userId).getDocument { snapshot, error in
            if let error = error {
                completion(error)
                return
            }
            guard let data = snapshot?.data() as [String: Any]? else {
                completion(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User data not found"]))
                return
            }
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: data)
                let user = try JSONDecoder().decode(AppUser.self, from: jsonData)
                self.user = user
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }

    func signOut() {
        try? Auth.auth().signOut()
        self.user = nil
    }
}*/
