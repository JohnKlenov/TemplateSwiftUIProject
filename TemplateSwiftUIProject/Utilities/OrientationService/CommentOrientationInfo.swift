//
//  CommentOrientationInfo.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 3.06.25.
//


// MARK: UIDevice.orientation + GeometryReader

///UIDevice.current.orientation относится именно к физической ориентации устройства, а не к ориентации интерфейса.
///Если устройство заблокировано в портретном режиме, но повернуто в ландшафт, UIDevice.current.orientation.isLandscape может все равно вернуть true, хотя сам интерфейс останется в портретном положении.
///Для правильной адаптации UI лучше использовать Size Classes или GeometryReader, чтобы определить фактические размеры доступного пространства.

//UIInterfaceOrientation (из UIApplication.shared.statusBarOrientation)
///UIInterfaceOrientation — это устаревшее API в UIKit, которое используется для определения текущей ориентации интерфейса. В современных приложениях лучше использовать UIDevice.orientation или windowScene.interfaceOrientation
///Определяет ориентацию пользовательского интерфейса, т.е. как приложение отображает контент.
///Если приложение запретило смену ориентации
///(supportedInterfaceOrientations ограничены только портретом), то интерфейс останется в портретном режиме, даже если устройство физически повернуто в landscape.

//Фактический layout интерфейса (через PreferenceKey, GeometryReader)
///Если ориентация приложения заблокирована (например, только портретная компоновка), то размеры контейнера не изменятся даже при физическом повороте устройства.
///если контент заблокирован и не вращается, то вариант на основе измерения контейнера (GeometryReader с PreferenceKey) будет отражать актуальные размеры UI, потому что они будут зафиксированы в выбранной ориентации.

//Как запретить изменение ориентации на устройстве
///Настройка в Info.plist: Задайте поддерживаемые ориентации для вашего приложения. Например, чтобы разрешить только портрет, в Info.plist  добавьте ключ UISupportedInterfaceOrientations со значением UIInterfaceOrientationPortrait (а для iPad – при необходимости, либо отдельно определить портретные ориентации).
///Переопределение поведения контроллера: Если вам нужно программно запретить авто-поворот, можно в вашем UIViewController
///Для SwiftUI: Хотя SwiftUI напрямую не предоставляет API для блокировки ориентации, обычно это делается через настройку Info.plist  или через UIKit-обёртку в AppDelegate/SceneDelegate.

///Если вы запрещаете поворот UI, то для определения текущего интерфейсного состояния используйте измерение контейнера (GeometryReader / PreferenceKey), так как реальный размер экрана для UI не меняется.
///Объединённый сервис, который выбирает источник в зависимости от устройства, может, например, для iPad полагаться на размеры контейнера, а для iPhone – на системные уведомления. Но учтите, если вы блокируете ротейшн в обоих случаях (через Info.plist  или переопределяя shouldAutorotate), то размеры контейнера всегда будут соответствовать зафиксированной ориентации, а системные уведомления могут всё равно меняться, отражая только физическое положение устройства, а не интерфейс.


//Когда точно нужен GeometryReader (iPad):
///Если приложение поддерживает iPad
///Если нужна поддержка Split View/Slide Over
///Если есть кастомные контроллеры представления
///Если важна точность при запрете ориентаций

///Для простого iPhone-приложения можно использовать только UIDevice.orientation, но для production-решения лучше комбинированный подход.

//Когда достаточно только UIDevice.orientation:
///Приложение только для iPhone
///На iPad заблокированы все ориентации кроме портретной
///Не требуется поддержка Split View или Slide Over


// MARK: SizeClasses

///Size Classes — это механизм UIKit, который помогает адаптировать пользовательский интерфейс под разные размеры экрана. В SwiftUI они также играют ключевую роль в адаптивном UI-дизайне.
///Size Classes работают на двух осях: Horizontal Size Class (горизонтальная), Vertical Size Class (вертикальная)
///Каждая ось может иметь два состояния: Regular — много пространства для контента, Compact — ограниченное пространство
///Примеры:
///iPad всегда имеет Regular в обоих направлениях. (Split View  и  Slide Over ведут себя немного иначе)
///Обычные iPhone (не Plus/Max) в портретном режиме → wC hR в Landscape (горизонтально) - wC hC
///Pro Max и Plus → Portrait (вертикально) - wC hR Landscape (горизонтально) - wR hC (широкий режим)

