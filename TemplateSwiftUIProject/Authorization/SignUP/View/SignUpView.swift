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

//ScrollView(.vertical, showsIndicators: false) {..}.ignoresSafeArea(.keyboard)
/// если мы оставим такую запись то при появлении keyboard мы не сможем проскролить все содержимое из под keyboard то есть все что под keyboard будет не видимо для нас!
/// без ignoresSafeArea(.keyboard) мы можем проскролить все что осталось под keyboard и увидеть его над keyboard.

//side effects
///Побочные эффекты (side effects) в iOS-разработке – это изменения состояния, происходящие в результате выполнения функции или метода, которые не отражаются напрямую в её возвращаемом значении. Другими словами, функция с побочным эффектом делает что-то большее, чем просто вычисление и возврат результата; она может изменять глобальную или внешнюю переменную, обновлять UI, сохранять данные, отправлять сетевой запрос и так далее.
///Чистые функции vs. функции с побочными эффектами: Чистая функция вычисляет результат строго на основе входных данных и не изменяет никаких внешних состояний. Функции с побочными эффектами делают что-то дополнительно – изменяют состояние приложения, общаются с сетью, записывают данные в базу, обновляют пользовательский интерфейс и так далее.
///Почему это важно: В iOS-разработке, особенно при использовании SwiftUI, управление состоянием является ключевым аспектом. Когда изменения состояния (например, изменение значений @State или @Published) происходят не в ожидаемый момент или во время расчёта представления, система может выдавать предупреждения (например, «Publishing changes from within view updates is not allowed») и непредсказуемо обновлять UI.
///Разделение чистых функций и побочных эффектов: Хорошей практикой является использование чистых функций для вычислений, а изменение состояния выносить в отдельные обработчики, которые запускаются, например, с помощью модификаторов .onAppear, .onChange или через обработчики событий.
///В iOS-разработке побочные эффекты являются неотъемлемой частью, поскольку практически любое взаимодействие с внешним миром (UI, сеть, хранилище) вызывает изменения состояния. Главное – управлять ими разумно: отделять чистые вычисления от побочных эффектов, обеспечивать предсказуемость и тестируемость кода, особенно в контексте SwiftUI, где порядок и момент обновления состояния критичны для стабильности приложения.

//Button.allowsHitTesting(false)
///Этот модификатор просто отключает возможность клика (или «хита») на элементе, но не меняет его внешнего вида.


// GeometryReader
///Если мы хотим вычислять текущий размер View то можем поместить GeometryReader в его View.background
/// ScrollView.background { GeometryReader { geometry in Color.clear.onAppear{}.onChange{} .. } }


import SwiftUI
import UIKit

// MARK: - Фокусируемые поля
enum FieldToFocus: Hashable, CaseIterable {
    case emailField, securePasswordField, passwordField
}

// MARK: - Основное представление регистрации
struct SignUpView: View {
    // Состояние для переключения видимости пароля
    @State private var isPasswordVisible = false
    @FocusState var isFieldFocus: FieldToFocus?
    
    @StateObject private var viewModel = SignUpViewModel()
    @EnvironmentObject var localization: LocalizationService
    @EnvironmentObject var accountCoordinator:AccountCoordinator
    @EnvironmentObject private var orientationService: DeviceOrientationService
    
