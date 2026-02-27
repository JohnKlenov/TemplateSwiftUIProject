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

/// Firebase Auth State Listener
///
/// Этот listener вызывается КАЖДЫЙ раз, когда Firebase сообщает об изменении
/// состояния авторизации текущего пользователя. Он триггерится гораздо чаще,
/// чем просто при login/logout.
///
/// Срабатывает в следующих случаях:
///
/// 1. **При запуске приложения**
///    - Firebase восстанавливает сохранённую сессию.
///    - Вызывает listener даже если пользователь НЕ менялся.
///
/// 2. **При успешном входе в систему**
///    - Email/Password, Google, Apple, анонимная авторизация.
///
/// 3. **При выходе из аккаунта (signOut)**
///    - user становится nil.
///
/// 4. **При удалении аккаунта**
///    - user → nil, затем Firebase может автоматически создать анонимного.
///
/// 5. **При обновлении ID Token**
///    - Firebase периодически обновляет токен (обычно раз в час).
///    - Listener вызывается, хотя пользователь тот же.
///
/// 6. **При восстановлении сети**
///    - Если приложение было оффлайн, а затем сеть появилась.
///
/// 7. **При автоматическом обновлении анонимного пользователя**
///    - Firebase может обновлять данные анонимной сессии.
///
/// 8. **При любых внутренних изменениях Firebase Auth**
///    - Например, обновление refresh token, reauth, link/unlink provider.
///
/// ⚠️ Важно:
/// Listener МОЖЕТ вызываться без фактической смены пользователя.
/// Поэтому всегда нужно сравнивать UID, прежде чем выполнять тяжёлые операции
/// (например, отменять Firestore listeners или перезагружать данные).



/// Firebase Auth State Listener — поведение при отсутствии сети
///
/// addStateDidChangeListener вызывается **сразу после подписки**, даже если
/// интернет недоступен. Firebase Auth использует локально сохранённого
/// пользователя (persisted user), поэтому сеть для первого вызова не нужна.
///
/// Что происходит при первом старте:
/// - Если пользователь уже был авторизован ранее — вернётся локальный user.
/// - Если пользователь был анонимным — вернётся локальный анонимный user.
/// - Если приложение запускается впервые — вернётся nil.
/// - Сеть при этом не требуется.
///
/// Что происходит, когда сеть появляется:
/// - Firebase синхронизирует состояние пользователя с сервером.
/// - Listener вызывается повторно.
/// - Если токен обновился — придёт обновлённый user.
/// - Если аккаунт был удалён на сервере — придёт user == nil.
/// - Если всё в порядке — пользователь останется тем же.
///
/// Итог:
/// Listener всегда вызывается минимум один раз локально,
/// а затем повторно при восстановлении сети или изменении состояния Firebase Auth.



// MARK: - userProvider подписан на AuthorizationService + HomeManager + UserInfoCellManager + UserInfoEditManager

// userProvider имеет много подписчико и при отработкив в нем блока addStateDidChangeListener имитет знгачения для подписчико в не определенном порядке(так как addStateDidChangeListener в нем срабатывает асинхронно)
// то есть подписчики каждый раз могут имитеть значения в произвольном порядке это важно учитывать реализуя сложную логику и взаимодействия меджду сущностями

/// Важно понимать разницу между двумя типами событий FirebaseAuthUserProvider:
///
/// 1) initialUser (значение из кэша Firebase)
///    - отправляется синхронно в момент создания FirebaseAuthUserProvider;
///    - все менеджеры подписываются в init, последовательно;
///    - поэтому порядок получения initialUser всегда совпадает с порядком
///      инициализации объектов в ViewBuilderService.
///
/// 2) AuthStateDidChangeListener (событие из сети)
///    - приходит асинхронно, в произвольный момент жизненного цикла приложения;
///    - подписки уже находятся в очереди main runloop;
///    - порядок их обработки зависит от загрузки runloop, момента завершения init
///      каждого менеджера и текущего состояния SwiftUI;
///    - поэтому порядок вызовов при сетевом событии НЕ гарантирован и может
///      отличаться от порядка инициализации, меняясь от запуска к запуску.
///
/// Итог:
/// - порядок initialUser всегда детерминирован и повторяет порядок создания менеджеров;
/// - порядок событий из сети недетерминирован — это нормальное поведение Combine;
/// - все подписчики получают оба события, но логика внутри `if currentUID != newUID`
///   может скрывать повторные вызовы, если UID не изменился.