///iPad Size Classes
///Size Classes (horizontalSizeClass и verticalSizeClass) на iPad более гибкие, чем на iPhone, из-за поддержки Split View, Slide Over и Stage Manager.
///Режим iPad                      horizontalSizeClass                                       verticalSizeClass   Комментарий

///Full Screen (Portrait)   .     regular                                                            .regular                  Обычный портретный режим
///Full Screen (Landscape)   regular                                                             regular                  Обычный ландшафтный режим
///Split View (50/50)  .           regular                                                             regular                  Обе части получают Regular
///Split View (70/30)  .           .regular (основная) / .compact (вторая)        regular                  Зависит от размера
///Slide Over  .                      compact                                                            regular                 Компактный режим
///Stage Manager (окно)  .   Зависит от размера окна (может быть .compact или .regular)

///В SwiftUI можно использовать @Environment(\.horizontalSizeClass), чтобы менять UI динамически
///Вывод Size Classes дают гибкость в проектировании UI, особенно для iPad и больших iPhone. Они помогают создавать адаптивные приложения без привязки к конкретным моделям устройств.




// MARK: - Что за звери ‑ Split View, Slide Over, Stage Manager?
///Любое iPad-приложение может запретить любой режим в режим в Info.plist.

///Split View    Экран делится на два окна (треки 50/50, 70/30, 30/70). Можно Одновременно держать два полноценных приложения.    Каждое приложение получает своё UIWindowScene; его фрейм динамически меняется, когда пользователь перетягивает разделитель.
///Можно ли менять размер окон руками? Да! В Split View есть перетягиваемый разделитель, которым можно регулировать ширину каждого приложения.
///Что происходит при переходе из портрета в ландшафт? Оба приложения разворачиваются шире, но их относительные размеры сохраняются. Если в портрете было 70/30, в ландшафте останется тот же баланс ширины.UIKit не считает это новой ориентацией, а просто раздвигает окна.
///Что показывает UIDevice при изменении Split View? UIDevice.current.orientation  остаётся тем же! Например, если iPad физически в портретном положении, UIDevice.orientation == .portrait, даже если приложение стало узким. Вот почему в Split View нельзя ориентироваться только на UIDevice.orientation — ведь UI реально изменился, а UIDevice говорит, что всё как раньше.
///DeviceOrientationService смотрит размер окна через GeometryReader. Даже если физическая ориентация не поменялась, UI адаптируется по реальной ширине.

///Slide Over
///В классическом Slide Over сервис особо не нужен, потому что:
///Окно всегда остаётся одним и тем же размером (≈ 507 × 1024 pt).
///Этот размер не меняется, но если пользователь переместит приложение в Split View, тогда ширина изменится → вот где DeviceOrientationService снова пригодится.
///UIDevice.orientation не влияет на Slide Over — оно «парит» поверх основного UI.
///Нет изменений ширины/высоты, как в Split View или Stage Manager.
///
///Узкое плавающее окошко, гордо «парит» поверх основного приложения, прячется сбоку свайпом.    Быстро чек-нуть мессенджер или заметки, не покидая текущее приложение.    Ваше приложение остаётся на паузе на заднем плане; Slide Over-приложение получает фокус, но размер вашего окна не меняется.
///Можно ли менять размер окна руками? Нет, в Slide Over размер окна фиксирован.Оно может быть перемещено влево или вправо, а также свернуто свайпом, но его размеры остаются неизменными.
///Как ведёт себя приложение при переходе из портрета в ландшафт?
///Если iPad переходит в ландшафт, основное приложение растягивается шире, но окно Slide Over остаётся таким же. Его позиция может измениться, но размер — нет. Slide Over всегда остаётся узким, даже если основное приложение полностью развернулось.
///Что показывает UIDevice при изменении Slide Over?
///UIDevice.current.orientation отражает положение iPad, а не Slide Over.
///Размер основного окна не меняется, потому что Slide Over — только дополнительное плавающее окно.
///Вывод: Slide Over не требует специальных обработок в DeviceOrientationService, но если оно закрывает часть основного UI, можно добавить логику, скрывающую элементы при активном Slide Over.
///Да! Любое iPad-приложение может быть открыто в Slide Over, если оно не запрещает этот режим в Info.plist. 📌 Проверь в UISupportedInterfaceOrientations, чтобы убедиться, что твое приложение не блокирует Slide Over.

