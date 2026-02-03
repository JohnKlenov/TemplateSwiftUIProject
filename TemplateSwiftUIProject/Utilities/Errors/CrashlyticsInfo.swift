//
//  CrashlyticsLoggingService.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 12.04.25.
//


// CrashlyticsLoggingService.swift

///Я хочу создать сервис для логирования ошибок в Crashlytics Firebase ! В моем приложении у меня есть различные сущности(ErrorHandlers) которые принимают ошибку, определяют ее домен и возвращают локализированный текст этой ошибки для алерта или же просто в нутри своей логики проводят онализ и при необходимости логируют сообщения для команды разработчиков на Crashlytics Firebase. Дак вот для таких сущностей как ErrorHandlers я хочу создать сервис для логирования ошибок в Crashlytics Firebase и использовать ее в ErrorHandlers как зависимость для передачи logToCrashlytics. Но я хочу что бы в  logToCrashlytics я передавал не только саму ошибку но и все необходимые данные что бы упростить мониторинг ошибки в консоли Crashlytics Firebase для разработчиков а так же чтьо важно передать данные о том откуда пришла эта ошибка от какого ErrorHandlers и от какого домена! вобщем я хочу что бы сделал мне грамотный  сервис для логирования ошибок в Crashlytics Firebase и подошеол к этому ответственно как старший ios developer.   - вот пример моих ErrorHandlers
///логировать мы будем только те ошибки которые являются критичными и нуждаются во вмешательстве команды разработчиков! ну и для пользователя в итоговой реализации SharedErrorHandler мы будем возвращать только те локализованные текста для алертов которые в действительности могут быть полезны и понятны для пользователя а те что не понятны и бесполезны мы будем заменять локализованным текстом типо что то пошло не так попробуй еще! Так же сервис для логирования ошибок в Crashlytics Firebase мы будем использовать и во ViewModel и даже может быть в View так как там тоже могут быть отловлены ошибки которые требуют вмешательства команды разработчиков
///Так же сервис для логирования ошибок в Crashlytics Firebase мы будем использовать и во ViewModel и даже может быть в View так как там тоже могут быть отловлены ошибки которые требуют вмешательства команды разработчиков.

///Пользователь хочет передавать не только саму ошибку, но и дополнительную информацию: домен ошибки, источник (например, конкретный ErrorHandler), и другие метаданные, которые помогут разработчикам быстрее диагностировать проблему. Также важно различать критические и некритические ошибки, чтобы не засорять логи ненужной информацией.

//Рекомендации по улучшению:
///Добавьте обработку ошибок сети с проверкой интернет-соединения
///Реализуйте фильтрацию дубликатов ошибок
///Добавьте трекинг пользовательских сценариев
///Настройте автоматическую отправку логов при старте приложения
///Реализуйте механизм маскирования конфиденциальных данных в логах



//import Foundation
//import FirebaseCrashlytics
//
//protocol ErrorLoggingServiceProtocol {
//    func log(
//        error: Error,
//        domain: String,
//        source: String,
//        message: String?,
//        additionalParams: [String: Any]?,
//        severity: ErrorSeverityLevel
//    )
//    
//    func log(
//        message: String,
//        domain: String,
//        source: String,
//        additionalParams: [String: Any]?,
//        severity: ErrorSeverityLevel
//    )
//}
//
//enum ErrorSeverityLevel: String {
//    case fatal
//    case error
//    case warning
//    case info
//}
//
//final class CrashlyticsLoggingService: ErrorLoggingServiceProtocol {
//    static let shared = CrashlyticsLoggingService()
//    private let crashlytics = Crashlytics.crashlytics()
//    
//    private init() {}
//    
//    func log(
//        error: Error,
//        domain: String,
//        source: String,
//        message: String? = nil,
//        additionalParams: [String: Any]? = nil,
//        severity: ErrorSeverityLevel = .error
//    ) {
//        var userInfo: [String: Any] = [
//            "error_domain": domain,
//            "error_source": source,
//            "severity": severity.rawValue,
//            "underlying_error": error.localizedDescription,
//            "error_code": (error as NSError).code
//        ]
//        
//        if let message = message {
//            userInfo["custom_message"] = message
//        }
//        
//        if let additionalParams = additionalParams {
//            userInfo.merge(additionalParams) { (current, _) in current }
//        }
//        
//        let nsError = NSError(
//            domain: domain,
//            code: (error as NSError).code,
//            userInfo: userInfo
//        )
//        
//        crashlytics.record(error: nsError)
//        logAdditionalInfo(userInfo: userInfo)
//    }
//    
//    func log(
//        message: String,
//        domain: String,
//        source: String,
//        additionalParams: [String: Any]? = nil,
//        severity: ErrorSeverityLevel = .info
//    ) {
//        var logData: [String: Any] = [
//            "log_domain": domain,
//            "log_source": source,
//            "severity": severity.rawValue,
//            "message": message
//        ]
//        
//        if let additionalParams = additionalParams {
//            logData.merge(additionalParams) { (current, _) in current }
//        }
//        
//        logAdditionalInfo(userInfo: logData)
//    }
//    
//    private func logAdditionalInfo(userInfo: [String: Any]) {
//        userInfo.forEach { key, value in
//            crashlytics.setCustomValue(value, forKey: "log_\(key)")
//        }
//        
//        if let message = userInfo["message"] as? String {
//            crashlytics.log(format: "[%@] %@: %@",
//                             userInfo["severity"] as? String ?? "unknown",
//                             userInfo["log_source"] as? String ?? "unknown_source",
//                             message)
//        }
//    }
//}



// MARK: - example integration in view + viewModel



// MARK:  SharedErrorHandler

