//
//  CombineSetting.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 19.06.25.
//

// MARK: - Combine -


// subscriber and .store


// Плохо: подписка живет вечно
//somePublisher
//    .sink { [weak self] _ in ... }
    // Нет .store(in: &cancellables)


// Плохо: подписка уничтожается сразу
//somePublisher.sink { ... } // Нет .store

// MARK: - life cycle Publisher

//В Combine любая цепочка паблишеров живёт по одному простому контракту:
///За жизненный цикл подписки Publisher может выдать 0…N событий «значение» • А потом обязательно один терминальный эвент: .finished или .failure(Error) • После терминального эвента — больше никаких событий, подписка отменяется



//  1. example: От Publisher в sink минуя все операторы:




///так как у нас в Publisher<Output, AuthError> AuthError - передача данных может завершится с ошибкой! (если Never то с ошибкой не может)
/// и если мы на любом шаге в currentUserPublisher() или в .flatMap пушим  .failure(AuthError) через Fail или Future/promise(.failure). - ТОГДА  ПОТОК СРАЗУ ЖЕ ПЕРЕХОДИТ НА .SINK МИНУЯ .flatMap

///Fail(error: …) Это паблишер-«хелпер», который при первом же .subscribe сразу шлёт подписчику .failure(…) и мгновенно завершает подписку. downstream-операторы (flatMap, handleEvents, map) никогда даже не будут вызваны, потому что сразу получили «ошибку → конец» и отписались.

///Ключевая мысль: в Combine одно появление .failure или .finished означает конец цепочки и немедленную отписку от всех upstream-операций.

//func signUp(
//  email: String,
//  password: String,
//  name: String
//) -> AnyPublisher<Bool, AuthError> {
//    // 1) Получаем текущего user или кидаем .notAuthorized
//    currentUserPublisher()
//    // 2) Если аноним – линкуем email/password, иначе создаём новый
//    .flatMap { user in
//        user.isAnonymous
//          ? self.linkPublisher(email: email, password: password)
//          : self.createUserPublisher(email: email, password: password)
//    }
//    // 3) Создаём профиль (displayName + верификейшн)
//    .flatMap { _ in
//        self.createProfilePublisher(name: name)
//    }
//    // 4) По успешному созданию шлём письмо и возвращаем true
//    .handleEvents(receiveOutput: { _ in
//        self.sendVerificationEmail()
//    })
//    .map { _ in true }
//    // 5) Бросаем всё на глобальную фоновую очередь, результат отдаем на главный
//    .subscribe(on: DispatchQueue.global(qos: .userInitiated))
//    .receive(on: DispatchQueue.main)
//    .eraseToAnyPublisher()
//}


//  2. example: От Publisher в flatMap ( почему при authenticationPublisher.send(.failure(authenticationError)) мы попадаем не в .sink а сначало в flatMap?)

///Когда вы вызываете authenticationService.authenticate(), он шлёт вам не ошибку Combine (поскольку Failure == Never), а значение–Result.failure(authenticationError). Из-за этого пайплайн не «падает» в sink(receiveCompletion:), а передаёт Result.failure дальше: первым его ловит ваш flatMap, в блоке case .failure вы создаёте Just(.failure(error)), и уже это новое значение добегает до sink(receiveValue:), где срабатывает case .failure. Именно flatMap отвечает за то, чтобы взять каждое входящее значение, подменить его на результирующий Publisher (будь то Just, сетевой запрос или что-то другое) и «расплющить» все выходы этих внутренних паблишеров в один единый поток, позволяя выстраивать последовательность зависимых асинхронных шагов.



///Service
//private func createAnonymousUser() {
//    Auth.auth().signInAnonymously { [weak self] authResult, error in
//        guard let self = self else { return }
//        guard let user = authResult?.user else {
//            let authenticationError = error ?? NSError(domain: "Anonymous Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown error occurred during anonymous authentication"])
//            self.authenticationPublisher.send(.failure(authenticationError))
//            return
//        }
//        // Ничего не делаем, так как addStateDidChangeListener отработает снова и вызовет authPublisher.send(.success(user.uid))
//    }
//}

/// ViewModel
//private func bind() {
//    viewState = .loading
//    authenticationService.authenticate()
//        .flatMap { [weak self] result -> AnyPublisher<Result<[BookCloud], Error>, Never> in
//            guard let self = self else {
//                return Just(.success([])).eraseToAnyPublisher()
//            }
//            switch result {
//            case .success(let userId):
//                
//                return firestorColletionObserverService.observeCollection(at: "users/\(userId)/data")
//            case .failure(let error):
//                stateError = .globalError
//                return Just(.failure(error)).eraseToAnyPublisher()
//            }
//        }
//        .receive(on: DispatchQueue.main)
//        .sink { [weak self] result in
//            switch result {
//            case .success(let data):
//                self?.viewState = .content(data)
//            case .failure(let error):
//                self?.handleStateError(error)
//            }
//        }
//        .store(in: &cancellables)
//}




