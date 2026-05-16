//
//  AppSessionManager.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 20.04.26.
//

// Если HomeManager уничтожен, старая Combine-цепочка может ещё получать
// события от Firebase/Firestore. Возвращая .error("Internal state lost"),
// мы корректно завершаем старую цепочку и предотвращаем ситуацию, когда
// старый поток данных успевает отправить ложное состояние в UI (например,
// пустой список). Новый ContentView/ViewModel/HomeManager уже созданы и
// имеют собственную подписку, поэтому ошибка гарантирует, что старый поток
// не вмешается в работу нового стека.

// Если self == nil, HomeManager уже уничтожен (например, при пересоздании
// дерева SwiftUI). В этот момент его зависимости, включая errorHandler,
// тоже недоступны, поэтому логировать ошибку здесь невозможно. Мы
// возвращаем .error("Internal state lost") только для корректного
// завершения старой Combine-цепочки, чтобы она не вмешалась в работу
// нового стека сущностей.



/// Почему в HomeManager может произойти гонка между cancelListener() и observeCollection()
///
/// Оба AuthStateDidChangeListener (в FirebaseAuthUserProvider и в AuthenticationService)
/// вызываются Firebase **строго в порядке регистрации** и **в одном и том же потоке** — на главном.
/// Это гарантирует последовательное выполнение без параллельных вызовов.
///
/// Последовательность при появлении сети всегда такая:
/// 1) Сначала вызывается listener в FirebaseAuthUserProvider → триггерит HomeManager.observeUserChanges() → cancelListener().
/// 2) Затем вызывается listener в AuthenticationService → триггерит HomeManager.observeBooks() → observeCollection().
///
/// Почему в HomeManager возможна путаница и как мы это исправили
///
/// Ранее комментарий утверждал, что гонки между cancelListener() и observeCollection()
/// невозможны, потому что Firebase вызывает слушатели "строго в порядке регистрации".
/// Это было упрощением — реальность сложнее.
///
/// Что важно знать теперь:
/// - Значение из кэша (initialUser) отправляется синхронно при создании FirebaseAuthUserProvider.
///   В этот момент подписки, создаваемые последовательно в init, получают значение в порядке
///   инициализации — поведение детерминировано.
/// - Событие из сети (AuthStateDidChangeListener) приходит асинхронно в произвольный момент.
///   Порядок обработки подписчиков при таком событии зависит от того, когда каждая подписка
///   фактически зарегистрирована/обработана в main runloop; этот порядок не гарантирован и
///   может меняться между запусками приложения.
///
/// Следствия для HomeManager:
/// - Теоретически возможна ситуация, когда код, который вызывает observeCollection()
///   (например, через authService.authenticate()), выполнится раньше, чем подписка
///   userProvider.currentUserPublisher обработает смену UID и вызовет cancelListener().
///   Это может привести к кратковременному наложению слушателей, если сервис наблюдений
///   не защищён от повторных вызовов.
///
/// Меры защиты и рекомендации (реализованные/рекомендуемые):
/// - Рассматривать userProvider как единственный источник правды для смены пользователя:
///   все перезапуски Firestore‑наблюдений инициировать в ответ на currentUserPublisher.
/// - Обновлять currentUID до запуска новой логики наблюдения, чтобы избежать гонок по состоянию.
/// - Сделать FirestoreCollectionObserverService идемпотентным: при новом observeCollection(at:)
///   сервис обязан сначала отменить предыдущий listener, затем создать новый.
/// - При необходимости сериализовать операции cancel/observe через private serial DispatchQueue
///   внутри HomeManager, чтобы исключить параллельные вызовы на уровне менеджера.
/// - Логировать входящие события (вне условий сравнения UID), чтобы не пропускать сетевые вызовы.
///
/// Итог:
/// - initialUser — детерминированный порядок (соответствует init).
/// - сетевые события — асинхронны, порядок подписчиков не гарантирован.
/// - гонка возможна теоретически, но её легко устранить архитектурно: один источник правды
///   (userProvider), идемпотентный сервис наблюдений и/или сериализация операций.


