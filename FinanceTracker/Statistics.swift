//
//  Statistics.swift
//  FinanceTracker
//
//  Created by Lucas Hsu on 1/31/25.
//

import SwiftUI
import SwiftData
import Charts

struct Statistics: View {
    @State var dateStart: Date = (Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date())
    @State var dateEnd: Date = Date()
    
    // Assuming you have a @Query to fetch your transactions from the SwiftData store
    @Query(sort: \Transaction.date, order: .reverse) var transactions: [Transaction]
    
    @State private var selectedTags: Set<String> = Set(Tag.allCases.map { $0.rawValue })
    @State private var isUnpaid: Bool = false;
    
    
    var body: some View {
        
        VStack {
            Text("Statistics Page")
                .font(.largeTitle)
                .foregroundColor(.black)
            Text("Bar")
            HStack {
                ForEach(Tag.allCases, id: \.self) { tag in
                    Image(systemName: symbolRepresentation[tag] ?? "questionmark")
                        .padding()
                        .frame(width: 80, height: 50)
                        .background(self.selectedTags.contains(tag.rawValue) ? Color.accentColor : Color.gray.opacity(0.2))
                        .cornerRadius(8)
                        .foregroundColor(self.selectedTags.contains(tag.rawValue) ? .white : .secondary)
                        .onTapGesture {
                            // Toggle selection on tap
                            if self.selectedTags.contains(tag.rawValue) {
                                self.selectedTags.remove(tag.rawValue)
                            } else {
                                self.selectedTags.insert(tag.rawValue)
                            }
                        }
                }
            }
            .padding()
            Toggle("Show Only Payment Pending", isOn: $isUnpaid)
                .toggleStyle(ButtonToggleStyle())
                        .scaleEffect(isUnpaid ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: isUnpaid)
            Form{
                DatePicker("Start Date", selection: $dateStart)
                DatePicker("End Date", selection: $dateEnd)
            }
        }
    }
}



struct Statistics_Previews: PreviewProvider {
    static var previews: some View {
        Statistics()
    }
}