// MARK: - .sink(receiveCompletion:receiveValue:)

///Блок receiveValue (в данном случае success in) сработает, если пайплайн успешно завершится без ошибки и вернёт значение. В вашем случае — когда AuthorizationManager.signUp(...) проходит всю цепочку (currentUserPublisher → link/createUser → createProfile) без ошибок и .map { _ in true } эмитит true.
///Блок receiveCompletion (в данном случае completion in) срабатывает один раз — когда пайплайн завершается:
///.finished — цепочка отработала без ошибок. → Это также случается после receiveValue, но в твоём коде case .finished не обрабатывается.
///.failure(let error) — цепочка где-то упала (например, Fail(error) или Future.promise(.failure(...))). → Тогда ты попадаешь в case .failure(let err) и устанавливаешь error = err.
///Всё прошло без ошибок    - 👉 Сработает receiveValue(success), затем — completion: .finished (который ты не обрабатываешь)
///Где-то в пайплайне вызван .failure (например, Fail(.notAuthorized))    - 👉 Мгновенно вызывается receiveCompletion(.failure(error)) — receiveValue даже не срабатывает
///receiveValue сработает только при успехе + receiveCompletion сработает в любом случае (сначала .failure, либо после value — .finished), но ты ловишь только .failure


// MARK: - Publisher<Output, Failure>

///В Combine каждый паблишер объявляет два параметра-- что он пуб­ли­кует (Output) и что он может за­пушить как ошибку (Failure).
///AnyPublisher — это просто «упаковка в костюм-невидимку», которая скрывает конкретный тип паблишера, но всё равно тащит за собой его Output и Failure:
///AnyPublisher<Result<String, Error>, Never>
///Output = Result<String, Error> — то, что придёт подписчику как «значение». В вашем случае это или – .success(userId: String) – .failure(error: Error) — сами ошибки Firebase вы оборачиваете внутрь Result, чтобы поток Combine никогда не «валился».
///Failure = Never — это тип ошибки, которую паблишер может выдать как часть самого Combine. — Never означает «никогда не случится». Вы гарантируете, что ваш поток не завершится с .failure(...), а только в лучшем варианте .finished или с бесконечной серией значений.
///Что это даёт на практике?
///При подписке .sink вы можете использовать упрощённый вариант: publisher.sink { result in // сюда попадут только ваши Result<…, Error> }
///А блок receiveCompletion не нужен, потому что .failure в терминах Combine никогда не случится, а про .finished вы обычно не заботитесь.
///Если вы вместо Never указали бы реальный тип ошибки, например: AnyPublisher<String, AuthError>
///тогда в .sink придётся писать:
///.sink(   receiveCompletion: { completion in     switch completion { case .failure(let err): // сюда придёт AuthError case .finished: // сюда придёт, когда поток закрыт нормально }},receiveValue: { userId in // сюда приходят String-значения }}
///Почему иногда удобно Failure == Never + Result<…,Error>:
///– вы никогда не «режете» цепочку Combine-ошибкой, а всегда сами решаете, упала ли операция, внутри Result. – потоки можно смешивать (merge, combineLatest) без конфликтов типов ошибок. – UI-код подписки становится проще: одна точка входа для обработки всех исходов (успех или бизнес-ошибка).
//Коротко:
///Параметр <… , Never> означает, что сам Combine-поток не выдаст ошибок, он только выдаёт значения Result<…,Error>, в которых вы сами инкапсулируете любую бизнес-ошибку.
///Если бы вы хотели, чтобы Combine прерывал цепочку при ошибке, вы бы заменили Never на свой тип (например AuthError) и пушили бы .failure(AuthError) через Fail или Future/promise(.failure). - ТОГДА БЫ ПОТОК СРАЗУ ЖЕ ПЕРЕШОЛ НА .SINK МИНУЯ .flatMap




// MARK: - «пайплайн» — это

///В контексте Combine (и реактивного программирования вообще) «пайплайн» — это просто цепочка шагов (операторов), через которые проходит поток данных от источника к потребителю. Представь производственный конвейер, где каждая станция что-то к детали добавляет, проверяет или меняет, а потом передаёт дальше.
/// 1. Источник (Publisher) Создаёт событие (например, приходит User или Void).
/// 2. Операторы Каждый оператор (map, flatMap, filter, handleEvents и т. д.) – получает входящие элементы, – трансформирует их или реагирует на них, – эмитит новый элемент (или ошибку), который уходит к следующему оператору.
/// 3. Потребитель (Subscriber) В конце цепочки вы обычно вызываете .sink или assign, чтобы подписаться на результаты: – .receiveValue — обрабатываете успех, – .receiveCompletion — ловите .finished или .failure.



// MARK: - Data stream в Combine


/// Data stream в Combine — это поток асинхронных данных, который движется от источника (Publisher) через операторы (Operators) к подписчику (Subscriber). Такой поток может содержать: одно или несколько значений (.value) , завершение без ошибки (.finished) , либо завершение с ошибкой (.failure).