//class SharedErrorHandler: ErrorHandlerProtocol {
//    private let loggingService: ErrorLoggingServiceProtocol
//    private let RealtimeDatabaseErrorDomain = "com.firebase.database"
//    
//    init(loggingService: ErrorLoggingServiceProtocol = CrashlyticsLoggingService.shared) {
//        self.loggingService = loggingService
//    }
//    
//    func handle(error: Error?) -> String {
//        guard let error = error else {
//            return Localized.FirebaseEnternalError.defaultError
//        }
//        
//        let nsError = error as NSError
//        let errorMessage: String
//        
//        if let authErrorCode = AuthErrorCode(rawValue: nsError.code) {
//            errorMessage = handleAuthError(authErrorCode)
//            logAuthError(authErrorCode, nsError: nsError)
//        } else if nsError.domain == FirestoreErrorDomain {
//            errorMessage = handleFirestoreError(nsError)
//            logFirestoreError(nsError)
//        } else if let storageErrorCode = StorageErrorCode(rawValue: nsError.code) {
//            errorMessage = handleStorageError(storageErrorCode)
//            logStorageError(storageErrorCode, nsError: nsError)
//        } else if nsError.domain == RealtimeDatabaseErrorDomain {
//            errorMessage = handleRealtimeDatabaseError(nsError)
//            logRealtimeDatabaseError(nsError)
//        } else if let customError = error as? FirebaseEnternalError {
//            errorMessage = customError.errorDescription ?? Localized.FirebaseEnternalError.defaultError
//            logCustomError(customError)
//        } else {
//            errorMessage = Localized.FirebaseEnternalError.defaultError
//            logUnknownError(nsError)
//        }
//        
//        return errorMessage
//    }
//    
//    private func logAuthError(_ code: AuthErrorCode, nsError: NSError) {
//        let shouldLog = isCriticalAuthError(code)
//        guard shouldLog else { return }
//        
//        loggingService.log(
//            error: nsError,
//            domain: "FirebaseAuth",
//            source: "SharedErrorHandler",
//            message: "Critical Auth Error",
//            additionalParams: ["auth_error_code": code.rawValue],
//            severity: .error
//        )
//    }
//    
//    private func isCriticalAuthError(_ code: AuthErrorCode) -> Bool {
//        switch code {
//        case .invalidCredential,
//             .invalidSender,
//             .invalidRecipientEmail,
//             .keychainError,
//             .internalError,
//             .malformedJWT:
//            return true
//        default:
//            return false
//        }
//    }
//    
//    // Аналогичные методы logFirestoreError, logStorageError и т.д.
//}


// MARK: SDWebImageErrorHandler

//final class SDWebImageErrorHandler: ObservableObject, SDWebImageErrorHandlerProtocol {
//    private let loggingService: ErrorLoggingServiceProtocol
//    
//    init(loggingService: ErrorLoggingServiceProtocol = CrashlyticsLoggingService.shared) {
//        self.loggingService = loggingService
//    }
//    
//    private func logCriticalError(_ message: String, error: NSError, metadata: [String: Any], url: URL?) {
//        var params: [String: Any] = [
//            "error_code": error.code,
//            "error_domain": error.domain,
//            "url": url?.absoluteString ?? "nil"
//        ]
//        params.merge(metadata) { (current, _) in current }
//        
//        loggingService.log(
//            error: error,
//            domain: "SDWebImage",
//            source: "SDWebImageErrorHandler",
//            message: message,
//            additionalParams: params,
//            severity: .error
//        )
//    }
//}


// MARK: FirestoreGetService

//final class FirestoreGetService {
//    private let db = Firestore.firestore()
//    private let loggingService: ErrorLoggingServiceProtocol
//    
//    init(loggingService: ErrorLoggingServiceProtocol = CrashlyticsLoggingService.shared) {
//        self.loggingService = loggingService
//    }
//    
//    func fetchMalls() async throws -> [MallItem] {
//        try await withCheckedThrowingContinuation { continuation in
//            db.collection("MallCenters").getDocuments { [weak self] snapshot, error in
//                guard let self = self else { return }
//                
//                if let error = error as NSError? {
//                    self.handleFetchError(error)
//                    continuation.resume(throwing: error)
//                } else {
//                    // Обработка успешного результата
//                }
//            }
//        }
//    }
//    
//    private func handleFetchError(_ error: NSError) {
//        let criticalCodes: [Int] = [
//            FirestoreErrorCode.invalidArgument.rawValue,
//            FirestoreErrorCode.permissionDenied.rawValue,
//            FirestoreErrorCode.resourceExhausted.rawValue,
//            FirestoreErrorCode.failedPrecondition.rawValue,
//            FirestoreErrorCode.unimplemented.rawValue,
//            FirestoreErrorCode.internal.rawValue,
//            FirestoreErrorCode.dataLoss.rawValue,
//            FirestoreErrorCode.unauthenticated.rawValue
//        ]
//        
//        guard criticalCodes.contains(error.code) else { return }
//        
//        loggingService.log(
//            error: error,
//            domain: "Firestore",
//            source: "FirestoreGetService",
//            message: "Critical Firestore Error",
//            additionalParams: [
//                "collection": "MallCenters",
//                "operation": "fetchMalls"
//            ],
//            severity: .error
//        )
//    }
//}









// MARK: - Выжимка всех настроек, которые мы делали для корректной работы Crashlytics 26.01.26 (первая попытка работы с Crashlytics)