//сначала срабатывает FirebaseAuthUserProvider, а затем AuthenticationService

/// Почему в логах почти всегда сначала срабатывает FirebaseAuthUserProvider, а затем AuthenticationService
///
/// В текущей архитектуре это выглядит как закономерность, но важно понимать,
/// что это побочный эффект порядка регистрации слушателей, а не гарантированное
/// поведение Firebase.
///
/// 1. FirebaseAuthUserProvider создаётся первым в ViewBuilderService.init.
///    Его addStateDidChangeListener вызывается сразу в init, поэтому слушатель
///    регистрируется очень рано и живёт всё время жизни приложения.
///
/// 2. AuthenticationService создаётся позже и НЕ регистрирует слушатель в init.
///    Его addStateDidChangeListener вызывается только в start()/reset(),
///    то есть значительно позже userProvider.
///
/// 3. Поэтому при удалении пользователя и создании анонимного Firebase вызывает
///    слушатели в порядке их фактической регистрации:
///        userProvider → AuthenticationService
///    и это выглядит стабильным.
///
/// Важно:
/// - Firebase официально НЕ гарантирует порядок вызова нескольких
///   AuthStateDidChangeListener, даже если они зарегистрированы в разное время.
/// - Порядок может измениться при изменении жизненного цикла объектов,
///   задержках SwiftUI, нагрузке на main thread или обновлении SDK.
/// - Архитектура не должна зависеть от порядка вызова слушателей.
///
/// Итог:
/// - Сейчас userProvider почти всегда получает событие первым, потому что
///   его listener регистрируется раньше.
/// - Но это не контракт Firebase. Логика HomeManager должна быть построена так,
///   чтобы порядок слушателей не имел значения (единый источник правды).



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





//                    if self.currentUID != userId {
//                        print("HomeManager func observeBooks() if self.currentUID != userId { ")
//                        self.firestoreService.cancelListener()
//                        self.currentUID = userId
//                    }











// MARK: - реализовать 100 гарантию того что  self.firestoreService.cancelListener() не вызовится сразу после self.firestoreService.observeCollection(at: path) при смене пользователя
// AuthStateDidChangeListener в userProvider и authService могут отработать в произвольном порядке
// пока стабильно вызов в userProvider происходит до authService



// когда мы signIn/signUp мы сразу получаем user из authService.authenticate() и отключаем firestoreService.cancelListener() перед observeCollection(at: path) ошибку прав мы не видим
// когда мы delete user мы сначало получаем nil и это реакция с nil не попадает в пейплайн authService.authenticate()
// мы тратим время на создания анонимного пользователя а за это время observeCollection(at: path) возвращает ошибку прав
// затем приходит userUID в authService.authenticate() и заново пересоздает observeCollection(at: path) (ошибка в homeView исчезает при смене stateerror на stateContent)
// Нам нужно как то ловить nil в пейплайне authService.authenticate() и вызывать self.firestoreService.cancelListener()
// и не вызывать операторы пейплайна ниже а ждать уже следующее эмитированое значение




// MARK: - implemintation shared AppSessionManager (обслуживает любое количество ViewModel)



import Combine
import Foundation

final class AppSessionManager {

    // MARK: - Public reactive state

    private let stateSubject = CurrentValueSubject<DropeState?, Never>(nil)
    var statePublisher: AnyPublisher<DropeState?, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    // MARK: - Dependencies

    private let authService: AuthenticationServiceProtocol
    private let firestoreService: FirestoreCollectionObserverProtocol
    private let errorHandler: ErrorDiagnosticsProtocol
    private let alertManager: AlertManager

    private var cancellables = Set<AnyCancellable>()
    private(set) var globalRetryHandler: GlobalRetryHandler?

    init(
        authService: AuthenticationServiceProtocol,
        firestoreService: FirestoreCollectionObserverProtocol,
        errorHandler: ErrorDiagnosticsProtocol,
        alertManager: AlertManager = .shared
    ) {
        self.authService = authService
        self.firestoreService = firestoreService
        self.errorHandler = errorHandler
        self.alertManager = alertManager
        print("init HomeManager")
    }

