//
//  PhotoPickerError.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 25.08.25.
//

//    /// Нет доступного элемента (например, пользователь выбрал фото, которое уже удалено)
//    case noItemAvailable
//
//    /// Элемент недоступен для загрузки (например, повреждённый файл)
//    case itemUnavailable
//
//    /// Неподдерживаемый тип медиа (например, выбрано видео при фильтре `.images`)
//    case unsupportedType
//
//    /// Доступ к фото запрещён пользователем
//    case accessDenied
//
//    /// Доступ к фото ограничен политикой устройства (например, родительский контроль)
//    case accessRestricted
//
//    /// Фото находится в iCloud и требует подключения к сети
//    case iCloudRequired
//
//    /// Ошибка загрузки (с сохранением оригинальной ошибки)
//    case loadFailed(Error)
//
//    /// Неизвестная ошибка (с сохранением оригинальной ошибки)
//    case unknown(Error)
//


import Foundation
import Photos
import UniformTypeIdentifiers

// MARK: - Ошибки фотопикера

enum PhotoPickerError: Error {
    case noItemAvailable /// Нет доступного элемента (например, пользователь выбрал фото, которое уже удалено)
    case itemUnavailable /// Элемент недоступен для загрузки (например, повреждённый файл)
    case unsupportedType /// Неподдерживаемый тип медиа (например, выбрано видео при фильтре `.images`)
    case iCloudRequired /// Фото находится в iCloud и требует подключения к сети
    case loadFailed(Error) /// Ошибка загрузки (с сохранением оригинальной ошибки)
    case unknown(Error) /// Неизвестная ошибка (с сохранением оригинальной ошибки)
}

// MARK: - Mapping системных ошибок → PhotoPickerError

extension PhotoPickerError {

    static func map(_ error: Error) -> PhotoPickerError {
        let nsError = error as NSError

        switch nsError.domain {
            // 📌 Домен NSItemProvider.errorDomain
            // Ошибки, связанные с передачей/загрузкой данных через NSItemProvider.
            // Используется в API вроде PHPicker, drag & drop, share extensions.
            // Здесь могут быть коды, означающие, что элемент недоступен или не может быть загружен.
        case NSItemProvider.errorDomain:
            switch nsError.code {
            case -1000:
                return .noItemAvailable // Исторический код: элемент отсутствует
            case -1001:
                return .itemUnavailable // Исторический код: элемент есть, но его нельзя загрузить
            default:
                return .loadFailed(error) // Любая другая ошибка NSItemProvider
            }

        case PHPhotosErrorDomain:
            // 📌 Домен PHPhotosErrorDomain
            // Ошибки, возвращаемые фреймворком Photos (PhotoKit).
            // Обычно возникают при работе с медиа в библиотеке пользователя.
            // Для PHPicker из публичных кейсов полезен только .networkAccessRequired.
            if let code = PHPhotosError.Code(rawValue: nsError.code) {
                switch code {
                case .networkAccessRequired:
                    return .iCloudRequired // Фото в iCloud, нужно скачать (требуется сеть)
                default:
                    return .loadFailed(error)
                }
            }
            return .loadFailed(error)

        case NSCocoaErrorDomain:
            // 📌 Домен NSCocoaErrorDomain
            // Общие Cocoa-ошибки (Foundation/AppKit/UIKit).
            // Могут возникать при работе с файлами, сериализацией, доступом к ресурсам.
            return .loadFailed(error)

        default:
            // 📌 Любой другой домен
            // Ошибка не из известных нам категорий — считаем её неизвестной.
            return .unknown(error)
        }
    }
}

// MARK: - Техническое описание (для Crashlytics)

extension PhotoPickerError {
    var technicalDescription: String {
        switch self {
        case .noItemAvailable:
            return "Selected item is not available"
        case .itemUnavailable:
            return "Item exists but cannot be loaded"
        case .unsupportedType:
            return "Unsupported media type"
        case .iCloudRequired:
            return "Photo requires iCloud download"
        case .loadFailed(let underlying):
            return "Failed to load image: \(underlying.localizedDescription)"
        case .unknown(let underlying):
            return "Unknown photo picker error: \(underlying.localizedDescription)"
        }
    }
}

// MARK: - NSError совместимость (для Crashlytics)

extension PhotoPickerError: CustomNSError {

    static var errorDomain: String { "com.yourapp.photoPicker" }

    var errorCode: Int {
        switch self {
        case .noItemAvailable: return 1
        case .itemUnavailable: return 2
        case .unsupportedType: return 3
        case .iCloudRequired: return 4
        case .loadFailed: return 5
        case .unknown: return 6
        }
    }

    var errorUserInfo: [String : Any] {
        [
            NSLocalizedDescriptionKey: self.technicalDescription
        ]
    }
}



// MARK: - before technicalDescription


