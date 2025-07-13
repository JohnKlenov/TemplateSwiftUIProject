//
//  FirestoreProfileService.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 12.07.25.
//

// что мы ловим в блоке catch?

/// Ошибку DecodingError — результат того, что snapshot.data(as:) не смог преобразовать данные Firestore в тип UserProfile. Это может быть:
/// DecodingError.dataCorrupted
/// DecodingError.keyNotFound
/// DecodingError.typeMismatch
/// DecodingError.valueNotFound
/// DecodingError — это не NSError, но если ты приведёшь его к NSError, то получишь - NSCocoaErrorDomain
// let nsError = error as NSError
//print(nsError.domain)
///Ошибка в catch — это DecodingError, с NSError.domain == NSCocoaErrorDomain

// мы можем отлавить эту ошибку в блоке catch двумя способами:

//if nsError.domain == NSCocoaErrorDomain {
//    return handleDecodingError(nsError)
//}

//private func handleDecodingError(_ error: NSError) -> String {
//    switch error.code {
//    case 4864: // типичная ошибка расшифровки JSON
//        return Localized.FirebaseEnternalError.decodingTypeMismatch
//    case 4860:
//        return Localized.FirebaseEnternalError.missingRequiredKey
//    default:
//        return Localized.FirebaseEnternalError.decodingError // fallback
//    }
//}

//или:

//if let decodingError = error as? DecodingError {
//    return handleDecodingError(decodingError)
//}

//private func handleDecodingError(_ error: DecodingError) -> String {
//    switch error {
//    case .typeMismatch(let type, let context):
//        let path = context.codingPath.map(\.stringValue).joined(separator: ".")
//        return "Тип данных не совпадает: ожидали \(type), путь: \(path)"
//        
//    case .valueNotFound(let type, let context):
//        let path = context.codingPath.map(\.stringValue).joined(separator: ".")
//        return "Значение типа \(type) не найдено, путь: \(path)"
//        
//    case .keyNotFound(let key, let context):
//        let path = context.codingPath.map(\.stringValue).joined(separator: ".")
//        return "Отсутствует ключ '\(key.stringValue)', путь: \(path)"
//        
//    case .dataCorrupted(let context):
//        let path = context.codingPath.map(\.stringValue).joined(separator: ".")
//        return "Данные повреждены: \(context.debugDescription), путь: \(path)"
//        
//    @unknown default:
//        return "Неизвестная ошибка расшифровки данных"
//    }
//}

//as NSError + domain - Упрощённую классификацию через NSCocoaErrorDomain, но без деталей
//as? DecodingError  - Доступ к case, codingPath, debugDescription и конкретному типу



import FirebaseFirestore
import Combine

struct UserProfile: Codable {
    let uid: String
    var name: String?
    var email: String?
    var photoURL: URL?
    
    init(uid: String, name: String? = nil, email: String? = nil, photoURL: URL? = nil) {
        self.uid = uid
        self.name = name
        self.email = email
        self.photoURL = photoURL
    }
}


protocol ProfileServiceProtocol {
    func fetchProfile(uid: String) -> AnyPublisher<UserProfile, Error>
    func updateProfile(_ profile: UserProfile) -> AnyPublisher<Void, Error>
}

class FirestoreProfileService: ProfileServiceProtocol {
    
    private let db = Firestore.firestore()
    private let errorHandler: ErrorHandlerProtocol = SharedErrorHandler()
    private let alertManager: AlertManager = AlertManager.shared
    
    func fetchProfile(uid: String) -> AnyPublisher<UserProfile, Error> {
        Future { [weak self] promise in
            self?.db.collection("users").document(uid).getDocument { snapshot, error in
                if let error = error {
                    promise(.failure(error))
                    self?.handleFirestoreError(error, operationDescription: "Error fetch profile")
                    return
                }
                
                do {
                    if let snapshot = snapshot, snapshot.exists {
                        let profile = try snapshot.data(as: UserProfile.self)
                        promise(.success(profile))
                    } else {
                        // Чёткое разделение: документ есть, но пустой vs документ отсутствует
                        promise(.success(UserProfile(uid: uid)))
                    }
                } catch {
                    promise(.failure(error)) // Чёткая ошибка декодирования
                    self?.handleFirestoreError(error, operationDescription: "Error fetch profile")
                }
            }
        }.eraseToAnyPublisher()
    }
    
    func updateProfile(_ profile: UserProfile) -> AnyPublisher<Void, Error> {
        Future { [weak self] promise in
            do {
                try self?.db.collection("users").document(profile.uid).setData(from: profile) { error in
                    if let error = error {
                        promise(.failure(error))
                        self?.handleFirestoreError(error, operationDescription: "Error update profile")
                    } else {
                        promise(.success(()))
                    }
                }
            } catch {
                promise(.failure(error))
                self?.handleFirestoreError(error, operationDescription: "Error update profile")
            }
        }.eraseToAnyPublisher()
    }
    
    private func handleFirestoreError(_ error: Error, operationDescription:String) {
        let errorMessage = errorHandler.handle(error: error)
        alertManager.showGlobalAlert(message: errorMessage, operationDescription: operationDescription, alertType: .ok)
    }
}


//                do {
//                    if let profile = try snapshot?.data(as: UserProfile.self) {
//                        promise(.success(profile))
//                    } else {
//                        // Создаем новый профиль если не найден
//                        let newProfile = UserProfile(uid: uid)
//                        promise(.success(newProfile))
//                    }
//                } catch {
//                    promise(.failure(error))
//                }
