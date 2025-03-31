//
//  ImageCacheManager.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 30.03.25.
//


// MARK: - Firebase Firestore:

///По умолчанию Firestore включает оффлайн-кэширование документов, что позволяет вашему приложению работать без постоянного подключения к сети. Документы, полученные из базы, кэшируются и доступны локально, а изменения синхронизируются с сервером при восстановлении соединения.

// MARK: - Вызовите memory warning вручную через меню:
///Debug → Simulate Memory Warning


// MARK: - Cache SDWebImage

//Дефолтные настройки кэша SDWebImage

///let defaultCache = SDImageCache.shared
///defaultCache.config.maxMemoryCost = 0 // Не ограничено (на практике ~1/5 памяти устройства)
///defaultCache.config.maxDiskSize = 100 * 1024 * 1024 // 100 МБ
///defaultCache.config.maxDiskAge = 60 * 60 * 24 * 7 // 1 неделя (7 дней)

//Рекомендация для вашего случая:

///Если в приложении нет большого количества тяжёлых изображений (например, 1000+ файлов по 1-2 МБ), дефолтных настроек достаточно.
//но если:
///Пользователи просматривают сотни изображений ежедневно + Есть много полноразмерных фото (3+ МБ) + Приложение часто обновляет изображения = Тогда стоит настроить кэш явно.


///SDWebImage кеширует изображения как в памяти, так и на диске.
///Кешированные изображения повторно используются, что уменьшает количество сетевых запросов и повышает производительность.
///Поскольку изображения кешируются, при прокрутке назад к тому же элементу запрос сети не будет повторяться.
///При наличии 1000 изображений, если каждое изображение большое, использование памяти может увеличиться. Однако SDWebImage управляет памятью, автоматически очищая наименее использованные изображения при нехватке памяти.
///Большие размеры изображений: Изображения высокого разрешения потребляют больше памяти. Рассмотрите возможность изменения размера изображений на сервере или перед их отображением.

//Настройка кеша SDWebImage

///SDImageCache.shared.config.maxMemoryCost = 100 * 1024 * 1024 // 100 МБ
///SDImageCache.shared.config.maxDiskSize = 500 * 1024 * 1024 // 500 МБ
///Вы можете тонко настроить время истечения кеша, интервалы очистки и т.д.


// MARK: - как работает кэширование изображений в приложениях (например, при использовании SDWebImage) на двух уровнях: оперативная память (RAM) и дисковое пространство, на примере новостной ленты.

//Оперативная память (in-memory cache)

///Загрузка и декодирование: Когда пользователь впервые скроллит новостную ленту, каждое изображение требует загрузки из сети. После загрузки данные изображения декодируются в формат, удобный для рендеринга (объект UIImage). Эти декодированные изображения сохраняются в оперативной памяти для быстрого доступа. Это обеспечивает мгновенный отклик (например, при повторном просмотре или обратном скролле).
///Принцип LRU (Least Recently Used): Память — ограниченный ресурс, поэтому кэш в памяти работает по принципу LRU. Изображения, которые давно не использовались и не отображаются на экране, будут автоматически удаляться, если объем кэша достигает заданного лимита (настраивается через параметр вроде maxMemoryCost или через NSCache). Таким образом, даже если ежедневно открываются 100 новостей, старые изображения будут утрачены из памяти, если пользователь не возвращается к ним сразу. Но их можно будет восстановить из дискового кэша, если они там сохранены.
///Накаливание памяти: Если фотографии постоянно отображаются на экране и активно повторно запрашиваются, оперативная память может временно «накапливать» данные, что увеличивает общий объем кэшированных изображений. Однако благодаря LRU-схеме, если пользователь просто скроллит ленту и не задерживается на одном изображении, старые или невидимые элементы будут выброшены из памяти, чтобы освободить место для новых.


//Дисковый кэш

///Постоянство кэша: При загрузке изображения SDWebImage сохраняет его не только в оперативную память, но и на диск (обычно в виде файлов в кеш-папке). Это позволяет при повторном открытии ленты или переходе между сессиями не загружать изображение заново из сети, а брать его с диска.
///Накопление данных: Каждый раз, когда пользователь открывает новые новости, сохраняются новые изображения. Например, если у тебя в среднем одно изображение весит 300 КБ, то 100 новостей займут примерно 30 МБ дискового пространства. Если каждодневно в кэше будут накапливаться уникальные изображения, то за неделю это может составить 210 МБ — и это вполне допустимый объем, если установлен лимит в сотни мегабайт.
///Ограничения и стратегия очистки: В настройках кэша можно задать максимальный размер дискового кэша (например, 500 МБ) и время жизни файлов (например, 7 дней). При достижении лимита или истечении срока давности старые изображения автоматически удаляются. Это предотвращает бесконтрольное накопление кэша.

//SDImageCache.shared.deleteOldFiles

/// на первый взгляд может показаться, что если у тебя настроено, скажем, хранение изображений на 7 дней (maxDiskAge), то устаревшие файлы должны удаляться автоматически. Однако на практике поведение может быть следующим:
/// Автоматическая уборка работает не моментально: SDImageCache имеет встроенный механизм удаления устаревших файлов, который запускается в определённых ситуациях (например, при обращении к кэшу или при запуске фоновых задач). Но этот процесс может быть не мгновенным и зависит от активности кэша. Если кэш большой или приложение долго работает без перезапуска, устаревшие файлы могут накапливаться до тех пор, пока не сработает автоматическая уборка.
/// Явный вызов для немедленной очистки: Метод deleteOldFiles(completion:) позволяет тебе вручную инициировать проверку и удаление файлов, срок хранения которых истёк. Это полезно, когда ты хочешь гарантированно освободить место на диске сразу, например, при переходе приложения в фоновый режим или перед запуском новой сессии, чтобы убедиться, что кэш не раздувается.
/// Таким образом, даже если автоматическая очистка по maxDiskAge настроена, метод deleteOldFiles полезен для ручного, более своевременного управления дисковым кэшем.

