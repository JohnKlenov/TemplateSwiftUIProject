//
//  SettingLaunchScreen.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 12.05.25.
//

import Foundation

//Вашу Static LaunchScreen нельзя «повернуть» в другую ориентацию(laundscape, portret) после старта, и это сделано специально.
//Если вам нужен адаптивный(и динамически живой) сплэш, делайте его в своем коде (SplashViewController) с программным Auto Layout или SwiftUI View, а не в LaunchScreen.storyboard..


// Создание LaunchScreen для SwiftUI

/// Создание LaunchScreen для SwiftUI-проекта происходит через добавление storyboard-файла (LaunchScreen.storyboard), в котором вы статически настраиваете внешний вид экрана (обычно логотип и/или фон).
/// далее мы заходим в TargetProject/General - заходим App Icons and Launch Images  section. - В поле Launch Screen File field выберите файл экрана запуска, который вы хотите использовать в качестве экрана запуска.

///Если понадобится реализовать «с splash screen эффектом» уже с анимацией или динамическим контентом, можно создать отдельное представление (например, SplashScreenView) на SwiftUI, которое показывается как первое окно после LaunchScreen, но основной LaunchScreen остаётся статичным.

//на Storeboard задать констрайнт для ширины и высоты так что бы они были равны к примеру 1/3 ширины rootView

///Создание constraint для ширины
///Control-drag (Ctrl + перетаскивание) от дочернего view к его родительскому view. При отпускании выберите опцию "Equal Widths". Это создаст constraint, связывающий ширину дочернего view с шириной родительского view по формуле
///Выберите созданный constraint (его можно найти в Document Outline или на канвасе). + Откройте Attributes Inspector.
///Найдите поле «Multiplier» и измените его с «1:1» на «1:3» — это можно сделать, введя значение «0.3333» (или соответствующее дробное значение).

///Создание constraint для высоты
///Control-drag от дочернего view к родительскому view снова, но уже выберите опцию "Equal Heights".
///Откройте созданный constraint и измените мультипликатор на «0.3333», аналогично тому, как вы сделали для ширины.
///далее меняем Second Item на SuperView.Width вместо SuperView.Height

//как сделать так что бы UILabel адаптировал свой размер (а точнее — уменьшал шрифт) в зависимости от доступной ширины.

/// Auto Layout Constraints:
/// Leading Constraint: Label.leading  = Superview.leading  + 16
/// Trailing Constraint: Label.trailing  = Superview.trailing  − 16
/// (Опционально) Center Y Constraint: Label.centerY = Superview.centerY

///Attributes Inspector для UILabel:
///Text: «TemplateProject» + Font: System Bold, 30 + Lines: 1 + Adjusts Font Size To Fit Width: включено + Minimum Font Scale: 0.5
///С такой настройкой, если ширина супер-вида станет меньше, чем требуется для полного отображения текста при 30 пунктовом шрифте, UILabel автоматически уменьшит размер шрифта до значения не меньше 15 пунктов (если минимальная шкала установлена в 0.5).
///Установите "Minimum Font Scale": Это значение (например, 0.5) определяет, до какого коэффициента шрифт может быть уменьшен по сравнению с исходным размером (у вас он 30). Таким образом, если минимальное значение равно 0.5, шрифт может уменьшиться до 15 пунктов.
