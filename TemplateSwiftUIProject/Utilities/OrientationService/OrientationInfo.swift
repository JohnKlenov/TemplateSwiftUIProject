//
//  OrientationInfo.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 25.05.25.


// MARK: - DeviceOrientationService

// будем синхронизировать данные из сервиса ориентации с локальными размерами GeometryReader.

///вот так все работает без визуальных багов
///struct OnboardingPageView: View { @EnvironmentObject private var orientationService: DeviceOrientationService var body: some View { GeometryReader { geo in Group { if orientationService.orientation == .landscape  { Горизонтальная компоновка для ландшафтного режима } else { Вертикальная компоновка для портретного режима } } .frame(width: geo.size.width, height: geo.size.height) .animation(.easeInOut(duration: 0.35), value: orientationService.orientation) }}}

//я боялся что изменение ориентации в Environment произойдет раньше чем размер придет в GeometrySize или на оборот. Но на сколько я понял этого не стоит боятся , ведь SwiftUI обработает это?
///Да, вы правы: бояться порядка «кто первым придёт – ориентация или geometry» в SwiftUI обычно не стоит. SwiftUI в декларативном body просто смотрит на текущее значение всех @State/@EnvironmentObject/@Binding и выстраивает UI под них. Если ориентация приедет раньше размера или наоборот – будет два прохода body, но в итоге вьюшки отрисуются уже в корректном состоянии.
///
///Самый простой рецепт:
///1.Читаем ориентацию через @EnvironmentObject
///2.Читаем размер через GeometryReader
///3.Вставляем одну–единственную анимацию на orientation (она плавно покроет и geometry-смену).
///4.Больше никаких CombineLatest, CurrentValueSubject и прочих «прокладок».
///Вот минимальный пример, как это выглядит в OnboardingPageView:
///struct OnboardingPageView: View { @EnvironmentObject private var orientationService: DeviceOrientationService var body: some View { GeometryReader { geo in Group { } .frame(width: geo.size.width, height: geo.size.height) .animation(.easeInOut(duration: 0.35), value: orientationService.orientation) }}}
///SwiftUI автоматически перерисует OnboardingPageView и пересчитает GeometryReader каждый раз, когда меняется orientationService.orientation или geo.size. • .animation(..., value: orientationService.orientation) «накладывает» плавное изменение и на layout, и на geometry. • Даже если приходят два отдельных события (сначала размер, потом ориентация, или наоборот) – вью перерисуется дважды, но оба раза с анимацией, и конечный результат будет правильным.
///
///Когда всё же может понадобиться «склейка» size+orient?
///У вас есть сложные смены нескольких state-переменных, и вы действительно хотите запустить один-единственный обработчик, когда они оба поменялись.
///Вам нужно точно отловить «момент», когда и геометрия, и ориентация обновились, чтобы запустить кастомную логику.

//В подавляющем большинстве случаев для адаптивного лэйаута это избыточно. Доверьтесь реактивному потоку SwiftUI – он честно пересчитает body под любые сочетания @State и @EnvironmentObject.