///Stage Manager (iPadOS 16+)    это многозадачность нового уровня, которая появилась в iPadOS 16 и делает iPad похожим на полноценную настольную систему.
///Позволяет открывать несколько окон одновременно и свободно менять их размеры.
///Окна можно переключать, перетягивать, группировать в «виртуальные рабочие пространства».
///Работает как на самом iPad, так и при подключении внешнего монитора (там можно открыть до 6 окон!).
///Размер окна не фиксирован! В отличие от Split View, пользователь может тянуть любой угол окна, и приложение должно подстраиваться.
///UIScreen.main.bounds больше не даёт реальный размер окна — нужно использовать GeometryReader.
///Окно может быть на внешнем дисплее — и тогда его фрейм будет совсем другим.



// MARK: - bug
//Почему при показе sheet/модалки GeometryReader внезапно отдаёт 361 × 782 pt вместо 393 × 852 pt
///Когда .sheet появляется, UIKit: создаёт дочернее окно, в котором живёт сам лист; сжимает/отодвигает presenting-контроллер (ваш WindowGroup) — добавляет горизонтальные отступы ≈16 pt с каждой стороны и поднимает его вверх, чтобы за листом было видно «слой фона». Именно поэтому GeometryReader, прикреплённый к «старому» представлению, вдруг видит размер 361 × 782,6 pt (393 − 32 и 852 − ≈70).
///Используйте onChange(UIScreen.main.bounds.size) на iPhone можно, На iPad передавайте geo.size, но игнорируйте небольшие скачки от модалки.

//На iPhone тоже может меняться размер (Split View в landscape)
///Улучшение: Для iPhone тоже можно использовать containerSize




// MARK: - the salt of the DeviceOrientationService work

//Точное определение ориентации - Позволяет различать portrait/landscape/square

///Единая «точка правды»  - больше не нужно дергать UIDevice, GeometryReader на каждом экране.
///Гибридная логика iPhone / iPad Для iPhone сервис ориентируется на физический поворот или UIScreen.main.bounds, а для iPad он учитывает размер окна, что позволяет правильно адаптироваться к Split-View и Stage Manager. На телефоне окно всегда full-screen, на iPad может стать 2/3, 1/2, 1/3 экрана.
///Фильтрация шумов (debounce, nonzeroBitCount, проверка isRotationLocked) - Не срабатывает от модалок, клавиатуры, маленьких safe-area рывков.
///KVO-friendly (@Published var orientation) — обновления приходят реактивно во все подписанные вью.   Просто кладёте .environmentObject(orientationService) и пишете @EnvironmentObject var orientationService в любом экране.

//Куда реально применяют в «боевых» проектах
///1. Переключать layout списка/галереи     swift if orientationService.orientation == .landscape { GridView() } else { ListView() }
///2. Менять размеры/расположение элементов (ваша кнопка 300 pt)    swift .frame(maxWidth: orientationService.orientation == .landscape ? 300 : .infinity)
///3. Убирать/добавлять боковую панель на iPad    swift if orientationService.isLandscape { Sidebar() }
///4. Переключать toolBar/tabBar снизу → справа в landscape    .toolbarPlacement(orientationService.isLandscape ? .navigationBarTrailing : .bottomBar)
///5. Подгонять анимации, адаптировать GeometryReader-вычисления    При смене .orientation пересчитываем aspectRatio, выравнивания.
///6. Видеоплеер / камера — переход на full-screen landscape, даже если UI лок.    При .landscape → открываем VideoPlayerFullScreenView.

