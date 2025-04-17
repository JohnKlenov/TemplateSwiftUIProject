//
//  AlertManager.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 2.12.24.
//


///Глобальные алерты: Используются для критических ошибок, которые могут затронуть весь функционал приложения. Эти алерты управляются на уровне корневого представления.
///Локальные алерты: Используются для ошибок, специфичных для текущего представления или действия. Эти алерты управляются непосредственно в представлении, где происходит ошибка.

///На iOS система не позволяет одновременно отображать два алерта. Если второй алерт будет вызван, пока первый алерт уже отображается, второй алерт не появится до тех пор, пока первый не будет закрыт.

// MARK: - a new understanding of how bindingError works -

import SwiftUI
import Combine

protocol AlertManagerProtocol: ObservableObject {
    var globalAlert: [String: [AlertData]] { get set }
    var localAlerts: [String: [AlertData]] { get set }
    var isHomeViewVisible: Bool { get set }
    func showGlobalAlert(message: String, operationDescription: String)
    func showLocalalAlert(message: String, forView view: String, operationDescription: String)
    func resetFirstLocalAlert(forView view: String)
    func resetFirstGlobalAlert()
}

//struct AlertData: Identifiable {
//    let id = UUID()
//    let message: String
//    let operationDescription: String
//}

struct AlertData: Identifiable, Equatable {
    let id = UUID()
    let message: String
    let operationDescription: String

    static func == (lhs: AlertData, rhs: AlertData) -> Bool {
        return lhs.id == rhs.id
    }
}


class AlertManager: AlertManagerProtocol {
    
    static let shared = AlertManager()
    
    @Published var globalAlert: [String: [AlertData]] = [:] {
        didSet {
            print("didSet globalAlert")
        }
    }
    
    @Published var localAlerts: [String: [AlertData]] = [:] {
        didSet {
            print("didSet localAlerts")
        }
    }
    
    @Published var isHomeViewVisible: Bool = false { // Добавляем флаг для отслеживания видимости HomeView
        didSet {
            print("didSet isHomeViewVisible")
        }
    }
    
    @Published var isGalleryViewVisible: Bool = false { // Добавляем флаг для отслеживания видимости GalleryView
        didSet {
            print("didSet isGalleryViewVisible")
        }
    }
    
    @Published var isAccountViewVisible: Bool = false { // Добавляем флаг для отслеживания видимости AccountView
        didSet {
            print("didSet isAccountViewVisible")
        }
    }
    
    func showGlobalAlert(message: String, operationDescription: String) {
        let alert = AlertData(message: message, operationDescription: operationDescription)
        
        if globalAlert["globalError"] == nil {
            globalAlert["globalError"] = [alert]
        } else {
            globalAlert["globalError"]?.append(alert)
        }
    }
    
    func showLocalalAlert(message: String, forView view: String, operationDescription: String) {
        
        let alert = AlertData(message: message, operationDescription: operationDescription)
        
        if localAlerts[view] == nil {
            localAlerts[view] = [alert]
        } else if !localAlerts[view]!.contains(where: { $0.operationDescription == operationDescription }) {
            localAlerts[view]?.append(alert)
        }
    }
    
    func resetFirstLocalAlert(forView view: String) {
        if var alerts = localAlerts[view], !alerts.isEmpty {
            alerts.removeFirst()
            if alerts.isEmpty {
                print("localAlerts[view] = nil")
                localAlerts[view] = nil
            } else {
                print("localAlerts[view] = alerts")
                localAlerts[view] = alerts
            }
        }
    }
    
    func resetFirstGlobalAlert() {
        if var alerts = globalAlert["globalError"], !alerts.isEmpty {
            alerts.removeFirst()
            if alerts.isEmpty {
                print("globalAlert[globalError] = nil")
                globalAlert["globalError"] = nil
            } else {
                print("globalAlert[globalError] = alerts")
                globalAlert["globalError"] = alerts
            }
        }
    }
}

extension Notification.Name {
    static let globalAlert = Notification.Name("globalAlert")
}




//    func showGlobalAlert(message: String, operationDescription: String) {
//        let alert = AlertData(message: message, operationDescription: operationDescription)
//        globalAlert = alert
//        NotificationCenter.default.post(name: .globalAlert, object: alert)
//    }

//func isErrorForView(forView:String) -> Bool {
//    return self.localAlerts[forView] != nil
//}

// MARK: - new solution with func resetFirstLocalAlert -

