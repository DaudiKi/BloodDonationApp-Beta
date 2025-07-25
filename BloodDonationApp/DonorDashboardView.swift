// Import FirebaseFirestore for database interactions, SwiftUI for UI, and FirebaseAuth for user authentication
import FirebaseFirestore
import SwiftUI
import FirebaseAuth

// Define DonorDashboardView, a SwiftUI View that serves as the main dashboard for blood donors to view their donations, appointments, and perform actions
struct DonorDashboardView: View {
    // Access the shared AuthManager to manage user authentication state
    @EnvironmentObject var authManager: AuthManager
    // Store the list of user donations fetched from Firestore
    @State private var donations: [Donation] = []
    // Store the list of user appointments fetched from Firestore
    @State private var appointments: [Appointment] = []
    // Store the list of hospitals fetched from Firestore for reference in donation details
    @State private var hospitals: [Hospital] = []
    // Control whether the donation form sheet is presented
    @State private var showDonationForm = false
    // Control whether an error alert is displayed
    @State private var showAlert = false
    // Store the message to display in the error alert
    @State private var alertMessage = ""
    // Create a reference to the Firestore database for data operations
    private let db = Firestore.firestore()

    // Define custom colors for consistent UI styling
    private let deepRed = Color(red: 0.7, green: 0.1, blue: 0.1)
    private let cream = Color(red: 0.98, green: 0.96, blue: 0.9)
    private let lightRed = Color(red: 0.9, green: 0.7, blue: 0.7)

