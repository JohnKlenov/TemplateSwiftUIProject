//
//  TemplateSwiftUIProjectApp.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 8.10.24.
//


// MARK: - iPad

///Начните с iPhone-версии Сначала доведите до ума на одном устройстве
///Код, написанный для iPhone, запустится на iPad без ошибок
///Но интерфейс может выглядеть неоптимально (как "увеличенный iPhone")
///Для профессионального приложения нужна дополнительная адаптация

// MARK: - Launch Screen

///на данный момент для реального launch screen в iOS требуется использовать именно LaunchScreen.storyboard. Это связано с тем, что система загружает этот файл раньше вашего кода, чтобы отобразить статичный экран до инициализации приложения, и Apple не предоставляет возможности задать его в SwiftUI.
///если ты не интегрируешь или не настроишь LaunchScreen.storyboard, то при запуске приложения после нажатия на иконку система покажет пользователю пустой (обычно чёрный или белый) экран до того, как загрузится и отобразится первый экран твоего приложения.
///Важно понимать, что экран запуска (Launch Screen) предназначен для того, чтобы скрыть задержку между нажатием иконки и появлением UI твоего приложения. Он создаётся на уровне конфигурации проекта через Storyboard (или XIB) и отображается до инициализации кода. Если его не будет, система по умолчанию использует пустой экран, что может негативно сказаться на восприятии приложения пользователем.

///В iOS экран запуска (Launch Screen) не создаётся программно внутри вашего SwiftUI‑приложения, как например ContentView. Вместо этого он задаётся на уровне конфигурации всего проекта. Вот что для этого нужно знать:
///LaunchScreen.storyboard При создании нового проекта Xcode автоматически генерирует файл LaunchScreen.storyboard. Именно этот файл используется системой для отображения статического экрана до того, как ваш код (точка входа, например, TemplateSwiftUIProjectApp) загрузится. Чтобы настроить дизайн экрана запуска, откройте файл LaunchScreen.storyboard и измените его содержимое по своему усмотрению (например, добавьте логотип, фон и т.д.).
///Настройки проекта (Info.plist)
///Запуск и поведение iOS загружает этот экран до и во время инициализации вашего приложения, чтобы обеспечить плавный переход от момента нажатия на иконку до загрузки вашего интерфейса. Из-за природы экрана запуска он должен быть максимально простым и статичным, без анимаций или динамического контента.
///Таким образом, в вашем коде на уровне TemplateSwiftUIProjectApp никаких изменений для отображения LaunchScreen делать не нужно — всё управление этим экраном происходит на уровне storyboard и файлов конфигурации.

//SplashView
///Если же вам требуется некий splash-эффект с анимацией, который появляется после LaunchScreen, но до основного контента приложения, лучшим решением будет создать дополнительное SwiftUI‑представление (например, SplashView), которое вы показываете сразу после запуска, а затем переходите к основному интерфейсу. Такой подход позволит добавлять анимации и динамические элементы, оставаясь при этом в рамках правил разработки под iOS.


// MARK: - Life Cicle Application

//⌘ + Shift + H
///симулятор предоставляет возможность перейти в режим App Switcher и проверить, как ваше приложение ведёт себя, когда оно уходит в фон или происходит переключение между приложениями.

//@Environment(\.scenePhase)

