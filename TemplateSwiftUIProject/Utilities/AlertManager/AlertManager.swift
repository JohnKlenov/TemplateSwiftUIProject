//
//  AlertManager.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 2.12.24.
//


///Глобальные алерты: Используются для критических ошибок, которые могут затронуть весь функционал приложения. Эти алерты управляются на уровне корневого представления.
///Локальные алерты: Используются для ошибок, специфичных для текущего представления или действия. Эти алерты управляются непосредственно в представлении, где происходит ошибка.

import Foundation
import Combine

protocol AlertManagerProtocol {
    var globalAlert:AlertData? { get set }
    var localAlerts: [String:AlertData] { get set }
    func showGlobalAlert(message:String)
    func showLocalalAlert(message:String, forView view: String)
    func resetGlobalAlert()
    func resetLocalAlert(forView view: String)
}

struct AlertData {
    let message:String
}

class AlertManager: AlertManagerProtocol {
    
    static let shared = AlertManager()
    
    private init() {}
    
    var globalAlert: AlertData?
    var localAlerts: [String : AlertData] = [:]
    
    func showGlobalAlert(message: String) {
        globalAlert = AlertData(message: message)
    }
    
    func showLocalalAlert(message: String, forView view: String) {
        localAlerts[view] = AlertData(message: message)
    }
    
    func resetGlobalAlert() {
        globalAlert = nil
    }
    
    /// если View  исчезает из памяти до того как отработает алерт мы должны вызвать func resetLocalAlert до его исчезнавения???
    func resetLocalAlert(forView view: String) {
        localAlerts[view] = nil
    }
    
}