//Рекомендации для продакшена
/// Дебаунс 50–100 мс на iPad-resize, чтобы не триггерить каскадный Layout при live-перетягивании границы Split-View.
/// Тестируйте: • iPhone SE (без safe-area снизу), • iPhone 15 Pro (Dynamic Island), • iPad Split-View 1/3-2/3-full, • Stage Manager с произвольным окном.

//Bottom line(итог)
///DeviceOrientationService — это тонкая обёртка, которая превращает «хаотичные» системные нотификации (UIDevice, window-resize) в упорядоченный, реактивный сигнал.
///Она особенно полезна, когда:
///у приложения два радикально разных лэйаута (портрет/ландшафт)
///надо поддерживать iPad Split-View и Stage Manager
///хочется, чтобы весь UI «знал» о смене ориентации, не подписываясь на десяток NotificationCenter-каналов.

//Будут ли лаги?
///@Published var orientation обновляется, каждое подписанное View получает новый рендер. Если таких подписчиков много (например, 10+ экранов), то да, возможны излишние обновления, но они не обязательно приведут к проблемам с производительностью.
///SwiftUI оптимизирован для таких случаев, но есть нюансы: ✅ Если вью не на экране (например, спрятан TabView), SwiftUI не будет их перерисовывать. ❌ Если подписано 10–15 сложных вью, каждая с onChange / task, могут появиться лишние вычисления. ❌ Если часть подписчиков — тяжелые гриды/списки, перерасчёты могут занять больше времени.
///✅ Если подписчиков до 10 обычных View, проблем не будет. ✅ Если много подписанных сложных списков, гридов, лучше добавить debounce. ✅ SwiftUI не перерисовывает спрятанные вью, так что табы и модальные экраны не нагружают систему. ✅ При экстремальных нагрузках можно перейти к ручному управлению Combine (CurrentValueSubject).
///Но в реальном приложении с 10-15 подписчиками обычно всё будет хорошо, если не перегружать их тяжелыми вычислениями.
///Если в NavigationStack есть 10 экранов с @EnvironmentObject var orientationService, и происходит изменение orientationService.orientation, перерисуется только тот экран, который видим в данный момент.
///SwiftUI умно управляет рендерингом, и скрытые экраны не получают обновление сразу. Только активное View получает обновление. Когда пользователь возвращается на экран, который раньше был скрыт, он получит актуальное значение orientationService.orientation.





// MARK: - Unified Orientation Service

