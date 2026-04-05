import SwiftUI
import Combine
import AVFoundation

// --- 1. 数据模型 ---
struct Bubble: Identifiable {
    let id = UUID()
    let number: Int
    var xOffset: CGFloat
    var yOffset: CGFloat
    var speed: Double
    var isPopped: Bool = false
    var isWrong: Bool = false
}

// --- 2. 游戏逻辑层（随机出题与音效引擎） ---
class GameViewModel: ObservableObject {
    @Published var num1: Int = 0
    @Published var num2: Int = 0
    @Published var options: [Int] = []
    @Published var score: Int = 0
    
    var audioPlayer: AVAudioPlayer?
    var correctAnswer: Int { num1 * num2 }
    
    init() { generateNewQuestion() }
    
    func generateNewQuestion() {
        num1 = Int.random(in: 2...9)
        num2 = Int.random(in: 2...9)
        let correct = num1 * num2
        
        var wrongs = Set<Int>()
        while wrongs.count < 2 {
            // 生成接近正确答案的干扰项
            let offset = Int.random(in: -5...5)
            let wrong = correct + offset
            if wrong != correct && wrong > 0 { wrongs.insert(wrong) }
        }
        options = (Array(wrongs) + [correct]).shuffled()
    }
    
    func playSound(named name: String) {
        guard let url = Bundle.main.url(forResource: name, withExtension: "mp3") else { return }
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
        } catch {
            print("播放失败")
        }
    }
}

// --- 3. 主入口 ---
struct ContentView: View {
    @StateObject private var vm = GameViewModel()
    @State private var gameMode: String? = nil

    var body: some View {
        if gameMode != nil {
            JiuJiuGameView(isBattleMode: gameMode == "battle", vm: vm) { gameMode = nil }
        } else {
            // 首页
            VStack(spacing: 40) {
                Text("九九マスター for Kids")
                    .font(.system(size: 60, weight: .black, design: .rounded))
                    .foregroundColor(.orange)
                    .shadow(radius: 5)
                
                HStack(spacing: 50) {
                    Button(action: { gameMode = "solo" }) { MenuButton(title: "一人で修業", icon: "person.fill", color: .blue) }
                    Button(action: { gameMode = "battle" }) { MenuButton(title: "二人で対戦", icon: "person.2.fill", color: .pink) }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.blue.opacity(0.05).ignoresSafeArea())
        }
    }
}

// --- 4. 游戏主战场 ---
struct JiuJiuGameView: View {
    let isBattleMode: Bool
    @ObservedObject var vm: GameViewModel
    var onExit: () -> Void
    
    let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    
    @State private var timeLeft = 10
    @State private var p1Bubbles: [Bubble] = []
    @State private var p2Bubbles: [Bubble] = []
    @State private var frameCount = 0

    var body: some View {
        ZStack {
            // 背景渐变
            LinearGradient(colors: [Color.blue.opacity(0.1), .white], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            
            VStack(spacing: 0) {
                if isBattleMode {
                    PlayerArena(isP1: true, vm: vm, bubbles: $p1Bubbles, timeLeft: timeLeft)
                        .rotationEffect(.degrees(180))
                }
                
                PlayerArena(isP1: false, vm: vm, bubbles: $p2Bubbles, timeLeft: timeLeft)
            }
            
            // 右上角得分
            VStack {
                HStack {
                    Spacer()
                    Text("Score: \(vm.score)")
                        .font(.system(size: 40, weight: .black, design: .rounded))
                        .foregroundColor(.orange).padding()
                }
                Spacer()
            }
            
            // 退出
            VStack { HStack { Button(action: onExit) { Image(systemName: "house.fill").padding().background(Circle().fill(.white)) }.padding(); Spacer() }; Spacer() }
        }
        .onAppear(perform: startRound)
        .onReceive(timer) { _ in updateFrame() }
    }

    func startRound() {
        vm.generateNewQuestion()
        timeLeft = 10
        // 降低漂浮速度到 1.0...1.6，给孩子更多思考时间
        p1Bubbles = vm.options.map { Bubble(number: $0, xOffset: CGFloat.random(in: -250...250), yOffset: 450, speed: Double.random(in: 1.0...1.6)) }
        p2Bubbles = vm.options.map { Bubble(number: $0, xOffset: CGFloat.random(in: -250...250), yOffset: 450, speed: Double.random(in: 1.0...1.6)) }
    }

    func updateFrame() {
        frameCount += 1
        if frameCount >= 20 {
            if timeLeft > 0 { timeLeft -= 1 } else { startRound() }
            frameCount = 0
        }
        
        // 气泡移动逻辑
        for i in 0..<p2Bubbles.count {
            if !p2Bubbles[i].isPopped {
                p2Bubbles[i].yOffset -= p2Bubbles[i].speed
                // 碰到云朵判定线自动破裂
                if p2Bubbles[i].yOffset < -120 { p2Bubbles[i].isPopped = true }
            }
        }
        if isBattleMode {
            for i in 0..<p1Bubbles.count {
                if !p1Bubbles[i].isPopped {
                    p1Bubbles[i].yOffset -= p1Bubbles[i].speed
                    if p1Bubbles[i].yOffset < -120 { p1Bubbles[i].isPopped = true }
                }
            }
        }
    }
}

// --- 5. 竞技场 (扭动动画 + 卡通倒计时问号) ---
struct PlayerArena: View {
    let isP1: Bool
    @ObservedObject var vm: GameViewModel
    @Binding var bubbles: [Bubble]
    let timeLeft: Int
    @State private var wiggle = false
    
