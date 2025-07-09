//
//  ImageRecognize.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 2/15/25.
//


import SwiftUI
import Vision
import Foundation

struct ImageRecognize: View {
    let image: UIImage
    @Binding var price: Double
    @Binding var date: Date
    @Binding var name: String
    @Binding var notes: [String]?

    @State private var recognizedText: [VNRecognizedTextObservation] = []
    @State private var selectedDate = Date()

    var body: some View {
        VStack {
            // Image Display
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: UIScreen.main.bounds.height * 0.6)
                .onAppear {
                    performOCR()
                }
                .onChange(of: image) { oldImage, newImage in
                    if oldImage != newImage {
                        performOCR()
                    }
                }
                .background(
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .blur(radius: 10)
                            .edgesIgnoringSafeArea(.all)
                    )
                .padding(10)

                // Horizontal ScrollView for 2 rows of recognized text
                ScrollView(.horizontal, showsIndicators: false) {
                    VStack(spacing: 0) {
                        // First row of recognized text
                        HStack(spacing: 10) {
                            ForEach(0..<min(4, recognizedText.count), id: \.self) { index in
                                let observation = recognizedText[index]
                                if let candidate = observation.topCandidates(1).first {
                                    Button(action: {
                                        fillTextField(with: candidate.string)
                                        
                                    }) {
                                        Text(candidate.string)
                                            .foregroundColor(.white)
                                            .padding(8)
                                            .accentButton(opacity: 0.8, blurRadius: 2)
                                            .frame(minWidth: 100, maxWidth: .infinity)
                                            .textSelection(.disabled) // Disable text selection
                                    }.buttonStyle(ScaleButtonStyle())
                                }
                            }
                        }.padding(6)
                            .padding(.top, 6)

                        // Second row of recognized text
                        HStack(spacing: 10) {
                            ForEach(min(4, recognizedText.count) ..< recognizedText.count, id: \.self) { index in
                                let observation = recognizedText[index]
                                if let candidate = observation.topCandidates(1).first {
                                    Button(action: {
                                        fillTextField(with: candidate.string)
                                        
                                    }) {
                                        Text(candidate.string)
                                            .foregroundColor(.white)
                                            .padding(8)
                                            .accentButton(opacity: 0.8, blurRadius: 2)
                                            .frame(minWidth: 100, maxWidth: .infinity)
                                            .textSelection(.disabled) // Disable text selection
                                    }.buttonStyle(ScaleButtonStyle())
                                }
                            }
                        }
                        .padding(12)
                    }
                    
                    
                }.plainFill()
                .frame(maxWidth: .infinity, maxHeight: UIScreen.main.bounds.height * 0.1)
                .padding(10)
        }
    }

    func performOCR() {
        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                print("[ERROR] OCR failed: \(error.localizedDescription)")
                return
            }

            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
            recognizedText = observations
        }

        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = ["zh-Hans", "en"]
        
        let handler = VNImageRequestHandler(cgImage: image.cgImage!, options: [:])
        
        do {
            try handler.perform([request])
        } catch {
            print("[ERROR] Failed to perform OCR request: \(error.localizedDescription)")
        }
    }

    func fillTextField(with text: String) {
        if let dateValue = isDate(str: text) {
            selectedDate = dateValue
            date = dateValue
        } else if let priceValue = extractPrice(from: text) {
            price = priceValue
        } else if (name.isEmpty || name.hasPrefix("Transaction")) {
            name = text
        } else {
            // Append to notes
            if notes == nil {
                notes = [text]
            } else {
                notes?.append(text)
            }
        }
    }
    
    private func isDate(str: String) -> Date? {
        let dateFormatter = DateFormatter()
        
        // List of all formats
        let dateFormats = [
            "dd/MM/yyyy", "yyyy/MM/dd", "dd MM yyyy", "yyyy MM dd", "dd.MM.yyyy", "yyyy.MM.dd",
            "yyyy年MM月dd日", "yyyy年MM月dd号", "MM月dd日, yyyy年", "MM月dd号, yyyy年", "MM月dd日,yyyy年", "MM月dd号,yyyy年",
            "MMM. dd, yyyy", "yyyy MMM. dd", "MMMM dd, yyyy", "yyyy MMMM dd"]
        
        // Try all formats
        for format in dateFormats {
            dateFormatter.dateFormat = format
            if let date = dateFormatter.date(from: str) {
                return date
            }
        }
        
        // Special logic for month without year (past year)
        if let date = parseMonthWithoutYear(str) {
            return date
        }
        
        return nil
    }
    
    // Logic to handle months without year (determine if it should be last year or current year)
    private func parseMonthWithoutYear(_ str: String) -> Date? {
        let today = Date()
        let dateFormatter = DateFormatter()
        let dateFormats = ["MMMM dd", "MMM. dd", "dd MMMM", "dd MMM."]
        for format in dateFormats {
            dateFormatter.dateFormat = format
            
            if let date = dateFormatter.date(from: str) {
                // Determine if the date should be from last year or current year
                let calendar = Calendar.current
                let currentYear = calendar.component(.year, from: today)
                // Check if the parsed date has already occurred this year
                
                // Extract the components of the date (year, month, day)
                var str_components = calendar.dateComponents([.year, .month, .day], from: date)
                
                // Set the year to 2025
                str_components.year = 2025
                
                // Reconstruct the date with the new year
                let currentYearDate: Date = calendar.date(from: str_components) ?? Date()
                    
                
                // If this year's date has passed, use the current year, else use the previous year
                let finalYear = (currentYearDate > today) ? currentYear - 1 : currentYear
                
                // Replace the year with the correct year
                var components = calendar.dateComponents([.year, .month, .day], from: date)
                components.year = finalYear
                
                return calendar.date(from: components)
            }
        }
        
        return nil
    }

    func extractPrice(from text: String) -> Double? {
        let pricePattern = #"^-?(\$|€|£|¥)?\s?\d{1,3}(,\d{3})*(\.\d{2})?$"#
        if let range = text.range(of: pricePattern, options: .regularExpression) {
            let priceString = text[range]
            let cleanedString = priceString.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
            return Double(cleanedString)
        }
        return nil
    }



    func isDate(_ text: String) -> Bool {
        let datePattern = #"^(0[1-9]|1[0-2])[-/](0[1-9]|[12][0-9]|3[01])[-/](\d{4}|\d{2})$|^\d{4}[-/](0[1-9]|1[0-2])[-/](0[1-9]|[12][0-9]|3[01])$|^(0[1-9]|[12][0-9]|3[01])[-/](0[1-9]|1[0-2])[-/](\d{4}|\d{2})$"#
        return text.range(of: datePattern, options: .regularExpression) != nil
    }



    func isPrice(_ text: String) -> Bool {
        let priceRegex = "^(\\$|€|£)?\\d+(\\.\\d{2})?$" // Example regex for price
        let pricePredicate = NSPredicate(format: "SELF MATCHES %@", priceRegex)
        return pricePredicate.evaluate(with: text)
    }

    func normalizedRect(for boundingBox: CGRect, imageSize: CGSize) -> CGRect {
        let scaleX = imageSize.width
        let scaleY = imageSize.height
        return CGRect(x: boundingBox.origin.x * scaleX, y: (1 - boundingBox.origin.y - boundingBox.height) * scaleY, width: boundingBox.width * scaleX, height: boundingBox.height * scaleY)
    }

    private var priceFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"
        return formatter
    }
}

struct ImageRecognize_Previews: PreviewProvider {
    static var previews: some View {
        if let sampleImage = UIImage(named: "Test Reciept") {
            ImageRecognize(
                image: sampleImage,
                price: .constant(0.0),
                date: .constant(Date()),
                name: .constant("Sample Name"),
                notes: .constant(nil)
            )
        } else {
            // Handle the case where the image is not found
            Text("Image not found")
        }
    }
}