//То есть в боевых приложениях если у нас есть пара или тройка State или Environment которые при изменении перерисовывают View и делают это почти одновременно это абсолютно нормально?
///Да, это совершенно нормально и даже ожидаемо. SwiftUI построен так, чтобы
///при любом изменении любого @State/@Binding/@EnvironmentObject заново вызывать body
///сверять старое и новое дерево вью (diff) и вносить только необходимые патчи
///всё это происходит очень быстро (в пределах одного кадра), так что глаз почти не заметит «двойной» ререндер.
///
///1. «SwiftUI сверяет старое и новое дерево вью (diff) и вносит только необходимые патчи»:
///Каждый раз, когда вы меняете @State/@Binding/@EnvironmentObject и SwiftUI вызывает ваш body, фреймворк не перерисовывает весь экран заново.
///Вместо этого он строит «новое» виртуальное дерево вью (некие лёгковесные структуры, описывающие: “здесь VStack, там Text c таким-то текстом, здесь у него этот модификатор…”).
///Затем SwiftUI сравнивает старое и новое виртуальные деревья (операция diff).
///И только для тех узлов, где обнаружились изменения в типе вьюшки, её идентификаторе или параметрах, делает низкоуровневые вызовы в UIKit/AppKit для вставки/показа/анимации/обновления.
///Даже если вы перепишите 10 Text подряд, но меняется только у одного текстовое содержимое — SwiftUI увидит, что остальные десять идентичны, и не тронет их.
///
///2.«Если изменения приводят к тяжёлым расчётам в body и вы хотите минимизировать число пересборок — можно сгруппировать их в одном @StateObject или в одном withTransaction.»
///Когда в вашем body лежат сложные вычисления (например, итерации по большим коллекциям, сложная логика .map/.reduce, тяжёлые свойства .onAppear и т. д.), каждый проход body может стоить дорого. Чтобы уменьшить число таких проходов, есть два приёма:
///A) Группировка стейтов в один ObservableObject (@StateObject)
///struct ProfileView: View { @State private var name: String = "" @State private var avatarData: Data? @State private var isPremium: Bool = false var body: some View { // читать три разных @State // каждый апдейт пробуждает body }}
///class ProfileModel: ObservableObject { @Published var name: String = "" @Published var avatarData: Data? @Published var isPremium: Bool = false // здесь же можно спрятать тяжёлую логику загрузки/парсинга }
///Плюс такого подхода:
///Вы не разбросали логику по трём отдельных @State, а сконцентрировали в одном классе.
///Внутри ProfileModel можно кешировать результаты и делать objectWillChange.send() только тогда, когда действительно нужно, тем самым снижая число апдейтов body.
///
///Если логика разбросана по разным @State и вы видите в профилировщике слишком много ререндеров, склейте эти состояния в один @StateObject/ObservableObject.
///Если у вас несколько связанных visual-эффектов (движение, изменение прозрачности, масштаб) и вы хотите их атомарно анимировать, — оберните все изменения в один withAnimation или в withTransaction.
///В остальном — полагайтесь на то, что SwiftUI диффит дерево и экономит на обновлениях автоматически.





// MARK: - Adaptive UI (iPod + iOS)

// оставим поддержку iPad но отключу режимы Split View, Slide Over, Stage Manager в info.plist
///
///Запрещает запуск приложения в Split View и Slide Over — оно всегда будет работать только полноэкранно.
///В iPadOS 16+ Stage Manager позволяет пользователям масштабировать окна вручную, но ты можешь запретить поддержку внешнего экрана:
///Обеспечивает только полноэкранный запуск, без поддержки оконного режима.
///Stage Manager не будет работать, потому что приложение всегда занимает весь экран.


// MARK: - Setting

//var isRotationLocked
///let supportedOrientations = UIApplication.shared.supportedInterfaceOrientations(for: nil) - Запрашивает разрешённые ориентации экрана для текущего приложения.
///Чем это управляется? - Info.plist (UISupportedInterfaceOrientations), AppDelegate (application(_:supportedInterfaceOrientationsFor:)), UIViewController.supportedInterfaceOrientations (в текущем VC)
///supportedOrientations → это маска (UIInterfaceOrientationMask), содержащая допустимые ориентации (.portrait, .landscapeLeft, .landscapeRight и т. д.).
///return supportedOrientations == .portrait || supportedOrientations.isSubset(of: .portrait) - Проверяем, заблокирован ли поворот
///Возвращает true, если приложение разрешает только портретную ориентацию.
///если в Info.plist записано только .portrait, то считается, что поворот заблокирован.
///supportedOrientations.isSubset(of: .portrait) - Проверяет, содержит ли маска только портретную ориентацию. Это помогает поймать ситуацию, когда кроме .portrait вообще ничего не разрешено.
///Если в supportedOrientations есть только .portrait → isSubset(of: .portrait) == true. ❌ Если там есть и .portrait, и .landscapeLeft → isSubset(of: .portrait) == false.
///Результат: Если в supportedOrientations есть только портрет — isRotationLocked == true. Если разрешены ландшафтные режимы — isRotationLocked == false.
///Этот код проверяет, заблокирован ли экран в портретном режиме. Он помогает понять, будет ли приложение переключаться в .landscape, и правильно адаптировать UI.
///
///Почему не достаточно одной проверки supportedOrientations == .portrait?
///isRotationLocked становится более надёжным и учитывает больше сценариев!
///supportedOrientations == .portrait // `true`, если приложение поддерживает ТОЛЬКО портрет! Но если supportedOrientations содержит ещё и ландшафт, сравнение вернёт false, даже если приложение в портретном режиме.
///supportedOrientations.isSubset(of: .portrait) // `true`, если доступны ТОЛЬКО портретные режимы
///Эта проверка нужна, чтобы убедиться, что в supportedOrientations нет никаких других ориентаций кроме .portrait.
///Этот метод определяет, содержит ли текущая маска ТОЛЬКО .portrait, даже если в Info.plist явно перечислены .portrait, .portraitUpsideDown (что всё равно является портретной ориентацией).
///Первая (== .portrait) ловит ровно один вариант: чистый портрет без других ориентаций. 🔹 Вторая (isSubset(of: .portrait)) дополнительно проверяет, что в маске разрешений нет ничего кроме портретных режимов.
///Оператор || (логическое ИЛИ) означает, что если любая из двух проверок вернёт true, вся конструкция тоже будет true.
///то есть если бы мы оставили только supportedOrientations == .portrait и в supportedOrientations было бы (.portrait, .portraitUpsideDown) то результат был бы false но он бы нам подошел!

