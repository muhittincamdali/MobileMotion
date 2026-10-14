<p align="center"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftUI-Animation-Masterclass/main/.github/brand/banner-tr-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/SwiftUI-Animation-Masterclass/main/.github/brand/banner-tr-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/SwiftUI-Animation-Masterclass/main/.github/brand/banner-tr-light.svg" alt="Animation Masterclass: iOS ve macOS için SwiftUI'da fizik tabanlı hareket, parçacıklar, değişim efektleri ve geçişler."></picture></p>

<p align="center"><a href="README.md">English</a> · <a href="README.tr.md">Türkçe</a></p>

# MobileMotion taşındı

**Bu proje artık [SwiftUI-Animation-Masterclass](https://github.com/muhittincamdali/SwiftUI-Animation-Masterclass) içinde yaşıyor.**
Bu depo arşivlendi ve bir daha değişmeyecek. Burada yayımlanan son sürüm
[v1.0.0](https://github.com/muhittincamdali/MobileMotion/releases/tag/v1.0.0).

## Kod nereye gitti

SwiftUI-Animation-Masterclass 2.0.0, bu deponun animasyon ve jest kısımlarını SwiftUI'ın kendi
`Animation` ve jest tipleri üzerine, testlerle birlikte yeniden yazdı.

| Burada                     | SwiftUI-Animation-Masterclass içinde                                                                                                                                                               |
| -------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Yay fiziği                 | [`DampedSpring`](https://github.com/muhittincamdali/SwiftUI-Animation-Masterclass/blob/main/Sources/SwiftUIAnimationMasterclass/Physics/DampedSpring.swift), kapalı formda çözülür                 |
| Fırlatma için sürtünme     | [`Decay`](https://github.com/muhittincamdali/SwiftUI-Animation-Masterclass/blob/main/Sources/SwiftUIAnimationMasterclass/Physics/Decay.swift), fırlatmanın varacağı noktayı da hesaplar            |
| Zeminde zıplayan yerçekimi | [`GravityBounce`](https://github.com/muhittincamdali/SwiftUI-Animation-Masterclass/blob/main/Sources/SwiftUIAnimationMasterclass/Physics/GravityBounce.swift)                                      |
| Jest güdümlü animasyon     | [Gestures](https://github.com/muhittincamdali/SwiftUI-Animation-Masterclass/tree/main/Sources/SwiftUIAnimationMasterclass/Gestures): bırakma hızını yaya aktaran `.elasticDrag()` ve `.snapDrag()` |

Her şey taşınmadı. Sensörler (ivmeölçer, jiroskop, manyetometre), aktivite tanıma, sallama ve
eğme algılama, haptics, Dart paketi, CocoaPods podspec'i ve `Enterprise` yardımcıları
(`CircuitBreaker`, `RetryPolicy`, `EventBus`) SwiftUI animasyonuyla ilgili olmadığı için
taşınmadı. Tam kapsam için
[2.0.0 değişiklik günlüğüne](https://github.com/muhittincamdali/SwiftUI-Animation-Masterclass/blob/main/CHANGELOG.md)
bakın.

## Yeni paketi kurun

```swift
.package(url: "https://github.com/muhittincamdali/SwiftUI-Animation-Masterclass.git", from: "2.0.0")
```

Ardından `.product(name: "SwiftUIAnimationMasterclass", package: "SwiftUI-Animation-Masterclass")`
satırını target'ınıza ekleyin. iOS 17 veya macOS 14 ve Swift 6.2 gerekir. Tüm dokümantasyon:
[SwiftUI-Animation-Masterclass README](https://github.com/muhittincamdali/SwiftUI-Animation-Masterclass#readme).

## Lisans

MIT, bkz. [LICENSE](LICENSE).
