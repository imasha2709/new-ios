import SwiftUI
import Combine

struct LightItUpView: View {
    @State private var cards: [Card] = []
    @State private var score = 0
    @State private var timeLeft = 60
    @State private var columns = 3
    @State private var gameOver = false
    
    @AppStorage("lightHighScore") var highScore = 0
    
    let gameTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 15) {
            // MARK: - Header
            VStack(spacing: 5) {
                HStack(spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.orange)
                    Text("Light It Up")
                        .font(.largeTitle)
                        .fontWeight(.black)
                }
                Text("High Score: \(highScore)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 50) {
                Text("Score: \(score)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .contentTransition(.numericText(value: Double(score)))
                
                Text("Time: \(timeLeft)s")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(timeLeft <= 10 ? .red : .primary)
            }
            .padding(.vertical, 10)
            
            // MARK: - Main Interactive Matrix Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: columns), spacing: 12) {
                ForEach(cards.indices, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 16)
                        .fill(cards[index].isLit ? Color.yellow : Color(.systemGray5))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(cards[index].isLit ? Color.orange : Color.clear, lineWidth: 2)
                        )
                        .shadow(color: cards[index].isLit ? .init(.displayP3, red: 1, green: 0.8, blue: 0, opacity: 0.4) : .clear, radius: 8)
                        .frame(height: 90)
                        .scaleEffect(cards[index].isLit ? 1.03 : 1.0)
                        .onTapGesture {
                            guard !gameOver else { return }
                            handleTap(at: index)
                        }
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: columns)
            .animation(.snappy, value: cards.map { $0.isLit })
            .padding()
            
            Spacer()
            
            // MARK: - Game Over Control Menu
            if gameOver {
                Button {
                    withAnimation(.spring()) { startGame() }
                } label: {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Play Again")
                    }
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 35)
                    .padding(.vertical, 15)
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding()
        .onAppear {
            startGame()
        }
        .onReceive(gameTimer) { _ in
            guard !gameOver else { return }
            
            if timeLeft > 0 {
                timeLeft -= 1
                updateLevel()
                lightRandomCard()
            } else {
                withAnimation(.bouncy) {
                    gameOver = true
                    if score > highScore { highScore = score }
                }
            }
        }
    }
    
    // MARK: - Helper Logics
    func handleTap(at index: Int) {
        guard index < cards.count else { return }
        if cards[index].isLit {
            score += 1
            cards[index].isLit = false
            lightRandomCard()
        } else {
            score -= 1
        }
    }
    
    func startGame() {
        score = 0
        timeLeft = 60
        gameOver = false
        columns = 3
        resetCards(count: 3)
    }
    
    func lightRandomCard() {
        guard !cards.isEmpty else { return }
        for i in cards.indices { cards[i].isLit = false }
        let randomIndex = Int.random(in: 0..<cards.count)
        cards[randomIndex].isLit = true
    }
    
    func updateLevel() {
        let targetCount: Int
        let targetColumns: Int
        
        if timeLeft > 45 {
            targetColumns = 3; targetCount = 3
        } else if timeLeft > 30 {
            targetColumns = 4; targetCount = 4
        } else if timeLeft > 15 {
            targetColumns = 3; targetCount = 6
        } else {
            targetColumns = 3; targetCount = 9
        }
        
        if cards.count != targetCount {
            columns = targetColumns
            resetCards(count: targetCount)
        }
    }
    
    func resetCards(count: Int) {
        cards = (0..<count).map { _ in Card() }
        lightRandomCard() // Ensure at least one random card lights up on generation split
    }
}

#Preview {
    LightItUpView()
}