//var currentInterfaceOrientation: UIInterfaceOrientation
///Что делает currentInterfaceOrientation?
///Это новый способ получения ориентации, появившийся в iOS 16+.
///currentInterfaceOrientation точнее определяет как выглядит UI, а не как повернуто устройство. ✅ Он полезен в адаптивных приложениях, особенно с Split View, Stage Manager. ✅ Использование default в switch позволяет обработать случаи, когда UIDevice.orientation даёт ошибочные данные.
///currentInterfaceOrientation — это ваш вспомогательный геттер, который вы, скорее всего, добавили в DeviceOrientationService. Он просто достаёт поле interfaceOrientation у первой активной UIWindowScene.(WindowGroup — это декларативная «обёртка» над UIKit-сценой. в любом SwiftUI-приложении (кроме виджета) хотя бы одна UIWindowScene существует автоматически, даже если вы никогда не видели её в коде.)
/// default ловит все «грязные» ситуации • .unknown, .faceUp, .faceDown (устройство на столе лицом вверх или вниз)
/// Минимум вычислений Проверить UIDevice.orientation дешевле, чем каждый раз искать активную UIWindowScene и дёргать её interfaceOrientation. Мы делаем это лишь тогда, когда датчик не дал однозначного ответа.

//UIDevice.orientation  vs currentInterfaceOrientation
///«Датчик-чайник» — UIDevice.orientation
///«Оркестр-дирижёр» — UIWindowScene.interfaceOrientation (то, что мы читаем как currentInterfaceOrientation)
///
///Как думает датчик (UIDevice.orientation)
///Он тупо подслушивает акселерометр: «Корпус повернули на 90°? Супер, ставлю .landscapeLeft. Лежим экраном вверх? Ну ок, .faceUp. Вообще не понимаю, что происходит? Ладно, кину .unknown.»
///Проблема: датчик ничего не знает про твоё приложение, про разрешённые ориентации или про Split View. Он честно докладывает положение устройства, но это ноль пользы, когда UI жить не хочет в ландшафте.
///
///Как думает дирижёр (currentInterfaceOrientation)
///Сначала к нему приходят сырые данные того же датчика.
///Он смотрит, что разрешено в Info.plist, делегатах и контроллерах. ‑ «Ага, у тебя UISupportedInterfaceOrientations = PortraitOnly? Окей, забудь про ландшафт, даже если корпус лежит боком.»
///Он учитывает, как система разместила окно: • Полноэкранное? • 70/30 Split View? • Окно Stage Manager на внешнем дисплее?
///Только потом он говорит: «Вот моё окончательное решение: UI сейчас .portrait (или .landscapeLeft / .landscapeRight).» ‑ Если окно вообще не повернули, он не меняет значение, даже если датчик орал «landscape!». ‑ Если UI заблокирован, он упрямо держит .portrait. ‑ Он никогда не возвращает .unknown, .faceUp, .faceDown: для пользовательского интерфейса эти позы бессмысленны.
///
///Живой пример, где «ум» заметен
///Ты разрешил только портрет. Пользователь кладёт iPad на диван боком → • Датчик: «landscapeRight!» • Дирижёр: «Не ведусь. UI останется портретным, потому что так просил разработчик.»
///Split View, устройство вертикально, но окно растянули так, что оно шире высоты → • Датчик: «portrait!» (корпус в портрете) • Дирижёр: «UI-координаты всё ещё портрет, разделитель просто дал нам широкую площадку. Значит, остаёмся .portrait.»
///Stage Manager, iPad держат вертикально, а окно утащили на внешний монитор, где Landscape → • Датчик: «portrait!» • Дирижёр (глядя на монитор): «Окно реально лежит горизонтально — объявляю .landscapeRight.»
///
///Почему мы держим их обоих
///Быстро: датчик отвечает мгновенно и подходит для анимации камеры или AR.
///Надёжно: дирижёр прикрывает, когда датчик врёт или UI под замком.