//Пример сценария с новостной лентой

///Ежедневное использование: Пользователь открывает ленту и скроллит 100 новостей:
///Оперативная память: В момент просмотра каждый раз загружаются и декодируются изображения, сохраняются в памяти для быстрой навигации. Если пользователь скроллит быстро, объекты, удалившиеся из памяти за LRU, не будут оставаться там надолго, поэтому «накаливание» оперативной памяти ограничивается текущей сессией и активными элементами.
///Дисковый кэш: Новые изображения сохраняются на диск. Если за неделю появляются уникальные новости, на диске аккумулируется общий объем изображений (при среднем размере, например, 30 МБ в день), но настроенные лимиты (maxDiskSize) и максимальный возраст файлов (maxDiskAge) гарантируют, что дисковый кэш не будет расти бесконечно.
///Повторные сессии: При повторном открытии ленты SDWebImage сначала посмотрит в оперативный кэш, если изображения уже там, и если нет — загрузит их с диска, что значительно ускоряет рендеринг, без обращения к сети.


// MARK: - Public methods ImageCacheManager

//func clearCache(completion: (() -> Void)? = nil)
///Этот метод используется для полной очистки кэша изображений как в оперативной памяти (memory cache), так и на диске (disk cache). - При получении предупреждения о нехватке памяти. + При выходе пользователя из аккаунта или переключении контекста. + При обновлении данных или ручном сбросе кэша.

//func deleteOldFiles(completion: (() -> Void)? = nil)
///Этот метод инициирует процесс удаления старых (устаревших) файлов из дискового кэша, которые превышают заданный срок хранения (например, maxDiskAge). - Периодическое обслуживание кэша. + Вручную по запросу пользователя. + После длительного использования приложения.

//func getCacheSize()
///Метод возвращает общий размер дискового кэша изображений в байтах в виде строки. Такой метод полезен для мониторинга и отладки использования ресурсов.


import SDWebImage
import SDWebImageSwiftUI
import Combine

final class ImageCacheManager {
    static let shared = ImageCacheManager()
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        print("init ImageCacheManager")
        setupMemoryWarningHandler()
    }
    
    // MARK: - Public Interface
    
    func clearCache(completion: (() -> Void)? = nil) {
        SDImageCache.shared.clearMemory()
        SDImageCache.shared.clearDisk {
            completion?()
        }
    }
    
    func deleteOldFiles(completion: (() -> Void)? = nil) {
        SDImageCache.shared.deleteOldFiles {
            completion?()
        }
    }
    
    func getCacheSize() {
        let diskSize = SDImageCache.shared.totalDiskSize()
        print("total bytes size of images in the disk - \(diskSize.bytesToMB()) MB")
//        return "total bytes size of images in the disk - \(diskSize.bytesToMB()) MB"
    }

    
    // MARK: - Private Methods
    
    ///Низкий уровень доступной оперативной памяти: Система iOS следит за использованием оперативной памяти всеми приложениями. Когда свободная RAM падает ниже определённого порога, система посылает это уведомление, чтобы дать приложениям шанс освободиться от временных данных.
    private func setupMemoryWarningHandler() {
        NotificationCenter.default.publisher(for: UIApplication.didReceiveMemoryWarningNotification)
            .sink { [weak self] _ in
                self?.handleMemoryWarning()
            }
            .store(in: &cancellables)
    }
    
    private func handleMemoryWarning() {
        SDImageCache.shared.clearMemory()
        //        Analytics.logEvent("memory_warning", parameters: [
        //            "timestamp": Date().timeIntervalSince1970
        //        ])
        print("⚠️ Memory warning handled: image cache cleared")
    }
}

// MARK: - Helpers для преобразования байтов в мегабайты
private extension UInt {
    func bytesToMB() -> Double {
        Double(self) / 1024 / 1024
    }
}



// MARK: - reserved code



// Когда имеет смысл настраивать configureCache()?:

//private init() { configureCache() ... }
///Если возникает нехватка ресурсов: Например, если приложение начинает испытывать проблемы с памятью из-за роста числа изображений или их размеров, тогда увеличение maxMemoryCost и maxDiskSize может помочь.
///Когда нужны строгие ограничения: Если в проекте критично ограничить использование памяти или дискового пространства (например, для приложения, работающего на устройствах с минимальными ресурсами), то ручная настройка этих параметров может быть полезной.
///Если изображения часто обновляются: При частом обновлении изображений можно сократить maxDiskAge, чтобы удалить устаревшие файлы быстрее.
//    func configureCache(
//        maxMemoryCost: UInt = 100 * 1024 * 1024,
//        maxDiskSize: UInt = 500 * 1024 * 1024,
//        maxDiskAge: TimeInterval = 60 * 60 * 24 * 7
//    ) {
//        SDImageCache.shared.config.maxMemoryCost = maxMemoryCost
//        SDImageCache.shared.config.maxDiskSize = maxDiskSize
//        SDImageCache.shared.config.maxDiskAge = maxDiskAge
//    }




//    func getCacheSize() -> (memory: String, disk: String) {
//        let memorySize = SDImageCache.shared.totalDiskSize()
//        let diskSize = SDImageCache.shared.totalDiskSize()
//        return (
//            "\(memorySize.bytesToMB()) MB",
//            "\(diskSize.bytesToMB()) MB"
//        )
//    }
