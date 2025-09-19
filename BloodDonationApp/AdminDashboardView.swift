import SwiftUI
import FirebaseFirestore

struct AdminDashboardView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var users: [AppUser] = []
    @State private var donations: [Donation] = []
    @State private var hospitals: [hospital] = []
    @State private var selectedTab = 0
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var togglingUserId: String?
    @State private var showDonationForm = false
    private let db = Firestore.firestore()
    
    private let deepRed = Color(red: 0.8, green: 0.1, blue: 0.1)
    private let cream = Color(red: 0.98, green: 0.96, blue: 0.9)
    private let lightRed = Color(red: 0.95, green: 0.8, blue: 0.8)
    
    var body: some View {
        NavigationView {
            ZStack {
                cream.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        SegmentButton(title: "Users", isSelected: selectedTab == 0) {
                            selectedTab = 0
                        }
                        SegmentButton(title: "Donations", isSelected: selectedTab == 1) {
                            selectedTab = 1
                        }
                        SegmentButton(title: "Active Donors", isSelected: selectedTab == 2) {
                            selectedTab = 2
                        }
                    }
                    .background(deepRed)
                    
                    TabView(selection: $selectedTab) {
                        usersListView.tag(0)
                        donationsListView.tag(1)
                        activeDonorsListView.tag(2)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    actionButtons()
                }
            }
            .navigationTitle("Admin Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(deepRed, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        authManager.signOut()
                    }) {
                        Text("Logout")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .sheet(isPresented: $showDonationForm) {
                DonationFormView(authManager: authManager, users: users.filter { $0.role != "admin" }, hospitals: hospitals)
            }
            .onAppear {
                fetchUsers()
                fetchDonations()
                fetchHospitals()
            }
        }
    }
    
    private var usersListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(users) { user in
                    userCardView(user)
                }
                .padding(.horizontal)
                .padding(.top)
            }
            .padding(.bottom)
        }
        .background(cream)
    }
    
    private var activeDonorsListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(users.filter { $0.isActive && $0.role != "admin" }) { user in
                    userCardView(user)
                }
                .padding(.horizontal)
                .padding(.top)
            }
            .padding(.bottom)
        }
        .background(cream)
    }
    
    private func userCardView(_ user: AppUser) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(user.name)
                        .font(.headline)
                        .foregroundColor(.black)
                    Text(user.email)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    HStack {
                        Circle()
                            .fill(user.isActive ? Color.green : Color.gray)
                            .frame(width: 10, height: 10)
                        Text(user.isActive ? "Active" : "Inactive")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                Button(action: {
                    Task {
                        await toggleUserStatus(user)
                    }
                }) {
                    Text(togglingUserId == user.id ? "Toggling..." : (user.isActive ? "Disable" : "Enable"))
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(user.isActive ? Color.red.opacity(0.2) : deepRed)
                        .foregroundColor(user.isActive ? .red : .white)
                        .cornerRadius(8)
                }
                .disabled(togglingUserId == user.id)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var donationsListView: some View {
        ScrollView {
            LazyVStack(spacing: 15) {
                ForEach(donations.filter { $0.status == "pending" }) { donation in
                    donationCardView(donation)
                }
                .padding(.horizontal)
                .padding(.top)
            }
            .padding(.bottom)
        }
        .background(cream)
    }
    
    private func donationCardView(_ donation: Donation) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Donor: \(users.first { $0.id == donation.donorId }?.name ?? donation.donorId)")
                    .font(.headline)
                    .foregroundColor(.black)
                Spacer()
                Text(donation.status.capitalized)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(lightRed)
                    .foregroundColor(deepRed)
                    .cornerRadius(6)
            }
            Text("Date: \(donation.date, format: .dateTime)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text("Hospital: \(donation.hospital)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            if let hospital = hospitals.first(where: { $0.name == donation.hospital }) {
                Text("Address: \(hospital.address)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            HStack(spacing: 12) {
                Button(action: {
                    Task {
                        await approveDonation(donation)
                    }
                }) {
                    HStack {
                        Image(systemName: "checkmark")
                        Text("Approve")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(deepRed)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                Button(action: {
                    Task {
                        await rejectDonation(donation)
                    }
                }) {
                    HStack {
                        Image(systemName: "xmark")
                        Text("Reject")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.black)
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private func actionButtons() -> some View {
        HStack(spacing: 15) {
            Button(action: {
                showDonationForm = true
            }) {
                HStack {
                    Image(systemName: "plus")
                    Text("Log Donation")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(deepRed)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color.white)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: -2)
    }
    
    private func SegmentButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .fontWeight(.semibold)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(isSelected ? cream : deepRed)
                .foregroundColor(isSelected ? deepRed : cream)
        }
    }
    
    private func fetchUsers() {
        db.collection("users").addSnapshotListener { snapshot, error in
            if let error = error {
                print("Error fetching users: \(error)")
                alertTitle = "Error"
                alertMessage = "Failed to fetch users: \(error.localizedDescription)"
                showAlert = true
                return
            }
            users = snapshot?.documents.compactMap { document in
                let data = document.data()
                guard let id = data["id"] as? String,
                      let email = data["email"] as? String,
                      let name = data["name"] as? String,
                      let role = data["role"] as? String,
                      let isActive = data["isActive"] as? Bool,
                      let streaks = data["streaks"] as? Int,
                      let hasNotifiedFourDonations = data["hasNotifiedFourDonations"] as? Bool else {
                    print("Failed to decode user document \(document.documentID): \(data)")
                    return nil
                }
                return AppUser(
                    id: id,
                    email: email,
                    name: name,
                    role: role,
                    isActive: isActive,
                    streaks: streaks,
                    hasNotifiedFourDonations: hasNotifiedFourDonations
                )
            } ?? []
            print("Fetched \(users.count) users")
        }
    }
    
    private func fetchDonations() {
        db.collection("donations").addSnapshotListener { snapshot, error in
            if let error = error {
                print("Error fetching donations: \(error)")
                alertTitle = "Error"
                alertMessage = "Failed to fetch donations: \(error.localizedDescription)"
                showAlert = true
                return
            }
            donations = snapshot?.documents.compactMap { document in
                let data = document.data()
                guard let id = data["id"] as? String,
                      let donorId = data["donorId"] as? String,
                      let hospital = data["hospital"] as? String,
                      let bloodType = data["bloodType"] as? String,
                      let date = (data["date"] as? Timestamp)?.dateValue(),
                      let status = data["status"] as? String else {
                    print("Failed to decode donation document \(document.documentID): \(data)")
                    return nil
                }
                return Donation(id: id, donorId: donorId, hospital: hospital, bloodType: bloodType, date: date, status: status)
            } ?? []
            print("Fetched \(donations.count) donations")
        }
    }
    
    private func fetchHospitals() {
        db.collection("hospitals").addSnapshotListener { snapshot, error in
            if let error = error {
                print("Error fetching hospitals: \(error)")
                alertTitle = "Error"
                alertMessage = "Failed to fetch hospitals: \(error.localizedDescription)"
                showAlert = true
                return
            }
            hospitals = snapshot?.documents.compactMap { document in
                let data = document.data()
                guard let id = data["id"] as? String,
                      let name = data["name"] as? String,
                      let address = data["address"] as? String else {
                    print("Failed to decode hospital document \(document.documentID): \(data)")
                    return nil
                }
                return hospital(id: id, name: name, address: address)
            } ?? []
            print("Fetched \(hospitals.count) hospitals")
        }
    }
    
    private func toggleUserStatus(_ user: AppUser) async {
        guard !user.id.isEmpty else {
            alertTitle = "Error"
            alertMessage = "Invalid user ID"
            showAlert = true
            print("Invalid user ID for toggling status")
            return
        }
        
        var currentUser: AppUser?
        await MainActor.run {
            currentUser = authManager.user
        }
        guard currentUser?.role == "admin" else {
            alertTitle = "Error"
            alertMessage = "You do not have permission to toggle user status"
            showAlert = true
            print("Non-admin attempted to toggle user status for ID: \(user.id)")
            return
        }
        
        guard user.id != currentUser?.id else {
            alertTitle = "Error"
            alertMessage = "You cannot toggle your own account status"
            showAlert = true
            print("Admin attempted to toggle their own status for ID: \(user.id)")
            return
        }
        
        do {
            togglingUserId = user.id
            let updateData: [String: Bool] = ["isActive": !user.isActive]
            try await db.collection("users").document(user.id).updateData(updateData)
            alertTitle = "Success"
            alertMessage = "User status \(user.isActive ? "disabled" : "enabled") successfully."
            showAlert = true
            print("Toggled user status for ID: \(user.id) to isActive: \(!user.isActive)")
        } catch {
            alertTitle = "Error"
            alertMessage = "Failed to toggle user status: \(error.localizedDescription)"
            showAlert = true
            print("Error toggling user status for ID: \(user.id), error: \(error.localizedDescription)")
        }
        
        togglingUserId = nil
    }
    
    private func approveDonation(_ donation: Donation) async {
        let donationId = donation.id
        if donationId.isEmpty {
            alertTitle = "Error"
            alertMessage = "Invalid donation ID"
            showAlert = true
            return
        }
        
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        guard let startOfYear = calendar.date(from: DateComponents(year: currentYear, month: 1, day: 1)),
              let endOfYear = calendar.date(from: DateComponents(year: currentYear, month: 12, day: 31, hour: 23, minute: 59, second: 59)) else {
            alertTitle = "Error"
            alertMessage = "Failed to calculate year range for donation limit check"
            showAlert = true
            return
        }
        
        do {
            let snapshot = try await db.collection("donations")
                .whereField("donorId", isEqualTo: donation.donorId)
                .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: startOfYear))
                .whereField("date", isLessThanOrEqualTo: Timestamp(date: endOfYear))
                .whereField("status", isEqualTo: "approved")
                .getDocuments()
            
            let approvedCount = snapshot.documents.count
            if approvedCount >= 4 {
                alertTitle = "Cannot Approve"
                alertMessage = "User has already reached the donation limit of 4 for \(currentYear)."
                showAlert = true
                return
            }
            
            let updateData: [String: String] = ["status": "approved"]
            try await db.collection("donations").document(donationId).updateData(updateData)
            alertTitle = "Success"
            alertMessage = "Donation approved successfully."
            showAlert = true
            print("Approved donation ID: \(donationId) for user: \(donation.donorId)")
        } catch {
            alertTitle = "Error"
            alertMessage = "Failed to approve donation: \(error.localizedDescription)"
            showAlert = true
            print("Error approving donation ID: \(donationId), error: \(error.localizedDescription)")
        }
    }
    
    private func rejectDonation(_ donation: Donation) async {
        let donationId = donation.id
        if donationId.isEmpty {
            alertTitle = "Error"
            alertMessage = "Invalid donation ID"
            showAlert = true
            return
        }
        
        do {
            let updateData: [String: String] = ["status": "rejected"]
            try await db.collection("donations").document(donationId).updateData(updateData)
            alertTitle = "Success"
            alertMessage = "Donation rejected successfully."
            showAlert = true
            print("Rejected donation ID: \(donationId) for user: \(donation.donorId)")
        } catch {
            alertTitle = "Error"
            alertMessage = "Failed to reject donation: \(error.localizedDescription)"
            showAlert = true
            print("Error rejecting donation ID: \(donationId), error: \(error.localizedDescription)")
        }
    }
}

#Preview {
    AdminDashboardView()
        .environmentObject(AuthManager())
}








































/*// File: AdminDashboardView.swift
// Project: BloodDonationApp
// Purpose: Admin dashboard for managing users, donations, and active donors
// Created by Student1 on 28/04/2025

import SwiftUI
import FirebaseFirestore

struct AdminDashboardView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var users: [AppUser] = []
    @State private var donations: [Donation] = []
    @State private var hospitals: [Hospital] = []
    @State private var selectedTab = 0
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var togglingUserId: String?
    @State private var showDonationForm = false
    private let db = Firestore.firestore()
    
    private let deepRed = Color(red: 0.8, green: 0.1, blue: 0.1)
    private let cream = Color(red: 0.98, green: 0.96, blue: 0.9)
    private let lightRed = Color(red: 0.95, green: 0.8, blue: 0.8)
    
    var body: some View {
        NavigationView {
            ZStack {
                cream.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        SegmentButton(title: "Users", isSelected: selectedTab == 0) {
                            selectedTab = 0
                        }
                        SegmentButton(title: "Donations", isSelected: selectedTab == 1) {
                            selectedTab = 1
                        }
                        SegmentButton(title: "Active Donors", isSelected: selectedTab == 2) {
                            selectedTab = 2
                        }
                    }
                    .background(deepRed)
                    
                    TabView(selection: $selectedTab) {
                        usersListView.tag(0)
                        donationsListView.tag(1)
                        activeDonorsListView.tag(2)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    actionButtons()
                }
            }
            .navigationTitle("Admin Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(deepRed, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        authManager.signOut()
                    }) {
                        Text("Logout")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .sheet(isPresented: $showDonationForm) {
                DonationFormView(authManager: authManager)
            }
            .onAppear {
                fetchUsers()
                fetchDonations()
                fetchHospitals()
            }
        }
    }
    
    private var usersListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(users) { user in
                    userCardView(user)
                }
                .padding(.horizontal)
                .padding(.top)
            }
            .padding(.bottom)
        }
        .background(cream)
    }
    
    private var activeDonorsListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(users.filter { $0.isActive && $0.role != "admin" }) { user in
                    userCardView(user)
                }
                .padding(.horizontal)
                .padding(.top)
            }
            .padding(.bottom)
        }
        .background(cream)
    }
    
    private func userCardView(_ user: AppUser) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(user.name)
                        .font(.headline)
                        .foregroundColor(.black)
                    Text(user.email)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    HStack {
                        Circle()
                            .fill(user.isActive ? Color.green : Color.gray)
                            .frame(width: 10, height: 10)
                        Text(user.isActive ? "Active" : "Inactive")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                Button(action: {
                    Task {
                        await toggleUserStatus(user)
                    }
                }) {
                    Text(togglingUserId == user.id ? "Toggling..." : (user.isActive ? "Disable" : "Enable"))
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(user.isActive ? Color.red.opacity(0.2) : deepRed)
                        .foregroundColor(user.isActive ? .red : .white)
                        .cornerRadius(8)
                }
                .disabled(togglingUserId == user.id)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var donationsListView: some View {
        ScrollView {
            LazyVStack(spacing: 15) {
                ForEach(donations.filter { $0.status == "pending" }) { donation in
                    donationCardView(donation)
                }
                .padding(.horizontal)
                .padding(.top)
            }
            .padding(.bottom)
        }
        .background(cream)
    }
    
    private func donationCardView(_ donation: Donation) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Donor ID: \(donation.donorId)")
                    .font(.headline)
                    .foregroundColor(.black)
                Spacer()
                Text("Pending")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(lightRed)
                    .foregroundColor(deepRed)
                    .cornerRadius(6)
            }
            Text("Date: \(donation.date, format: .dateTime)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text("Hospital: \(donation.hospital)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            if let hospital = hospitals.first(where: { $0.name == donation.hospital }) {
                Text("Address: \(hospital.address)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            HStack(spacing: 12) {
                Button(action: {
                    Task {
                        await approveDonation(donation)
                    }
                }) {
                    HStack {
                        Image(systemName: "checkmark")
                        Text("Approve")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(deepRed)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                Button(action: {
                    Task {
                        await rejectDonation(donation)
                    }
                }) {
                    HStack {
                        Image(systemName: "xmark")
                        Text("Reject")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.black)
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private func actionButtons() -> some View {
        HStack(spacing: 15) {
            Button(action: {
                showDonationForm = true
            }) {
                HStack {
                    Image(systemName: "plus")
                    Text("Log Donation")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(deepRed)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color.white)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: -2)
    }
    
    private func SegmentButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .fontWeight(.semibold)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(isSelected ? cream : deepRed)
                .foregroundColor(isSelected ? deepRed : cream)
        }
    }
    
    private func fetchUsers() {
        db.collection("users").addSnapshotListener { snapshot, error in
            if let error = error {
                print("Error fetching users: \(error)")
                alertTitle = "Error"
                alertMessage = "Failed to fetch users: \(error.localizedDescription)"
                showAlert = true
                return
            }
            users = snapshot?.documents.compactMap { document in
                let data = document.data()
                guard let id = data["id"] as? String,
                      let email = data["email"] as? String,
                      let name = data["name"] as? String,
                      let role = data["role"] as? String,
                      let isActive = data["isActive"] as? Bool,
                      let streaks = data["streaks"] as? Int,
                      let hasNotifiedFourDonations = data["hasNotifiedFourDonations"] as? Bool else {
                    print("Failed to decode user document \(document.documentID): \(data)")
                    return nil
                }
                return AppUser(
                    id: id,
                    email: email,
                    name: name,
                    role: role,
                    isActive: isActive,
                    streaks: streaks,
                    hasNotifiedFourDonations: hasNotifiedFourDonations
                )
            } ?? []
            print("Fetched \(users.count) users")
        }
    }
    
    private func fetchDonations() {
        db.collection("donations").addSnapshotListener { snapshot, error in
            if let error = error {
                print("Error fetching donations: \(error)")
                alertTitle = "Error"
                alertMessage = "Failed to fetch donations: \(error.localizedDescription)"
                showAlert = true
                return
            }
            donations = snapshot?.documents.compactMap { document in
                let data = document.data()
                guard let id = data["id"] as? String,
                      let donorId = data["donorId"] as? String,
                      let hospital = data["hospital"] as? String,
                      let bloodType = data["bloodType"] as? String,
                      let date = (data["date"] as? Timestamp)?.dateValue(),
                      let status = data["status"] as? String else {
                    print("Failed to decode donation document \(document.documentID): \(data)")
                    return nil
                }
                return Donation(id: id, donorId: donorId, hospital: hospital, bloodType: bloodType, date: date, status: status)
            } ?? []
            print("Fetched \(donations.count) donations")
        }
    }
    
    private func fetchHospitals() {
        db.collection("hospitals").addSnapshotListener { snapshot, error in
            if let error = error {
                print("Error fetching hospitals: \(error)")
                alertTitle = "Error"
                alertMessage = "Failed to fetch hospitals: \(error.localizedDescription)"
                showAlert = true
                return
            }
            hospitals = snapshot?.documents.compactMap { document in
                let data = document.data()
                guard let id = data["id"] as? String,
                      let name = data["name"] as? String,
                      let address = data["address"] as? String else {
                    print("Failed to decode hospital document \(document.documentID): \(data)")
                    return nil
                }
                return Hospital(id: id, name: name, address: address)
            } ?? []
            print("Fetched \(hospitals.count) hospitals")
        }
    }
    
    private func toggleUserStatus(_ user: AppUser) async {
        guard !user.id.isEmpty else {
            alertTitle = "Error"
            alertMessage = "Invalid user ID"
            showAlert = true
            print("Invalid user ID for toggling status")
            return
        }
        
        var currentUser: AppUser?
        await MainActor.run {
            currentUser = authManager.user
        }
        guard currentUser?.role == "admin" else {
            alertTitle = "Error"
            alertMessage = "You do not have permission to toggle user status"
            showAlert = true
            print("Non-admin attempted to toggle user status for ID: \(user.id)")
            return
        }
        
        guard user.id != currentUser?.id else {
            alertTitle = "Error"
            alertMessage = "You cannot toggle your own account status"
            showAlert = true
            print("Admin attempted to toggle their own status for ID: \(user.id)")
            return
        }
        
        do {
            togglingUserId = user.id
            let updateData: [String: Bool] = ["isActive": !user.isActive]
            try await db.collection("users").document(user.id).updateData(updateData)
            alertTitle = "Success"
            alertMessage = "User status \(user.isActive ? "disabled" : "enabled") successfully."
            showAlert = true
            print("Toggled user status for ID: \(user.id) to isActive: \(!user.isActive)")
        } catch {
            alertTitle = "Error"
            alertMessage = "Failed to toggle user status: \(error.localizedDescription)"
            showAlert = true
            print("Error toggling user status for ID: \(user.id), error: \(error.localizedDescription)")
        }
        
        togglingUserId = nil
    }
    
    private func approveDonation(_ donation: Donation) async {
        let donationId = donation.id
        if donationId.isEmpty {
            alertTitle = "Error"
            alertMessage = "Invalid donation ID"
            showAlert = true
            return
        }
        
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        guard let startOfYear = calendar.date(from: DateComponents(year: currentYear, month: 1, day: 1)),
              let endOfYear = calendar.date(from: DateComponents(year: currentYear, month: 12, day: 31, hour: 23, minute: 59, second: 59)) else {
            alertTitle = "Error"
            alertMessage = "Failed to calculate year range for donation limit check"
            showAlert = true
            return
        }
        
        do {
            let snapshot = try await db.collection("donations")
                .whereField("donorId", isEqualTo: donation.donorId)
                .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: startOfYear))
                .whereField("date", isLessThanOrEqualTo: Timestamp(date: endOfYear))
                .whereField("status", isEqualTo: "approved")
                .getDocuments()
            
            let approvedCount = snapshot.documents.count
            if approvedCount >= 4 {
                alertTitle = "Cannot Approve"
                alertMessage = "User has already reached the donation limit of 4 for \(currentYear)."
                showAlert = true
                return
            }
            
            let updateData: [String: String] = ["status": "approved"]
            try await db.collection("donations").document(donationId).updateData(updateData)
            alertTitle = "Success"
            alertMessage = "Donation approved successfully."
            showAlert = true
            print("Approved donation ID: \(donationId) for user: \(donation.donorId)")
        } catch {
            alertTitle = "Error"
            alertMessage = "Failed to approve donation: \(error.localizedDescription)"
            showAlert = true
            print("Error approving donation ID: \(donationId), error: \(error.localizedDescription)")
        }
    }
    
    private func rejectDonation(_ donation: Donation) async {
        let donationId = donation.id
        if donationId.isEmpty {
            alertTitle = "Error"
            alertMessage = "Invalid donation ID"
            showAlert = true
            return
        }
        
        do {
            let updateData: [String: String] = ["status": "rejected"]
            try await db.collection("donations").document(donationId).updateData(updateData)
            alertTitle = "Success"
            alertMessage = "Donation rejected successfully."
            showAlert = true
            print("Rejected donation ID: \(donationId) for user: \(donation.donorId)")
        } catch {
            alertTitle = "Error"
            alertMessage = "Failed to reject donation: \(error.localizedDescription)"
            showAlert = true
            print("Error rejecting donation ID: \(donationId), error: \(error.localizedDescription)")
        }
    }
}

#Preview {
    AdminDashboardView()
        .environmentObject(AuthManager())
}*/




































/*// Import SwiftUI for building the user interface and FirebaseFirestore for interacting with the Firestore database
import SwiftUI
import FirebaseFirestore

// Define AdminDashboardView, a SwiftUI View designed for administrators to manage users, donations, and view active donors
struct AdminDashboardView: View {
    // Access the shared AuthManager to manage authentication state and user data
    @EnvironmentObject var authManager: AuthManager
    // Store the list of all users fetched from Firestore
    @State private var users: [AppUser] = []
    // Store the list of all donations fetched from Firestore
    @State private var donations: [Donation] = []
    // Store the list of hospitals fetched from Firestore for reference in donation details
    @State private var hospitals: [Hospital] = []
    // Track the currently selected tab (Users, Donations, or Active Donors)
    @State private var selectedTab = 0
    // Control whether an alert should be displayed for errors or success messages
    @State private var showAlert = false
    // Store the title of the alert to be displayed
    @State private var alertTitle = ""
    // Store the message content for the alert
    @State private var alertMessage = ""
    // Track the ID of the user whose status is being toggled to prevent multiple toggles
    @State private var togglingUserId: String?
    // Create a reference to the Firestore database for data operations
    private let db = Firestore.firestore()
    
    // Define custom colors for consistent UI styling
    private let deepRed = Color(red: 0.8, green: 0.1, blue: 0.1)
    private let cream = Color(red: 0.98, green: 0.96, blue: 0.9)
    private let lightRed = Color(red: 0.95, green: 0.8, blue: 0.8)
    
    // Define the main UI structure of the admin dashboard
    var body: some View {
        // Use NavigationView to provide a navigation bar and support toolbar items
        NavigationView {
            // Use ZStack to layer the background color and content
            ZStack {
                // Set a cream-colored background that extends to all edges, ignoring safe areas
                cream.edgesIgnoringSafeArea(.all)
                
                // Arrange content vertically with no spacing between sections
                VStack(spacing: 0) {
                    // Create a custom segmented control for switching between tabs
                    HStack(spacing: 0) {
                        // Button for the "Users" tab
                        SegmentButton(title: "Users", isSelected: selectedTab == 0) {
                            selectedTab = 0
                        }
                        // Button for the "Donations" tab
                        SegmentButton(title: "Donations", isSelected: selectedTab == 1) {
                            selectedTab = 1
                        }
                        // Button for the "Active Donors" tab
                        SegmentButton(title: "Active Donors", isSelected: selectedTab == 2) {
                            selectedTab = 2
                        }
                    }
                    // Apply a deep red background to the segmented control
                    .background(deepRed)
                    
                    // Use TabView to display different content based on the selected tab
                    TabView(selection: $selectedTab) {
                        // Show the list of all users
                        usersListView.tag(0)
                        // Show the list of pending donations
                        donationsListView.tag(1)
                        // Show the list of active non-admin users
                        activeDonorsListView.tag(2)
                    }
                    // Use page-style navigation without index dots
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
            }
            // Set the navigation title for the dashboard
            .navigationTitle("Admin Dashboard")
            // Display the title inline within the navigation bar
            .navigationBarTitleDisplayMode(.inline)
            // Apply a deep red background to the navigation bar
            .toolbarBackground(deepRed, for: .navigationBar)
            // Ensure the navigation bar background is visible
            .toolbarBackground(.visible, for: .navigationBar)
            // Use a dark color scheme for toolbar text and icons
            .toolbarColorScheme(.dark, for: .navigationBar)
            // Add a toolbar with a logout button
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Sign the admin out when the button is tapped
                        authManager.signOut()
                    }) {
                        Text("Logout")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                }
            }
            // Show an alert with a title and message when triggered
            .alert(isPresented: $showAlert) {
                Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            // Fetch data when the view appears
            .onAppear {
                fetchUsers()
                fetchDonations()
                fetchHospitals()
            }
        }
    }
    
    // Create a scrollable view to display the list of all users
    private var usersListView: some View {
        ScrollView {
            // Use LazyVStack for efficient rendering of user cards
            LazyVStack(spacing: 12) {
                ForEach(users) { user in
                    userCardView(user)
                }
                .padding(.horizontal)
                .padding(.top)
            }
            .padding(.bottom)
        }
        // Set a cream-colored background for the view
        .background(cream)
    }
    
    // Create a scrollable view to display the list of active non-admin users
    private var activeDonorsListView: some View {
        ScrollView {
            // Use LazyVStack for efficient rendering of user cards
            LazyVStack(spacing: 12) {
                // Filter users to show only active non-admin users
                ForEach(users.filter { $0.isActive && $0.role != "admin" }) { user in
                    userCardView(user)
                }
                .padding(.horizontal)
                .padding(.top)
            }
            .padding(.bottom)
        }
        // Set a cream-colored background for the view
        .background(cream)
    }
    
    // Create a card to display user details and status toggle
    private func userCardView(_ user: AppUser) -> some View {
        // Display user name, email, status, and a toggle button
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    // Show the user's name
                    Text(user.name)
                        .font(.headline)
                        .foregroundColor(.black)
                    
                    // Show the user's email
                    Text(user.email)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    // Indicate whether the user is active or inactive
                    HStack {
                        Circle()
                            .fill(user.isActive ? Color.green : Color.gray)
                            .frame(width: 10, height: 10)
                        
                        Text(user.isActive ? "Active" : "Inactive")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Button to toggle the user's active status
                Button(action: {
                    Task {
                        await toggleUserStatus(user)
                    }
                }) {
                    Text(togglingUserId == user.id ? "Toggling..." : (user.isActive ? "Disable" : "Enable"))
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(user.isActive ? Color.red.opacity(0.2) : deepRed)
                        .foregroundColor(user.isActive ? .red : .white)
                        .cornerRadius(8)
                }
                // Disable the button while toggling to prevent multiple requests
                .disabled(togglingUserId == user.id)
            }
        }
        // Style the card with padding, white background, and shadow
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // Create a scrollable view to display pending donations
    private var donationsListView: some View {
        ScrollView {
            // Use LazyVStack for efficient rendering of donation cards
            LazyVStack(spacing: 15) {
                // Filter donations to show only those with "pending" status
                ForEach(donations.filter { $0.status == "pending" }) { donation in
                    donationCardView(donation)
                }
                .padding(.horizontal)
                .padding(.top)
            }
            .padding(.bottom)
        }
        // Set a cream-colored background for the view
        .background(cream)
    }
    
    // Create a card to display donation details and approval/rejection buttons
    private func donationCardView(_ donation: Donation) -> some View {
        // Display donation details and buttons to approve or reject
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Show the donor ID
                Text("Donor ID: \(donation.donorId)")
                    .font(.headline)
                    .foregroundColor(.black)
                
                Spacer()
                
                // Indicate the donation's pending status
                Text("Pending")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(lightRed)
                    .foregroundColor(deepRed)
                    .cornerRadius(6)
            }
            
            // Show the donation date
            Text("Date: \(donation.date, format: .dateTime)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Show the hospital name
            Text("Hospital: \(donation.hospital)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Show the hospital address if available
            if let hospital = hospitals.first(where: { $0.name == donation.hospital }) {
                Text("Address: \(hospital.address)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            // Provide buttons to approve or reject the donation
            HStack(spacing: 12) {
                Button(action: {
                    Task {
                        await approveDonation(donation)
                    }
                }) {
                    HStack {
                        Image(systemName: "checkmark")
                        Text("Approve")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(deepRed)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                
                Button(action: {
                    Task {
                        await rejectDonation(donation)
                    }
                }) {
                    HStack {
                        Image(systemName: "xmark")
                        Text("Reject")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.black)
                    .cornerRadius(8)
                }
            }
        }
        // Style the card with padding, white background, and shadow
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // Create a custom button for the segmented control
    private func SegmentButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        // Display a button that toggles between tabs and highlights the selected tab
        Button(action: action) {
            Text(title)
                .fontWeight(.semibold)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(isSelected ? cream : deepRed)
                .foregroundColor(isSelected ? deepRed : cream)
        }
    }
    
    // Fetch the list of all users from Firestore
    private func fetchUsers() {
        // Set up a real-time listener for the users collection
        db.collection("users").addSnapshotListener { snapshot, error in
            if let error = error {
                // Handle errors during data fetch
                print("Error fetching users: \(error)")
                alertTitle = "Error"
                alertMessage = "Failed to fetch users: \(error.localizedDescription)"
                showAlert = true
                return
            }
            // Parse user data into AppUser objects
            self.users = snapshot?.documents.compactMap { document in
                let data = document.data()
                guard let id = data["id"] as? String,
                      let email = data["email"] as? String,
                      let name = data["name"] as? String,
                      let role = data["role"] as? String,
                      let isActive = data["isActive"] as? Bool,
                      let streaks = data["streaks"] as? Int else {
                    return nil
                }
                return AppUser(id: id, email: email, name: name, role: role, isActive: isActive, streaks: streaks)
            } ?? []
        }
    }
    
    // Fetch the list of all donations from Firestore
    private func fetchDonations() {
        // Set up a real-time listener for the donations collection
        db.collection("donations").addSnapshotListener { snapshot, error in
            if let error = error {
                // Handle errors during data fetch
                print("Error fetching donations: \(error)")
                alertTitle = "Error"
                alertMessage = "Failed to fetch donations: \(error.localizedDescription)"
                showAlert = true
                return
            }
            // Parse donation data into Donation objects
            self.donations = snapshot?.documents.compactMap { document in
                let data = document.data()
                guard let id = data["id"] as? String,
                      let donorId = data["donorId"] as? String,
                      let hospital = data["hospital"] as? String,
                      let bloodType = data["bloodType"] as? String,
                      let date = (data["date"] as? Timestamp)?.dateValue(),
                      let status = data["status"] as? String else {
                    return nil
                }
                return Donation(id: id, donorId: donorId, hospital: hospital, bloodType: bloodType, date: date, status: status)
            } ?? []
        }
    }
    
    // Fetch the list of hospitals from Firestore
    private func fetchHospitals() {
        // Set up a real-time listener for the hospitals collection
        db.collection("hospitals").addSnapshotListener { snapshot, error in
            if let error = error {
                // Handle errors during data fetch
                print("Error fetching hospitals: \(error)")
                alertTitle = "Error"
                alertMessage = "Failed to fetch hospitals: \(error.localizedDescription)"
                showAlert = true
                return
            }
            // Parse hospital data into Hospital objects
            self.hospitals = snapshot?.documents.compactMap { document in
                let data = document.data()
                guard let id = data["id"] as? String,
                      let name = data["name"] as? String,
                      let address = data["address"] as? String else {
                    return nil
                }
                return Hospital(id: id, name: name, address: address)
            } ?? []
        }
    }
    
    // Toggle the active status of a user in Firestore
    private func toggleUserStatus(_ user: AppUser) async {
        // Ensure the user ID is valid before proceeding
        guard !user.id.isEmpty else {
            alertTitle = "Error"
            alertMessage = "Invalid user ID"
            showAlert = true
            print("Invalid user ID for toggling status")
            return
        }
        
        // Verify the current user is an admin
        var currentUser: AppUser?
        await MainActor.run {
            currentUser = authManager.user
        }
        guard currentUser?.role == "admin" else {
            alertTitle = "Error"
            alertMessage = "You do not have permission to toggle user status"
            showAlert = true
            print("Non-admin attempted to toggle user status for ID: \(user.id)")
            return
        }
        
        // Prevent admins from toggling their own status
        guard user.id != currentUser?.id else {
            alertTitle = "Error"
            alertMessage = "You cannot toggle your own account status"
            showAlert = true
            print("Admin attempted to toggle their own status for ID: \(user.id)")
            return
        }
        
        do {
            // Update the user's isActive status in Firestore
            let updateData: [String: Bool] = ["isActive": !user.isActive]
            try await db.collection("users").document(user.id).updateData(updateData)
            alertTitle = "Success"
            alertMessage = "User status \(user.isActive ? "disabled" : "enabled") successfully."
            showAlert = true
            print("Toggled user status for ID: \(user.id) to isActive: \(!user.isActive)")
        } catch {
            // Handle errors during the update
            alertTitle = "Error"
            alertMessage = "Failed to toggle user status: \(error.localizedDescription)"
            showAlert = true
            print("Error toggling user status for ID: \(user.id), error: \(error.localizedDescription)")
        }
        
        // Clear the toggling state
        togglingUserId = nil
    }
    
    // Approve a pending donation in Firestore
    private func approveDonation(_ donation: Donation) async {
        // Ensure the donation ID is valid
        let donationId = donation.id
        if donationId.isEmpty {
            alertTitle = "Error"
            alertMessage = "Invalid donation ID"
            showAlert = true
            return
        }
        
        // Calculate the date range for the current year to check donation limits
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        guard let startOfYear = calendar.date(from: DateComponents(year: currentYear, month: 1, day: 1)),
              let endOfYear = calendar.date(from: DateComponents(year: currentYear, month: 12, day: 31, hour: 23, minute: 59, second: 59)) else {
            alertTitle = "Error"
            alertMessage = "Failed to calculate year range for donation limit check"
            showAlert = true
            return
        }
        
        do {
            // Check if the user has reached the annual donation limit (4 donations)
            let snapshot = try await db.collection("donations")
                .whereField("donorId", isEqualTo: donation.donorId)
                .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: startOfYear))
                .whereField("date", isLessThanOrEqualTo: Timestamp(date: endOfYear))
                .whereField("status", isEqualTo: "approved")
                .getDocuments()
            
            let approvedCount = snapshot.documents.count
            if approvedCount >= 4 {
                // Prevent approval if the user has reached the donation limit
                alertTitle = "Cannot Approve"
                alertMessage = "User has already reached the donation limit of 4 for \(currentYear)."
                showAlert = true
                return
            }
            
            // Update the donation status to "approved" in Firestore
            let updateData: [String: String] = ["status": "approved"]
            try await db.collection("donations").document(donationId).updateData(updateData)
            alertTitle = "Success"
            alertMessage = "Donation approved successfully."
            showAlert = true
            print("Approved donation ID: \(donationId) for user: \(donation.donorId)")
        } catch {
            // Handle errors during the approval process
            alertTitle = "Error"
            alertMessage = "Failed to approve donation: \(error.localizedDescription)"
            showAlert = true
            print("Error approving donation ID: \(donationId), error: \(error.localizedDescription)")
        }
    }
    
    // Reject a pending donation in Firestore
    private func rejectDonation(_ donation: Donation) async {
        // Ensure the donation ID is valid
        let donationId = donation.id
        if donationId.isEmpty {
            alertTitle = "Error"
            alertMessage = "Invalid donation ID"
            showAlert = true
            return
        }
        
        do {
            // Update the donation status to "rejected" in Firestore
            let updateData: [String: String] = ["status": "rejected"]
            try await db.collection("donations").document(donationId).updateData(updateData)
            alertTitle = "Success"
            alertMessage = "Donation rejected successfully."
            showAlert = true
            print("Rejected donation ID: \(donationId) for user: \(donation.donorId)")
        } catch {
            // Handle errors during the rejection process
            alertTitle = "Error"
            alertMessage = "Failed to reject donation: \(error.localizedDescription)"
            showAlert = true
            print("Error rejecting donation ID: \(donationId), error: \(error.localizedDescription)")
        }
    }
}

// Provide a preview of the AdminDashboardView for SwiftUI's canvas
#Preview {
    AdminDashboardView()
        .environmentObject(AuthManager())
}*/


































































































/*// AdminDashboardView.swift
import SwiftUI
import FirebaseFirestore

struct AdminDashboardView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var users: [AppUser] = []
    @State private var donations: [Donation] = []
    @State private var hospitals: [Hospital] = []
    @State private var selectedTab = 0
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var togglingUserId: String? // Track user being toggled
    private let db = Firestore.firestore()
    
    // Theme colors
    private let deepRed = Color(red: 0.8, green: 0.1, blue: 0.1)
    private let cream = Color(red: 0.98, green: 0.96, blue: 0.9)
    private let lightRed = Color(red: 0.95, green: 0.8, blue: 0.8)
    
    var body: some View {
        NavigationView {
            ZStack {
                cream.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Custom segmented control
                    HStack(spacing: 0) {
                        SegmentButton(title: "Users", isSelected: selectedTab == 0) {
                            selectedTab = 0
                        }
                        SegmentButton(title: "Donations", isSelected: selectedTab == 1) {
                            selectedTab = 1
                        }
                        SegmentButton(title: "Active Donors", isSelected: selectedTab == 2) {
                            selectedTab = 2
                        }
                    }
                    .background(deepRed)
                    
                    TabView(selection: $selectedTab) {
                        usersListView.tag(0)
                        donationsListView.tag(1)
                        activeDonorsListView.tag(2)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
            }
            .navigationTitle("Admin Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(deepRed, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        authManager.signOut()
                    }) {
                        Text("Logout")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .onAppear {
                fetchUsers()
                fetchDonations()
                fetchHospitals()
            }
        }
    }
    
    private var usersListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(users) { user in
                    userCardView(user)
                }
                .padding(.horizontal)
                .padding(.top)
            }
            .padding(.bottom)
        }
        .background(cream)
    }
    
    private var activeDonorsListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(users.filter { $0.isActive && $0.role != "admin" }) { user in
                    userCardView(user)
                }
                .padding(.horizontal)
                .padding(.top)
            }
            .padding(.bottom)
        }
        .background(cream)
    }
    
    private func userCardView(_ user: AppUser) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(user.name)
                        .font(.headline)
                        .foregroundColor(.black)
                    
                    Text(user.email)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    HStack {
                        Circle()
                            .fill(user.isActive ? Color.green : Color.gray)
                            .frame(width: 10, height: 10)
                        
                        Text(user.isActive ? "Active" : "Inactive")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button(action: {
                    Task {
                        await toggleUserStatus(user)
                    }
                }) {
                    Text(togglingUserId == user.id ? "Toggling..." : (user.isActive ? "Disable" : "Enable"))
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(user.isActive ? Color.red.opacity(0.2) : deepRed)
                        .foregroundColor(user.isActive ? .red : .white)
                        .cornerRadius(8)
                }
                .disabled(togglingUserId == user.id)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var donationsListView: some View {
        ScrollView {
            LazyVStack(spacing: 15) {
                ForEach(donations.filter { $0.status == "pending" }) { donation in
                    donationCardView(donation)
                }
                .padding(.horizontal)
                .padding(.top)
            }
            .padding(.bottom)
        }
        .background(cream)
    }
    
    private func donationCardView(_ donation: Donation) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Donor ID: \(donation.donorId)")
                    .font(.headline)
                    .foregroundColor(.black)
                
                Spacer()
                
                Text("Pending")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(lightRed)
                    .foregroundColor(deepRed)
                    .cornerRadius(6)
            }
            
            Text("Date: \(donation.date, format: .dateTime)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("Hospital: \(donation.hospital)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if let hospital = hospitals.first(where: { $0.name == donation.hospital }) {
                Text("Address: \(hospital.address)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            HStack(spacing: 12) {
                Button(action: {
                    Task {
                        await approveDonation(donation)
                    }
                }) {
                    HStack {
                        Image(systemName: "checkmark")
                        Text("Approve")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(deepRed)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                
                Button(action: {
                    Task { // Make rejectDonation async for consistency
                        await rejectDonation(donation)
                    }
                }) {
                    HStack {
                        Image(systemName: "xmark")
                        Text("Reject")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.black)
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private func SegmentButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .fontWeight(.semibold)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(isSelected ? cream : deepRed)
                .foregroundColor(isSelected ? deepRed : cream)
        }
    }
    
    private func fetchUsers() {
        db.collection("users").addSnapshotListener { snapshot, error in
            if let error = error {
                print("Error fetching users: \(error)")
                alertTitle = "Error"
                alertMessage = "Failed to fetch users: \(error.localizedDescription)"
                showAlert = true
                return
            }
            self.users = snapshot?.documents.compactMap { document in
                let data = document.data()
                guard let id = data["id"] as? String,
                      let email = data["email"] as? String,
                      let name = data["name"] as? String,
                      let role = data["role"] as? String,
                      let isActive = data["isActive"] as? Bool,
                      let streaks = data["streaks"] as? Int else {
                    return nil
                }
                return AppUser(id: id, email: email, name: name, role: role, isActive: isActive, streaks: streaks)
            } ?? []
        }
    }
    
    private func fetchDonations() {
        db.collection("donations").addSnapshotListener { snapshot, error in
            if let error = error {
                print("Error fetching donations: \(error)")
                alertTitle = "Error"
                alertMessage = "Failed to fetch donations: \(error.localizedDescription)"
                showAlert = true
                return
            }
            self.donations = snapshot?.documents.compactMap { document in
                let data = document.data()
                guard let id = data["id"] as? String,
                      let donorId = data["donorId"] as? String,
                      let hospital = data["hospital"] as? String,
                      let bloodType = data["bloodType"] as? String,
                      let date = (data["date"] as? Timestamp)?.dateValue(),
                      let status = data["status"] as? String else {
                    return nil
                }
                return Donation(id: id, donorId: donorId, hospital: hospital, bloodType: bloodType, date: date, status: status)
            } ?? []
        }
    }
    
    private func fetchHospitals() {
        db.collection("hospitals").addSnapshotListener { snapshot, error in
            if let error = error {
                print("Error fetching hospitals: \(error)")
                alertTitle = "Error"
                alertMessage = "Failed to fetch hospitals: \(error.localizedDescription)"
                showAlert = true
                return
            }
            self.hospitals = snapshot?.documents.compactMap { document in
                let data = document.data()
                guard let id = data["id"] as? String,
                      let name = data["name"] as? String,
                      let address = data["address"] as? String else {
                    return nil
                }
                return Hospital(id: id, name: name, address: address)
            } ?? []
        }
    }
    
    private func toggleUserStatus(_ user: AppUser) async {
        guard !user.id.isEmpty else {
            alertTitle = "Error"
            alertMessage = "Invalid user ID"
            showAlert = true
            print("Invalid user ID for toggling status")
            return
        }
        
        var currentUser: AppUser?
        await MainActor.run {
            currentUser = authManager.user
        }
        guard currentUser?.role == "admin" else {
            alertTitle = "Error"
            alertMessage = "You do not have permission to toggle user status"
            showAlert = true
            print("Non-admin attempted to toggle user status for ID: \(user.id)")
            return
        }
        
        guard user.id != currentUser?.id else {
            alertTitle = "Error"
            alertMessage = "You cannot toggle your own account status"
            showAlert = true
            print("Admin attempted to toggle their own status for ID: \(user.id)")
            return
        }
        
        do {
            let updateData: [String: Bool] = ["isActive": !user.isActive]
            try await db.collection("users").document(user.id).updateData(updateData)
            alertTitle = "Success"
            alertMessage = "User status \(user.isActive ? "disabled" : "enabled") successfully."
            showAlert = true
            print("Toggled user status for ID: \(user.id) to isActive: \(!user.isActive)")
        } catch {
            alertTitle = "Error"
            alertMessage = "Failed to toggle user status: \(error.localizedDescription)"
            showAlert = true
            print("Error toggling user status for ID: \(user.id), error: \(error.localizedDescription)")
        }
        
        togglingUserId = nil
    }
    
    private func approveDonation(_ donation: Donation) async {
        let donationId = donation.id // Use directly since id is non-optional
        if donationId.isEmpty {
            alertTitle = "Error"
            alertMessage = "Invalid donation ID"
            showAlert = true
            return
        }
        
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        guard let startOfYear = calendar.date(from: DateComponents(year: currentYear, month: 1, day: 1)),
              let endOfYear = calendar.date(from: DateComponents(year: currentYear, month: 12, day: 31, hour: 23, minute: 59, second: 59)) else {
            alertTitle = "Error"
            alertMessage = "Failed to calculate year range for donation limit check"
            showAlert = true
            return
        }
        
        do {
            // Check donation limit for the user
            let snapshot = try await db.collection("donations")
                .whereField("donorId", isEqualTo: donation.donorId)
                .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: startOfYear))
                .whereField("date", isLessThanOrEqualTo: Timestamp(date: endOfYear))
                .whereField("status", isEqualTo: "approved")
                .getDocuments()
            
            let approvedCount = snapshot.documents.count
            if approvedCount >= 4 {
                alertTitle = "Cannot Approve"
                alertMessage = "User has already reached the donation limit of 4 for \(currentYear)."
                showAlert = true
                return
            }
            
            // Approve the donation with strongly typed dictionary
            let updateData: [String: String] = ["status": "approved"]
            try await db.collection("donations").document(donationId).updateData(updateData)
            alertTitle = "Success"
            alertMessage = "Donation approved successfully."
            showAlert = true
            print("Approved donation ID: \(donationId) for user: \(donation.donorId)")
        } catch {
            alertTitle = "Error"
            alertMessage = "Failed to approve donation: \(error.localizedDescription)"
            showAlert = true
            print("Error approving donation ID: \(donationId), error: \(error.localizedDescription)")
        }
    }
    
    private func rejectDonation(_ donation: Donation) async {
        let donationId = donation.id // Use directly since id is non-optional
        if donationId.isEmpty {
            alertTitle = "Error"
            alertMessage = "Invalid donation ID"
            showAlert = true
            return
        }
        
        do {
            let updateData: [String: String] = ["status": "rejected"]
            try await db.collection("donations").document(donationId).updateData(updateData)
            alertTitle = "Success"
            alertMessage = "Donation rejected successfully."
            showAlert = true
            print("Rejected donation ID: \(donationId) for user: \(donation.donorId)")
        } catch {
            alertTitle = "Error"
            alertMessage = "Failed to reject donation: \(error.localizedDescription)"
            showAlert = true
            print("Error rejecting donation ID: \(donationId), error: \(error.localizedDescription)")
        }
    }
}

#Preview {
    AdminDashboardView()
        .environmentObject(AuthManager())
}*/







































/*import SwiftUI
import FirebaseFirestore

struct AdminDashboardView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var users: [AppUser] = []
    @State private var donations: [Donation] = []
    @State private var hospitals: [Hospital] = []
    private let db = Firestore.firestore()

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Users")) {
                    ForEach(users) { user in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(user.name)
                                Text(user.email)
                                Text("Active: \(user.isActive ? "Yes" : "No")")
                            }
                            Spacer()
                            Button(user.isActive ? "Disable" : "Enable") {
                                toggleUserStatus(user)
                            }
                        }
                    }
                }
                Section(header: Text("Pending Donations")) {
                    ForEach(donations.filter { $0.status == "pending" }) { donation in
                        VStack(alignment: .leading) {
                            Text("Donor ID: \(donation.donorId)")
                            Text("Date: \(donation.date, format: .dateTime)")
                            Text("Hospital: \(donation.hospital)")
                            if let hospital = hospitals.first(where: { $0.name == donation.hospital }) {
                                Text("Address: \(hospital.address)")
                            }
                            HStack {
                                Button("Approve") {
                                    approveDonation(donation)
                                }
                                Button("Reject") {
                                    rejectDonation(donation)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Admin Dashboard")
            .toolbar {
                ToolbarItem {
                    Button("Logout") {
                        authManager.signOut()
                    }
                }
            }
            .onAppear {
                fetchUsers()
                fetchDonations()
                fetchHospitals()
            }
        }
    }

    private func fetchUsers() {
        db.collection("users").addSnapshotListener { snapshot, error in
            if let error = error {
                print("Error fetching users: \(error)")
                return
            }
            self.users = snapshot?.documents.compactMap { document in
                guard let data = document.data() as [String: Any]? else { return nil }
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: data)
                    let user = try JSONDecoder().decode(AppUser.self, from: jsonData)
                    return user
                } catch {
                    print("Error decoding user: \(error)")
                    return nil
                }
            } ?? []
        }
    }

    private func fetchDonations() {
        db.collection("donations").addSnapshotListener { snapshot, error in
            if let error = error {
                print("Error fetching donations: \(error)")
                return
            }
            self.donations = snapshot?.documents.compactMap { document in
                guard let data = document.data() as [String: Any]? else { return nil }
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: data)
                    let donation = try JSONDecoder().decode(Donation.self, from: jsonData)
                    return donation
                } catch {
                    print("Error decoding donation: \(error)")
                    return nil
                }
            } ?? []
        }
    }

    private func fetchHospitals() {
        db.collection("hospitals").addSnapshotListener { snapshot, error in
            if let error = error {
                print("Error fetching hospitals: \(error)")
                return
            }
            self.hospitals = snapshot?.documents.compactMap { document in
                guard let data = document.data() as [String: Any]? else { return nil }
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: data)
                    let hospital = try JSONDecoder().decode(Hospital.self, from: jsonData)
                    return hospital
                } catch {
                    print("Error decoding hospital: \(error)")
                    return nil
                }
            } ?? []
        }
    }

    private func toggleUserStatus(_ user: AppUser) {
        db.collection("users").document(user.id).updateData(["isActive": !user.isActive])
    }

    private func approveDonation(_ donation: Donation) {
        db.collection("donations").document(donation.id).updateData(["status": "approved"]) { error in
            if error == nil {
                db.collection("users").document(donation.donorId).updateData([
                    "streaks": FieldValue.increment(Int64(1))
                ])
            }
        }
    }

    private func rejectDonation(_ donation: Donation) {
        db.collection("donations").document(donation.id).updateData(["status": "rejected"])
    }
}

#Preview {
    AdminDashboardView()
        .environmentObject(AuthManager())
}*/
