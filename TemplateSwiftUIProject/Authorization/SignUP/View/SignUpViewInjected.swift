//
//  SignUpViewInjected.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 20.06.25.
//


///@EnvironmentObject не приводит к ререндеру, пока ты не используешь его свойства в body
///Создание viewModel = SignUpViewModel(...) произойдёт только при первом вызове body, если ты не полагаешься на обновляемые свойства authManager прямо в body

//@ObservedObjec vs @StateObject

///Вывод:
///@ObservedObject просто наблюдает за объектом, но не владеет им. Жизненный цикл VM — там, где ты его создаёшь (в body SignUpEntryView).
///При переходе вперёд VM не сбрасывается и сидит в памяти, пока экран находится в сте­ке.
///При полном удалении из стека и повторном вталкивании — создаётся новый экземпляр.
///Если бы ты использовал @StateObject прямо в SignUpView (и создавал VM там), то при повторном пуше SignUp ты всё равно бы получал новый экземпляр, но ререндеры внутри экрана не воссоздали бы его дважды.
///Как правило, когда VM должна хранить своё состояние между перерисовками одного экрана, её помечают @StateObject. Когда VM приходит извне и живёт столько, сколько живёт экран в навигации, — @ObservedObject. В твоём случае SignUpEntryView создаёт VM один раз при пуше, дальше SwiftUI больше его не пересоздаёт при внутренних ререндерингах.

/*
 ┌────────────────────┬──────────────────────────────┬──────────────────────────────┬─────────────────────────────┐
 │     Свойство       │ Контроль над временем жизни  │ Пересоздание при ререндере   │ Создание ViewModel внутри   │
 ├────────────────────┼──────────────────────────────┼──────────────────────────────┼─────────────────────────────┤
 │ @StateObject       │ ✅ View владеет               │ ❌ Не пересоздаётся           │ ✅ Да                        │
 │ @ObservedObject    │ ❌ View только наблюдает      │ 🔁 Зависит от места создания  │ ❌ Нет                       │
 └────────────────────┴──────────────────────────────┴──────────────────────────────┴─────────────────────────────┘

 Пояснение:
 • @StateObject — используется тогда, когда View сама создаёт и владеет ViewModel.
     Он сохраняется между ререндерингами, инициализируется ровно один раз.

 • @ObservedObject — используется, когда ViewModel создаётся снаружи и передаётся внутрь View.
     View не владеет моделью и не контролирует её создание. Подходит для инъекции зависимостей или родительской координации.
*/



import SwiftUI

struct SignUpViewInjected: View {
    @StateObject private var viewModel: SignUpViewModel
    
    init(authorizationManager: AuthorizationManager) {
        print("init SignUpViewInjected")
        let _ = Self._printChanges()
        _viewModel = StateObject(
            wrappedValue: SignUpViewModel(
                authorizationManager: authorizationManager
            )
        )
    }
    
    var body: some View {
        SignUpView(viewModel: viewModel)
    }
}


//import SwiftUI
//
//struct ReauthenticateViewInjected: View {
//    @StateObject private var viewModel: ReauthenticateViewModel
//    
//    init(authorizationManager: AuthorizationManager) {
//        print("init SignUpViewInjected")
//        let _ = Self._printChanges()
//        _viewModel = StateObject(
//            wrappedValue: ReauthenticateViewModel(
//                authorizationManager: authorizationManager
//            )
//        )
//    }
//    
//    var body: some View {
//        ReauthenticateView(viewModel: viewModel)
//    }
//}
//
//import SwiftUI
//import Combine
//
////@MainActor
//class ReauthenticateViewModel: ObservableObject {
//    @Published var email: String = ""
//    @Published var password: String = ""
//    
//    @Published var emailError: String?
//    @Published var passwordError: String?
//    
//    @Published var registeringState: AuthorizationManager.State = .idle
//    
//
//    private let authorizationManager: AuthorizationManager
//    private var cancellables = Set<AnyCancellable>()
//    
//
//    init(authorizationManager: AuthorizationManager) {
//        self.authorizationManager = authorizationManager
//        print("init SignUpViewModel")
//       
//        authorizationManager.$state
//            .handleEvents(receiveOutput: { print("→ SignUpViewModel подписка получила:", $0) })
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] state in
//                self?.registeringState = state
//            }
//            .store(in: &cancellables)
//    }
//    
//    func reauthenticate() {
//        authorizationManager.reauthenticate(email: email, password: password)
//        
//    }
//    
//    deinit {
//        cancellables.removeAll()
//        print("deinit SignUpViewModel")
//    }
//}
