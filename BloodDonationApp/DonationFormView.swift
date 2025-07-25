// Import SwiftUI framework for creating the user interface and FirebaseFirestore for interacting with the Firestore database
import SwiftUI
import FirebaseFirestore

// Define DonationFormView, a SwiftUI View responsible for allowing users to log their blood donations
struct DonationFormView: View {
    // Observe AuthManager to track user authentication state and access user data
    @ObservedObject var authManager: AuthManager
    // Access environment variable to dismiss the view when needed (e.g., cancel or successful submission)
    @Environment(\.dismiss) var dismiss
    // Store the selected donation date, defaulting to the current date
    @State private var date = Date()
    // Store the hospital name entered or selected by the user
    @State private var hospital = ""
    // Store the blood type selected by the user
    @State private var bloodType = ""
    // Control whether an alert should be displayed to the user
    @State private var showAlert = false
    // Store the message to be shown in the alert
    @State private var alertMessage = ""
    // Control whether a loading indicator should be displayed during async operations
    @State private var showLoading = false
    // Track whether the user has reached the annual donation limit (4 donations per year)
    @State private var donationLimitReached = false
    // Store a message indicating when the user can donate again if the limit is reached
    @State private var remainingTimeMessage = ""
    // Create a reference to the Firestore database for querying and storing donation data
    private let db = Firestore.firestore()
    
    // Define a custom deep red color for UI elements to maintain consistent branding
    private let deepRed = Color(red: 0.7, green: 0.1, blue: 0.1)
    // Define a custom cream color for the background to enhance visual appeal
    private let cream = Color(red: 0.98, green: 0.96, blue: 0.9)
    // List of valid blood types to ensure user selects a recognized type
    private let validBloodTypes = ["A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-", "B", "A"]
    // Store a list of predefined hospitals for the user to select from, with the option to add custom ones
    @State private var hospitals: [String] = ["Central Hospital", "Memorial Medical Center", "St. Mary's Hospital", "City General Hospital"]
    
