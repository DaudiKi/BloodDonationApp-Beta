// Import SwiftUI for building the user interface, FirebaseFirestore for database interactions, and AVFoundation for haptic feedback
import SwiftUI
import FirebaseFirestore
import AVFoundation

// Define the Hospital struct to represent hospital data with identifiable and codable properties
struct Hospital: Identifiable, Codable {
    // Unique identifier for the hospital
    let id: String
    // Name of the hospital
    let name: String
    // Address of the hospital
    let address: String
    
    // Define coding keys to map struct properties to Firestore document fields
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case address
    }
}

// Define the Appointment struct to represent appointment data with identifiable and codable properties
struct Appointment: Identifiable, Codable {
    // Unique identifier for the appointment
    let id: String
    // ID of the donor booking the appointment
    let donorId: String
    // ID of the selected hospital
    let hospitalId: String
    // Name of the selected hospital
    let hospitalName: String
    // Address of the selected hospital
    let hospitalAddress: String
    // Date of the appointment
    let date: Date
    // Status of the appointment (e.g., "booked")
    let status: String
    
    // Define coding keys to map struct properties to Firestore document fields
    enum CodingKeys: String, CodingKey {
        case id
        case donorId
        case hospitalId
        case hospitalName
        case hospitalAddress
        case date
        case status
    }
}

// Define AppointmentBookingView, a SwiftUI View for users to book blood donation appointments
struct AppointmentBookingView: View {
    // Observe AuthManager to access user authentication data
    @ObservedObject var authManager: AuthManager
    // Store a hardcoded list of hospitals for selection
    @State private var hospitals: [Hospital] = [
        Hospital(id: "hospital1", name: "City Hospital", address: "123 Main St, Nairobi"),
        Hospital(id: "hospital2", name: "General Medical Center", address: "456 Health Ave, Mombasa"),
        Hospital(id: "hospital3", name: "Hope Clinic", address: "789 Wellness Rd, Kisumu")
    ]
    // Track the currently selected hospital
    @State private var selectedHospital: Hospital?
    // Store the selected appointment date, defaulting to the current date
    @State private var date = Date()
    // Control whether an alert is displayed for errors or success messages
    @State private var showAlert = false
    // Store the message content for the alert
    @State private var alertMessage = ""
    // Store the title for the alert
    @State private var alertTitle = ""
    // Track whether the alert indicates a successful booking
    @State private var isSuccess = false
    // Store the user's donation streak count
    @State private var streak: Int
    // Control whether a loading indicator is shown while fetching hospitals (not used with hardcoded data)
    @State private var isLoadingHospitals = false
    // Control whether a retry button is shown if hospital fetching fails (not used with hardcoded data)
    @State private var showRetryButton = false
    
    // Create a reference to the Firestore database for storing appointment data
    private let db = Firestore.firestore()
    
    // Define custom colors for consistent UI styling
    private let deepRed = Color(red: 0.8, green: 0.1, blue: 0.1)
    private let cream = Color(red: 0.98, green: 0.96, blue: 0.9)
    private let lightRed = Color(red: 0.95, green: 0.8, blue: 0.8)
    
    // Initialize the view with AuthManager and streak count
    init(authManager: AuthManager, streak: Int) {
        self.authManager = authManager
        self._streak = State(initialValue: streak)
    }
    