    deinit {
        print("deinit HomeManager")
    }

    // MARK: - Public API

    func start() {
        authService.start()
    }

    /// Единая реактивная цепочка:
    /// Auth → userId → Firestore → ViewState → stateSubject
    func observe() {
        authService.authenticate()
            .flatMap { [weak self] resultOrNil -> AnyPublisher<DropeState, Never> in
                guard let self = self else {
                    return Just(.error(AppInternalError.entityDeallocated.localizedDescription))
                        .eraseToAnyPublisher()
                }

                // user == nil → deleteAccount / signOut / переходное состояние
                guard let result = resultOrNil else {
                    self.firestoreService.cancelListener()
                    return Just(.loading).eraseToAnyPublisher()
                }

                switch result {
                case .success(let userId):
                    let path = "users/\(userId)/myTracks"

                    let publisher: AnyPublisher<Result<[MyTrackCloud], Error>, Never> =
                        self.firestoreService.observeCollection(at: path)

                    return publisher
                        .map { result in
                            switch result {
                            case .success(let myTracks):
                                return .myTracks(myTracks)
                            case .failure(let error):
                                return self.handleError(
                                    error,
                                    context: .HomeManager_observeBooks_firestoreService_observeCollection
                                )
                            }
                        }
                        .eraseToAnyPublisher()

                case .failure(let error):
                    /// это ошибка может возникнуть только если createAnonymousUser вернет ошибку
                    /// она может возникнуть (при первом старте, если мы удалили account и не удадось createAnonymousUser ... )
                    /// так как HomeContentViewModel это единственная точка создания createAnonymousUser
                    /// refresh из любой точки приложения нужно делать сдесь через globalAlert и notification
                    /// может получится так что при первом старте время ответа от Firebase Auth будет долгим из за плохой сети
                    /// и пользователь перейдет на другую вкладку TabBar
                    /// тогда при ошибки создания createAnonymousUser мы должны через globalAlert на любом другом экране refresh
                    /// тут важно что бы globalAlert всегда первым отображался на экране ()
                    /// Таймауты Firebase Auth: Стандартный таймаут: 10-60 секунд (зависит от версии SDK и сетевых условий)
                    /// 3G: 2-8 секунд / Edge-сети (2G): 12-30 секунд / После 15 сек 60% пользователей закрывают приложение
                    return Just(
                        self.handleError(
                            error,
                            context: .HomeManager_observeBooks_authService_authenticate
                        )
                    )
                    .eraseToAnyPublisher()
                }
            }
            .sink { [weak self] state in
                self?.stateSubject.send(state)
            }
            .store(in: &cancellables)
    }

    func retry() {
        stateSubject.send(.loading)
        authService.reset()
    }

    func setRetryHandler(_ handler: GlobalRetryHandler) {
        self.globalRetryHandler = handler
    }

    // MARK: - Error Handling (единый маршрут ошибок)
    
    /// помоему мы решили эту проблему ?!
    /// Локальные ошибки Firestore → без глобального алерта
    /// когда мы signOut/deleteAccount в момент когда user == nil отрабатывает firestorColletionObserverService.observeCollection(at: "users/\(userId)/data")
    /// и выбрасывает [FirebaseFirestore][I-FST000001] Listen for query at users/Sni6ad3yp4U3bnkamD1SpevQiVs2/data failed: Missing or insufficient permissions.
    /// для лучшего user experience мы не отображаем глобальный алерт, ведь буквально через мгновение у firestorColletionObserverService.observeCollection будет удален старый наблюдатель и установлен новый и .error(message) сменится на .content(books)
    private func handleError(_ error: Error, context: ErrorContext) -> DropeState {
        let message = errorHandler.handle(error: error, context: context.rawValue)

        globalRetryHandler?.setAuthenticationRetryHandler { [weak self] in
            self?.retry()
        }

        alertManager.showGlobalAlert(
            message: message,
            operationDescription: Localized.TitleOfFailedOperationFirebase.authentication,
            alertType: .tryAgain
        )

        return .error(message)
    }
}