    // Define the main UI structure of the view
    var body: some View {
        // Use NavigationView to provide a navigation bar and support toolbar items
        NavigationView {
            // Use ZStack to layer the background color and content
            ZStack {
                // Set a cream-colored background that extends to all edges, ignoring safe areas
                cream.ignoresSafeArea()
                
                // Arrange content vertically with no spacing between top header and main content
                VStack(spacing: 0) {
                    // Create a header section to display the app's branding and purpose
                    VStack(spacing: 8) {
                        // Display a blood drop icon to visually represent blood donation
                        Image(systemName: "drop.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 40, height: 40)
                            .foregroundColor(.white)
                        
                        // Display the title of the form to indicate its purpose
                        Text("Log Your Donation")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        // Show a thank-you message to encourage and appreciate the user
                        Text("Thank you for saving lives!")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    // Ensure header spans the full width
                    .frame(maxWidth: .infinity)
                    // Add vertical padding for better spacing
                    .padding(.vertical, 25)
                    // Apply a gradient background transitioning from deep red to a lighter shade
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [deepRed, deepRed.opacity(0.8)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    
                    // Conditionally display content based on loading state
                    if showLoading {
                        // Show a loading indicator while checking donation limits or submitting data
                        Spacer()
                        ProgressView("Checking your donations...")
                            .padding()
                        Spacer()
                    } else {
                        // Display the main form content in a scrollable view
                        ScrollView {
                            // Arrange form sections vertically with spacing
                            VStack(spacing: 20) {
                                // If donation limit is reached, show a warning message
                                if donationLimitReached {
                                    // Display a section to inform the user they cannot donate again this year
                                    VStack(spacing: 10) {
                                        // Show a warning triangle icon to draw attention
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 40, height: 40)
                                            .foregroundColor(deepRed)
                                        // Display a clear message about the donation limit
                                        Text("Donation Limit Reached")
                                            .font(.headline)
                                            .foregroundColor(deepRed)
                                        // Show the time remaining until the user can donate again
                                        Text(remainingTimeMessage)
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal)
                                    }
                                    // Add vertical padding for better presentation
                                    .padding(.vertical, 20)
                                } else {
                                    // Display the donation date selection section
                                    formSection(title: "When did you donate?", iconName: "calendar") {
                                        // Provide a date picker to select the donation date
                                        DatePicker("Donation Date", selection: $date, in: ...Date(), displayedComponents: .date)
                                            .datePickerStyle(.graphical)
                                            .tint(deepRed)
                                            .padding(.horizontal)
                                            .padding(.bottom, 10)
                                    }
                                    
                                    // Display the hospital selection section
                                    formSection(title: "Where did you donate?", iconName: "building.2") {
                                        // Allow user to select a hospital from a predefined list
                                        Picker("Select Hospital", selection: $hospital) {
                                            Text("Select a hospital").tag("")
                                            ForEach(hospitals, id: \.self) { hospital in
                                                Text(hospital).tag(hospital)
                                            }
                                        }
                                        .pickerStyle(.wheel)
                                        .frame(height: 100)
                                        .padding(.horizontal)
                                        
                                        // Provide an option to enter a custom hospital name
                                        HStack {
                                            // Show a plus icon to indicate adding a new hospital
                                            Image(systemName: "plus.circle.fill")
                                                .foregroundColor(deepRed)
                                            // Allow user to type a hospital name
                                            TextField("Or enter a hospital name", text: $hospital)
                                                .padding()
                                                .background(Color.white)
                                                .cornerRadius(10)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 10)
                                                        .stroke(deepRed.opacity(0.3), lineWidth: 1)
                                                )
                                        }
                                        .padding(.horizontal)
                                        .padding(.bottom, 10)
                                    }
                                    
                                    // Display the blood type selection section
                                    formSection(title: "What's your blood type?", iconName: "drop.fill") {
                                        // Allow user to select a blood type from valid options
                                        Picker("Blood Type", selection: $bloodType) {
                                            Text("Select Blood Type").tag("")
                                            ForEach(validBloodTypes, id: \.self) { type in
                                                Text(type).tag(type)
                                            }
                                        }
                                        .pickerStyle(.segmented)
                                        .padding(.horizontal)
                                        .padding(.bottom, 10)
                                    }
                                    
                                    // Provide a button to submit the donation form
                                    Button(action: {
                                        // Trigger an asynchronous task to submit the donation data
                                        Task {
                                            await submitDonation()
                                        }
                                    }) {
                                        // Display the submit button with dynamic styling
                                        Text("Submit Donation")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(isFormValid ? deepRed : deepRed.opacity(0.4))
                                            .cornerRadius(12)
                                            .padding(.horizontal)
                                    }
                                    // Disable the button if the form is not valid
                                    .disabled(!isFormValid)
                                    .padding(.vertical)
                                }
                            }
                            // Add vertical padding to the form content
                            .padding(.vertical)
                        }
                    }
                }
            }
            // Set navigation bar title to display inline
            .navigationBarTitleDisplayMode(.inline)
            // Add a toolbar with a cancel button
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        // Dismiss the view when the cancel button is tapped
                        dismiss()
                    }
                    .foregroundColor(deepRed)
                }
            }
            // Show an alert with a message when triggered
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Message"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            // Automatically check the donation limit when the view appears
            .onAppear {
                Task {
                    await checkDonationLimit()
                }
            }
        }
    }
    
    // Define a reusable function to create styled form sections for date, hospital, and blood type inputs
    private func formSection<Content: View>(title: String, iconName: String, @ViewBuilder content: () -> Content) -> some View {
        // Arrange section content vertically with leading alignment
        VStack(alignment: .leading, spacing: 10) {
            // Display a header with an icon and title for the section
            HStack {
                Image(systemName: iconName)
                    .foregroundColor(deepRed)
                Text(title)
                    .font(.headline)
                    .foregroundColor(deepRed)
            }
            .padding(.horizontal)
            // Include the provided content (e.g., date picker, hospital picker)
            content()
        }
        // Style the section with padding, background, corner radius, and shadow
        .padding(.vertical, 10)
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
    
    // Computed property to validate the form inputs
    private var isFormValid: Bool {
        // Ensure hospital and blood type are non-empty, blood type is valid, and date is not in the future
        !hospital.isEmpty && !bloodType.isEmpty && validBloodTypes.contains(bloodType) && date <= Date()
    }
    
    // Asynchronous function to check if the user has reached the donation limit (4 per year)
    private func checkDonationLimit() async {
        // Verify that the user is authenticated before proceeding
        guard let userId = authManager.user?.id else {
            print("No user ID found")
            alertMessage = "User not authenticated. Please log in."
            showAlert = true
            donationLimitReached = true
            return
        }
        
        // Calculate the date range for the current year to query donations
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        guard let startOfYear = calendar.date(from: DateComponents(year: currentYear, month: 1, day: 1)),
              let endOfYear = calendar.date(from: DateComponents(year: currentYear, month: 12, day: 31, hour: 23, minute: 59, second: 59)),
              let nextYearStart = calendar.date(from: DateComponents(year: currentYear + 1, month: 1, day: 1)) else {
            print("Failed to calculate year range for \(currentYear)")
            alertMessage = "Error checking donation limit. Please try again later."
            showAlert = true
            donationLimitReached = true
            return
        }
        
        do {
            // Query Firestore for approved donations made by the user in the current year
            let snapshot = try await db.collection("donations")
                .whereField("donorId", isEqualTo: userId)
                .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: startOfYear))
                .whereField("date", isLessThanOrEqualTo: Timestamp(date: endOfYear))
                .whereFilter(Filter.orFilter([
                    Filter.whereField("status", isEqualTo: "approved"),
                    Filter.whereField("status", isEqualTo: "used")
                ]))
                .getDocuments()
            
            // Determine if the donation limit has been reached
            let approvedCount = snapshot.documents.count
            donationLimitReached = approvedCount >= 4
            
            // If the limit is reached, calculate and display the time until the next year
            if donationLimitReached {
                let components = calendar.dateComponents([.month, .day, .hour, .minute], from: Date(), to: nextYearStart)
                let months = components.month ?? 0
                let days = components.day ?? 0
                let hours = components.hour ?? 0
                let minutes = components.minute ?? 0
                
                // Build a message detailing the remaining time until the user can donate again
                var timeComponents: [String] = []
                if months > 0 { timeComponents.append("\(months) month\(months == 1 ? "" : "s")") }
                if days > 0 { timeComponents.append("\(days) day\(days == 1 ? "" : "s")") }
                if hours > 0 { timeComponents.append("\(hours) hour\(hours == 1 ? "" : "s")") }
                if minutes > 0 { timeComponents.append("\(minutes) minute\(minutes == 1 ? "" : "s")") }
                
                let timeRemaining = timeComponents.isEmpty ? "less than a minute" : timeComponents.joined(separator: ", ")
                remainingTimeMessage = "You have donated 4 times in \(currentYear). You can donate again in \(timeRemaining) on January 1st, \(currentYear + 1)."
            } else {
                // Clear the message if the limit is not reached
                remainingTimeMessage = ""
            }
            
            // Log the result of the donation limit check for debugging
            print("Checked donation limit: \(approvedCount) approved donations in \(currentYear), limit reached: \(donationLimitReached)")
        } catch {
            // Handle errors during the Firestore query
            print("Error checking donation limit: \(error.localizedDescription)")
            alertMessage = "Failed to check donation limit: \(error.localizedDescription)"
            showAlert = true
            donationLimitReached = true
        }
    }
    
    // Asynchronous function to submit the donation data to Firestore
    private func submitDonation() async {
        // Validate the form inputs before attempting to submit
        guard isFormValid else {
            alertMessage = "Please fill all fields correctly. Ensure hospital is not empty, blood type is valid, and the date is not in the future."
            showAlert = true
            return
        }
        
        // Display a loading indicator during the submission process
        showLoading = true
        
        do {
            // Re-check the donation limit to ensure compliance
            await checkDonationLimit()
            if donationLimitReached {
                alertMessage = remainingTimeMessage
                showAlert = true
                showLoading = false
                return
            }
            
            // Verify user authentication before submission
            guard let userId = authManager.user?.id else {
                alertMessage = "User not authenticated. Please log in."
                showAlert = true
                showLoading = false
                return
            }
            
            // Create a Donation object with the form data
            let donation = Donation(
                id: UUID().uuidString,
                donorId: userId,
                hospital: hospital,
                bloodType: bloodType,
                date: date,
                status: "pending"
            )
            
            // Prepare the donation data as a dictionary for Firestore
            let donationData: [String: Any] = [
                "id": donation.id,
                "donorId": donation.donorId,
                "date": Timestamp(date: donation.date),
                "hospital": donation.hospital,
                "bloodType": donation.bloodType,
                "status": donation.status
            ]
            
            // Log the submission attempt for debugging
            print("Submitting donation for user \(userId): \(donationData)")
            // Save the donation data to the Firestore "donations" collection
            try await db.collection("donations").document(donation.id).setData(donationData)
            
            // Show a success message and dismiss the view after a short delay
            alertMessage = "Donation submitted successfully! It will be reviewed by an admin."
            showAlert = true
            showLoading = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                dismiss()
            }
        } catch {
            // Handle errors during submission and display an error message
            print("Failed to submit donation: \(error.localizedDescription)")
            alertMessage = "Failed to submit donation: \(error.localizedDescription)"
            showAlert = true
            showLoading = false
        }
    }
}

