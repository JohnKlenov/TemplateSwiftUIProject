//
//  GalleryView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 18.10.24.
//

import SwiftUI
//
//struct ModalView:View {
//    var body: some View {
//        ZStack {
//            Color.green
//                .ignoresSafeArea()
//            Text("I'm ModalView")
//                .font(.system(.largeTitle, design: .default, weight: .regular))
//        }
//    }
//}



struct GalleryView: View {
    @State private var isPresentingAlert = false
    @State private var isPresentingSheet = false
    
    var body: some View {
        VStack {
            Button("Show Sheet") {
                isPresentingSheet = true
            }
        }
        .sheet(isPresented: $isPresentingSheet) {
            ModalView(isPresentingAlert: $isPresentingAlert)
                .alert(isPresented: $isPresentingAlert) {
                    Alert(title: Text("Alert"), message: nil, dismissButton: .default(Text("OK")))
                }
        }
    }
}

struct ModalView: View {
    @Binding var isPresentingAlert: Bool
    
    var body: some View {
        VStack {
            Button("Show Alert") {
                isPresentingAlert = true
            }
        }
    }
}




//struct GalleryView: View {
//    
////    @State var isPresentingAlert = false
////        @State var isPresentingSheet = false
////        
////        var body: some View {
////            VStack {
////                Button("Show Sheet") {
////                    isPresentingSheet = true
////                }
////            }
////            .alert("Alert", isPresented: $isPresentingAlert) {}
////            .sheet(isPresented: $isPresentingSheet) {
////                Button("Show Alert") {
////                    isPresentingAlert = true
////                }
////            }
////        }
//    
//    @State var isShowModal:Bool = false
//    
//    init() {
//        print("GalleryView init")
//    }
//    var body: some View {
//        ZStack {
//            Color.pink
//                .ignoresSafeArea()
//            VStack(spacing:20) {
//                Text("I'm Gallery")
//                    .font(.system(.largeTitle, design: .default, weight: .regular))
//                Button("AddModal", role: .none) {
//                    isShowModal.toggle()
//                }
//            }
//            
//        }
//        .onAppear(perform: {
//            print("GalleryView onAppear")
//        })
////        .fullScreenCover(isPresented: $isShowModal) { ModalView() }
//        .sheet(isPresented: $isShowModal) {
//            ModalView()
//        }
//    }
//}

#Preview {
    GalleryView()
}