//
//  Выжимка всех настроек, которые мы делали для корректной работы Crashlytics
//  и расшифровки крэшей в Firebase. Кратко, чётко, по делу.
//
//  ----------------------------------------------------------------------
//  1. Настройки проекта для корректной генерации dSYM
//
//  • Build Settings → Debug Information Format = "DWARF with dSYM File"
//    (обязательно для Release, иначе Firebase не сможет расшифровать стек)
//
//  • ENABLE_USER_SCRIPT_SANDBOXING = NO
//    (нужно, чтобы Xcode мог корректно выполнять скрипты Crashlytics
//     и генерировать dSYM без блокировок)
//
//  • Archive должен собираться в Release:
//      Scheme → Edit Scheme → Archive → Build Configuration = Release
//
//  Эти настройки гарантируют:
//  - корректный dSYM
//  - правильный UUID
//  - возможность расшифровки стека в Firebase
//
//  ----------------------------------------------------------------------
//  2. Настройки Signing & Capabilities для установки на реальное устройство
//
//  • Automatically manage signing = ON
//  • Team = Evgeniy Klenov (Personal Team)
//  • Provisioning Profile = Xcode Managed Profile
//  • Signing Certificate = Apple Development
//
//  Это позволяет:
//  - подписывать приложение под твой Apple ID
//  - устанавливать Release‑сборку на iPhone без App Store
//  - запускать приложение на реальном устройстве
//
//  ----------------------------------------------------------------------
//  3. Почему мы отключали sandboxing и проверяли dSYM
//
//  • ENABLE_USER_SCRIPT_SANDBOXING = NO
//    Crashlytics использует скрипты для генерации dSYM и загрузки символов.
//    Если sandbox включён — Xcode блокирует эти скрипты.
//
//  • Проверка dSYM через:
//        dwarfdump --uuid TemplateSwiftUIProject.app.dSYM
//    Это нужно, чтобы убедиться, что UUID совпадает с тем,
//    который Firebase показывает как Missing.
//
//  ----------------------------------------------------------------------
//  4. Почему мы делали Archive (а не просто Run)
//
//  Archive создаёт:
//  - настоящую Release‑сборку
//  - корректный dSYM
//  - правильный UUID
//
//  Run (даже в Release) на симуляторе:
//  - создаёт Debug‑UUID
//  - генерирует неправильный dSYM
//  - Crashlytics не может расшифровать стек
//
//  ----------------------------------------------------------------------
//  5. Почему Crashlytics не работает на симуляторе
//
//  • Симулятор всегда работает в Debug‑режиме
//  • dSYM от симулятора не подходит для Firebase
//  • UUID симулятора ≠ UUID Release‑архива
//  • Симулятор не использует настоящий crash handler iOS
//  • Firebase официально НЕ поддерживает Crashlytics на симуляторе
//
//  Итог: Crashlytics работает только на реальном устройстве.
//
//  ----------------------------------------------------------------------
//  6. Что нужно для корректного тестирования Crashlytics
//
//  1) Собрать Release‑архив (Product → Archive)
//  2) Экспортировать .ipa через Distribute App → Development
//  3) Установить .ipa на iPhone через Devices and Simulators
//  4) Запустить приложение на устройстве
//  5) Вызвать тестовый краш (fatalError или record(error:))
//  6) Открыть Firebase → увидеть новый UUID
//  7) Найти dSYM в архиве
//  8) Проверить UUID через dwarfdump
//  9) Загрузить dSYM в Firebase
// 10) Получить расшифрованный стек
//
//  ----------------------------------------------------------------------
//  7. Итоговая суть всех настроек
//
//  Мы настроили проект так, чтобы:
//
//  • Release‑сборка создаёт корректный dSYM
//  • Firebase может расшифровать стек
//  • приложение можно установить на реальный iPhone
//  • Crashlytics получает настоящие крэши
//  • UUID совпадает между Firebase и архивом
//
//  Теперь Crashlytics будет работать так, как задумано,
//  и ты сможешь видеть полноценные стеки ошибок.
//
//








// MARK: - Почему Firebase Crashlytics НЕ работает на iOS Simulator -



//
//  Почему Firebase Crashlytics НЕ работает на iOS Simulator
//  Подробное объяснение для сохранения в Xcode как комментарий.
//
//  ----------------------------------------------------------------------
//  1. Симулятор НЕ является реальным устройством
//
//  iOS Simulator — это не полноценная копия iPhone. Это программа,
//  которая запускает iOS‑подобную среду внутри macOS. У него нет:
//
//  - настоящего ядра iOS
//  - настоящего процесса перезагрузки после краша
//  - настоящего устройства с ARM‑архитектурой
//  - настоящего окружения для Crashlytics
//
//  Firebase Crashlytics рассчитан на работу ТОЛЬКО на реальных устройствах,
//  потому что он интегрируется в низкоуровневые механизмы iOS,
//  которые отсутствуют в симуляторе.
//
//  ----------------------------------------------------------------------
//  2. Симулятор ВСЕГДА работает в Debug‑режиме
//
//  Даже если выбрать "Release" в схеме, симулятор:
//
//  - не создаёт корректный dSYM
//  - не использует Release‑подпись
//  - не генерирует UUID, совпадающий с архивом
//  - не отправляет корректные отчёты о крашах
//
//  Crashlytics не может расшифровать стек, потому что:
//
//  - UUID от симулятора ≠ UUID от Release‑архива
//  - dSYM от симулятора ≠ dSYM от устройства
//
//  ----------------------------------------------------------------------
//  3. Firebase Crashlytics НЕ получает настоящие крэши с симулятора
//
//  Crashlytics работает так:
//
//  - перехватывает краш на устройстве
//  - сохраняет отчёт в файловую систему устройства
//  - отправляет отчёт при следующем запуске приложения
//
//  На симуляторе:
//
//  - краш не проходит через настоящий crash handler iOS
//  - отчёт не сохраняется в нужном формате
//  - Crashlytics не может отправить данные на сервер
//
//  Поэтому в Firebase появляются:
//
//  - пустые события
//  - Unknown UUID
//  - Uploaded без стека
//  - Missing dSYM, которые невозможно загрузить
//
//  ----------------------------------------------------------------------
//  4. dSYM от симулятора НЕ подходит для Firebase
//
//  Симулятор использует архитектуру x86_64 или arm64e (в зависимости от Mac),
//  а реальное устройство — arm64.
//
//  Firebase принимает ТОЛЬКО dSYM от arm64.
//
//  Поэтому dSYM, собранный симулятором:
//
//  - не подходит
//  - не загружается
//  - не совпадает по UUID
//  - не может расшифровать стек
//
//  ----------------------------------------------------------------------
//  5. Итог: Crashlytics НЕ работает на симуляторе по техническим причинам
//
//  Кратко:
//
//  - нет настоящего crash handler
//  - нет настоящего UUID
//  - нет корректного dSYM
//  - нет настоящей отправки отчётов
//  - нет ARM‑архитектуры
//
//  Crashlytics официально поддерживает ТОЛЬКО:
//
//  ✔ реальные устройства (iPhone / iPad)
//  ✘ симулятор — НЕ поддерживается
//
//  ----------------------------------------------------------------------
//  6. Как правильно тестировать Crashlytics
//
//  Единственный корректный способ:
//
//  1. Собрать Release‑архив (Product → Archive)
//  2. Установить .ipa на реальный iPhone
//  3. Вызвать краш (fatalError или record(error:))
//  4. Открыть Firebase → увидеть новый UUID
//  5. Найти dSYM в архиве
//  6. Загрузить dSYM в Firebase
//  7. Получить расшифрованный стек
//
//  Только так Crashlytics работает полностью корректно.
//
//  ----------------------------------------------------------------------
//
//  Если Crashlytics не работает на симуляторе — это НОРМАЛЬНО.
//  Он никогда там не работал и не будет работать.
//
//









// MARK: - Debug vs Release -


