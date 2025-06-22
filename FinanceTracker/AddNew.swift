//
//  AddNew.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 1/31/25.
//

import SwiftUI

struct AddNew: View
{
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var transaction: Transaction = Transaction()
    @State private var name: String
    @State private var paid: Bool
    @State private var date: Date
    @State private var price: Double
    @State private var tag: Tag
    @State private var notes: [String]?
    @State private var image: UIImage
    
    @State private var showUploadMethodAlert = false
    @State private var showChosenMethod = false
    @State private var chosenUploadMethod: UIImagePickerController.SourceType = .photoLibrary
    
    /// Returns a valid image, either the already existing UIImage image, the Data transaction.image, or a default one
    private func imageConverted() -> UIImage
    {
        if image != UIImage() { return image }
        if let img = toUIImage(from: transaction.image) { return img }
        return UIImage(named: "Test Reciept")! // UIImage(systemName: "photo")!
    }
    
    private func saveTransaction(date: Date,
                         name: String,
                         tag: String,
                         price: Double,
                         paid: Bool,
                         notes: [String]? = nil,
                         image: Data? = nil)
    {
        transaction = Transaction(date: date,
                                  name: name.isEmpty ? "Untitled at \(Date())" : name,
                                  tag: tag,
                                  price: price,
                                  paid: paid,
                                  notes: notes,
                                  image: image)
        modelContext.insert(transaction)
        saveModelContext(modelContext)
    }
    
    init(name: String = "",
         paid: Bool = true,
         date: Date = Date(),
         price: Double = 0.0,
         tag: Tag = .other,
         notes: [String]? = nil,
         image: UIImage = UIImage())
    {
        self.name = name
        self.paid = paid
        self.date = date
        self.price = price
        self.tag = tag
        self.notes = notes
        self.image = image
    }
    
    var body: some View
    {
        HStack
        {
            ZStack
            {
                ImageRecognize(
                    image: imageConverted(),
                    price: $price,
                    date: $date,
                    name: $name,
                    notes: $notes
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
                                      text: $name)
                                .padding()
                            
                            DatePicker("Enter Date",
                                       selection: $date,
                                       displayedComponents: .date)
                                .padding()
                            
                            Picker("Select Tag",
                                   selection: $tag)
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
                                          value: $price,
                                          formatter: Transaction().priceFormatter)
                                    .keyboardType(.decimalPad)
                            }
                                .padding()
                            
                            Toggle("Paid",
                                   isOn: $paid)
                                .padding()
                                .toggleStyle(GlassmorphismToggleStyle())
                            
                            TextEditor(
                                text: Binding(get:
                                            { notes?.joined(separator: "\n") ?? "" },
                                         set:
                                            { newValue in
                                            notes = newValue.split(separator: "\n").map { String($0) }
                                            }
                                             ))
                                .padding()
                                .frame(minHeight: 150)
                                .overlay(Text("Enter Notes")
                                            .foregroundColor(.gray)
                                            .opacity(notes?.isEmpty ?? true ? 0.5 : 0)
                                            .padding(.top, 25)
                                            .padding(.leading, 20),
                                         alignment: .topLeading)
                            
                            Button(action: { showUploadMethodAlert = true })
                            {
                                Text("Select Image")
                            }
                                .padding()
                                .alert("Upload Receipt Image", isPresented: $showUploadMethodAlert) {
                                    Button("Use Camera", action: {
                                        self.showChosenMethod = true
                                        chosenUploadMethod = .camera
                                    })
                                    
                                    Button("Photo Album", action: {
                                        self.showChosenMethod = true
                                        chosenUploadMethod = .photoLibrary
                                    })
                                    
                                    Button("Cancel", action: {})
                                }
                                .sheet(isPresented: $showChosenMethod) {
                                    ImagePicker(selectedImage: $image, sourceType: chosenUploadMethod)
                                }
                        }
                        header: {
                            Text("Transaction Record")
                                .padding(2)
                                .background(
                                    RoundedRectangle(cornerRadius: 1)
                                        .fill(.thinMaterial)
                                        .blur(radius: 8))
                        }
                        .listRowBackground(Color.clear)
                        .plainFill()
                        .foregroundColor(.primary)
                    }
                    .plainFill(material: .ultraThinMaterial, opacity: 0.4, cornerRadius: 20)
                    .scrollContentBackground(.hidden)
                    
                    HStack
                    {
                        Button(action:{
                            saveTransaction(date: date,
                                            name: name,
                                            tag: tag.rawValue,
                                            price: price,
                                            paid: paid,
                                            notes: notes,
                                            image: toData(from: image))
                            dismiss()
                            })
                        {
                            HStack
                            {
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
                        }
                            .layoutPriority(2)
                            .buttonStyle(ScaleButtonStyle())
                        
                        Button(action: {
                            dismiss()
                            })
                        {
                            HStack
                            {
                                Text("Cancel")
                                    .font(.headline)
                            }
                                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: 50)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(.thinMaterial)
                                        .blur(radius: 4))
                                .foregroundColor(.accentColor)
                                .cornerRadius(10)
                                .padding(.horizontal)
                        }
                            .layoutPriority(2)
                            .buttonStyle(ScaleButtonStyle())
                    }
                }
                    .padding(20)
            }
                .scrollContentBackground(.hidden)
        }
            .colorfulAccentBackground(colorLinear: [.white, .white, .accentColor], colorRadial: [.accentColor, .white])
    }
}

#Preview {
    AddNew()
}
