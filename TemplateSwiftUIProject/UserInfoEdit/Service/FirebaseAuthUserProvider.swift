//
//  FirebaseAuthUserProvider.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 19.10.25.
//

import FirebaseAuth
import Combine


/// FirebaseAuthUserProvider: источник текущего пользователя на базе FirebaseAuth.
/// Как работает по шагам (сценарии):
/// 1) Старт приложения:
///    - Инициализация класса подписывается на Auth.addStateDidChangeListener.
///    - Немедленно эмитится текущее состояние (subject.send(user?.uid)) — это может быть nil или реальный uid.
/// 2) Логин (user != nil):
///    - FirebaseAuth вызовет listener, мы отправим новый uid через subject.
///    - Все подписчики currentUserPublisher получат новый uid.
/// 3) Логаут / удаление аккаунта (user == nil):
///    - Listener получит nil, мы отправим nil через subject.
///    - Подписчики увидят nil и могут сбросить своё состояние, отменить пайплайны и очистить ресурсы.
/// 4) Обновление токена / незначительные изменения пользователя без смены uid:
///    - Listener может сработать, но uid останется тем же: мы просто заново отправим тот же uid.
///    - Если подписчику важно фильтровать одинаковые значения — используйте .removeDuplicates() на стороне потребителя.
/// 5) Быстрая смена пользователей (A → B → A):
///    - Каждый раз listener отправит соответствующий uid (или nil), порядок событий гарантируется FirebaseAuth.
///    - Потребители должны отменять активные операции, привязанные к старому uid.
/// 6) Жизненный цикл:
///    - При деинициализации мы корректно снимаем Auth listener через removeStateDidChangeListener.
///    - Publisher не завершает поток (Never) — он «живёт» пока жив класс.
///
/// Использование:
///   let provider = FirebaseAuthUserProvider()
///   provider.currentUserPublisher   // AnyPublisher<String?, Never>
///   Подпишитесь, чтобы получать uid или nil при изменениях авторизации.
///
///


struct AuthUser {
    let uid: String
    let isAnonymous: Bool
}

protocol CurrentUserProvider {
    /// Паблишер, который эмитит AuthUser или nil при logout/удалении.
    var currentUserPublisher: AnyPublisher<AuthUser?, Never> { get }
}


final class FirebaseAuthUserProvider: CurrentUserProvider {
    private let subject: CurrentValueSubject<AuthUser?, Never>
    private var handle: AuthStateDidChangeListenerHandle?

    init() {
        let initialUser = Auth.auth().currentUser.map { AuthUser(uid: $0.uid, isAnonymous: $0.isAnonymous) }
        subject = CurrentValueSubject<AuthUser?, Never>(initialUser)
        
        handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            let authUser = user.map { AuthUser(uid: $0.uid, isAnonymous: $0.isAnonymous) }
            self?.subject.send(authUser)
        }
    }

    deinit {
        if let handle = handle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    var currentUserPublisher: AnyPublisher<AuthUser?, Never> {
        subject.eraseToAnyPublisher()
    }
}






// MARK: - Before refactoring AuthorizationService (DI FirebaseAuthUserProvider)


///// Абстракция над источником текущего пользователя.
///// Может быть реализована через FirebaseAuth, мок для тестов, или любую другую систему авторизации.
//protocol CurrentUserProvider {
//    /// Паблишер, который эмитит uid текущего пользователя или nil при logout/удалении.
//    var currentUserPublisher: AnyPublisher<String?, Never> { get }
//}
//
//
//final class FirebaseAuthUserProvider: CurrentUserProvider {
//    private let subject = CurrentValueSubject<String?, Never>(Auth.auth().currentUser?.uid)
//    private var handle: AuthStateDidChangeListenerHandle?
//
//    init() {
//        handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
//            self?.subject.send(user?.uid)
//        }
//    }
//
//    deinit {
//        if let handle = handle {
//            Auth.auth().removeStateDidChangeListener(handle)
//        }
//    }
//
//    var currentUserPublisher: AnyPublisher<String?, Never> {
//        subject.eraseToAnyPublisher()
//    }
//}
