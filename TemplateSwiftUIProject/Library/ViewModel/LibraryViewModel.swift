//
//  LibraryViewModel.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 21.11.2026.
//


import SwiftUI

@MainActor
final class LibraryViewModel: ObservableObject {

    // MARK: - Dependencies

    private let alertManager: AlertManager

    // MARK: - Initialization

    init(
        alertManager: AlertManager
    ) {
        self.alertManager = alertManager
    }
}
