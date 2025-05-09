//
//  NetworkMonitor.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 28.04.25.
//

//isConnected == false
///Когда значение isConnected становится равным false, это означает, что на основании информации, полученной от NWPathMonitor, в данный момент устройство не имеет удовлетворительного сетевого соединения.
///1. Общее состояние сети: NWPathMonitor не различает конкретные типы соединений (Wi‑Fi, сотовые данные и т.д.). Оно выдаёт единое состояние подключения. Таким образом, если self.isConnected == false, то нет ни активного Wi‑Fi, ни работающего сотового соединения, ни альтернативного способа подключения к сети.
///2. Сценарии, при которых self.isConnected может стать false:
///Wi‑Fi отключён: Если устройство не подключено к Wi‑Fi (либо выключен модуль, либо сеть недоступна).
///Сотовые данные отключены или отсутствуют: Например, если в настройках отключена сотовая связь или устройство находится вне зоны покрытия.
///Включён авиарежим: При активном авиарежиме и отсутствие возможности подключения к сети через Wi‑Fi, соединение отсутствует.
///Проблемы с маршрутизацией/доступом: Если существуют какие-то проблемы на уровне сети (например, временные сбои или некорректная конфигурация сети), что приводит к тому, что система не может установить корректный сетевой путь (NWPath не удовлетворяет требованиям).
///Таким образом, значение self.isConnected == false говорит о том, что в настоящий момент отсутствует любой доступный способ подключения к сети, независимо от того, какой тип соединения потенциально мог бы обеспечить доступ к Интернету.

///на симуляторе! когда мы запускаем приложение с подключенным wifi в консоли мы видим isConnected - true когда мы отключаем wifi нам в консоль опять распечатывается isConnected - true а когда потом мы включаем wifi нам в консоль распечатывается isConnected - false и мы видим как появляется с анимацией наш NetworkStatusBanner? почему у нас такое поведение?
///Это поведение действительно может сбивать с толку, но подобные аномалии часто наблюдаются именно при тестировании на симуляторе. Фреймворк Network (и, в частности, NWPathMonitor) зависит от системных сигналов, которые в симуляторе могут обрабатываться иначе, чем на реальном устройстве.
///Сетевое окружение симулятора: Симулятор использует сетевое подключение хоста (вашего Mac), и изменения в конфигурации сети на хосте могут не корректно транслироваться в симулятор. Это может привести к тому, что обновление статуса происходит с запаздыванием или даже в неправильном порядке.
///Особенности NWPathMonitor: NWPathMonitor рассчитан на работу с реальными устройствами, где системные события подключения приходят в ожидаемом виде. В симуляторе многие сетевые изменения обрабатываются иначе, что иногда приводит к инверсии или неожиданным обновлениям свойства isConnected.


///Свойство hasStatus (только для симулятора): Это свойство отслеживает, было ли уже зафиксировано первое событие обновления. Если оно не было установлено, мы устанавливаем isConnected согласно path.status и задаем hasStatus = true. При последующих обновлениях симулятор переключает isConnected.toggle(), чтобы имитировать аномальное поведение NWPathMonitor в симуляторе.
///Блок #if targetEnvironment(simulator) В симуляторе используется альтернативная логика, описанная выше. На реальном устройстве всегда просто устанавливается значение isConnected в зависимости от path.status.
///Такой подход позволяет обойти некорректное поведение симулятора и добиться ожидаемого обновления isConnected, когда вы тестируете на устройстве или в симуляторе.


// сущности TemplateSwiftUIProjectApp + NetworkStatusBanner + NetworkMonitor
///выполняют слаженную работу кода по управлению состояния подключения к сети (то есть важно что бы .onChange(of: scenePhase) в каждой из сущностей выполнялись последовательно - он так и выполняется а так же есть приоритет выполнения корневые view/дочерние view)
///первый старт и отсутствие wifi : TemplateSwiftUIProjectApp - oldPhase: inactive, newPhase: active) - startMonitoring() - (isConnected - false + isSimulating - true) - NetworkStatusBanner - oldPhase: inactive, newPhase: active) - showBannerIfNeeded() - NetworkStatusBanner - isOldConnected: true, isNewConnected: false)
///если мы изменим порядок модификаторов в NetworkStatusBanner .onChange(of: networkMonitor.isConnected) - .onChange(of: scenePhase) то их вызов будет последовательный сверху вниз!
/// сначало вызываются модификаторы TemplateSwiftUIProjectApp а затем уже модификаторы его дочерний NetworkStatusBanner
/// если мы после первого старта выйдим из нашего app в стороннее app то сначало отработает .onChange для TemplateSwiftUIProjectApp (+отработают методы NetworkMonitor) а затем для NetworkStatusBanner - это то что нам нужно для слаженнной и правельной работы нашего кода!
/// важный момент : когда мы при первом старте isConnected - false выходим из нашего app в другой app а затем снова заходим
/// print стек в консоли: TemplateSwiftUIProjectApp - oldPhase: inactive, newPhase: active) + startMonitoring() + NetworkStatusBanner - oldPhase: inactive, newPhase: active)(если бы тут newPhase == .active && !networkMonitor.isConnected .. networkMonitor.isConnected не был бы false с прошлого раза то алерт бы мы не увидели? ) + showBannerIfNeeded() +  (isConnected - false isSimulating - true)
/// так как в  showBannerIfNeeded() у нас стоит guard showBanner == false else { return } то при многократном вызове showBannerIfNeeded() пока showBanner == false мы не вызовим анимации до тех пор пока текущая не закончит свою работу и не изменит showBanner с true на false

