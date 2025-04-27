//
//  GlobalRetryHandler.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 27.04.25.
//



// MARK: - NotificationCenter
///связь между AlertViewGlobal и HomeContentViewModel с использованием NotificationCenter:

///extension Notification.Name { static let authenticationRetry = Notification.Name("authenticationRetry") }
/// Button(alertButtonText) { if alertType == .authentication {  NotificationCenter.default.post(name: .authenticationRetry, object: nil) } }
/// class HomeContentViewModel: HomeViewModelProtocol { init() { } }
/// NotificationCenter.default.addObserver(self,selector:#selector(handleAuthenticationRetryNotification(_:)),name:.authenticationRetry,object: nil)

///NotificationCenter — это практичный и оправданный компромисс, если у тебя уже сложилась архитектура, где передача события через несколько слоев иначе стала бы слишком запутанной. Главное — использовать его контролируемо, документировать и ограничивать область применения, чтобы не превратить его в универсальное средство для межкомпонентного общения. Таким образом, в твоем случае это может стать продуманным решением, а не грязным обходным путём.




import SwiftUI

//специализированный (Well-defined scope) сервис отвечающий только за хранение и вызов замыканий для retry-операций.
//Well-defined scope — это чётко обозначенная область ответственности или применения.

final class GlobalRetryHandler: ObservableObject {
    private var currentRetryHandler: (() -> Void)? = nil {
        didSet {
            print("currentRetryHandler - \(String(describing: currentRetryHandler))")
        }
    }
    
    // Устанавливаем обработчик с автоматическим weak захватом
    func setAuthenticationRetryHandler(_ handler: @escaping () -> Void) {
        currentRetryHandler = { [weak self] in
            handler()
            self?.clearRetryHandler()
        }
    }
    
    func triggerRetry() {
        currentRetryHandler?()
    }
    
    func clearRetryHandler() {
        currentRetryHandler = nil
    }
}