    // Define the main UI structure of the dashboard
    var body: some View {
        // Use NavigationView to provide a navigation bar and support toolbar items
        NavigationView {
            // Use ZStack to layer the background color and content
            ZStack {
                // Set a cream-colored background that extends to all edges, ignoring safe areas
                cream.ignoresSafeArea()
                // Arrange content vertically with no spacing between sections
                VStack(spacing: 0) {
                    // Display user information if the user is authenticated
                    if let user = authManager.user {
                        // Show a card with user details and donation streak
                        userInfoCard(user: user, streaks: calcStreak(donations: donations))
                        // Create a scrollable view for donations and appointments
                        ScrollView {
                            // Arrange sections vertically with spacing
                            VStack(alignment: .leading, spacing: 20) {
                                // Display a header for the donations section
                                Text("Your Donations")
                                    .font(.headline)
                                    .padding(.horizontal)
                                    .padding(.top)
                                    .foregroundColor(deepRed)
                                // Show a placeholder if no donations exist
                                if donations.isEmpty {
                                    emptyDonationsView()
                                } else {
                                    // Display a list of donation cards
                                    donationsList()
                                }
                                // Display a header for the appointments section
                                Text("Your Appointments")
                                    .font(.headline)
                                    .padding(.horizontal)
                                    .padding(.top)
                                    .foregroundColor(deepRed)
                                // Show a placeholder if no appointments exist
                                if appointments.isEmpty {
                                    emptyAppointmentsView()
                                } else {
                                    // Display a list of appointment cards
                                    appointmentsList()
                                }
                            }
                        }
                        // Add minimal vertical padding to the scrollable content
                        .padding(.vertical, 5)
                        // Display buttons for logging a donation and booking an appointment
                        actionButtons()
                    }
                }
            }
            // Set the navigation title for the dashboard
            .navigationTitle("My Dashboard")
            // Display the title inline within the navigation bar
            .navigationBarTitleDisplayMode(.inline)
            // Add a toolbar with a sign-out button
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Sign the user out when the button is tapped
                        authManager.signOut()
                    }) {
                        // Show a sign-out icon
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(deepRed)
                    }
                }
            }
            // Present the donation form as a sheet when triggered
            .sheet(isPresented: $showDonationForm) {
                DonationFormView(authManager: authManager)
            }
            // Show an alert with an error message when triggered
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            // Fetch data when the view appears
            .onAppear {
                fetchDonations()
                fetchHospitals()
                fetchAppointments()
            }
        }
    }

    // Calculate the user's donation streak based on approved donations
    private func calcStreak(donations: [Donation]) -> Int {
        // Return the count of donations with "approved" status
        return donations.filter { $0.status == "approved" }.count
    }

    // Create a card displaying user information and donation streak
    private func userInfoCard(user: AppUser, streaks: Int) -> some View {
        // Arrange user info and streak count vertically
        VStack(spacing: 10) {
            HStack {
                // Display user name and email
                VStack(alignment: .leading, spacing: 4) {
                    Text("Welcome, \(user.name)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Text(user.email)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                }
                Spacer()
                // Display the donation streak in a circular badge
                VStack {
                    Text("\(streaks)")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    Text("Streak\(streaks == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.9))
                }
                .frame(width: 80, height: 80)
                .background(Color.white.opacity(0.2))
                .cornerRadius(40)
            }
        }
        // Style the card with padding, gradient background, and shadow
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [deepRed, deepRed.opacity(0.8)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(15)
        .padding(.horizontal)
        .padding(.top, 10)
        .shadow(color: deepRed.opacity(0.3), radius: 10, x: 0, y: 5)
    }

    // Create a placeholder view for when no donations are recorded
    private func emptyDonationsView() -> some View {
        // Display a message encouraging the user to log their first donation
        VStack(spacing: 15) {
            Image(systemName: "drop.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 60, height: 60)
                .foregroundColor(deepRed.opacity(0.5))
                .padding()
            Text("No donations yet")
                .font(.headline)
                .foregroundColor(deepRed)
            Text("Log your first donation and start saving lives!")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }

    // Create a placeholder view for when no appointments are scheduled
    private func emptyAppointmentsView() -> some View {
        // Display a message encouraging the user to book their first appointment
        VStack(spacing: 15) {
            Image(systemName: "calendar")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 60, height: 60)
                .foregroundColor(deepRed.opacity(0.5))
                .padding()
            Text("No appointments yet")
                .font(.headline)
                .foregroundColor(deepRed)
            Text("Book your first appointment to donate blood!")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }

    // Create a list of donation cards
    private func donationsList() -> some View {
        // Display each donation as a card
        VStack(spacing: 10) {
            ForEach(donations) { donation in
                donationCard(donation: donation)
            }
        }
        .padding(.horizontal)
    }

    // Create a list of appointment cards
    private func appointmentsList() -> some View {
        // Display each appointment as a card
        VStack(spacing: 10) {
            ForEach(appointments) { appointment in
                appointmentCard(appointment: appointment)
            }
        }
        .padding(.horizontal)
    }

    // Create a card to display donation details
    private func donationCard(donation: Donation) -> some View {
        // Display donation date, hospital, address, blood type, and status
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(deepRed)
                Text(donation.date, style: .date)
                    .font(.system(size: 16, weight: .medium))
                Spacer()
                statusBadge(status: donation.status)
            }
            Divider()
                .background(deepRed.opacity(0.3))
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    // Show hospital name
                    HStack {
                        Image(systemName: "building.2")
                            .foregroundColor(deepRed)
                        Text(donation.hospital)
                            .font(.system(size: 15))
                    }
                    // Show hospital address if available
                    if let hospital = hospitals.first(where: { $0.name == donation.hospital }) {
                        HStack {
                            Image(systemName: "mappin.and.ellipse")
                                .foregroundColor(deepRed)
                            Text(hospital.address)
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                Spacer()
                // Show blood type
                HStack {
                    Image(systemName: "drop.fill")
                        .foregroundColor(deepRed)
                    Text(donation.bloodType)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(deepRed)
                }
            }
        }
        // Style the card with padding, white background, and shadow
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    // Create a card to display appointment details
    private func appointmentCard(appointment: Appointment) -> some View {
        // Display appointment date, hospital name, address, and status
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(deepRed)
                Text(appointment.date, style: .date)
                    .font(.system(size: 16, weight: .medium))
                Spacer()
                statusBadge(status: appointment.status)
            }
            Divider()
                .background(deepRed.opacity(0.3))
            // Show hospital name
            HStack {
                Image(systemName: "building.2")
                    .foregroundColor(deepRed)
                Text(appointment.hospitalName)
                    .font(.system(size: 15))
            }
            // Show hospital address
            HStack {
                Image(systemName: "mappin.and.ellipse")
                    .foregroundColor(deepRed)
                Text(appointment.hospitalAddress)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
        }
        // Style the card with padding, white background, and shadow
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    // Create a badge to display the status of a donation or appointment
    private func statusBadge(status: String) -> some View {
        // Show the status with color-coded background and text
        Text(status.capitalized)
            .font(.system(size: 12, weight: .semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                status == "approved" || status == "booked"
                    ? Color.green.opacity(0.2)
                    : status == "pending" ? Color.orange.opacity(0.2) : Color.red.opacity(0.2)
            )
            .foregroundColor(
                status == "approved" || status == "booked"
                    ? Color.green
                    : status == "pending" ? Color.orange : Color.red
            )
            .cornerRadius(10)
    }

    // Create buttons for logging a donation and booking an appointment
    private func actionButtons() -> some View {
        // Arrange buttons horizontally
        HStack(spacing: 15) {
            // Button to open the donation form
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
            // Navigation link to the appointment booking view
            NavigationLink(
                destination: AppointmentBookingView(authManager: authManager, streak: calcStreak(donations: donations))
                    .onDisappear {
                        // Refresh donations when returning from booking view
                        fetchDonations()
                    }
            ) {
                HStack {
                    Image(systemName: "calendar.badge.plus")
                    Text("Book Appointment")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white)
                .foregroundColor(deepRed)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(deepRed, lineWidth: 1)
                )
            }
        }
        // Style the button row with padding, background, and shadow
        .padding()
        .background(Color.white)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: -2)
    }

    // Fetch the user's donations from Firestore
    private func fetchDonations() {
        // Ensure the user is authenticated before fetching data
        guard let userId = authManager.user?.id else {
            print("No authenticated user for donations fetch, Firebase UID: \(String(describing: FirebaseAuth.Auth.auth().currentUser?.uid))")
            alertMessage = "User not authenticated. Please log in."
            showAlert = true
            return
        }
        // Set up a real-time listener for the user's donations
        db.collection("donations")
            .whereField("donorId", isEqualTo: userId)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    // Handle errors during data fetch
                    print("Error fetching donations: \(error)")
                    alertMessage = "Failed to fetch donations: \(error.localizedDescription)"
                    showAlert = true
                    return
                }
                // Parse donation data into Donation objects
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
                // Log the number of donations fetched
                print("Fetched \(donations.count) donations for userId: \(userId), calculated streaks: \(calcStreak(donations: donations))")
            }
    }

    // Fetch the list of hospitals from Firestore
    private func fetchHospitals() {
        // Set up a real-time listener for hospital data
        db.collection("hospitals").addSnapshotListener { snapshot, error in
            if let error = error {
                // Handle errors during data fetch
                print("Error fetching hospitals: \(error)")
                alertMessage = "Failed to fetch hospitals: \(error.localizedDescription)"
                showAlert = true
                return
            }
            // Parse hospital data into Hospital objects
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
            // Log the number of hospitals fetched
            print("Fetched \(hospitals.count) hospitals: \(hospitals.map { $0.name })")
        }
    }

    // Fetch the user's appointments from Firestore
    private func fetchAppointments() {
        // Ensure the user is authenticated before fetching data
        guard let userId = authManager.user?.id else {
            print("No authenticated user for appointments fetch, Firebase UID: \(String(describing: FirebaseAuth.Auth.auth().currentUser?.uid))")
            alertMessage = "User not authenticated. Please log in."
            showAlert = true
            return
        }
        // Set up a real-time listener for the user's appointments
        db.collection("appointments")
            .whereField("donorId", isEqualTo: userId)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    // Handle errors during data fetch
                    print("Error fetching appointments: \(error)")
                    alertMessage = "Failed to fetch appointments: \(error.localizedDescription)"
                    showAlert = true
                    return
                }
                // Parse appointment data into Appointment objects
                appointments = snapshot?.documents.compactMap { document in
                    let data = document.data()
                    guard let id = data["id"] as? String,
                          let donorId = data["donorId"] as? String,
                          let hospitalId = data["hospitalId"] as? String,
                          let hospitalName = data["hospitalName"] as? String,
                          let hospitalAddress = data["hospitalAddress"] as? String,
                          let date = (data["date"] as? Timestamp)?.dateValue(),
                          let status = data["status"] as? String else {
                        print("Failed to decode appointment document \(document.documentID): \(data)")
                        return nil
                    }
                    return Appointment(id: id, donorId: donorId, hospitalId: hospitalId, hospitalName: hospitalName, hospitalAddress: hospitalAddress, date: date, status: status)
                } ?? []
                // Log the number of appointments fetched
                print("Fetched \(appointments.count) appointments for userId: \(userId)")
            }
    }
}

