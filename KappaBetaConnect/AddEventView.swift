import SwiftUI

struct AddEventView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var eventRepository: EventRepository
    @ObservedObject var userRepository: UserRepository
    @EnvironmentObject private var authManager: AuthManager
    
    @State private var eventName = ""
    @State private var eventDate = Date()
    @State private var location = ""
    @State private var eventLink = ""
    @State private var description = ""
    @State private var hashtags = ""
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Event Name
                    VStack(alignment: .leading) {
                        Text("Event Name")
                            .foregroundColor(.gray)
                        TextField("Enter event name", text: $eventName)
                            .customTextField()
                    }
                    
                    // Date and Time
                    VStack(alignment: .leading) {
                        Text("Date and Time")
                            .foregroundColor(.gray)
                        DatePicker("", selection: $eventDate)
                            .datePickerStyle(.graphical)
                            .tint(.primary)
                    }
                    
                    // Location
                    VStack(alignment: .leading) {
                        Text("Location")
                            .foregroundColor(.gray)
                        TextField("Enter location", text: $location)
                            .customTextField()
                    }
                    
                    // Event Link
                    VStack(alignment: .leading) {
                        Text("Event Link")
                            .foregroundColor(.gray)
                        TextField("Enter event link", text: $eventLink)
                            .customTextField()
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                    }
                    
                    // Description
                    VStack(alignment: .leading) {
                        Text("Description")
                            .foregroundColor(.gray)
                        CustomTextEditor(text: $description, placeholder: "Enter event description")
                            .customTextEditor()
                    }
                    
                    // Hashtags
                    VStack(alignment: .leading) {
                        Text("Hashtags")
                            .foregroundColor(.gray)
                        TextField("Enter hashtags (separated by spaces)", text: $hashtags)
                            .customTextField()
                    }
                    
                    // Create Event Button
                    Button(action: {
                        Task {
                            await createEvent()
                        }
                    }) {
                        Text("Create Event")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.black)
                            .cornerRadius(10)
                    }
                    .disabled(eventName.isEmpty || location.isEmpty)
                }
                .padding()
            }
            .navigationTitle("Create Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.primary)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func createEvent() async {
        guard let userId = authManager.currentUser?.id else {
            showError = true
            errorMessage = "User not logged in"
            return
        }
        
        do {
            try await eventRepository.createEvent(
                title: eventName,
                description: description,
                date: eventDate,
                location: location,
                eventLink: eventLink.isEmpty ? nil : eventLink,
                hashtags: hashtags.isEmpty ? nil : hashtags,
                createdBy: userId
            )
            dismiss()
        } catch {
            showError = true
            errorMessage = error.localizedDescription
        }
    }
} 