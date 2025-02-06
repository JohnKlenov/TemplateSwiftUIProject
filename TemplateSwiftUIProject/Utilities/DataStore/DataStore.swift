//
//  DataStore.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 5.02.25.
//

import SwiftUI


class DataStore:ObservableObject {
    var homeBookDataStore = HomeBookDataStore()
}


class HomeBookDataStore: ObservableObject {
    @Published var books:[BookCloud] = []
}