///В SwiftUI можно использовать как NotificationCenter, так и новый механизм отслеживания жизненного цикла приложения через среду (Environment). Например, SwiftUI предоставляет свойство scenePhase:
///Active (Активное): Приложение находится на переднем плане и активно взаимодействует с пользователем. Здесь выполняется вся анимация, обработка пользовательского ввода и обновление пользовательского интерфейса. Это оптимальное состояние для работы с ресурсами, так как приложение «на виду» и должно работать максимально откликается. Обновление данных: При переходе в активное состояние (active) можно инициировать обновление контента или возобновление отложенных операций, чтобы пользователь видел актуальную информацию.
///Inactive (Неактивное): Это переходное или временное состояние, когда приложение временно теряет фокус (например, во время входящего звонка, появления системных уведомлений или короткого перехода между активными состояниями). Здесь приложение не обрабатывает пользовательский ввод, а многие задачи приостанавливаются. Можно воспринимать это как «задержку» перед полноценным переходом в фон или обратно в активное состояние. Приостановка задач: При событии перехода в состояние inactive или background можно приостановить «тяжёлые» задачи, такие как анимации или интенсивные вычисления, чтобы освободить ресурсы.
///Background (Фоновое): Приложение работает в фоновом режиме, то есть оно не находится на переднем плане и визуально не доступно пользователю, но может продолжать выполнять ограниченные задачи (например, сохранять данные, обновлять содержимое, завершать уже начатые операции). Здесь система накладывает ограничения на использование ресурсов, поэтому интенсивные операции или обновление интерфейса не проводятся. Сохранение состояния и данных: При переходе в фон (background) можно сохранять текущее состояние приложения, например, данные формы или прогресс загрузки, чтобы при возвращении пользователю всё восстановилось без потерь.
///В iOS нет "магического" уведомления, которое гарантированно сообщило бы вашему приложению, что оно вот-вот будет выгружено (терминировано) из памяти.
///Переход в фон и сохранение состояния: Лучший способ "подготовиться" к возможной выгрузке из памяти – это сохранять критичные данные и состояние во время перехода в фон (например, в методе scenePhase актуального SwiftUI или в applicationDidEnterBackground у делегата). Так, если система в какой‑то момент решит выгрузить приложение, восстановление состояния произойдёт при следующем запуске, даже если вы не получили явного уведомления о завершении работы.
///Метод делегата applicationWillTerminate: Если ваше приложение работает в активном состоянии (на переднем плане) и затем закрывается (например, пользователь вручную завершает работу приложения через App Switcher или система осуществляет корректное завершение), то вызывается метод applicationWillTerminate в UIApplicationDelegate. Однако этот метод вызывается не во всех случаях. Если приложение уже находится в фоне (и заморожено системой) и затем выгружается для освобождения памяти, этот метод не гарантируется.


//NotificationCenter.default.publisher(...):

///Даже если вы не используете классический UIApplicationDelegate в SwiftUI, можно отслеживать многие события жизненного цикла приложения через уведомления NotificationCenter или через новые возможности самого SwiftUI.

///UIApplication.didEnterBackgroundNotification Отправляется, когда приложение переходит в фон. Это удобно для сохранения данных или освобождения ресурсов.
///UIApplication.willEnterForegroundNotification Отправляется, когда приложение собирается выйти из фонового режима и вернуться на передний план, что позволяет обновить интерфейс или данные.
///UIApplication.didBecomeActiveNotification Отправляется, когда приложение становится активным. Здесь можно возобновить паузенные задачи или обновить информацию.
///UIApplication.willResignActiveNotification Отправляется, когда приложение переходит в состояние неактивности (например, при входящем звонке или при переходе в меню), что может быть полезно для временной остановки обработки.
///Помимо этого, можно подписаться на такие уведомления, как изменения ориентации устройства (например, UIDevice.orientationDidChangeNotification).


// MARK: - something else
/// Когда ты передаешь объект managerCRUDS в ContentView с помощью .environmentObject(managerCRUDS), этот объект становится доступным для всех дочерних представлений, которые используют @EnvironmentObject.
/// в struct нам не нужно передавать зависимость через конструктор просто используем @EnvironmentObject var managerCRUDS: CRUDSManager а в классах нужно передавать через конструктор - HomeViewModel(authenticationService: authenticationService, firestorColletionObserverService: firestoreCollectionObserver, managerCRUDS: managerCRUDS, errorHandler: errorHandler)


// MARK: -  .receive(on: RunLoop.main) ???? обновление UI должно быть везде на главном потоке!!!! -
// MARK: - проверить всех подписчиков на утечку памяти profileLoadCancellable?.cancel() (CombineSetting почитать тут)



import SwiftUI
import UIKit

@main
struct TemplateSwiftUIProjectApp: App {