    var body: some View {
 
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    // Форма регистрации
                    VStack(spacing: 15) {
                        // Поле "Email"
                        VStack(alignment: .leading, spacing: 5) {
                            Text(Localized.SignUpView.email.localized())
                                .font(.subheadline)
                                .foregroundColor(AppColors.primary)
                            TextField(Localized.SignUpView.emailPlaceholder.localized(), text: $viewModel.email)
                                .submitLabel(.next)
                                .focused($isFieldFocus, equals: .emailField)
                                .onSubmit { focusNextField() }
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                                .keyboardType(.emailAddress)
                                .disableAutocorrection(true)
                                .autocapitalization(.none)
                            // При тапе очищается ошибка
                                .onTapGesture {
                                    viewModel.emailError = nil
                                }
                            if let error = viewModel.emailError {
                                Text(error.localized())
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        
                        // Поле "Пароль" с кнопкой-переключателем "eye"
                        VStack(alignment: .leading, spacing: 5) {
                            Text(Localized.SignUpView.password.localized())
                                .font(.subheadline)
                                .foregroundColor(AppColors.primary)
                            HStack {
                                Group {
                                    if isPasswordVisible {
                                        TextField(Localized.SignUpView.passwordPlaceholder.localized(), text: $viewModel.password)
                                            .submitLabel(.done)
                                            .focused($isFieldFocus, equals: .passwordField)
                                            .textContentType(.password)
                                            .autocapitalization(.none)
                                            .disableAutocorrection(true)
                                            .onSubmit { focusNextField() }
                                            .onChange(of: viewModel.password) { _ , _ in
                                                viewModel.updateValidationPassword()
                                            }
                                            .onTapGesture {
                                                viewModel.passwordError = nil
                                            }
                                    } else {
                                        SecureField(Localized.SignUpView.passwordPlaceholder.localized(), text: $viewModel.password)
                                            .submitLabel(.done)
                                            .focused($isFieldFocus, equals: .securePasswordField)
                                            .textContentType(.password)
                                            .autocapitalization(.none)
                                            .disableAutocorrection(true)
                                            .onSubmit { focusNextField() }
                                            .onChange(of: viewModel.password) { _ , _ in
                                                viewModel.updateValidationPassword()
                                            }
                                            .onTapGesture {
                                                viewModel.passwordError = nil
                                            }
                                    }
                                }
                                // Кнопка-переключатель видимости пароля
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
                            if let error = viewModel.passwordError {
                                Text(error.localized())
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                    
                    // Кнопка регистрации (всегда активна)
                    Button(action: register) {
                        Group {
                            if viewModel.isRegistering {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            } else {
                                Text(Localized.SignUpView.register.localized())
                            }
                        }
//                        .frame(maxWidth: viewModel.isLandscape ? 300 : .infinity)
                        .frame(maxWidth: orientationService.orientation == .landscape  ? 300 : .infinity)
                        .contentShape(Rectangle())
                    }
                    .fontWeight(.semibold)
                    .padding()
                    .background(AppColors.activeColor)
                    .foregroundColor(AppColors.primary)
                    .cornerRadius(8)
                    .padding(.horizontal)
                    .disabled(viewModel.isRegistering)
                    
                    // Разделитель между регистрацией и альтернативными способами входа
                    HStack {
                        VStack { Divider().frame(height: 1).background(Color.primary) }
                        Text(Localized.SignUpView.or.localized())
                            .font(.footnote)
                            .foregroundColor(.primary)
                        VStack { Divider().frame(height: 1).background(Color.primary) }
                    }
                    .padding([.horizontal, .vertical])
                    
                    // Блок альтернативной регистрации
                    HStack(spacing: 40) {
                        // Кнопка Apple
                        Button(action: {
                            guard !viewModel.isRegistering else { return }
                            print("applelogo")
                        })  {
                            Image(systemName: "applelogo")
                                .resizable()
                                .scaledToFit()
                                .padding()
                                .frame(width: 60, height: 60) // ← Жёсткий размер
                                .tint(AppColors.primary)
                                .background(Circle().stroke(Color.gray, lineWidth: 1))
                        }
                        
                        // Кнопка Google
                        Button(action: {
                            guard !viewModel.isRegistering else { return }
                            print("googlelogo")
                        }) {
                            Image("googlelogo")
                                .resizable()
                                .scaledToFit()
                                .padding()
                                .frame(width: 60, height: 60) // ← Жёсткий размер
                                .background(Circle().stroke(Color.gray, lineWidth: 1))
                        }
                    }
                    .padding(.vertical, 10)
                    
                    
                    // Ссылка для SignIn
                    HStack {
                        Text(Localized.SignUpView.alreadyHaveAccount.localized())
                        Button(action: {
                            // Переход на экран входа
                            guard !viewModel.isRegistering else { return }
                            accountCoordinator.navigateTo(page: .login)
                        }) {
                            Text(Localized.SignUpView.signIn.localized())
                                .foregroundColor(.blue)
                                .fontWeight(.semibold)
                        }
                    }
                    .padding(.bottom, 20)
                }
                .navigationBarTitleDisplayMode(.inline)
                .navigationTitle(Localized.SignUpView.navigationTitle.localized())
            }
            // Применяем жест, который срабатывает одновременно с другими
            ///первым отрабатывает simultaneousGesture затем все другие обработчики
            ///поэтому при нажатии на TextField с открытой keyboard клавиатура пропадает а затем снова открывается
            .simultaneousGesture(
                TapGesture().onEnded {
                    hideKeyboard()
                }
            )
    }
    
    private func focusNextField() {
        switch isFieldFocus {
        case .emailField:
            isFieldFocus = isPasswordVisible ? .passwordField : .securePasswordField
        case .securePasswordField, .passwordField:
            isFieldFocus = nil
        default:
            isFieldFocus = nil
        }
    }
    
    
    private func register() {
        // Защита от повторного срабатывания
        guard !viewModel.isRegistering else { return }
        
        // Обновляем валидацию полей
        viewModel.updateValidationEmail()
        viewModel.updateValidationPassword()
        
        if viewModel.isValid {
            viewModel.isRegistering = true
            print("Данные валидны. Начинаем регистрацию.")
            
            // Симуляция асинхронного процесса регистрации, который может быть заменён реальным API-вызовом
            viewModel.registerUser { success in
                // Выключаем спиннер после завершения регистрации
                DispatchQueue.main.async {
                    viewModel.isRegistering = false
                }
            }
        } else {
            print("Некоторые поля заполнены неверно.")
        }
    }
}



// MARK: - Version alternative autentification

// zero version
/// адаптивный - если у нас ширина меньше 160pt(60 + 40 + 60) то кнопка будет ужиматься
/// но у нас Даже iPhone SE (3rd) имеет ширину 375pt → 160pt < 375pt
/// то есть такой подход избыточен

//HStack(spacing: 40) {
//    // Кнопка регистрации через Apple
//    Button(action: {
//        guard !viewModel.isRegistering else { return }
//        print("applelogo")
//    }) {
//        Image(systemName: "applelogo")
//            .resizable()
//            .scaledToFit()
//            .padding()
//            .frame(maxWidth: .infinity, maxHeight: .infinity)
//            .aspectRatio(1, contentMode: .fit)
//            .background(
//                Circle()
//                    .stroke(Color.gray, lineWidth: 1)
//            )
//            .tint(AppColors.primary)
//    }
//    .frame(maxWidth: 60, maxHeight: 60)
//    .aspectRatio(1, contentMode: .fit)
//    .background(
//           GeometryReader { geometry in
//               Color.clear
//                   .onAppear {
//                       print("Apple Button size: \(geometry.size)")
//                   }
//                   .onChange(of: geometry.size) { _, newSize in
//                       print("Apple Button new size: \(newSize)")
//                   }
//           }
//       )
//    
//    // Кнопка регистрации через Google
//    Button(action: {
//        guard !viewModel.isRegistering else { return }
//        print("googlelogo")
//    }) {
//        Image("googlelogo")
//            .resizable()
//            .scaledToFit()
//            .padding()
//            .frame(maxWidth: .infinity, maxHeight: .infinity)
//            .aspectRatio(1, contentMode: .fit)
//            .background(
//                Circle()
//                    .stroke(Color.gray, lineWidth: 1)
//            )
//    }
//    .frame(maxWidth: 60, maxHeight: 60)
//    .aspectRatio(1, contentMode: .fit)
//    .background(
//         GeometryReader { geometry in
//             Color.clear
//                 .onAppear {
//                     print("Google Button size: \(geometry.size)")
//                 }
//                 .onChange(of: geometry.size) { _, newSize in
//                     print("Google Button new size: \(newSize)")
//                 }
//         }
//     )
//}
//.frame(maxWidth: .infinity)
//.padding(.vertical, 10)


// first verssion
///проблема в том что нам приходится жестко фиксировать frame для GeometryReader
///в большинстве случаев использование GeometryReader внутри ScrollView — не лучшая практика.

//                    GeometryReader { geometry in
//                        HStack(spacing: 40) {
//                            // Кнопка регистрации через Apple
//                            Button(action: {
//                                // Реализуйте регистрацию через Apple
//                                guard !viewModel.isRegistering else { return }
//                                print("applelogo")
//                            }) {
//                                Image(systemName: "applelogo")
//                                    .resizable()
//                                    .scaledToFit()
//                                //                            UIScreen.main.bounds.width * 0.08
//                                    .frame(width: geometry.size.width * 0.08,
//                                           height: geometry.size.width * 0.08)
//                                    .padding()
//                                    .tint(AppColors.primary)
//                                    .clipShape(Circle())
//                                    .overlay(Circle().stroke(Color.gray, lineWidth: 1))
//                            }
//
//                            // Кнопка регистрации через Google
//                            Button(action: {
//                                // Реализуйте регистрацию через Google
//                                guard !viewModel.isRegistering else { return }
//                                print("googlelogo")
//                            }) {
//                                Image("googlelogo")
//                                    .resizable()
//                                    .scaledToFit()
//                                    .frame(width: geometry.size.width * 0.08,
//                                           height: geometry.size.width * 0.08)
//                                    .padding()
//                                    .clipShape(Circle())
//                                    .overlay(Circle().stroke(Color.gray, lineWidth: 1))
//                            }
//                        }
//                        .frame(width: geometry.size.width, height: geometry.size.height, alignment: .center)
//                        .padding(.vertical, 10)
//                    }
//                    .frame(height: 100)
//                    .background(Color.green)

//second version
// при изменении ориентации и срабатывании state размер резко менялся до больших размеров

//HStack(spacing: 40) {
//    // Кнопка регистрации через Apple
//    Button(action: {
//        // Реализуйте регистрацию через Apple
//        guard !viewModel.isSignIn else { return }
//        print("applelogo")
//    }) {
//        Image(systemName: "applelogo")
//            .resizable()
//            .scaledToFit()
//            .frame(width: UIScreen.main.bounds.width * 0.08,
//                   height: UIScreen.main.bounds.width * 0.08)
//            .padding()
//            .tint(AppColors.primary)
//            .clipShape(Circle())
//            .overlay(Circle().stroke(Color.gray, lineWidth: 1))
//    }
//    
//    // Кнопка регистрации через Google
//    Button(action: {
//        // Реализуйте регистрацию через Google
//        guard !viewModel.isSignIn else { return }
//        print("googlelogo")
//    }) {
//        Image("googlelogo")
//            .resizable()
//            .scaledToFit()
//            .frame(width: UIScreen.main.bounds.width * 0.08,
//                   height: UIScreen.main.bounds.width * 0.08)
//            .padding()
//            .clipShape(Circle())
//            .overlay(Circle().stroke(Color.gray, lineWidth: 1))
//    }
//}
//.padding(.vertical, 10)



// MARK: - first version Validation
//import SwiftUI
//
//enum FieldToFocus: Hashable , CaseIterable {
//    case emailField, securePasswordField, passwordField
//}
//
//struct CreateAccountView: View {
//
//    // Новое состояние для переключения видимости пароля
//    @State private var isPasswordVisible: Bool = false
//    @FocusState var isFieldFocus: FieldToFocus?
//
//    @StateObject private var viewModel = CreateAccountViewModel()
//
//    var body: some View {
//        ScrollView(.vertical, showsIndicators: false) {
//            VStack(spacing: 20) {
//                // Форма регистрации с метками
//                VStack(spacing: 15) {
//                    // Поле "Email"
//                    VStack(alignment: .leading, spacing: 5) {
//                        Text("Email")
//                            .font(.subheadline)
//                            .foregroundColor(AppColors.primary)
//                        TextField("Введите email", text: $viewModel.email)
//                            .submitLabel(.next)
//                            .focused($isFieldFocus, equals: .emailField)
//                            .onSubmit {
//                                focusNextField()
//                            }
//                            .padding()
//                            .background(Color.gray.opacity(0.1))
//                            .cornerRadius(8)
//                            .keyboardType(.emailAddress)
//                            .autocapitalization(.none)
//                            .onChange(of: viewModel.email) { _ , _ in
//                                viewModel.updateValidationEmail()
//                            }
//                        if let error = viewModel.emailError {
//                            Text(error)
//                                .font(.caption)
//                                .foregroundColor(.red)
//                        }
//                    }
//
//                    // Поле "Пароль" с кнопкой "eye" для переключения видимости
//                    VStack(alignment: .leading, spacing: 5) {
//                        Text("Пароль")
//                            .font(.subheadline)
//                            .foregroundColor(AppColors.primary)
//                        HStack {
//                            Group {
//                                if isPasswordVisible {
//                                    TextField("Введите пароль", text: $viewModel.password)
//                                        .submitLabel(.done)
//                                        .focused($isFieldFocus, equals: .passwordField)
//                                        .textContentType(.password)
//                                        .onSubmit {
//                                            focusNextField()
//                                        }
//                                        .onChange(of: viewModel.password) { _ , _ in
//                                            viewModel.updateValidationPassword()
//                                        }
//                                } else {
//                                    SecureField("Введите пароль", text: $viewModel.password)
//                                        .submitLabel(.done)
//                                        .focused($isFieldFocus, equals: .securePasswordField)
//                                        .textContentType(.password)
//                                        .onSubmit {
//                                            focusNextField()
//                                        }
//                                        .onChange(of: viewModel.password) { _ , _ in
//                                            viewModel.updateValidationPassword()
//                                        }
//                                }
//                            }
//                            // Кнопка-переключатель
//                            Button(action: {
//                                isPasswordVisible.toggle()
//                                isFieldFocus = isPasswordVisible ? .passwordField : .securePasswordField
//                            }) {
//                                Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
//                                    .foregroundColor(.gray)
//                            }
//                        }
//                        .padding()
//                        .background(Color.gray.opacity(0.1))
//                        .cornerRadius(8)
//                        if let error = viewModel.passwordError {
//                            Text(error)
//                                .font(.caption)
//                                .foregroundColor(.red)
//                        }
//                    }  // End of password field
//                }
//                .padding(.horizontal)
//                .padding(.top, 20)
//
//                // Кнопка регистрации
//                Button(action: {
//                    // Обработка регистрации пользователя
//                }, label: {
//                    Text("Зарегистрироваться")
//                        .fontWeight(.semibold)
//                        .frame(maxWidth: .infinity)
//                        .padding()
//                        .background(AppColors.activeColor)
//                        .foregroundColor(AppColors.primary)
//                        .cornerRadius(8)
//                })
//                .padding(.horizontal)
//                //                .disabled(!viewModel.isValid)
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
//                            .frame(width: UIScreen.main.bounds.width * 0.08, height: UIScreen.main.bounds.width * 0.08)
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
//                            .frame(width: UIScreen.main.bounds.width * 0.08, height: UIScreen.main.bounds.width * 0.08)
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
//            .navigationBarTitleDisplayMode(.inline)
//            .navigationTitle("Создать аккаунт")
//        }
//    }
//
//    private func focusNextField() {
//        switch isFieldFocus {
//        case .emailField:
//            isFieldFocus = isPasswordVisible ? .passwordField : .securePasswordField
//        case .securePasswordField, .passwordField:
//            isFieldFocus = nil
//        default:
//            isFieldFocus = nil
//        }
//    }
//}
//
//class CreateAccountViewModel: ObservableObject {
//    @Published var email: String = ""
//    @Published var password: String = ""
//
//    @Published var emailError: String?
//    @Published var passwordError: String?
//
//    // Вычисляемое свойство без side‑эффектов:
//    var isValid: Bool {
//        email.isValidEmail && (password.validatePassword() == ValidationResult.success)
//    }
//
//    func updateValidationEmail() {
//        emailError = email.isValidEmail ? nil : "Введите корректный адрес электронной почты."
//    }
//
//    func updateValidationPassword() {
//        switch password.validatePassword() {
//        case .failure(let message):
//            passwordError = message
//        case .success:
//            passwordError = nil
//        }
//    }
//}
//
//
//// Validation
//enum ValidationResult: Equatable {
//    case success
//    case failure(String)
//}
//
//
//extension String {
//    /// Проверка email с использованием регулярного выражения
////    var isValidEmail: Bool {
////        // Используем простое регулярное выражение для примера
////        // Регулярки для email могут быть весьма сложными; в продакшене можно использовать более надёжное решение или библиотеку.
////        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
////        return NSPredicate(format:"SELF MATCHES %@", emailRegex).evaluate(with: self)
////    }
//
//    /// Проверка email с использованием NSDataDetector
//        var isValidEmail: Bool {
//            let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
//            let range = NSRange(location: 0, length: self.utf16.count)
//            let matches = detector?.matches(in: self, options: [], range: range) ?? []
//            return matches.count == 1 && matches.first?.url?.scheme == "mailto"
//        }
//
//
//    func validatePassword() -> ValidationResult {
//        if self.count < 8 {
//            return .failure("Пароль должен содержать не менее 8 символов.")
//        }
//        if self.rangeOfCharacter(from: .decimalDigits) == nil {
//            return .failure("Пароль должен содержать хотя бы одну цифру.")
//        }
//        if self.rangeOfCharacter(from: .lowercaseLetters) == nil {
//            return .failure("Пароль должен содержать хотя бы одну строчную букву.")
//        }
//        if self.rangeOfCharacter(from: .uppercaseLetters) == nil {
//            return .failure("Пароль должен содержать хотя бы одну заглавную букву.")
//        }
//        return .success
//    }
//}


//    func isValidEmail(_ email: String) -> Bool {
//        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
//        let range = NSRange(location: 0, length: email.utf16.count)
//        let matches = detector?.matches(in: email, options: [], range: range) ?? []
//        return matches.count == 1 && matches.first?.url?.scheme == "mailto"
//    }

//    // Метод, который можно вызывать, чтобы обновить ошибки, например, в onChange
//        func updateValidationErrors() {
//            emailError = email.isValidEmail ? nil : "Введите корректный адрес электронной почты."
//
//            switch password.validatePassword() {
//            case .failure(let message):
//                passwordError = message
//            case .success:
//                passwordError = nil
//            }
//        }
    
//    func validateFields() -> Bool {
//        // Проверка email
//        if !email.isValidEmail {
//            emailError = "Введите корректный адрес электронной почты."
//        } else {
//            emailError = nil
//        }
//
//        // Проверка пароля
//        switch password.validatePassword() {
//        case .failure(let message):
//            passwordError = message
//        case .success:
//            passwordError = nil
//        }
//
//        return emailError == nil && passwordError == nil
//    }


// MARK: - Sistem Warning

///Итак, подытожим: Это предупреждение связано с системой автоматической адаптации клавиатуры iOS и не является следствием вашего кода напрямую. Если у вас нет проблем с отображением элементов и работы формы, можно спокойно игнорировать эти сообщения. Если же предупреждение вызывает реальные визуальные или функциональные проблемы, стоит рассмотреть отключение input assistant или исследование проблемы более подробно, но на практике большинство разработчиков видят подобные сообщения и не предпринимают никаких действий.

//Unable to simultaneously satisfy constraints.
//    Probably at least one of the constraints in the following list is one you don't want.
//    Try this:
//        (1) look at each constraint and try to figure out which you don't expect;
//        (2) find the code that added the unwanted constraint or constraints and fix it.
//(
//    "<NSLayoutConstraint:0x6000021ed310 'accessoryView.bottom' _UIRemoteKeyboardPlaceholderView:0x104399940.bottom == _UIKBCompatInputView:0x1047209e0.top   (active)>",
//    "<NSLayoutConstraint:0x6000021e8ff0 'assistantHeight' SystemInputAssistantView.height == 45   (active, names: SystemInputAssistantView:0x1045b34d0 )>",
//    "<NSLayoutConstraint:0x6000021f07d0 'assistantView.bottom' SystemInputAssistantView.bottom == _UIKBCompatInputView:0x1047209e0.top   (active, names: SystemInputAssistantView:0x1045b34d0 )>",
//    "<NSLayoutConstraint:0x6000021f0780 'assistantView.top' V:[_UIRemoteKeyboardPlaceholderView:0x104399940]-(0)-[SystemInputAssistantView]   (active, names: SystemInputAssistantView:0x1045b34d0 )>"
//)
//
//Will attempt to recover by breaking constraint
//<NSLayoutConstraint:0x6000021f0780 'assistantView.top' V:[_UIRemoteKeyboardPlaceholderView:0x104399940]-(0)-[SystemInputAssistantView]   (active, names: SystemInputAssistantView:0x1045b34d0 )>
//
//Make a symbolic breakpoint at UIViewAlertForUnsatisfiableConstraints to catch this in the debugger.
//The methods in the UIConstraintBasedLayoutDebugging category on UIView listed in <UIKitCore/UIView.h> may also be helpful.





// MARK: - Three textField

//import SwiftUI
//
//enum FieldToFocus: Hashable , CaseIterable {
//    case nameField, emailField, securePasswordField, passwordField
//}
//
//struct CreateAccountView: View {
//    @State private var username: String = ""
//    @State private var email: String = ""
//    @State private var password: String = ""
//    // Новое состояние для переключения видимости пароля
//    @State private var isPasswordVisible: Bool = false
//    @FocusState var isFieldFocus: FieldToFocus?
//    
//    var body: some View {
//        ScrollView(.vertical, showsIndicators: false) {
//            VStack(spacing: 20) {
//                // Заголовок экрана
////                Text("Создать аккаунт")
////                    .font(.largeTitle)
////                    .fontWeight(.bold)
////                    .padding(.top, 20)
//                
//                // Форма регистрации с метками
//                VStack(spacing: 15) {
//                    // Поле "Имя"
//                    VStack(alignment: .leading, spacing: 5) {
//                        Text("Имя")
//                            .font(.subheadline)
//                            .foregroundColor(AppColors.primary)
//                        TextField("Введите имя", text: $username)
//                            .submitLabel(.next)
//                            .focused($isFieldFocus, equals: .nameField)
//                            .onSubmit { focusNextField() }
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
//                            .submitLabel(.next)
//                            .focused($isFieldFocus, equals: .emailField)
//                            .onSubmit { focusNextField() }
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
//                            .foregroundColor(AppColors.primary)
//                        HStack {
//                            Group {
//                                if isPasswordVisible {
//                                    TextField("Введите пароль", text: $password)
//                                        .submitLabel(.done)
//                                        .focused($isFieldFocus, equals: .passwordField)
//                                        .textContentType(.password)
//                                        .onSubmit { focusNextField() }
//                                } else {
//                                    SecureField("Введите пароль", text: $password)
//                                        .submitLabel(.done)
//                                        .focused($isFieldFocus, equals: .securePasswordField)
//                                        .textContentType(.password)
//                                        .onSubmit { focusNextField() }
//                                }
//                            }
//                            // Кнопка-переключатель
//                            Button(action: {
//                                isPasswordVisible.toggle()
//                                isFieldFocus = isPasswordVisible ? .passwordField : .securePasswordField
//                            }) {
//                                Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
//                                    .foregroundColor(.gray)
//                            }
//                        }
//                        .padding()
//                        .background(Color.gray.opacity(0.1))
//                        .cornerRadius(8)
//                    }  // End of password field
//                }
//                .padding(.horizontal)
//                .padding(.top, 20)
//                
//                // Кнопка регистрации
//                Button(action: {
//                    // Обработка регистрации пользователя
//                }, label: {
//                    Text("Зарегистрироваться")
//                        .fontWeight(.semibold)
//                        .frame(maxWidth: .infinity)
//                        .padding()
//                        .background(AppColors.activeColor)
//                        .foregroundColor(AppColors.primary)
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
//                            .frame(width: UIScreen.main.bounds.width * 0.08, height: UIScreen.main.bounds.width * 0.08)
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
//                            .frame(width: UIScreen.main.bounds.width * 0.08, height: UIScreen.main.bounds.width * 0.08)
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
//            .navigationBarTitleDisplayMode(.inline)
//            .navigationTitle("Создать аккаунт")
//        }
////        .ignoresSafeArea(.keyboard)
//    }
//    
//    private func focusNextField() {
//        switch isFieldFocus {
//        case .nameField:
//            isFieldFocus = .emailField
//        case .emailField:
//            isFieldFocus = isPasswordVisible ? .passwordField : .securePasswordField
//        case .securePasswordField, .passwordField:
//            isFieldFocus = nil
//        default:
//            isFieldFocus = nil
//        }
//    }
//}


// MARK: - Code

//VStack(spacing: 20).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

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