//
//  Debug vs Release — что это такое и зачем они нужны
//  Подробное объяснение для сохранения в Xcode.
//
//  ----------------------------------------------------------------------
//  1. Что такое Debug‑режим
//
//  Debug — это режим разработки. Он предназначен для программиста,
//  чтобы удобно писать код, тестировать, отлаживать и ловить ошибки.
//
//  Основные особенности Debug:
//
//  • Включена отладочная информация (символы, метаданные, подсказки).
//  • Приложение работает медленнее, но даёт максимум информации.
//  • Включены проверки безопасности, assert'ы, fatalError'ы.
//  • Логи, print(), debugPrint() работают без ограничений.
//  • dSYM создаётся упрощённый и НЕ подходит для Crashlytics.
//  • UUID Debug‑сборки НЕ совпадает с UUID Release‑архива.
//  • Симулятор ВСЕГДА работает в Debug, даже если выбрать Release.
//
//  Debug нужен для:
//  • разработки,
//  • тестирования логики,
//  • поиска ошибок,
//  • работы на симуляторе,
//  • проверки UI.
//
//  ----------------------------------------------------------------------
//  2. Что такое Release‑режим
//
//  Release — это режим для реального использования приложения.
//  Это та сборка, которую получают пользователи.
//
//  Основные особенности Release:
//
//  • Оптимизированный код (быстрее, меньше, эффективнее).
//  • Отключены debug‑проверки и лишние логи.
//  • Генерируется полноценный dSYM для Crashlytics.
//  • UUID совпадает с архивом, поэтому стек можно расшифровать.
//  • Приложение работает так же, как у реальных пользователей.
//  • Только Release‑сборка даёт корректные отчёты Crashlytics.
//
//  Release нужен для:
//  • тестирования Crashlytics,
//  • тестирования производительности,
//  • тестирования на реальном устройстве,
//  • публикации в App Store,
//  • реального использования.
//
//  ----------------------------------------------------------------------
//  3. Почему Crashlytics работает только в Release
//
//  Crashlytics требует:
//  • настоящего dSYM,
//  • настоящего UUID,
//  • настоящего ARM‑устройства,
//  • настоящего краша,
//  • настоящей перезагрузки приложения.
//
//  В Debug‑режиме:
//
//  ✘ dSYM неполный
//  ✘ UUID другой
//  ✘ симулятор не создаёт корректные отчёты
//  ✘ краши не проходят через настоящий crash handler
//
//  Поэтому Crashlytics НЕ может расшифровать стек из Debug.
//
//  ----------------------------------------------------------------------
//  4. Краткое сравнение Debug vs Release
//
//  Debug:
//  • медленнее
//  • удобнее для разработки
//  • много логов
//  • работает на симуляторе
//  • dSYM НЕ подходит для Crashlytics
//
//  Release:
//  • быстрее
//  • оптимизирован
//  • минимум логов
//  • работает на реальном устройстве
//  • dSYM подходит для Crashlytics
//
//  ----------------------------------------------------------------------
//  5. Итог
//
//  Debug — для разработки.
//  Release — для реального тестирования и Crashlytics.
//
//  Если нужно протестировать Crashlytics:
//  → всегда использовать Release‑архив
//  → установить его на реальный iPhone
//  → вызвать краш
//  → загрузить dSYM
//  → получить расшифрованный стек.
//
//












// MARK: -  Как тестировать на реальном устройстве -



// инструкцию запуска приложения на устройстве прямо из Xcode (без .ipa)
// не подходит для тестирования Crashlytics - debug version!!!


//
//  Как подключить iPhone 15 к Mac и запустить приложение для тестирования Crashlytics
//  Полная инструкция в виде комментария для Xcode.
//
//  ----------------------------------------------------------------------
//  1. Подключение iPhone 15 к Mac
//
//  1.1. Подключить устройство кабелем USB‑C ↔ USB‑C (или Lightning ↔ USB‑C).
//
//  1.2. На iPhone появится окно:
//       «Доверять этому компьютеру?» → нажать "Доверять" → ввести код‑пароль.
//
//  1.3. В Xcode открыть:
//       Window → Devices and Simulators → вкладка Devices.
//       • iPhone 15 должен появиться в списке.
//       • Если Xcode предложит “Use for Development” — согласиться.
//       • Если попросит войти в Apple ID — войти под тем же Apple ID,
//         который используется в Personal Team.
//
//  ----------------------------------------------------------------------
//  2. Проверка настроек проекта перед запуском на устройстве
//
//  2.1. Signing & Capabilities:
//       • Automatically manage signing = ON
//       • Team = Evgeniy Klenov (Personal Team)
//       • Provisioning Profile = Xcode Managed Profile
//       • Certificate = Apple Development
//
//  2.2. Deployment Target:
//       • General → Deployment Info → iOS Deployment Target = 17.5 (или ниже)
//       Важно:
//       • Версия iOS на устройстве должна быть ≥ Deployment Target.
//       • Если на iPhone стоит iOS 18 / 19 / 26 — это нормально.
//       • Проблема была бы только если устройство имеет iOS НИЖЕ Deployment Target.
//
//  2.3. Firebase и Crashlytics должны быть инициализированы:
//
//       import FirebaseCore
//       import FirebaseCrashlytics
//
//       @main
//       struct AppMain: App {
//           init() {
//               FirebaseApp.configure()
//           }
//           var body: some Scene {
//               WindowGroup { ContentView() }
//           }
//       }
//
//  ----------------------------------------------------------------------
//  3. Запуск приложения на реальном устройстве через Xcode
//
//  3.1. В верхней панели Xcode выбрать устройство:
//       • Слева от кнопки Run (▶️) выбрать iPhone 15.
//
//  3.2. Нажать Run (⌘R).
//       Xcode:
//       • соберёт приложение,
//       • подпишет его твоим Personal Team,
//       • установит на iPhone,
//       • автоматически запустит.
//
//  3.3. Если iPhone покажет ошибку «Untrusted Developer»:
//       На iPhone:
//       Settings → General → VPN & Device Management → выбрать профиль → Trust.
//
//  ----------------------------------------------------------------------
//  4. Тестирование Crashlytics на реальном устройстве
//
//  4.1. Добавить тестовый экран/кнопку для краша:
//
//       struct CrashTestView: View {
//           var body: some View {
//               VStack(spacing: 20) {
//                   Button("Test fatalError crash") {
//                       fatalError("Test Crash for Firebase Crashlytics")
//                   }
//                   Button("Test Crashlytics error") {
//                       let error = NSError(
//                           domain: "TestCrash",
//                           code: 999,
//                           userInfo: [NSLocalizedDescriptionKey: "Intentional test error"]
//                       )
//                       Crashlytics.crashlytics().record(error: error)
//                   }
//               }
//           }
//       }
//
//       struct ContentView: View {
//           var body: some View { CrashTestView() }
//       }
//
//  4.2. Запустить приложение на iPhone через Run (⌘R).
//
//  4.3. Вызвать краш:
//       • fatalError — приложение упадёт сразу.
//       • record(error:) — приложение не упадёт, но Crashlytics отправит событие.
//
//  4.4. После краша снова открыть приложение,
//       чтобы Crashlytics отправил отчёт на сервер.
//
//  ----------------------------------------------------------------------
//  5. Проверка отчёта в Firebase Crashlytics
//
//  5.1. Открыть Firebase Console → Crashlytics.
//  5.2. Через 1–5 минут появится новый крэш или ошибка.
//  5.3. Firebase покажет UUID, который нужен для dSYM.
//
//  ----------------------------------------------------------------------
//  6. Почему версия iOS 26 на iPhone НЕ является проблемой
//
//  • Важно только одно правило:
//        iOS на устройстве ≥ Deployment Target в проекте.
//
//  • Если Deployment Target = 17.5,
//        а устройство = iOS 18 / 19 / 26 — всё работает.
//
//  • Проблема была бы только если устройство имело iOS ниже 17.5.
//
//  • Xcode автоматически подгружает Device Support Files,
//        чтобы работать с более новой iOS.
//
//  ----------------------------------------------------------------------
//  7. Итог
//
//  • iPhone 15 можно подключить и использовать для тестирования Crashlytics.
//  • Разница версий iOS не мешает, если Deployment Target ≤ версия устройства.
//  • Запуск через Xcode (Run) — самый быстрый способ протестировать Crashlytics.
//  • Crashlytics работает только на реальном устройстве, не на симуляторе.
//
//






