//
//  UIImage+Ext.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 19.09.25.
//


import UIKit

extension UIImage {
    /// Масштабирует изображение, сохраняя пропорции, чтобы оно вписалось в квадрат заданного размера.
    ///
    /// Метод автоматически подбирает размер, чтобы изображение не искажалось и вписывалось в квадрат со стороной `maxSide`.
    /// Например, если изображение горизонтальное, оно будет ограничено по ширине, а высота рассчитана пропорционально.
    /// Если вертикальное — ограничено по высоте, а ширина подстроится.
    ///
    /// Используется `UIGraphicsImageRenderer`, который безопасно рендерит изображение с учётом масштаба экрана (`scale`)
    /// и прозрачности (`opaque = false`), что особенно важно для аватаров и превью.
    ///
    /// 🔐 Защита от ошибок:
    /// - Проверяется, что `maxSide > 0` — иначе возвращается оригинал.
    /// - Проверяется, что `self.size` не содержит нулевых значений — иначе возвращается оригинал.
    /// - Метод устойчив к повреждённым изображениям (например, без `CGImage`) — в худшем случае вернёт пустое изображение.
    /// - При обработке больших изображений рекомендуется использовать `autoreleasepool {}` вне метода, чтобы избежать утечек памяти.
    ///
    /// - Parameter maxSide: Максимальная длина стороны квадрата (например, 300 для 300x300).
    /// - Returns: Новое `UIImage`, отрисованное с сохранением пропорций или оригинал, если входные данные некорректны.
    func resizedMaintainingAspectRatio(toFit maxSide: CGFloat) -> UIImage? {
        guard maxSide > 0 else { return nil }
        guard self.size.width > 0, self.size.height > 0 else { return nil }
        
        ///max Возвращает большее из двух значений
        let maxOriginalSide = max(self.size.width, self.size.height)
            guard maxOriginalSide > maxSide else {
                // Изображение уже меньше — не увеличиваем
                return self
            }
        
        let originalSize = self.size
        let aspectRatio = originalSize.width / originalSize.height

        var targetSize: CGSize
        if aspectRatio > 1 {
            // Горизонтальное изображение: ограничиваем ширину
            targetSize = CGSize(width: maxSide, height: maxSide / aspectRatio)
        } else {
            // Вертикальное или квадратное изображение: ограничиваем высоту
            targetSize = CGSize(width: maxSide * aspectRatio, height: maxSide)
        }

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = self.scale // сохраняем чёткость на Retina
        format.opaque = false     // поддерживаем прозрачность

        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}

//import UIKit
//
//extension UIImage {
//    /// Масштабирует изображение, сохраняя пропорции, чтобы оно вписалось в квадрат заданного размера.
//    ///
//    /// Метод автоматически подбирает размер, чтобы изображение не искажалось и вписывалось в квадрат со стороной `maxSide`.
//    /// Например, если изображение горизонтальное, оно будет ограничено по ширине, а высота рассчитана пропорционально.
//    /// Если вертикальное — ограничено по высоте, а ширина подстроится.
//    ///
//    /// Используется `UIGraphicsImageRenderer`, который безопасно рендерит изображение с учётом масштаба экрана (`scale`)
//    /// и прозрачности (`opaque = false`), что особенно важно для аватаров и превью.
//    ///
//    / - Parameter maxSide: Максимальная длина стороны квадрата (например, 300 для 300x300).
//    / - Returns: Новое `UIImage`, отрисованное с сохранением пропорций.
//    /
//    func resizedMaintainingAspectRatio(toFit maxSide: CGFloat) -> UIImage {
//        guard maxSide > 0 else { return self }
//        guard self.size.width > 0, self.size.height > 0 else { return self }
//
//        let originalSize = self.size
//        let aspectRatio = originalSize.width / originalSize.height
//
//        var targetSize: CGSize
//        if aspectRatio > 1 {
//            targetSize = CGSize(width: maxSide, height: maxSide / aspectRatio)
//        } else {
//            targetSize = CGSize(width: maxSide * aspectRatio, height: maxSide)
//        }
//
//        let format = UIGraphicsImageRendererFormat.default()
//        format.scale = self.scale
//        format.opaque = false
//
//        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
//        return renderer.image { _ in
//            self.draw(in: CGRect(origin: .zero, size: targetSize))
//        }
//    }
//}