    // Define the main UI structure of the appointment booking view
    var body: some View {
        // Use NavigationView to provide a navigation bar with title and styling
        NavigationView {
            // Use ZStack to layer the background color and content
            ZStack {
                // Set a cream-colored background that extends to all edges, ignoring safe areas
                cream.edgesIgnoringSafeArea(.all)
                // Arrange content vertically with spacing
                VStack(spacing: 20) {
                    // Display the user's donation streak information
                    streakInfoView
                    // Create a scrollable view for hospital and date selection
                    ScrollView {
                        // Arrange selection views vertically with spacing
                        VStack(spacing: 20) {
                            // Show the hospital selection interface
                            hospitalSelectionView
                            // Show the date selection interface
                            dateSelectionView
                            // Add spacing at the bottom
                            Spacer(minLength: 30)
                            // Display the button to book the appointment
                            bookButton
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.top)
            }
            // Set the navigation title for the view
            .navigationTitle("Book Appointment")
            // Display the title inline within the navigation bar
            .navigationBarTitleDisplayMode(.inline)
            // Apply a deep red background to the navigation bar
            .toolbarBackground(deepRed, for: .navigationBar)
            // Ensure the navigation bar background is visible
            .toolbarBackground(.visible, for: .navigationBar)
            // Use a dark color scheme for toolbar text and icons
            .toolbarColorScheme(.dark, for: .navigationBar)
            // Show an alert with a title and message when triggered
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text(alertTitle),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK")) {
                        // Clear the selected hospital on successful booking
                        if isSuccess {
                            selectedHospital = nil
                        }
                    }
                )
            }
        }
    }
    
    // Create a view to display the user's donation streak information
    private var streakInfoView: some View {
        // Display the streak count and requirements for booking
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(lightRed)
            HStack(spacing: 15) {
                // Show a flame icon to represent streaks
                Image(systemName: "flame.fill")
                    .font(.title2)
                    .foregroundColor(deepRed)
                // Display streak details
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Donation Streaks")
                        .font(.headline)
                        .foregroundColor(.black)
                    Text("You have \(streak) streak\(streak == 1 ? "" : "s") available")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    // Warn the user if they have insufficient streaks
                    if streak < 1 {
                        Text("You need at least 1 streak to book an appointment")
                            .font(.caption)
                            .foregroundColor(deepRed)
                            .padding(.top, 2)
                    }
                }
                Spacer()
            }
            .padding()
        }
        .padding(.horizontal)
        .frame(height: 100)
    }
    
    // Create a view for selecting a hospital
    private var hospitalSelectionView: some View {
        // Display a list of hospitals or a loading/error state
        VStack(alignment: .leading, spacing: 10) {
            // Show the section title
            Text("Select Hospital")
                .font(.headline)
                .foregroundColor(deepRed)
            // Display a loading indicator if hospitals are being fetched
            if isLoadingHospitals {
                VStack(spacing: 15) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: deepRed))
                        .scaleEffect(1.5)
                        .padding()
                    Text("Loading hospitals...")
                        .font(.headline)
                        .foregroundColor(deepRed)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            } else if hospitals.isEmpty {
                // Display a message if no hospitals are available
                VStack(spacing: 15) {
                    Image(systemName: "building.2.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 60, height: 60)
                        .foregroundColor(deepRed.opacity(0.5))
                        .padding()
                    Text("No hospitals available")
                        .font(.headline)
                        .foregroundColor(deepRed)
                    Text("Please try again or contact support.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    // Show a retry button if hospital fetching fails
                    if showRetryButton {
                        Button(action: {
                            // No fetch needed, but can reset UI if desired
                        }) {
                            Text("Retry")
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity)
                                .background(deepRed)
                                .cornerRadius(8)
                        }
                        .padding(.horizontal)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            } else {
                // Display a list of hospital cards
                VStack(spacing: 12) {
                    ForEach(hospitals, id: \.id) { hospital in
                        hospitalCardView(hospital)
                    }
                    // Show a clear selection button if a hospital is selected
                    if selectedHospital != nil {
                        Button(action: {
                            // Deselect the hospital with animation and provide haptic feedback
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedHospital = nil
                            }
                            let impact = UIImpactFeedbackGenerator(style: .light)
                            impact.impactOccurred()
                        }) {
                            Text("Clear Selection")
                                .font(.subheadline)
                                .foregroundColor(deepRed)
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(deepRed, lineWidth: 1)
                                )
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
    }
    
    // Create a card for each hospital in the selection list
    private func hospitalCardView(_ hospital: Hospital) -> some View {
        // Display hospital details and allow selection
        Button(action: {
            // Select the hospital with animation and provide haptic feedback
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedHospital = hospital
            }
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            print("Selected hospital: \(hospital.name) (ID: \(hospital.id))")
        }) {
            HStack {
                // Show hospital name and address
                VStack(alignment: .leading, spacing: 5) {
                    Text(hospital.name)
                        .font(.headline)
                        .foregroundColor(.black)
                    Text(hospital.address)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }
                Spacer()
                // Indicate whether the hospital is selected
                Image(systemName: selectedHospital?.id == hospital.id ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(selectedHospital?.id == hospital.id ? deepRed : .gray)
                    .font(.title3)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: selectedHospital?.id == hospital.id ? deepRed.opacity(0.2) : Color.black.opacity(0.05),
                           radius: 5, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(selectedHospital?.id == hospital.id ? deepRed : Color.clear, lineWidth: 2)
            )
        }
        // Use PlainButtonStyle to avoid default button styling
        .buttonStyle(PlainButtonStyle())
    }
    
    // Create a view for selecting the appointment date
    private var dateSelectionView: some View {
        // Display a date picker in a styled container
        VStack(alignment: .leading, spacing: 10) {
            Text("Select Date")
                .font(.headline)
                .foregroundColor(deepRed)
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                // Provide a graphical date picker for selecting the appointment date
                DatePicker("", selection: $date, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .accentColor(deepRed)
                    .padding()
            }
        }
    }
    
    // Create a button to submit the appointment booking
    private var bookButton: some View {
        // Display a button to book the appointment, disabled if conditions are not met
        Button(action: {
            // Trigger the appointment booking process
            bookAppointment()
        }) {
            Text("Book Appointment")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(streak < 1 || selectedHospital == nil ? Color.gray : deepRed)
                )
                .shadow(color: streak < 1 || selectedHospital == nil ? Color.clear : deepRed.opacity(0.3),
                        radius: 5, x: 0, y: 3)
        }
        // Disable the button if the user has no streaks or no hospital is selected
        .disabled(streak < 1 || selectedHospital == nil)
        .padding(.bottom, 30)
    }
    
    // Placeholder function for adding test hospitals (not used with hardcoded hospitals)
    private func addTestHospitals() {
        // Log that the function is disabled since hospitals are hardcoded
        print("addTestHospitals is disabled; hospitals are now hardcoded.")
    }
    
    // Handle the appointment booking process
    private func bookAppointment() {
        // Ensure the user is authenticated and a hospital is selected
        guard let userId = authManager.user?.id,
              let hospitalId = selectedHospital?.id,
              let hospitalName = selectedHospital?.name,
              let hospitalAddress = selectedHospital?.address else {
            alertTitle = "Error"
            alertMessage = "Please select a hospital and ensure you are logged in."
            showAlert = true
            return
        }
        // Check if the user has at least one streak
        guard streak >= 1 else {
            alertTitle = "Insufficient Streaks"
            alertMessage = "You need at least one streak to book an appointment. Current streaks: \(streak)"
            showAlert = true
            return
        }
        
        // Perform asynchronous operations for booking
        Task {
            do {
                // Fetch approved donations to verify available streaks
                let snapshot: QuerySnapshot = try await db.collection("donations")
                    .whereField("donorId", isEqualTo: userId)
                    .whereField("status", isEqualTo: "approved")
                    .getDocuments()
                
                // Parse approved donations
                let approvedDonations: [Donation] = snapshot.documents.compactMap { document in
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
                }
                
                // Verify available streaks
                let availableStreaks = approvedDonations.count
                print("Available streaks (approved donations): \(availableStreaks), Local streak: \(streak)")
                if availableStreaks < 1 {
                    alertTitle = "Insufficient Streaks"
                    alertMessage = "No approved donations available to use as streaks."
                    showAlert = true
                    return
                }
                
                // Create a new appointment object
                let appointmentId = UUID().uuidString
                let appointment = Appointment(
                    id: appointmentId,
                    donorId: userId,
                    hospitalId: hospitalId,
                    hospitalName: hospitalName,
                    hospitalAddress: hospitalAddress,
                    date: date,
                    status: "booked"
                )
                
                // Prepare appointment data for Firestore
                let appointmentData: [String: Any] = [
                    "id": appointment.id,
                    "donorId": appointment.donorId,
                    "hospitalId": appointment.hospitalId,
                    "hospitalName": appointment.hospitalName,
                    "hospitalAddress": appointment.hospitalAddress,
                    "date": Timestamp(date: appointment.date),
                    "status": appointment.status
                ]
                
                // Save the appointment to Firestore
                try await db.collection("appointments").document(appointmentId).setData(appointmentData)
                
                // Mark one approved donation as used to consume a streak
                if let donationToUse = approvedDonations.first {
                    try await db.collection("donations").document(donationToUse.id).updateData(["status": "used"])
                    print("Marked donation \(donationToUse.id) as used")
                    // Update the local streak count
                    await MainActor.run {
                        streak -= 1
                    }
                } else {
                    // Handle case where no donation is available to mark as used
                    print("No donation found to mark as used")
                    alertTitle = "Partial Success"
                    alertMessage = "Appointment booked, but failed to update streaks: No donation available."
                    isSuccess = true
                    showAlert = true
                    return
                }
                
                // Show success message
                alertTitle = "Success!"
                alertMessage = "Your appointment has been booked successfully at \(hospitalName) on \(date.formatted(date: .long, time: .omitted))."
                isSuccess = true
                showAlert = true
            } catch {
                // Handle errors during booking
                print("Error booking appointment: \(error.localizedDescription)")
                alertTitle = "Booking Failed"
                alertMessage = "Failed to book appointment: \(error.localizedDescription)"
                isSuccess = false
                showAlert = true
            }
        }
    }
}

// Provide a preview of the AppointmentBookingView for SwiftUI's canvas
#Preview {
    AppointmentBookingView(authManager: AuthManager(), streak: 3)
}


































































































/*import SwiftUI
import FirebaseFirestore
import AVFoundation

struct Hospital: Identifiable, Codable {
    let id: String
    let name: String
    let address: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case address
    }
}

struct Appointment: Identifiable, Codable {
    let id: String
    let donorId: String
    let hospitalId: String
    let hospitalName: String
    let hospitalAddress: String
    let date: Date
    let status: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case donorId
        case hospitalId
        case hospitalName
        case hospitalAddress
        case date
        case status
    }
}

struct AppointmentBookingView: View {
    @ObservedObject var authManager: AuthManager
    @State private var hospitals: [Hospital] = [
        Hospital(id: "hospital1", name: "City Hospital", address: "123 Main St, Nairobi"),
        Hospital(id: "hospital2", name: "General Medical Center", address: "456 Health Ave, Mombasa"),
        Hospital(id: "hospital3", name: "Hope Clinic", address: "789 Wellness Rd, Kisumu")
    ]
    @State private var selectedHospital: Hospital?
    @State private var date = Date()
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""
    @State private var isSuccess = false
    @State private var streak: Int
    @State private var isLoadingHospitals = false
    @State private var showRetryButton = false
    
    private let db = Firestore.firestore()
    
    private let deepRed = Color(red: 0.8, green: 0.1, blue: 0.1)
    private let cream = Color(red: 0.98, green: 0.96, blue: 0.9)
    private let lightRed = Color(red: 0.95, green: 0.8, blue: 0.8)
    
    init(authManager: AuthManager, streak: Int) {
        self.authManager = authManager
        self._streak = State(initialValue: streak)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                cream.edgesIgnoringSafeArea(.all)
                VStack(spacing: 20) {
                    streakInfoView
                    ScrollView {
                        VStack(spacing: 20) {
                            hospitalSelectionView
                            dateSelectionView
                            Spacer(minLength: 30)
                            bookButton
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.top)
            }
            .navigationTitle("Book Appointment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(deepRed, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text(alertTitle),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK")) {
                        if isSuccess {
                            selectedHospital = nil
                        }
                    }
                )
            }
        }
    }
    
    private var streakInfoView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(lightRed)
            HStack(spacing: 15) {
                Image(systemName: "flame.fill")
                    .font(.title2)
                    .foregroundColor(deepRed)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Donation Streaks")
                        .font(.headline)
                        .foregroundColor(.black)
                    Text("You have \(streak) streak\(streak == 1 ? "" : "s") available")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    if streak < 1 {
                        Text("You need at least 1 streak to book an appointment")
                            .font(.caption)
                            .foregroundColor(deepRed)
                            .padding(.top, 2)
                    }
                }
                Spacer()
            }
            .padding()
        }
        .padding(.horizontal)
        .frame(height: 100)
    }
    
    private var hospitalSelectionView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Select Hospital")
                .font(.headline)
                .foregroundColor(deepRed)
            if isLoadingHospitals {
                VStack(spacing: 15) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: deepRed))
                        .scaleEffect(1.5)
                        .padding()
                    Text("Loading hospitals...")
                        .font(.headline)
                        .foregroundColor(deepRed)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            } else if hospitals.isEmpty {
                VStack(spacing: 15) {
                    Image(systemName: "building.2.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 60, height: 60)
                        .foregroundColor(deepRed.opacity(0.5))
                        .padding()
                    Text("No hospitals available")
                        .font(.headline)
                        .foregroundColor(deepRed)
                    Text("Please try again or contact support.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    if showRetryButton {
                        Button(action: {
                            // No fetch needed, but can reset UI if desired
                        }) {
                            Text("Retry")
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity)
                                .background(deepRed)
                                .cornerRadius(8)
                        }
                        .padding(.horizontal)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            } else {
                VStack(spacing: 12) {
                    ForEach(hospitals, id: \.id) { hospital in
                        hospitalCardView(hospital)
                    }
                    if selectedHospital != nil {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedHospital = nil
                            }
                            let impact = UIImpactFeedbackGenerator(style: .light)
                            impact.impactOccurred()
                        }) {
                            Text("Clear Selection")
                                .font(.subheadline)
                                .foregroundColor(deepRed)
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(deepRed, lineWidth: 1)
                                )
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
    }
    
    private func hospitalCardView(_ hospital: Hospital) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedHospital = hospital
            }
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            print("Selected hospital: \(hospital.name) (ID: \(hospital.id))")
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text(hospital.name)
                        .font(.headline)
                        .foregroundColor(.black)
                    Text(hospital.address)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }
                Spacer()
                Image(systemName: selectedHospital?.id == hospital.id ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(selectedHospital?.id == hospital.id ? deepRed : .gray)
                    .font(.title3)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: selectedHospital?.id == hospital.id ? deepRed.opacity(0.2) : Color.black.opacity(0.05),
                           radius: 5, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(selectedHospital?.id == hospital.id ? deepRed : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var dateSelectionView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Select Date")
                .font(.headline)
                .foregroundColor(deepRed)
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                DatePicker("", selection: $date, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .accentColor(deepRed)
                    .padding()
            }
        }
    }
    
    private var bookButton: some View {
        Button(action: {
            bookAppointment()
        }) {
            Text("Book Appointment")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(streak < 1 || selectedHospital == nil ? Color.gray : deepRed)
                )
                .shadow(color: streak < 1 || selectedHospital == nil ? Color.clear : deepRed.opacity(0.3),
                        radius: 5, x: 0, y: 3)
        }
        .disabled(streak < 1 || selectedHospital == nil)
        .padding(.bottom, 30)
    }
    
    private func addTestHospitals() {
        // No longer needed since hospitals are hardcoded
        print("addTestHospitals is disabled; hospitals are now hardcoded.")
    }
    
    private func bookAppointment() {
        guard let userId = authManager.user?.id,
              let hospitalId = selectedHospital?.id,
              let hospitalName = selectedHospital?.name,
              let hospitalAddress = selectedHospital?.address else {
            alertTitle = "Error"
            alertMessage = "Please select a hospital and ensure you are logged in."
            showAlert = true
            return
        }
        guard streak >= 1 else {
            alertTitle = "Insufficient Streaks"
            alertMessage = "You need at least one streak to book an appointment. Current streaks: \(streak)"
            showAlert = true
            return
        }
        
        Task {
            do {
                let snapshot: QuerySnapshot = try await db.collection("donations")
                    .whereField("donorId", isEqualTo: userId)
                    .whereField("status", isEqualTo: "approved")
                    .getDocuments()
                
                let approvedDonations: [Donation] = snapshot.documents.compactMap { document in
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
                }
                
                let availableStreaks = approvedDonations.count
                print("Available streaks (approved donations): \(availableStreaks), Local streak: \(streak)")
                if availableStreaks < 1 {
                    alertTitle = "Insufficient Streaks"
                    alertMessage = "No approved donations available to use as streaks."
                    showAlert = true
                    return
                }
                
                let appointmentId = UUID().uuidString
                let appointment = Appointment(
                    id: appointmentId,
                    donorId: userId,
                    hospitalId: hospitalId,
                    hospitalName: hospitalName,
                    hospitalAddress: hospitalAddress,
                    date: date,
                    status: "booked"
                )
                
                let appointmentData: [String: Any] = [
                    "id": appointment.id,
                    "donorId": appointment.donorId,
                    "hospitalId": appointment.hospitalId,
                    "hospitalName": appointment.hospitalName,
                    "hospitalAddress": appointment.hospitalAddress,
                    "date": Timestamp(date: appointment.date),
                    "status": appointment.status
                ]
                
                try await db.collection("appointments").document(appointmentId).setData(appointmentData)
                
                if let donationToUse = approvedDonations.first {
                    try await db.collection("donations").document(donationToUse.id).updateData(["status": "used"])
                    print("Marked donation \(donationToUse.id) as used")
                    await MainActor.run {
                        streak -= 1
                    }
                } else {
                    print("No donation found to mark as used")
                    alertTitle = "Partial Success"
                    alertMessage = "Appointment booked, but failed to update streaks: No donation available."
                    isSuccess = true
                    showAlert = true
                    return
                }
                
                alertTitle = "Success!"
                alertMessage = "Your appointment has been booked successfully at \(hospitalName) on \(date.formatted(date: .long, time: .omitted))."
                isSuccess = true
                showAlert = true
            } catch {
                print("Error booking appointment: \(error.localizedDescription)")
                alertTitle = "Booking Failed"
                alertMessage = "Failed to book appointment: \(error.localizedDescription)"
                isSuccess = false
                showAlert = true
            }
        }
    }
}

#Preview {
    AppointmentBookingView(authManager: AuthManager(), streak: 3)
}*/
































/*import SwiftUI
import FirebaseFirestore

struct AppointmentBookingView: View {
    @ObservedObject var authManager: AuthManager
    @State private var hospitals: [Hospital] = []
    @State private var selectedHospital: Hospital?
    @State private var date = Date()
    @State private var showAlert = false
    @State private var alertMessage = ""
    private let db = Firestore.firestore()

    var body: some View {
        NavigationView {
            Form {
                Picker("Hospital", selection: $selectedHospital) {
                    Text("Select a hospital").tag(nil as Hospital?)
                    ForEach(hospitals, id: \.id) { hospital in
                        VStack(alignment: .leading) {
                            Text(hospital.name)
                            Text(hospital.address)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .tag(hospital as Hospital?)
                    }
                }
                DatePicker("Appointment Date", selection: $date, displayedComponents: .date)
            }
            .navigationTitle("Book Appointment")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Book") {
                        bookAppointment()
                    }
                    .disabled(authManager.user?.streaks ?? 0 < 1 || selectedHospital == nil)
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .onAppear {
                fetchHospitals()
            }
        }
    }

    private func fetchHospitals() {
        db.collection("hospitals").addSnapshotListener { snapshot, error in
            if let error = error {
                print("Error fetching hospitals: \(error)")
                alertMessage = "Failed to load hospitals: \(error.localizedDescription)"
                showAlert = true
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

    private func bookAppointment() {
        guard let userId = authManager.user?.id, let hospitalId = selectedHospital?.id else {
            alertMessage = "Please select a hospital and ensure you are logged in."
            showAlert = true
            return
        }
        guard authManager.user?.streaks ?? 0 >= 1 else {
            alertMessage = "You need at least one streak to book an appointment."
            showAlert = true
            return
        }
        let appointmentId = UUID().uuidString
        let appointment = Appointment(
            id: appointmentId,
            donorId: userId,
            hospitalId: hospitalId,
            date: date,
            status: "booked"
        )
        db.collection("appointments").document(appointmentId).setData([
            "id": appointment.id,
            "donorId": appointment.donorId,
            "hospitalId": appointment.hospitalId,
            "date": Timestamp(date: appointment.date),
            "status": appointment.status
        ]) { error in
            if let error = error {
                alertMessage = "Failed to book appointment: \(error.localizedDescription)"
                showAlert = true
                return
            }
            db.collection("users").document(userId).updateData([
                "streaks": FieldValue.increment(Int64(-1))
            ]) { error in
                if let error = error {
                    alertMessage = "Appointment booked, but failed to update streaks: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        }
    }
}

#Preview {
    AppointmentBookingView(authManager: AuthManager())
}*/
