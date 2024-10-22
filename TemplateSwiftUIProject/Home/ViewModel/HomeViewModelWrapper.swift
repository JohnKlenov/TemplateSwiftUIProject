//
//  HomeViewModelWrapper.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 21.10.24.
//

import Combine

// Это может быть не лучшее решение!

///SwiftUI не позволяет напрямую использовать протоколы с @StateObject или @ObservedObject (SwiftUI управляет состоянием и жизненным циклом объектов).
///Как это обойти? - Обертка AnyViewModelWrapper позволяет использовать протоколы с @StateObject или @ObservedObject в SwiftUI, сохраняя возможность Dependency Injection. Это гибкий и тестируемый подход, который решает проблемы типизации.

///Основная проблема: SwiftUI требует, чтобы объект, передаваемый в @StateObject или @ObservedObject, строго соответствовал типу ObservableObject. Но Swift не позволяет использовать протоколы, такие как HomeViewModelProtocol, напрямую с @StateObject или @ObservedObject.
/// Решение: ViewModelWrapper оборачивает любой объект, который соответствует протоколу HomeViewModelProtocol, и преобразует его в ObservableObject. Это позволяет нам сохранить возможность Dependency Injection (DI) и использовать протоколы для тестирования и гибкости.
//class HomeViewModelWrapper: ObservableObject {
//    @Published private var wrapped: any HomeViewModelProtocol
//
//    init(wrapped: any HomeViewModelProtocol) {
//        self.wrapped = wrapped
//        
//    }
//
//    var data: [String] {
//        return wrapped.data
//    }
//
//    var isLoading: Bool {
//        return wrapped.isLoading
//    }
//
//    var errorMessage: String? {
//            get {
//                return wrapped.errorMessage
//            }
//            set {
//                wrapped.errorMessage = newValue
//            }
//        }
////    var errorMessage: String? {
////        return wrapped.errorMessage
////    }
//
//    func retry() {
//        wrapped.retry()
//    }
//    
//}
