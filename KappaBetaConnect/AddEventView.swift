import SwiftUI

struct AddEventView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var eventRepository: EventRepository
    @ObservedObject var userRepository: UserRepository
    
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
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // Date and Time
                    VStack(alignment: .leading) {
                        Text("Date and Time")
                            .foregroundColor(.gray)
                        DatePicker("", selection: $eventDate)
                            .datePickerStyle(.graphical)
                    }
                    
                    // Location
                    VStack(alignment: .leading) {
                        Text("Location")
                            .foregroundColor(.gray)
                        TextField("Enter location", text: $location)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // Event Link
                    VStack(alignment: .leading) {
                        Text("Event Link")
                            .foregroundColor(.gray)
                        TextField("Enter event link", text: $eventLink)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                    }
                    
                    // Description
                    VStack(alignment: .leading) {
                        Text("Description")
                            .foregroundColor(.gray)
                        TextEditor(text: $description)
                            .frame(height: 100)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                    }
                    
                    // Hashtags
                    VStack(alignment: .leading) {
                        Text("Hashtags")
                            .foregroundColor(.gray)
                        TextField("Enter hashtags (separated by spaces)", text: $hashtags)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
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
        guard let userId = userRepository.currentUser?.id else {
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
                createdBy: userId
            )
            dismiss()
        } catch {
            showError = true
            errorMessage = error.localizedDescription
        }
    }
} 