//
//  AuthorizationService.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 16.06.25.
//

//UX (User Experience) — это пользовательский опыт, то есть то, как человек воспринимает и ощущает работу с продуктом или сервисом.


// MARK: - ID токен Firebase

// Firebase Auth: срок жизни токена
//
// - ID токен Firebase по умолчанию живёт около 1 часа.
// - После этого он автоматически обновляется с помощью refresh‑токена,
//   если приложение активно и есть интернет.
// - Refresh‑токен не имеет жёсткого срока (может жить месяцами),
//   но сервер может его отозвать (например, при смене пароля или блокировке).
// - Если пользователь заходит в приложение раз в сутки или раз в две недели,
//   SDK при старте обновит ID токен через refresh‑токен и всё будет работать.
// - Проблемы возникают только если refresh‑токен недействителен
//   (например, пользователь удалён, пароль изменён, аккаунт отключён).
//
// Итог:
// - ID токен устаревает через ~1 час.
// - Для пользователя, который заходит раз в день или реже,
//   это прозрачно: SDK обновит токен автоматически.
// - Реаутентификация нужна только при критичных операциях
//   (delete, смена пароля/почты) или если refresh‑токен отозван.
//


// MARK: - паралельное выполнение auth‑операций

// Auth операции (SignIn / SignUp / DeleteAccount)
//
// - В боевых приложениях не допускают параллельных auth‑операций.
// - Пока выполняется SignIn или SignUp, UI блокирует другие действия (например, DeleteAccount).
// - Причина: Firebase Auth поддерживает только одного currentUser, параллельные вызовы создают гонки.
// - Правильный паттерн: "одна auth‑операция за раз" + возможность отмены на уровне UI.
// - Таким образом сохраняется консистентность и предсказуемое поведение.
//


// MARK: - func deleteAccount()


// Firebase Auth: user.delete — обработка ошибок и сетевое поведение
//
// 1) Подробно: возможные ошибки в блоке `user.delete { error in ... }`
//
//    - Домен ошибок: FIRAuthErrorDomain (можно преобразовать в AuthErrorCode по rawValue).
//    - Наиболее частые коды, которые стоит явно обрабатывать:
//
//      .requiresRecentLogin
//      // Удаление аккаунта требует «свежей» аутентификации.
//      // Нужно инициировать повторный вход пользователя и затем повторить удаление.
//
//      .networkError
//      // Проблемы с сетью: отсутствие интернета, сбои DNS, потеря пакетов.
//      // Следует показать пользователю сообщение об ошибке и предложить повторить.
//
//      .userTokenExpired
//      // Токен доступа устарел. Обычно помогает повторная аутентификация.
//
//      .invalidUserToken
//      // Токен недействителен (повреждён или отозван). Требуется повторный вход.
//
//      .userNotFound
//      // Пользователь больше не существует (например, уже удалён на сервере).
//      // С точки зрения UX можно трактовать как успешное удаление.
//
//      .internalError
//      // Внутренняя ошибка Firebase. Логируем и показываем общее сообщение об ошибке.
//
//      .appNotAuthorized
//      // Ошибка конфигурации проекта (неверные ключи, настройки).
//      // Критическая ошибка, требует исправления конфигурации.
//
//    // Общий паттерн:
//    // if let code = AuthErrorCode(rawValue: nsError.code) { switch code { ... } }
//
//
// 2) Ключевые моменты: плохой интернет или отсутствие сети
//    - При полном отсутствии соединения SDK быстро вернёт `.networkError`.
//    - При очень плохом соединении SDK будет пытаться достучаться до серверов,
//      пока системный стек не вернёт ошибку.
//
//
// 3) Ключевые моменты: таймаут
//    - У Firebase Auth SDK нет жёстко задокументированного таймаута для delete().
//    - Используется системный сетевой стек iOS (обычно таймаут соединения ~60 секунд).
//    - Если нужно предсказуемое поведение, оборачивайте вызов в Combine‑оператор
//      `.timeout(.seconds(15), ...)`, чтобы ограничить ожидание.
//
//
// Практические рекомендации
//    - Минимум обрабатывать: .requiresRecentLogin, .networkError, .userNotFound.
//    - Для временных проблем (сеть) показывать пользователю возможность повторить.
//    - Для предсказуемости использовать собственный таймаут на уровне Combine.
//    - Неизвестные коды логировать и показывать универсальное сообщение об ошибке.
//

// Поведение при таймауте и «позднем ответе» Firebase SDK (user.delete)
// для deleteAccount лучше не ставить таймаут, а довериться SDK и показать пользователю реальный результат.
//
// 1) Что делает таймаут в Combine
//    - Когда срабатывает .timeout, паблишер завершает цепочку с ошибкой.
//    - Подписчик (sink) получает .failure и считается завершённым.
//    - Все cancellable для этой подписки освобождаются.
//
// 2) Что происходит, если SDK вернёт ответ позже
//    - Firebase SDK всё равно вызовет completion-блок user.delete.
//    - Внутри Future будет вызван promise(...).
//    - Но Future по контракту принимает результат только один раз.
//    - Если promise уже был вызван (таймаут сработал), повторный вызов игнорируется.
//    - Никакого двойного завершения или краша не произойдёт.
//
// 3) Итоговое поведение
//    - Для подписчика: он увидит только ошибку таймаута.
//    - Поздний ответ SDK будет проигнорирован.
//    - Это нормальное и безопасное поведение.
//
// 4) Практический совет
//    - Если важно отлаживать такие ситуации, можно добавить print()
//      перед вызовом promise в user.delete, чтобы логировать «опоздавшие» ответы.
//    - Например: print("⚠️ SDK ответил после таймаута").
//



// MARK: - func reauthenticate

// Обработка ошибок при user.reauthenticate(with: credential)
//
// switch code {
// case .wrongPassword, .invalidEmail:
//     // Неверные данные — показать пользователю сообщение и запросить ввод заново.
//
// case .invalidCredential, .userTokenExpired, .invalidUserToken:
//     // Текущая сессия/credential недействительны.
//     // Автоматический повтор не поможет — нужно запросить у пользователя актуальные данные.
//
// case .userMismatch:
//     // Credential принадлежит другому пользователю — показать ошибку и запросить правильный аккаунт.
//
// case .userDisabled:
//     // Аккаунт отключён администратором — сообщить пользователю, вход невозможен.
//
// case .userNotFound:
//     // Пользователь удалён — сообщить, что аккаунт не существует.
//
// case .networkError:
//     // Проблемы с сетью — показать сообщение и предложить повторить.
//
// default:
//     // Все остальные ошибки — логировать и показать универсальное сообщение.
//

// Основные моменты по реаутентификации с разными провайдерами:
//
// Регистрация с выбором одного провайдера vs мульти‑провайдерность:
//
// мы не будем давать возможность привязывать несколько провайдеров к одному аккаунту.
// Аккаунт создаётся только с одним провайдером (SignIn/SignUp всегда имеет три провайдера на экране а вот ReauthenticateView будет определять перед отрисовкой View к какому провайдеру привязан аккаунт и отображать только этот способ Reauthenticate на View что бы не вводить в заблуждения пользователя).
// Это абсолютно нормальная практика для продакшн‑приложений.
// Мульти‑провайдерность добавляют только если есть бизнес‑ценность (например, повысить retention за счёт «запасного» способа входа).
//
// - Нельзя всегда использовать EmailAuthProvider.credential(...).
//   Нужно применять тот же провайдер, через который пользователь вошёл.
//
// - Для Email/Password:
//   EmailAuthProvider.credential(withEmail: email, password: password)
//
// - Для Google:
//   GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
//
// - Для Apple:
//   OAuthProvider.credential(withProviderID: "apple.com", idToken: idToken, rawNonce: nonce)
//
// - В user.providerData хранится список провайдеров ("password", "google.com", "apple.com").
//   По нему можно определить, какой credential нужно запросить.
//
// - В продакшн‑коде обычно делают обёртку (enum AuthProviderType),
//   которая возвращает корректный AuthCredential для reauthenticate.
//
// Итог:
// - Архитектура должна поддерживать разные провайдеры.
// - Реаутентификация всегда должна выполняться тем же способом,
//   каким пользователь изначально вошёл.
//

// Профессиональный вывод по реаутентификации:
//
// - Не показывать все провайдеры бездумно — это может вызвать ошибки (.userMismatch).
//
// - Правильный паттерн:
//   1. Смотришь user.providerData.
//   2. Если один провайдер → показываешь только его.
//   3. Если несколько → даёшь пользователю выбор из этих провайдеров.
//
// - Так делают старшие разработчики, потому что:
//   • минимизируются ошибки (.userMismatch),
//   • UX становится предсказуемым,
//   • решение остаётся гибким для мульти‑провайдерных аккаунтов.
//

// Регистрация с выбором одного провайдера vs мульти‑провайдерность:
//
//ReauthenticateView one provaider
//
//
// Профессиональный паттерн:
//
// - Мы не даём возможность привязывать несколько провайдеров к одному аккаунту.
// - Аккаунт создаётся только с одним провайдером (Email, Google или Apple).
// - На экране SignIn/SignUp всегда показываем все три варианта,
//   чтобы пользователь выбрал способ регистрации.
//
// - На экране ReauthenticateView:
//   • перед отрисовкой определяем, к какому провайдеру привязан аккаунт,
//   • отображаем только этот способ реаутентификации,
//   • это исключает путаницу и ошибки (.userMismatch).
//
// Итог:
// - Так делают на боевых приложениях: выбор провайдера при регистрации,
//   а при реаутентификации — строго тот же провайдер, что у аккаунта.
//
//
// Регистрация с выбором одного провайдера vs мульти‑провайдерность:
//
// - Мульти‑провайдерность (через user.link(with:)) добавляют только если:
//   • есть бизнес‑ценность (запасной способ входа),
//   • нужно повысить retention,
//   • требуется гибкость входа с разных устройств.
//
// Итог:
// - Можно не использовать мульти‑провайдерность.
// - Выбор одного провайдера при регистрации — это нормальная и распространённая практика.
//
//
// Как иметь несколько провайдеров входа на одном аккаунте:
//
// - Базовый вход (например, Email/Password) создаёт currentUser с UID.
// - В настройках показываем кнопки "Привязать Google/Apple".
// - Получаем credential второго провайдера и вызываем:
//     user.link(with: newCredential) { ... }
// - Успех: в user.providerData появляется второй провайдер,
//   один и тот же UID теперь доступен через несколько способов входа.
// - Нюансы:
//   • link работает только на текущем пользователе,
//   • возможны конфликты, если credential уже привязан к другому аккаунту,
//   • для чувствительных действий может потребоваться реаутентификация.
// - Telegram: вход по номеру телефона; привязки Google/Apple именно как способов
//   логина к Telegram-аккаунту нет — это фича auth-платформ (например, Firebase).
//



// MARK: - func sendPasswordReset(email: String)

/*
 
 Firebase Email Templates

 В консоли Firebase есть раздел Authentication → Templates (Email Templates).
 Там настраиваются тексты и оформление писем, которые Firebase рассылает пользователям:

 - Password reset email — письмо со ссылкой для сброса пароля
 - Email verification — письмо для подтверждения email при регистрации
 - Email change — письмо при смене email

 Что можно настроить:
 - Заголовок письма (subject)
 - Текст письма (body), включая динамические плейсхолдеры вроде {email} или {url}
 - Логотип и цветовую схему
 - Язык письма (Firebase поддерживает локализацию)

 👉 Если шаблон не настроен, Firebase всё равно отправит письмо,
    но оно будет стандартным (английский текст, базовый вид).
*/


/*
 Добавление логотипа в шаблоны писем Firebase

 Чтобы вставить логотип в письмо (например, для сброса пароля), добавьте HTML‑тег <img> в тело шаблона:

 <img src="https://yourdomain.com/logo.png" alt="Logo" width="120" />

 Требования:
 - Картинка должна быть размещена по публичному HTTPS‑адресу
 - Firebase не хранит изображения — он просто ссылается на внешний URL
 - Рекомендуется использовать Firebase Hosting, GitHub Pages или CDN

 Тег можно разместить над или под основным текстом письма, чтобы визуально брендировать сообщение.
*/