//import SwiftUI
//import UIKit
//import Combine
//
//
//// MARK: - View
//
////WindowGroup { AppRootView(hasSeenOnboarding: hasSeenOnboarding).environmentObject(orientationService).readRootSize { size in orientationService.updateContainerSize(size) } }
//
///// Сервис, объединяющий данные о физической ориентации (для iPhone)
///// и информацию о размере контейнера (для iPad), чтобы определить текущую ориентацию.
//class DeviceOrientationService: ObservableObject {
//    enum Orientation: String {
//        case portrait
//        case landscape
//        case square
//    }
//    
//    /// Публикуемое свойство, на которое подписаны вью для обновления UI
//    @Published private(set) var orientation: Orientation = .portrait {
//        didSet {
//            print("orientation - \(orientation)")
//        }
//    }
//    
//    /// Последний размер контейнера (используется для iPad)
//    private var containerSize: CGSize = .zero
//    
//    private var cancellables = Set<AnyCancellable>()
//    
//    /// Предмет для дебаунсирования обновлений контейнерного размера (для iPad)
//    private let containerSizeSubject = PassthroughSubject<CGSize, Never>()
//    
//    /// Порог, по которому считаем, что размеры почти равны (для "square")
//    private let squareThreshold: CGFloat = 50
//    
//    init() {
//        // Если устройство — iPhone, подписываемся на системные уведомления изменения ориентации.
//        if UIDevice.current.userInterfaceIdiom == .phone {
//            //updateOrientationForiPhone() // Первоначальное определение (но нет смысла при первом старте в landscape отрабатывает NotificationCenter.default.publisher )
//            NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)
//                .sink { [weak self] _ in
//                    self?.updateOrientationForiPhone()
//                }
//                .store(in: &cancellables)
//        }
//        
//        // Для iPad обновления контейнерного размера обрабатываем с дебаунсом,
//        // чтобы снизить частоту обновлений при быстром изменении размеров.
//        if UIDevice.current.userInterfaceIdiom == .pad {
//            containerSizeSubject
//                .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
//                .sink { [weak self] size in
//                    self?.containerSize = size
//                    self?.updateOrientationForiPad()
//                }
//                .store(in: &cancellables)
//        }
//    }
//    
//    /// Метод, который должен вызываться (например, через GeometryReader)
//    /// для обновления размера контейнера (работает только на iPad)
//    func updateContainerSize(_ size: CGSize) {
//        print("geometry.size - \(size)")
//        if UIDevice.current.userInterfaceIdiom == .pad {
//            containerSizeSubject.send(size)
//        }
//    }
//    
//    // MARK: - Orientation Update Methods
//    
//    /// Определение, заблокирован ли поворот экрана.
//    /// Здесь мы полагаемся на supportedInterfaceOrientations (определённые в Info.plist или контроллере).
//    /// Info.plist (UISupportedInterfaceOrientations*) ‒ базовые правила для приложения.
//    /// application(_:supportedInterfaceOrientationsFor:) в AppDelegate (если переопределили).
//    /// UIWindow.rootViewController → активный верхний UIViewController (или представленный модально) со своим supportedInterfaceOrientations.
//    /// То есть isRotationLocked не привязан строго к Info.plist: он отражает текущее состояние окна. Вы контролируете это состояниe либо статично (Info.plist), либо динамически (разные VC + setNeedsUpdateOfSupportedInterfaceOrientations()).
//    private var isRotationLocked: Bool {
//        UIApplication.shared.supportedInterfaceOrientations(for: nil) == .portrait
//    }
//private var isRotationLocked: Bool {
//    let supportedOrientations = UIApplication.shared.supportedInterfaceOrientations(for: nil)
//    return supportedOrientations == .portrait || supportedOrientations.isSubset(of: .portrait)
//}
//
//    
//    /// Обновление ориентации для iPhone.
//    /// При заблокированном повороте всегда возвращает portrait,
//    /// иначе — учитывается физическая ориентация устройства.
//    /// если оринтация .portraitUpsideDown то deviceOrientation.isLandscape вернет .portrait
//    /// но UI роспалагается как будто это ландшавт но в перевернутом portret - поэтому мы его переопределили
//    
//    //    private func updateOrientationForiPhone() {
//    //        let newOrientation: Orientation
//    //
//    //        if isRotationLocked {
//    //            newOrientation = .portrait
//    //        } else {
//    //            let deviceOrientation = UIDevice.current.orientation
//    //            if deviceOrientation.isValidInterfaceOrientation {
//    //                newOrientation = deviceOrientation.isLandscape ? .landscape : .portrait
//    //            } else {
//    //                newOrientation = .portrait
//    //            }
//    //        }
//    //
//    //        DispatchQueue.main.async { [weak self] in
//    //            guard let self = self, self.orientation != newOrientation else { return }
//    //            self.orientation = newOrientation
//    //        }
//    //    }
//    private func updateOrientationForiPhone() {
//        let newOrientation: Orientation
//        
//        if isRotationLocked {
//            newOrientation = .portrait
//        } else {
//            let deviceOrientation = UIDevice.current.orientation
//            if deviceOrientation.isValidInterfaceOrientation {
//                switch deviceOrientation {
//                case .landscapeLeft, .landscapeRight, .portraitUpsideDown:
//                    newOrientation = .landscape
//                case .portrait:
//                    newOrientation = .portrait
//                default:
//                    newOrientation = .portrait
//                }
//            } else {
//                newOrientation = .portrait
//            }
//        }
//
//        DispatchQueue.main.async { [weak self] in
//            guard let self = self, self.orientation != newOrientation else { return }
//            self.orientation = newOrientation
//        }
//    }
//
//    
//    /// Обновление ориентации для iPad на основе размера контейнера.
//    /// Если разница между шириной и высотой меньше порогового значения — считаем, что
//    /// приложение находится в "square" режиме (например, Split View или Stage Manager).
//    private func updateOrientationForiPad() {
//        let width = containerSize.width
//        let height = containerSize.height
//        let newOrientation: Orientation
//        
//        if abs(width - height) < squareThreshold {
//            newOrientation = .square
//        } else {
//            newOrientation = width > height ? .landscape : .portrait
//        }
//        
//        DispatchQueue.main.async { [weak self] in
//            guard let self = self, self.orientation != newOrientation else { return }
//            self.orientation = newOrientation
//        }
//    }
//    
//    deinit {
//        cancellables.forEach { $0.cancel() }
//    }
//}
//
//// Вспомогательное расширение для проверки допустимой ориентации устройства.
/////Проверить, что текущая ориентация устройства относится к "действительным" для интерфейса, то есть к тем, которые обычно используются для компоновки UI: .portrait, .portraitUpsideDown, .landscapeLeft и .landscapeRight.
/////Почему это нужно: Когда вы запрашиваете текущую ориентацию через UIDevice.current.orientation, система может вернуть и другие значения, например, .faceUp, .faceDown или .unknown, которые не подходят для корректного размещения элементов интерфейса. Это расширение фильтрует такие состояния, гарантируя, что используются только те ориентации, которые реально влияют на расположение интерфейса.
/////Свойство isValidInterfaceOrientation возвращает true, если значение UIDeviceOrientation равно одному из «валидных» вариантов. Иначе — false.
//extension UIDeviceOrientation {
//    var isValidInterfaceOrientation: Bool {
//        return self == .portrait ||
//               self == .portraitUpsideDown ||
//               self == .landscapeLeft ||
//               self == .landscapeRight
//    }
//}
////.onChange(of: geo.frame(in: .global).size) { oldSize, newSize
/////почему когда делаю ротацию устройства с портрета на ландшавт (newSize отрабатывает ) затем с ландшавта в перевернутый верх ногами портрет (newSize не отрабатывает) затем с перевернутого верх ногами портрета в перевернутый верх ногами ландшавт (newSize не отрабатывает) и затем с перевернутого верх ногами ландшавта в портрет (newSize отрабатывает ) ? за всю ротацию по кругу отрабатывает только два раза, как сделать что бы отрабатывал всегда?
/////SwiftUI сравнивает старое и новое значение (CGSize – Equatable). Если они различаются → вызывает ваше замыкание и кладёт туда (oldSize, newSize).
//
//// MARK: - Модификатор без PreferenceKey
///если ты адаптируешь UI под Split View / Stage Manager, safe area всё равно полезна и лучше не .ignoresSafeArea()
//struct RootSizeReader: ViewModifier {
//    
//    let onChange: (CGSize) -> Void
//    
//    func body(content: Content) -> some View {
//        content
//            .background(
//                GeometryReader { geo in
//                    Color.clear
//                        .ignoresSafeArea()
//                        .onAppear {
//                            onChange(geo.frame(in: .global).size)
//                        }
//                        .onChange(of: geo.frame(in: .global).size) { oldSize, newSize in           // любое изменение
//                            onChange(newSize)
//                        }
//                }
//                    .ignoresSafeArea()
//            )
//    }
//}
//
//extension View {
//    func readRootSize(_ onChange: @escaping (CGSize) -> Void) -> some View {
//        self.modifier(RootSizeReader(onChange: onChange))
//    }
//}
//










