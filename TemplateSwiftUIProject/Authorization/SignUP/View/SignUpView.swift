//
//  SignUpView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 14.05.25.
//

// TextField magic
///https://habr.com/ru/articles/815685/
///https://github.com/C5FR7Q/x-text-field/blob/main/x-text-field/Playground/FocusHolderView.swift


//VStack "Password"
///Приведённое решение с использованием HStack, где мы рядом размещаем текстовое поле (или SecureField) и кнопку-переключатель, — лишь один из вариантов реализации. Можно также использовать ZStack или модификатор .overlay, чтобы наложить кнопку на текстовое поле. Такой подход позволяет визуально разместить кнопку "eye" непосредственно поверх поля ввода, что может выглядеть более компактно или органично с точки зрения дизайна.
/////в данной реализации фокус при нажатии на кнопку eye пропадает с TextField Password! Мы пока опустили эту реализацию! часть работы есть в CustomSecureField.swift

//Intrinsic Content Size у TextField и SecureField немного отличается, и при переключении видно изменение высоты.

//keyboard

///Это стандартное поведение iOS/SwiftUI. Когда клавиатура появляется, система автоматически сдвигает содержимое, чтобы активное поле ввода (например, TextField) оставалось видимым и не оказалось скрытым за клавиатурой. Этот механизм помогает пользователю видеть то, что он вводит, без необходимости вручную прокручивать или нажимать на экран.
///Если тебе не нравится такое поведение, можно попытаться отключить автоматическую адаптацию safe area для клавиатуры, используя, например, модификатор:
///.ignoresSafeArea(.keyboard, edges: .bottom)
///Но будь осторожен — это может привести к тому, что поле ввода окажется скрытым клавиатурой на некоторых устройствах.
///Form + keyboard
///Когда ты размещаешь TextField внутри контейнера Form, SwiftUI оборачивает его в scrollable контейнер (основанный на UIKit‑таблице или scroll view), который автоматически корректирует отступы и скроллит содержимое так, чтобы активное поле всегда оставалось видимым, без резкого "подъёма" всего контента.
///То есть, в отличие от простой вёрстки с использованием VStack (где открытие клавиатуры сдвигает весь view наверх), Form обеспечивает более «умное» поведение: он автоматически скроллит нужное поле, сохраняя общую структуру интерфейса. Это делает работу с клавиатурой более естественной и позволяет избежать визуальных сдвигов всей вёрстки.


import SwiftUI

enum FieldToFocus: Hashable , CaseIterable {
    case nameField, emailField, securePasswordField, passwordField
}

