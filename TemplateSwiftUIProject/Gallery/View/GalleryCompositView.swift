//
//  GalleryCompositView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 12.03.25.
//


// MARK: - .refreshable

///Дело в том, что модификатор .refreshable в SwiftUI специально спроектирован для работы с асинхронными операциями, такими как вызов await refreshAction(). Когда пользователь потягивает для обновления, SwiftUI запускает замыкание и отображает системный индикатор обновления (спиннер) вверху экрана. Вот как это работает:
///Асинхронное выполнение: При активации .refreshable вызывается замыкание, содержащее await refreshAction(). Это означает, что выполнение задачи блокируется до тех пор, пока операция завершится. Пока выполняется этот асинхронный код (например, fetchData()), индикатор обновления остаётся активным.
///Блокировка повторного вызова: Сам механизм .refreshable не даёт инициировать новый запрос, пока текущий не завершён. Это встроенная защита от того, чтобы пользователь не смог запустить несколько одновременных запросов. То есть если fetchData() всё ещё выполняется, система не начнёт новый вызов, даже если будет повторное потягивание экрана.
///Интеграция с Swift Concurrency: Благодаря использованию await весь механизм работает в рамках Swift Concurrency. Как только завершится задача (либо успешно, либо с ошибкой), система завершит отображение спиннера, и элемент управления станет восприимчивым к повторному действию.
///Таким образом, макет работы с .refreshable гарантирует, что:
///Спиннер отображается, пока идет выполнение асинхронного кода.
///Повторный вызов не происходит, пока предыдущий не завершится.
/// tесли в блоке .refreshable будет синхронный метод то спинер прекратит выполнение сразу

import SwiftUI


struct GalleryCompositView: View {
    
    @EnvironmentObject var localization: LocalizationService 
    
    let data: [UnifiedSectionModel]
    let refreshAction: () async -> Void // Асинхронное замыкание
    
    var body: some View {
        ScrollView {
            VStack(spacing: 10) { // Используем LazyVStack
                ForEach(data) { section in
                    switch section {
                    case .malls(let mallSection):
                        MallsSectionView(items: mallSection.items, headerTitle: mallSection.header.localized())
                    
                    case .shops(let shopSection):
                        ShopsSectionView(items: shopSection.items, headerTitle: shopSection.header.localized())
                    
                    case .popularProducts(let productSection):
                        PopularProductsSectionView(items: productSection.items, headerTitle: productSection.header.localized())
                    }
                }
            }
            .padding(.vertical)
        }
        ///Пока выполняется этот асинхронный код (await refreshAction()), индикатор обновления(спинер) остаётся активным.
        .refreshable {
            await refreshAction()
        }
    }
}

