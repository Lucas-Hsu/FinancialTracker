//
//  AddNew.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 1/31/25.
//

import SwiftUI

struct AddNew: View {
    @State var transaction: Transaction = Transaction()
    @State private var isShowPhotoLibrary = false
    @State private var image: UIImage = UIImage()
    
    @Environment(\.dismiss) private var dismiss // Access the dismiss function
    @Environment(\.modelContext) var modelContext
    
    @State public var date: Date = Date()
    @State public var name: String = ""
    @State public var selectedTag: Tag = .other
    @State public var price: Double = 0.0
    @State private var paid: Bool = true
    @State private var notes: [String]? = nil
    
    @State private var chosenUploadMethod: UIImagePickerController.SourceType = .photoLibrary
    @State private var showAlert = false
    
    var priceFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }
    
    private func formattedPrice(_ price: Decimal) -> String {
        return priceFormatter.string(from: price as NSDecimalNumber) ?? "$0.00"
    }
    
    func imagee() -> UIImage{
        if image != UIImage(){
            return image
        }
        
        //return convertToUIImage(imageData: transaction.image) ?? UIImage(systemName: "photo")!
        return convertToUIImage(imageData: transaction.image) ?? UIImage(named: "Test Reciept")!
    }
    
    var body: some View {
        
        
        HStack {
            ZStack{
                ImageRecognize(
                    
                    image: imagee(),
                    price: $price,
                    date: $date,
                    name: $name,
                    notes: $notes
                )
                .padding()
                .plainFill(material: .ultraThinMaterial, opacity: 0.4, cornerRadius: 20)
                
            }.padding(.leading, 30)
            
            ZStack {
                VStack {
                    Form {
                        Section {
                            TextField("Title", text: $name)
                                .padding()
                            
                            DatePicker(
                                "Enter Date",
                                selection: $date,
                                displayedComponents: .date
                            )
                            .padding()
                            
                            
                            Picker("Select Tag", selection: $selectedTag) {
                                ForEach(Tag.allCases, id: \.self) { tag in
                                    Image(systemName: symbolRepresentation[tag] ?? "questionmark").tag(tag)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .padding()
                            
                            HStack {
                                Text("Price  (CN¥)")
                                Spacer()
                                TextField("Enter Price", value: $price, formatter: priceFormatter)
                                    .keyboardType(.decimalPad)
                            }
                            .padding()
                            
                            Toggle("Paid", isOn: $paid)
                                .padding()
                                .toggleStyle(GlassmorphismToggleStyle())
                                        
                            
                            TextEditor(text: Binding(
                                get: {
                                    notes?.joined(separator: "\n") ?? ""
                                },
                                set: { newValue in
                                    notes = newValue.split(separator: "\n").map { String($0) }
                                }
                            ))
                            .padding()
                            .frame(minHeight: 150)
                            .overlay(
                                Text("Enter Notes")
                                    .foregroundColor(.gray)
                                    .opacity(notes?.isEmpty ?? true ? 0.5 : 0)
                                    .padding(.top, 25)
                                    .padding(.leading, 20),
                                alignment: .topLeading
                            )
                            
                            Button(action: {
                                showAlert = true
                            }) {
                                Text("Select Image")
                            }
                            .padding()
                            .alert("Upload Receipt Image", isPresented: $showAlert) {
                                Button("Use Camera", action: {
                                    self.isShowPhotoLibrary = true
                                    chosenUploadMethod = .camera
                                })
                                
                                Button("Photo Album", action: {
                                    self.isShowPhotoLibrary = true
                                    chosenUploadMethod = .photoLibrary
                                })
                                
                                Button("Cancel", action: {})
                            }
                            .sheet(isPresented: $isShowPhotoLibrary) {
                                ImagePicker(selectedImage: $image, sourceType: chosenUploadMethod)
                            }
                        }
                        header: {
                            Text("Transaction Record")
                                .padding(2)
                                .background(
                                    RoundedRectangle(cornerRadius: 1)
                                        .fill(.thinMaterial) // Apply thin material background
                                        .blur(radius: 8)
                                )
                        }
                        .listRowBackground(Color.clear)
                        .plainFill()
                        .foregroundColor(.primary)
                        
                        
                    }
                    .plainFill(material: .ultraThinMaterial, opacity: 0.4, cornerRadius: 20)
                    .scrollContentBackground(.hidden)
                    
                    HStack {
                        Button(action: {
                            saveTransaction(
                                date: date,
                                name: name,
                                tag: selectedTag.rawValue,
                                price: price,
                                paid: paid,
                                notes: notes,
                                image: convertToData(image: image)
                            )
                            dismiss()
                        }) {
                            HStack {
                                Text("Submit")
                                    .font(.headline)
                            }
                            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: 50)
                            .background(
                                Color.accentColor
                                    .opacity(0.6)
                                    .blur(radius: 10)
                            )
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding(.horizontal)
                        }.layoutPriority(2)
                            .buttonStyle(ScaleButtonStyle())
                        
                        Button(action: {
                            dismiss()
                        }) {
                            HStack {
                                Text("Cancel")
                                    .font(.headline)
                            }
                            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(.thinMaterial)
                                    .blur(radius: 4)
                            )
                            .foregroundColor(.accentColor)
                            .cornerRadius(10)
                            .padding(.horizontal)
                        }.layoutPriority(2)
                        .buttonStyle(ScaleButtonStyle())
                    }
                }.padding(20)
            }
            .scrollContentBackground(.hidden)
        }.colorfulAccentBackground(colorLinear: [.white, .white, .accentColor], colorRadial: [.accentColor, .white])
    }
    
    func saveTransaction(
        date: Date,
        name: String,
        tag: String,
        price: Double,
        paid: Bool,
        notes: [String]? = nil,
        image: Data? = nil
    ) {
        transaction = Transaction(
            date: date,
            name: name.isEmpty ? "Untitled at \(Date())" : name,
            tag: tag,
            price: price,
            paid: paid,
            notes: notes,
            image: image
        )
        modelContext.insert(transaction)
        try! modelContext.save()
    }
}

func convertToData(image: UIImage?) -> Data? {
    if let uiImage = image {
        return uiImage.jpegData(compressionQuality: 1.0)
    }
    return nil
}

struct AddNew_Previews: PreviewProvider {
    static var previews: some View {
        AddNew()
    }
}
