//
//  AddNew.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 1/31/25.
//
import Foundation
import SwiftData
import SwiftUI
import UIKit

struct AddNew: View {
    @State var transaction: Transaction = Transaction()
    @State private var isShowPhotoLibrary = false
    @State private var image: UIImage = UIImage()

    @Environment(\.dismiss) private var dismiss // Access the dismiss function
    @Environment(\.modelContext) var modelContext

    @State private var date: Date = Date()
    @State private var name: String = ""
    @State private var selectedTag: Tag = .other
    @State private var price: Double = 0.0
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
            HStack{
                
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
                            image: convertToData(image: image)
                        )
                        dismiss()
                    }) {
                        HStack {
                            Text("Submit")
                                .font(.headline)
                        }
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: 50)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }.layoutPriority(2)

                    Button(action: {
                        dismiss()
                    }) {
                        HStack {
                            Text("Cancel")
                                .font(.headline)
                        }
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: 50)
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.accentColor)
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }.layoutPriority(2)
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