//import SwiftUI
//import PhotosUI
//import Photos
//import UniformTypeIdentifiers
//
//
//// MARK: - Ошибки фотопикера
//
//enum PhotoPickerError: Error {
//    case noItemAvailable /// Нет доступного элемента (например, пользователь выбрал фото, которое уже удалено)
//    case itemUnavailable /// Элемент недоступен для загрузки (например, повреждённый файл)
//    case unsupportedType /// Неподдерживаемый тип медиа (например, выбрано видео при фильтре `.images`)
//    case iCloudRequired /// Фото находится в iCloud и требует подключения к сети
//    case loadFailed(Error) /// Ошибка загрузки (с сохранением оригинальной ошибки)
//    case unknown(Error) /// Неизвестная ошибка (с сохранением оригинальной ошибки)
//}
//
//extension PhotoPickerError {
//
//    static func map(_ error: Error) -> PhotoPickerError {
//        let nsError = error as NSError
//
//        switch nsError.domain {
//        case NSItemProvider.errorDomain:
//            // 📌 Домен NSItemProvider.errorDomain
//            // Ошибки, связанные с передачей/загрузкой данных через NSItemProvider.
//            // Используется в API вроде PHPicker, drag & drop, share extensions.
//            // Здесь могут быть коды, означающие, что элемент недоступен или не может быть загружен.
//            switch nsError.code {
//            case -1000:
//                return .noItemAvailable   // Исторический код: элемент отсутствует
//            case -1001:
//                return .itemUnavailable   // Исторический код: элемент есть, но его нельзя загрузить
//            default:
//                return .loadFailed(error) // Любая другая ошибка NSItemProvider
//            }
//
//        case PHPhotosErrorDomain:
//            // 📌 Домен PHPhotosErrorDomain
//            // Ошибки, возвращаемые фреймворком Photos (PhotoKit).
//            // Обычно возникают при работе с медиа в библиотеке пользователя.
//            // Для PHPicker из публичных кейсов полезен только .networkAccessRequired.
//            if let code = PHPhotosError.Code(rawValue: nsError.code) {
//                switch code {
//                case .networkAccessRequired:
//                    return .iCloudRequired // Фото в iCloud, нужно скачать (требуется сеть)
//                default:
//                    return .loadFailed(error)
//                }
//            }
//            return .loadFailed(error)
//
//        case NSCocoaErrorDomain:
//            // 📌 Домен NSCocoaErrorDomain
//            // Общие Cocoa-ошибки (Foundation/AppKit/UIKit).
//            // Могут возникать при работе с файлами, сериализацией, доступом к ресурсам.
//            return .loadFailed(error)
//
//        default:
//            // 📌 Любой другой домен
//            // Ошибка не из известных нам категорий — считаем её неизвестной.
//            return .unknown(error)
//        }
//    }
//}











//import SwiftUI
//import PhotosUI
//import Photos
//import UniformTypeIdentifiers
//
//// MARK: - Ошибки фотопикера
//
//enum PhotoPickerError: Error {
//    case noItemAvailable
//    case itemUnavailable
//    case unsupportedType
//    case iCloudRequired
//    case loadFailed(Error)
//    case unknown(Error)
//}
//
//extension PhotoPickerError {
//    var localizedDescription: String {
//        switch self {
//        case .noItemAvailable:
//            return "Выбранный элемент недоступен."
//        case .itemUnavailable:
//            return "Элемент нельзя загрузить."
//        case .unsupportedType:
//            return "Неподдерживаемый тип медиа."
//        case .iCloudRequired:
//            return "Требуется подключение к сети для загрузки из iCloud."
//        case .loadFailed(let error), .unknown(let error):
//            return (error as NSError).localizedDescription
//        }
//    }
//
//    static func map(_ error: Error) -> PhotoPickerError {
//        let nsError = error as NSError
//
//        switch nsError.domain {
//        case NSItemProvider.errorDomain:
//            // Магические коды из старого NSItemProviderError
//            switch nsError.code {
//            case -1000:
//                return .noItemAvailable
//            case -1001:
//                return .itemUnavailable
//            default:
//                return .loadFailed(error)
//            }
//
//        case PHPhotosErrorDomain:
//            if let code = PHPhotosError.Code(rawValue: nsError.code) {
//                switch code {
//                case .networkAccessRequired:
//                    return .iCloudRequired
//                default:
//                    return .loadFailed(error)
//                }
//            }
//            return .loadFailed(error)
//
//        case NSCocoaErrorDomain:
//            return .loadFailed(error)
//
//        default:
//            return .unknown(error)
//        }
//    }
//}




