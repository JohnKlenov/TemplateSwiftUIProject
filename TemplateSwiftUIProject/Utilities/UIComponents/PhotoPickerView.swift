//
//  PhotoPickerView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 25.08.25.
//



// MARK: - Итоговая схема работы

//SwiftUI показывает .sheet → вызывает makeCoordinator() → makeUIViewController(...).

///makeCoordinator()
///Вызывается один раз при создании структуры PhotoPickerView в SwiftUI.
///SwiftUI создаёт координатор, чтобы потом передавать его в context.coordinator в makeUIViewController и updateUIViewController.
///Это твой мост между UIKit-делегатами и SwiftUI.
///makeUIViewController(context:) 
///Вызывается, когда SwiftUI впервые нужно отобразить этот контроллер (например, при показе .sheet).
///Здесь ты создаёшь и настраиваешь PHPickerViewController, назначаешь делегата (context.coordinator) и возвращаешь его.
///SwiftUI потом сам презентует его на экране.
///updateUIViewController
///Вызывается каждый раз, когда SwiftUI считает, что нужно синхронизировать состояние SwiftUI с UIKit (например, если изменились какие-то @Binding внутри твоей структуры). В нашем случае он пустой, потому что пикер не зависит от внешнего состояния во время показа.

//Пользователь выбирает фото → didFinishPicking в координаторе.

///Почему мы делаем picker.dismiss(animated: true) сразу при выборе
///PHPickerViewController — это модальный контроллер.
///Когда пользователь выбрал фото (или отменил), делегат didFinishPicking вызывается один раз.
///Если мы не закроем пикер вручную, он останется висеть на экране, и пользователь не вернётся в свой интерфейс.

// Мы закрываем пикер (dismiss), чтобы вернуться в UI.

// Через NSItemProvider загружаем UIImage (если возможно).

///Какие типы данных может вернуть provider
///provider — это NSItemProvider, универсальный контейнер для передачи данных между приложениями/системой.
///provider.canLoadObject(ofClass: UIImage.self) Проверяет, может ли он отдать объект как UIImage.
///Это работает для большинства стандартных форматов изображений: JPEG, PNG, HEIC,GIF (только первый кадр), TIFF и т.д.
///Система сама декодирует файл в UIImage.
///Что не поддерживается напрямую:
///RAW-форматы (DNG, CR2 и т.п.) — их нужно грузить как Data через loadDataRepresentation(forTypeIdentifier:).
///Видео — нужно использовать UTType.movie и загружать через loadFileRepresentation.
///Live Photos — отдельный тип (PHLivePhoto), грузится через canLoadObject(ofClass: PHLivePhoto.self).

// Результат передаём в SwiftUI через onComplete.

import SwiftUI
import PhotosUI


enum PhotoPickerResult {
    case success(UIImage)
    case failure(PhotoPickerError)
    case cancelled
}


/// SwiftUI-обёртка над UIKit-контроллером `PHPickerViewController`
/// Позволяет интегрировать системный фотопикер в SwiftUI-поток
struct PhotoPickerView: UIViewControllerRepresentable {
    
    /// Фильтр для выбора типов медиа (по умолчанию — только изображения)
    var filter: PHPickerFilter = .images
    
    /// Лимит количества выбираемых элементов (по умолчанию — 1)
    var limit: Int = 1
    
    /// Колбэк, который будет вызван после выбора или отмены
    /// Если пользователь отменил или загрузка не удалась — придёт `nil`
    var onComplete: (PhotoPickerResult) -> Void
    
    // MARK: - UIViewControllerRepresentable
    
    /// Создаёт и настраивает UIKit-контроллер
    func makeUIViewController(context: Context) -> PHPickerViewController {
        // Конфигурация пикера
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = filter                  // показываем только фото
        config.selectionLimit = limit           // ограничиваем выбор одним элементом
        
        // Создаём контроллер с конфигурацией
        let picker = PHPickerViewController(configuration: config)
        
        // Назначаем делегата (через Coordinator)
        picker.delegate = context.coordinator
        
        return picker
    }
    
    /// Обновление контроллера при изменении состояния SwiftUI
    /// Здесь пусто, так как пикер не зависит от внешних изменений во время показа
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    /// Создаёт координатор — мост между UIKit-делегатом и SwiftUI
    func makeCoordinator() -> Coordinator {
        Coordinator(onComplete: onComplete)
    }
    
    // MARK: - Coordinator
    
    /// Класс-координатор, реализующий делегат `PHPickerViewControllerDelegate`
    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        
        /// Замыкание для передачи результата обратно в SwiftUI
        let onComplete: (PhotoPickerResult) -> Void
        
        init(onComplete: @escaping (PhotoPickerResult) -> Void) {
            self.onComplete = onComplete
        }
        
        /// Вызывается, когда пользователь завершил выбор или отменил
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            // Закрываем пикер (и, как следствие, SwiftUI .sheet)
            picker.dismiss(animated: true)

            // Пользователь закрыл пикер, ничего не выбрав
            if results.isEmpty {
                onComplete(.cancelled)
                return
            }