// Provide a preview of the DonationFormView for SwiftUI's canvas
#Preview {
    DonationFormView(authManager: AuthManager())
}


































































































/*import SwiftUI
import FirebaseFirestore

struct DonationFormView: View {
    @ObservedObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss
    @State private var date = Date()
    @State private var hospital = ""
    @State private var bloodType = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showLoading = false
    @State private var donationLimitReached = false
    @State private var remainingTimeMessage = ""
    private let db = Firestore.firestore()
    
    private let deepRed = Color(red: 0.7, green: 0.1, blue: 0.1)
    private let cream = Color(red: 0.98, green: 0.96, blue: 0.9)
    private let validBloodTypes = ["A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-", "B", "A"]
    @State private var hospitals: [String] = ["Central Hospital", "Memorial Medical Center", "St. Mary's Hospital", "City General Hospital"]
    
    var body: some View {
        NavigationView {
            ZStack {
                cream.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    VStack(spacing: 8) {
                        Image(systemName: "drop.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 40, height: 40)
                            .foregroundColor(.white)
                        
                        Text("Log Your Donation")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Thank you for saving lives!")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 25)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [deepRed, deepRed.opacity(0.8)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    
                    if showLoading {
                        Spacer()
                        ProgressView("Checking your donations...")
                            .padding()
                        Spacer()
                    } else {
                        ScrollView {
                            VStack(spacing: 20) {
                                if donationLimitReached {
                                    VStack(spacing: 10) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 40, height: 40)
                                            .foregroundColor(deepRed)
                                        Text("Donation Limit Reached")
                                            .font(.headline)
                                            .foregroundColor(deepRed)
                                        Text(remainingTimeMessage)
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal)
                                    }
                                    .padding(.vertical, 20)
                                } else {
                                    formSection(title: "When did you donate?", iconName: "calendar") {
                                        DatePicker("Donation Date", selection: $date, in: ...Date(), displayedComponents: .date)
                                            .datePickerStyle(.graphical)
                                            .tint(deepRed)
                                            .padding(.horizontal)
                                            .padding(.bottom, 10)
                                    }
                                    
                                    formSection(title: "Where did you donate?", iconName: "building.2") {
                                        Picker("Select Hospital", selection: $hospital) {
                                            Text("Select a hospital").tag("")
                                            ForEach(hospitals, id: \.self) { hospital in
                                                Text(hospital).tag(hospital)
                                            }
                                        }
                                        .pickerStyle(.wheel)
                                        .frame(height: 100)
                                        .padding(.horizontal)
                                        
                                        HStack {
                                            Image(systemName: "plus.circle.fill")
                                                .foregroundColor(deepRed)
                                            TextField("Or enter a hospital name", text: $hospital)
                                                .padding()
                                                .background(Color.white)
                                                .cornerRadius(10)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 10)
                                                        .stroke(deepRed.opacity(0.3), lineWidth: 1)
                                                )
                                        }
                                        .padding(.horizontal)
                                        .padding(.bottom, 10)
                                    }
                                    
                                    formSection(title: "What's your blood type?", iconName: "drop.fill") {
                                        Picker("Blood Type", selection: $bloodType) {
                                            Text("Select Blood Type").tag("")
                                            ForEach(validBloodTypes, id: \.self) { type in
                                                Text(type).tag(type)
                                            }
                                        }
                                        .pickerStyle(.segmented)
                                        .padding(.horizontal)
                                        .padding(.bottom, 10)
                                    }
                                    
                                    Button(action: {
                                        Task {
                                            await submitDonation()
                                        }
                                    }) {
                                        Text("Submit Donation")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(isFormValid ? deepRed : deepRed.opacity(0.4))
                                            .cornerRadius(12)
                                            .padding(.horizontal)
                                    }
                                    .disabled(!isFormValid)
                                    .padding(.vertical)
                                }
                            }
                            .padding(.vertical)
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(deepRed)
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Message"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .onAppear {
                Task {
                    await checkDonationLimit()
                }
            }
        }
    }
    
    private func formSection<Content: View>(title: String, iconName: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: iconName)
                    .foregroundColor(deepRed)
                Text(title)
                    .font(.headline)
                    .foregroundColor(deepRed)
            }
            .padding(.horizontal)
            content()
        }
        .padding(.vertical, 10)
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
    
    private var isFormValid: Bool {
        !hospital.isEmpty && !bloodType.isEmpty && validBloodTypes.contains(bloodType) && date <= Date()
    }
    
    private func checkDonationLimit() async {
        guard let userId = authManager.user?.id else {
            print("No user ID found")
            alertMessage = "User not authenticated. Please log in."
            showAlert = true
            donationLimitReached = true
            return
        }
        
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        guard let startOfYear = calendar.date(from: DateComponents(year: currentYear, month: 1, day: 1)),
              let endOfYear = calendar.date(from: DateComponents(year: currentYear, month: 12, day: 31, hour: 23, minute: 59, second: 59)),
              let nextYearStart = calendar.date(from: DateComponents(year: currentYear + 1, month: 1, day: 1)) else {
            print("Failed to calculate year range for \(currentYear)")
            alertMessage = "Error checking donation limit. Please try again later."
            showAlert = true
            donationLimitReached = true
            return
        }
        
        do {
            let snapshot = try await db.collection("donations")
                .whereField("donorId", isEqualTo: userId)
                .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: startOfYear))
                .whereField("date", isLessThanOrEqualTo: Timestamp(date: endOfYear))
                .whereField("status", isEqualTo: "approved")
                .getDocuments()
            
            let approvedCount = snapshot.documents.count
            donationLimitReached = approvedCount >= 4
            
            if donationLimitReached {
                let components = calendar.dateComponents([.month, .day, .hour, .minute], from: Date(), to: nextYearStart)
                let months = components.month ?? 0
                let days = components.day ?? 0
                let hours = components.hour ?? 0
                let minutes = components.minute ?? 0
                
                var timeComponents: [String] = []
                if months > 0 { timeComponents.append("\(months) month\(months == 1 ? "" : "s")") }
                if days > 0 { timeComponents.append("\(days) day\(days == 1 ? "" : "s")") }
                if hours > 0 { timeComponents.append("\(hours) hour\(hours == 1 ? "" : "s")") }
                if minutes > 0 { timeComponents.append("\(minutes) minute\(minutes == 1 ? "" : "s")") }
                
                let timeRemaining = timeComponents.isEmpty ? "less than a minute" : timeComponents.joined(separator: ", ")
                remainingTimeMessage = "You have donated 4 times in \(currentYear). You can donate again in \(timeRemaining) on January 1st, \(currentYear + 1)."
            } else {
                remainingTimeMessage = ""
            }
            
            print("Checked donation limit: \(approvedCount) approved donations in \(currentYear), limit reached: \(donationLimitReached)")
        } catch {
            print("Error checking donation limit: \(error.localizedDescription)")
            alertMessage = "Failed to check donation limit: \(error.localizedDescription)"
            showAlert = true
            donationLimitReached = true
        }
    }
    
    private func submitDonation() async {
        guard isFormValid else {
            alertMessage = "Please fill all fields correctly. Ensure hospital is not empty, blood type is valid, and the date is not in the future."
            showAlert = true
            return
        }
        
        showLoading = true
        
        do {
            await checkDonationLimit()
            if donationLimitReached {
                alertMessage = remainingTimeMessage
                showAlert = true
                showLoading = false
                return
            }
            
            guard let userId = authManager.user?.id else {
                alertMessage = "User not authenticated. Please log in."
                showAlert = true
                showLoading = false
                return
            }
            
            let donation = Donation(
                id: UUID().uuidString,
                donorId: userId,
                hospital: hospital,
                bloodType: bloodType,
                date: date,
                status: "pending"
            )
            
            let donationData: [String: Any] = [
                "id": donation.id,
                "donorId": donation.donorId,
                "date": Timestamp(date: donation.date),
                "hospital": donation.hospital,
                "bloodType": donation.bloodType,
                "status": donation.status
            ]
            
            print("Submitting donation for user \(userId): \(donationData)")
            try await db.collection("donations").document(donation.id).setData(donationData)
            
            alertMessage = "Donation submitted successfully! It will be reviewed by an admin."
            showAlert = true
            showLoading = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                dismiss()
            }
        } catch {
            print("Failed to submit donation: \(error.localizedDescription)")
            alertMessage = "Failed to submit donation: \(error.localizedDescription)"
            showAlert = true
            showLoading = false
        }
    }
}

#Preview {
    DonationFormView(authManager: AuthManager())
}*/







