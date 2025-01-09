//
//  SheetManager.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 8.12.24.
//

import Foundation
import Combine

///@StateObject используется для инициализации и хранения объекта, который будет использоваться для управления состоянием представления. Сохраняться на протяжении всего жизненного цикла представления и не теряеьт свои данные при перерисовках.
///@StateObject гарантирует, что объект будет жить столько, сколько живет представление, и будет удален, когда представление больше не нужно. Это помогает избежать утечек памяти.

///когда к примеру в .sheet(isPresented: $sheetManager.isPresented) блок set в binding возвращает false то значение isPresented автоматически изменится на false

///Binding<Bool>( get: { .. }, set: { .. } )





protocol SheetManagerProtocol: ObservableObject {
    var isPresented:Bool { get set }
    func showSheet()
    func hideSheet()
}

/// так как modalView перекрывает все View а так же TabBar то можго оставить SheetManager один на все modalView
class SheetManager: SheetManagerProtocol {
    @Published var isPresented: Bool = false {
        didSet {
            print("didSet isPresented - \(isPresented)")
        }
    }
    
    static let shared = SheetManager()
    
    func showSheet() {
        isPresented = true
    }
    
    func hideSheet() {
        isPresented = false
    }
}

// MARK: - before correct initialization of the state -


//protocol SheetManagerProtocol: ObservableObject {
//    var isPresented:Bool { get set }
//    func showSheet()
//    func hideSheet()
//}
//
//
//class SheetManager: SheetManagerProtocol {
//    @Published var isPresented: Bool = false
//    
//    func showSheet() {
//        isPresented = true
//    }
//    
//    func hideSheet() {
//        isPresented = false
//    }
//}
