//
//  NetworkMonitor.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 28.04.25.
//

///на симуляторе! когда мы запускаем приложение с подключенным wifi в консоли мы видим isConnected - true когда мы отключаем wifi нам в консоль опять распечатывается isConnected - true а когда потом мы включаем wifi нам в консоль распечатывается isConnected - false и мы видим как появляется с анимацией наш NetworkStatusBanner? почему у нас такое поведение?
///Это поведение действительно может сбивать с толку, но подобные аномалии часто наблюдаются именно при тестировании на симуляторе. Фреймворк Network (и, в частности, NWPathMonitor) зависит от системных сигналов, которые в симуляторе могут обрабатываться иначе, чем на реальном устройстве.
///Сетевое окружение симулятора: Симулятор использует сетевое подключение хоста (вашего Mac), и изменения в конфигурации сети на хосте могут не корректно транслироваться в симулятор. Это может привести к тому, что обновление статуса происходит с запаздыванием или даже в неправильном порядке.
///Особенности NWPathMonitor: NWPathMonitor рассчитан на работу с реальными устройствами, где системные события подключения приходят в ожидаемом виде. В симуляторе многие сетевые изменения обрабатываются иначе, что иногда приводит к инверсии или неожиданным обновлениям свойства isConnected.


///Свойство hasStatus (только для симулятора): Это свойство отслеживает, было ли уже зафиксировано первое событие обновления. Если оно не было установлено, мы устанавливаем isConnected согласно path.status и задаем hasStatus = true. При последующих обновлениях симулятор переключает isConnected.toggle(), чтобы имитировать аномальное поведение NWPathMonitor в симуляторе.
///Блок #if targetEnvironment(simulator) В симуляторе используется альтернативная логика, описанная выше. На реальном устройстве всегда просто устанавливается значение isConnected в зависимости от path.status.
///Такой подход позволяет обойти некорректное поведение симулятора и добиться ожидаемого обновления isConnected, когда вы тестируете на устройстве или в симуляторе.


// MARK: - code for simulator

import Network
import SwiftUI

final class NetworkMonitor: ObservableObject {
    /// Публикуемое значение: true – подключение активно, false – отсутствует.
    @Published var isConnected: Bool = true {
        didSet {
            print("isConnected - \(isConnected)")
        }
    }

    private let monitor: NWPathMonitor
    private let queue = DispatchQueue.global(qos: .background)
    
    #if targetEnvironment(simulator)
    private var hasStatus: Bool = false
    #endif

    init() {
        monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { [weak self] path in
            // Обновляем состояние на главном потоке, чтобы избежать UI-ошибок
            DispatchQueue.main.async {
                guard let self = self else { return }
                #if targetEnvironment(simulator)
                if !self.hasStatus {
                    self.isConnected = (path.status == .satisfied)
                    self.hasStatus = true
                } else {
                    // Если уже получили первое значение, переключаем состояние для имитации
                    self.isConnected.toggle()
                }
                #else
                self.isConnected = (path.status == .satisfied)
                #endif
            }
        }
        monitor.start(queue: queue)
    }
    
    deinit {
        monitor.cancel()
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

