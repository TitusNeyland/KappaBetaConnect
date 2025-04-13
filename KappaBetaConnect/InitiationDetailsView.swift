import SwiftUI

struct InitiationDetailsView: View {
    @ObservedObject var userData: UserSignupData
    @State private var selectedLineNumber = "1"
    @State private var selectedSemester = "Fall"
    @State private var selectedYear = String(Calendar.current.component(.year, from: Date()))
    @State private var selectedStatus = "Collegiate"
    @State private var selectedGraduationYear = String(Calendar.current.component(.year, from: Date()) + 4)
    @State private var navigateToPassword = false
    @State private var isLoading = false
    
    let lineNumbers = Array(1...50).map { String($0) }
    let semesters = ["Fall", "Spring"]
    let years: [String] = {
        let currentYear = Calendar.current.component(.year, from: Date())
        return Array(1911...currentYear).map { String($0) }.reversed()
    }()
    let graduationYears: [String] = {
        let currentYear = Calendar.current.component(.year, from: Date())
        return Array(currentYear...(currentYear + 10)).map { String($0) }
    }()
    let statuses = ["Collegiate", "Alumni"]
    
    var body: some View {
        VStack(spacing: 20) {
            Image("kblogo")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .padding(.top, 30)
                .padding(.bottom, 20)
            
            ScrollView {
                VStack(spacing: 15) {
                    // Status Picker
                    HStack {
                        Text("Status")
                            .foregroundColor(.gray)
                        Spacer()
                        Picker("Status", selection: $selectedStatus) {
                            ForEach(statuses, id: \.self) { status in
                                Text(status).tag(status)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(.black)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                    
                    // Graduation Year Picker (only shown for Collegiate)
                    if selectedStatus == "Collegiate" {
                        HStack {
                            Text("Expected Graduation Year")
                                .foregroundColor(.gray)
                            Spacer()
                            Picker("Graduation Year", selection: $selectedGraduationYear) {
                                ForEach(graduationYears, id: \.self) { year in
                                    Text(year).tag(year)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(.black)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                    }
                    
                    // Line Number Picker
                    HStack {
                        Text("Line Number")
                            .foregroundColor(.gray)
                        Spacer()
                        Picker("Line Number", selection: $selectedLineNumber) {
                            ForEach(lineNumbers, id: \.self) { number in
                                Text(number).tag(number)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(.black)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                    
                    // Semester Picker
                    HStack {
                        Text("Initiation Semester")
                            .foregroundColor(.gray)
                        Spacer()
                        Picker("Initiation Semester", selection: $selectedSemester) {
                            ForEach(semesters, id: \.self) { semester in
                                Text(semester).tag(semester)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(.black)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                    
                    // Year Picker
                    HStack {
                        Text("Initiation Year")
                            .foregroundColor(.gray)
                        Spacer()
                        Picker("Initiation Year", selection: $selectedYear) {
                            ForEach(years, id: \.self) { year in
                                Text(year).tag(year)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(.black)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                    
                    NavigationLink(destination: PasswordSetupView(userData: userData), isActive: $navigateToPassword) {
                        Button(action: {
                            userData.lineNumber = selectedLineNumber
                            userData.semester = selectedSemester
                            userData.year = selectedYear
                            userData.status = selectedStatus
                            userData.graduationYear = selectedStatus == "Collegiate" ? selectedGraduationYear : ""
                            navigateToPassword = true
                        }) {
                            Text("Continue")
                                .foregroundColor(.white)
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 55)
                        .background(Color.black)
                        .cornerRadius(10)
                        .disabled(isLoading)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 30)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemBackground))
    }
}

#Preview {
    NavigationStack {
        InitiationDetailsView(userData: UserSignupData())
    }
} 