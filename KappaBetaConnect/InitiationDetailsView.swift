import SwiftUI

struct InitiationDetailsView: View {
    @State private var selectedLineNumber = "1"
    @State private var selectedSemester = "Fall"
    @State private var selectedYear = String(Calendar.current.component(.year, from: Date()))
    
    let lineNumbers = Array(1...50).map { String($0) }
    let semesters = ["Fall", "Spring"]
    let years: [String] = {
        let currentYear = Calendar.current.component(.year, from: Date())
        return Array(1911...currentYear).map { String($0) }.reversed()
    }()
    
    var body: some View {
        VStack(spacing: 20) {
            Image("kblogo")
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 150)
                .padding(.top, 30)
            
            ScrollView {
                VStack(spacing: 15) {
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
                        Text("Semester")
                            .foregroundColor(.gray)
                        Spacer()
                        Picker("Semester", selection: $selectedSemester) {
                            ForEach(semesters, id: \.self) { semester in
                                Text(semester).tag(semester)
                            }
                        }
                        .pickerStyle(.menu)
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
                        Text("Year")
                            .foregroundColor(.gray)
                        Spacer()
                        Picker("Year", selection: $selectedYear) {
                            ForEach(years, id: \.self) { year in
                                Text(year).tag(year)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                    
                    Button(action: {
                        // Handle completion
                    }) {
                        Text("Complete Setup")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.black)
                            .cornerRadius(10)
                    }
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
        InitiationDetailsView()
    }
} 