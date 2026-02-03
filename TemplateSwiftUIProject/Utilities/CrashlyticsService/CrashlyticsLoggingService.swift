//
//  CrashlyticsLoggingService.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 2.02.26.
//



/// Что делает `Thread.callStackSymbols`:
/// - Собирает текущий стек вызовов в момент, когда мы попали в `SharedErrorHandler.handle(error:context:)`.
/// - Это список «откуда пришли» до точки обработки, включая ваши методы, Combine/SwiftUI слои и системные фреймы.
///
/// Зачем логировать стек в Crashlytics:
/// - Для команды разработки стек показывает полный путь ошибки: из какого экрана, какого менеджера,
///   какой операции она пришла, и где была обработана.
/// - Пользователь получает лаконичное сообщение, а Crashlytics — подробный технический след.
///
/// Как это выглядит в вашем кейсе (примерная структура стека):
/// Stack:
/// 0   MyApp      SharedErrorHandler.handle(error:context:)                   // централизованная точка обработки
/// 1   MyApp      AuthorizationManager.signInWithGoogle(intent:)              // источник: операция авторизации
/// 2   MyApp      HomeViewModel.googleSignIn()                                // инициатор из ViewModel
/// 3   MyApp      HomeContentView.body.getter                                 // экран Home, где вызвано действие
/// 4   MyApp      ViewBuilderService.homeViewBuild(page:)                     // сборка UI через ваш билдер
/// 5   SwiftUI    ViewGraph.update(...) / CombinePublisher.sink(...)          // системные слои SwiftUI/Combine
/// 6   UIKitCore  UIApplicationMain                                           // вход в цикл событий приложения
///
/// Важно:
/// - Стек формируется на момент вызова `handle(error:context:)`. Поэтому он отражает «путь» до централизованного обработчика,
///   что достаточно для диагностики «где в продуктовой цепочке возникла ошибка».
///
/// Как логировать:
/// let stack = Thread.callStackSymbols.joined(separator: "\n")
/// Crashlytics.crashlytics().log("Stack:\n\(stack)")
/// Crashlytics.crashlytics().record(error: error)
///
/// Результат:
/// - В отчёте Crashlytics вы увидите и саму ошибку, и полный стек вызовов, который ведёт к `SharedErrorHandler`.
/// - Это позволяет быстро сопоставить ошибку с конкретным экраном (Home), менеджером (AuthorizationManager),
///   и местом её обработки (SharedErrorHandler) в вашей архитектуре.





//
//  Пояснение: какие ошибки Crashlytics показывает полностью,
//  а какие — нет. Краткое резюме для разработчика.
//
//  ----------------------------------------------------------------------
//  ✔ Что Crashlytics показывает полностью
//
//  Crashlytics отлично работает с NSError, поэтому если ошибка
//  является NSError (или автоматически конвертируется в NSError),
//  то в консоли Crashlytics будут видны:
//
//  • domain
//  • code
//  • localizedDescription
//  • userInfo
//  • stacktrace (если мы логируем его вручную)
//
//  Firebase‑ошибки (Auth, Firestore, Storage) ВСЕ являются NSError,
//  поэтому Crashlytics показывает их полностью.
//
//  ----------------------------------------------------------------------
//  ❌ Что Crashlytics НЕ показывает полностью
//
//  Crashlytics НЕ умеет сериализовать чистые Swift‑ошибки,
//  которые НЕ являются NSError.
//
//  Это означает, что Crashlytics НЕ покажет:
//
//  • весь объект Swift‑ошибки
//  • enum‑ошибки с associated values
//  • вложенные структуры
//  • кастомные поля, которых нет в NSError
//
//  Crashlytics просто создаёт минимальный NSError:
//
//      domain = "Swift.Error"
//      code = 1
//      userInfo = пустой
//      message = имя типа ошибки
//
//  ----------------------------------------------------------------------
//  ❗ Примеры ошибок, которые НЕ будут полностью видны
//
//  1) Swift enum:
//
//      enum PhotoPickerError: Error {
//          case unsupportedType
//          case loadFailed(underlying: Error)
//      }
//
//  В Crashlytics будет видно только:
//
//      domain: Swift.Error
//      code: 1
//      message: "unsupportedType"
//
//  Но НЕ будет видно:
//      • что это enum
//      • что это case .unsupportedType
//      • что есть underlying error
//
//  ----------------------------------------------------------------------
//
//  2) Кастомная структура:
//
//      struct APIError: Error {
//          let statusCode: Int
//          let message: String
//          let metadata: [String: Any]
//      }
//
//  В Crashlytics НЕ будет видно:
//      • statusCode
//      • message
//      • metadata
//
//  ----------------------------------------------------------------------
//
//  ✔ Как передать дополнительные данные вручную
//
//  Если нужно, чтобы Crashlytics видел дополнительные поля,
//  их нужно передавать вручную:
//
//      Crashlytics.crashlytics().setCustomValue(value, forKey: key)
//
//  или:
//
//      Crashlytics.crashlytics().setCustomKeysAndValues([:])
//
//  ----------------------------------------------------------------------
//
//  ИТОГ:
//
//  • NSError → Crashlytics показывает полностью
//  • Firebase ошибки → показываются полностью
//  • Swift enum / struct ошибки → Crashlytics НЕ видит их внутренности
//  • Для кастомных данных → используем setCustomValue / setCustomKeysAndValues
//
//  ----------------------------------------------------------------------
//



