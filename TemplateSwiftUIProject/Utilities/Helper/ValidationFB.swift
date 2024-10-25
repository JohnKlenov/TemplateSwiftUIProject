//
//  Validation.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 19.10.24.
//

import Foundation



struct PathValidator {
    static func validateCollectionPath(_ path:String) -> Bool {
        let pathComponent = path.split(separator:"/")
        return pathComponent.count % 2 != 0
    }
}