//import Foundation
//import PhotosUI
//import Photos
//
///// Ошибки, которые имеет смысл поверхностно нормализовать при работе с PHPicker/NSItemProvider
//enum PhotoPickerError: Error {
//    case noItemAvailable
//    case itemUnavailable
//    case unsupportedType           // выставляй вручную при несоответствии ожидаемому UTType
//    case iCloudRequired
//    case loadFailed(Error)
//    case unknown(Error)
//}
//
//extension PhotoPickerError {
//    var localizedDescription: String {
//        switch self {
//        case .noItemAvailable:
//            return "Выбранный элемент недоступен."
//        case .itemUnavailable:
//            return "Элемент нельзя загрузить."
//        case .unsupportedType:
//            return "Неподдерживаемый тип медиа."
//        case .iCloudRequired:
//            return "Требуется подключение к сети для загрузки из iCloud."
//        case .loadFailed(let error), .unknown(let error):
//            return (error as NSError).localizedDescription
//        }
//    }
//
//    /// Нормализуем системные ошибки в кейсы PhotoPickerError
//    static func map(_ error: Error) -> PhotoPickerError {
//        let nsError = error as NSError
//
//        switch nsError.domain {
//        // Современное имя домена: NSItemProvider.errorDomain
//        case NSItemProvider.errorDomain:
//            if let code = NSItemProvider.ErrorCode(rawValue: nsError.code) {
//                switch code {
//                case .noItemAvailable:
//                    return .noItemAvailable
//                case .itemUnavailable:
//                    return .itemUnavailable
//                default:
//                    return .loadFailed(error)
//                }
//            }
//            return .loadFailed(error)
//
//        // Домен PhotoKit: PHPhotosErrorDomain
//        case PHPhotosErrorDomain:
//            if let code = PHPhotosError.Code(rawValue: nsError.code) {
//                switch code {
//                case .networkAccessRequired:
//                    return .iCloudRequired
//                default:
//                    return .loadFailed(error)
//                }
//            }
//            return .loadFailed(error)
//
//        case NSCocoaErrorDomain:
//            return .loadFailed(error)
//
//        default:
//            return .unknown(error)
//        }
//    }
//}








//import Foundation
//import PhotosUI
//
///// Возможные ошибки при работе с системным фотопикером
//enum PhotoPickerError: Error, Equatable {
//    
//    // MARK: - Коды ошибок
//    
//    /// Нет доступного элемента (например, пользователь выбрал фото, которое уже удалено)
//    case noItemAvailable
//    
//    /// Элемент недоступен для загрузки (например, повреждённый файл)
//    case itemUnavailable
//    
//    /// Неподдерживаемый тип медиа (например, выбрано видео при фильтре `.images`)
//    case unsupportedType
//    
//    /// Доступ к фото запрещён пользователем
//    case accessDenied
//    
//    /// Доступ к фото ограничен политикой устройства (например, родительский контроль)
//    case accessRestricted
//    
//    /// Фото находится в iCloud и требует подключения к сети
//    case iCloudRequired
//    
//    /// Ошибка загрузки (с сохранением оригинальной ошибки)
//    case loadFailed(Error)
//    
//    /// Неизвестная ошибка (с сохранением оригинальной ошибки)
//    case unknown(Error)
//    
//    // MARK: - Локализованное описание
//    
//    var localizedDescription: String {
//        switch self {
//        case .noItemAvailable:
//            return "Выбранный элемент недоступен."
//        case .itemUnavailable:
//            return "Изображение не может быть загружено."
//        case .unsupportedType:
//            return "Выбран неподдерживаемый тип медиа."
//        case .accessDenied:
//            return "Доступ к фото запрещён."
//        case .accessRestricted:
//            return "Доступ к фото ограничен политикой устройства."
//        case .iCloudRequired:
//            return "Изображение находится в iCloud и требует подключения к сети."
//        case .loadFailed(let error), .unknown(let error):
//            return error.localizedDescription
//        }
//    }
//    
//    // MARK: - Маппинг системных ошибок в PhotoPickerError
//    
//    /// Преобразует системную ошибку в один из кейсов PhotoPickerError
//    static func map(_ error: Error) -> PhotoPickerError {
//        let nsError = error as NSError
//        
//        switch (nsError.domain, nsError.code) {
//            
//        // Ошибки NSItemProvider
//        case (NSItemProviderErrorDomain, NSItemProviderError.noItemAvailable.rawValue):
//            return .noItemAvailable
//            
//        case (NSItemProviderErrorDomain, NSItemProviderError.itemUnavailable.rawValue):
//            return .itemUnavailable
//            
//        // Ошибки PHPhotos
//        case (PHPhotosErrorDomain, PHPhotosError.accessDenied.rawValue):
//            return .accessDenied
//            
//        case (PHPhotosErrorDomain, PHPhotosError.accessRestricted.rawValue):
//            return .accessRestricted
//            
//        case (PHPhotosErrorDomain, PHPhotosError.networkAccessRequired.rawValue):
//            return .iCloudRequired
//            
//        // Общие Cocoa-ошибки
//        case (NSCocoaErrorDomain, _):
//            return .loadFailed(error)
//            
//        // Остальные — неизвестные
//        default:
//            return .unknown(error)
//        }
//    }
//}
//