//
//  Почему мы вызываем writeCustomKeys(userInfo),
//  даже если уже передали userInfo в crashlytics.record(error: nsError)
//
//  ----------------------------------------------------------------------
//  КРАТКИЙ ОТВЕТ:
//
//  • crashlytics.record(error:) использует userInfo ТОЛЬКО для текста ошибки
//  • но НЕ сохраняет userInfo как Custom Keys
//  • Custom Keys — это единственный способ видеть данные в UI Crashlytics,
//    фильтровать по ним, искать, анализировать и группировать ошибки
//
//  Поэтому writeCustomKeys(userInfo) — обязательный шаг.
//
//  ----------------------------------------------------------------------
//  ПОДРОБНО:
//
//  Когда мы вызываем:
//
//      crashlytics.record(error: nsError)
//
//  Crashlytics:
//
//  ✔ показывает domain
//  ✔ показывает code
//  ✔ показывает localizedDescription
//  ✔ может включить часть userInfo в текст ошибки
//
//  НО:
//
//  ❌ НЕ сохраняет userInfo как Custom Keys
//  ❌ НЕ позволяет фильтровать ошибки по userInfo
//  ❌ НЕ показывает userInfo как отдельные поля
//  ❌ НЕ даёт искать по userInfo
//  ❌ НЕ сохраняет userInfo в аналитике
//
//  То есть userInfo → это просто текст, а не структурированные данные.
//
//  ----------------------------------------------------------------------
//  ЗАЧЕМ writeCustomKeys(userInfo):
//
//  Метод:
//
//      writeCustomKeys(userInfo)
//
//  делает каждое поле userInfo отдельным Custom Key:
//
//      log_domain = Firestore
//      log_source = GalleryManager
//      log_severity = error
//      log_message = "Failed to fetch"
//      log_error_code = 7
//
//  Теперь в Crashlytics можно:
//
//  ✔ фильтровать ошибки по домену
//  ✔ смотреть, какие модули чаще всего падают
//  ✔ сортировать по severity
//  ✔ искать по message
//  ✔ анализировать error_code
//
//  Это превращает Crashlytics из “свалки ошибок” в полноценную систему аналитики.
//
//  ----------------------------------------------------------------------
//  ИТОГ:
//
//  • record(error:) → отправляет ошибку
//  • userInfo → используется только для текста
//  • writeCustomKeys → делает данные структурированными и доступными в UI
//
//  Оба вызова нужны, потому что они решают разные задачи.
//
//  ----------------------------------------------------------------------
//



