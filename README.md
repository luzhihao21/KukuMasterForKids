# 九九マスター for Kids (JiuJiu Master)

## 🌟 概要 / Overview / 概要
**[JP]** 子供たちが楽しみながら九九を習得できる、教育系インタラクティブアプリです。
**[CN]** 这是一款专为儿童设计的九九乘法表互动学习应用，通过游戏化体验提升学习乐趣。
**[EN]** An interactive educational app designed for children to master multiplication tables through engaging gameplay.

---

## 🛠 技术栈 / Tech Stack / 技術スタック
- **Language:** Swift 5.9+
- **Framework:** SwiftUI
- **Audio Engine:** AVFoundation (Multi-track Audio Management)
- **Logic:** Combine & Timer-based State Management

---

## ✨ 技术亮点 / Key Features / 核心亮点

### 1. 并排布局算法 (3-Lane Lane-Based Layout)
- **[JP]** バブルの重なりを防ぐため、画面を3つのセクションに分割し、並列に浮上させるアルゴリズムを実装しました。
- **[CN]** 为了防止气泡重叠，实现了将屏幕划分为三个区域并排上升的布局算法，优化了视觉反馈。
- **[EN]** Implemented a 3-lane division algorithm to ensure bubbles rise in parallel without overlapping, enhancing visual clarity.

### 2. 音声インタラクション (Dynamic Audio Feedback)
- **[JP]** BGMのループ再生と、正解・不正解時の効果音を独立して管理するマルチオーディオシステムを搭載。
- **[CN]** 搭载了多音频管理系统，实现了背景音乐（BGM）循环播放与交互音效（点击反馈）的完美共存。
- **[EN]** Developed a multi-audio system that manages looping background music and interactive sound effects independently.

---

## 📖 实现逻辑 / Implementation / 実装の詳細
- **State Management:** 利用 `@StateObject` 和 `@Published` 实时驱动 UI 更新。
- **UX Optimization:** 针对儿童用户，优化了气泡上升速度（2.8 - 4.5）与碰撞判定线。
アプリのスクリーンショット 👇
