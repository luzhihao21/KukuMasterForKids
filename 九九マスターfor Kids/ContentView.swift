import SwiftUI
import Combine

// --- 1. 数据模型 ---
struct Bubble: Identifiable {
    let id = UUID()
    let number: Int
    var xOffset: CGFloat
    var yOffset: CGFloat
    var speed: Double
}

// --- 2. 主入口视图：增加导航选择 ---
struct ContentView: View {
    @State private var gameMode: String? = nil // nil: 首页, "solo": 个人, "battle": 对战

    var body: some View {
        if gameMode == "solo" {
            JiuJiuGameView(isBattleMode: false) { gameMode = nil }
        } else if gameMode == "battle" {
            JiuJiuGameView(isBattleMode: true) { gameMode = nil }
        } else {
            // 首页选择界面
            VStack(spacing: 40) {
                Text("九九マスター for Kids")
                    .font(.system(size: 60, weight: .black, design: .rounded))
                    .foregroundColor(.orange)
                
                HStack(spacing: 50) {
                    // 个人模式按钮
                    Button(action: { gameMode = "solo" }) {
                        MenuButton(title: "一人で修業", icon: "person.fill", color: .blue)
                    }
                    
                    // 对战模式按钮
                    Button(action: { gameMode = "battle" }) {
                        MenuButton(title: "二人で対戦", icon: "person.2.fill", color: .pink)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.yellow.opacity(0.1).ignoresSafeArea())
        }
    }
}

// --- 3. 核心游戏视图 (通用版) ---
struct JiuJiuGameView: View {
    let isBattleMode: Bool
    var onExit: () -> Void
    
    let timer = Timer.publish(every: 0.04, on: .main, in: .common).autoconnect()
    
    @State private var timeLeft = 10
    @State private var question = "3 × 8"
    @State private var p1Bubbles: [Bubble] = []
    @State private var p2Bubbles: [Bubble] = []
    @State private var shakeAngle: Double = 0
    @State private var score = 0

    var body: some View {
        ZStack {
            // 背景层
            VStack(spacing: 0) {
                Color.blue.opacity(0.1)
                if isBattleMode { Color.pink.opacity(0.1) }
            }.ignoresSafeArea()
            
            VStack(spacing: 0) {
                if isBattleMode {
                    // 对战模式：上方玩家
                    PlayerArena(isPlayerOne: true, timeLeft: timeLeft, question: question, bubbles: $p1Bubbles, shakeAngle: shakeAngle, score: .constant(0))
                        .rotationEffect(.degrees(180))
                    
                    Rectangle().fill(Color.orange).frame(height: 4)
                }
                
                // 个人模式或对战下方的玩家
                PlayerArena(isPlayerOne: false, timeLeft: timeLeft, question: question, bubbles: $p2Bubbles, shakeAngle: shakeAngle, score: $score)
            }
            
            // 退出按钮
            VStack {
                HStack {
                    Button(action: onExit) {
                        Image(systemName: "house.fill")
                            .font(.title).padding().background(Circle().fill(Color.white.opacity(0.8)))
                    }.padding()
                    Spacer()
                }
                Spacer()
            }
        }
        .onAppear(perform: setupNewQuestion)
        .onReceive(timer) { _ in updatePositions() }
    }

    func setupNewQuestion() {
        // 这里后续可以做成随机题目
        let options = [23, 24, 38].shuffled()
        p1Bubbles = createBubbles(with: options)
        p2Bubbles = createBubbles(with: options)
    }

    func createBubbles(with options: [Int]) -> [Bubble] {
        options.enumerated().map { index, val in
            Bubble(number: val, xOffset: CGFloat(index * 200 - 200), yOffset: 450, speed: Double.random(in: 2...4))
        }
    }

    func updatePositions() {
        shakeAngle = sin(Date().timeIntervalSince1970 * 4) * 10
        for i in 0..<p1Bubbles.count {
            p1Bubbles[i].yOffset -= p1Bubbles[i].speed
            if p1Bubbles[i].yOffset < -400 { p1Bubbles[i].yOffset = 450 }
        }
        for i in 0..<p2Bubbles.count {
            p2Bubbles[i].yOffset -= p2Bubbles[i].speed
            if p2Bubbles[i].yOffset < -400 { p2Bubbles[i].yOffset = 450 }
        }
    }
}

// --- 4. 玩家竞技场组件 ---
struct PlayerArena: View {
    let isPlayerOne: Bool
    let timeLeft: Int
    let question: String
    @Binding var bubbles: [Bubble]
    let shakeAngle: Double
    @Binding var score: Int
    
    var body: some View {
        ZStack {
            VStack {
                Text(question + " = ?")
                    .font(.system(size: 80, weight: .black, design: .rounded))
                    .padding(.top, 60)
                
                Text("SCORE: \(score)")
                    .font(.title.bold()).foregroundColor(.blue)
                
                Spacer()
            }
            
            ForEach(bubbles) { bubble in
                BubbleSprite(number: bubble.number, color: isPlayerOne ? .blue : .pink)
                    .offset(x: bubble.xOffset, y: bubble.yOffset)
                    .onTapGesture {
                        if bubble.number == 24 { // 暂时写死正确答案
                            score += 10
                            // 这里可以加爆炸效果
                        }
                    }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity).clipped()
    }
}

// --- 5. 辅助 UI 组件 ---
struct MenuButton: View {
    let title: String; let icon: String; let color: Color
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon).font(.system(size: 50))
            Text(title).font(.title2.bold())
        }
        .frame(width: 200, height: 200)
        .background(color.opacity(0.2)).cornerRadius(30)
        .overlay(RoundedRectangle(cornerRadius: 30).stroke(color, lineWidth: 4))
    }
}

struct BubbleSprite: View {
    let number: Int; let color: Color
    var body: some View {
        ZStack {
            Circle().fill(RadialGradient(colors: [.white, color.opacity(0.5)], center: .center, startRadius: 0, endRadius: 60))
            Text("\(number)").font(.system(size: 40, weight: .bold)).foregroundColor(color)
        }
        .frame(width: 120, height: 120)
    }
}