/*import SwiftUI
import FirebaseFirestore

struct DonationFormView: View {
    @ObservedObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss
    @State private var date = Date()
    @State private var hospital = ""
    @State private var bloodType = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    private let db = Firestore.firestore()

    // App theme colors
    private let deepRed = Color(red: 0.7, green: 0.1, blue: 0.1)
    private let cream = Color(red: 0.98, green: 0.96, blue: 0.9)

    // List of valid blood types
    private let validBloodTypes = ["A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-", "B", "A"]

    // List of hospitals (would typically come from a database)
    @State private var hospitals: [String] = ["Central Hospital", "Memorial Medical Center", "St. Mary's Hospital", "City General Hospital"]

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                cream.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "drop.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 40, height: 40)
                            .foregroundColor(.white)

                        Text("Log Your Donation")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)

                        Text("Thank you for saving lives!")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 25)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [deepRed, deepRed.opacity(0.8)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                    // Form
                    ScrollView {
                        VStack(spacing: 20) {
                            // Date Picker
                            formSection(title: "When did you donate?", iconName: "calendar") {
                                DatePicker("Donation Date", selection: $date, displayedComponents: .date)
                                    .datePickerStyle(.graphical)
                                    .tint(deepRed)
                                    .padding(.horizontal)
                                    .padding(.bottom, 10)
                            }

                            // Hospital Picker
                            formSection(title: "Where did you donate?", iconName: "building.2") {
                                Picker("Select Hospital", selection: $hospital) {
                                    Text("Select a hospital").tag("")
                                    ForEach(hospitals, id: \.self) { hospital in
                                        Text(hospital).tag(hospital)
                                    }
                                }
                                .pickerStyle(.wheel)
                                .frame(height: 100)
                                .padding(.horizontal)

                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(deepRed)
                                    TextField("Or enter a hospital name", text: $hospital)
                                        .padding()
                                        .background(Color.white)
                                        .cornerRadius(10)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(deepRed.opacity(0.3), lineWidth: 1)
                                        )
                                }
                                .padding(.horizontal)
                                .padding(.bottom, 10)
                            }

                            // Blood Type Picker
                            formSection(title: "What's your blood type?", iconName: "drop.fill") {
                                Picker("Blood Type", selection: $bloodType) {
                                    Text("Select Blood Type").tag("")
                                    ForEach(validBloodTypes, id: \.self) { type in
                                        Text(type).tag(type)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .padding(.horizontal)
                                .padding(.bottom, 10)
                            }

                            // Submit Button
                            Button(action: {
                                submitDonation()
                            }) {
                                Text("Submit Donation")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(isFormValid ? deepRed : deepRed.opacity(0.4))
                                    .cornerRadius(12)
                                    .padding(.horizontal)
                            }
                            .disabled(!isFormValid)
                            .padding(.vertical)
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(deepRed)
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Message"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }

    private func formSection<Content: View>(title: String, iconName: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: iconName)
                    .foregroundColor(deepRed)

                Text(title)
                    .font(.headline)
                    .foregroundColor(deepRed)
            }
            .padding(.horizontal)

            content()
        }
        .padding(.vertical, 10)
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }

    // Form validation
    private var isFormValid: Bool {
        !hospital.isEmpty && !bloodType.isEmpty && validBloodTypes.contains(bloodType) && date <= Date()
    }

    private func canSubmitDonation(completion: @escaping (Bool) -> Void) {
        guard let userId = authManager.user?.id else {
            print("No user ID found. Cannot check donation limit.")
            completion(false)
            return
        }

        let calendar = Calendar.current
        let currentDate = Date()

        // Calculate start and end of the current year (2025)
        guard let startOfYear = calendar.date(from: calendar.dateComponents([.year], from: currentDate)),
              let endOfYear = calendar.date(byAdding: .year, value: 1, to: startOfYear) else {
            print("Failed to calculate year range.")
            completion(false)
            return
        }

        print("Checking donations for user: \(userId)")
        print("Year range: \(startOfYear) to \(endOfYear)")

        db.collection("donations")
            .whereField("donorId", isEqualTo: userId)
            .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: startOfYear))
            .whereField("date", isLessThan: Timestamp(date: endOfYear))
            .whereField("status", isEqualTo: "approved")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error checking donation limit: \(error)")
                    completion(false)
                    return
                }

                let count = snapshot?.documents.count ?? 0

                // Enhanced: Log detailed information about each donation
                if let documents = snapshot?.documents {
                    for doc in documents {
                        let data = doc.data()
                        if let donationDate = (data["date"] as? Timestamp)?.dateValue(),
                           let status = data["status"] as? String,
                           let donorId = data["donorId"] as? String {
                            print("Found donation - ID: \(doc.documentID), Donor: \(donorId), Date: \(donationDate), Status: \(status)")
                        } else {
                            print("Invalid donation data in document: \(doc.documentID)")
                        }
                    }
                }

                print("Approved donations in 2025: \(count)")
                if count >= 4 {
                    print("Donation limit reached. Cannot submit more donations this year.")
                } else {
                    print("Can submit donation. Current count: \(count)")
                }

                completion(count < 4)
            }
    }

    private func submitDonation() {
        guard isFormValid else {
            alertMessage = "Please fill all fields correctly. Ensure hospital is not empty, blood type is valid, and the date is not in the future."
            showAlert = true
            return
        }

        canSubmitDonation { canSubmit in
            if !canSubmit {
                alertMessage = "You have already donated 4 times this year. Please wait until next year."
                showAlert = true
                return
            }

            guard let userId = authManager.user?.id else {
                alertMessage = "User not authenticated."
                showAlert = true
                return
            }

            let donation = Donation(
                id: UUID().uuidString,
                donorId: userId,
                date: date,
                hospital: hospital,
                bloodType: bloodType,
                status: "pending"
            )

            do {
                let data = try JSONEncoder().encode(donation)
                let dictionary = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
                print("Submitting donation: \(dictionary)")

                db.collection("donations").document(donation.id).setData(dictionary) { error in
                    if let error = error {
                        print("Failed to submit donation: \(error)")
                        alertMessage = "Failed to submit donation: \(error.localizedDescription)"
                        showAlert = true
                        return
                    }

                    print("Donation submitted successfully!")
                    alertMessage = "Donation submitted successfully!"
                    showAlert = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        dismiss()
                    }
                }
            } catch {
                print("Failed to encode donation: \(error)")
                alertMessage = "Failed to encode donation: \(error.localizedDescription)"
                showAlert = true
            }
        }
    }
}

#Preview {
    DonationFormView(authManager: AuthManager())
}*/

