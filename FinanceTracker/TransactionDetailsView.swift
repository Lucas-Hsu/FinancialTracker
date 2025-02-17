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
    
    private var priceFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }
    
    private func formattedPrice(_ price: Decimal) -> String {
        return priceFormatter.string(from: price as NSDecimalNumber) ?? "$0.00"
    }

    // Initialize state variables with the transaction values
    init(transaction: Binding<Transaction>) {
        _transaction = transaction
        _date = State(initialValue: transaction.wrappedValue.date)
        _name = State(initialValue: transaction.wrappedValue.name)
        _selectedTag = State(initialValue: Tag(rawValue: transaction.wrappedValue.tag) ?? .other)
        _price = State(initialValue: transaction.wrappedValue.price)
        _paid = State(initialValue: transaction.wrappedValue.paid)
    }
    
    func imagee() -> UIImage{
        if image != UIImage(){
            return image
        }
            
        return convertToUIImage(imageData: transaction.image) ?? UIImage(systemName: "photo")!
        // return convertToUIImage(imageData: transaction.image) ?? UIImage(named: "Test Reciept")!
    }
    

    var body: some View {
        HStack {
            ZStack{
                /*
                Image(uiImage: imagee())
                    .resizable()
                    .scaledToFit()
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .edgesIgnoringSafeArea(.all)*/
                
                    ImageRecognize(
                        
                        image: imagee(),
                        price: $price,
                        date: $date,
                        name: $name,
                        notes: $notes
                    )
            }

            VStack {
                Form {
                    Section(header: Text("Transaction Record")) {
                        
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
                                Text(tag.rawValue).tag(tag)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle()) // Or you can choose a default style
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
                            // Show the alert to choose the upload method
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
                    .foregroundColor(.primary)
                }
                
                HStack {
                    Button(action: {
                        saveTransaction(
                            date: date,
                            name: name,
                            tag: selectedTag.rawValue,
                            price: price,
                            paid: paid,
                            notes: notes,
                            image: convertToData(image: imagee())
                        )
                        print(
                            "Form submitted with values: \(name), \(selectedTag.rawValue), \(price), \(paid), \(notes ?? []), \(imageData?.count ?? 0) bytes"
                        )
                        dismiss()
                    }) {
                            Text("Save")
                                .font(.headline)
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: 50)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }
                    
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Cancel")
                            .font(.headline)
                    }
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: 50)
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.accentColor)
                    .cornerRadius(10)
                    .padding(.horizontal)
                    
                    Button(action: {
                        deleteTransaction()
                    }) {
                            Text("Delete")
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: 50)
                        .background(Color.red.opacity(0.2))
                        .foregroundColor(.red)
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }
                }
            }
        }
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

func convertToUIImage(imageData: Data?) -> UIImage? {
        guard let data = imageData else {
            return nil
        }
        return UIImage(data: data)
    }



struct TransactionDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        // Pass a binding to a transaction in the preview
        TransactionDetailsView(transaction: .constant(Transaction(date: Date(), name: "Test", tag: Tag.food.rawValue, price: 1.00, paid: true)))
    }
}


