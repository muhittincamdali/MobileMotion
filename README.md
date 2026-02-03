<div align="center">

# 🎬 MobileMotion

**Cross-platform physics-based animation engine for iOS, Flutter & React Native**

[![Swift](https://img.shields.io/badge/Swift-5.9+-F05138?style=for-the-badge&logo=swift&logoColor=white)](https://swift.org)
[![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)

</div>

---

## ✨ Features

- 🌊 **Spring Physics** — Natural bouncy motion
- ⚡ **60fps** — Smooth performance
- 🎯 **Gesture Driven** — Drag, fling, snap
- 📦 **Cross-Platform** — Same API everywhere
- 🎨 **Customizable** — Tension, friction, mass

---

## 🚀 Quick Start

### Swift
```swift
import MobileMotion

view.animate(to: targetPoint)
    .spring(tension: 200, friction: 20)
    .start()
```

### Flutter
```dart
import 'package:mobile_motion/mobile_motion.dart';

controller.animate(to: 1.0, spring: Spring(tension: 200));
```

---

## 📄 License

MIT • [@muhittincamdali](https://github.com/muhittincamdali)
