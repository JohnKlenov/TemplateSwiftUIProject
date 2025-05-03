//
//  NetworkStatusBanner.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 28.04.25.
//


import SwiftUI

struct NetworkStatusBanner: View {
    @EnvironmentObject var networkMonitor: NetworkMonitor
    @Environment(\.scenePhase) private var scenePhase
    @State private var showBanner: Bool = false
    
    private let bannerDuration: TimeInterval = 4.0
    
    var body: some View {
        Group {
            if showBanner {
                Text("Нет соединения с Интернетом")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .shadow(radius: 4)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                    .transition(.move(edge: .bottom))
            }
        }
//        _, newPhase
        .animation(.easeInOut, value: showBanner)
        .onChange(of: scenePhase) {  oldPhase, newPhase in
            print("NetworkStatusBanner - oldPhase: \(oldPhase), newPhase: \(newPhase))")
            if newPhase == .active && !networkMonitor.isConnected {
                showBannerIfNeeded()
            }
        }
        .onChange(of: networkMonitor.isConnected) { isOldConnected, isNewConnected in
            print("NetworkStatusBanner - isOldConnected: \(isOldConnected), isNewConnected: \(isNewConnected))")
            handleConnectionChange(isConnected: isNewConnected)
        }
    }
    
    private func handleConnectionChange(isConnected: Bool) {
        if isConnected {
            withAnimation { showBanner = false }
        } else {
            showBannerIfNeeded()
        }
    }
    
    private func showBannerIfNeeded() {
        guard showBanner == false else { return }
        print("showBannerIfNeeded() сработает дважды если при первом старте isConnected == false")
        withAnimation { showBanner = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + bannerDuration) {
            withAnimation { showBanner = false }
        }
    }
}

//import SwiftUI
//
//struct NetworkStatusBanner: View {
//    @EnvironmentObject var networkMonitor: NetworkMonitor
//    @State private var showBanner: Bool = false {
//        didSet {
//            print("showBanner - \(showBanner)")
//        }
//    }
//    
//    /// Длительность отображения баннера (в секундах)
//    private let bannerDuration: TimeInterval = 4.0
//    
//    var body: some View {
//        Group {
//            if showBanner {
//                Text("Нет соединения с Интернетом")
//                    .padding()
//                    .frame(maxWidth: .infinity)
//                    .background(Color.red)
//                    .foregroundColor(.white)
//                    .cornerRadius(8)
//                    .shadow(radius: 4)
//                    .padding(.horizontal, 16)
//                    .padding(.bottom, 16)
//                    .transition(.move(edge: .bottom))
//            }
//        }
//        .onAppear {
//            print("NetworkStatusBanner onAppear")
//        }
//        .onDisappear {
//            print("NetworkStatusBanner onDisappear")
//        }
//        .animation(.easeInOut, value: showBanner)
//        .onChange(of: networkMonitor.isConnected) { oldValue, isConnected in
//            print("isConnected changed to \(isConnected)")
//            if isConnected == false {
//                // Оборачиваем изменение состояния в withAnimation,
//                // чтобы переход сработал корректно.
//                withAnimation {
//                    showBanner = true
//                }
//                // Через bannerDuration секунд скрываем баннер с анимацией
//                DispatchQueue.main.asyncAfter(deadline: .now() + bannerDuration) {
//                    withAnimation {
//                        showBanner = false
//                    }
//                }
//            } else {
//                withAnimation {
//                    showBanner = false
//                }
//            }
//        }
//    }
//}

//import SwiftUI
//
//struct NetworkStatusBanner: View {
//    @EnvironmentObject var networkMonitor: NetworkMonitor
//    @State private var showBanner: Bool = false
//    
//    /// Длительность отображения баннера (в секундах)
//    private let bannerDuration: TimeInterval = 4.0
//    
//    var body: some View {
//        Group {
//            if showBanner {
//                Text("Нет соединения с Интернетом")
//                    .padding()
//                    .frame(maxWidth: .infinity)
//                    .background(Color.red)
//                    .foregroundColor(.white)
//                    .cornerRadius(8)
//                    .shadow(radius: 4)
//                    .padding(.horizontal, 16)
//                    .padding(.bottom, 16)
//                    .transition(.move(edge: .bottom))
//            }
//        }
//        .animation(.easeInOut, value: showBanner)
//        .onChange(of: networkMonitor.isConnected) { oldValue, isConnected in
//            if isConnected == false {
//                // При потере соединения отображаем баннер
//                showBanner = true
//                // Автоматически скрываем баннер через bannerDuration секунд
//                DispatchQueue.main.asyncAfter(deadline: .now() + bannerDuration) {
//                    withAnimation {
//                        showBanner = false
//                    }
//                }
//            } else {
//                // Если соединение восстановлено – сразу скрываем баннер (если он отображается)
//                withAnimation {
//                    showBanner = false
//                }
//            }
//        }
//
//    }
//}

