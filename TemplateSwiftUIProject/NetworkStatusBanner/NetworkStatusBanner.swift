//
//  NetworkStatusBanner.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 28.04.25.
//

import SwiftUI

struct NetworkStatusBanner: View {
    @EnvironmentObject var networkMonitor: NetworkMonitor
    @State private var showBanner: Bool = false
    
    /// Длительность отображения баннера (в секундах)
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
        .animation(.easeInOut, value: showBanner)
        .onChange(of: networkMonitor.isConnected) { oldValue, isConnected in
            if isConnected == false {
                // При потере соединения отображаем баннер
                showBanner = true
                // Автоматически скрываем баннер через bannerDuration секунд
                DispatchQueue.main.asyncAfter(deadline: .now() + bannerDuration) {
                    withAnimation {
                        showBanner = false
                    }
                }
            } else {
                // Если соединение восстановлено – сразу скрываем баннер (если он отображается)
                withAnimation {
                    showBanner = false
                }
            }
        }

    }
}