/**
 Почему мы НЕ используем:
     if let appError = error as? AppInternalError

 И почему мы ВСЕГДА восстанавливаем AppInternalError через:
     let nsError = error as NSError
     if nsError.domain == AppInternalError.errorDomain,
        let appError = AppInternalError(rawValue: nsError.code)

 ---------------------------------------------------------------
 1. Swift НЕ гарантирует, что ошибка останется enum AppInternalError
 ---------------------------------------------------------------

 AppInternalError — это Swift enum, но в реальном приложении ошибка
 почти всегда проходит через один или несколько механизмов, которые
 автоматически преобразуют Error → NSError:

    • Combine (Future, Publisher, sink)
    • async/await
    • Firebase SDK (Auth, Firestore, Storage)
    • Foundation API (JSONEncoder, URLSession, FileManager)
    • любые Objective‑C API

 После такого bridging ошибка перестаёт быть enum и становится
 обычным NSError. В этот момент:

     (error as? AppInternalError) == nil

 То есть прямое приведение типа НЕ сработает в большинстве случаев.


 ---------------------------------------------------------------
 2. CustomNSError гарантирует domain + code, но НЕ гарантирует enum
 ---------------------------------------------------------------

 Благодаря CustomNSError каждая AppInternalError‑ошибка превращается в:

     NSError(
         domain: "com.yourapp.internal",
         code: <rawValue>,
         userInfo: [...]
     )

 Это означает, что мы ВСЕГДА можем восстановить enum по code:

     AppInternalError(rawValue: nsError.code)

 Но НЕ можем восстановить enum через:

     error as? AppInternalError


 ---------------------------------------------------------------
 3. Почему восстановление через domain + code — единственный надёжный путь
 ---------------------------------------------------------------

 Проверка:

     if nsError.domain == AppInternalError.errorDomain

 гарантирует, что ошибка действительно наша.

 А проверка:

     AppInternalError(rawValue: nsError.code)

 гарантирует, что мы корректно восстановим enum независимо от того,
 сколько раз ошибка прошла через bridging.

 Это работает ВСЕГДА:
    • для ошибок из сервисов
    • для ошибок из Combine
    • для ошибок из Firebase
    • для ошибок из async/await
    • для ошибок, которые уже стали NSError


 ---------------------------------------------------------------
 4. Почему это важно для Crashlytics
 ---------------------------------------------------------------

 Crashlytics работает только с NSError. Поэтому:

    • domain → используется для группировки ошибок
    • code → уникальный идентификатор кейса
    • userInfo → техническая информация
    • message → техническое описание (technicalDescription)

 Если бы мы полагались на:
     error as? AppInternalError

 то в 90% случаев мы бы НЕ получили enum и НЕ смогли бы
 отправить корректное technicalDescription в Crashlytics.


 ---------------------------------------------------------------
 5. Итог
 ---------------------------------------------------------------

 • error as? AppInternalError — НЕ надёжно (enum теряется после bridging)
 • nsError.domain + nsError.code — 100% надёжно
 • AppInternalError(rawValue: code) — всегда восстанавливает enum
 • Crashlytics получает стабильный английский technicalDescription
 • UI получает локализованный текст через LocalizedError

 Это гарантирует:
    • предсказуемую архитектуру
    • корректную группировку ошибок
    • стабильные Crashlytics‑логи
    • чистый и расширяемый код
 */







import Foundation
import FirebaseCrashlytics


//  Severity

enum ErrorSeverityLevel: String {
    case fatal
    case error
    case warning
    case info
}


protocol ErrorLoggingServiceProtocol {
    func logError(
        _ error: Error,
        domain: String?,
        source: String,
        message: String?,
        params: [String: Any]?,   // params: дополнительные параметры, которые мы хотим передать в Crashlytics
        severity: ErrorSeverityLevel
    )
}


final class CrashlyticsLoggingService: ErrorLoggingServiceProtocol {

    static let shared = CrashlyticsLoggingService()
    private let crashlytics = Crashlytics.crashlytics()

    private init() {}

    func logError(
        _ error: Error,
        domain: String? = nil,
        source: String,
        message: String?,
        params: [String: Any]?,
        severity: ErrorSeverityLevel
    ) {
        let nsError = error as NSError

        // Реальный домен ошибки
        let realDomain = domain ?? nsError.domain
        
        // Техническое сообщение для Crashlytics (всегда английское)
        let technicalMessage: String = {
            if nsError.domain == AppInternalError.errorDomain,
               let appError = AppInternalError(rawValue: nsError.code) {
                return appError.technicalDescription
            } else {
                return message ?? error.localizedDescription
            }
        }()

        var userInfo: [String: Any] = [
            "domain": realDomain,
            "source": source,
            "severity": severity.rawValue,
            "localized_description": technicalMessage,
            "error_code": nsError.code
        ]
        
        userInfo["message"] = technicalMessage


        // params — дополнительные параметры, которые разработчик может передать вручную
        // merge(params) — объединяет словари, НЕ перезаписывая существующие ключи userInfo
        if let params = params {
            userInfo.merge(params) { current, _ in current }
        }

        userInfo["stacktrace"] = Thread.callStackSymbols.joined(separator: "\n")

        // Превращаем в NSError, чтобы Crashlytics корректно отобразил domain/code/userInfo
        let wrappedError = NSError(
            domain: realDomain,
            code: nsError.code,
            userInfo: userInfo
        )

        crashlytics.record(error: wrappedError)

        // Custom Keys для фильтрации и аналитики
        userInfo.forEach { key, value in
            crashlytics.setCustomValue(value, forKey: "log_\(key)")
        }

        // Текстовый лог
        crashlytics.log("[\(severity.rawValue.uppercased())] \(source): \(technicalMessage)")
    }
}
