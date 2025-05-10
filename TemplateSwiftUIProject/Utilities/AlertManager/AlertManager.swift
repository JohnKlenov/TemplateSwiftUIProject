//
//  AlertManager.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 2.12.24.
//



// MARK: - inout parametrs showGlobalAlert

/// мы должны хорошо продумать о том какие параметры передовать в showGlobalAlert message: String, operationDescription: String
/// они должны хорошо отражать проблему , понятную для пользователя
///  вопрос нужно ли не сокращать однотипные ошибки до одного  алерта if !globalAlert[nameKey]!.contains(where: { $0.operationDescription == operationDescription }) ?

// MARK: - new imlemintation AlertManager and errorHandling

/// все начилось с того что я захотел сделать возможным из любого места в app иметь возможность retry createUserAnonimous!

// Get data ( addSnapshotListener + getDocuments, getDocument если кэш не пуст ошибки не выбросит долгое время) / ContentErrorView

// Post data (setData + addDocument + updateData)

/// debug/release: любая запись succes если в блок приходит error логируем в Crashlytics +FirestoreOperationsManager+ отображаем на глобальном алерт
/// FirestoreOperationsManager(сохраняем статус всех операций записи )
/// для чего нужен FirestoreOperationsManager (операцию проверки делать на очереди в low priority):
/// ошибка из блока может не прийти никогда (1. Не дождались возврата ошибки и вышли из приложения, 2. сервис который отвечал за Post data был init in viewModel а View была в NavigationStack или modalPesented и закрылось до получения ответа об ошибки в блоке)
/// !!!!! желательно что бы все Service были в shared environment и тогда это будет единственная точка откуда мы будем деркать Api FirestoreOperationsManager
/// и будет больше шансов получить ошибку в текущей сессии App (в нашей кодовой базе все операции записи идут через CRUDSManager который живет весь жизненный цикл App и он передает ошибку в AlertManager)

///в нашем коде CRUDSManager(работает с глобальным алертом)  через который проходят все операции записи инициируется глобально в ViewBuilderService и живет там весь жизненный цикл App то есть ошибка при неудачном сохранении данных в отложенном сценарии пока App в памяти придет!
///иначе придется использовать FirestoreOperationsManager

/// оффлайн-поддержа запись выполняется локально а затем ждет синхронизации с сервером.
///Если же существуют проблемы, независимо от сети тогда ошибка будет передана в блок error. Но не факт что этот блок еще будет в памяти.
///Если проблема возникает, например, из-за нарушения правил безопасности или некорректных данных, ошибка будет возвращена через блок error мгновенно но если интернет плохой, то и ошибка из-за нарушения правил может отреагировать с задержкой.
///Заносите информацию о попытке записи, её статус или ошибок в долговременное хранилище (например, UserDefaults, local database или на уровне бизнес-логики). При следующем запуске приложения можно проверить, была ли операция завершена корректно, и уведомить пользователя о неудачной попытке.
///Firebase Crashlytics
///Если операция критична для пользователя, можно предусмотреть промежуточное состояние с индикатором незавершённой синхронизации или временным статусом «Ожидание подтверждения от сервера»

// AlertManager and errorHandling

/// основные моменты: максимально уйти от localAlert или совсем его убрать (так как в процессе вызова локальных и глобальных алертов они могут уничтожать один другого что усложнит логику AlertManager). оставить globalAlert для максимально критических ошибок (Auth ... )  и не только.
/// использовать errorHandling дизайн GitHub. Если у нас не получается отобоазить данные(get + observer) на View размещаем ContentErrorView (на всех экранах NavigationStack)
/// если ошибка приходит от addSnapshotListener отображваем ContentErrorView (localAlert не используем)

/// localAlert мы можем применять только там где моментально получаем информацио об ошибки (Put data а они nil, failed validation .. )
/// пользователь должен как можно меньше получать информации об ошибки , только ту информацию которая ему может реально помочь!

// log Crashlytics
/// все log уходят из SharedErrorHandler 






// MARK: - AlertManager

