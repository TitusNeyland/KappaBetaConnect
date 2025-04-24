import SwiftUI

struct BirthdayDialogView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var userRepository: UserRepository
    @State private var birthdayUsers: [User] = []
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.2)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }
            
            // Dialog content
            VStack(spacing: 20) {
                // Header
                HStack {
                    Image(systemName: "gift.fill")
                        .foregroundColor(.orange)
                        .font(.title2)
                    Text("Birthdays Today")
                        .font(.headline)
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                            .font(.title3)
                    }
                }
                .padding(.top, 20)
                .padding(.horizontal, 24)
                
                if isLoading {
                    ProgressView()
                        .padding()
                } else if birthdayUsers.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "gift.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.orange)
                        
                        Text("No birthdays today")
                            .font(.headline)
                        
                        Text("Check back tomorrow!")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 32)
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(birthdayUsers) { user in
                                HStack(spacing: 16) {
                                    if let profileImageURL = user.profileImageURL,
                                       let url = URL(string: profileImageURL) {
                                        AsyncImage(url: url) { image in
                                            image
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 48, height: 48)
                                                .clipShape(Circle())
                                        } placeholder: {
                                            Circle()
                                                .fill(Color.gray.opacity(0.3))
                                                .frame(width: 48, height: 48)
                                                .overlay(
                                                    Image(systemName: "person.fill")
                                                        .foregroundColor(.gray)
                                                )
                                        }
                                    } else {
                                        Circle()
                                            .fill(Color.gray.opacity(0.3))
                                            .frame(width: 48, height: 48)
                                            .overlay(
                                                Image(systemName: "person.fill")
                                                    .foregroundColor(.gray)
                                            )
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("\(user.firstName) \(user.lastName)")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        
                                        if let lineNumber = user.lineNumber {
                                            Text("Line #\(lineNumber)")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        // TODO: Implement birthday wish functionality
                                    }) {
                                        Image(systemName: "gift.fill")
                                            .foregroundColor(.orange)
                                            .font(.title3)
                                    }
                                    .padding(8)
                                }
                                .padding(.horizontal, 24)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .frame(maxHeight: 250) // Increased scrollable area height
                }
                
                // Footer
                Button(action: { dismiss() }) {
                    Text("Close")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
            .frame(maxWidth: 320) // Slightly increased max width
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(radius: 20, x: 0, y: 10)
        }
        .onAppear {
            fetchBirthdayUsers()
        }
    }
    
    private func fetchBirthdayUsers() {
        Task {
            do {
                let users = try await userRepository.getAllUsers()
                let today = Calendar.current.startOfDay(for: Date())
                
                birthdayUsers = users.filter { user in
                    let userBirthday = Calendar.current.startOfDay(for: user.birthday)
                    return Calendar.current.component(.day, from: userBirthday) == Calendar.current.component(.day, from: today) &&
                           Calendar.current.component(.month, from: userBirthday) == Calendar.current.component(.month, from: today)
                }
                
                isLoading = false
            } catch {
                print("Error fetching birthday users: \(error)")
                isLoading = false
            }
        }
    }
} 