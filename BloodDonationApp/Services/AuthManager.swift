// File: AuthManager.swift
// Project: BloodDonationApp
// Purpose: Manage user authentication and user data for the Blood Donation App
// Created by Student1 on 28/04/2025

import FirebaseAuth
import FirebaseFirestore
import FirebaseFunctions
import GoogleSignIn
import Combine

class AuthManager: ObservableObject {
    @Published var user: AppUser?
    private let db = Firestore.firestore()
    private let functions = Functions.functions()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Listen for authentication state changes
        Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            guard let self = self else { return }
            print("DEBUG: Auth state changed, user: \(firebaseUser?.uid ?? "nil")")
            if let firebaseUser = firebaseUser {
                self.fetchUserData(userId: firebaseUser.uid)
            } else {
                print("DEBUG: No authenticated user, setting user to nil")
                self.user = nil
            }
        }
    }
    
    private func fetchUserData(userId: String) {
        // Fetch user data from Firestore
        db.collection("users").document(userId).getDocument { [weak self] document, error in
            guard let self = self else { return }
            
            if let error = error {
                print("DEBUG: Error fetching Firestore user data: \(error.localizedDescription)")
                // Fallback to Firebase Auth data
                let email = Auth.auth().currentUser?.email ?? ""
                let name = Auth.auth().currentUser?.displayName ?? ""
                self.user = AppUser(id: userId, email: email, name: name, role: "donor", isActive: true, streaks: 0)
                return
            }
            
            if let document = document, document.exists {
                do {
                    let appUser = try document.data(as: AppUser.self)
                    print("DEBUG: Fetched user data from Firestore: \(appUser)")
                    self.user = appUser
                } catch {
                    print("DEBUG: Error decoding user: \(error.localizedDescription)")
                    // Fallback to Firebase Auth data with default donor role
                    let email = Auth.auth().currentUser?.email ?? ""
                    let name = Auth.auth().currentUser?.displayName ?? ""
                    self.user = AppUser(id: userId, email: email, name: name, role: "donor", isActive: true, streaks: 0)
                }
            } else {
                print("DEBUG: User document does not exist in Firestore")
                // Create a default user document
                let email = Auth.auth().currentUser?.email ?? ""
                let name = Auth.auth().currentUser?.displayName ?? ""
                let userData = AppUser(id: userId, email: email, name: name, role: "donor", isActive: true, streaks: 0)
                do {
                    try db.collection("users").document(userId).setData(from: userData)
                    print("DEBUG: Created default user document: \(userData)")
                    self.user = userData
                } catch {
                    print("DEBUG: Error creating default user document: \(error.localizedDescription)")
                    self.user = userData // Set user anyway to allow redirect
                }
            }
        }
    }
    
    func signIn(email: String, password: String, completion: @escaping (Error?) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else {
                completion(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "AuthManager unavailable"]))
                return
            }
            
            if let error = error {
                print("DEBUG: Sign-in error: \(error.localizedDescription)")
                completion(error)
                return
            }
            
            print("DEBUG: Email sign-in successful, user: \(result?.user.uid ?? "unknown")")
            // User data will be fetched via state change listener
            completion(nil)
        }
    }
    
    func signUp(email: String, password: String, name: String, role: String, completion: @escaping (Error?) -> Void) {
        // Restrict sign-up to donors only
        guard role == "donor" else {
            print("DEBUG: Sign-up failed: Only donors can create accounts")
            completion(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Only donors can create accounts"]))
            return
        }
        
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else {
                completion(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "AuthManager unavailable"]))
                return
            }
            
            if let error = error {
                print("DEBUG: Sign-up error: \(error.localizedDescription)")
                completion(error)
                return
            }
            
            guard let firebaseUser = result?.user else {
                print("DEBUG: Sign-up failed: No Firebase user created")
                completion(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User creation failed"]))
                return
            }
            
            // Set custom claim for role
            functions.httpsCallable("setUserRole").call(["userId": firebaseUser.uid, "role": role]) { result, error in
                if let error = error {
                    print("DEBUG: Error setting user role: \(error.localizedDescription)")
                    completion(error)
                    return
                }
                
                // Create user document in Firestore
                let userData = AppUser(id: firebaseUser.uid, email: email, name: name, role: role, isActive: true, streaks: 0)
                do {
                    try self.db.collection("users").document(firebaseUser.uid).setData(from: userData)
                    print("DEBUG: Created Firestore user document: \(userData)")
                    self.user = userData // Update user to trigger redirect
                    completion(nil)
                } catch {
                    print("DEBUG: Error saving user to Firestore: \(error.localizedDescription)")
                    completion(error)
                }
            }
        }
    }
    
    func signInWithGoogle(idToken: String, accessToken: String, email: String, name: String, completion: @escaping (Error?) -> Void) {
        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
        
        Auth.auth().signIn(with: credential) { [weak self] result, error in
            guard let self = self else {
                completion(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "AuthManager unavailable"]))
                return
            }
            
            if let error = error {
                print("DEBUG: Google Sign-In error: \(error.localizedDescription)")
                completion(error)
                return
            }
            
            guard let firebaseUser = result?.user else {
                print("DEBUG: Google Sign-In failed: No Firebase user")
                completion(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Google Sign-In failed"]))
                return
            }
            
            // Check if user exists in Firestore
            db.collection("users").document(firebaseUser.uid).getDocument { [weak self] snapshot, error in
                guard let self = self else {
                    completion(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "AuthManager unavailable"]))
                    return
                }
                
                if let error = error {
                    print("DEBUG: Error checking user existence: \(error.localizedDescription)")
                    completion(error)
                    return
                }
                
                if snapshot?.exists == true {
                    // Existing user, fetch data via state change listener
                    print("DEBUG: Existing Google user, fetching data: \(firebaseUser.uid)")
                    completion(nil)
                } else {
                    // New user, create with donor role
                    let role = "donor"
                    functions.httpsCallable("setUserRole").call(["userId": firebaseUser.uid, "role": role]) { result, error in
                        if let error = error {
                            print("DEBUG: Error setting role for Google user: \(error.localizedDescription)")
                            completion(error)
                            return
                        }
                        
                        // Create user document in Firestore
                        let userData = AppUser(id: firebaseUser.uid, email: email, name: name, role: role, isActive: true, streaks: 0)
                        do {
                            try self.db.collection("users").document(firebaseUser.uid).setData(from: userData)
                            print("DEBUG: Created Google user document: \(userData)")
                            self.user = userData // Update user to trigger redirect
                            completion(nil)
                        } catch {
                            print("DEBUG: Error saving Google user to Firestore: \(error.localizedDescription)")
                            completion(error)
                        }
                    }
                }
            }
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            print("DEBUG: Signed out successfully")
            self.user = nil
        } catch {
            print("DEBUG: Sign-out error: \(error.localizedDescription)")
        }
    }
}




































































































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