//появление предупреждения (желтого warning) в консоли.

///SwiftUI пытается показать алерт в момент, когда вид, к которому он прикреплён, не находится в активном или видимом контексте.
///система регистрирует конфликт в иерархии представлений, приводит к появлению предупреждения (желтого warning) в консоли.
/// если мы разместим код отображения alert на rootView но при этом он сработает в момент когда  childView лежит поверх rootView мы получим желтый ворнинг в консоль ?
///Такое предупреждение не обязательно означает фатальную ошибку, но сигнализирует о том, что реализация показа алертов может работать не так, как ожидалось. Чтобы избежать подобных ситуаций, рекомендуется: Привязывать алерты к активным представлениям, Контролировать показ алертов,
///желтые предупреждения (warnings) в консоли не означают, что приложение будет работать некорректно в продакшене. Это больше сигнал, что какая-то часть логики (например, показ алерта на rootView, когда поверх него уже находится childView) может быть реализована не идеально с точки зрения управления иерархией представлений.
///Однако с точки зрения качественного кода и дальнейшего обслуживания рекомендуется по возможности избегать подобных предупреждений, чтобы не вводить в заблуждение других разработчиков и не создавать потенциальных проблем при дальнейшем развитии приложения.

// Глобальные алерты + Локальные алерты

///Глобальные алерты: Используются для критических ошибок, которые могут затронуть весь функционал приложения. Эти алерты управляются на уровне корневого представления.
///Локальные алерты: Используются для ошибок, специфичных для текущего представления или действия. Эти алерты управляются непосредств енно в представлении, где происходит ошибка.

///На iOS система не позволяет одновременно отображать два алерта. Если второй алерт будет вызван, пока первый алерт уже отображается, второй алерт не появится до тех пор, пока первый не будет закрыт.

///SwiftUI обрабатывает модификаторы снизу вверх. GlobalAlert, будучи "ближе" к корню, получает приоритет.
///SwiftUI не позволяет отображать несколько алертов одновременно. При активации нового: Текущий алерт автоматически закрывается / Новый алерт замещает предыдущий


// приоритет работы alert в AlertManager

/// в связи с сложностью совместной работы LocalAlert и GlobalAlert принито решение оставить только GlobalAlert

/// если в одном стеке срабатывают LocalAlert из rootView дважды то они не уничтожают один другого.
/// если вызовы alert происходят из разных стековв - GlobalAlert из rootView закрывает LocalalAlert из дочернего стека
/// и на оборот LocalalAlert из дочернего стека закрывает GlobalAlert из rootView

/// GalleryView
/// в маем коде работа AlertManager следующая
/// showGlobalAlert поверх showLocalalAlert
/// при вызове showGlobalAlert поверх showLocalalAlert LocalalAlert  закрывается и отображается GlobalAlert но из var localAlerts: [String: [AlertData]] не удаляется
/// затем после закрытия GlobalAlert когда мы уходим из GalleryView и снова заходим на GalleryView  срабатывает LocalalAlert так как все Publisher отрабатывают
/// но если isVisibleView удален то LocalalAlert больше не срабатывает

///showLocalalAlert поверх showLocalalAlert
///если мы добавляем showLocalalAlert поверх showLocalalAlert то первый LocalalAlert не закрывается но когда мы нажимаем на OK то отрабатывает viewModel.alertManager.resetFirstLocalAlert(forView: nameView) (с задержкой в 0.1 сек) и когда отрабатывает localAlerts[view] = alerts то отображается второй LocalalAlert который отработал позже первого. Но почему это работает только с  задержкой в 0.1 сек(DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { })???

///showLocalalAlert поверх showGlobalAlert
///если мы добавляем showLocalalAlert поверх showGlobalAlert то  GlobalAlert  закрывается и отображается LocalAlert но когда мы нажимаем на его OK то GlobalAlert больше не отображается и при повторном переходе на HomeView тоже

/// showGlobalAlert поверх showGlobalAlert
/// работает точно так же как showLocalalAlert поверх showLocalalAlert