/*
 Локализация писем Firebase (Password Reset, Verification)

 1. В консоли Firebase (Authentication → Templates) создайте шаблон письма для каждого языка:
    - Выберите язык в выпадающем списке ("Set template language")
    - Отредактируйте Subject и Body с плейсхолдерами (%EMAIL%, %APP_NAME%, %LINK%)
    - Сохраните шаблон для каждого языка (ru, en, es)

 2. В коде перед вызовом метода укажите нужный язык:
    Auth.auth().languageCode = "ru"
    Auth.auth().sendPasswordReset(withEmail: email) { ... }

 Firebase автоматически выберет шаблон нужного языка и отправит письмо с локализованным текстом - так и есть - если в Auth.auth().languageCode = "es" то письмо приходит на испанском. 
*/



// MARK: - Sign in with Google

/*
 SignIn (Google) → Permanent
 Сценарий: у нас есть перманентный пользователь (например, email/password), и он нажимает «Sign in with Google».

 🔹 Если в Firebase ещё нет ни одного пользователя с этим Google‑аккаунтом —
    Firebase создаст нового пользователя с новым UID, привязанным к Google.
    Текущая сессия переключится на него, а старый перманентный аккаунт останется в системе, но будет «брошен» (UID сменится).

 🔹 Если Google‑аккаунт уже существует в Firebase —
    Firebase просто выполнит вход в существующего пользователя (UID того Google‑аккаунта).
    Текущий перманентный аккаунт будет заменён в сессии, и ты окажешься в уже существующем Google‑пользователе.

 👉 Итог: SignIn всегда переключает сессию на Google‑аккаунт.
    Если его нет — создаётся новый. Если он есть — вход в существующий.


 SignUp (Google) → Permanent
 Сценарий: у нас есть перманентный пользователь (например, email/password), и он нажимает «Sign up with Google».

 🔹 Если Google‑аккаунт ещё не существует в Firebase —
    Firebase создаст нового пользователя с новым UID, и текущая сессия переключится на него.
    Старый перманентный аккаунт останется в системе, но сессия уйдёт в новый Google‑аккаунт.

 🔹 Если Google‑аккаунт уже существует в Firebase —
    Попытка «создать» приведёт к ошибке AuthErrorCode.credentialAlreadyInUse.
    Это значит, что такой Google‑аккаунт уже привязан к другому UID.
    В этом случае правильное поведение:
      • показать пользователю сообщение «Этот Google‑аккаунт уже зарегистрирован, войдите через Sign In»,
      • либо автоматически переключить сессию на существующий Google‑аккаунт (fallback в SignIn).

 👉 Итог: SignUp при перманентном пользователе всегда создаёт новый Google‑аккаунт,
    но если он уже есть в системе, мы получаем ошибку и должны обработать её как «аккаунт уже существует».
*/


// MARK: -  Вариант с ViewControllerProvider

// ViewControllerProvider даёт тебе реальный UIViewController из SwiftUI‑экрана.
// Ты передаёшь его в viewModel, а дальше вниз в AuthorizationManager → AuthorizationService.
// Таким образом, ты не ищешь глобально topViewController, а используешь именно тот VC (на самом деле ты создаешь новый VC), из которого пользователь нажал кнопку. Это надёжнее и проще, если у тебя ограниченное число экранов для входа.
/// Вопрос про утечки памяти:
/// - В случае с topViewController мы лишь получаем ссылку на уже существующий VC в иерархии UIKit.
///   Он живёт пока экран активен и освобождается системой при закрытии — лишних удержаний нет.
/// - В случае с ViewControllerProvider создаётся временный VC, встроенный в SwiftUI.
///   Его жизненный цикл управляется самим SwiftUI: когда экран уничтожается, VC тоже освобождается.
/// - Главное правило: не хранить VC в сильных (strong) свойствах менеджеров/сервисов.
///   Если нужно сохранить — использовать weak, тогда утечек не будет.
// View
//struct SignInView: View {
//    @State private var isPasswordVisible = false
//    @FocusState var isFieldFocus: FieldToFocusAuth?
//
//    @ObservedObject var viewModel: SignInViewModel
//    @EnvironmentObject var localization: LocalizationService
//    @EnvironmentObject var accountCoordinator: AccountCoordinator
//
//    // локальное состояние для вызова VC
//    @State private var isResolvingVC = false
//
//    var body: some View {
//        ZStack {
//            // твой UI...
//
//            Button(action: {
//                print("googlelogo")
//                isResolvingVC = true   // запускаем получение VC
//            }) {
//                Image("googlelogo")
//                    .resizable()
//                    .scaledToFit()
//                    .padding()
//                    .frame(width: 60, height: 60)
//                    .background(Circle().stroke(Color.gray, lineWidth: 1))
//            }
//            .disabled(viewModel.isAuthOperationInProgress)
//
//            // Встраиваем ViewControllerProvider
//            ViewControllerProvider { vc in
//                // как только VC получен → сбрасываем флаг
//                isResolvingVC = false
//                // передаём VC в viewModel
//                viewModel.googleSignInWithPresenting(vc)
//            }
//            .opacity(0) // делаем невидимым, чтобы не мешал UI
//        }
//    }
//}
// ViewModel
//extension SignInViewModel {
//    func googleSignInWithPresenting(_ vc: UIViewController) {
//        guard !isAuthOperationInProgress else { return }
//        isAuthOperationInProgress = true
//        signInState = .loading
//
//        authorizationManager.googleSignIn(presentingVC: vc)
//    }
//}
// AuthorizationManager и AuthorizationService
//class AuthorizationManager {
//    private let authService: AuthorizationService
//    private var cancellables = Set<AnyCancellable>()
//
//    func googleSignIn(presentingVC: UIViewController) {
//        authService.signInWithGoogle(intent: .signIn, presentingVC: presentingVC)
//            .receive(on: DispatchQueue.main)
//            .sink { completion in
//                // обработка ошибок/успеха
//            } receiveValue: { _ in }
//            .store(in: &cancellables)
//    }
//}
//func signInWithGoogle(intent: GoogleAuthIntent, presentingVC: UIViewController) -> AnyPublisher<Void, Error> {
//    currentUserPublisher()
//        .flatMap { [weak self] user -> AnyPublisher<Void, Error> in
//            guard let self else {
//                return Fail(error: FirebaseInternalError.defaultError).eraseToAnyPublisher()
//            }
//            return self.getGoogleCredential(presentingVC: presentingVC)
//                .flatMap { credential -> AnyPublisher<Void, Error> in
//                    switch intent {
//                    case .signIn:
//                        return self.googleSignInReplacingSession(credential: credential)
//                    case .signUp:
//                        if user.isAnonymous {
//                            return self.googleLinkAnonymous(user: user, credential: credential)
//                        } else {
//                            return self.googleSignInReplacingSession(credential: credential)
//                        }
//                    }
//                }
//                .eraseToAnyPublisher()
//        }
//        .eraseToAnyPublisher()
//}
//private func getGoogleCredential(presentingVC: UIViewController) -> AnyPublisher<AuthCredential, Error> {
//    Future<AuthCredential, Error> { promise in
//        guard let clientID = FirebaseApp.app()?.options.clientID else {
//            return promise(.failure(FirebaseInternalError.defaultError))
//        }
//        let config = GIDConfiguration(clientID: clientID)
//        GIDSignIn.sharedInstance.configuration = config
//
//        DispatchQueue.main.async {
//            GIDSignIn.sharedInstance.signIn(withPresenting: presentingVC) { result, error in
//                if let error = error {
//                    return promise(.failure(error))
//                }
//                guard let gUser = result?.user,
//                      let idToken = gUser.idToken?.tokenString else {
//                    return promise(.failure(FirebaseInternalError.defaultError))
//                }
//                let accessToken = gUser.accessToken.tokenString
//                let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
//                promise(.success(credential))
//            }
//        }
//    }
//    .eraseToAnyPublisher()
//}



import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import UIKit
import Combine


// Ошибка, специфичная для deleteAccount()
enum DeleteAccountError: Error {
    /// Firebase вернул код .requiresRecentLogin
    case reauthenticationRequired(Error)
    /// Любая другая ошибка — оборачиваем оригинальный Error
    case underlying(Error)
}

// Google intents: SignIn / SignUp (без мульти-провайдерной линковки)
enum GoogleAuthIntent {
    case signIn     // заменить текущую сессию Google-аккаунтом
    case signUp     // аноним → линк; перманент → создать/войти в Google-аккаунт (новый/существующий)
}

final class AuthorizationService {
    
    // MARK: - Dependencies
    private let userProvider: CurrentUserProvider
    private let errorHandler: ErrorDiagnosticsProtocol
    
    // MARK: - Publishers & Storage
    private var cancellable: AnyCancellable?
    // тут тоже как и в AuthenticationService правельнее было бы использовать CurrentValueSubject
    /// на authStateSubject подписываются позже чем мы вызываем  func observeUserChanges()
    /// но так как мы делаем это асинхронно и в другом тике логика отрабатывает корректно но это случайность а не архитектурное решение
//    private let authStateSubject = PassthroughSubject<AuthUser?, Never>()
    private let authStateSubject = CurrentValueSubject<AuthUser?, Never>(nil)

    
    // MARK: - Init
    init(userProvider: CurrentUserProvider,
         errorHandler: ErrorDiagnosticsProtocol) {
        print("AuthorizationService init")
        self.userProvider = userProvider
        self.errorHandler = errorHandler
        observeUserChanges()
    }
    
    deinit {
        print("AuthorizationService deinit")
    }
}

// MARK: - User state
extension AuthorizationService {
    
    /// Паблишер, который эмитит AuthUser или nil при logout/удалении.
    var authStatePublisher: AnyPublisher<AuthUser?, Never> {
        authStateSubject.eraseToAnyPublisher()
    }
    
    func observeUserChanges() {
        print("AuthorizationService func observeUserChanges() ")
        cancellable = userProvider.currentUserPublisher
            .sink { [weak self] authUser in
                print("AuthorizationService observeUserChanges() userProvider.currentUserPublisher имитет значение")
                self?.authStateSubject.send(authUser)
            }
    }
    
    // Для заполнения UI профиля:
    /// - user.displayName может быть nil после линковки, поэтому имя лучше брать из providerData.
    /// - В providerData[google.com] всегда есть displayName и email от Google.
    /// - Для надёжности: email → user.email, имя → provider.displayName.
    /// - Таким образом UI профиля заполняем комбинацией основных полей и providerData.
    
    // сдесь можно если мы захотим при линковки anon -> provider тригерить сохранение в CloudFirestore текущий profile
    // тригерить сохранение в CloudFirestore текущий profile (из emailProvider, googleProvider ...)
    // по тому что для обновления UI на UserInfoCellView мы обращаемся через UserInfoCellManager в userInfoCellManager.loadUserProfile(uid: uid)
    // вызов loadUserProfile(uid: uid) делается либо вручную либо при смене пользователя через паблишер либо возможно через addSnapshotListener (нужно проверить и если да то тут можно инициировать func updateProfile)
    
    private func updateAuthState(from user: FirebaseAuth.User) {
        // Распечатываем ключевые поля для отладки
            print("🔄 updateAuthState called")
            print("UID: \(user.uid)")
            print("isAnonymous: \(user.isAnonymous)")
            print("email: \(user.email ?? "nil")")
            print("displayName: \(user.displayName ?? "nil")")
            print("providerData:")
        // ⚡️ Важно:
        // user.email — это основной email, который Firebase хранит для аккаунта.
        // provider.email — это email, полученный от конкретного провайдера (например, google.com).
        // Они могут совпадать, но при нескольких провайдерах или смене email — различаться.

            for provider in user.providerData {
                print(" - providerID: \(provider.providerID), email: \(provider.email ?? "nil"), displayName: \(provider.displayName ?? "nil")")
            }
        let authUser = AuthUser(uid: user.uid, isAnonymous: user.isAnonymous)
        authStateSubject.send(authUser)
    }
}

// MARK: - Sign up / Link
extension AuthorizationService {
    
    /// Регистрация или линковка анонимного пользователя
    func signUpBasic(email: String, password: String) -> AnyPublisher<Void, Error> {
        currentUserPublisher()
            .flatMap { user -> AnyPublisher<AuthDataResult, Error> in
                if user.isAnonymous {
                    let cred = EmailAuthProvider.credential(withEmail: email, password: password)
                    return self.linkPublisher(user: user, credential: cred)
                } else {
                    return self.createUserPublisher(email: email, password: password)
                }
            }
            .map { _ in () }
            .eraseToAnyPublisher()
    }
    