// инструкцию запуска приложения на устройстве прямо из Xcode (c .ipa)
// Release‑сборка




//
//  Что такое .ipa, зачем он нужен и как установить приложение на iPhone
//  Подробное объяснение для сохранения в Xcode.
//
//  ----------------------------------------------------------------------
//  1. Что такое .ipa
//
//  .ipa — это готовый установочный файл iOS‑приложения.
//  Это аналог .apk на Android или .exe/.dmg на Windows/macOS.
//
//  Внутри .ipa находится:
//  • собранное приложение (.app)
//  • ресурсы (картинки, шрифты, локализации)
//  • подпись разработчика (Personal Team или Developer Program)
//  • dSYM (иногда)
//  • метаданные сборки
//
//  .ipa — это то, что устанавливается на реальное устройство,
//  когда приложение НЕ запускается напрямую из Xcode.
//
//  ----------------------------------------------------------------------
//  2. Чем отличается запуск через Xcode от установки .ipa
//
//  Запуск через Xcode (Run):
//  • приложение собирается и ставится на устройство напрямую
//  • Xcode сам подписывает приложение твоим Personal Team
//  • приложение работает как Debug/Development версия
//  • удобно для разработки, но не подходит для тестирования Crashlytics
//    (потому что это не Release‑сборка)
//
//  Установка .ipa:
//  • это полноценная Release‑сборка
//  • приложение работает так же, как у реальных пользователей
//  • создаётся корректный dSYM
//  • UUID совпадает с архивом
//  • Crashlytics работает на 100% корректно
//
//  Итог:
//  • Run из Xcode — для разработки
//  • .ipa — для тестирования Crashlytics и реального поведения приложения
//
//  ----------------------------------------------------------------------
//  3. Как создать .ipa в Xcode
//
//  3.1. Собрать архив:
//       Product → Archive
//
//  3.2. В Organizer выбрать архив → нажать "Distribute App".
//
//  3.3. Выбрать тип дистрибуции:
//       • Development (НЕ App Store)
//
//  3.4. Xcode создаст файл:
//       TemplateSwiftUIProject.ipa
//
//  ----------------------------------------------------------------------
//  4. Как установить .ipa на iPhone через Xcode
//
//  4.1. Подключить iPhone кабелем.
//
//  4.2. Открыть:
//       Xcode → Window → Devices and Simulators → вкладка Devices.
//
//  4.3. В списке выбрать iPhone 15.
//
//  4.4. Перетащить TemplateSwiftUIProject.ipa
//       в правую часть окна устройства.
//
//  4.5. Xcode установит приложение на iPhone.
//
//  Если появится ошибка "Untrusted Developer":
//       На iPhone → Settings → General → VPN & Device Management → Trust.
//
//  ----------------------------------------------------------------------
//  5. Почему Crashlytics нужно тестировать именно через .ipa
//
//  Crashlytics корректно работает ТОЛЬКО в Release‑сборке, потому что:
//
//  • только Release создаёт правильный dSYM
//  • только Release создаёт корректный UUID
//  • только Release работает как реальное приложение
//  • только Release отправляет настоящие отчёты о крашах
//
//  Запуск через Xcode (Run) НЕ подходит для Crashlytics, потому что:
//  • это Development‑сборка
//  • UUID другой
//  • dSYM другой
//  • Firebase не сможет расшифровать стек
//
//  ----------------------------------------------------------------------
//  6. Важный момент про версии iOS (iPhone 15 с iOS 26)
//
//  • Приложение можно установить, если:
//        iOS на устройстве ≥ Deployment Target в проекте.
//
//  • Если Deployment Target = 17.5,
//        а устройство = iOS 18 / 19 / 26 — всё работает.
//
//  • Проблема была бы только если устройство имело iOS ниже 17.5.
//
//  ----------------------------------------------------------------------
//  7. Итог
//
//  • .ipa — это готовый установочный файл приложения.
//  • Запуск через Xcode — для разработки.
//  • Установка .ipa — для тестирования Crashlytics.
//  • iPhone 15 с iOS 26 можно использовать без проблем,
//    если Deployment Target ≤ версия устройства.
//
//