    var body: some View {
        ZStack {
            // 隐蔽的云朵判定线
            VStack {
                Spacer().frame(height: 250)
                HStack(spacing: -10) {
                    ForEach(0..<12) { _ in
                        Circle().fill(Color.white.opacity(0.4)).frame(width: 120, height: 80)
                    }
                }
                Spacer()
            }

            VStack {
                // 扭动的算式
                HStack(spacing: 20) {
                    Group {
                        Text("\(vm.num1)")
                        Text("×")
                        Text("\(vm.num2)")
                        Text("=")
                    }
                    .modifier(WiggleModifier(active: wiggle))
                    
                    // 卡通问号倒计时
                    ZStack {
                        Text("?").font(.system(size: 100, weight: .black))
                            .offset(y: -20)
                        
                        // 问号底部的点做成大的倒计时显示器
                        Circle()
                            .fill(timeLeft < 4 ? Color.red : Color.orange)
                            .frame(width: 50, height: 50)
                            .offset(y: 50)
                            .overlay(
                                Text("\(timeLeft)")
                                    .foregroundColor(.white)
                                    .font(.system(size: 28, weight: .bold))
                                    .offset(y: 50)
                            )
                    }
                    .modifier(WiggleModifier(active: wiggle))
                }
                .font(.system(size: 80, weight: .black, design: .rounded))
                .padding(.top, 40)
                
                Spacer()
            }
            
            // 气泡
            ForEach($bubbles) { $bubble in
                if !bubble.isPopped {
                    BubbleView(bubble: $bubble, color: isP1 ? .blue : .pink)
                        .offset(x: bubble.xOffset, y: bubble.yOffset)
                        .onTapGesture { tap(bubble: $bubble) }
                }
            }
        }
        .onAppear { wiggle = true }
        .frame(maxWidth: .infinity, maxHeight: .infinity).clipped()
    }
    
    func tap(bubble: Binding<Bubble>) {
        if bubble.wrappedValue.number == vm.correctAnswer {
            vm.playSound(named: "bingo")
            vm.score += 10
            withAnimation(.easeOut(duration: 0.2)) { bubble.wrappedValue.isPopped = true }
            // 延迟一点刷新题目，让孩子看到得分
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                vm.generateNewQuestion()
                bubbles = vm.options.map { Bubble(number: $0, xOffset: CGFloat.random(in: -250...250), yOffset: 450, speed: Double.random(in: 1.0...1.6)) }
            }
        } else {
            vm.playSound(named: "pupu")
            withAnimation(.spring(response: 0.3, dampingFraction: 0.2)) {
                bubble.wrappedValue.isWrong = true
            }
            // 恢复原状
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                bubble.wrappedValue.isWrong = false
            }
        }
    }
}

// --- 6. 辅助组件 ---
struct WiggleModifier: ViewModifier {
    let active: Bool
    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(active ? 4 : -4))
            .offset(y: active ? -5 : 5)
            .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: active)
    }
}

struct BubbleView: View {
    @Binding var bubble: Bubble
    let color: Color
    
    var body: some View {
        ZStack {
            // 肥皂泡多层感
            Circle()
                .fill(RadialGradient(colors: [.white, color.opacity(0.3)], center: .topLeading, startRadius: 0, endRadius: 80))
                .frame(width: 140, height: 140)
                .overlay(Circle().stroke(color.opacity(0.5), lineWidth: 3))
                .scaleEffect(bubble.isWrong ? 1.5 : 1.0) // 气鼓鼓效果
            
            Text("\(bubble.number)")
                .font(.system(size: 45, weight: .black, design: .rounded))
                .foregroundColor(color)
        }
    }
}

struct MenuButton: View {
    let title: String; let icon: String; let color: Color
    var body: some View {
        VStack(spacing: 15) {
            Image(systemName: icon).font(.system(size: 40))
            Text(title).font(.headline)
        }
        .frame(width: 200, height: 200).background(color.opacity(0.1)).cornerRadius(30)
        .overlay(RoundedRectangle(cornerRadius: 30).stroke(color, lineWidth: 4))
    }
}
