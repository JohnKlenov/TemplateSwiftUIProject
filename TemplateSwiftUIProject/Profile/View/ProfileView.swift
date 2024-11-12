//
//  ProfileView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 18.10.24.
//

import SwiftUI

struct ProfileView: View {
    
    @State private var searchText = ""
    let items = ["Apple", "Banana", "Cherry", "Date", "Fig", "Grape"]
    var filteredItems: [String] {
        if searchText.isEmpty {
            return items
        } else {
            return items.filter { $0.contains(searchText) }
        }
    }
    
    init() {
        print("ProfileView init")
    }
    var body: some View {
        
        NavigationStack {
            List(filteredItems, id: \.self) { item in
                Text(item)
            }
            .navigationTitle("Fruits")
            .searchable(text: $searchText, prompt: "Search fruits")
        }
    }
}

#Preview {
    ProfileView()
}
