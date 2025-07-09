//
//  TransactionDetailsView.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 2/15/25.
//

import SwiftUI
import Vision

enum detailsViewType: String {
    case add, modify
}

struct OCRResult: Identifiable {
    let id = UUID()
    let text: String
    let x: CGFloat  // Normalized (0–1)
    let y: CGFloat  // Normalized (0–1)
}

struct TransactionDetailsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Binding var transaction: Transaction

    @State private var showUploadMethodAlert = false
    @State private var showChosenMethod = false
    @State private var chosenUploadMethod: UIImagePickerController.SourceType = .photoLibrary
    @State private var detailsType: detailsViewType

    @State private var ocrResults: [OCRResult] = []
    
    private func toUIImage(from data: Data?) -> UIImage? {
        guard let data = data else { return nil }
        return UIImage(data: data)
    }

    private func convertedUIImage(from image: Data?) -> UIImage {
        if let img = toUIImage(from: image) { return img }
        return UIImage(named: "Test Reciept")!
    }

    init(transaction: Binding<Transaction>, type: detailsViewType) {
        _transaction = transaction
        self.detailsType = type
    }

    var body: some View {
        HStack {
            ZStack {
                ZoomableImageWithOCR(
                    image: convertedUIImage(from: transaction.image),
                    ocrResults: ocrResults,
                    onTextTap: { result in
                        if let value = Double(result.text.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)) {
                            transaction.price = value
                        } else {
                            if transaction.notes == nil { transaction.notes = [] }
                            transaction.notes?.append(result.text)
                        }
                    }
                )
                .onAppear {
                    let uiImage = convertedUIImage(from: transaction.image)
                    performOCR(on: uiImage, in: CGSize(width: uiImage.size.width, height: uiImage.size.height)) { results in
                        ocrResults = results
                    }
                }

                .padding()
                .plainFill(material: .ultraThinMaterial, opacity: 0.4, cornerRadius: 20)
            }
            .padding(.leading, 30)

            VStack {
                Form {
                    Section {
                        TextField("Title", text: $transaction.name).padding()
                        DatePicker("Enter Date", selection: $transaction.date, displayedComponents: .date).padding()
                        Picker("Select Tag", selection: $transaction.tag) {
                            ForEach(Tag.allCases, id: \.self) { tagCase in
                                let symbol = tagSymbol[tagCase] ?? "questionmark"
                                Image(systemName: symbol).tag(tagCase)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding()
                        HStack {
                            Text("Price (CN¥)")
                            Spacer()
                            TextField("Enter Price", value: $transaction.price, formatter: Transaction().priceFormatter)
                                .keyboardType(.decimalPad)
                        }
                        .padding()
                        Toggle("Paid", isOn: $transaction.paid)
                            .padding()
                            .toggleStyle(GlassmorphismToggleStyle())
                        TextEditor(text: Binding(
                            get: { transaction.notes?.joined(separator: "\n") ?? "" },
                            set: { newValue in transaction.notes = newValue.split(separator: "\n").map(String.init) }
                        ))
                        .padding()
                        .frame(minHeight: 150)
                        .overlay(
                            Text("Enter Notes")
                                .foregroundColor(.gray)
                                .opacity(transaction.notes?.isEmpty ?? true ? 0.5 : 0)
                                .padding(.top, 25)
                                .padding(.leading, 20),
                            alignment: .topLeading
                        )
                        Button("Select Image") { showUploadMethodAlert = true }
                            .padding()
                            .sheet(isPresented: $showChosenMethod) {
                                ImagePicker(selectedImage: $transaction.image, sourceType: chosenUploadMethod)
                            }
                            .alert("Upload Receipt Image", isPresented: $showUploadMethodAlert) {
                                Button("Use Camera") {
                                    showChosenMethod = true
                                    chosenUploadMethod = .camera
                                }
                                Button("Photo Album") {
                                    showChosenMethod = true
                                    chosenUploadMethod = .photoLibrary
                                }
                                Button("Cancel", role: .cancel) {}
                            }
                    }
                    header: {
                        Text("Transaction Record")
                            .padding(2)
                            .background(RoundedRectangle(cornerRadius: 1).fill(.thinMaterial).blur(radius: 8))
                    }
                    .listRowBackground(Color.clear)
                    .plainFill()
                    .foregroundColor(.primary)
                }
                .plainFill(material: .ultraThinMaterial, opacity: 0.4, cornerRadius: 20)
                .scrollContentBackground(.hidden)

                HStack {
                    Button {
                        saveTransaction(date: transaction.date,
                                        name: transaction.name,
                                        tag: transaction.tag,
                                        price: transaction.price,
                                        paid: transaction.paid,
                                        notes: transaction.notes,
                                        image: transaction.image)
                    } label: {
                        Text(detailsType == .modify ? "Save" : "Submit")
                            .font(.headline)
                            .frame(maxWidth: .infinity, maxHeight: 50)
                            .background(Color.accentColor.opacity(0.6).blur(radius: 10))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding(.horizontal)
                    }
                    .buttonStyle(ScaleButtonStyle())

                    Button { dismiss() } label: {
                        Text("Cancel")
                            .font(.headline)
                            .frame(maxWidth: .infinity, maxHeight: 50)
                            .background(RoundedRectangle(cornerRadius: 10).fill(.thinMaterial).blur(radius: 4))
                            .foregroundColor(.accentColor)
                            .cornerRadius(10)
                            .padding(.horizontal)
                    }
                    .buttonStyle(ScaleButtonStyle())

                    if detailsType == .modify {
                        Button {
                            deleteTransaction()
                        } label: {
                            Text("Delete")
                                .font(.headline)
                                .frame(maxWidth: .infinity, maxHeight: 50)
                                .background(RoundedRectangle(cornerRadius: 10).fill(.red).blur(radius: 4))
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .padding(.horizontal)
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }
            }
            .padding(20)
        }
        .colorfulAccentBackground(colorLinear: [.white, .white, .accentColor], colorRadial: [.accentColor, .white])
    }

    private func saveTransaction(date: Date, name: String, tag: Tag, price: Double, paid: Bool, notes: [String]?, image: Data?) {
        transaction = Transaction(
            date: date,
            name: name.isEmpty || name == "Transaction" ? "Transaction at \(Date().time)" : name,
            tag: tag,
            price: price,
            paid: paid,
            notes: notes,
            image: image
        )
        if detailsType == .add {
            modelContext.insert(transaction)
        }
        saveModelContext(modelContext)
        dismiss()
    }

    private func deleteTransaction() {
        modelContext.delete(transaction)
        saveModelContext(modelContext)
        dismiss()
    }

    private func performMockOCR() -> [OCRResult] {
        // You should replace this with a real OCR engine
        return [
            OCRResult(text: "123.45", x: 0.6, y: 0.5),
            OCRResult(text: "2025-07-09", x: 0.3, y: 0.7),
            OCRResult(text: "Apple Store", x: 0.4, y: 0.3)
        ]
    }
}

func performOCR(on image: UIImage, in size: CGSize, completion: @escaping ([OCRResult]) -> Void) {
    guard let cgImage = image.cgImage else {
        completion([])
        return
    }

    let request = VNRecognizeTextRequest { request, error in
        guard let observations = request.results as? [VNRecognizedTextObservation] else {
            completion([])
            return
        }

        let results: [OCRResult] = observations.compactMap { observation in
            guard let candidate = observation.topCandidates(1).first else { return nil }
            let boundingBox = observation.boundingBox // CGRect (x, y, w, h) in normalized coordinates (bottom-left origin)
            
            // Convert center of bounding box
            let centerX = boundingBox.midX
            let centerY = 1 - boundingBox.midY // Flip y-axis for SwiftUI coordinate system

            return OCRResult(text: candidate.string, x: centerX, y: centerY)
        }

        DispatchQueue.main.async {
            completion(results)
        }
    }

    request.recognitionLevel = .accurate
    request.usesLanguageCorrection = true

    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
    DispatchQueue.global(qos: .userInitiated).async {
        do {
            try handler.perform([request])
        } catch {
            print("OCR failed:", error)
            DispatchQueue.main.async { completion([]) }
        }
    }
}