// Provide a preview of the DonorDashboardView for SwiftUI's canvas
#Preview {
    DonorDashboardView()
        .environmentObject(AuthManager())
}


































































































/*import FirebaseFirestore
import SwiftUI
import FirebaseAuth

struct DonorDashboardView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var donations: [Donation] = []
    @State private var appointments: [Appointment] = []
    @State private var hospitals: [Hospital] = []
    @State private var showDonationForm = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    private let db = Firestore.firestore()

    private let deepRed = Color(red: 0.7, green: 0.1, blue: 0.1)
    private let cream = Color(red: 0.98, green: 0.96, blue: 0.9)
    private let lightRed = Color(red: 0.9, green: 0.7, blue: 0.7)

    var body: some View {
        NavigationView {
            ZStack {
                cream.ignoresSafeArea()
                VStack(spacing: 0) {
                    if let user = authManager.user {
                        userInfoCard(user: user, streaks: calcStreak(donations: donations))
                        ScrollView {
                            VStack(alignment: .leading, spacing: 20) {
                                Text("Your Donations")
                                    .font(.headline)
                                    .padding(.horizontal)
                                    .padding(.top)
                                    .foregroundColor(deepRed)
                                if donations.isEmpty {
                                    emptyDonationsView()
                                } else {
                                    donationsList()
                                }
                                Text("Your Appointments")
                                    .font(.headline)
                                    .padding(.horizontal)
                                    .padding(.top)
                                    .foregroundColor(deepRed)
                                if appointments.isEmpty {
                                    emptyAppointmentsView()
                                } else {
                                    appointmentsList()
                                }
                            }
                        }
                        .padding(.vertical, 5)
                        actionButtons()
                    }
                }
            }
            .navigationTitle("My Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        authManager.signOut()
                    }) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(deepRed)
                    }
                }
            }
            .sheet(isPresented: $showDonationForm) {
                DonationFormView(authManager: authManager)
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .onAppear {
                fetchDonations()
                fetchHospitals()
                fetchAppointments()
            }
        }
    }

    private func calcStreak(donations: [Donation]) -> Int {
        return donations.filter { $0.status == "approved" }.count
    }

    private func userInfoCard(user: AppUser, streaks: Int) -> some View {
        VStack(spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Welcome, \(user.name)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Text(user.email)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                }
                Spacer()
                VStack {
                    Text("\(streaks)")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    Text("Streak\(streaks == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.9))
                }
                .frame(width: 80, height: 80)
                .background(Color.white.opacity(0.2))
                .cornerRadius(40)
            }
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [deepRed, deepRed.opacity(0.8)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(15)
        .padding(.horizontal)
        .padding(.top, 10)
        .shadow(color: deepRed.opacity(0.3), radius: 10, x: 0, y: 5)
    }

    private func emptyDonationsView() -> some View {
        VStack(spacing: 15) {
            Image(systemName: "drop.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 60, height: 60)
                .foregroundColor(deepRed.opacity(0.5))
                .padding()
            Text("No donations yet")
                .font(.headline)
                .foregroundColor(deepRed)
            Text("Log your first donation and start saving lives!")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }

    private func emptyAppointmentsView() -> some View {
        VStack(spacing: 15) {
            Image(systemName: "calendar")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 60, height: 60)
                .foregroundColor(deepRed.opacity(0.5))
                .padding()
            Text("No appointments yet")
                .font(.headline)
                .foregroundColor(deepRed)
            Text("Book your first appointment to donate blood!")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }

    private func donationsList() -> some View {
        VStack(spacing: 10) {
            ForEach(donations) { donation in
                donationCard(donation: donation)
            }
        }
        .padding(.horizontal)
    }

    private func appointmentsList() -> some View {
        VStack(spacing: 10) {
            ForEach(appointments) { appointment in
                appointmentCard(appointment: appointment)
            }
        }
        .padding(.horizontal)
    }

    private func donationCard(donation: Donation) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(deepRed)
                Text(donation.date, style: .date)
                    .font(.system(size: 16, weight: .medium))
                Spacer()
                statusBadge(status: donation.status)
            }
            Divider()
                .background(deepRed.opacity(0.3))
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Image(systemName: "building.2")
                            .foregroundColor(deepRed)
                        Text(donation.hospital)
                            .font(.system(size: 15))
                    }
                    if let hospital = hospitals.first(where: { $0.name == donation.hospital }) {
                        HStack {
                            Image(systemName: "mappin.and.ellipse")
                                .foregroundColor(deepRed)
                            Text(hospital.address)
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                Spacer()
                HStack {
                    Image(systemName: "drop.fill")
                        .foregroundColor(deepRed)
                    Text(donation.bloodType)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(deepRed)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    private func appointmentCard(appointment: Appointment) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(deepRed)
                Text(appointment.date, style: .date)
                    .font(.system(size: 16, weight: .medium))
                Spacer()
                statusBadge(status: appointment.status)
            }
            Divider()
                .background(deepRed.opacity(0.3))
            HStack {
                Image(systemName: "building.2")
                    .foregroundColor(deepRed)
                Text(appointment.hospitalName)
                    .font(.system(size: 15))
            }
            HStack {
                Image(systemName: "mappin.and.ellipse")
                    .foregroundColor(deepRed)
                Text(appointment.hospitalAddress)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    private func statusBadge(status: String) -> some View {
        Text(status.capitalized)
            .font(.system(size: 12, weight: .semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                status == "approved" || status == "booked"
                    ? Color.green.opacity(0.2)
                    : status == "pending" ? Color.orange.opacity(0.2) : Color.red.opacity(0.2)
            )
            .foregroundColor(
                status == "approved" || status == "booked"
                    ? Color.green
                    : status == "pending" ? Color.orange : Color.red
            )
            .cornerRadius(10)
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
            NavigationLink(
                destination: AppointmentBookingView(authManager: authManager, streak: calcStreak(donations: donations))
                    .onDisappear {
                        fetchDonations()
                    }
            ) {
                HStack {
                    Image(systemName: "calendar.badge.plus")
                    Text("Book Appointment")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white)
                .foregroundColor(deepRed)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(deepRed, lineWidth: 1)
                )
            }
        }
        .padding()
        .background(Color.white)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: -2)
    }

    private func fetchDonations() {
        guard let userId = authManager.user?.id else {
            print("No authenticated user for donations fetch, Firebase UID: \(String(describing: FirebaseAuth.Auth.auth().currentUser?.uid))")
            alertMessage = "User not authenticated. Please log in."
            showAlert = true
            return
        }
        db.collection("donations")
            .whereField("donorId", isEqualTo: userId)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error fetching donations: \(error)")
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
                print("Fetched \(donations.count) donations for userId: \(userId), calculated streaks: \(calcStreak(donations: donations))")
            }
    }

    private func fetchHospitals() {
        db.collection("hospitals").addSnapshotListener { snapshot, error in
            if let error = error {
                print("Error fetching hospitals: \(error)")
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
            print("Fetched \(hospitals.count) hospitals: \(hospitals.map { $0.name })")
        }
    }

    private func fetchAppointments() {
        guard let userId = authManager.user?.id else {
            print("No authenticated user for appointments fetch, Firebase UID: \(String(describing: FirebaseAuth.Auth.auth().currentUser?.uid))")
            alertMessage = "User not authenticated. Please log in."
            showAlert = true
            return
        }
        db.collection("appointments")
            .whereField("donorId", isEqualTo: userId)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error fetching appointments: \(error)")
                    alertMessage = "Failed to fetch appointments: \(error.localizedDescription)"
                    showAlert = true
                    return
                }
                appointments = snapshot?.documents.compactMap { document in
                    let data = document.data()
                    guard let id = data["id"] as? String,
                          let donorId = data["donorId"] as? String,
                          let hospitalId = data["hospitalId"] as? String,
                          let hospitalName = data["hospitalName"] as? String,
                          let hospitalAddress = data["hospitalAddress"] as? String,
                          let date = (data["date"] as? Timestamp)?.dateValue(),
                          let status = data["status"] as? String else {
                        print("Failed to decode appointment document \(document.documentID): \(data)")
                        return nil
                    }
                    return Appointment(id: id, donorId: donorId, hospitalId: hospitalId, hospitalName: hospitalName, hospitalAddress: hospitalAddress, date: date, status: status)
                } ?? []
                print("Fetched \(appointments.count) appointments for userId: \(userId)")
            }
    }
}

#Preview {
    DonorDashboardView()
        .environmentObject(AuthManager())
}*/



