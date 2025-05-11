//
//  NetworkStatusBanner.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 28.04.25.
//

// Animation
///В SwiftUI вы можете применять анимацию двумя способами: неявно (implicit), через модификатор .animation(value:), и явно (explicit) – оборачивая изменение состояния в блок withAnimation { … }.
///В нашем случае мы используем и явную и неявную анимацию одновременно, но можем убрать явную и изменять showBanner = false без нее и все будет работать хорошо!
///В вашем коде использование withAnimation дополнительно к модификатору анимации не является избыточным, если вы хотите получить дополнительное гарантирующее управление анимацией. Однако если вам кажется, что эффект одинаковый, вы можете попробовать убрать этот блок и наблюдать за результатом.

///Как работает анимация?
///при изменении showBanner у нас отрабатывает неявная анимация .animation(.easeInOut, value: showBanner) и если бы небыло .transition(.move(edge: .bottom)) то NetworkStatusBanner бы плавно появился .easeInOut и так же бы плавно исчез .easeInOut.
/// .transition(.move(edge: .bottom)) - как представление будет добавляться или удаляться из иерархии представлений.
/// .move(edge: .bottom) - определяет, что при появлении (и исчезновении) баннера он должен двигаться из области нижнего края. То есть, когда showBanner становится true, текст "въезжает" с нижнего края, а когда становится false – уезжает вниз.


import SwiftUI
import UIKit

struct NetworkStatusBanner: View {
    @EnvironmentObject var networkMonitor: NetworkMonitor
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject var localization: LocalizationService
    @State private var showBanner: Bool = false
    
    private let bannerDuration: TimeInterval = 10.0
    
    var body: some View {
        Group {
            if showBanner {
                Text(Localized.NetworkStatusBanner.noInternetConnection.localized())
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(AppColors.red)
                    .foregroundColor(AppColors.primary)
                    .cornerRadius(8)
                    .shadow(radius: 4)
                    .padding(.horizontal, 16)
//                    .hapticFeedback(.warning)
                    .transition(.move(edge: .bottom))
            }
        }
        .animation(.easeInOut, value: showBanner)
        .onChange(of: scenePhase) {  oldPhase, newPhase in
            if newPhase == .active && !networkMonitor.isConnected {
                showBannerIfNeeded()
            }
        }
        .onChange(of: networkMonitor.isConnected) { isOldConnected, isNewConnected in
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
        ///делаем проверку на guard так как сработает дважды если при первом старте isConnected == false"
        guard showBanner == false else { return }
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



// MARK: - Description

//print("NetworkStatusBanner - isOldConnected: \(isOldConnected), isNewConnected: \(isNewConnected))")
//print("NetworkStatusBanner - oldPhase: \(oldPhase), newPhase: \(newPhase))")


