//
//  SomeView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 5.02.25.
//

import SwiftUI

struct SomeView: View {
    @EnvironmentObject var homeCoordinator:HomeCoordinator
    @StateObject var viewModel = SomeViewModel()
    
    init() {
        print("init SomeView")
    }
    var body:some View {
        ZStack {
            Color.green.ignoresSafeArea()
            Button("BackToRoot") {
                homeCoordinator.popToRoot()
                print("did tap BackToRoot")
            }
        }
        .onAppear {
            print("onAppear SomeView")
        }
        .onDisappear {
            print("onDisappear SomeView")
        }
    }
}

class SomeViewModel:ObservableObject {
    
    init() {
        print("init SomeViewModel")
    }
    
    deinit {
        print("deinit SomeViewModel")
    }
}