/*import SwiftUI
import FirebaseFirestore

struct DonorDashboardView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var donations: [Donation] = []
    @State private var hospitals: [Hospital] = []
    @State private var showDonationForm = false
    private let db = Firestore.firestore()

    var body: some View {
        NavigationView {
            VStack {
                if let user = authManager.user {
                    Text("Welcome, \(user.name)")
                        .font(.title)
                    Text("Streaks: \(user.streaks)")
                        .font(.headline)
                    List(donations) { donation in
                        VStack(alignment: .leading) {
                            Text("Date: \(donation.date, format: .dateTime)")
                            Text("Hospital: \(donation.hospital)")
                            // Optionally display the hospital address if you match it with hospitals
                            if let hospital = hospitals.first(where: { $0.name == donation.hospital }) {
                                Text("Address: \(hospital.address)")
                            }
                            Text("Status: \(donation.status)")
                        }
                    }
                    Button("Log Donation") {
                        showDonationForm = true
                    }
                    .buttonStyle(.borderedProminent)
                    NavigationLink("Book Appointment") {
                        AppointmentBookingView(authManager: authManager)
                    }
                    .buttonStyle(.bordered)
                    Button("Logout") {
                        authManager.signOut()
                    }
                }
            }
            .navigationTitle("Donor Dashboard")
            .sheet(isPresented: $showDonationForm) {
                DonationFormView(authManager: authManager)
            }
            .onAppear {
                fetchDonations()
                fetchHospitals()
            }
        }
    }

    private func fetchDonations() {
        guard let userId = authManager.user?.id else { return }
        db.collection("donations")
            .whereField("donorId", isEqualTo: userId)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error fetching donations: \(error)")
                    return
                }
                donations = snapshot?.documents.compactMap { try? $0.data(as: Donation.self) } ?? []
            }
    }

    private func fetchHospitals() {
        db.collection("hospitals").addSnapshotListener { snapshot, error in
            if let error = error {
                print("Error fetching hospitals: \(error)")
                return
            }
            hospitals = snapshot?.documents.compactMap { try? $0.data(as: Hospital.self) } ?? []
        }
    }
}

#Preview {
    DonorDashboardView()
        .environmentObject(AuthManager())
}*/
