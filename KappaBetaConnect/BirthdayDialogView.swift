import SwiftUI
import UIKit

struct BirthdayDialogView: View {
    @ObservedObject var userRepository: UserRepository
    @EnvironmentObject private var birthdayService: BirthdayService
    @State private var birthdayUsers: [User] = []
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.2)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation {
                        birthdayService.shouldShowBirthdayDialog = false
                    }
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
                                    
                                    VStack(alignment: .leading) {
                                        Text("\(user.firstName) \(user.lastName)")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        
                                        if let city = user.city, let state = user.state {
                                            Text("\(city), \(state)")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        let phoneNumber = user.phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
                                        if !phoneNumber.isEmpty {
                                            let message = "Happy Birthday \(user.firstName)! 🎉🎂"
                                            let urlString = "sms:\(phoneNumber)&body=\(message)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                                            if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
                                                UIApplication.shared.open(url)
                                            }
                                        }
                                    }) {
                                        Image(systemName: "gift.fill")
                                            .foregroundColor(.orange)
                                            .font(.title3)
                                    }
                                    .padding(8)
                                    .disabled(user.phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                                }
                                .padding(.horizontal, 24)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .frame(maxHeight: 250)
                }
                
                // Footer
                Button(action: { 
                    withAnimation {
                        birthdayService.shouldShowBirthdayDialog = false
                    }
                }) {
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
            .frame(maxWidth: 320)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(radius: 20, x: 0, y: 10)
        }
        .task {
            await fetchBirthdayUsers()
        }
    }
    
    private func fetchBirthdayUsers() async {
        do {
            let users = try await userRepository.getAllUsers()
            let today = Calendar.current.startOfDay(for: Date())
            
            let todaysBirthdays = users.filter { user in
                let userBirthday = Calendar.current.startOfDay(for: user.birthday)
                return Calendar.current.component(.month, from: userBirthday) == Calendar.current.component(.month, from: today) &&
                       Calendar.current.component(.day, from: userBirthday) == Calendar.current.component(.day, from: today)
            }
            
            await MainActor.run {
                birthdayUsers = todaysBirthdays
                isLoading = false
            }
        } catch {
            print("Error fetching birthday users: \(error)")
            await MainActor.run {
                birthdayUsers = []
                isLoading = false
            }
        }
    }
} 