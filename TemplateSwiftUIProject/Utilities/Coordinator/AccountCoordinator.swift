//
//  AccountCoordinator.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 17.04.25.
//

import SwiftUI


class AccountCoordinator:ObservableObject {
    
    @Published var path: NavigationPath = NavigationPath() {
        didSet {
            print("NavigationPath updated: \(path.count)")
        }
    }
    @Published var sheet:SheetItem? {
        didSet {
            print("sheet updated: \(String(describing: sheet))")
        }
    }
    @Published var fullScreenItem:FullScreenItem?
    
    func navigateTo(page:AccountFlow) {
        path.append(page)
    }
    
    func pop() {
        path.removeLast()
    }
    
    func popToRoot() {
        path = NavigationPath()
    }
    
    func presentSheet(_ sheet: SheetItem) {
        self.sheet = sheet
    }
    
    func presentFullScreenCover(_ cover: FullScreenItem) {
        self.fullScreenItem = cover
    }
    
    func dismissSheet() {
        self.sheet = nil
    }
    
    func dismissCover() {
        self.fullScreenItem = nil
    }
}