// стратегия использования в life cicle app and in the hierarchy views
///NetworkMonitor мониторит есть ли подключение к сети!
///если с самого первого старта ее нет нам на onboarding будет показан Alert. / затем при пеерходе на HomeView мы повторно его уже не увидим.
///если с первого старта сеть была то затем при ее исчезнавении в App мы увидем Alert на любой иерархии View кроме модальных окон(на GitHub так же) и больше не увидим!
///если мы выйдем из нашего App в другое App а затем снова вернемся в нашу App то при отсутствии сети снова сработает Alert.
///можно в ContentView().environmentObject(networkMonitor) и к примеру как на GitHub при переходе на определенную View в onApeare { networkMonitor.stopMonitoring() + networkMonitor.startMonitoring() } что бы инициировать новый показ Alert для пользователя.
///можно подумать о том что бы при первом срабатывании isConnected = false включался таймер для повторного инициирования Alert для пользователя. / можно добавлять NetworkStatusBanner().environmentObject(networkMonitor) в модальные View что бы отображать и там Alert

// MARK: - code for simulator

import Network
import SwiftUI

final class NetworkMonitor: ObservableObject {
    @Published var isConnected: Bool = true {
        didSet {
            print("isConnected - \(isConnected)")
        }
    }
    
    private var monitor: NWPathMonitor?
    private let queue = DispatchQueue.global(qos: .background)
    
    #if targetEnvironment(simulator)
    /// isSimulating проперти только для работы на симуляторе(убираем инвертное поведение)
    private var isSimulating: Bool = false {
        didSet {
            print("isSimulating - \(isSimulating)")
        }
    }
    #endif
    
    init() {
        // Мониторинг не запускаем автоматически, ждем команды от App
    }
    
    func startMonitoring() {
        print("startMonitoring()")
        guard monitor == nil else { return }
        
        monitor = NWPathMonitor()
        monitor?.pathUpdateHandler = { [weak self] path in
            // Обновляем состояние на главном потоке, чтобы избежать UI-ошибок
            DispatchQueue.main.async {
                guard let self = self else { return }
                #if targetEnvironment(simulator)
                if !self.isSimulating {
                    self.isConnected = (path.status == .satisfied)
                    self.isSimulating = true
                } else {
                    // Для симулятора переключаем значение, чтобы имитировать изменение статуса
                    self.isConnected.toggle()
                }
                #else
                self.isConnected = (path.status == .satisfied)
                #endif
            }
        }
        monitor?.start(queue: queue)
    }
    
    func stopMonitoring() {
        print("stopMonitoring()")
        monitor?.cancel()
        monitor = nil
        #if targetEnvironment(simulator)
        isSimulating = false
        #endif
    }
    
    deinit {
        stopMonitoring()
    }
}



// MARK: - code for real device

//final class NetworkMonitor: ObservableObject {
//    /// Публикуемое значение: true – подключение активно, false – отсутствует.
//    @Published var isConnected: Bool = true {
//        didSet {
//            print("isConnected - \(isConnected)")
//        }
//    }
//
//    private let monitor: NWPathMonitor
//    private let queue = DispatchQueue.global(qos: .background)
//    
//    init() {
//        monitor = NWPathMonitor()
//        monitor.pathUpdateHandler = { [weak self] path in
//            // Обновляем состояние на главном потоке, чтобы избежать UI-ошибок
//            DispatchQueue.main.async {
//                self?.isConnected = (path.status == .satisfied)
//            }
//        }
//        monitor.start(queue: queue)
//    }
//    
//    deinit {
//        monitor.cancel()
//    }
//}

