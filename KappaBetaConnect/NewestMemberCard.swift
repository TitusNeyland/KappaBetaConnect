import SwiftUI

struct NewestMemberCard: View {
    let member: LineMember
    let userRepository: UserRepository
    let lineRepository: LineRepository
    @State private var matchingUser: User?
    @State private var currentLine: Line?
    
    private func fetchData() async {
        do {
            try await lineRepository.fetchLines()
            
            if let recentLine = try await lineRepository.fetchMostRecentLine() {
                currentLine = recentLine
                
                let allUsers = try await userRepository.searchUsers(byName: "")
                
                matchingUser = allUsers.first { user in
                    guard let userLineNumber = user.lineNumber,
                          let userSemester = user.semester,
                          let userYear = user.year else {
                        return false
                    }
                    
                    return userLineNumber == String(member.number) &&
                           userSemester == recentLine.semester &&
                           userYear == String(recentLine.year)
                }
            }
        } catch {
            // Handle error silently
        }
    }
    
    var body: some View {
        VStack {
            ZStack {
                GradientRingView()
                    .frame(width: 74, height: 74)
                
                if let user = matchingUser,
                   let profileImageURL = user.profileImageURL,
                   let url = URL(string: profileImageURL) {
                    NavigationLink(destination: ProfileView(userId: user.id)) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 70, height: 70)
                                    .clipShape(Circle())
                            case .failure:
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 70, height: 70)
                                    .overlay(
                                        Image(systemName: "person.fill")
                                            .foregroundColor(.gray)
                                            .font(.system(size: 30))
                                    )
                            @unknown default:
                                ProgressView()
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 70, height: 70)
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(.gray)
                                .font(.system(size: 30))
                        )
                }
            }
            
            Text(member.name)
                .font(.caption)
                .multilineTextAlignment(.center)
            
            if let alias = member.alias {
                Text(alias)
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(width: 80)
        .onAppear {
            Task {
                await fetchData()
            }
        }
    }
} 