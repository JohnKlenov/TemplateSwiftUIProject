//
//  Book.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 3.11.24.
//

import Foundation
import FirebaseFirestore

///При добавлении нового документа с помощью addDocument(from:), Firestore автоматически генерирует уникальный идентификатор для этого документа(он же будет передан в качестве @DocumentID var id при получении данных).
///Когда вы запрашиваете документы из коллекции books, каждый документ будет содержать поле @DocumentID var id, которое будет заполнено значением сгенерированного идентификатора.
///Если вы задаёте собственный идентификатор для документа при его сохранении, то при последующем получении документа из базы данных, поле @DocumentID var id будет содержать этот идентификатор.


struct Book: Identifiable, Codable {
    @DocumentID var id: String?
    var title: String
    var author: String
    var description: String
    var pathImage: String
}