// когда мы убрали из AlertManager @Published var isViewVisible
/// при первом отображении GlobalAlert и последующим срабатывании LocalAlert: GlobalAlert не исчезает но после нажатия кнопки на GlobalAlert и его исчезновения LocalAlert не отображается и следовательно не срабатывает func resetFirstLocalAlert





import SwiftUI
import Combine


// MARK: - Enum для типа алерта

enum AlertType {
    case authentication
    case common
}

// MARK: - Модель данных алерта

struct AlertData: Identifiable, Equatable {
    let id = UUID()
    let message: String
    let operationDescription: String
    let type: AlertType
    
    static func == (lhs: AlertData, rhs: AlertData) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Протокол для менеджера алертов

protocol AlertManagerProtocol: ObservableObject {
    var globalAlert: [String: [AlertData]] { get set }
    func showGlobalAlert(message: String, operationDescription: String, alertType: AlertType)
    func resetFirstGlobalAlert()
}

// MARK: - Реализация менеджера алертов

class AlertManager: AlertManagerProtocol {
    
    static let shared = AlertManager()
    private let nameKey = "globalError"
    
    @Published var globalAlert: [String: [AlertData]] = [:] {
        didSet {
            print("globalAlert - \(globalAlert)")
        }
    }
    
    init() {}
    
    func showGlobalAlert(message: String, operationDescription: String, alertType: AlertType) {
        let alert = AlertData(message: message, operationDescription: operationDescription, type: alertType)
        if globalAlert[nameKey] == nil {
            globalAlert[nameKey] = [alert]
        } else if !globalAlert[nameKey]!.contains(where: { $0.operationDescription == operationDescription }) {
            globalAlert[nameKey]?.append(alert)
        }
    }
    
    func resetFirstGlobalAlert() {
        if var alerts = globalAlert[nameKey], !alerts.isEmpty {
            alerts.removeFirst()
            if alerts.isEmpty {
                globalAlert[nameKey] = nil
            } else {
                globalAlert[nameKey] = alerts
            }
        }
    }
    
