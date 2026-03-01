//
//  ViewBuilderService.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 5.02.25.
//




// MARK: - порядок init объектов в init ViewBuilderService имеет значения



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


// MARK: - userProvider и authServic и их addStateDidChangeListener

// userProvider и authService при отработки в них addStateDidChangeListener не гарантирует последовательно срабатывание (если userProvider первый был создан то не факт что при смене пользоваткеля в нем addStateDidChangeListener отработает раньше )
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


// !!! идея вынести алерт и еррор менеджер из сервисов (storageProfileService и profileService ) и перенести их в (authorizationManager + userInfoEditManager)
import SwiftUI

//@MainActor
class ViewBuilderService: ObservableObject {
    
    private let profileService:FirestoreProfileService
    private let storageProfileService: StorageProfileServiceProtocol
    private let authService: AuthenticationServiceProtocol
    
    private let crudManager: CRUDSManager
    private let authorizationManager: AuthorizationManager
    private let userInfoCellManager: UserInfoCellManager
    private let userInfoEditManager:UserInfoEditManager
    private let homeManager: HomeManager
    private let galleryManager: GalleryManager

    init() {
        let userProvider: CurrentUserProvider = FirebaseAuthUserProvider()
        
        let service = AuthorizationService(userProvider: userProvider)
        self.authorizationManager = AuthorizationManager(service: service, errorHandler: ErrorDiagnosticsCenter())
        
        let trackerService = AnonAccountTrackerService(errorCenter: ErrorDiagnosticsCenter())
        self.authService = AuthenticationService(trackerService: trackerService)
        
        self.profileService = FirestoreProfileService()
        self.storageProfileService = StorageProfileService()
        
        self.userInfoEditManager = UserInfoEditManager(firestoreService: profileService, storageService: storageProfileService, errorHandler: SharedErrorHandler(), userProvider: userProvider)
        
        self.userInfoCellManager = UserInfoCellManager(profileService: profileService, userProvider: userProvider, errorHandler: ErrorDiagnosticsCenter())
        
        self.crudManager = CRUDSManager(
            authService: AuthService(),
            errorHandler: ErrorDiagnosticsCenter(),
            databaseService: FirestoreDatabaseCRUDService()
        )
        
        self.homeManager = HomeManager(
            authService: authService,
            firestoreService: FirestoreCollectionObserverService(errorHandler: ErrorDiagnosticsCenter()),
            errorHandler: ErrorDiagnosticsCenter(),
            alertManager: AlertManager.shared
        )
        
        self.galleryManager = GalleryManager(
            firestoreService: FirestoreGetService(errorHandler: ErrorDiagnosticsCenter()),
            errorHandler: ErrorDiagnosticsCenter(),
            alertManager: AlertManager.shared
        )
        
        print("init ViewBuilderService")
    }
    
    deinit {
        print("deinit ViewBuilderService")
    }
    
    
    @ViewBuilder
    func homeViewBuild(page: HomeFlow) -> some View {
        switch page {
        case .home:
            HomeContentViewInjected( managerCRUDS: crudManager, homeManager: homeManager )
        case .bookDetails(let book):
            BookDetailsViewInjected( managerCRUDS: crudManager, book: book )
        case .someHomeView:
            SomeView()
        }
    }
    
    @ViewBuilder 
    func galleryViewBuild(page: GalleryFlow) -> some View {
        switch page {
        case .gallery:
            GalleryContentViewInjected(galleryManager: galleryManager)
        case .someHomeView:
            SomeView()
        }
    }
    
    
    @ViewBuilder
    func accountViewBuild(page: AccountFlow) -> some View {
        switch page {
        case .userInfo:
            SomeView()
        case .language:
            ChangeLanguageViewInjected()
        case .aboutUs:
            SomeView()
        case .createAccount:
            SignUpViewInjected(authorizationManager: authorizationManager)
        case .account:
            ContentAccountViewInjected(
                authorizationManager: authorizationManager,
                userInfoCellManager: userInfoCellManager
            )
        case .login:
            SignInViewInjected(authorizationManager: authorizationManager)
        case .reauthenticate:
            ReauthenticateViewInjected(authorizationManager: authorizationManager)
        case .forgotPassword:
            ForgotPasswordViewInjected(authorizationManager: authorizationManager)   
        case .userInfoEdit(let profile):
            UserInfoEditViewInjected(editManager: userInfoEditManager, profile: profile)
        }
    }

    
    /// будут ли у нас проблемы если у нас ViewBuilderService работает на двух стеках и на одгом мы дерним buildSheet что произойдет на втором стеке он тоже дернится?
    @ViewBuilder
    func buildSheet(sheet: SheetItem) -> some View {
        sheet.content
    }
    
    @ViewBuilder
    func buildCover(cover: FullScreenItem) -> some View {
        cover.content
    }
}



// before refactoring View → ViewModel → Manager → Service


//@ViewBuilder
//func homeViewBuild(page: HomeFlow) -> some View {
//    switch page {
//    case .home:
//        HomeContentView(managerCRUDS: crudManager, authenticationService: authService)
//    case .bookDetails(let book):
//        BookDetailsView(managerCRUDS: crudManager, book: book)
//    case .someHomeView:
//        SomeView()
//    }
//}


// before ForgotPasswordView

//@ViewBuilder
//func accountViewBuild(page: AccountFlow) -> some View {
//    switch page {
//    case .userInfo:
//        SomeView()
//    case .language:
//        SomeView()
//    case .aboutUs:
//        SomeView()
//    case .createAccount:
//        SignUpViewInjected(authorizationManager: authorizationManager)
//    case .account:
//        ContentAccountViewInjected(authorizationManager: authorizationManager, userInfoCellManager: userInfoCellManager)
//    case .login:
//        SignInViewInjected(authorizationManager: authorizationManager)
//    case .reauthenticate:
//        ReauthenticateViewInjected(authorizationManager: authorizationManager)
//    case .userInfoEdit(let profile):
//        UserInfoEditViewInjected(editManager: userInfoEditManager, profile: profile)
//    }
//}