// MARK: - PreferenceKey


///DeviceOrientationModifier измеряет размер того контейнера, к которому он применён, а не всего экрана устройства.
///Что влияет на размер: Safe Area (вырез, индикатор дома) + NavigationBar/Toolbar + TabBar + Любые другие padding'и
///TabView { .. } .modifier(DeviceOrientationModifier()) // ← Будет учитывать высоту TabBar

//Как получить реальные размеры экрана
///Если вам нужны полные размеры экрана (без учета safe area и других элементов):
///ContentView().ignoresSafeArea() // ← Игнорируем safe area .modifier(DeviceOrientationModifier()) // ← Теперь получим полный экран

//он учитывает реальное доступное пространство.
//struct DeviceOrientationModifier: ViewModifier {
//    @EnvironmentObject private var orientationService: DeviceOrientationService
//
//    func body(content: Content) -> some View {
//        content
//            .background(
//                GeometryReader { geometry in
//                    Color.clear
//                        .preference(
//                            key: ContainerSizeKey.self,
//                            value: geometry.size
//                        )
//                }
//            )
//            .onPreferenceChange(ContainerSizeKey.self) { size in
//                orientationService.updateContainerSize(size)
//            }
//    }
//}

///// Удобное расширение для применения модификатора
//extension View {
//    func trackContainerSize() -> some View {
//        modifier(DeviceOrientationModifier())
//    }
//}

