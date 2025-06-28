//
//  LifeCycleView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 28.06.25.
//

import SwiftUI



// MARK: - LifeCycleView -


//Как SwiftUI работает с View:

///View — это структуры, они легковесны и часто пересоздаются
///init вызывается часто: При изменении родительского View, обновлении @State, изменении в NavigationStack и т.д.
///body пересчитывается ещё чаще: На каждый измененный @Published, @State, @Binding или внешний параметр



//1. Когда создается View (init срабатывает):
///При первом появлении на сцене:
///При изменении входных параметров:  struct MyView: View { let id: Int // ← Если это значение изменится, View пересоздастся init(id: Int) { print("Init") } }
///При изменении структуры родительского View: Если родитель полностью перестраивается и "забывает" о дочерней View


//2. Когда перерисовывается body (без пересоздания View):
///При изменении наблюдаемых свойств:  @State, @StateObject, @ObservedObject, @EnvironmentObject @State private var counter = 0 // При изменении counter вызовется body, но init НЕ сработает
///При изменении окружения (@Environment):
///При получении новых данных через Binding
///
///Обертка    Влияние на перерисовку    Сохраняется ли при перерисовках
///
///@State    Вызывает перерисовку body при изменении    ✅ Да (SwiftUI сохраняет значение)
///@StateObject    Вызывает перерисовку при изменении @Published    ✅ Да (живет дольше View)
///@ObservedObject    Вызывает перерисовку при изменении    ❌ Нет (управляется извне)
///@EnvironmentObject    Вызывает перерисовку при изменении    ✅ Да (живет в Environment)
///@Published (в VM)    Сообщает View об изменениях данных    -

//struct SignUpViewInjectedTest: View {
//    @StateObject private var viewModel: SignUpViewModel
//    
//    init(authorizationManager: AuthorizationManager) {
//        // ✅ Это выполнится только при ПЕРВОМ создании View
//        _viewModel = StateObject(wrappedValue: SignUpViewModel(...))
//    }
//    
//    var body: some View {
//        // ❗️Это может вызываться многократно при:
//        // - Изменении viewModel.email/viewModel.password
//        // - Изменении окружения
//        // - Обновлении родительского View
//        SignUpView(viewModel: viewModel)
//    }
//}


//Главные правила:
///init View срабатывает при реальном добавлении в иерархию
///body срабатывает при любом изменении данных, от которых зависит View
///@StateObject гарантирует, что объект живет дольше, чем сама View-структура




// MARK: - _printChanges():


//Как отличить инициализацию от перерисовки:

///Если в логах есть @identity → View была пересоздана
///Если только @self → SwiftUI перерисовал ту же самую View
///Если указаны конкретные свойства (_viewModel, _someState) → триггером было изменение данных
///Если видите частые @identity changed — это повод проверить, не пересоздается ли View неожиданно.



//var body: some View {
//    let _ = Self._printChanges()
//    // остальной код View...
//}


//Сценарий 1: Первая инициализация View
//MyView: @self, @identity changed.
///View создается впервые (@self - изменилась сама структура)
///@identity - изменился идентификатор View в иерархии


//Сценарий 2: Перерисовка без пересоздания
//MyView: @self changed.
///Или (если изменились конкретные зависимости):
//MyView: _someState changed.
///View не пересоздавалась, но изменились какие-то данные (@State, @Published и т.д.)


//3. Пример с вашим SignUpViewInjected:


//struct SignUpViewInjected: View {
//    @StateObject private var viewModel: SignUpViewModel
//    
//    init(authorizationManager: AuthorizationManager) {
//        print("SignUpViewInjected INIT")
//        _viewModel = StateObject(wrappedValue: SignUpViewModel(authorizationManager: authorizationManager))
//    }
//    
//    var body: some View {
//        let _ = Self._printChanges()
//        SignUpView(viewModel: viewModel)
//    }
//}

//При первом открытии:
//SignUpViewInjected INIT
//SignUpViewInjected: @self, @identity changed.

//При обновлении viewModel.email:
//SignUpViewInjected: _viewModel changed.


//SignUpViewInjected: @self changed.
// SwiftUI перерисовывает View, но не пересоздает ее полностью.



//Идеальная отладочная настройка:

//struct SignUpViewInjected: View {
//    @StateObject private var viewModel: SignUpViewModel
//    
//    init(authorizationManager: AuthorizationManager) {
//        print("✅ SIGNUP VIEW INIT")
//        _viewModel = StateObject(wrappedValue: SignUpViewModel(authorizationManager: authorizationManager))
//    }
//    
//    var body: some View {
//        let _ = print("🔄 SignUpViewInjected body update")
//        let _ = Self._printChanges()
//        
//        SignUpView(viewModel: viewModel)
//    }
//    
//    deinit {
//        print("♻️ SIGNUP VIEW DEINIT")
//    }
//}



//что происходит с @ObservedObject var viewModel в SignUpView при перерисовках.

//struct SignUpViewInjected: View {
//    @StateObject private var viewModel: SignUpViewModel // ← Жизненный цикл здесь!
//    
//    var body: some View {
//        SignUpView(viewModel: viewModel) // ← Всегда передаётся один и тот же экземпляр
//    }
//}

//ри перерисовках SignUpViewInjected:
///@StateObject сохраняет ViewModel
///В SignUpView всегда приходит та же самая ViewModel
///Состояние (введённые данные) не теряется

//При перерисовках самого SignUpView:
///Так как ViewModel одна и та же, @ObservedObject просто подписывается на её изменения
///Если в VM меняется email/password → перерисовывается body
///Сама ViewModel не пересоздаётся
