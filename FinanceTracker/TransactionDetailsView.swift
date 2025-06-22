//
//  TransactionDetailsView.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 2/15/25.
//


import Foundation
import SwiftData
import SwiftUI

struct TransactionDetailsView: View {
    
    @Binding var transaction: Transaction // Change to Binding
    @State private var isShowPhotoLibrary = false
    @State private var image = UIImage()
    
    @Environment(\.dismiss) private var dismiss // Access the dismiss function
    @Environment(\.modelContext) var modelContext
    
    @State private var date: Date
    @State private var name: String
    @State private var selectedTag: Tag
    @State private var price: Double
    @State private var paid: Bool
    @State private var notes: [String]? = nil
    @State private var imageData: Data? = nil
    
    @State private var chosenUploadMethod: UIImagePickerController.SourceType = .photoLibrary
    @State private var showAlert = false

    private func formattedPrice(_ price: Decimal) -> String {
        return Transaction().priceFormatter.string(from: price as NSDecimalNumber) ?? "$0.00"
    }
    
    // Initialize state variables with the transaction values
    init(transaction: Binding<Transaction>) {
        _transaction = transaction
        _date = State(initialValue: transaction.wrappedValue.date)
        _name = State(initialValue: transaction.wrappedValue.name)
        _selectedTag = State(initialValue: Tag(rawValue: transaction.wrappedValue.tag) ?? .other)
        _price = State(initialValue: transaction.wrappedValue.price)
        _paid = State(initialValue: transaction.wrappedValue.paid)
        _notes = State(initialValue: transaction.wrappedValue.notes)
    }
    
    func imagee() -> UIImage{
        if image != UIImage(){
            return image
        }
        
        return toUIImage(from: transaction.image) ?? UIImage(systemName: "photo")!
        // return convertToUIImage(imageData: transaction.image) ?? UIImage(named: "Test Reciept")!
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
                                    Image(systemName: tagSymbol[tag] ?? "questionmark").tag(tag)
                                    //Text(tag.rawValue).tag(tag)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle()) // Or you can choose a default style
                            .padding()
                            
                            HStack {
                                Text("Price  (CN¥)")
                                Spacer()
                                TextField("Enter Price", value: $price, formatter: Transaction().priceFormatter)
                                    .keyboardType(.decimalPad)
                            }
                            .padding()
                            
                            Toggle("Paid", isOn: $paid)
                                .padding()
                                .toggleStyle(GlassmorphismToggleStyle())
                            
                            // Notes Input Field (multi-line, allows newlines)
                            TextEditor(text: Binding(
                                get: {
                                    notes?.joined(separator: "\n") ?? ""  // Join the array into a single string for display, default to empty string if nil
                                },
                                set: { newValue in
                                    notes = newValue.split(separator: "\n").map { String($0) }  // Split the string into an array by newlines
                                }
                            ))
                            .padding()
                            .frame(minHeight: 150) // Set height for the text editor
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
                                Button("Use Camera", action:{
                                    self.isShowPhotoLibrary = true
                                    chosenUploadMethod = .camera
                                })
                                
                                Button("Photo Album", action:{
                                    self.isShowPhotoLibrary = true
                                    chosenUploadMethod = .photoLibrary
                                })
                                
                                Button("Cancel", action:{})
                            }
                            .sheet(isPresented: $isShowPhotoLibrary) {
                                ImagePicker(selectedImage: self.$image, sourceType: chosenUploadMethod)
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
                        .clearBackground()
                        .plainFill()
                        .foregroundColor(.primary)
                    }
                    .plainFill(material: .ultraThinMaterial, opacity: 0.4, cornerRadius: 20)
                    
                    HStack {
                        Button(action: {
                            saveTransaction(
                                date: date,
                                name: name,
                                tag: selectedTag.rawValue,
                                price: price,
                                paid: paid,
                                notes: notes,
                                image: toData(from: imagee())
                            )
                            print(
                                "Form submitted with values: \(name), \(selectedTag.rawValue), \(price), \(paid), \(notes ?? []), \(imageData?.count ?? 0) bytes"
                            )
                            dismiss()
                        }) {
                            Text("Save")
                                .font(.headline)
                                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: 50)
                                .accentButton()
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .padding(.horizontal)
                        }
                        .buttonStyle(ScaleButtonStyle())
                        
                        Button(action: {
                            dismiss()
                        }) {
                            Text("Cancel")
                                .font(.headline)
                                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: 50)
                                .plainFill()
                                .foregroundColor(.accentColor)
                                .cornerRadius(10)
                                .padding(.horizontal)
                        }
                        .buttonStyle(ScaleButtonStyle())
                        
                        
                        Button(action: {
                            deleteTransaction()
                        }) {
                            Text("Delete")
                                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: 50)
                                .accentButton(color: .red)
                                .foregroundColor(.primary)
                                .cornerRadius(10)
                                .padding(.horizontal)
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }.padding(20)
            }
            .clearBackground()
        }.colorfulAccentBackground(colorLinear: [.accentColor, .white,  .white], colorRadial: [.accentColor, .white])
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
        transaction.date = date
        transaction.name = name
        transaction.tag = tag
        transaction.price = price
        transaction.paid = paid
        transaction.notes = notes
        transaction.image = image
        try! modelContext.save() // Save the modified transaction
    }
    
    
    private func deleteTransaction() {
        // Delete the transaction from the model context
        modelContext.delete(transaction)
        
        // Save the changes to persist the deletion
        try? modelContext.save()
        
        // Optionally, dismiss the view after deletion
        dismiss()
    }
}

func toUIImage(from data: Data?) -> UIImage?
{
    guard let data = data else { return nil }
    return UIImage(data: data)
}

func toData(from image: UIImage?) -> Data?
{
    if let uiImage = image { return uiImage.jpegData(compressionQuality: 1.0) }
    return nil
}

struct TransactionDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        // Pass a binding to a transaction in the preview
        TransactionDetailsView(transaction: .constant(Transaction(date: Date(), name: "Test", tag: Tag.food.rawValue, price: 1.00, paid: true)))
    }
}

