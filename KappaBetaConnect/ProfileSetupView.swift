import SwiftUI

struct ProfileSetupView: View {
    @ObservedObject var userData: UserSignupData
    @State private var navigateToInitiation = false
    @State private var isLoading = false
    
    let careerFields = [
        "Business & Finance",
        "Technology & Engineering",
        "Healthcare & Medicine",
        "Law & Legal Services",
        "Education & Research",
        "Government & Public Service",
        "Arts & Entertainment",
        "Marketing & Communications",
        "Science & Research",
        "Real Estate & Construction",
        "Non-Profit & Social Services",
        "Other"
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Image("kblogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .padding(.top, 30)
                    .padding(.bottom, 20)
                
                // Education Section
                VStack(alignment: .leading, spacing: 20) {
                    Text("Education")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 30)
                        .padding(.top, 10)
                    
                    VStack(spacing: 15) {
                        TextField("Major", text: $userData.major)
                            .textFieldStyle(.plain)
                            .frame(minHeight: 55)
                            .font(.system(size: 18))
                            .padding(.horizontal, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal, 30)
                }
                
                // Career Section
                VStack(alignment: .leading, spacing: 20) {
                    Text("Career")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 30)
                        .padding(.top, 30)
                    
                    VStack(spacing: 15) {
                        // Career Field Picker
                        Picker("", selection: $userData.careerField) {
                            Text("Career Field").tag("")
                            ForEach(careerFields, id: \.self) { field in
                                Text(field).tag(field)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(.black)
                        .frame(minHeight: 55)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                        
                        TextField("Current Job Title", text: $userData.jobTitle)
                            .textFieldStyle(.plain)
                            .frame(minHeight: 55)
                            .font(.system(size: 18))
                            .padding(.horizontal, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                        
                        TextField("Company", text: $userData.company)
                            .textFieldStyle(.plain)
                            .frame(minHeight: 55)
                            .font(.system(size: 18))
                            .padding(.horizontal, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal, 30)
                }
                
                // Continue Button
                NavigationLink(destination: InitiationDetailsView(userData: userData), isActive: $navigateToInitiation) {
                    Button(action: {
                        navigateToInitiation = true
                    }) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Continue")
                                .foregroundColor(.white)
                                .font(.headline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 55)
                    .background(Color.black)
                    .cornerRadius(10)
                    .padding(.horizontal, 30)
                    .padding(.top, 40)
                    .padding(.bottom, 30)
                    .disabled(isLoading)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemBackground))
    }
}

#Preview {
    NavigationStack {
        ProfileSetupView(userData: UserSignupData())
    }
} 