    /// можно не сокращать однотипные ошибки до одного  алерта
//func showGlobalAlert(message: String, operationDescription: String, alertType: AlertType) {
//            let alert = AlertData(message: message, operationDescription: operationDescription, type: alertType)
//    
//            if globalAlert[nameKey] == nil {
//                globalAlert[nameKey] = [alert]
//            } else {
//                globalAlert[nameKey]?.append(alert)
//            }
//        }
}



//        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
//            self?.showGlobalAlert(message: "This is a test global alert 1.", operationDescription: "Test 1", alertType: .common)
//        }
//        DispatchQueue.main.asyncAfter(deadline: .now() + 15) { [weak self] in
////            self?.showLocalalAlert(message: "This is a test local alert 2.", forView: "HomeView", operationDescription: "Test 2", alertType: .common)
//            self?.showGlobalAlert(message: "This is a test global alert 2.", operationDescription: "Test 2", alertType: .common)
//        }


//    private var currentRetryHandler: (() -> Void)? = nil {
//        didSet {
//            print("currentRetryHandler - \(String(describing: currentRetryHandler))")
//        }
//    }

//
//    // Устанавливаем обработчик с автоматическим weak захватом
//    func setAuthenticationRetryHandler(_ handler: @escaping () -> Void) {
//        currentRetryHandler = { [weak self] in
//            handler()
//            self?.clearRetryHandler()
//        }
//    }
//
//    func triggerRetry() {
//        currentRetryHandler?()
//    }
//
//    func clearRetryHandler() {
//        currentRetryHandler = nil
//    }

// Инициализация таймера для вызова showGlobalAlert каждую минуту
//            timer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
//                guard let self = self else { return }
//                self.showGlobalAlert(message: "This is a global alert.", operationDescription: "Periodic alert")
//            }

//            timer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
//                guard let self = self else { return }
//                self.showLocalalAlert(message: "This is a test local alert.", forView: "HomeView", operationDescription: "Test")
//            }



//protocol AlertManagerProtocol: ObservableObject {
//    var globalAlert: [String: [AlertData]] { get set }
//    var localAlerts: [String: [AlertData]] { get set }
//    func showGlobalAlert(message: String, operationDescription: String)
//    func showLocalalAlert(message: String, forView view: String, operationDescription: String)
//    func resetFirstLocalAlert(forView view: String)
//    func resetFirstGlobalAlert()
//}


// MARK: - FirestoreOperationsManager

///. Если же пользователь свернёт приложение или система выгрузит его из памяти до того, как ответ от сервера придет, то этот блок не будет вызван. В таком случае pending-операция останется в долговременном хранилище (например, в UserDefaults) со статусом .pending.
///Чтобы решить эту проблему и обеспечить «отслеживание» успешной или неуспешной отправки даже если приложение было закрыто:

///можно сохранить информацию о каждом отправляемом документе (например, его идентификатор) и затем при следующем запуске (или когда приложение снова становится активным) выполнить запрос для проверки состояния этого документа. При получении DocumentSnapshot можно использовать свойство metadata.hasPendingWrites для определения, находятся ли изменения в очереди, или уже синхронизированы с сервером.


// сервер

//import Foundation
//import FirebaseFirestore
//import FirebaseFirestoreSwift
//import Network
//
//class FirestoreOperationsManager: ObservableObject {
//    
//    static let shared = FirestoreOperationsManager()
//    
//    @Published var pendingOperations: [FirestoreWriteOperation] = []
//    
//    private let userDefaultsKey = "pendingFirestoreOperations"
//    private var db = Firestore.firestore()
//    
//    init() {
//        loadPendingOperations()
//    }
//    
//    // Загружаем список операций из UserDefaults
//    private func loadPendingOperations() {
//        if let data = UserDefaults.standard.data(forKey: userDefaultsKey) {
//            do {
//                let ops = try JSONDecoder().decode([FirestoreWriteOperation].self, from: data)
//                self.pendingOperations = ops
//            } catch {
//                print("Ошибка декодирования операций: \(error)")
//                self.pendingOperations = []
//            }
//        }
//    }
//    
//    // Сохраняем операции в UserDefaults
//    private func savePendingOperations() {
//        do {
//            let data = try JSONEncoder().encode(pendingOperations)
//            UserDefaults.standard.set(data, forKey: userDefaultsKey)
//        } catch {
//            print("Ошибка кодирования операций: \(error)")
//        }
//    }
//    
//    /// Добавление документа в Firestore с сохранением идентификатора документа.
//    /// Используем setData на конкретном documentReference, чтобы сразу получить documentID.
//    func addDocument(data: [String: Any], description: String, completion: @escaping (Bool) -> Void) {
//        // Создаем документ с заранее определенным ID.
//        let docRef = db.collection("myCollection").document()
//        let operationId = UUID().uuidString
//        var operation = FirestoreWriteOperation(
//            id: operationId,
//            timestamp: Date(),
//            description: description,
//            status: .pending,
//            documentID: docRef.documentID
//        )
//        pendingOperations.append(operation)
//        savePendingOperations()
//        
//        // Отправляем данные
//        docRef.setData(data) { [weak self] error in
//            guard let self = self else { return }
//            if let error = error {
//                if let index = self.pendingOperations.firstIndex(where: { $0.id == operationId }) {
//                    self.pendingOperations[index].status = .failed(error.localizedDescription)
//                }
//                self.savePendingOperations()
//                completion(false)
//            } else {
//                if let index = self.pendingOperations.firstIndex(where: { $0.id == operationId }) {
//                    self.pendingOperations[index].status = .success
//                }
//                self.savePendingOperations()
//                completion(true)
//            }
//        }
//    }
//    
//    /// Функция, которая проверяет состояние ранее отправленных документов.
//    /// Если documentID известен, мы получаем документ и смотрим, есть ли еще pendingWrites.
//    func checkOperationStatus(for operation: FirestoreWriteOperation, completion: @escaping (FirestoreWriteOperation) -> Void) {
//        guard let documentID = operation.documentID else {
//            completion(operation)
//            return
//        }
//        
//        let docRef = db.collection("myCollection").document(documentID)
//        // Запрашиваем документ с типом запроса default (использует локальный кэш + синхронизацию с сервером)
//        docRef.getDocument { snapshot, error in
//            var updatedOperation = operation
//            if let error = error {
//                // Если получили ошибку, фиксируем её
//                updatedOperation.status = .failed(error.localizedDescription)
//            } else if let snapshot = snapshot {
//                // Если hasPendingWrites == false, запись синхронизирована
//                if snapshot.metadata.hasPendingWrites {
//                    updatedOperation.status = .pending
//                } else {
//                    updatedOperation.status = .success
//                }
//            }
//            completion(updatedOperation)
//        }
//    }
//    
//    /// Проверка всех pending операций, обновление их статуса и возврат списка обновлённых операций.
//    func recheckPendingOperations(completion: @escaping ([FirestoreWriteOperation]) -> Void) {
//        let pendingOps = pendingOperations.filter { op in
//            if case .pending = op.status { return true }
//            return false
//        }
//
//        let group = DispatchGroup()
//        var updatedOperations = pendingOperations
//        
//        for op in pendingOps {
//            group.enter()
//            checkOperationStatus(for: op) { updatedOp in
//                if let index = updatedOperations.firstIndex(where: { $0.id == updatedOp.id }) {
//                    updatedOperations[index] = updatedOp
//                }
//                group.leave()
//            }
//        }
//        
//        group.notify(queue: .main) {
//            self.pendingOperations = updatedOperations
//            self.savePendingOperations()
//            completion(updatedOperations)
//        }
//    }
//}



//клиент

//import SwiftUI
//
//struct AppContentView: View {
//    @StateObject var operationsManager = FirestoreOperationsManager.shared
//    @State private var showAlert = false
//    @State private var alertMessage = ""
//    
//    var body: some View {
//        VStack(spacing: 20) {
//            Text("Главный экран приложения")
//                .font(.largeTitle)
//            
//            Button("Добавить документ") {
//                let sampleData: [String: Any] = ["name": "Тестовый документ", "value": 42]
//                operationsManager.addDocument(data: sampleData, description: "Добавление тестового документа") { success in
//                    if !success {
//                        // Можно сразу отобразить ошибку (если присутствует)
//                        alertMessage = "Ошибка записи документа"
//                        showAlert = true
//                    }
//                }
//            }
//            
//            // Отображение списка pending операций (для отладки)
//            List(operationsManager.pendingOperations) { op in
//                VStack(alignment: .leading) {
//                    Text(op.description)
//                    Text("Статус: \(statusText(for: op.status))")
//                        .font(.footnote)
//                        .foregroundColor(.gray)
//                }
//            }
//        }
//        .onAppear {
//            // При запуске снова проверяем состояние операций
//            operationsManager.recheckPendingOperations { ops in
//                let failed = ops.filter {
//                    if case .failed(let message) = $0.status, !message.isEmpty {
//                        return true
//                    }
//                    return false
//                }
//                if !failed.isEmpty {
//                    // Если есть операции, завершившиеся с ошибкой, оповещаем пользователя
//                    alertMessage = "Некоторые операции не были синхронизированы с сервером."
//                    showAlert = true
//                }
//            }
//        }
//        .alert(isPresented: $showAlert) {
//            Alert(title: Text("Статус операций"),
//                  message: Text(alertMessage),
//                  dismissButton: .default(Text("OK")))
//        }
//    }
//    
//    func statusText(for status: WriteOperationStatus) -> String {
//        switch status {
//        case .pending: return "pending"
//        case .success: return "success"
//        case .failed(let error): return "failed: \(error)"
//        }
//    }
//}




//class AlertManager: AlertManagerProtocol {
//
//    static let shared = AlertManager()
//
//    @Published var globalAlert: [String: [AlertData]] = [:] {
//        didSet {
//            print("globalAlert - \(globalAlert)")
//        }
//    }
//
//    @Published var localAlerts: [String: [AlertData]] = [:] {
//        didSet {
//            print("localAlerts - \(localAlerts)")
//        }
//    }
//
//    private var timer: Timer?
//
//        init() {}
//
//    func showGlobalAlert(message: String, operationDescription: String) {
//        let alert = AlertData(message: message, operationDescription: operationDescription)
//
//        if globalAlert["globalError"] == nil {
//            globalAlert["globalError"] = [alert]
//        } else {
//            globalAlert["globalError"]?.append(alert)
//        }
//    }
//
//    func showLocalalAlert(message: String, forView view: String, operationDescription: String) {
//
//        let alert = AlertData(message: message, operationDescription: operationDescription)
//
//        if localAlerts[view] == nil {
//            localAlerts[view] = [alert]
//        } else if !localAlerts[view]!.contains(where: { $0.operationDescription == operationDescription }) {
//            localAlerts[view]?.append(alert)
//        }
//    }
//
//    func resetFirstLocalAlert(forView view: String) {
//        if var alerts = localAlerts[view], !alerts.isEmpty {
//            alerts.removeFirst()
//            if alerts.isEmpty {
//                localAlerts[view] = nil
//            } else {
//                localAlerts[view] = alerts
//            }
//        }
//    }
//
//    func resetFirstGlobalAlert() {
//        if var alerts = globalAlert["globalError"], !alerts.isEmpty {
//            alerts.removeFirst()
//            if alerts.isEmpty {
//                globalAlert["globalError"] = nil
//            } else {
//                globalAlert["globalError"] = alerts
//            }
//        }
//    }
//}
//
//extension Notification.Name {
//    static let globalAlert = Notification.Name("globalAlert")
//}



//// Инициализация таймера для вызова showGlobalAlert каждую минуту
////            timer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
////                guard let self = self else { return }
////                self.showGlobalAlert(message: "This is a global alert.", operationDescription: "Periodic alert")
////            }
//DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
//    self?.showLocalalAlert(message: "This is a test local alert.", forView: "HomeView", operationDescription: "Test")
//}
////            timer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
////                guard let self = self else { return }
////                self.showLocalalAlert(message: "This is a test local alert.", forView: "HomeView", operationDescription: "Test")
////            }



// MARK: - old implemintation with var isViewVisible: Bool

//protocol AlertManagerProtocol: ObservableObject {
//    var globalAlert: [String: [AlertData]] { get set }
//    var localAlerts: [String: [AlertData]] { get set }
//    var isHomeViewVisible: Bool { get set }
//    func showGlobalAlert(message: String, operationDescription: String)
//    func showLocalalAlert(message: String, forView view: String, operationDescription: String)
//    func resetFirstLocalAlert(forView view: String)
//    func resetFirstGlobalAlert()
//}
//
//struct AlertData: Identifiable, Equatable {
//    let id = UUID()
//    let message: String
//    let operationDescription: String
//
//    static func == (lhs: AlertData, rhs: AlertData) -> Bool {
//        return lhs.id == rhs.id
//    }
//}
//
//
//class AlertManager: AlertManagerProtocol {
//
//    static let shared = AlertManager()
//
//    @Published var globalAlert: [String: [AlertData]] = [:] {
//        didSet {
//            print("globalAlert - \(globalAlert)")
//        }
//    }
//
//    @Published var localAlerts: [String: [AlertData]] = [:] {
//        didSet {
//            print("localAlerts - \(localAlerts)")
//        }
//    }
//
//    @Published var isHomeViewVisible: Bool = false
//
//    @Published var isGalleryViewVisible: Bool = false
//
//    @Published var isAccountViewVisible: Bool = false
//
//    private var timer: Timer?
//
//        init() {
//            // Инициализация таймера для вызова showGlobalAlert каждую минуту
////            timer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
////                guard let self = self else { return }
////                self.showGlobalAlert(message: "This is a global alert.", operationDescription: "Periodic alert")
////            }
//            DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
//                self?.showLocalalAlert(message: "This is a test local alert.", forView: "HomeView", operationDescription: "Test")
//            }
////            timer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
////                guard let self = self else { return }
////                self.showLocalalAlert(message: "This is a test local alert.", forView: "HomeView", operationDescription: "Test")
////            }
//        }
//
//    func showGlobalAlert(message: String, operationDescription: String) {
//        let alert = AlertData(message: message, operationDescription: operationDescription)
//
//        if globalAlert["globalError"] == nil {
//            globalAlert["globalError"] = [alert]
//        } else {
//            globalAlert["globalError"]?.append(alert)
//        }
//    }
//
//    func showLocalalAlert(message: String, forView view: String, operationDescription: String) {
//
//        let alert = AlertData(message: message, operationDescription: operationDescription)
//
//        if localAlerts[view] == nil {
//            localAlerts[view] = [alert]
//        } else if !localAlerts[view]!.contains(where: { $0.operationDescription == operationDescription }) {
//            localAlerts[view]?.append(alert)
//        }
//    }
//
//    func resetFirstLocalAlert(forView view: String) {
//        if var alerts = localAlerts[view], !alerts.isEmpty {
//            alerts.removeFirst()
//            if alerts.isEmpty {
//                localAlerts[view] = nil
//            } else {
//                localAlerts[view] = alerts
//            }
//        }
//    }
//
//    func resetFirstGlobalAlert() {
//        if var alerts = globalAlert["globalError"], !alerts.isEmpty {
//            alerts.removeFirst()
//            if alerts.isEmpty {
//                globalAlert["globalError"] = nil
//            } else {
//                globalAlert["globalError"] = alerts
//            }
//        }
//    }
//}
//
//extension Notification.Name {
//    static let globalAlert = Notification.Name("globalAlert")
//}



// MARK: - new solution with func resetFirstLocalAlert -

//import Foundation
//import Combine
//
//protocol AlertManagerProtocol: ObservableObject {
//    var globalAlert: AlertData? { get set }
//    var localAlerts: [String: [AlertData]] { get set }
//    func showGlobalAlert(message: String, operationDescription: String)
//    func showLocalalAlert(message: String, forView view: String, operationDescription: String)
//    func resetGlobalAlert()
//    func resetLocalAlert(forView view: String)
//    func resetFirstLocalAlert(forView view: String)
//}
//
////struct AlertData: Identifiable {
////    let id = UUID()
////    let message: String
////    let operationDescription: String
////}
//
//struct AlertData: Identifiable, Equatable {
//    let id = UUID()
//    let message: String
//    let operationDescription: String
//
//    static func == (lhs: AlertData, rhs: AlertData) -> Bool {
//        return lhs.id == rhs.id
//    }
//}
//
//
//class AlertManager: AlertManagerProtocol {
//    static let shared = AlertManager()
//    
//    @Published var globalAlert: AlertData? {
//        didSet {
//            print("didSet globalAlert")
//        }
//    }
////    @Published
//    @Published var localAlerts: [String: [AlertData]] = [:] {
//        didSet {
//            print("didSet localAlerts")
//        }
//    }
//    
//    @Published var showLocalAlert:Bool = false
//    
//    func showGlobalAlert(message: String, operationDescription: String) {
//        let alert = AlertData(message: message, operationDescription: operationDescription)
//        globalAlert = alert
//        NotificationCenter.default.post(name: .globalAlert, object: alert)
//    }
//    
//    func showLocalalAlert(message: String, forView view: String, operationDescription: String) {
//        let sharedMessage = operationDescription + message
//        let alert = AlertData(message: sharedMessage, operationDescription: operationDescription)
//        if localAlerts[view] != nil {
//            localAlerts[view]?.append(alert)
//        } else {
//            localAlerts[view] = [alert]
//        }
//    }
//    
//    func resetGlobalAlert() {
//        globalAlert = nil
//    }
//    
//    func resetLocalAlert(forView view: String) {
//        localAlerts[view] = nil
//    }
//
//    func resetFirstLocalAlert(forView view: String) {
//        if var alerts = localAlerts[view], !alerts.isEmpty {
//            alerts.removeFirst()
//            if alerts.isEmpty {
//                print("localAlerts[view] = nil")
//                localAlerts[view] = nil
//            } else {
////                showLocalAlert = true
//                print("localAlerts[view] = alerts")
//                localAlerts[view] = alerts
//            }
//        }
//    }
//}
//
//extension Notification.Name {
//    static let globalAlert = Notification.Name("globalAlert")
//}



// MARK: - new solution with notification  - 
//import Foundation
//import Combine
//
//protocol AlertManagerProtocol: ObservableObject {
//    var globalAlert: AlertData? { get set }
//    var localAlerts: [String: AlertData] { get set }
//    func showGlobalAlert(message: String)
//    func showLocalalAlert(message: String, forView view: String)
//    func resetGlobalAlert()
//    func resetLocalAlert(forView view: String)
//}
//
//struct AlertData {
//    let message: String
//}
//
//class AlertManager: AlertManagerProtocol {
//    
//    static let shared = AlertManager()
//    
//    var globalAlert: AlertData? {
//        didSet {
//            print("didSet globalAlert")
//        }
//    }
//    @Published var localAlerts: [String: AlertData] = [:] {
//        didSet {
//            print("didSet localAlerts")
//        }
//    }
//    
//    func showGlobalAlert(message: String) {
//        globalAlert = AlertData(message: message)
//        NotificationCenter.default.post(name: .globalAlert, object: globalAlert)
//    }
//    
//    func showLocalalAlert(message: String, forView view: String) {
//        localAlerts[view] = AlertData(message: message)
//    }
//    
//    func resetGlobalAlert() {
//        globalAlert = nil
//    }
//    
//    func resetLocalAlert(forView view: String) {
//        localAlerts[view] = nil
//    }
//}
//
//extension Notification.Name {
//    static let globalAlert = Notification.Name("globalAlert")
//}



//    private init() {
//            DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
//                self?.showGlobalAlert(message: "Test Global Alert")
//            }
//    }




// MARK: - old solution -

//import Foundation
//import Combine
//
//protocol AlertManagerProtocol:ObservableObject {
//    var globalAlert:AlertData? { get set }
//    var localAlerts: [String:AlertData] { get set }
//    func showGlobalAlert(message:String)
//    func showLocalalAlert(message:String, forView view: String)
//    func resetGlobalAlert()
//    func resetLocalAlert(forView view: String)
//}
//
//struct AlertData {
//    let message:String
//}
//
//class AlertManager: AlertManagerProtocol {
//    
//    static let shared = AlertManager()
//    //    var isFlag:Bool = true
//    
//    private init() {}
//    
//    @Published var globalAlert: AlertData?
//    @Published var localAlerts: [String : AlertData] = [:] {
//        didSet {
//            print("didSet localAlerts")
//        }
//    }
//    
//    func showGlobalAlert(message: String) {
//        globalAlert = AlertData(message: message)
//    }
//    
//    func showLocalalAlert(message: String, forView view: String) {
//        localAlerts[view] = AlertData(message: message)
//        //        imitationOfRepeatCall()
//    }
//    
//    func resetGlobalAlert() {
//        globalAlert = nil
//    }
//    
//    /// если View  исчезает из памяти до того как отработает алерт мы должны вызвать func resetLocalAlert до его исчезнавения???
//    func resetLocalAlert(forView view: String) {
//        localAlerts[view] = nil
//    }
    
    //    func imitationOfRepeatCall() {
    //        if isFlag {
    //            DispatchQueue.main.asyncAfter(deadline: .now() + 4) { [weak self] in
    //                print("imitationOfRepeatCall")
    //                self?.isFlag.toggle()
    //                self?.showLocalalAlert(message: "imitationOfRepeatCall", forView: "Home")
    //
    //            }
    //        }
    //
    //    }
//}




