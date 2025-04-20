import Foundation

class UserSignupData: ObservableObject {
    // Personal Information
    @Published var prefix: String = ""
    @Published var firstName: String = ""
    @Published var lastName: String = ""
    @Published var suffix: String = ""
    @Published var email: String = ""
    @Published var phoneNumber: String = ""
    @Published var city: String = ""
    @Published var state: String = ""
    @Published var homeCity: String = ""
    @Published var homeState: String = ""
    
    // Security
    @Published var password: String = ""
    
    // Profile Information
    @Published var careerField: String = ""
    @Published var major: String = ""
    @Published var jobTitle: String = ""
    @Published var company: String = ""
    
    // Initiation Information
    @Published var lineNumber: String = ""
    @Published var semester: String = ""
    @Published var year: String = ""
    @Published var status: String = ""
    @Published var graduationYear: String = ""
    
    func createUser() -> User {
        return User(
            prefix: prefix.isEmpty ? nil : prefix,
            firstName: firstName,
            lastName: lastName,
            suffix: suffix.isEmpty ? nil : suffix,
            email: email,
            phoneNumber: phoneNumber,
            city: city.isEmpty ? nil : city,
            state: state.isEmpty ? nil : state,
            homeCity: homeCity.isEmpty ? nil : homeCity,
            homeState: homeState.isEmpty ? nil : homeState,
            password: password,
            careerField: careerField.isEmpty ? nil : careerField,
            major: major.isEmpty ? nil : major,
            jobTitle: jobTitle.isEmpty ? nil : jobTitle,
            company: company.isEmpty ? nil : company,
            lineNumber: lineNumber.isEmpty ? nil : lineNumber,
            semester: semester.isEmpty ? nil : semester,
            year: year.isEmpty ? nil : year,
            status: status.isEmpty ? nil : status,
            graduationYear: graduationYear.isEmpty ? nil : graduationYear
        )
    }
} 