            // Есть результат, но нет провайдера — это ошибка
            guard let provider = results.first?.itemProvider else {
                onComplete(.failure(.noItemAvailable))
                return
            }

            // 1. Проверяем, что провайдер действительно содержит изображение
            if !provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                onComplete(.failure(.unsupportedType))
                return
            }

            // 2. Проверяем, что его можно загрузить как UIImage
            if !provider.canLoadObject(ofClass: UIImage.self) {
                onComplete(.failure(.unsupportedType))
                return
            }

            // 3. Асинхронная загрузка изображения
            provider.loadObject(ofClass: UIImage.self) { object, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self.onComplete(.failure(PhotoPickerError.map(error)))
                        return
                    }
                    guard let image = object as? UIImage else {
                        self.onComplete(.failure(.unsupportedType))
                        return
                    }
                    self.onComplete(.success(image))
                }
            }
        }
    }
}




//        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
//            // Закрываем пикер (и, как следствие, SwiftUI .sheet)
//            picker.dismiss(animated: true)
//
//            // Если ничего не выбрано — считаем, что пользователь отменил
//            guard let provider = results.first?.itemProvider else {
//                onComplete(.cancelled)
//                return
//            }
//
//            // Проверяем, умеет ли провайдер загружать UIImage
//            if provider.canLoadObject(ofClass: UIImage.self) {
//                // Загружаем объект асинхронно
//                provider.loadObject(ofClass: UIImage.self) { image, error in
//                    // Возвращаем результат на главном потоке (UI-обновления)
//                    DispatchQueue.main.async {
//                        if let error = error {
//                            self.onComplete(.failure(PhotoPickerError.map(error)))
//                            return
//                        }
//                        guard let image = image as? UIImage else {
//                            self.onComplete(.failure(.unsupportedType))
//                            return
//                        }
//                        self.onComplete(.success(image))
//                    }
//                }
//            } else {
//                // Если загрузить нельзя — возвращаем ошибку
//                onComplete(.failure(.unsupportedType))
//            }
//        }

///// SwiftUI-обёртка над UIKit-контроллером `PHPickerViewController`
///// Позволяет интегрировать системный фотопикер в SwiftUI-поток
//struct PhotoPickerView: UIViewControllerRepresentable {
//    
//    /// Фильтр для выбора типов медиа (по умолчанию — только изображения)
//    var filter: PHPickerFilter = .images
//    
//    /// Лимит количества выбираемых элементов (по умолчанию — 1)
//    var limit: Int = 1
//    
//    /// Колбэк, который будет вызван после выбора или отмены
//    /// Если пользователь отменил или загрузка не удалась — придёт `nil`
//    var onComplete: (UIImage?) -> Void
//    
//    // MARK: - UIViewControllerRepresentable
//    
//    /// Создаёт и настраивает UIKit-контроллер
//    func makeUIViewController(context: Context) -> PHPickerViewController {
//        // Конфигурация пикера
//        var config = PHPickerConfiguration(photoLibrary: .shared())
//        config.filter = filter                  // показываем только фото
//        config.selectionLimit = limit           // ограничиваем выбор одним элементом
//        
//        // Создаём контроллер с конфигурацией
//        let picker = PHPickerViewController(configuration: config)
//        
//        // Назначаем делегата (через Coordinator)
//        picker.delegate = context.coordinator
//        
//        return picker
//    }
//    
//    /// Обновление контроллера при изменении состояния SwiftUI
//    /// Здесь пусто, так как пикер не зависит от внешних изменений во время показа
//    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
//    
//    /// Создаёт координатор — мост между UIKit-делегатом и SwiftUI
//    func makeCoordinator() -> Coordinator {
//        Coordinator(onComplete: onComplete)
//    }
//    
//    // MARK: - Coordinator
//    
//    /// Класс-координатор, реализующий делегат `PHPickerViewControllerDelegate`
//    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
//        
//        /// Замыкание для передачи результата обратно в SwiftUI
//        let onComplete: (UIImage?) -> Void
//        
//        init(onComplete: @escaping (UIImage?) -> Void) {
//            self.onComplete = onComplete
//        }
//        
//        /// Вызывается, когда пользователь завершил выбор или отменил
//        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
//            // Закрываем пикер (и, как следствие, SwiftUI .sheet)
//            picker.dismiss(animated: true)
//            
//            // Если ничего не выбрано — возвращаем nil
//            guard let provider = results.first?.itemProvider else {
//                onComplete(nil)
//                return
//            }
//            
//            // Проверяем, умеет ли провайдер загружать UIImage
//            if provider.canLoadObject(ofClass: UIImage.self) {
//                // Загружаем объект асинхронно
//                provider.loadObject(ofClass: UIImage.self) { image, error in
//                    // Возвращаем результат на главном потоке (UI-обновления)
//                    DispatchQueue.main.async {
//                        self.onComplete(image as? UIImage)
//                    }
//                }
//            } else {
//                // Если загрузить нельзя — возвращаем nil
//                onComplete(nil)
//            }
//        }
//    }
//}