//struct ContainerSizeKey: PreferenceKey {
//    static var defaultValue: CGSize = .zero
//    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
//        value = nextValue()
//    }
//}

// MARK: - old implement DeviceOrientationService

//import Combine
//import SwiftUI
//
//class DeviceOrientationService: ObservableObject {
//    enum Orientation { case portrait, landscape }
//
//    @Published private(set) var orientation: Orientation = .portrait
//    private var cancellables = Set<AnyCancellable>()
//    private var lastContainerSize: CGSize = .zero
//
//    init() {
//        setupOrientationTracking()
//    }
//
//    private func setupOrientationTracking() {
//        // Системные уведомления об изменении ориентации
//        NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)
//            .sink { [weak self] _ in
//                self?.handleDeviceOrientationChange()
//            }
//            .store(in: &cancellables)
//
//        // Первоначальное обновление
//        updateOrientation()
//    }
//
//    // Обработчик изменений от GeometryReader
//    func updateContainerSize(_ size: CGSize) {
//        print("geometry.size - \(size)")
//        lastContainerSize = size
//        updateOrientation()
//    }
//
//    private func handleDeviceOrientationChange() {
//        guard UIDevice.current.orientation.isValidInterfaceOrientation else { return }
//        updateOrientation()
//    }
//
//    private func updateOrientation() {
//        let newOrientation = calculateOrientation()
//
//        DispatchQueue.main.async {
//            if self.orientation != newOrientation {
//                self.orientation = newOrientation
//            }
//        }
//    }
//
//    private func calculateOrientation() -> Orientation {
//        if UIDevice.current.userInterfaceIdiom == .phone {
//            // Для iPhone доверяем физической ориентации
//            return UIDevice.current.orientation.isLandscape ? .landscape : .portrait
//        } else {
//            // Для iPad/Mac используем комбинированный подход
//            let isDeviceLandscape = UIDevice.current.orientation.isLandscape
//            let isContainerLandscape = lastContainerSize.width > lastContainerSize.height
//
//            // Разрешение конфликтов
//            if isDeviceLandscape == isContainerLandscape {
//                return isDeviceLandscape ? .landscape : .portrait
//            } else {
//                // Приоритет данным контейнера для iPad
//                return isContainerLandscape ? .landscape : .portrait
//            }
//        }
//    }
//}
//
//
//
//extension UIDeviceOrientation {
//    var isValidInterfaceOrientation: Bool {
//        // Исключаем неизвестное, лицевое вниз и вверх
//        return self == .portrait || self == .portraitUpsideDown || self == .landscapeLeft || self == .landscapeRight
//    }
//}
