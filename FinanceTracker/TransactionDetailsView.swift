//
//  TransactionDetailsView.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 2/15/25.
//

import SwiftUI

enum detailsViewType: String {
    case add, modify
}

struct TransactionDetailsView: View
{
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Binding var transaction: Transaction
    
    @State private var showUploadMethodAlert = false
    @State private var showChosenMethod = false
    @State private var chosenUploadMethod: UIImagePickerController.SourceType = .photoLibrary
    @State private var detailsType: detailsViewType
    
    private func toUIImage(from data: Data?) -> UIImage?
    {
        guard let data = data else { return nil }
        return UIImage(data: data)
    }

    private func convertedUIImage(from image: Data?) -> UIImage
    {
        if let img = toUIImage(from: image)
        { return img }
        return UIImage(named: "Test Reciept")!
    }
    
    init(transaction: Binding<Transaction>, type: detailsViewType) {
        _transaction = transaction
        self.detailsType = type
    }
    
    var body: some View
    {
        HStack
        {
            ZStack
            {
                ImageRecognize(
                    image: convertedUIImage(from: transaction.image),
                    price: $transaction.price,
                    date: $transaction.date,
                    name: $transaction.name,
                    notes: $transaction.notes
                )
                .padding()
                .plainFill(material: .ultraThinMaterial, opacity: 0.4, cornerRadius: 20)
            }.padding(.leading, 30)
            
            ZStack
            {
                VStack
                {
                    Form
                    {
                        Section
                        {
                            TextField("Title",
                                      text: $transaction.name)
                                .padding()
                            
                            DatePicker("Enter Date",
                                       selection: $transaction.date,
                                       displayedComponents: .date)
                                .padding()
                            
                            Picker("Select Tag",
                                   selection: $transaction.tag)
                            {
                                ForEach(Tag.allCases, id: \.self)
                                { tagCase in
                                    let symbol = tagSymbol[tagCase] ?? "questionmark"
                                    Image(systemName: symbol)
                                        .tag(tagCase)
                                }
                            }
                                .pickerStyle(SegmentedPickerStyle())
                                .padding()
                            
                            HStack
                            {
                                Text("Price  (CN¥)")
                                
                                Spacer()
                                
                                TextField("Enter Price",
                                          value: $transaction.price,
                                          formatter: Transaction().priceFormatter)
                                    .keyboardType(.decimalPad)
                            }
                                .padding()
                            
                            Toggle("Paid",
                                   isOn: $transaction.paid)
                                .padding()
                                .toggleStyle(GlassmorphismToggleStyle())
                            
                            TextEditor(
                                text: Binding(get:
                                                { transaction.notes?.joined(separator: "\n") ?? "" },
                                              set:
                                                { newValue in
                                                    transaction.notes = newValue.split(separator: "\n").map { String($0) }
                                                }
                                             ))
                                .padding()
                                .frame(minHeight: 150)
                                .overlay(Text("Enter Notes")
                                            .foregroundColor(.gray)
                                            .opacity(transaction.notes?.isEmpty ?? true ? 0.5 : 0)
                                            .padding(.top, 25)
                                            .padding(.leading, 20),
                                         alignment: .topLeading)
                            
                            Button(action: { showUploadMethodAlert = true })
                            { Text("Select Image") }
                                .padding()
                                .sheet(isPresented: $showChosenMethod)
                                { ImagePicker(selectedImage: $transaction.image, sourceType: chosenUploadMethod) }
                                .alert("Upload Receipt Image", isPresented: $showUploadMethodAlert)
                                {
                                    Button("Use Camera", action: {  self.showChosenMethod = true
                                                                    chosenUploadMethod = .camera })
                                
                                    Button("Photo Album", action: { self.showChosenMethod = true
                                                                    chosenUploadMethod = .photoLibrary })
                                    
                                    Button("Cancel", action: {})
                                }
                        }
                        header: {   Text("Transaction Record")
                                        .padding(2)
                                        .background(RoundedRectangle(cornerRadius: 1)
                                                        .fill(.thinMaterial)
                                                        .blur(radius: 8)) }
                            .listRowBackground(Color.clear)
                            .plainFill()
                            .foregroundColor(.primary)
                    }
                        .plainFill(material: .ultraThinMaterial, opacity: 0.4, cornerRadius: 20)
                        .scrollContentBackground(.hidden)
                    
                    HStack
                    {
                        Button(action:{ saveTransaction(date: transaction.date,
                                                        name: transaction.name,
                                                        tag: transaction.tag,
                                                        price: transaction.price,
                                                        paid: transaction.paid,
                                                        notes: transaction.notes,
                                                        image: transaction.image)
                                        dismiss() })
                        {
                            HStack
                            {
                                Text(detailsType == .modify ? "Save" : "Submit")
                                    .font(.headline)
                            }
                                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: 50)
                                .background(Color.accentColor
                                                .opacity(0.6)
                                                .blur(radius: 10))
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .padding(.horizontal)
                        }
                            .layoutPriority(2)
                            .buttonStyle(ScaleButtonStyle())
                        
                        Button(action: { dismiss() })
                        {
                            HStack
                            {
                                Text("Cancel")
                                    .font(.headline)
                            }
                                .frame(minWidth: 0,
                                       maxWidth: .infinity,
                                       minHeight: 0,
                                       maxHeight: 50)
                                .background(RoundedRectangle(cornerRadius: 10)
                                                .fill(.thinMaterial)
                                                .blur(radius: 4))
                                .foregroundColor(.accentColor)
                                .cornerRadius(10)
                                .padding(.horizontal)
                        }
                            .layoutPriority(2)
                            .buttonStyle(ScaleButtonStyle())

                        if (detailsType == .modify) {
                            Button(action: { deleteTransaction() })
                            {
                                HStack
                                {
                                    Text("Delete")
                                        .font(.headline)
                                }
                                    .frame(minWidth: 0,
                                           maxWidth: .infinity,
                                           minHeight: 0,
                                           maxHeight: 50)
                                    .background(RoundedRectangle(cornerRadius: 10)
                                                    .fill(.red)
                                                    .blur(radius: 4))
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                    .padding(.horizontal)
                            }
                                .layoutPriority(2)
                                .buttonStyle(ScaleButtonStyle())
                        }
                    }
                }
                    .padding(20)
            }
                .scrollContentBackground(.hidden)
        }
            .colorfulAccentBackground(colorLinear: [.white, .white, .accentColor],
                                      colorRadial: [.accentColor, .white])
    }
    
    private func saveTransaction(date: Date,
                                 name: String,
                                 tag: Tag,
                                 price: Double,
                                 paid: Bool,
                                 notes: [String]? = nil,
                                 image: Data? = nil)
    {
        transaction = Transaction(date: date,
                                  name: (name.isEmpty || name == "Transaction") ? "Transaction at \(Date().time)" : name,
                                  tag: tag,
                                  price: price,
                                  paid: paid,
                                  notes: notes,
                                  image: image)
        modelContext.insert(transaction)
        saveModelContext(modelContext)
    }
    
    private func deleteTransaction()
    {
        modelContext.delete(transaction)
        saveModelContext(modelContext)
        dismiss()
    }
}
