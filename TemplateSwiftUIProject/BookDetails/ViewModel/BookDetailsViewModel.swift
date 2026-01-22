//
//  BookDetailsViewModel.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 5.02.25.
//

import SwiftUI

class BookDetailsViewModel:ObservableObject {
    var crudManager: CRUDSManager
    
    init(managerCRUDS: CRUDSManager) {
        print("init BookDetailsViewModel")
        self.crudManager = managerCRUDS
    }
    
    deinit {
        print("deinit BookDetailsViewModel")
    }
}


// MARK: - before BookDetailsViewInjected


//import SwiftUI
//
//class BookDetailsViewModel:ObservableObject {
//    var crudManager: CRUDSManager
//    
//    init(managerCRUDS: CRUDSManager) {
//        print("init BookDetailsViewModel")
//        self.crudManager = managerCRUDS
//    }
//    
//    deinit {
//        print("deinit BookDetailsViewModel")
//    }
//}