    private func createUserPublisher(email: String, password: String) -> AnyPublisher<AuthDataResult, Error> {
        Future { promise in
            Auth.auth().createUser(withEmail: email, password: password) { res, err in
                if let error = err {
                    promise(.failure(error))
                } else if let result = res {
                    promise(.success(result))
                } else {
                    let _ = self.errorHandler.handle(error: AppInternalError.firebaseReturnedNilResult, context: ErrorContext.AuthorizationService_createUserPublisher.rawValue)
                    promise(.failure(AppInternalError.firebaseReturnedNilResult))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    private func linkPublisher(user: User, credential: AuthCredential) -> AnyPublisher<AuthDataResult, Error> {
        Future { [weak self] promise in
            user.link(with: credential) { res, err in
                print("linkPublisher res - \(String(describing: res)), error - \(String(describing: err))")
                if let error = err {
                    promise(.failure(error))
                } else if let result = res {
                    // 💡 Обновляем authState сразу — при успешной линковке addStateDidChangeListener может не отработать
                    self?.updateAuthState(from: result.user)
                    promise(.success(result))
                } else {
                    let _ = self?.errorHandler.handle(error: AppInternalError.firebaseReturnedNilResult, context: ErrorContext.AuthorizationService_linkPublisher.rawValue)
                    promise(.failure(AppInternalError.firebaseReturnedNilResult))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}

// MARK: - Sign in / Out
extension AuthorizationService {
    
    /// Логирование; при необходимости удаление анонимного пользователя после входа
    func signInBasic(email: String, password: String) -> AnyPublisher<Void, Error> {
        currentUserPublisher()
            .flatMap { [weak self] user -> AnyPublisher<Void, Error> in
                guard let self = self else {
                    return Fail(error: FirebaseInternalError.defaultError).eraseToAnyPublisher()
                }
                if user.isAnonymous {
                    // Сохраняем UID анонима (если далее понадобится cleanup)
                    let anonUid = user.uid
                    print("anonUid func signInBasic - \(anonUid)")
                    return self.signInPublisher(email: email, password: password)
                        // .flatMap { _ in self.cleanupAnonymous(anonUid: anonUid) }
                        .map { _ in () }
                        .eraseToAnyPublisher()
                } else {
                    print("permanentUser func signInBasic - \(user.uid)")
                    return self.signInPublisher(email: email, password: password)
                        .map { _ in () }
                        .eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
    }
    
    private func signInPublisher(email: String, password: String) -> AnyPublisher<AuthDataResult, Error> {
        Future { promise in
            Auth.auth().signIn(withEmail: email, password: password) { res, err in
                if let err = err {
                    promise(.failure(err))
                } else if let result = res {
                    promise(.success(result))
                } else {
                    // Обязательно логировать: неизвестное состояние
                    promise(.failure(FirebaseInternalError.defaultError))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// Выход (локально)
    func signOut() -> AnyPublisher<Void, Error> {
        Future { promise in
            do {
                try Auth.auth().signOut()
                promise(.success(()))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
}

// MARK: - Account deletion
extension AuthorizationService {
    
    /// Удаление аккаунта с маппингом ошибок, требующих реаутентификации
    func deleteAccount() -> AnyPublisher<Void, DeleteAccountError> {
        Future<Void, DeleteAccountError> { promise in
            guard let user = Auth.auth().currentUser else {
                promise(.failure(.underlying(AppInternalError.notSignedIn)))
                return
            }
            user.delete { error in
                if let nsError = error as NSError? {
                    if let code = AuthErrorCode(rawValue: nsError.code) {
                        switch code {
                        case .requiresRecentLogin,
                             .userTokenExpired,
                             .invalidUserToken,
                             .invalidCredential:
                            // Все эти ошибки требуют повторной аутентификации
                            promise(.failure(.reauthenticationRequired(nsError)))
                        default:
                            promise(.failure(.underlying(nsError)))
                        }
                    } else {
                        promise(.failure(.underlying(nsError)))
                    }
                } else {
                    promise(.success(()))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}

// MARK: - Reauthentication
extension AuthorizationService {
    
    /// Повторная аутентификация через email+password
    func reauthenticate(email: String, password: String) -> AnyPublisher<Void, Error> {
        Future<Void, Error> { promise in
            guard let user = Auth.auth().currentUser else {
                return promise(.failure(FirebaseInternalError.notSignedIn))
            }
            let credential = EmailAuthProvider.credential(withEmail: email, password: password)
            user.reauthenticate(with: credential) { _, error in
                if let error = error {
                    promise(.failure(error))
                } else {
                    promise(.success(()))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}

// MARK: - SendPasswordReset
extension AuthorizationService {
    /// Отправка письма для сброса пароля
    func sendPasswordReset(email: String) -> AnyPublisher<Void, Error> {
        // Установка языка письма через Firebase на основе текущего языка приложения
        // Используем singleton LocalizationService.shared, доступный глобально
//        print("sendPasswordReset / LocalizationService.shared.currentLanguage - \(LocalizationService.shared.currentLanguage)")
        Auth.auth().languageCode = LocalizationService.shared.currentLanguage

        return Future<Void, Error> { promise in
            Auth.auth().sendPasswordReset(withEmail: email) { error in
                if let error = error {
                    promise(.failure(error))
                } else {
                    promise(.success(()))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}


// MARK: - Verification
extension AuthorizationService {
    
    /// Отправка письма подтверждения
    func sendVerificationEmail() {
        Auth.auth().currentUser?.sendEmailVerification { error in
            let _ = self.errorHandler.handle(error: error, context: ErrorContext.AuthorizationService_sendVerificationEmail.rawValue)
        }
    }
}


// MARK: - Auth providers
extension AuthorizationService {
    
    /// Publisher, который эмитит список всех провайдеров текущего пользователя
    func authProvidersPublisher() -> AnyPublisher<[String], Never> {
        let providers = Auth.auth().currentUser?.providerData.map { $0.providerID } ?? []
        return Just(providers)
            .eraseToAnyPublisher()
    }
    
    /// Publisher, который эмитит основной провайдер (обычно первый)
    func primaryAuthProviderPublisher() -> AnyPublisher<String?, Never> {
        let provider = Auth.auth().currentUser?.providerData.first?.providerID
        return Just(provider)
            .eraseToAnyPublisher()
    }
}

// MARK: - currentUser
extension AuthorizationService {
    
    /// Текущий Firebase User как publisher (ошибка, если не залогинен)
    private func currentUserPublisher() -> AnyPublisher<User, Error> {
        guard let user = Auth.auth().currentUser else {
            return Fail(error: AppInternalError.notSignedIn).eraseToAnyPublisher()
        }
        return Just(user)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}


// MARK: - Google Auth

extension AuthorizationService {

    /// 🔎 Подробное описание последовательности работы Google Sign-In:
    ///
    /// 1. Вызов `signInWithGoogle(intent:)`
    ///    - Получаем текущего пользователя через `currentUserPublisher()`.
    ///    - Логируем его UID и статус (анонимный или постоянный).
    ///
    /// 2. Запускаем `getGoogleCredential()`
    ///    - Проверяем наличие `clientID` в FirebaseApp.options.
    ///    - Конфигурируем `GIDSignIn` с этим clientID.
    ///    - На главном потоке ищем верхний UIViewController (`presentingVC`).
    ///    - Вызываем `GIDSignIn.sharedInstance.signIn(withPresenting:)`.
    ///
    /// 3. На экране Google пользователь выбирает аккаунт и подтверждает вход.
    ///    - После подтверждения отрабатывает completion-блок `signIn(...)`.
    ///    - В блоке получаем `idToken` и `accessToken` от Google.
    ///    - Формируем `AuthCredential` через `GoogleAuthProvider.credential(...)`.
    ///    - Возвращаем credential в publisher.
    ///
    /// 4. Возврат в `signInWithGoogle(intent:)`
    ///    - В зависимости от intent:
    ///      • `.signIn`: выполняем `googleSignInReplacingSession(credential:)`
    ///        → создаём новый аккаунт, если его нет, или входим в существующий.
    ///      • `.signUp`: проверяем статус пользователя:
    ///          ◦ Если анонимный → выполняем `googleLinkAnonymous(user, credential)`
    ///            → линковка: сохраняем UID и данные, превращаем анонимного в постоянного.
    ///          ◦ Если уже постоянный → выполняем `googleSignInReplacingSession(credential:)`
    ///            → создаём/входим в Google-аккаунт, UID меняется, старый остаётся.
    ///
    /// 📌 Таким образом:
    /// - `getGoogleCredential()` отвечает за получение токенов и формирование Firebase credential.
    /// - `signInWithGoogle(intent:)` решает, что делать с этим credential:
    ///   либо линковать анонимного пользователя, либо заменить текущую сессию входом через Google.

    func signInWithGoogle(intent: GoogleAuthIntent) -> AnyPublisher<Void, Error> {
        currentUserPublisher()
            .flatMap { [weak self] user -> AnyPublisher<Void, Error> in
                guard let self else {
                    return Fail(error: AppInternalError.entityDeallocated).eraseToAnyPublisher()
                }
                return self.getGoogleCredential()
                    .flatMap { credential -> AnyPublisher<Void, Error> in
                        switch intent {
                        case .signIn:
                            // Anonymous/Permanent → вход: создаст новый аккаунт, если его нет; войдёт, если есть
                            return self.googleSignInReplacingSession(credential: credential)

                        case .signUp:
                            if user.isAnonymous {
                                // Anonymous → линк (сохранить UID и данные)
                                return self.googleLinkAnonymous(user: user, credential: credential)
                            } else {
                                // Permanent → создаём/входим в Google-аккаунт (UID меняется; старый остаётся)
                                return self.googleSignInReplacingSession(credential: credential)
                            }
                        }
                    }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }


    // MARK: - Получение Google credential
    
    /// Зачем нужен `presentingVC`:
    /// - Google Sign-In показывает UI (экран выбора аккаунта / веб-страницу авторизации) **модально поверх текущего экрана**.
    /// - Для корректной презентации модального интерфейса UIKit требует знать, **из какого контроллера** показывать этот UI.
    /// - Поэтому SDK GoogleSignIn просит передать `UIViewController`, из которого он будет презентовать своё окно:
    ///   `GIDSignIn.sharedInstance.signIn(withPresenting: presentingVC, ...)`.
    ///
    /// Почему мы ищем именно «верхний» контроллер:
    /// - В SwiftUI корневой контроллер — это `UIHostingController`, но фактически интерфейс может находиться:
    ///   - внутри выбранной вкладки (`UITabBarController` → `selectedViewController`),
    ///   - внутри навигационного стека (`UINavigationController` → `visibleViewController`),
    ///   - в модально показанном представлении (`presentedViewController`).
    /// - Если презентовать не из верхнего контроллера, модальное окно может не отобразиться или появиться «за кадром».
    /// - Метод `topViewController()` поднимается по иерархии и возвращает **актуальный верхний VC**, доступный для презентации.
    ///
    /// Как это работает в iOS:
    /// - При нажатии «Войти через Google» мы берём верхний VC активного окна/сцены и передаём его в GoogleSignIn.
    /// - SDK открывает авторизацию поверх него (встроенный веб-контроллер/контроллер выбора аккаунта).
    /// - После выбора аккаунта система возвращает результат обратно в приложение по URL‑схеме (`REVERSED_CLIENT_ID`),
    ///   а `AppDelegate.application(_:open:options:)` передаёт URL в `GIDSignIn.sharedInstance.handle(url)` для завершения авторизации.
    ///
    /// Важно:
    /// - Всегда выполняем получение `presentingVC` и вызов `signIn(withPresenting:)` на **главном потоке** — это требования UIKit.
    /// - В многооконных сценариях (iPad, multiwindow) мы ищем контроллер **в активной сцене**, чтобы презентовать именно там,
    ///   где пользователь взаимодействует с приложением.
    private func getGoogleCredential() -> AnyPublisher<AuthCredential, Error> {
        Future<AuthCredential, Error> { promise in

            guard let clientID = FirebaseApp.app()?.options.clientID else {
                return promise(.failure(AppInternalError.googleMissingClientID))
            }
            let config = GIDConfiguration(clientID: clientID)
            GIDSignIn.sharedInstance.configuration = config

            // Гарантируем главный поток для UI-презентации
            DispatchQueue.main.async {
                guard let presentingVC = Self.topViewController() else {
                    return promise(.failure(AppInternalError.googleMissingPresentingVC))
                }

                GIDSignIn.sharedInstance.signIn(withPresenting: presentingVC) { result, error in
                    if let error = error {
                        return promise(.failure(error))
                    }
                    guard
                        let gUser = result?.user,
                        let idToken = gUser.idToken?.tokenString
                    else {
                        return promise(.failure(AppInternalError.googleMissingTokens))
                    }

                    let accessToken = gUser.accessToken.tokenString
                    let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
                    promise(.success(credential))
                }
            }
        }
        .eraseToAnyPublisher()
    }


    // MARK: - Replace session (SignIn/SignUp permanent)
    private func googleSignInReplacingSession(credential: AuthCredential) -> AnyPublisher<Void, Error> {
        Future<Void, Error> { [weak self] promise in
/*
         ⚠️ Важно:
         Вызов Auth.auth().signIn(with:) ведёт себя как "Sign In + Sign Up".
         - Если Google‑аккаунт уже существует в Firebase → произойдёт вход в существующего пользователя (UID того аккаунта).
         - Если аккаунта ещё нет → Firebase автоматически создаст нового пользователя с новым UID и выполнит вход.
         
         ❌ Ошибка credentialAlreadyInUse здесь НЕ возникает.
         Она характерна только для link(with:), когда пытаешься привязать Google‑аккаунт к текущему UID.
         
         👉 Итог: этот метод всегда переключает текущую сессию на Google‑аккаунт —
         либо существующий, либо новый.
        */
            Auth.auth().signIn(with: credential) { res, err in
                if let err = err {
                    return promise(.failure(err))
                }
                // 2. Проверяем self отдельно — это отдельный сценарий
                guard let self else {
                    return promise(.failure(AppInternalError.entityDeallocated))
                }
                
                // 3. Firebase вернул nil вместо результата → это наш общий кейс
                guard let _ = res?.user else {
                    let _ = self.errorHandler.handle(
                        error: AppInternalError.firebaseReturnedNilResult,
                        context: ErrorContext.AuthorizationService_googleSignInReplacingSession.rawValue
                    )
                    return promise(.failure(AppInternalError.firebaseReturnedNilResult))
                }
// тут не нужно так как  Auth.auth().signIn(with: credential) вызовет блок в addStateDidChangeListener
//                self.updateAuthState(from: user)
                promise(.success(()))
            }
        }
        .eraseToAnyPublisher()
    }

    // MARK: - Anonymous → Link (SignUp)
    private func googleLinkAnonymous(user: User, credential: AuthCredential) -> AnyPublisher<Void, Error> {
        Future<Void, Error> { [weak self] promise in
            user.link(with: credential) { res, err in
                if let err = err {
                    // Если credential уже используется другим UID → это не линковка; в твоей политике линковку не продолжаем
                    // Можно сообщить пользователю, что этот Google-аккаунт уже зарегистрирован — используйте Sign In.
                    return promise(.failure(err))
                } else if let result = res {
                    self?.updateAuthState(from: result.user) // listener не гарантирован
                    promise(.success(()))
                } else {
                    let _ = self?.errorHandler.handle(error: AppInternalError.firebaseReturnedNilResult, context: ErrorContext.AuthorizationService_googleLinkAnonymous.rawValue)
                    promise(.failure(AppInternalError.firebaseReturnedNilResult))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}

// MARK: - Google Reauthenticate
extension AuthorizationService {

    func reauthenticateWithGoogle() -> AnyPublisher<Void, Error> {
        Future<Void, Error> { promise in
            guard let currentUser = Auth.auth().currentUser else {
                return promise(.failure(FirebaseInternalError.notSignedIn))
            }
            guard let clientID = FirebaseApp.app()?.options.clientID else {
                return promise(.failure(FirebaseInternalError.defaultError))
            }
            let config = GIDConfiguration(clientID: clientID)
            GIDSignIn.sharedInstance.configuration = config

            guard let presentingVC = Self.topViewController() else {
                return promise(.failure(FirebaseInternalError.defaultError))
            }
            
            GIDSignIn.sharedInstance.signIn(withPresenting: presentingVC) { result, error in
                if let error = error {
                    return promise(.failure(error))
                }
                guard let gUser = result?.user,
                      let idToken = gUser.idToken?.tokenString else {
                    return promise(.failure(FirebaseInternalError.defaultError))
                }
                let accessToken = gUser.accessToken.tokenString
                let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
                currentUser.reauthenticate(with: credential) { _, error in
                    if let error = error {
                        return promise(.failure(error))
                    }
                    return promise(.success(()))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}

// MARK: - Top ViewController Utilities

// это сложный поиск того UIViewController который сейчас на экране
// можно передавать на прямую vc из экрана вызова google signIn
extension AuthorizationService {

    /// Определяет верхний UIViewController, подходящий для показа UI (например, Google Sign-In).
    ///
    /// Пошагово:
    /// 1. Получаем все подключённые сцены из UIApplication.
    /// 2. Фильтруем только активные (foregroundActive) UIWindowScene — именно из них можно презентовать UI.
    /// 3. Пытаемся найти keyWindow среди активных сцен и берём его rootViewController.
    /// 4. Если keyWindow не найден, используем первый видимый (не скрытый, alpha > 0) window и его rootViewController.
    /// 5. Рекурсивно поднимаемся по иерархии контроллеров:
    ///    - Если это UINavigationController → возвращаем visibleViewController.
    ///    - Если UITabBarController → возвращаем selectedViewController.
    ///    - Если есть presentedViewController → возвращаем его.
    ///    - Иначе возвращаем базовый контроллер.
    ///
    /// Примечания:
    /// - Метод устойчив к мульти-сценам (iPad, multi-window) и временным состояниям UI.
    /// - Вызывать нужно на главном потоке перед показом UI.
    /// - Логи помогают отследить путь выбора контроллера; в продакшене можно обернуть их в `#if DEBUG`.
    static func topViewController(base: UIViewController? = {
        // MARK: сбор сцен
        let allScenes = UIApplication.shared.connectedScenes

        let activeScenes = allScenes
            .compactMap { $0 as? UIWindowScene }
            .filter { $0.activationState == .foregroundActive }

        // MARK: Попытка 1: keyWindow
        if let keyWindow = activeScenes
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow }) {
            let root = keyWindow.rootViewController
            return root
        }

        // MARK: Попытка 2: первый видимый window
        if let visibleWindow = activeScenes
            .flatMap({ $0.windows })
            .first(where: { !$0.isHidden && $0.alpha > 0 }) {
            let root = visibleWindow.rootViewController
            return root
        }

        // MARK: Попытка 3: fallback без устаревшего API
        return nil
    }()) -> UIViewController? {
        // Рекурсивно определяем верхний VC
        if let nav = base as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        }
        if let tab = base as? UITabBarController {
            return topViewController(base: tab.selectedViewController)
        }
        if let presented = base?.presentedViewController {
            return topViewController(base: presented)
        }
        return base
    }
}

// MARK: - Google Auth с логами

//extension AuthorizationService {
//
//    /// 🔎 Подробное описание последовательности работы Google Sign-In:
//    ///
//    /// 1. Вызов `signInWithGoogle(intent:)`
//    ///    - Получаем текущего пользователя через `currentUserPublisher()`.
//    ///    - Логируем его UID и статус (анонимный или постоянный).
//    ///
//    /// 2. Запускаем `getGoogleCredential()`
//    ///    - Проверяем наличие `clientID` в FirebaseApp.options.
//    ///    - Конфигурируем `GIDSignIn` с этим clientID.
//    ///    - На главном потоке ищем верхний UIViewController (`presentingVC`).
//    ///    - Вызываем `GIDSignIn.sharedInstance.signIn(withPresenting:)`.
//    ///
//    /// 3. На экране Google пользователь выбирает аккаунт и подтверждает вход.
//    ///    - После подтверждения отрабатывает completion-блок `signIn(...)`.
//    ///    - В блоке получаем `idToken` и `accessToken` от Google.
//    ///    - Формируем `AuthCredential` через `GoogleAuthProvider.credential(...)`.
//    ///    - Возвращаем credential в publisher.
//    ///
//    /// 4. Возврат в `signInWithGoogle(intent:)`
//    ///    - В зависимости от intent:
//    ///      • `.signIn`: выполняем `googleSignInReplacingSession(credential:)`
//    ///        → создаём новый аккаунт, если его нет, или входим в существующий.
//    ///      • `.signUp`: проверяем статус пользователя:
//    ///          ◦ Если анонимный → выполняем `googleLinkAnonymous(user, credential)`
//    ///            → линковка: сохраняем UID и данные, превращаем анонимного в постоянного.
//    ///          ◦ Если уже постоянный → выполняем `googleSignInReplacingSession(credential:)`
//    ///            → создаём/входим в Google-аккаунт, UID меняется, старый остаётся.
//    ///
//    /// 📌 Таким образом:
//    /// - `getGoogleCredential()` отвечает за получение токенов и формирование Firebase credential.
//    /// - `signInWithGoogle(intent:)` решает, что делать с этим credential:
//    ///   либо линковать анонимного пользователя, либо заменить текущую сессию входом через Google.
//
//    func signInWithGoogle(intent: GoogleAuthIntent) -> AnyPublisher<Void, Error> {
//        currentUserPublisher()
//            .flatMap { [weak self] user -> AnyPublisher<Void, Error> in
//                guard let self else {
//                    print("❌ [GoogleAuth] self = nil")
//                    return Fail(error: FirebaseInternalError.defaultError).eraseToAnyPublisher()
//                }
//                print("👤 [GoogleAuth] Текущий пользователь: \(user.uid), isAnonymous = \(user.isAnonymous)")
//                return self.getGoogleCredential()
//                    .flatMap { credential -> AnyPublisher<Void, Error> in
//                        print("🔑 [GoogleAuth] Получен credential, intent = \(intent)")
//                        switch intent {
//                        case .signIn:
//                            // Anonymous/Permanent → вход: создаст новый аккаунт, если его нет; войдёт, если есть
//                            return self.googleSignInReplacingSession(credential: credential)
//
//                        case .signUp:
//                            if user.isAnonymous {
//                                print("🔗 [GoogleAuth] Anonymous → Link")
//                                // Anonymous → линк (сохранить UID и данные)
//                                return self.googleLinkAnonymous(user: user, credential: credential)
//                            } else {
//                                print("🔄 [GoogleAuth] Permanent → SignInReplacingSession")
//                                // Permanent → создаём/входим в Google-аккаунт (UID меняется; старый остаётся)
//                                return self.googleSignInReplacingSession(credential: credential)
//                            }
//                        }
//                    }
//                    .eraseToAnyPublisher()
//            }
//            .eraseToAnyPublisher()
//    }
//
//
//    // MARK: - Получение Google credential
//    
//    /// Зачем нужен `presentingVC`:
//    /// - Google Sign-In показывает UI (экран выбора аккаунта / веб-страницу авторизации) **модально поверх текущего экрана**.
//    /// - Для корректной презентации модального интерфейса UIKit требует знать, **из какого контроллера** показывать этот UI.
//    /// - Поэтому SDK GoogleSignIn просит передать `UIViewController`, из которого он будет презентовать своё окно:
//    ///   `GIDSignIn.sharedInstance.signIn(withPresenting: presentingVC, ...)`.
//    ///
//    /// Почему мы ищем именно «верхний» контроллер:
//    /// - В SwiftUI корневой контроллер — это `UIHostingController`, но фактически интерфейс может находиться:
//    ///   - внутри выбранной вкладки (`UITabBarController` → `selectedViewController`),
//    ///   - внутри навигационного стека (`UINavigationController` → `visibleViewController`),
//    ///   - в модально показанном представлении (`presentedViewController`).
//    /// - Если презентовать не из верхнего контроллера, модальное окно может не отобразиться или появиться «за кадром».
//    /// - Метод `topViewController()` поднимается по иерархии и возвращает **актуальный верхний VC**, доступный для презентации.
//    ///
//    /// Как это работает в iOS:
//    /// - При нажатии «Войти через Google» мы берём верхний VC активного окна/сцены и передаём его в GoogleSignIn.
//    /// - SDK открывает авторизацию поверх него (встроенный веб-контроллер/контроллер выбора аккаунта).
//    /// - После выбора аккаунта система возвращает результат обратно в приложение по URL‑схеме (`REVERSED_CLIENT_ID`),
//    ///   а `AppDelegate.application(_:open:options:)` передаёт URL в `GIDSignIn.sharedInstance.handle(url)` для завершения авторизации.
//    ///
//    /// Важно:
//    /// - Всегда выполняем получение `presentingVC` и вызов `signIn(withPresenting:)` на **главном потоке** — это требования UIKit.
//    /// - В многооконных сценариях (iPad, multiwindow) мы ищем контроллер **в активной сцене**, чтобы презентовать именно там,
//    ///   где пользователь взаимодействует с приложением.
//    private func getGoogleCredential() -> AnyPublisher<AuthCredential, Error> {
//        Future<AuthCredential, Error> { promise in
//            print("➡️ [GoogleAuth] Запрос Google credential")
//
//            guard let clientID = FirebaseApp.app()?.options.clientID else {
//                print("❌ [GoogleAuth] Нет clientID в FirebaseApp.options")
//                return promise(.failure(FirebaseInternalError.defaultError))
//            }
//            let config = GIDConfiguration(clientID: clientID)
//            GIDSignIn.sharedInstance.configuration = config
//
//            // Гарантируем главный поток для UI-презентации
//            DispatchQueue.main.async {
//                guard let presentingVC = Self.topViewController() else {
//                    print("❌ [GoogleAuth] Не найден presentingVC")
//                    return promise(.failure(FirebaseInternalError.defaultError))
//                }
//                print("📱 [GoogleAuth] presentingVC найден: \(presentingVC)")
//
//                GIDSignIn.sharedInstance.signIn(withPresenting: presentingVC) { result, error in
//                    print("GIDSignIn.sharedInstance.signIn")
//                    if let error = error {
//                        print("❌ [GoogleAuth] Ошибка при signIn: \(error.localizedDescription)")
//                        return promise(.failure(error))
//                    }
//                    guard
//                        let gUser = result?.user,
//                        let idToken = gUser.idToken?.tokenString
//                    else {
//                        print("❌ [GoogleAuth] Нет idToken")
//                        return promise(.failure(FirebaseInternalError.defaultError))
//                    }
//
//                    let accessToken = gUser.accessToken.tokenString
//                    print("✅ [GoogleAuth] Получены токены: idToken длина=\(idToken.count), accessToken длина=\(accessToken.count)")
//
//                    let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
//                    print("🔑 [GoogleAuth] Сформирован credential")
//                    promise(.success(credential))
//                }
//            }
//        }
//        .eraseToAnyPublisher()
//    }
//
//
//    // MARK: - Replace session (SignIn/SignUp permanent)
//    private func googleSignInReplacingSession(credential: AuthCredential) -> AnyPublisher<Void, Error> {
//        Future<Void, Error> { [weak self] promise in
//            print("➡️ [GoogleAuth] SignInReplacingSession")
///*
//         ⚠️ Важно:
//         Вызов Auth.auth().signIn(with:) ведёт себя как "Sign In + Sign Up".
//         - Если Google‑аккаунт уже существует в Firebase → произойдёт вход в существующего пользователя (UID того аккаунта).
//         - Если аккаунта ещё нет → Firebase автоматически создаст нового пользователя с новым UID и выполнит вход.
//         
//         ❌ Ошибка credentialAlreadyInUse здесь НЕ возникает.
//         Она характерна только для link(with:), когда пытаешься привязать Google‑аккаунт к текущему UID.
//         
//         👉 Итог: этот метод всегда переключает текущую сессию на Google‑аккаунт —
//         либо существующий, либо новый.
//        */
//            Auth.auth().signIn(with: credential) { res, err in
//                if let err = err {
//                    print("❌ [GoogleAuth] Ошибка signIn: \(err.localizedDescription)")
//                    return promise(.failure(err))
//                }
//                guard let self, let user = res?.user else {
//                    print("❌ [GoogleAuth] Ошибка signIn: - нет self или user")
//                    return promise(.failure(FirebaseInternalError.defaultError))
//                }
//                print("✅ [GoogleAuth] Успешный вход: uid=\(user.uid), email=\(user.email ?? "nil")")
//// тут не нужно так как  Auth.auth().signIn(with: credential) вызовет блок в addStateDidChangeListener
////                self.updateAuthState(from: user)
//                promise(.success(()))
//            }
//        }
//        .eraseToAnyPublisher()
//    }
//
//    // MARK: - Anonymous → Link (SignUp)
//    private func googleLinkAnonymous(user: User, credential: AuthCredential) -> AnyPublisher<Void, Error> {
//        Future<Void, Error> { [weak self] promise in
//            print("➡️ [GoogleAuth] Anonymous → Link для uid=\(user.uid)")
//            user.link(with: credential) { res, err in
//                if let err = err {
//                    print("❌ [GoogleAuth] Ошибка link: \(err.localizedDescription)")
//                    // Если credential уже используется другим UID → это не линковка; в твоей политике линковку не продолжаем
//                    // Можно сообщить пользователю, что этот Google-аккаунт уже зарегистрирован — используйте Sign In.
//                    return promise(.failure(err))
//                } else if let result = res {
//                    print("✅ [GoogleAuth] Успешная линковка: новый uid=\(result.user.uid)")
//                    self?.updateAuthState(from: result.user) // listener не гарантирован
//                    promise(.success(()))
//                } else {
//                    print("❌ [GoogleAuth] Неизвестная ошибка при линковке")
//                    promise(.failure(FirebaseInternalError.defaultError))
//                }
//            }
//        }
//        .eraseToAnyPublisher()
//    }
//}
//
//// MARK: - Google Reauthenticate
//extension AuthorizationService {
//
//    func reauthenticateWithGoogle() -> AnyPublisher<Void, Error> {
//        Future<Void, Error> { promise in
//            print("➡️ [GoogleAuth] Начало reauthenticateWithGoogle()")
//            guard let currentUser = Auth.auth().currentUser else {
//                print("❌ [GoogleAuth] Нет текущего пользователя — reauth невозможен")
//                return promise(.failure(FirebaseInternalError.notSignedIn))
//            }
//            print("👤 [GoogleAuth] Текущий пользователь: uid=\(currentUser.uid), email=\(currentUser.email ?? "nil")")
//            guard let clientID = FirebaseApp.app()?.options.clientID else {
//                print("❌ [GoogleAuth] Нет clientID в FirebaseApp.options")
//                return promise(.failure(FirebaseInternalError.defaultError))
//            }
//            print("🔑 [GoogleAuth] Получен clientID из FirebaseApp.options")
//            let config = GIDConfiguration(clientID: clientID)
//            GIDSignIn.sharedInstance.configuration = config
//
//            guard let presentingVC = Self.topViewController() else {
//                print("❌ [GoogleAuth] Не найден presentingVC для показа Google Sign-In")
//                return promise(.failure(FirebaseInternalError.defaultError))
//            }
//
//            print("📱 [GoogleAuth] presentingVC найден: \(presentingVC)")
//            
//            GIDSignIn.sharedInstance.signIn(withPresenting: presentingVC) { result, error in
//                if let error = error {
//                    print("❌ [GoogleAuth] Ошибка при signIn: \(error.localizedDescription)")
//                    return promise(.failure(error))
//                }
//                guard let gUser = result?.user,
//                      let idToken = gUser.idToken?.tokenString else {
//                    print("❌ [GoogleAuth] Нет idToken в результате Google Sign-In")
//                    return promise(.failure(FirebaseInternalError.defaultError))
//                }
//                let accessToken = gUser.accessToken.tokenString
//                print("✅ [GoogleAuth] Получены токены: idToken длина=\(idToken.count), accessToken длина=\(accessToken.count)")
//                let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
//                print("🔑 [GoogleAuth] Сформирован credential для reauthenticate")
//                currentUser.reauthenticate(with: credential) { _, error in
//                    if let error = error {
//                        print("❌ [GoogleAuth] Ошибка при reauthenticate: \(error.localizedDescription)")
//                        return promise(.failure(error))
//                    }
//                    print("✅ [GoogleAuth] Успешная reauthenticate для uid=\(currentUser.uid)")
//                    return promise(.success(()))
//                }
//            }
//        }
//        .eraseToAnyPublisher()
//    }
//}
//
//// MARK: - Top ViewController Utilities
//
//// это сложный поиск того UIViewController который сейчас на экране
//// можно передавать на прямую vc из экрана вызова google signIn
//extension AuthorizationService {
//
//    /// Определяет верхний UIViewController, подходящий для показа UI (например, Google Sign-In).
//    ///
//    /// Пошагово:
//    /// 1. Получаем все подключённые сцены из UIApplication.
//    /// 2. Фильтруем только активные (foregroundActive) UIWindowScene — именно из них можно презентовать UI.
//    /// 3. Пытаемся найти keyWindow среди активных сцен и берём его rootViewController.
//    /// 4. Если keyWindow не найден, используем первый видимый (не скрытый, alpha > 0) window и его rootViewController.
//    /// 5. Рекурсивно поднимаемся по иерархии контроллеров:
//    ///    - Если это UINavigationController → возвращаем visibleViewController.
//    ///    - Если UITabBarController → возвращаем selectedViewController.
//    ///    - Если есть presentedViewController → возвращаем его.
//    ///    - Иначе возвращаем базовый контроллер.
//    ///
//    /// Примечания:
//    /// - Метод устойчив к мульти-сценам (iPad, multi-window) и временным состояниям UI.
//    /// - Вызывать нужно на главном потоке перед показом UI.
//    /// - Логи помогают отследить путь выбора контроллера; в продакшене можно обернуть их в `#if DEBUG`.
//    static func topViewController(base: UIViewController? = {
//        // MARK: Логи: сбор сцен
//        let allScenes = UIApplication.shared.connectedScenes
//        print("🔎 [TopVC] Количество подключённых сцен: \(allScenes.count)")
//
//        let activeScenes = allScenes
//            .compactMap { $0 as? UIWindowScene }
//            .filter { $0.activationState == .foregroundActive }
//
//        print("🔎 [TopVC] Активные UIWindowScene: \(activeScenes.count)")
//
//        // MARK: Попытка 1: keyWindow
//        if let keyWindow = activeScenes
//            .flatMap({ $0.windows })
//            .first(where: { $0.isKeyWindow }) {
//            print("✅ [TopVC] Используем keyWindow: \(keyWindow)")
//            let root = keyWindow.rootViewController
//            print("✅ [TopVC] keyWindow.rootViewController: \(String(describing: root))")
//            return root
//        }
//
//        // MARK: Попытка 2: первый видимый window
//        if let visibleWindow = activeScenes
//            .flatMap({ $0.windows })
//            .first(where: { !$0.isHidden && $0.alpha > 0 }) {
//            print("✅ [TopVC] Используем видимый window (fallback): \(visibleWindow)")
//            let root = visibleWindow.rootViewController
//            print("✅ [TopVC] visibleWindow.rootViewController: \(String(describing: root))")
//            return root
//        }
//
//        // MARK: Попытка 3: fallback без устаревшего API
//        print("⚠️ [TopVC] Не найдено активное окно, возвращаем nil")
//        return nil
//    }()) -> UIViewController? {
//        // Рекурсивно определяем верхний VC
//        if let nav = base as? UINavigationController {
//            print("🔼 [TopVC] UINavigationController → visibleViewController: \(String(describing: nav.visibleViewController))")
//            return topViewController(base: nav.visibleViewController)
//        }
//        if let tab = base as? UITabBarController {
//            print("🔼 [TopVC] UITabBarController → selectedViewController: \(String(describing: tab.selectedViewController))")
//            return topViewController(base: tab.selectedViewController)
//        }
//        if let presented = base?.presentedViewController {
//            print("🔼 [TopVC] Presented → \(String(describing: presented))")
//            return topViewController(base: presented)
//        }
//        print("🏁 [TopVC] Итоговый VC: \(String(describing: base))")
//        return base
//    }
//}



















//extension AuthorizationService {
//    static func topViewController(base: UIViewController? = {
//        let scenes = UIApplication.shared.connectedScenes
//        let windowScene = scenes.first { $0.activationState == .foregroundActive } as? UIWindowScene
//        let window = windowScene?.windows.first { $0.isKeyWindow }
//        return window?.rootViewController
//    }()) -> UIViewController? {
//        if let nav = base as? UINavigationController { return topViewController(base: nav.visibleViewController) }
//        if let tab = base as? UITabBarController { return topViewController(base: tab.selectedViewController) }
//        if let presented = base?.presentedViewController { return topViewController(base: presented) }
//        return base
//    }
//}




//    private func getGoogleCredential() -> AnyPublisher<AuthCredential, Error> {
//        Future<AuthCredential, Error> { promise in
//            print("➡️ [GoogleAuth] Запрос Google credential")
//            guard let clientID = FirebaseApp.app()?.options.clientID else {
//                print("❌ [GoogleAuth] Нет clientID в FirebaseApp.options")
//                return promise(.failure(FirebaseInternalError.defaultError))
//            }
//            let config = GIDConfiguration(clientID: clientID)
//            GIDSignIn.sharedInstance.configuration = config
//
//            guard let presentingVC = Self.topViewController() else {
//                print("❌ [GoogleAuth] Не найден presentingVC")
//                return promise(.failure(FirebaseInternalError.defaultError))
//            }
//
//            GIDSignIn.sharedInstance.signIn(withPresenting: presentingVC) { result, error in
//                if let error = error {
//                    print("❌ [GoogleAuth] Ошибка при signIn: \(error.localizedDescription)")
//                    return promise(.failure(error))
//                }
//                guard
//                    let gUser = result?.user,
//                    let idToken = gUser.idToken?.tokenString
//                else {
//                    print("❌ [GoogleAuth] Нет idToken")
//                    return promise(.failure(FirebaseInternalError.defaultError))
//                }
//                let accessToken = gUser.accessToken.tokenString
//                print("✅ [GoogleAuth] Получены токены: idToken длина=\(idToken.count), accessToken длина=\(accessToken.count)")
//                let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
//                promise(.success(credential))
//            }
//        }
//        .eraseToAnyPublisher()
//    }
//











// MARK: - before Google credential

//import FirebaseAuth
//import Combine
//
//
//// Ошибка, специфичная для deleteAccount()
//enum DeleteAccountError: Error {
//    /// Firebase вернул код .requiresRecentLogin
//    case reauthenticationRequired(Error)
//    /// Любая другая ошибка — оборачиваем оригинальный Error
//    case underlying(Error)
//}
//
//
//
//final class AuthorizationService {
//    
//    // MARK: - Dependencies
//    private let userProvider: CurrentUserProvider
//    
//    // MARK: - Publishers & Storage
//    private var cancellable: AnyCancellable?
//    private let authStateSubject = PassthroughSubject<AuthUser?, Never>()
//    
//    // MARK: - Init
//    init(userProvider: CurrentUserProvider) {
//        print("AuthorizationService init")
//        self.userProvider = userProvider
//        observeUserChanges()
//    }
//    
//    deinit {
//        print("AuthorizationService deinit")
//    }
//}
//
//// MARK: - User state
//extension AuthorizationService {
//    
//    /// Паблишер, который эмитит AuthUser или nil при logout/удалении.
//    var authStatePublisher: AnyPublisher<AuthUser?, Never> {
//        authStateSubject.eraseToAnyPublisher()
//    }
//    
//    func observeUserChanges() {
//        cancellable = userProvider.currentUserPublisher
//            .sink { [weak self] authUser in
//                print("🔄 AuthorizationService получил нового пользователя: \(String(describing: authUser))")
//                self?.authStateSubject.send(authUser)
//            }
//    }
//    
//    private func updateAuthState(from user: FirebaseAuth.User) {
//        // Распечатываем ключевые поля для отладки
//            print("🔄 updateAuthState called")
//            print("UID: \(user.uid)")
//            print("isAnonymous: \(user.isAnonymous)")
//            print("email: \(user.email ?? "nil")")
//            print("displayName: \(user.displayName ?? "nil")")
//            print("providerData:")
//        // ⚡️ Важно:
//        // user.email — это основной email, который Firebase хранит для аккаунта.
//        // provider.email — это email, полученный от конкретного провайдера (например, google.com).
//        // Они могут совпадать, но при нескольких провайдерах или смене email — различаться.
//
//            for provider in user.providerData {
//                print(" - providerID: \(provider.providerID), email: \(provider.email ?? "nil"), displayName: \(provider.displayName ?? "nil")")
//            }
//        let authUser = AuthUser(uid: user.uid, isAnonymous: user.isAnonymous)
//        authStateSubject.send(authUser)
//    }
//}
//
//// MARK: - Sign up / Link
//extension AuthorizationService {
//    
//    /// Регистрация или линковка анонимного пользователя
//    func signUpBasic(email: String, password: String) -> AnyPublisher<Void, Error> {
//        currentUserPublisher()
//            .flatMap { user -> AnyPublisher<AuthDataResult, Error> in
//                if user.isAnonymous {
//                    let cred = EmailAuthProvider.credential(withEmail: email, password: password)
//                    return self.linkPublisher(user: user, credential: cred)
//                } else {
//                    return self.createUserPublisher(email: email, password: password)
//                }
//            }
//            .map { _ in () }
//            .eraseToAnyPublisher()
//    }
//    
//    private func createUserPublisher(email: String, password: String) -> AnyPublisher<AuthDataResult, Error> {
//        Future { promise in
//            Auth.auth().createUser(withEmail: email, password: password) { res, err in
//                if let error = err {
//                    promise(.failure(error))
//                } else if let result = res {
//                    promise(.success(result))
//                } else {
//                    // Обязательно логировать: неизвестное состояние
//                    promise(.failure(FirebaseInternalError.defaultError))
//                }
//            }
//        }
//        .eraseToAnyPublisher()
//    }
//    
//    private func linkPublisher(user: User, credential: AuthCredential) -> AnyPublisher<AuthDataResult, Error> {
//        Future { [weak self] promise in
//            user.link(with: credential) { res, err in
//                print("linkPublisher res - \(String(describing: res)), error - \(String(describing: err))")
//                if let error = err {
//                    promise(.failure(error))
//                } else if let result = res {
//                    // 💡 Обновляем authState сразу — при успешной линковке addStateDidChangeListener может не отработать
//                    self?.updateAuthState(from: result.user)
//                    promise(.success(result))
//                } else {
//                    // Обязательно логировать: неизвестное состояние
//                    promise(.failure(FirebaseInternalError.defaultError))
//                }
//            }
//        }
//        .eraseToAnyPublisher()
//    }
//}
//
//// MARK: - Sign in / Out
//extension AuthorizationService {
//    
//    /// Логирование; при необходимости удаление анонимного пользователя после входа
//    func signInBasic(email: String, password: String) -> AnyPublisher<Void, Error> {
//        currentUserPublisher()
//            .flatMap { [weak self] user -> AnyPublisher<Void, Error> in
//                guard let self = self else {
//                    return Fail(error: FirebaseInternalError.defaultError).eraseToAnyPublisher()
//                }
//                if user.isAnonymous {
//                    // Сохраняем UID анонима (если далее понадобится cleanup)
//                    let anonUid = user.uid
//                    print("anonUid func signInBasic - \(anonUid)")
//                    return self.signInPublisher(email: email, password: password)
//                        // .flatMap { _ in self.cleanupAnonymous(anonUid: anonUid) }
//                        .map { _ in () }
//                        .eraseToAnyPublisher()
//                } else {
//                    print("permanentUser func signInBasic - \(user.uid)")
//                    return self.signInPublisher(email: email, password: password)
//                        .map { _ in () }
//                        .eraseToAnyPublisher()
//                }
//            }
//            .eraseToAnyPublisher()
//    }
//    
//    private func signInPublisher(email: String, password: String) -> AnyPublisher<AuthDataResult, Error> {
//        Future { promise in
//            Auth.auth().signIn(withEmail: email, password: password) { res, err in
//                if let err = err {
//                    promise(.failure(err))
//                } else if let result = res {
//                    promise(.success(result))
//                } else {
//                    // Обязательно логировать: неизвестное состояние
//                    promise(.failure(FirebaseInternalError.defaultError))
//                }
//            }
//        }
//        .eraseToAnyPublisher()
//    }
//    
//    /// Выход (локально)
//    func signOut() -> AnyPublisher<Void, Error> {
//        Future { promise in
//            do {
//                try Auth.auth().signOut()
//                promise(.success(()))
//            } catch {
//                promise(.failure(error))
//            }
//        }
//        .eraseToAnyPublisher()
//    }
//}
//
//// MARK: - Account deletion
//extension AuthorizationService {
//    
//    /// Удаление аккаунта с маппингом ошибок, требующих реаутентификации
//    func deleteAccount() -> AnyPublisher<Void, DeleteAccountError> {
//        Future<Void, DeleteAccountError> { promise in
//            guard let user = Auth.auth().currentUser else {
//                promise(.failure(.underlying(FirebaseInternalError.notSignedIn)))
//                return
//            }
//            user.delete { error in
//                if let nsError = error as NSError? {
//                    if let code = AuthErrorCode(rawValue: nsError.code) {
//                        switch code {
//                        case .requiresRecentLogin,
//                             .userTokenExpired,
//                             .invalidUserToken,
//                             .invalidCredential:
//                            // Все эти ошибки требуют повторной аутентификации
//                            promise(.failure(.reauthenticationRequired(nsError)))
//                        default:
//                            promise(.failure(.underlying(nsError)))
//                        }
//                    } else {
//                        promise(.failure(.underlying(nsError)))
//                    }
//                } else {
//                    promise(.success(()))
//                }
//            }
//        }
//        .eraseToAnyPublisher()
//    }
//}
//
//// MARK: - Reauthentication
//extension AuthorizationService {
//    
//    /// Повторная аутентификация через email+password
//    func reauthenticate(email: String, password: String) -> AnyPublisher<Void, Error> {
//        Future<Void, Error> { promise in
//            guard let user = Auth.auth().currentUser else {
//                return promise(.failure(FirebaseInternalError.notSignedIn))
//            }
//            let credential = EmailAuthProvider.credential(withEmail: email, password: password)
//            user.reauthenticate(with: credential) { _, error in
//                if let error = error {
//                    promise(.failure(error))
//                } else {
//                    promise(.success(()))
//                }
//            }
//        }
//        .eraseToAnyPublisher()
//    }
//}
//
//// MARK: - SendPasswordReset
//extension AuthorizationService {
//    /// Отправка письма для сброса пароля
//    func sendPasswordReset(email: String) -> AnyPublisher<Void, Error> {
//        // Установка языка письма через Firebase на основе текущего языка приложения
//        // Используем singleton LocalizationService.shared, доступный глобально
////        print("sendPasswordReset / LocalizationService.shared.currentLanguage - \(LocalizationService.shared.currentLanguage)")
//        Auth.auth().languageCode = LocalizationService.shared.currentLanguage
//
//        return Future<Void, Error> { promise in
//            Auth.auth().sendPasswordReset(withEmail: email) { error in
//                if let error = error {
//                    promise(.failure(error))
//                } else {
//                    promise(.success(()))
//                }
//            }
//        }
//        .eraseToAnyPublisher()
//    }
//}
//
//
//// MARK: - Verification
//extension AuthorizationService {
//    
//    /// Отправка письма подтверждения
//    func sendVerificationEmail() {
//        Auth.auth().currentUser?.sendEmailVerification(completion: nil)
//    }
//}
//
//// MARK: - Auth providers
//extension AuthorizationService {
//    
//    /// Publisher, который эмитит список всех провайдеров текущего пользователя
//    func authProvidersPublisher() -> AnyPublisher<[String], Never> {
//        let providers = Auth.auth().currentUser?.providerData.map { $0.providerID } ?? []
//        return Just(providers)
//            .eraseToAnyPublisher()
//    }
//    
//    /// Publisher, который эмитит основной провайдер (обычно первый)
//    func primaryAuthProviderPublisher() -> AnyPublisher<String?, Never> {
//        let provider = Auth.auth().currentUser?.providerData.first?.providerID
//        return Just(provider)
//            .eraseToAnyPublisher()
//    }
//}
//
//// MARK: - Helpers
//extension AuthorizationService {
//    
//    /// Текущий Firebase User как publisher (ошибка, если не залогинен)
//    private func currentUserPublisher() -> AnyPublisher<User, Error> {
//        guard let user = Auth.auth().currentUser else {
//            return Fail(error: FirebaseInternalError.notSignedIn).eraseToAnyPublisher()
//        }
//        return Just(user)
//            .setFailureType(to: Error.self)
//            .eraseToAnyPublisher()
//    }
//}






//extension AuthorizationService {
//    /// Отправка письма для сброса пароля
//    func sendPasswordReset(email: String) -> AnyPublisher<Void, Error> {
//        // Устанавливаем язык письма Firebase на основе текущего языка приложения
//        // Используем singleton LocalizationService.shared, доступный глобально
////        Auth.auth().languageCode = LocalizationService.shared.currentLanguage
//        Future { promise in
//            Auth.auth().sendPasswordReset(withEmail: email) { error in
//                if let error = error {
//                    promise(.failure(error))
//                } else {
//                    promise(.success(()))
//                }
//            }
//        }
//        .eraseToAnyPublisher()
//    }
//}


// MARK: - Before mark extension





//import FirebaseAuth
//import Combine
////import FirebaseFunctions
//
//// Ошибка, специфичная для deleteAccount()
//enum DeleteAccountError: Error {
//  /// Firebase вернул код .requiresRecentLogin
//  case reauthenticationRequired(Error)
//  /// Любая другая ошибка — оборачиваем оригинальный Error
//  case underlying(Error)
//}
//
//final class AuthorizationService {
//    
//    private let userProvider: CurrentUserProvider
//    private var cancellable: AnyCancellable?
//    private let authStateSubject = PassthroughSubject<AuthUser?, Never>()
//    
//    var authStatePublisher: AnyPublisher<AuthUser?, Never> {
//        authStateSubject.eraseToAnyPublisher()
//    }
//    
//    init(userProvider: CurrentUserProvider) {
//        print("AuthorizationService init")
//        self.userProvider = userProvider
//        observeUserChanges()
//    }
//    
//    private func observeUserChanges() {
//        cancellable = userProvider.currentUserPublisher
//            .sink { [weak self] authUser in
//                print("🔄 AuthorizationService получил нового пользователя: \(String(describing: authUser))")
//                self?.authStateSubject.send(authUser)
//            }
//    }
//    
//    // регистрация или линковка анонимного пользователя
//    func signUpBasic(email: String, password: String) -> AnyPublisher<Void, Error> {
//        currentUserPublisher()
//            .flatMap { user -> AnyPublisher<AuthDataResult, Error> in
//                if user.isAnonymous {
//                    let cred = EmailAuthProvider.credential(withEmail: email, password: password)
//                    return self.linkPublisher(user: user, credential: cred)
//                } else {
//                    return self.createUserPublisher(email: email, password: password)
//                }
//            }
//            .map { _ in () }
//            .eraseToAnyPublisher()
//    }
//    
//    // логирование и удаление анонимного пользователя
//    func signInBasic(email: String, password: String)
//    -> AnyPublisher<Void, Error>
//    {
//        currentUserPublisher()
//            .flatMap { [weak self] user -> AnyPublisher<Void, Error> in
//                guard let self = self else {
//                    return Fail(error: FirebaseInternalError.defaultError)
//                        .eraseToAnyPublisher()
//                }
//                if user.isAnonymous {
//                    // Сохраняем UID анонима, чтобы потом удалить
//                    let anonUid = user.uid
//                    print("anonUid func signInBasic - \(anonUid)")
//                    return self.signInPublisher(email: email, password: password)
//                    // после успешного входа — зовём Cloud Function
////                        .flatMap { _ in
////                            self.cleanupAnonymous(anonUid: anonUid)
////                        }
//                        .map { _ in () }
//                        .eraseToAnyPublisher()
//                } else {
//                    // Обычный вход, просто мапим в Void
//                    print("permanentUser func signInBasic - \(user.uid)")
//                    return self.signInPublisher(email: email, password: password)
//                        .map { _ in () }
//                        .eraseToAnyPublisher()
//                }
//            }
//            .eraseToAnyPublisher()
//    }
//        
//    
//    // удаляем аккаунт
//    func deleteAccount() -> AnyPublisher<Void, DeleteAccountError> {
//        Future<Void, DeleteAccountError> { promise in
//            guard let user = Auth.auth().currentUser else {
//                promise(.failure(.underlying(FirebaseInternalError.notSignedIn)))
//                return
//            }
//            user.delete { error in
//                if let nsError = error as NSError? {
//                    // создаём AuthErrorCode по rawValue и сравниваем
//                    if let code = AuthErrorCode(rawValue: nsError.code) {
//                        switch code {
//                        case .requiresRecentLogin,
//                             .userTokenExpired,
//                             .invalidUserToken,
//                             .invalidCredential:
//                            // Все эти ошибки требуют повторной аутентификации
//                            promise(.failure(.reauthenticationRequired(nsError)))
//                            
//                        default:
//                            // Остальные ошибки пробрасываем как underlying
//                            promise(.failure(.underlying(nsError)))
//                        }
//                    } else {
//                        // Если не удалось распарсить код — пробрасываем как underlying
//                        promise(.failure(.underlying(nsError)))
//                    }
//                } else {
//                    // Ошибки нет — удаление прошло успешно
//                    promise(.success(()))
//                }
//            }
//        }
//        .eraseToAnyPublisher()
//    }
//    
//    
//    func reauthenticate(email: String, password: String) -> AnyPublisher<Void, Error> {
//        Future<Void, Error> { promise in
//            guard let user = Auth.auth().currentUser else {
//                return promise(.failure(FirebaseInternalError.notSignedIn))
//            }
//
//            // может быть Apple + Google Provider
//            let credential = EmailAuthProvider.credential(withEmail: email, password: password)
//
//            user.reauthenticate(with: credential) { result, error in
//                if let error = error {
//                    promise(.failure(error))
//                } else {
//                    promise(.success(()))
//                }
//            }
//        }
//        .eraseToAnyPublisher()
//    }
//   
//
//
//    // MARK: - Helpers
//
//    private func currentUserPublisher() -> AnyPublisher<User, Error> {
//        guard let user = Auth.auth().currentUser else {
//            return Fail(error: FirebaseInternalError.notSignedIn).eraseToAnyPublisher()
//        }
//        return Just(user)
//            .setFailureType(to: Error.self)
//            .eraseToAnyPublisher()
//    }
//
//    private func createUserPublisher(email: String, password: String) -> AnyPublisher<AuthDataResult, Error> {
//        Future { promise in
//            Auth.auth().createUser(withEmail: email, password: password) { res, err in
//                if let error = err {
//                    promise(.failure(error))
//                } else if let result = res {
//                    promise(.success(result))
//                } else {
//                    /// вот эту ошибку нужно обязательно логировать
//                    /// то есть не так FirebaseEnternalError.defaultError а какимто специальным case что бы указать где именно она произошла
//                    promise(.failure(FirebaseInternalError.defaultError))
//                }
//            }
//        }
//        .eraseToAnyPublisher()
//    }
//
//    private func linkPublisher(user: User, credential: AuthCredential) -> AnyPublisher<AuthDataResult, Error> {
//        Future { [weak self] promise in
//            user.link(with: credential) { res, err in
//                print("linkPublisher res - \(String(describing: res)), error - \(String(describing: err))")
//                if let error = err {
//                    promise(.failure(error))
//                } else if let result = res {
//                    // 💡 Обновляем authState сразу так как при успешной линковки addStateDidChangeListener не отработает
//                    self?.updateAuthState(from: result.user)
//                    promise(.success(result))
//                } else {
//                    /// вот эту ошибку нужно обязательно логировать
//                    /// то есть не так FirebaseEnternalError.defaultError а какимто специальным case что бы указать где именно она произошла
//                    promise(.failure(FirebaseInternalError.defaultError))
//                }
//            }
//        }
//        .eraseToAnyPublisher()
//    }
//    
//    private func updateAuthState(from user: FirebaseAuth.User) {
//        let authUser = AuthUser(uid: user.uid, isAnonymous: user.isAnonymous)
//        authStateSubject.send(authUser)
//    }
//
//    private func signInPublisher(email: String, password: String)
//    -> AnyPublisher<AuthDataResult, Error>
//    {
//        Future { promise in
//            Auth.auth().signIn(withEmail: email, password: password) { res, err in
//                if let err = err {
//                    promise(.failure(err))
//                } else if let result = res {
//                    promise(.success(result))
//                } else {
//                    /// вот эту ошибку нужно обязательно логировать
//                    /// то есть не так FirebaseEnternalError.defaultError а какимто специальным case что бы указать где именно она произошла
//                    promise(.failure(FirebaseInternalError.defaultError))
//                }
//            }
//        }
//        .eraseToAnyPublisher()
//    }
//
//    func sendVerificationEmail() {
//        Auth.auth().currentUser?.sendEmailVerification(completion: nil)
//    }
//    
//    // сбрасываем локального юзера
//    func signOut() -> AnyPublisher<Void, Error> {
//        Future { promise in
//            do {
//                try Auth.auth().signOut()
//                promise(.success(()))
//            } catch {
//                promise(.failure(error))
//            }
//        }
//        .eraseToAnyPublisher()
//    }
//    
//    deinit {
//        print("AuthorizationService deinit")
//    }
//    
//}
//
//
//
//// MARK: -
//extension AuthorizationService {
//    
//    /// Publisher, который эмитит список всех провайдеров текущего пользователя
//    func authProvidersPublisher() -> AnyPublisher<[String], Never> {
//        let providers = Auth.auth().currentUser?.providerData.map { $0.providerID } ?? []
//        
//        // Если список пустой — это аномалия, логируем в Crashlytics
//        if providers.isEmpty {
//            // TODO: Crashlytics.log("authProvidersPublisher вернул пустой список провайдеров")
//            print("⚠️ authProvidersPublisher: пустой список провайдеров")
//        }
//        
//        return Just(providers)
//            .eraseToAnyPublisher()
//    }
//    
//    /// Publisher, который эмитит основной провайдер (обычно первый)
//    func primaryAuthProviderPublisher() -> AnyPublisher<String?, Never> {
//        let provider = Auth.auth().currentUser?.providerData.first?.providerID
//        
//        // Если nil — это аномалия, логируем в Crashlytics
//        if provider == nil {
//            // TODO: Crashlytics.log("primaryAuthProviderPublisher вернул nil")
//            print("⚠️ primaryAuthProviderPublisher: providerID == nil")
//        }
//        
//        return Just(provider)
//            .eraseToAnyPublisher()
//    }
//}



//            user.delete { error in
//                if let nsError = error as NSError? {
//                    // создаём AuthErrorCode по rawValue и сравниваем
//                    if let code = AuthErrorCode(rawValue: nsError.code),
//                       code == .requiresRecentLogin {
//                        promise(.failure(.reauthenticationRequired(nsError)))
//                    } else {
//                        promise(.failure(.underlying(nsError)))
//                    }
//                } else {
//                    promise(.success(()))
//                }
//            }




// MARK: - Before refactoring AuthorizationService (DI FirebaseAuthUserProvider)

//final class AuthorizationService {
//    
//    private var aythenticalSateHandler: AuthStateDidChangeListenerHandle?
//    private let authStateSubject = PassthroughSubject<AuthUser?, Never>()
////    private let functions = Functions.functions()
//    
//    var authStatePublisher: AnyPublisher<AuthUser?, Never> {
//        authStateSubject.eraseToAnyPublisher()
//    }
//    
//    init() {
//        
//        print("AuthorizationService init")
//        if let handle = aythenticalSateHandler {
//            Auth.auth().removeStateDidChangeListener(handle)
//        }
//        /// при удалении узера нам сначало должен прийти nil а потм уже объект user anon
//        aythenticalSateHandler = Auth.auth().addStateDidChangeListener { [weak self] (_, user) in
//            print("AuthorizationService/AuthorizationManager user.uid - \(String(describing: user?.uid))")
//            guard let user = user else {
//                self?.authStateSubject.send(nil)
//                return
//            }
//            let authUser = AuthUser(uid: user.uid, isAnonymous: user.isAnonymous)
//            self?.authStateSubject.send(authUser)
//        }
//    }

//deinit {
//    print("AuthorizationService deinit")
//    if let handle = aythenticalSateHandler {
//        Auth.auth().removeStateDidChangeListener(handle)
//    }
//}











/// 3) Вызываем HTTPS-функцию на удаление старого анонима
//    private func cleanupAnonymous(anonUid: String)
//    -> AnyPublisher<Void, Error>
//    {
//        let data: [String: Any] = ["uid": anonUid]
//        return Future { [weak self] promise in
//            self?.functions.httpsCallable("cleanupAnonymousUser")
//                .call(data) { result, error in
//                    if let error = error {
//                        promise(.failure(error))
//                    } else {
//                        promise(.success(()))
//                    }
//                }
//        }
//        .eraseToAnyPublisher()
//    }

// создаём/обновляем профиль
//    func createProfile(name: String) -> AnyPublisher<Void, Error> {
//        Deferred {
//            Future { promise in
//                guard let req = Auth.auth().currentUser?.createProfileChangeRequest() else {
//                    return promise(.failure(FirebaseEnternalError.notSignedIn))
//                }
//                req.displayName = name
//                req.commitChanges { error in
//                    if let error = error {
//                        promise(.failure(error))
//                    } else {
//                        promise(.success(()))
//                    }
//                }
//            }
//        }
//        .eraseToAnyPublisher()
//    }















// before DeleteAccountError
    
//    func deleteAccount() -> AnyPublisher<Void, Error> {
//        Future { promise in
//            guard let user = Auth.auth().currentUser else {
//                return promise(.failure(FirebaseEnternalError.notSignedIn))
//            }
//
//            user.delete { error in
//                if let error = error {
//                    promise(.failure(error))
//                } else {
//                    promise(.success(()))
//                }
//            }
//        }
//        .eraseToAnyPublisher()
//    }
    

//        aythenticalSateHandler = Auth.auth().addStateDidChangeListener { [weak self] (_, user) in
//            let authUser = user.map { AuthUser(isAnonymous: $0.isAnonymous) }
//            self?.authStateSubject.send(authUser)
//        }

/// Линкуем анонимного, делаем reload и шлём новый AuthUser
//    private func linkAndReload(
//        user: User,
//        credential: AuthCredential
//    ) -> AnyPublisher<Void, Error> {
//        linkPublisher(user: user, credential: credential)
//            .flatMap { [weak self] _ -> AnyPublisher<AuthUser, Error> in
//                guard let self = self else {
//                    return Fail(error: FirebaseEnternalError.defaultError)
//                        .eraseToAnyPublisher()
//                }
//                return self.reloadCurrentUser()
//            }
//            .handleEvents(receiveOutput: { [weak self] updated in
//                self?.authStateSubject.send(updated)
//            })
//            .map { _ in () }
//            .eraseToAnyPublisher()
//    }
//
//    /// Перезагружает текущего пользователя и выдаёт обновлённый AuthUser
//    private func reloadCurrentUser() -> AnyPublisher<AuthUser, Error> {
//        Future<AuthUser, Error> { promise in
//            Auth.auth().currentUser?.reload(completion: { err in
//                if let err = err {
//                    return promise(.failure(err))
//                }
//                guard let u = Auth.auth().currentUser else {
//                    return promise(.failure(FirebaseEnternalError.defaultError))
//                }
//                let au = AuthUser(uid: u.uid, isAnonymous: u.isAnonymous)
//                promise(.success(au))
//            })
//        }
//        .eraseToAnyPublisher()
//    }

// MARK: - before AnyPublisher<Void, Error>

// AuthorizationService.swift
//import FirebaseAuth
//import Combine
//
/////case .unknown:  Баг или нестабильность в SDK Firebase — крайне редкий случай, но иногда можно словить такой "undefined" результат при сетевых сбоях или конфликтах версий SDK.
//enum AuthError: LocalizedError {
//  case notAuthorized
//  case firebase(Error)
//  case unknown
//
//  var errorDescription: String? {
//    switch self {
//    case .notAuthorized:       return "Пользователь не авторизован."
//    case .firebase(let error): return error.localizedDescription
//    case .unknown:             return "Неизвестная ошибка."
//    }
//  }
//}
//
///// Чистый сервис — регистрирует/линкует пользователя, обновляет профиль.
//final class AuthorizationService {
//  
//    // Шаг 1: регистрация или линковка анонимного пользователя → возвращает Void
//    func signUpBasic(email: String, password: String) -> AnyPublisher<Void, AuthError> {
//      currentUserPublisher()
//        .flatMap { user -> AnyPublisher<AuthDataResult, AuthError> in
//          if user.isAnonymous {
//            let cred = EmailAuthProvider.credential(withEmail: email, password: password)
//            return self.linkPublisher(user: user, credential: cred)
//          } else {
//            return self.createUserPublisher(email: email, password: password)
//          }
//        }
//        .map { _ in () } // или .voidMap() если есть такое расширение
//        .eraseToAnyPublisher()
//    }
//
//  // Шаг 2: создаём/обновляем профиль → Void
//  func createProfile(name: String) -> AnyPublisher<Void, AuthError> {
//    Deferred {
//      Future { promise in
//        guard let req = Auth.auth().currentUser?.createProfileChangeRequest() else {
//          return promise(.failure(.notAuthorized))
//        }
//        req.displayName = name
//        req.commitChanges { error in
//          if let e = error {
//            promise(.failure(.firebase(e)))
//          } else {
//            promise(.success(()))
//          }
//        }
//      }
//    }
//    .eraseToAnyPublisher()
//  }
//
//  // MARK: — Helpers
//
//    private func currentUserPublisher() -> AnyPublisher<User, AuthError> {
//        guard let user = Auth.auth().currentUser else {
//            return Fail(error: .notAuthorized).eraseToAnyPublisher()
//        }
//        return Just(user)
//            .setFailureType(to: AuthError.self)
//            .eraseToAnyPublisher()
//    }
//
//    private func createUserPublisher(email: String, password: String)
//    -> AnyPublisher<AuthDataResult, AuthError>
//    {
//        Future { promise in
//            Auth.auth().createUser(withEmail: email, password: password) { res, err in
//                if let e = err          { promise(.failure(.firebase(e))) }
//                else if let success = res { promise(.success(success)) }
//                else                     { promise(.failure(.unknown)) }
//            }
//        }
//        .eraseToAnyPublisher()
//    }
//
//    private func linkPublisher(user: User, credential: AuthCredential)
//    -> AnyPublisher<AuthDataResult, AuthError>
//    {
//        Future { promise in
//            user.link(with: credential) { res, err in
//                if let e = err          { promise(.failure(.firebase(e))) }
//                else if let success = res { promise(.success(success)) }
//                else                     { promise(.failure(.unknown)) }
//            }
//        }
//        .eraseToAnyPublisher()
//    }
//
//  func sendVerificationEmail() {
//    Auth.auth().currentUser?.sendEmailVerification(completion: nil)
//  }
//}


// MARK: - func signUp(email: String, password: String, name: String) - create user and create profile user

///// Чистый сервис — регистрирует/линкует пользователя, обновляет профиль.
//final class AuthorizationService {
//  
//    // Шаг 1: регистрация или линковка анонимного пользователя → возвращает userId
//  func signUpBasic(email: String, password: String) -> AnyPublisher<String, AuthError> {
//    currentUserPublisher()
//      .flatMap { user -> AnyPublisher<AuthDataResult, AuthError> in
//        if user.isAnonymous {
//          let cred = EmailAuthProvider.credential(
//            withEmail: email,
//            password: password
//          )
//          return self.linkPublisher(user: user, credential: cred)
//        } else {
//          return self.createUserPublisher(email: email, password: password)
//        }
//      }
//      .map { $0.user.uid }
//      .eraseToAnyPublisher()
//  }
//
//  // Шаг 2: создаём/обновляем профиль → Void
//  func createProfile(name: String) -> AnyPublisher<Void, AuthError> {
//    Deferred {
//      Future { promise in
//        guard let req = Auth.auth().currentUser?.createProfileChangeRequest() else {
//          return promise(.failure(.notAuthorized))
//        }
//        req.displayName = name
//        req.commitChanges { error in
//          if let e = error {
//            promise(.failure(.firebase(e)))
//          } else {
//            promise(.success(()))
//          }
//        }
//      }
//    }
//    .eraseToAnyPublisher()
//  }
//
//  // MARK: — Helpers
//
//    private func currentUserPublisher() -> AnyPublisher<User, AuthError> {
//        guard let user = Auth.auth().currentUser else {
//            return Fail(error: .notAuthorized).eraseToAnyPublisher()
//        }
//        return Just(user)
//            .setFailureType(to: AuthError.self)
//            .eraseToAnyPublisher()
//    }
//
//    private func createUserPublisher(email: String, password: String)
//    -> AnyPublisher<AuthDataResult, AuthError>
//    {
//        Future { promise in
//            Auth.auth().createUser(withEmail: email, password: password) { res, err in
//                if let e = err          { promise(.failure(.firebase(e))) }
//                else if let success = res { promise(.success(success)) }
//                else                     { promise(.failure(.unknown)) }
//            }
//        }
//        .eraseToAnyPublisher()
//    }
//
//    private func linkPublisher(user: User, credential: AuthCredential)
//    -> AnyPublisher<AuthDataResult, AuthError>
//    {
//        Future { promise in
//            user.link(with: credential) { res, err in
//                if let e = err          { promise(.failure(.firebase(e))) }
//                else if let success = res { promise(.success(success)) }
//                else                     { promise(.failure(.unknown)) }
//            }
//        }
//        .eraseToAnyPublisher()
//    }
//
//  func sendVerificationEmail() {
//    Auth.auth().currentUser?.sendEmailVerification(completion: nil)
//  }
//}



// MARK: - legacy implementation

//import SwiftUI
//import FirebaseAuth
//
//class AuthorizationManager {
//    
//    var currentUser = Auth.auth().currentUser
//    
//    func signUp(email: String, password: String, name: String, completion: @escaping (Error?, Bool) -> Void) {
//        
//        let errorAuth = NSError(domain: "com.yourapp.error", code: 401, userInfo: [NSLocalizedDescriptionKey: "User is not authorized."])
//        
//            guard let _ = currentUser else {
//                
//                completion(errorAuth, false)
//                return
//            }
//        
//            if currentUser?.isAnonymous == true {
//                let credential = EmailAuthProvider.credential(withEmail: email, password: password)
//                currentUser?.link(with: credential) { [weak self] (result, error) in
//                    // Обработайте результат
//                    if let error = error {
//                        completion(error, false)
//                    } else {
//                        self?.createProfileAndHandleError(name: name, isAnonymous: true, completion: completion)
//                    }
//                }
//            } else {
//                Auth.auth().createUser(withEmail: email, password: password) { [weak self] (result, error) in
//                    if let error = error  {
//                        completion(error,false)
//                    } else {
//                        self?.createProfileAndHandleError(name: name, isAnonymous: false, completion: completion)
//                    }
//                }
//            }
//        }
//    
//    func createProfileAndHandleError(name: String, isAnonymous: Bool, completion: @escaping (Error?, Bool) -> Void) {
//        createProfileChangeRequest(name: name, { error in
//            if let error = error {
//                completion(error, false)
//            } else {
//                self.verificationEmail()
//                completion(error, true)
//            }
//        })
//    }
//        
//        // Отправить пользователю электронное письмо с подтверждением регистрации
//        func verificationEmail() {
//            currentUser?.sendEmailVerification()
//        }
//        
//        // если callback: ((StateProfileInfo, Error?) -> ())? = nil) closure не пометить как @escaping (зачем он нам не обязательный?)
//        // if error == nil этот callBack не будет вызван(вызов проигнорируется) - callBack: ((Error?) -> Void)? = nil // callBack?(error)
//        func createProfileChangeRequest(name: String? = nil, photoURL: URL? = nil,_ completion: @escaping (Error?) -> Void) {
//
//            if let request = currentUser?.createProfileChangeRequest() {
//                if let name = name {
//                    request.displayName = name
//                }
//
//                if let photoURL = photoURL {
//                    request.photoURL = photoURL
//                }
//                
//                request.commitChanges { error in
//                    completion(error)
//                }
//            } else {
//                ///need created build Error
//                let error = NSError(domain: "com.yourapp.error", code: 401, userInfo: [NSLocalizedDescriptionKey: "User is not authorized."])
//                completion(error)
//            }
//        }
//}
