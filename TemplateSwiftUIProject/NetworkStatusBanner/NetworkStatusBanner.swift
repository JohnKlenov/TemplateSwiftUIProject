//
//  NetworkStatusBanner.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 28.04.25.
//


import SwiftUI
import UIKit

struct NetworkStatusBanner: View {
    @EnvironmentObject var networkMonitor: NetworkMonitor
    @Environment(\.scenePhase) private var scenePhase
    @State private var showBanner: Bool = false
    
    private let bannerDuration: TimeInterval = 15.0
    
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
                    .transition(.move(edge: .bottom))
            }
        }
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
    
    ///сработает дважды если при первом старте isConnected == false
    private func showBannerIfNeeded() {
        guard showBanner == false else { return }
        print("showBannerIfNeeded() сработает дважды если при первом старте isConnected == false")
        /// Создаем haptic feedback -  Генерация тактильного сигнала при потере соединения.
        /// Можно использовать UINotificationFeedbackGenerator с типом .warning, .success, .error
        /// для тактильной вибрации (haptic feedback) можно использовать классы UIImpactFeedbackGenerator, UINotificationFeedbackGenerator, UISelectionFeedbackGenerator
        let notificationGenerator = UINotificationFeedbackGenerator()
        notificationGenerator.prepare()
        notificationGenerator.notificationOccurred(.warning)

        withAnimation { showBanner = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + bannerDuration) {
            withAnimation { showBanner = false }
        }
    }
}