import SwiftUI
import UIKit
import Combine

enum Orientation {
    case portrait
    case landscape
}

class DeviceOrientationService: ObservableObject {

    @Published private(set) var orientation: Orientation = .portrait
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        updateOrientation()
        
        NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)
            .sink { [weak self] _ in
                self?.updateOrientation()
            }
            .store(in: &cancellables)
    }
    
    private func updateOrientation() {
        let newOrientation: Orientation
        
        if isRotationLocked {
            newOrientation = .portrait
        } else {
            let deviceOrientation = UIDevice.current.orientation
            
            switch deviceOrientation {
            case .portrait, .portraitUpsideDown:
                newOrientation = .portrait
            case .landscapeLeft, .landscapeRight:
                newOrientation = .landscape
            default:
                // Новый способ получения interfaceOrientation
                newOrientation = currentInterfaceOrientation?.isLandscape ?? false ? .landscape : .portrait
            }
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.orientation = newOrientation
        }
    }
    
    private var currentInterfaceOrientation: UIInterfaceOrientation? {
        if #available(iOS 15.0, *) {
            return UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first?
                .interfaceOrientation
        } else {
            return UIApplication.shared.windows.first?.windowScene?.interfaceOrientation
        }
    }
    
    private var isRotationLocked: Bool {
        let supportedOrientations = UIApplication.shared.supportedInterfaceOrientations(for: nil)
        return supportedOrientations == .portrait || supportedOrientations.isSubset(of: .portrait)
    }
    
    deinit {
        cancellables.forEach { $0.cancel() }
    }
}

extension UIInterfaceOrientation {
    var isLandscape: Bool {
        return self == .landscapeLeft || self == .landscapeRight
    }
}



struct RootSizeReader: View {
    @EnvironmentObject var orientation: DeviceOrientationService
    
    var body: some View {
        GeometryReader { geo in
            Color.clear
                .onAppear {
//                    print("RootSizeReader onAppear geo.size - \(geo.size)")
//                    orientation.update(raw: geo.size)
                }
                .onChange(of: geo.size) { _, newSize in
//                    print("RootSizeReader onChange geo.size - \(geo.size)")
//                    orientation.update(raw: newSize)
                }
        }
    }
}


// MARK: - синхронизируем данные из сервиса ориентации с локальными размерами GeometryReader.


// MARK: AdaptiveView

// это чтука работает как обертка но  .onReceive(combined) происходит многократные вызовы, нужно дорабатывать

// Оборачиваем любой контент, которому нужны и размер, и ориентация.
// Универсальная обёртка: кладёшь внутрь любой контент
// builder(size, orientation) → View, где уже можно верстать.

// MARK: AdaptiveView – локальный size + ориентация в одном «пакете»

//import SwiftUI
//import Combine
//
//struct AdaptiveView<Content: View>: View {
//
//    // внешняя ориентация
//    @EnvironmentObject private var orient: DeviceOrientationService
//    // локальный размер
//    @State private var containerSize = CGSize.zero
//
////     Subject, чтобы сделать из size полноценный Publisher
//    private let sizeSubject = CurrentValueSubject<CGSize, Never>(.zero)
//
//    // Builder-замыкание, возвращающее любой View
//    private let builder: (CGSize, Orientation) -> Content
//    init(@ViewBuilder _ builder: @escaping (CGSize, Orientation) -> Content) {
//        self.builder = builder
//    }
//
//    // CombineLatest двух «настоящих» Publisher-ов
//    private var combined: AnyPublisher<(CGSize, Orientation), Never> {
//        Publishers.CombineLatest(
//            sizeSubject.removeDuplicates(),
//            orient.$orientation.removeDuplicates()
//        )
//        .eraseToAnyPublisher()
//    }
//
//    var body: some View {
//        GeometryReader { geo in
//            builder(containerSize, orient.orientation)          // ← сам контент
//                .onAppear { updateSize(geo.size) }
//                .onChange(of: geo.size) { old, new in  updateSize(new) }
//        }
//        .animation(.easeInOut(duration: 0.35), value: orient.orientation)
//        .onReceive(combined) { (size, orient) in                // кортеж в скобках!
//            debugPrint("⇢ sync  size:", size, "orient:", orient)
//            // здесь можно запускать побочные эффекты или кастомные анимации
//        }
//    }
//
//    private func updateSize(_ newSize: CGSize) {
//        guard newSize != containerSize else { return }
//        containerSize = newSize        // для SwiftUI-перерисовки
//        sizeSubject.send(newSize)      // для CombineLatest
//    }
//}
//
//
//struct Onboarding: View {
//    let page: OnboardingPage
//
//    var body: some View {
//        AdaptiveView { size, orient in
//            if orient == .landscape {
//                HStack(spacing: 24) {
//                    Image(systemName: page.imageName)
//                        .resizable().scaledToFit()
//                        .frame(width: size.width * 0.20)
//                    VStack(alignment: .leading, spacing: 16) {
//                        Text(page.title).font(.title).bold()
//                        Text(page.description)
//                    }
//                }
//                .padding()
//            } else {
//                VStack(spacing: 24) {
//                    Image(systemName: page.imageName)
//                        .resizable().scaledToFit()
//                        .frame(height: size.height * 0.30)
//                    Text(page.title).font(.largeTitle).bold()
//                    Text(page.description)
//                }
//                .padding(.horizontal)
//            }
//        }
//    }
//}
//