    // MARK: UIKit hooks
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    // MARK: – Persistent flags
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    // MARK: – Global services
    @StateObject private var localizationService = LocalizationService.shared
    @StateObject private var retryHandler        = GlobalRetryHandler()
    @StateObject private var networkMonitor      = NetworkMonitor()
    @StateObject private var orientationService  = DeviceOrientationService()
    @StateObject private var viewBuilderService = ViewBuilderService()
//    @StateObject private var authorizationManager = AuthorizationManager(service: AuthorizationService())

    // MARK: – Scene phase
    @Environment(\.scenePhase) private var scenePhase

    // MARK: – init (DEBUG helpers)
    init() {
        #if DEBUG
        UserDefaults.standard.removeObject(forKey: "hasSeenOnboarding")
        ImageCacheManager.shared.deleteOldFiles()
        #endif
    }

    // MARK: – Body
    var body: some Scene {
        WindowGroup {
            AppRootView(hasSeenOnboarding: hasSeenOnboarding)
//                .environmentObject(authorizationManager)
                .environmentObject(localizationService)
                .environmentObject(retryHandler)
                .environmentObject(networkMonitor)
                .environmentObject(orientationService)
                .environmentObject(viewBuilderService)
                .environment(\.sizeCategory, .medium)
                .onChange(of: scenePhase) { oldPhase, newPhase in
                    //            print("TemplateSwiftUIProjectApp - oldPhase: \(oldPhase), newPhase: \(newPhase))")
                    handleScenePhase(oldPhase)
                }
        }
    }
}

// ──────────────────────────────────────────────────────────────
// MARK: - Root View
// ──────────────────────────────────────────────────────────────

private struct AppRootView: View {

    let hasSeenOnboarding: Bool

    @EnvironmentObject private var networkMonitor: NetworkMonitor
    @EnvironmentObject private var orientationService: DeviceOrientationService

    var body: some View {
        GeometryReader { windowGeo in
            ZStack {                               // Один контейнер для всего
//                RootSizeReader()
                mainContent
                
                // Banner
                VStack {
                    Spacer()
                    NetworkStatusBanner()
                        .environmentObject(networkMonitor)
                        .padding(.bottom, Self.bottomPadding(for: windowGeo))
                }
            }
            .onAppear {
                UIDevice.current.beginGeneratingDeviceOrientationNotifications()
            }
            .onDisappear {
                UIDevice.current.endGeneratingDeviceOrientationNotifications()
            }
        }
    }

    // MARK: helpers
    ///ContentView().id("ContentView")  - Гарантированно один экземпляр
    ///ContentView().id("ContentView") - SwiftUI использует идентификатор для определения, нужно ли пересоздавать View или можно обойтись перерисовкой существующей.
    @ViewBuilder
    private var mainContent: some View {
        if hasSeenOnboarding {
            ContentView().id("ContentView")
        } else {
            OnboardingView().id("Onboarding")
        }
    }

    private static func bottomPadding(for geo: GeometryProxy) -> CGFloat {
        let inset = geo.safeAreaInsets.bottom
        return inset == 0 ? 64 : inset + 30        // 64 для устройств c кнопкой, иначе 30-pt над home-indicator
    }
}

// ──────────────────────────────────────────────────────────────
// MARK: - Scene-phase logic
// ──────────────────────────────────────────────────────────────

private extension TemplateSwiftUIProjectApp {

    func handleScenePhase(_ phase: ScenePhase) {
        #if targetEnvironment(simulator)
        // Симулятор ведёт себя “зеркально”, поэтому меняем логику
        switch phase {
        case .active:      networkMonitor.stopMonitoring()
        case .inactive,
             .background:  networkMonitor.startMonitoring()
        default:           break
        }
        #else
        switch phase {
        case .active:      networkMonitor.startMonitoring()
        case .inactive,
             .background:  networkMonitor.stopMonitoring()
        default:           break
        }
        #endif
    }
}




















//    geometry.size - (393.0, 759.0)
//                        .modifier(DeviceOrientationModifier())
//                        .modifier(DeviceOrientationModifier(orientationService: orientationService))

//                        .readRootSize { size in
//                            orientationService.updateContainerSize(size)
//                        }



// MARK: - first version

