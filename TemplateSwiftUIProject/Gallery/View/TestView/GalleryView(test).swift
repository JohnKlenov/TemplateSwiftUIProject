//
//  GalleryView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 18.10.24.
//

//import SwiftUI
//import Combine
//
//struct GalleryView: View {
//    
//    @StateObject private var viewModel:GalleryViewModel
//    
//    //alert
//    @State private var isShowAlert: Bool = false
//    @State private var alertMessage: String = ""
//    @State private var alertTitle: String = ""
//    @State private var cancellables = Set<AnyCancellable>()
//    
//    @EnvironmentObject var galleryCoordinator:GalleryCoordinator
//    @EnvironmentObject var viewBuilderService:ViewBuilderService
//    
//    init() {
//        _viewModel = StateObject(wrappedValue: GalleryViewModel(alertManager: AlertManager.shared))
//        print("init GalleryView")
//    }
//    
//    var body: some View {
//        ///в момент rerendering в init View передаются те же параметры что и при первой инициализации
//        ///поэксперементировать с homeCoordinator - вынести его из состояния в HomeView
//        NavigationStack(path: $galleryCoordinator.path) {
//            viewBuilderService.galleryViewBuild(page: .gallery)
//                .navigationDestination(for: GalleryFlow.self) { page in
//                    viewBuilderService.galleryViewBuild(page: page)
//                }
//        }
//        .sheet(item: $galleryCoordinator.sheet) { sheet in
//            viewBuilderService.buildSheet(sheet: sheet)
//        }
//        .fullScreenCover(item: $galleryCoordinator.fullScreenItem) { cover in
//            viewBuilderService.buildCover(cover: cover)
//        }
//        .onFirstAppear {
//            print("onFirstAppear GalleryView")
//            subscribeToLocalAlerts()
//        }
//        .onAppear {
//            viewModel.alertManager.isGalleryViewVisible = true
//            print("onAppear GalleryView")
//        }
//        .onDisappear {
//            viewModel.alertManager.isGalleryViewVisible = false
//            print("onDisappear GalleryView")
//        }
//        .background {
//            AlertViewLocal(isShowAlert: $isShowAlert, alertTitle: $alertTitle, alertMessage: $alertMessage, nameView: "GalleryView")
//        }
//    }
//    
//    private func subscribeToLocalAlerts() {
//        viewModel.alertManager.$localAlerts
//            .combineLatest(viewModel.alertManager.$isGalleryViewVisible)
//            .sink { (localAlert, isGalleryViewVisible) in
//                print(".sink { (localAlert, isGalleryViewVisible)")
//                if isGalleryViewVisible, let alert = localAlert["GalleryView"] {
//                    print("if isGalleryViewVisible, let alert = localAlert")
//                    alertMessage = alert.first?.message.localized() ?? Localized.Alerts.defaultMessage.localized()
//                    alertTitle = alert.first?.operationDescription.localized() ?? Localized.Alerts.title.localized()
//                    isShowAlert = true
//                }
//            }
//            .store(in: &cancellables)
//    }
//    
//}
// MARK: - before firestore localization

//
//struct ModalView:View {
//    var body: some View {
//        ZStack {
//            Color.green
//                .ignoresSafeArea()
//            Text("I'm ModalView")
//                .font(.system(.largeTitle, design: .default, weight: .regular))
//        }
//    }
//}



//struct GalleryView: View {
//    
//    // Получаем сервис локализации через EnvironmentObject
//    @EnvironmentObject var localization: LocalizationService
//    
//    // Список поддерживаемых языков
//    let supportedLanguages = ["en", "ru", "es"]
//    
//    var body: some View {
//        List(supportedLanguages, id: \.self) { code in
//            Button(action: {
//                // Устанавливаем выбранный язык
//                localization.setLanguage(code)
//            }) {
//                HStack {
//                    // Отображаем название языка
//                    Text(languageName(for: code))
//                    Spacer()
//                    // Показываем галочку для текущего языка
//                    if code == localization.currentLanguage {
//                        Image(systemName: "checkmark")
//                    }
//                }
//            }
//        }
//        .onAppear{
//            print("GalleryView onAppear")
//        }
//    }
//    
//    // Метод для получения названия языка
//    private func languageName(for code: String) -> String {
//        Locale.current.localizedString(forLanguageCode: code) ?? code.uppercased()
//    }
//}

//    @State private var isPresentingAlert = false
//    @State private var isPresentingSheet = false
//    @StateObject var viewModel = GalleryViewModel()
////    @EnvironmentObject private var crudManager: CRUDSManager
//
//    var body: some View {
//        VStack {
//            let _ = Self._printChanges()
//            Button("Show Sheet") {
////                isPresentingSheet = true
//                viewModel.managerCRUDS?.removeBook(book: BookCloud(title: "", author: "", description: "", urlImage: ""), forView: "TestView", operationDescription: "TestOperation")
//            }
//        }
//        .onFirstAppear {
//            print("onFirstAppear GalleryView")
//            /// ID
////            viewModel.setDataModel(crudManager)
//        }
//        .onAppear {
//            print("onAppear GalleryView")
//        }
//        .sheet(isPresented: $isPresentingSheet) {
//            ModalView(isPresentingAlert: $isPresentingAlert)
//                .alert(isPresented: $isPresentingAlert) {
//                    Alert(title: Text("Alert"), message: nil, dismissButton: .default(Text("OK")))
//                }
//        }
//    }

//class GalleryViewModel:ObservableObject {
//    
//    var managerCRUDS:CRUDSManager?
//    
//    init() {
//        print("init GalleryViewModel")
//    }
//    
//    func setDataModel(_ model:CRUDSManager) {
//        self.managerCRUDS = model
//    }
//    
//}
//
//struct ModalView: View {
//    @Binding var isPresentingAlert: Bool
//    
//    var body: some View {
//        VStack {
//            
//            Button("Show Alert") {
//                isPresentingAlert = true
//            }
//        }
//        
//    }
//}




//struct GalleryView: View {
//    
////    @State var isPresentingAlert = false
////        @State var isPresentingSheet = false
////        
////        var body: some View {
////            VStack {
////                Button("Show Sheet") {
////                    isPresentingSheet = true
////                }
////            }
////            .alert("Alert", isPresented: $isPresentingAlert) {}
////            .sheet(isPresented: $isPresentingSheet) {
////                Button("Show Alert") {
////                    isPresentingAlert = true
////                }
////            }
////        }
//    
//    @State var isShowModal:Bool = false
//    
//    init() {
//        print("GalleryView init")
//    }
//    var body: some View {
//        ZStack {
//            Color.pink
//                .ignoresSafeArea()
//            VStack(spacing:20) {
//                Text("I'm Gallery")
//                    .font(.system(.largeTitle, design: .default, weight: .regular))
//                Button("AddModal", role: .none) {
//                    isShowModal.toggle()
//                }
//            }
//            
//        }
//        .onAppear(perform: {
//            print("GalleryView onAppear")
//        })
////        .fullScreenCover(isPresented: $isShowModal) { ModalView() }
//        .sheet(isPresented: $isShowModal) {
//            ModalView()
//        }
//    }
//}

//#Preview {
//    GalleryView()
//}

