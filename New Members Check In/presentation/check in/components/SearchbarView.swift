//
//  SearchbarView.swift
//  New Members Check In
//
//  Created by Asher Pope on 1/13/23.
//

import SwiftUI

@MainActor
class SearchbarModel: ObservableObject {
    @Published var searchText = ""
}

struct Searchbar: View {
    @ObservedObject var searchModel: SearchbarModel
    @FocusState private var currentFocus: KeyboardFocus?
    
    var body: some View {
        HStack {
            Text(Image(systemName: "magnifyingglass"))
                .foregroundColor(.white.opacity(0.5))

            TextField("", text: $searchModel.searchText, prompt: Text("Search").foregroundColor(.white.opacity(0.75)))
                .foregroundColor(.white)
                .focused($currentFocus, equals: .searchbar)
            
            Button("\(Image(systemName: "xmark"))") {
                searchModel.searchText = ""
                currentFocus = nil
            }.tint(.white.opacity(currentFocus == .searchbar ? 0.5 : 0))
        }
        .padding()
        .frame(height: 50)
        .background(Color(hex: "354959"))
        .cornerRadius(10, antialiased: true)
        .onSubmit {
            currentFocus = nil
        }
    }
}

struct Searchbar_Preview: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

