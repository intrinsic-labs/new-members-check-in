//
//  SuccessToast.swift
//  New Members Check In
//
//  Created by Asher Pope on 1/13/23.
//

import SwiftUI

class ToastModel: ObservableObject {
    @Published var isPresented = false
}


struct SuccessToast: View {
    @State var toastModel: ToastModel
    
    var body: some View {
        VStack {
            Image(systemName: "checkmark.circle")
                .resizable()
                .frame(width: 50, height: 50)
                .foregroundColor(Color(hex: "#95B893"))
            Text("Thanks for checking in!")
                //.font(.headline)
                .foregroundColor(Color(hex: "1C3040"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 3)
        }
        .padding()
        .frame(width: 150, height: 150)
        .background(.white)
        .cornerRadius(10, antialiased: true)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                withAnimation {
                    toastModel.isPresented.toggle()
                }
            }
        }
    }
}

//
//struct SuccessToast_Previews: PreviewProvider {
//    static var previews: some View {
//        SuccessToast()
//    }
//}