/// Важно: порядок вызова подписчиков userProvider.currentUserPublisher НЕ гарантирован.
///
/// При первом значении (initialUser из кэша Firebase) порядок всегда совпадает
/// с порядком подписки, потому что CurrentValueSubject отправляет значение
/// синхронно в момент подписки, и все подписки создаются последовательно в init.
///
/// Но при сетевом событии (AuthStateDidChangeListener) порядок становится
/// недетерминированным. Причины:
///
/// 1. Firebase вызывает AuthStateDidChangeListener асинхронно через main runloop.
///    Порядок вызова слушателей Firebase НЕ гарантирован, даже если они были
///    зарегистрированы в разное время.
///
/// 2. Combine доставляет событие подписчикам в порядке, в котором подписки
///    фактически попали в очередь runloop, а не в порядке вызова .sink.
///    На это влияет момент создания объектов, загрузка главного потока,
///    рендеринг SwiftUI и другие асинхронные операции.
///
/// 3. SwiftUI может пересоздавать объекты, задерживать их инициализацию или
///    выполнять подписки позже, чем ожидается, что также меняет порядок.
///
/// Итог:
/// - initialUser → порядок детерминирован (совпадает с порядком подписки).
/// - сетевое событие → порядок НЕ гарантирован и может меняться при каждом запуске.
/// - Нельзя полагаться на порядок подписчиков при сетевых событиях.
/// - Логика HomeManager должна быть построена так, чтобы порядок вызовов
///   не имел значения (единый источник правды, идемпотентные операции).





/// Порядок вызова Auth.auth().addStateDidChangeListener при появлении сети
///
/// В приложении зарегистрировано два слушателя состояния Firebase Auth:
/// 1) в FirebaseAuthUserProvider()
/// 2) в AuthenticationService
///
/// Firebase вызывает *все* AuthStateDidChangeListener‑ы строго в порядке их регистрации.
/// Это справедливо при любом событии: первый запуск, отсутствие сети, восстановление сети,
/// обновление токена, logout, удаление аккаунта.
///
/// Что происходит при первом старте без сети:
/// - Firebase вызывает оба listener‑а сразу, используя локально сохранённого пользователя.
/// - Сеть не требуется.
/// - Первым вызывается listener из FirebaseAuthUserProvider().
/// - Вторым вызывается listener из AuthenticationService.
///
/// Что происходит, когда сеть появляется:
/// - Firebase повторно вызывает оба listener‑а после синхронизации состояния.
/// - Порядок остаётся тем же (не факт ):
///     1) FirebaseAuthUserProvider
///     2) AuthenticationService
///
/// Итог:
/// Listener в FirebaseAuthUserProvider всегда срабатывает первым,
/// потому что он был зарегистрирован раньше. AuthenticationService — вторым.




/// Важно: порядок вызова AuthStateDidChangeListener НЕ гарантирован.
///
/// Даже если userProvider создаётся раньше authService, это НЕ означает,
/// что его addStateDidChangeListener будет вызван первым при смене пользователя.
///
/// Причины:
/// - Firebase вызывает ВСЕ AuthStateDidChangeListener асинхронно через main runloop.
/// - Порядок зависит не от момента создания объекта, а от того,
///   когда слушатель фактически зарегистрировался в очереди runloop.
/// - Нагрузка на главный поток, момент появления UI, пересоздание объектов SwiftUI,
///   задержки в Combine — всё это влияет на порядок вызовов.
/// - Firebase официально НЕ гарантирует последовательность между несколькими слушателями.
///
/// Следствие:
/// - userProvider и authService могут получать события в разном порядке
///   при каждом запуске приложения.
/// - Нельзя полагаться на то, что cancelListener() отработает раньше observeCollection(),
///   если они завязаны на разные AuthStateDidChangeListener.
///
/// Вывод:
/// - Нужен единый источник правды (userProvider.currentUserPublisher),
///   который управляет жизненным циклом Firestore‑listener.
/// - Все операции cancel/observe должны запускаться только в ответ на userProvider,
///   а не на независимые события из authService.



/// Firebase не гарантирует порядок вызова AuthStateDidChangeListener,
/// а Combine не гарантирует порядок доставки асинхронных событий подписчикам.
/// Поэтому порядок подписчиков при сетевом событии может меняться при каждом запуске.
///
/// Управлять порядком подписчиков невозможно, но это и не требуется.
/// Вместо этого мы управляем порядком операций:
///     cancelListener() → startBooksObservation() → authenticate() → observeCollection()
///
/// Для этого userProvider.currentUserPublisher является ЕДИНСТВЕННЫМ источником правды.
/// Только он сообщает о смене UID, и только он инициирует перезапуск Firestore‑наблюдения.
/// Это гарантирует, что cancelListener() всегда вызывается раньше observeCollection(),
/// независимо от порядка подписчиков, таймингов Firebase и поведения SwiftUI.
///
/// Итог:
/// - порядок подписчиков недетерминирован и не должен использоваться в логике;
/// - порядок операций полностью детерминирован и гарантирован архитектурой.


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
            print("FirebaseAuthUserProvider Auth.auth().addStateDidChangeListener { - user:\(String(describing: user)) ")
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
