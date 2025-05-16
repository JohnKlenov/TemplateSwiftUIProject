//
//  CustomSecureField.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 15.05.25.
//

import SwiftUI
import UIKit

//в данной реализации фокус при нажатии на кнопку не пропадает с TextField Password но возникла проблема с тем что при вводе большого текста все rootView CreateAccountView растягивается за пределы экрана! и у нас проблемы с высотой VStack Password

///Да, ты правильно заметил: из-за того, что мы условно переключаем между двумя разными представлениями (TextField и SecureField), SwiftUI фактически пересоздаёт представление, и фокус теряется,
///Создание обёртки на базе UIKit: Более надёжным решением является создание собственного компонента через UIViewRepresentable, который оборачивает UITextField. В UIKit можно переключать вариант безопасного ввода, изменяя свойство isSecureTextEntry у одного и того же текстового поля, при этом фокус не сбрасывается, так как представление не пересоздаётся. Ниже приведён пример такой обёртки:



// Обёртка для UITextField, позволяющая переключать режим secure ввода без пересоздания представления
struct CustomSecureField: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String
    var isSecure: Bool
    var font: UIFont?
    
    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: CustomSecureField
        
        init(parent: CustomSecureField) {
            self.parent = parent
        }
        
        func textFieldDidChangeSelection(_ textField: UITextField) {
            // Обновляем привязанный текст
            parent.text = textField.text ?? ""
        }
    }
    
    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.placeholder = placeholder
        textField.isSecureTextEntry = isSecure
        textField.delegate = context.coordinator
//        textField.borderStyle = .roundedRect
        textField.autocapitalizationType = .none
        textField.backgroundColor = UIColor.clear
        if let f = font {
            textField.font = f
        }
        return textField
    }
    
    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.text = text
        // Меняем secure режим динамически без пересоздания view
        if uiView.isSecureTextEntry != isSecure {
            let wasFirstResponder = uiView.isFirstResponder
            uiView.resignFirstResponder()
            uiView.isSecureTextEntry = isSecure
            if wasFirstResponder {
                uiView.becomeFirstResponder()
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
}



// MARK: - Example View
//import SwiftUI
//
//struct CreateAccountView: View {
//    @State private var username: String = ""
//    @State private var email: String = ""
//    @State private var password: String = ""
//    // Новое состояние для переключения видимости пароля
//    @State private var isPasswordVisible: Bool = false
//    
//    var body: some View {
//        NavigationStack {
//            VStack(spacing: 20) {
//                // Заголовок экрана
//                Text("Создать аккаунт")
//                    .font(.largeTitle)
//                    .fontWeight(.bold)
//                    .padding(.top, 20)
//                
//                // Форма регистрации с метками
//                VStack(spacing: 15) {
//                    // Поле "Имя"
//                    VStack(alignment: .leading, spacing: 5) {
//                        Text("Имя")
//                            .font(.subheadline)
//                            .foregroundColor(AppColors.primary)
//                        TextField("Введите имя", text: $username)
//                            .padding()
//                            .background(Color.gray.opacity(0.1))
//                            .cornerRadius(8)
//                            .autocapitalization(.none)
//                    }
//                    
//                    // Поле "Email"
//                    VStack(alignment: .leading, spacing: 5) {
//                        Text("Email")
//                            .font(.subheadline)
//                            .foregroundColor(AppColors.primary)
//                        TextField("Введите email", text: $email)
//                            .padding()
//                            .background(Color.gray.opacity(0.1))
//                            .cornerRadius(8)
//                            .keyboardType(.emailAddress)
//                            .autocapitalization(.none)
//                    }
//                    
//                    // Поле "Пароль" с кнопкой "eye" для переключения видимости
//                    VStack(alignment: .leading, spacing: 5) {
//                        Text("Пароль")
//                            .font(.subheadline)
//                            .foregroundColor(.blue)
//                        CustomSecureField(
//                            text: $password,
//                            placeholder: "Введите пароль",
//                            isSecure: !isPasswordVisible,
//                            font: UIFont.systemFont(ofSize: 17)
//                        )
//                        .frame(height: 44)
//                        .overlay(
//                            HStack {
//                                Spacer()
//                                Button(action: {
//                                    isPasswordVisible.toggle()
//                                }) {
//                                    Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
//                                        .foregroundColor(.gray)
//                                        .padding(.trailing, 12)
//                                }
//                            }
//                        )
//                        .padding() // эквивалентно отступу во всех направлениях — можно настроить по аналогии с другими полями
//                        .background(Color.gray.opacity(0.1))
//                        .cornerRadius(8)
//                    }
//
//                }
//                .padding(.horizontal)
//                
//                // Кнопка регистрации
//                Button(action: {
//                    // Обработка регистрации пользователя
//                }, label: {
//                    Text("Зарегистрироваться")
//                        .fontWeight(.semibold)
//                        .frame(maxWidth: .infinity)
//                        .padding()
//                        .background(Color.purple)
//                        .foregroundColor(.white)
//                        .cornerRadius(8)
//                })
//                .padding(.horizontal)
//                
//                // Разделитель между регистрацией и альтернативными способами входа
//                HStack {
//                    VStack { Divider().frame(height: 1).background(Color.primary) }
//                    Text("ИЛИ")
//                        .font(.footnote)
//                        .foregroundColor(.primary)
//                    VStack { Divider().frame(height: 1).background(Color.primary) }
//                }
//                .padding([.horizontal, .vertical])
//                
//                // Блок альтернативной регистрации
//                HStack(spacing: 40) {
//                    // Кнопка регистрации через Apple
//                    Button(action: {
//                        // Реализуйте регистрацию через Apple
//                    }) {
//                        Image(systemName: "applelogo")
//                            .resizable()
//                            .scaledToFit()
//                            .frame(width: 30, height: 30)
//                            .padding()
//                            .tint(AppColors.primary)
//                            .clipShape(Circle())
//                            .overlay(Circle().stroke(Color.gray, lineWidth: 1))
//                    }
//                    
//                    // Кнопка регистрации через Google
//                    Button(action: {
//                        // Реализуйте регистрацию через Google
//                    }) {
//                        Image("googlelogo")
//                            .resizable()
//                            .scaledToFit()
//                            .frame(width: 30, height: 30)
//                            .padding()
//                            .clipShape(Circle())
//                            .overlay(Circle().stroke(Color.gray, lineWidth: 1))
//                    }
//                }
//                .padding(.vertical, 10)
//                
//                // Ссылка для входа
//                HStack {
//                    Text("Уже есть аккаунт?")
//                    Button(action: {
//                        // Переход на экран входа
//                    }) {
//                        Text("Войти")
//                            .foregroundColor(.blue)
//                            .fontWeight(.semibold)
//                    }
//                }
//                .padding(.bottom, 20)
//            }
//            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
//            .navigationBarTitleDisplayMode(.inline)
//        }
//    }
//}
//
//struct CreateAccountView_Previews: PreviewProvider {
//    static var previews: some View {
//        Group {
//            CreateAccountView()
//                .previewDevice("iPhone 12")
//            CreateAccountView()
//                .previewDevice("iPhone SE (2nd generation)")
//        }
//    }
//}