//import SwiftUI
//import UIKit
//
//@main
//struct TemplateSwiftUIProjectApp: App {
//    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
//    @AppStorage("hasSeenOnboarding") var tiedOnboarding: Bool = false
//    
//    @StateObject private var localizationService = LocalizationService.shared
//    @StateObject private var retryHandler = GlobalRetryHandler()
//    @StateObject private var networkMonitor = NetworkMonitor()
//    @StateObject private var orientationService = DeviceOrientationService()
//    @Environment(\.scenePhase) private var scenePhase
//    
//    init() {
//#if DEBUG
//        UserDefaults.standard.removeObject(forKey: "hasSeenOnboarding")
//        self.setupCache()
//#endif
//    }
//    
//    var body: some Scene {
//        WindowGroup {
//                Group {
//                    if tiedOnboarding {
//                        ContentView()
//                            .environmentObject(retryHandler)
//                            .environmentObject(localizationService)
//                            .environmentObject(orientationService)
//                            .readRootSize { size in            // теперь вернётся 393 × 852
//                                    orientationService.updateContainerSize(size)
//                                }
//                            .onAppear {
//                                // Активируем генерацию уведомлений
//                                UIDevice.current.beginGeneratingDeviceOrientationNotifications()
//                            }
//                            .onDisappear {
//                                UIDevice.current.endGeneratingDeviceOrientationNotifications()
//                            }
//                    } else {
//                        OnboardingView()
//                    }
//                }
//                .environment(\.sizeCategory, .medium)
//                .overlay {
//                    GeometryReader { geometry in
//                        VStack {
//                            Spacer()
//                            NetworkStatusBanner()
//                                .environmentObject(networkMonitor)
//                                .environmentObject(localizationService)
//                            //                        dynamic .padding
//                            //                        geometry.safeAreaInsets.bottom: динамически рассчитывает безопасный отступ внизу (например, на iPhone с Face ID это 34 pt от самого низа экрана до конца нижней safeArea)
//                            //                        iPhone с кнопкой "Домой" (например, iPhone SE, 8) → safeAreaInsets.bottom = 0.
//                            //                        Отсчёт высоты TabBar (49 pt) начинается с самой нижней точки экрана, а не от safeAreaInsets.bottom.
//                            //                        поэтому если safeAreaInsets.bottom == 0 то высоту 49 + 5 иначе 34 + 20 / можно сделать 10/15 пунктов вместо 5 для надежнности (59 : 25, 64:30)
//                                .padding(.bottom, geometry.safeAreaInsets.bottom == 0 ? 64 : geometry.safeAreaInsets.bottom + 30)
//                        }
//                    }
//                }
//        }
////        так как при работе с симулятором у нас инвертное поведение мы в handleScenePhaseChange(oldPhase) передаем oldPhase
////        на реальном устройстве мы должны передавать handleScenePhaseChange(newPhase)
////        first scenePhase: TemplateSwiftUIProjectApp - oldPhase: inactive, newPhase: active)
////        change  scenePhase: TemplateSwiftUIProjectApp - oldPhase: active, newPhase: inactive)
////        поэтому если мы передаем в handleScenePhaseChange(newPhase) при первом старте мы имеем networkMonitor.stopMonitoring()
//        .onChange(of: scenePhase) { oldPhase, newPhase in
////            print("TemplateSwiftUIProjectApp - oldPhase: \(oldPhase), newPhase: \(newPhase))")
//            handleScenePhaseChange(oldPhase)
//        }
//    }
//    
//    private func setupCache() {
//        ImageCacheManager.shared.deleteOldFiles()
//    }
//    
//    private func handleScenePhaseChange(_ oldPhase: ScenePhase) {
//        #if targetEnvironment(simulator)
//        switch oldPhase {
//        case .active:
//            networkMonitor.stopMonitoring()
//        case .inactive, .background:
//            networkMonitor.startMonitoring()
//        @unknown default:
//            break
//        }
//        #else
//        switch oldPhase {
//        case .active:
//            networkMonitor.startMonitoring()
//        case .inactive, .background:
//            networkMonitor.stopMonitoring()
//        @unknown default:
//            break
//        }
//        #endif
//    }
//}