/*import SwiftUI
import FirebaseFirestore

struct DonationFormView: View {
    @ObservedObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss
    @State private var date = Date()
    @State private var hospital = ""
    @State private var bloodType = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    private let db = Firestore.firestore()
    // Added: List of valid blood types
    private let validBloodTypes = ["A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-","B","A"]

    var body: some View {
        NavigationView {
            Form {
                DatePicker("Donation Date", selection: $date, displayedComponents: .date)
                    .padding(.vertical, 5)
                TextField("Hospital", text: $hospital)
                    .textFieldStyle(.roundedBorder)
                    .padding(.vertical, 5)
                Picker("Blood Type", selection: $bloodType) {
                    Text("Select Blood Type").tag("")
                    ForEach(validBloodTypes, id: \.self) { type in
                        Text(type).tag(type)
                    }
                }
                .pickerStyle(.menu)
                .padding(.vertical, 5)
            }
            .navigationTitle("Log Donation")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Submit") {
                        submitDonation()
                    }
                    .disabled(!isFormValid)
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Message"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }

    // Modified: Updated form validation to include blood type
    private var isFormValid: Bool {
        !hospital.isEmpty && !bloodType.isEmpty && validBloodTypes.contains(bloodType) && date <= Date()
    }

    private func canSubmitDonation(completion: @escaping (Bool) -> Void) {
        guard let userId = authManager.user?.id else {
            print("No user ID found. Cannot check donation limit.")
            completion(false)
            return
        }
        let calendar = Calendar.current
        let currentDate = Date()
        // Calculate start and end of the current year (2025)
        guard let startOfYear = calendar.date(from: calendar.dateComponents([.year], from: currentDate)),
              let endOfYear = calendar.date(byAdding: .year, value: 1, to: startOfYear) else {
            print("Failed to calculate year range.")
            completion(false)
            return
        }
        print("Checking donations for user: \(userId)")
        print("Year range: \(startOfYear) to \(endOfYear)")
        db.collection("donations")
            .whereField("donorId", isEqualTo: userId)
            .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: startOfYear))
            .whereField("date", isLessThan: Timestamp(date: endOfYear))
            .whereField("status", isEqualTo: "approved")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error checking donation limit: \(error)")
                    completion(false)
                    return
                }
                let count = snapshot?.documents.count ?? 0
                // Enhanced: Log detailed information about each donation
                if let documents = snapshot?.documents {
                    for doc in documents {
                        let data = doc.data()
                        if let donationDate = (data["date"] as? Timestamp)?.dateValue(),
                           let status = data["status"] as? String,
                           let donorId = data["donorId"] as? String {
                            print("Found donation - ID: \(doc.documentID), Donor: \(donorId), Date: \(donationDate), Status: \(status)")
                        } else {
                            print("Invalid donation data in document: \(doc.documentID)")
                        }
                    }
                }
                print("Approved donations in 2025: \(count)")
                if count >= 4 {
                    print("Donation limit reached. Cannot submit more donations this year.")
                } else {
                    print("Can submit donation. Current count: \(count)")
                }
                completion(count < 4)
            }
    }

    private func submitDonation() {
        guard isFormValid else {
            alertMessage = "Please fill all fields correctly. Ensure hospital is not empty, blood type is valid, and the date is not in the future."
            showAlert = true
            return
        }

        canSubmitDonation { canSubmit in
            if !canSubmit {
                alertMessage = "You have already donated 4 times this year. Please wait until next year."
                showAlert = true
                return
            }
            guard let userId = authManager.user?.id else {
                alertMessage = "User not authenticated."
                showAlert = true
                return
            }
            let donation = Donation(
                id: UUID().uuidString,
                donorId: userId,
                date: date,
                hospital: hospital,
                bloodType: bloodType,
                status: "pending"
            )
            do {
                let data = try JSONEncoder().encode(donation)
                let dictionary = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
                print("Submitting donation: \(dictionary)")
                db.collection("donations").document(donation.id).setData(dictionary) { error in
                    if let error = error {
                        print("Failed to submit donation: \(error)")
                        alertMessage = "Failed to submit donation: \(error.localizedDescription)"
                        showAlert = true
                        return
                    }
                    print("Donation submitted successfully!")
                    alertMessage = "Donation submitted successfully!"
                    showAlert = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        dismiss()
                    }
                }
            } catch {
                print("Failed to encode donation: \(error)")
                alertMessage = "Failed to encode donation: \(error.localizedDescription)"
                showAlert = true
            }
        }
    }
}

#Preview {
    DonationFormView(authManager: AuthManager())
}*/
