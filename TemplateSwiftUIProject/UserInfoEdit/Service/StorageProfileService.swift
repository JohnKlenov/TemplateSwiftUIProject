//
//  StorageProfileService.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 27.08.25.
//

/*
 Сценарии:
 1) Успех:
    - putData(data) завершился без ошибок
    - downloadURL получен
    - Возвращаем URL через .success
    - Никаких алертов

 2) Ошибка во время putData:
    - handleStorageError(error, operationDescription) покажет глобальный алерт
    - Возвращаем .failure(error)

 3) Ошибка получения downloadURL:
    - handleStorageError(error, operationDescription) покажет глобальный алерт
    - Возвращаем .failure(error)

 4) downloadURL == nil (неконсистентное состояние):
    - handleStorageError(FirebaseInternalError.nilSnapshot, operationDescription) покажет глобальный алерт
    - Возвращаем .failure(FirebaseInternalError.nilSnapshot)
*/

import FirebaseStorage
import Combine
import UIKit

protocol StorageProfileServiceProtocol {
    func uploadImageData(path: String, data: Data, operationDescription: String) -> AnyPublisher<URL, Error>
    func deleteImage(at url: URL, operationDescription: String) -> AnyPublisher<Void, Error>

}

final class StorageProfileService: StorageProfileServiceProtocol {
    
    private let storage = Storage.storage()
    private let errorHandler: ErrorHandlerProtocol = SharedErrorHandler()
    private let alertManager: AlertManager = .shared
    
    ///putData(data) — загрузка файла в Storage - Если интернет отсутствует:Firebase сразу вернёт ошибку в completion блоке
    ///Если интернет есть, но очень плохой: Загрузка может зависнуть, затем завершиться ошибкой по таймауту.
    ///downloadURL — получение ссылки после загрузки Если putData прошёл, но интернет пропал перед downloadURL: Получишь ошибку в блоке Не использует локальный кэш — всегда требует соединения с интернетом. Если интернет есть, но слабый или нестабильный: Запрос может «зависнуть» на некоторое время — Firebase SDK будет пытаться установить соединение.Запрос может «зависнуть» на некоторое время — Firebase SDK будет пытаться установить соединение.
    func uploadImageData(path: String, data: Data, operationDescription: String) -> AnyPublisher<URL, Error> {
        Future<URL, Error> { [weak self] promise in
            guard let self = self else { return }
            
            let ref = storage.reference(withPath: path)
            
            ref.putData(data, metadata: nil) { _, error in
                if let error = error {
                    self.handleStorageError(error, operationDescription: operationDescription)
                    promise(.failure(error))
                    return
                }
                
                ref.downloadURL { url, error in
                    if let error = error {
                        self.handleStorageError(error, operationDescription: operationDescription)
                        promise(.failure(error))
                        return
                    }
                    guard let url = url else {
                        let err = FirebaseInternalError.nilSnapshot
                        self.handleStorageError(err, operationDescription: operationDescription)
                        promise(.failure(err))
                        return
                    }
                    promise(.success(url))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func deleteImage(at url: URL, operationDescription: String) -> AnyPublisher<Void, Error> {
        Future<Void, Error> { [weak self] promise in
            guard let self else { return }

            let ref = storage.reference(forURL: url.absoluteString)
            ref.delete { error in
                if let error = error {
                    self.handleStorageError(error, operationDescription: operationDescription)
                    promise(.failure(error))
                } else {
                    promise(.success(()))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    
    private func handleStorageError(_ error: Error, operationDescription: String) {
        let message = errorHandler.handle(error: error)
        alertManager.showGlobalAlert(message: message, operationDescription: operationDescription, alertType: .ok)
    }
}

