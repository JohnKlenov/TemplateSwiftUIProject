//
//  AlertManager.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 2.12.24.
//


///Глобальные алерты: Используются для критических ошибок, которые могут затронуть весь функционал приложения. Эти алерты управляются на уровне корневого представления.
///Локальные алерты: Используются для ошибок, специфичных для текущего представления или действия. Эти алерты управляются непосредственно в представлении, где происходит ошибка.

///На iOS система не позволяет одновременно отображать два алерта. Если второй алерт будет вызван, пока первый алерт уже отображается, второй алерт не появится до тех пор, пока первый не будет закрыт.




// MARK: - new solution with notification  - 
import Foundation
import Combine

protocol AlertManagerProtocol: ObservableObject {
    var globalAlert: AlertData? { get set }
    var localAlerts: [String: AlertData] { get set }
    func showGlobalAlert(message: String)
    func showLocalalAlert(message: String, forView view: String)
    func resetGlobalAlert()
    func resetLocalAlert(forView view: String)
}

struct AlertData {
    let message: String
}

class AlertManager: AlertManagerProtocol {
    
    static let shared = AlertManager()
    
    private init() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
            self?.showGlobalAlert(message: "Test Global Alert")
        }
    }
    
    var globalAlert: AlertData? {
        didSet {
            print("didSet globalAlert")
        }
    }
    @Published var localAlerts: [String: AlertData] = [:] {
        didSet {
            print("didSet localAlerts")
        }
    }
    
    func showGlobalAlert(message: String) {
        globalAlert = AlertData(message: message)
        NotificationCenter.default.post(name: .globalAlert, object: globalAlert)
    }
    
    func showLocalalAlert(message: String, forView view: String) {
        localAlerts[view] = AlertData(message: message)
    }
    
    func resetGlobalAlert() {
        globalAlert = nil
    }
    
    func resetLocalAlert(forView view: String) {
        localAlerts[view] = nil
    }
}

extension Notification.Name {
    static let globalAlert = Notification.Name("globalAlert")
}



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