//
//  Инструкция: как подключить iPhone 15, установить Release‑сборку
//  и протестировать Firebase Crashlytics (с расшифровкой стека)
//
//  1. Подготовка проекта (один раз)
//
//  1.1. Убедиться, что Firebase Crashlytics подключён:
//       - В проекте есть GoogleService-Info.plist
//       - В App / AppDelegate вызывается:
//           FirebaseApp.configure()
//       - Подключён Crashlytics (через SPM / CocoaPods / XCFramework)
//
//  1.2. Убедиться, что схема собирается в Release с dSYM:
//       - Target → Build Settings:
//         * Debug Information Format = "DWARF with dSYM File"
//         * ENABLE_USER_SCRIPT_SANDBOXING = NO (для таргета и проекта, если нужно)
//       - Scheme → Edit Scheme → Archive → Build Configuration = Release
//
//  1.3. Убедиться, что код‑сайн настроен:
//       - Target → Signing & Capabilities:
//         * Галочка "Automatically manage signing" включена
//         * Team: "Evgeniy Klenov (Personal Team)"
//         * Bundle Identifier: klenov.TemplateSwiftUIProject
//       - Provisioning Profile: Xcode Managed Profile
//       - Signing Certificate: Apple Development (личный Apple ID)
//
//  ----------------------------------------------------------------------
//  2. Подключение iPhone 15 к Mac
//
//  2.1. Подключить iPhone 15 к Mac кабелем (USB‑C / Lightning → USB‑C).
//
//  2.2. На iPhone:
//       - При первом подключении появится диалог "Доверять этому компьютеру?"
//       - Нажать "Доверять" / "Trust"
//       - Ввести код‑пароль устройства.
//
//  2.3. На Mac / в Xcode:
//       - Открыть Xcode → меню Window → Devices and Simulators
//       - Во вкладке "Devices" должен появиться iPhone 15
//         с зелёной точкой / статусом "Connected".
//       - Если Xcode просит "Use for Development" — согласиться.
//       - Если Xcode просит залогиниться Apple ID — войти под тем же Apple ID,
//         что и в "Personal Team".
//
//  ----------------------------------------------------------------------
//  3. Сборка Release‑архива (Archive)
//
//  3.1. В Xcode выбрать:
//       - Scheme: TemplateSwiftUIProject (iOS App)
//       - Any iOS Device (или конкретный iPhone, не симулятор)
//
//  3.2. Собрать архив:
//       - Меню Product → Archive
//       - Дождаться окончания сборки и появления окна Organizer.
//
//  3.3. В Organizer:
//       - В левой колонке выбрать архив вида:
//         "TemplateSwiftUIProject 26.01.26, 15:41" (Version 1.0 (1))
//       - Убедиться, что:
//         * Identifier: klenov.TemplateSwiftUIProject
//         * Team: Evgeniy Klenov (Personal Team)
//         * Type: iOS App Archive
//
//  ----------------------------------------------------------------------
//  4. Экспорт .ipa для установки на iPhone
//
//  4.1. В Organizer нажать кнопку "Distribute App".
//
//  4.2. В мастере дистрибуции выбрать:
//       - "Development" (НЕ App Store, НЕ Ad Hoc, НЕ Enterprise).
//
//  4.3. Далее оставить настройки по умолчанию:
//       - Xcode сам выберет "Evgeniy Klenov (Personal Team)".
//       - Переподписывать ничего не нужно, просто "Next".
//
//  4.4. В конце мастер спросит, куда сохранить файл:
//       - Выбрать папку (например, Desktop).
//       - Будет создан файл вида:
//           TemplateSwiftUIProject.ipa
//
//  ----------------------------------------------------------------------
//  5. Установка .ipa на iPhone 15 через Xcode
//
//  5.1. Убедиться, что iPhone 15 подключён и виден в:
//       - Xcode → Window → Devices and Simulators → вкладка Devices.
//
//  5.2. В окне Devices and Simulators:
//       - В списке слева выбрать iPhone 15.
//       - Справа будет информация об устройстве (iOS версия, установленные приложения).
//
//  5.3. Установка .ipa:
//       - Открыть Finder и найти файл TemplateSwiftUIProject.ipa.
//       - Перетащить .ipa мышкой в правую часть окна устройства в Xcode
//         (в список приложений или просто на область с устройством).
//       - Xcode установит приложение на iPhone 15.
//       - На iPhone появится иконка TemplateSwiftUIProject.
//
//  5.4. Если iPhone ругается на доверие разработчику:
//       - На iPhone: Settings → General → VPN & Device Management
//         (или Profiles & Device Management).
//       - Найти профиль с твоим Apple ID / Personal Team.
//       - Нажать "Trust" / "Доверять этому разработчику".
//
//  ----------------------------------------------------------------------
//  6. Подготовка тестового краша для Crashlytics
//
//  6.1. Убедиться, что Firebase и Crashlytics инициализируются:
//
//       import FirebaseCore
//       import FirebaseCrashlytics
//
//       @main
//       struct TemplateSwiftUIProjectApp: App {
//           init() {
//               FirebaseApp.configure()
//           }
//
//           var body: some Scene {
//               WindowGroup {
//                   ContentView()
//               }
//           }
//       }
//
//  6.2. Добавить тестовую кнопку/экран для краша, например:
//
//       struct CrashTestView: View {
//           var body: some View {
//               VStack(spacing: 20) {
//                   Button("Test fatalError crash") {
//                       fatalError("Test Crash for Firebase Crashlytics")
//                   }
//
//                   Button("Test Crashlytics error") {
//                       let error = NSError(
//                           domain: "TestCrash",
//                           code: 999,
//                           userInfo: [NSLocalizedDescriptionKey: "Intentional test error for Crashlytics"]
//                       )
//                       Crashlytics.crashlytics().record(error: error)
//                   }
//               }
//               .padding()
//           }
//       }
//
//       // В ContentView временно показать CrashTestView:
//       struct ContentView: View {
//           var body: some View {
//               CrashTestView()
//           }
//       }
//
//  ----------------------------------------------------------------------
//  7. Вызов краша на реальном устройстве
//
//  7.1. На iPhone 15:
//       - Найти и открыть приложение TemplateSwiftUIProject.
//       - Перейти на экран с CrashTestView (если он не стартовый — сделать его стартовым).
//
//  7.2. Для жёсткого краша (fatalError):
//       - Нажать кнопку "Test fatalError crash".
//       - Приложение упадёт сразу.
//       - После этого снова открыть приложение хотя бы один раз,
//         чтобы Crashlytics успел отправить отчёт.
//
//  7.3. Для мягкого краша через record(error:):
//       - Нажать "Test Crashlytics error".
//       - Приложение не упадёт, но Crashlytics отправит событие ошибки.
//       - Подождать 1–2 минуты.
//
//  ----------------------------------------------------------------------
//  8. Поиск UUID и dSYM для этой сборки
//
//  8.1. На Mac открыть Terminal.
//
//  8.2. Перейти в папку с архивами Xcode:
//
//       cd ~/Library/Developer/Xcode/Archives
//       ls
//
//       // Найти папку с нужной датой, например:
//       cd 2026-01-26
//       ls
//
//       // Увидеть архив вида:
//       // "TemplateSwiftUIProject 26.01.26, 15.41.xcarchive"
//
//  8.3. Перейти в dSYMs внутри архива:
//
//       cd "TemplateSwiftUIProject 26.01.26, 15.41.xcarchive/dSYMs"
//       ls
//
//       // Должен быть файл:
//       // TemplateSwiftUIProject.app.dSYM
//
//  8.4. Получить UUID из dSYM:
//
//       dwarfdump --uuid TemplateSwiftUIProject.app.dSYM
//
//       // Вывод будет вида:
//       // UUID: 3331F722-C0D8-3EC3-A92D-D26FB9A40E46 (arm64) TemplateSwiftUIProject.app.dSYM/...
//
//       // Этот UUID нужно сравнить с тем, что показывает Firebase Crashlytics.
//
//  8.5. Упаковать dSYM в zip для загрузки:
//
//       zip -r TemplateSwiftUIProject_dSYM.zip TemplateSwiftUIProject.app.dSYM
//
//       // Получится файл TemplateSwiftUIProject_dSYM.zip.
//
//  ----------------------------------------------------------------------
//  9. Загрузка dSYM в Firebase Crashlytics и получение стека
//
//  9.1. Открыть Firebase Console в браузере:
//       - Перейти в проект, где настроен TemplateSwiftUIProject.
//       - Открыть раздел Crashlytics.
//
//  9.2. Найти тестовый краш:
//       - В списке событий должен появиться новый крэш / ошибка.
//       - Открыть его и посмотреть UUID, который Crashlytics считает "Missing dSYM"
//         (или открыть вкладку с Missing dSYMs).
//
//  9.3. Сравнить UUID:
//       - UUID из Firebase должен совпасть с UUID из команды dwarfdump.
//       - Если совпадает — это именно тот dSYM.
//
//  9.4. Загрузить dSYM:
//       - В Crashlytics нажать "Upload dSYM" / "Загрузить dSYM".
//       - Выбрать файл TemplateSwiftUIProject_dSYM.zip.
//       - Подождать 1–5 минут.
//
//  9.5. Обновить страницу Crashlytics:
//       - Открыть тот же крэш.
//       - Если всё корректно:
//         * Статус dSYM станет "Uploaded".
//         * Стек вызовов будет с именами файлов и строками кода,
//           например: TemplateSwiftUIProject/CrashTestView.swift:42.
//
//  ----------------------------------------------------------------------
//  10. Краткий чеклист, если что‑то не работает
//
//  - Приложение точно запускалось на РЕАЛЬНОМ устройстве, а не на симуляторе?
//  - Краш произошёл именно в этой Release‑сборке (той же версии и архива)?
//  - UUID из Firebase совпадает с UUID из dwarfdump?
//  - dSYM упакован целиком (zip от .app.dSYM, а не от его содержимого)?
//  - Firebase получил событие (прошло 1–5 минут после краша)?
//
//  Если всё "да" — Crashlytics должен показывать расшифрованный стек.
//  Если что‑то из этого "нет" — нужно проверить соответствующий шаг.
//
//







