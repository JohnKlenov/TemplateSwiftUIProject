//
//  LibraryCoordinator.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 20.11.2026.
//


import SwiftUI

final class LibraryCoordinator: ObservableObject {

    // MARK: - Navigation

    @Published var path = NavigationPath() {
        didSet {
            print("Library NavigationPath updated: \(path.count)")
        }
    }

    @Published var sheet: SheetItem? {
        didSet {
            print("Library sheet updated: \(String(describing: sheet))")
        }
    }

    @Published var fullScreenItem: FullScreenItem?

    // MARK: - Navigation Methods

    func navigateTo(page: DroplistFlow) {
        path.append(page)
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func popToRoot() {
        path = NavigationPath()
    }

    // MARK: - Presentation

    func presentSheet(_ sheet: SheetItem) {
        self.sheet = sheet
    }

    func presentFullScreenCover(_ cover: FullScreenItem) {
        fullScreenItem = cover
    }

    func dismissSheet() {
        sheet = nil
    }

    func dismissCover() {
        fullScreenItem = nil
    }
}