struct CreateAccountView: View {
    @State private var username: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    // Новое состояние для переключения видимости пароля
    @State private var isPasswordVisible: Bool = false
    @FocusState var isFieldFocus: FieldToFocus?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Заголовок экрана
                Text("Создать аккаунт")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 20)
                
                // Форма регистрации с метками
                VStack(spacing: 15) {
                    // Поле "Имя"
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Имя")
                            .font(.subheadline)
                            .foregroundColor(AppColors.primary)
                        TextField("Введите имя", text: $username)
                            .submitLabel(.next)
                            .focused($isFieldFocus, equals: .nameField)
                            .onSubmit { focusNextField() }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                            .autocapitalization(.none)
                    }
                    
                    // Поле "Email"
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Email")
                            .font(.subheadline)
                            .foregroundColor(AppColors.primary)
                        TextField("Введите email", text: $email)
                            .submitLabel(.next)
                            .focused($isFieldFocus, equals: .emailField)
                            .onSubmit { focusNextField() }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                    }
                    
                    // Поле "Пароль" с кнопкой "eye" для переключения видимости
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Пароль")
                            .font(.subheadline)
                            .foregroundColor(AppColors.primary)
                        HStack {
                            Group {
                                if isPasswordVisible {
                                    TextField("Введите пароль", text: $password)
                                        .submitLabel(.done)
                                        .focused($isFieldFocus, equals: .passwordField)
                                        .textContentType(.password)
                                        .onSubmit { focusNextField() }
                                } else {
                                    SecureField("Введите пароль", text: $password)
                                        .submitLabel(.done)
                                        .focused($isFieldFocus, equals: .securePasswordField)
                                        .textContentType(.password)
                                        .onSubmit { focusNextField() }
                                }
                            }
                            // Кнопка-переключатель
                            Button(action: {
                                isPasswordVisible.toggle()
                                isFieldFocus = isPasswordVisible ? .passwordField : .securePasswordField
                            }) {
                                Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }  // End of password field
                }
                .padding(.horizontal)
                
                // Кнопка регистрации
                Button(action: {
                    // Обработка регистрации пользователя
                }, label: {
                    Text("Зарегистрироваться")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                })
                .padding(.horizontal)
                
                // Разделитель между регистрацией и альтернативными способами входа
                HStack {
                    VStack { Divider().frame(height: 1).background(Color.primary) }
                    Text("ИЛИ")
                        .font(.footnote)
                        .foregroundColor(.primary)
                    VStack { Divider().frame(height: 1).background(Color.primary) }
                }
                .padding([.horizontal, .vertical])
                
                // Блок альтернативной регистрации
                HStack(spacing: 40) {
                    // Кнопка регистрации через Apple
                    Button(action: {
                        // Реализуйте регистрацию через Apple
                    }) {
                        Image(systemName: "applelogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                            .padding()
                            .tint(AppColors.primary)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.gray, lineWidth: 1))
                    }
                    
                    // Кнопка регистрации через Google
                    Button(action: {
                        // Реализуйте регистрацию через Google
                    }) {
                        Image("googlelogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                            .padding()
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.gray, lineWidth: 1))
                    }
                }
                .padding(.vertical, 10)
                
                // Ссылка для входа
                HStack {
                    Text("Уже есть аккаунт?")
                    Button(action: {
                        // Переход на экран входа
                    }) {
                        Text("Войти")
                            .foregroundColor(.blue)
                            .fontWeight(.semibold)
                    }
                }
                .padding(.bottom, 20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func focusNextField() {
        switch isFieldFocus {
        case .nameField:
            isFieldFocus = .emailField
        case .emailField:
            isFieldFocus = isPasswordVisible ? .passwordField : .securePasswordField
        case .securePasswordField, .passwordField:
            isFieldFocus = nil
        default:
            isFieldFocus = nil
        }
    }
}

//struct CreateAccountView_Previews: PreviewProvider {
//    static var previews: some View {
//        Group {
//            CreateAccountView()
//                .previewDevice("iPhone 15 Pro")
//            CreateAccountView()
//                .previewDevice("iPhone SE 3rd generation")
//        }
//    }
//}



// MARK: - Code


//var body: some View {
//    // GeometryReader позволяет получать размеры экрана
////        GeometryReader { geometry in
//        // ScrollView помогает избежать обрезания контента на маленьких экранах
////            ScrollView {
//            VStack(spacing: 20) {
//                // Заголовок экрана
//                Text("Создать аккаунт")
//                    .font(.largeTitle)
//                    .fontWeight(.bold)
//                    .padding(.top, 20)
//                
//                // Форма регистрации
//                VStack(spacing: 15) {
//                    TextField("Имя пользователя", text: $username)
//                        .padding()
//                        .background(Color.gray.opacity(0.1))
//                        .cornerRadius(8)
//                        .autocapitalization(.none)
//                    
//                    TextField("Email", text: $email)
//                        .padding()
//                        .background(Color.gray.opacity(0.1))
//                        .cornerRadius(8)
//                        .keyboardType(.emailAddress)
//                        .autocapitalization(.none)
//                    
//                    SecureField("Пароль", text: $password)
//                        .padding()
//                        .background(Color.gray.opacity(0.1))
//                        .cornerRadius(8)
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
//                        .background(Color.pink)
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
//                            .overlay(
//                                Circle().stroke(Color.gray, lineWidth: 1)
//                            )
//                    }
//                    
//                    // Кнопка регистрации через Google
//                    Button(action: {
//                        // Реализуйте регистрацию через Google
//                    }) {
//                        // Создайте в Assets иконку с названием "google" или замените на существующую
//                        Image("googlelogo")
//                            .resizable()
//                            .scaledToFit()
//                            .frame(width: 30, height: 30)
//                            .padding()
//                            .clipShape(Circle())
//                            .overlay(
//                                Circle().stroke(Color.gray, lineWidth: 1)
//                            )
//                    }
//                }
//                .padding(.vertical, 10)
//                
//                // Ссылка для перехода на экран входа
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
//            // Заставляем VStack занимать всю ширину
////                .frame(minWidth: 0, maxWidth: .infinity)
////            }
//        // Устанавливаем ширину ScrollView равной экрану
////            .frame(width: geometry.size.width)
////        }
//}