//import Foundation
//import Combine
//
//protocol AlertManagerProtocol: ObservableObject {
//    var globalAlert: AlertData? { get set }
//    var localAlerts: [String: [AlertData]] { get set }
//    func showGlobalAlert(message: String, operationDescription: String)
//    func showLocalalAlert(message: String, forView view: String, operationDescription: String)
//    func resetGlobalAlert()
//    func resetLocalAlert(forView view: String)
//    func resetFirstLocalAlert(forView view: String)
//}
//
////struct AlertData: Identifiable {
////    let id = UUID()
////    let message: String
////    let operationDescription: String
////}
//
//struct AlertData: Identifiable, Equatable {
//    let id = UUID()
//    let message: String
//    let operationDescription: String
//
//    static func == (lhs: AlertData, rhs: AlertData) -> Bool {
//        return lhs.id == rhs.id
//    }
//}
//
//
//class AlertManager: AlertManagerProtocol {
//    static let shared = AlertManager()
//    
//    @Published var globalAlert: AlertData? {
//        didSet {
//            print("didSet globalAlert")
//        }
//    }
////    @Published
//    @Published var localAlerts: [String: [AlertData]] = [:] {
//        didSet {
//            print("didSet localAlerts")
//        }
//    }
//    
//    @Published var showLocalAlert:Bool = false
//    
//    func showGlobalAlert(message: String, operationDescription: String) {
//        let alert = AlertData(message: message, operationDescription: operationDescription)
//        globalAlert = alert
//        NotificationCenter.default.post(name: .globalAlert, object: alert)
//    }
//    
//    func showLocalalAlert(message: String, forView view: String, operationDescription: String) {
//        let sharedMessage = operationDescription + message
//        let alert = AlertData(message: sharedMessage, operationDescription: operationDescription)
//        if localAlerts[view] != nil {
//            localAlerts[view]?.append(alert)
//        } else {
//            localAlerts[view] = [alert]
//        }
//    }
//    
//    func resetGlobalAlert() {
//        globalAlert = nil
//    }
//    
//    func resetLocalAlert(forView view: String) {
//        localAlerts[view] = nil
//    }
//
//    func resetFirstLocalAlert(forView view: String) {
//        if var alerts = localAlerts[view], !alerts.isEmpty {
//            alerts.removeFirst()
//            if alerts.isEmpty {
//                print("localAlerts[view] = nil")
//                localAlerts[view] = nil
//            } else {
////                showLocalAlert = true
//                print("localAlerts[view] = alerts")
//                localAlerts[view] = alerts
//            }
//        }
//    }
//}
//
//extension Notification.Name {
//    static let globalAlert = Notification.Name("globalAlert")
//}



// MARK: - new solution with notification  - 
//import Foundation
//import Combine
//
//protocol AlertManagerProtocol: ObservableObject {
//    var globalAlert: AlertData? { get set }
//    var localAlerts: [String: AlertData] { get set }
//    func showGlobalAlert(message: String)
//    func showLocalalAlert(message: String, forView view: String)
//    func resetGlobalAlert()
//    func resetLocalAlert(forView view: String)
//}
//
//struct AlertData {
//    let message: String
//}
//
//class AlertManager: AlertManagerProtocol {
//    
//    static let shared = AlertManager()
//    
//    var globalAlert: AlertData? {
//        didSet {
//            print("didSet globalAlert")
//        }
//    }
//    @Published var localAlerts: [String: AlertData] = [:] {
//        didSet {
//            print("didSet localAlerts")
//        }
//    }
//    
//    func showGlobalAlert(message: String) {
//        globalAlert = AlertData(message: message)
//        NotificationCenter.default.post(name: .globalAlert, object: globalAlert)
//    }
//    
//    func showLocalalAlert(message: String, forView view: String) {
//        localAlerts[view] = AlertData(message: message)
//    }
//    
//    func resetGlobalAlert() {
//        globalAlert = nil
//    }
//    
//    func resetLocalAlert(forView view: String) {
//        localAlerts[view] = nil
//    }
//}
//
//extension Notification.Name {
//    static let globalAlert = Notification.Name("globalAlert")
//}



//    private init() {
//            DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
//                self?.showGlobalAlert(message: "Test Global Alert")
//            }
//    }




// MARK: - old solution -

//import Foundation
//import Combine
//
//protocol AlertManagerProtocol:ObservableObject {
//    var globalAlert:AlertData? { get set }
//    var localAlerts: [String:AlertData] { get set }
//    func showGlobalAlert(message:String)
//    func showLocalalAlert(message:String, forView view: String)
//    func resetGlobalAlert()
//    func resetLocalAlert(forView view: String)
//}
//
//struct AlertData {
//    let message:String
//}
//
//class AlertManager: AlertManagerProtocol {
//    
//    static let shared = AlertManager()
//    //    var isFlag:Bool = true
//    
//    private init() {}
//    
//    @Published var globalAlert: AlertData?
//    @Published var localAlerts: [String : AlertData] = [:] {
//        didSet {
//            print("didSet localAlerts")
//        }
//    }
//    
//    func showGlobalAlert(message: String) {
//        globalAlert = AlertData(message: message)
//    }
//    
//    func showLocalalAlert(message: String, forView view: String) {
//        localAlerts[view] = AlertData(message: message)
//        //        imitationOfRepeatCall()
//    }
//    
//    func resetGlobalAlert() {
//        globalAlert = nil
//    }
//    
//    /// если View  исчезает из памяти до того как отработает алерт мы должны вызвать func resetLocalAlert до его исчезнавения???
//    func resetLocalAlert(forView view: String) {
//        localAlerts[view] = nil
//    }
    
    //    func imitationOfRepeatCall() {
    //        if isFlag {
    //            DispatchQueue.main.asyncAfter(deadline: .now() + 4) { [weak self] in
    //                print("imitationOfRepeatCall")
    //                self?.isFlag.toggle()
    //                self?.showLocalalAlert(message: "imitationOfRepeatCall", forView: "Home")
    //
    //            }
    //        }
    //
    //    }
//}