// MARK: - Инструкции по работе с Crashlytics: создание .ipa, загрузка dSYM, проверка UUID


//
//  ПОЛНЫЙ ПОРЯДОК РАБОТЫ С CRASHLYTICS
//  (Archive → dSYM → .ipa → Install → Crash → Upload dSYM → Stacktrace)
//
//  Этот порядок — единственно правильный. Любое отклонение ломает Crashlytics.
//
//  ----------------------------------------------------------------------
//  1. СБОРКА RELEASE‑АРХИВА (Product → Archive)
//
//  1.1. В Xcode выбрать:
//       • Scheme: TemplateSwiftUIProject (iOS App)
//       • Any iOS Device (или конкретный iPhone, НЕ симулятор)
//
//  1.2. Собрать архив:
//       Product → Archive
//
//  1.3. После сборки откроется Organizer.
//       Проверить архив:
//       • Identifier: klenov.TemplateSwiftUIProject
//       • Team: Evgeniy Klenov (Personal Team)
//       • Type: iOS App Archive
//
//  Это создаёт:
//       • корректный dSYM
//       • правильный UUID
//       • Release‑приложение для устройства
//
//  ----------------------------------------------------------------------
//  2. ЭКСПОРТ .IPA ДЛЯ УСТАНОВКИ НА УСТРОЙСТВО
//
//  2.1. В Organizer нажать "Distribute App".
//
//  2.2. Выбрать тип дистрибуции:
//       • Development (НЕ App Store, НЕ Ad Hoc)
//
//  2.3. Оставить настройки по умолчанию:
//       • Xcode сам выберет Personal Team
//
//  2.4. Сохранить файл:
//       • TemplateSwiftUIProject.ipa
//
//  ----------------------------------------------------------------------
//  3. УСТАНОВКА .IPA НА iPHONE 15
//
//  3.1. Подключить iPhone 15 к Mac кабелем.
//
//  3.2. Открыть:
//       Xcode → Window → Devices and Simulators → Devices
//
//  3.3. Выбрать iPhone 15 в списке.
//
//  3.4. Установить .ipa:
//       • Перетащить TemplateSwiftUIProject.ipa в правую часть окна устройства
//       • Xcode установит приложение на iPhone
//
//  3.5. Если iPhone пишет “Untrusted Developer”:
//       Settings → General → VPN & Device Management → Trust Developer
//
//  ----------------------------------------------------------------------
//  4. ПОЛУЧЕНИЕ dSYM И ПРОВЕРКА UUID
//
//  4.1. Найти архив:
//       ~/Library/Developer/Xcode/Archives/<дата>/<имя>.xcarchive
//
//  4.2. Перейти в папку dSYMs:
//       <архив>.xcarchive/dSYMs/TemplateSwiftUIProject.app.dSYM
//
//  4.3. Проверить UUID:
//       dwarfdump --uuid TemplateSwiftUIProject.app.dSYM
//
//       Пример:
//       UUID: 3331F722-C0D8-3EC3-A92D-D26FB9A40E46 (arm64)
//
//  ----------------------------------------------------------------------
//  5. ВЫЗОВ ТЕСТОВОГО КРАША НА РЕАЛЬНОМ УСТРОЙСТВЕ
//
//  5.1. Убедиться, что Firebase и Crashlytics инициализируются:
//
//       FirebaseApp.configure()
//
//  5.2. Добавить тестовые кнопки:
//
//       fatalError("Test Crash for Firebase Crashlytics")
//
//       или:
//
//       Crashlytics.crashlytics().record(error: ...)
//
//  5.3. Запустить приложение на iPhone и нажать кнопку краша.
//
//  5.4. После краша снова открыть приложение,
//       чтобы Crashlytics отправил отчёт.
//
//  ----------------------------------------------------------------------
//  6. ЗАГРУЗКА dSYM В FIREBASE CRASHLYTICS
//
//  6.1. Открыть Firebase Console → Crashlytics.
//
//  6.2. Найти краш → посмотреть UUID, который Firebase считает Missing.
//
//  6.3. Упаковать dSYM в zip:
//
//       zip -r TemplateSwiftUIProject_dSYM.zip TemplateSwiftUIProject.app.dSYM
//
//  6.4. Загрузить zip в Firebase:
//       Crashlytics → Missing dSYMs → Upload
//
//  ----------------------------------------------------------------------
//  7. ПРОВЕРКА РЕЗУЛЬТАТА
//
//  • Если UUID совпал → стек расшифруется.
//  • Если UUID не совпал → краш был из другой сборки.
//
//  ----------------------------------------------------------------------
//  8. НУЖНО ЛИ УДАЛЯТЬ СТАРЫЕ dSYM?
//
//  • Нет, удалять НЕ нужно.
//  • Firebase хранит dSYM по UUID.
//  • Старые dSYM не мешают и могут понадобиться,
//    если придёт краш со старой версии.
//
//  ----------------------------------------------------------------------
//  ИТОГОВАЯ ЛОГИКА:
//
//  1) Archive
//  2) Export .ipa
//  3) Install .ipa
//  4) Crash
//  5) Firebase показывает UUID
//  6) Находим dSYM с этим UUID
//  7) Загружаем dSYM
//  8) Получаем расшифрованный стек
//
//  Это единственно правильный рабочий процесс Crashlytics.
//
//