// MARK: - Если хочется иметь и ориентацию и размер контейнера одновременно


//Подход B. Свести источники в один сервис (рекомендуемый)




///Сервис хранит и размер, и ориентацию, вычисляя последнюю из «чистой» геометрии.
///View слушает ТОЛЬКО сервис → гарантированно получает синхронные данные.




//@MainActor
//final class DeviceOrientationService: ObservableObject {
//
//    enum Orientation { case portrait, landscape }
//
//    @Published private(set) var orientation  : Orientation = .portrait
//    @Published private(set) var containerSize: CGSize      = .zero
//
//    private var cancellables = Set<AnyCancellable>()
//    private let sizeSubject  = PassthroughSubject<CGSize, Never>()
//
//    init() {
//
//        // ❶ Сырой датчик (UIDevice) — только fallback
//        NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)
//            .sink { [weak self] _ in self?.fallbackFromDevice() }
//            .store(in: &cancellables)
//
//        // ❷ Истинный «мастер-таймлайн» — размер окна
//        sizeSubject
//            .removeDuplicates()
//            .debounce(for: .milliseconds(40), scheduler: RunLoop.main) // ждать, пока юзер отпустит палец
//            .sink { [weak self] size in self?.apply(size) }
//            .store(in: &cancellables)
//    }
//
//    func updateSize(_ size: CGSize) { sizeSubject.send(size) }
//
//    // MARK: - private
//
//    private func apply(_ size: CGSize) {
//        containerSize = size
//        orientation   = size.width > size.height ? .landscape : .portrait
//    }
//
//    private func fallbackFromDevice() {
//        guard containerSize == .zero else { return } // уже пришёл geo.size—фалбек не нужен
//        let device = UIDevice.current.orientation
//        orientation = (device == .landscapeLeft || device == .landscapeRight) ? .landscape : .portrait
//    }
//}

//struct RootSizeReader: View {
//    @EnvironmentObject var orient: DeviceOrientationService
//    var body: some View {
//        GeometryReader { geo in
//            Color.clear
//                .ignoresSafeArea()
//                .onAppear                     { orient.updateSize(geo.frame(in: .global).size) }
//                .onChange(of: geo.frame(in: .global).size) { new in
//                    orient.updateSize(new)
//                }
//        }
//    }
//}

//struct OnboardingPageView: View {
//    @EnvironmentObject private var orient: DeviceOrientationService
//    var body: some View {
//        if orient.orientation == .landscape {
//            LandscapeLayout(size: orient.containerSize)
//        } else {
//            PortraitLayout(size: orient.containerSize)
//        }
//        .animation(.easeInOut(duration: 0.35), value: orient.orientation)
//    }
//}





//Подход C. Комбинировать прямо в View (CombineLatest)


///Если не хочется переписывать сервис, можно «скрестить» два Publisher прямо в конкретной вьюхе:


//struct AdaptiveView: View {
//    @EnvironmentObject private var orient: DeviceOrientationService
//    @State private var size: CGSize = .zero
//
//    var body: some View {
//        GeometryReader { geo in
//            Color.clear
//                .onAppear { size = geo.size }
//                .onChange(of: geo.size) { size = $0 }
//        }
//        .overlay(content)
//        .onReceive(Publishers.CombineLatest($size, orient.$orientation)) { newSize, newOrient in
//            // здесь у вас гарантированно «одновременный» кадр и ориентация
//            // можно, например, запускать анимацию вручную
//        }
//    }

