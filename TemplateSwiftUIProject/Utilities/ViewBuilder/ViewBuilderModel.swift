//
//  ViewBuilderModel.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 5.02.25.
//

import SwiftUI

///В твоем коде, HomeFlow используется в качестве значения в NavigationPath, что требует соответствия протоколам Hashable и Equatable.
///NavigationPath использует хэширование для хранения и отслеживания пути. Это означает, что типы значений, передаваемые в NavigationPath, должны быть Hashable и Equatable.
///Протокол Equatable используется для сравнения экземпляров одного и того же типа. Если тип соответствует Equatable, это означает, что экземпляры этого типа можно сравнивать с помощью оператора ==.
///Протокол Hashable используется для создания хэш-кода для объекта. Если тип соответствует Hashable, это означает, что экземпляры этого типа можно хэшировать, что требуется для использования в структурах данных, таких как словари и множества.


enum HomeFlow: Hashable {
    case home
    case bookDetails(BookCloud)
    case someHomeView

    static func == (lhs: HomeFlow, rhs: HomeFlow) -> Bool {
        switch (lhs, rhs) {
        case (.home, .home), (.someHomeView, .someHomeView):
            return true
        case (.bookDetails(let lhsBook), .bookDetails(let rhsBook)):
            // Если хочется сравнить только по id (если не nil) или по другому
            if let lhsId = lhsBook.id, let rhsId = rhsBook.id {
                return lhsId == rhsId
            }
            return lhsBook == rhsBook
        default:
            return false
        }
    }

    func hash(into hasher: inout Hasher) {
        switch self {
        case .home:
            hasher.combine("home")
        case .someHomeView:
            hasher.combine("someHomeView")
        case .bookDetails(let book):
            // Если id присутствует, хешируем его, иначе всю структуру
            if let id = book.id {
                hasher.combine(id)
            } else {
                hasher.combine(book)
            }
        }
    }
}


enum GalleryFlow: Hashable, Equatable {
    case gallery
    case someHomeView
    static func == (lhs: GalleryFlow, rhs: GalleryFlow) -> Bool {
        switch (lhs, rhs) {
        case (.gallery, .gallery), (.someHomeView, .someHomeView):
            return true
        default:
            return false
        }
    }
        
        func hash(into hasher: inout Hasher) {
            switch self {
            case .gallery:
                hasher.combine("gallery")
            case .someHomeView:
                hasher.combine("someHomeView")
            }
        }
}

// before case .userInfoEdit(let profile):

//enum AccountFlow: Hashable {
//    case account
//    case userInfo
//    case language
//    case aboutUs
//    case createAccount
//    case login
//    case reauthenticate   // ← новый кейс
//
//    static func == (lhs: AccountFlow, rhs: AccountFlow) -> Bool {
//        switch (lhs, rhs) {
//        case (.account, .account),
//             (.userInfo, .userInfo),
//             (.language, .language),
//             (.aboutUs, .aboutUs),
//             (.createAccount, .createAccount),
//             (.login, .login),
//             (.reauthenticate, .reauthenticate):
//            return true
//        default:
//            return false
//        }
//    }
//
//    func hash(into hasher: inout Hasher) {
//        switch self {
//        case .account: hasher.combine("account")
//        case .userInfo: hasher.combine("userInfo")
//        case .language: hasher.combine("language")
//        case .aboutUs: hasher.combine("aboutUs")
//        case .createAccount: hasher.combine("createAccount")
//        case .login: hasher.combine("login")
//        case .reauthenticate: hasher.combine("reauthenticate")
//        }
//    }
//}

enum AccountFlow: Hashable {
    case account
    case userInfo
    case language
    case aboutUs
    case createAccount
    case login
    case reauthenticate
    case userInfoEdit(UserProfile)

    static func == (lhs: AccountFlow, rhs: AccountFlow) -> Bool {
        switch (lhs, rhs) {
        case (.account, .account),
             (.userInfo, .userInfo),
             (.language, .language),
             (.aboutUs, .aboutUs),
             (.createAccount, .createAccount),
             (.login, .login),
             (.reauthenticate, .reauthenticate):
            return true
        case (.userInfoEdit(let lhsProfile), .userInfoEdit(let rhsProfile)):
            return lhsProfile.uid == rhsProfile.uid
        default:
            return false
        }
    }

    func hash(into hasher: inout Hasher) {
        switch self {
        case .account: hasher.combine("account")
        case .userInfo: hasher.combine("userInfo")
        case .language: hasher.combine("language")
        case .aboutUs: hasher.combine("aboutUs")
        case .createAccount: hasher.combine("createAccount")
        case .login: hasher.combine("login")
        case .reauthenticate: hasher.combine("reauthenticate")
        case .userInfoEdit(let profile):
            hasher.combine("userInfoEdit")
            hasher.combine(profile.uid)
        }
    }
}


// before case .reauthenticate

//enum AccountFlow: Hashable {
//    case account
//    case userInfo
//    case language
//    case aboutUs
//    case createAccount
//    case login
//
//    static func == (lhs: AccountFlow, rhs: AccountFlow) -> Bool {
//        switch (lhs, rhs) {
//        case (.account, .account),
//            (.userInfo, .userInfo),
//            (.language, .language),
//            (.aboutUs, .aboutUs),
//            (.createAccount, .createAccount),
//            (.login, .login):
//            return true
//        default:
//            return false
//        }
//    }
//
//    
//    func hash(into hasher: inout Hasher) {
//        switch self {
//        case .userInfo:
//            hasher.combine("userInfo")
//        case .language:
//            hasher.combine("language")
//        case .aboutUs:
//            hasher.combine("aboutUs")
//        case .createAccount:
//            hasher.combine("createAccount")
//        case .account:
//            hasher.combine("account")
//        case .login:
//            hasher.combine("login")
//        }
//    }
//}


struct SheetItem: Identifiable {
    var id = UUID()
    var content: AnyView
}

struct FullScreenItem: Identifiable {
    var id = UUID()
    var content: AnyView
}


// MARK: - Cancel HomeBookDataStore

//enum HomeFlow: Hashable, Equatable {
//    case home
//    case bookDetails(String) // Передаем ID книги
//    case someHomeView
//
//    static func == (lhs: HomeFlow, rhs: HomeFlow) -> Bool {
//        switch (lhs, rhs) {
//        case (.home, .home), (.someHomeView, .someHomeView):
//            return true
//        case (.bookDetails(let lhsBook), .bookDetails(let rhsBook)):
//            return lhsBook == rhsBook
//        default:
//            return false
//        }
//    }
//
//    func hash(into hasher: inout Hasher) {
//        switch self {
//        case .home:
//            hasher.combine("home")
//        case .someHomeView:
//            hasher.combine("someHomeView")
//        case .bookDetails(let bookID):
//            hasher.combine(bookID)
//        }
//    }
//}


//enum GalleryFlow: Hashable, Equatable {
//    case gallery
//
//    static func == (lhs: GalleryFlow, rhs: GalleryFlow) -> Bool {
//        switch (lhs, rhs) {
//        case (.gallery, .gallery):
//            return true
//        }
//    }
//
//    func hash(into hasher: inout Hasher) {
//        switch self {
//        case .gallery:
//            hasher.combine("gallery")
//        }
//    }
//}