//Если ты уже загрузил dSYM для конкретного UUID, то ВСЕ последующие краши с этим же UUID будут расшифровываться автоматически.



//
//  Что происходит после загрузки dSYM и нужно ли что‑то делать заново
//  Подробное объяснение для сохранения в Xcode.
//
//  ----------------------------------------------------------------------
//  КОРОТКИЙ ОТВЕТ:
//
//  Если dSYM для конкретного UUID уже загружен в Firebase,
//  то ВСЕ последующие краши этой же сборки будут расшифровываться
//  автоматически. Ничего повторно делать НЕ нужно.
//
//  ----------------------------------------------------------------------
//  ПОДРОБНО:
//
//  Crashlytics работает по формуле:
//
//      UUID сборки → dSYM → расшифровка стека
//
//  Каждый Archive создаёт свой уникальный UUID.
//  Когда ты загружаешь dSYM в Firebase, Crashlytics навсегда запоминает:
//
//      «Для UUID X нужно использовать dSYM Y»
//
//  Поэтому:
//
//  • Если ты НЕ делал новый Archive
//  • Если приложение на устройстве — та же самая сборка
//  • Если UUID краша совпадает с UUID загруженного dSYM
//
//  → Crashlytics расшифрует стек автоматически,
//    без повторной загрузки dSYM.
//
//  ----------------------------------------------------------------------
//  КОГДА НУЖНО ЗАГРУЖАТЬ dSYM СНОВА:
//
//  Только в одном случае:
//
//      Когда ты сделал НОВЫЙ Archive.
//
//  Новый Archive = новый UUID = новый dSYM.
//
//  Поэтому:
//
//  • Новый Archive → новый UUID → новый dSYM → новая загрузка.
//  • Старый Archive → старый UUID → dSYM уже загружен → всё работает.
//
//  ----------------------------------------------------------------------
//  ПРИМЕР:
//
//  1) Ты сделал Archive → UUID = ABC123
//  2) Загрузил dSYM для ABC123
//  3) Получил расшифрованный стек
//  4) Сделал новый краш этой же сборки → UUID = ABC123
//  5) Firebase сразу расшифровал стек
//
//  Потому что dSYM уже загружен.
//
//  ----------------------------------------------------------------------
//  КОГДА СТЕК НЕ РАСШИФРУЕТСЯ:
//
//  • Ты сделал новый Archive → UUID изменился
//  • Но dSYM для нового UUID НЕ загружен
//  • Firebase покажет Missing dSYM
//
//  ----------------------------------------------------------------------
//  ИТОГОВАЯ ФОРМУЛА:
//
//      Один Archive → один UUID → один dSYM → одна загрузка.
//      Все последующие краши этой сборки расшифровываются автоматически.
//
//  ----------------------------------------------------------------------
//
//  Ничего повторно делать не нужно, пока ты не создашь новый Archive.
//
//



//
//  Когда нужно заново загружать dSYM, а когда нет
//
//  UUID сборки меняется ТОЛЬКО когда создаётся новый Archive.
//  Изменение кода само по себе UUID НЕ меняет.
//
//  Поэтому:
//
//  • Если я изменил код, но НЕ делал Product → Archive,
//    то UUID остаётся прежним, dSYM прежний,
//    и Crashlytics продолжает расшифровывать краши автоматически.
//
//  • Если я сделал новый Archive,
//    то создаётся новый UUID,
//    появляется новый dSYM,
//    и Crashlytics требует загрузить этот новый dSYM.
//
//  Итог:
//      Новый Archive → новый UUID → новый dSYM → новая загрузка.
//      Без нового Archive ничего заново делать не нужно.
//
