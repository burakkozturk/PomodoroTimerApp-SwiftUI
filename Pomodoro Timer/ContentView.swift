import SwiftUI

struct ColorSet {
    static let focusColors: [(start: Color, end: Color)] = [
        (Color(hex: "cdb4db"), Color(hex: "cdb4db").opacity(0.8)), // Lila
        (Color(hex: "a8dadc"), Color(hex: "a8dadc").opacity(0.8)), // Açık Mavi
        (Color(hex: "1d3557"), Color(hex: "1d3557").opacity(0.8)), // Koyu Mavi
        (Color(hex: "457b9d"), Color(hex: "457b9d").opacity(0.8)), // Mavi
    ]
    
    static let breakColors: [(start: Color, end: Color)] = [
        (Color(hex: "e63946"), Color(hex: "e63946").opacity(0.8)), // Kırmızı
        (Color(hex: "bde0fe"), Color(hex: "bde0fe").opacity(0.8)), // Açık Mavi
        (Color(hex: "a2d2ff"), Color(hex: "a2d2ff").opacity(0.8)), // Mavi
        (Color(hex: "ffc8dd"), Color(hex: "ffc8dd").opacity(0.8)), // Pembe
    ]
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct TimerSettings: Codable {
    var workTime: Int = 25    // minutes
    var breakTime: Int = 5    // minutes
    var cycles: Int = 4       // number of cycles
}

class TimerManager: ObservableObject {
    @Published private(set) var settings: TimerSettings
    @Published private(set) var timeRemaining: Int
    @Published private(set) var isActive: Bool
    @Published private(set) var isWorkTime: Bool
    @Published private(set) var currentCycle: Int
    @Published private(set) var currentColorIndex: Int
    private var timer: Timer?
    
    init() {
        let initialSettings = TimerSettings()
        self.settings = initialSettings
        self.timeRemaining = initialSettings.workTime * 60
        self.isActive = false
        self.isWorkTime = true
        self.currentCycle = 1
        self.currentColorIndex = Int.random(in: 0..<4)
    }
    
    func start() {
        isActive = true
        currentColorIndex = Int.random(in: 0..<4)
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.timeRemaining > 0 {
                self.timeRemaining -= 1
            } else {
                self.switchMode()
            }
        }
    }
    
    func pause() {
        isActive = false
        timer?.invalidate()
        timer = nil
    }
    
    func reset() {
        pause()
        isWorkTime = true
        currentCycle = 1
        timeRemaining = settings.workTime * 60
    }
    
    func switchMode() {
        isWorkTime.toggle()
        currentColorIndex = Int.random(in: 0..<4)  // Her mod değişiminde yeni renk
        if isWorkTime {
            currentCycle += 1
            if currentCycle > settings.cycles {
                reset()
                return
            }
        }
        timeRemaining = (isWorkTime ? settings.workTime : settings.breakTime) * 60
    }
    
    func updateSettings(workTime: Int, breakTime: Int, cycles: Int) {
        settings = TimerSettings(workTime: workTime, breakTime: breakTime, cycles: cycles)
        reset()
    }
}

struct SettingsView: View {
    @Binding var isPresented: Bool
    @ObservedObject var timerManager: TimerManager
    @State private var workTime: Double
    @State private var breakTime: Double
    @State private var cycles: Double
    
    init(isPresented: Binding<Bool>, timerManager: TimerManager) {
        self._isPresented = isPresented
        self.timerManager = timerManager
        self._workTime = State(initialValue: Double(timerManager.settings.workTime))
        self._breakTime = State(initialValue: Double(timerManager.settings.breakTime))
        self._cycles = State(initialValue: Double(timerManager.settings.cycles))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    List {
                        Section {
                            VStack(spacing: 15) {
                                settingRow(
                                    icon: "hourglass",
                                    title: "Work Time",
                                    value: "\(Int(workTime)) min",
                                    color: .red
                                ) {
                                    Slider(value: $workTime, in: 1...60, step: 1)
                                        .accentColor(.red)
                                }
                                
                                settingRow(
                                    icon: "cup.and.saucer.fill",
                                    title: "Break Time",
                                    value: "\(Int(breakTime)) min",
                                    color: .green
                                ) {
                                    Slider(value: $breakTime, in: 1...30, step: 1)
                                        .accentColor(.green)
                                }
                                
                                settingRow(
                                    icon: "repeat",
                                    title: "Cycles",
                                    value: "\(Int(cycles))",
                                    color: .blue
                                ) {
                                    Slider(value: $cycles, in: 1...10, step: 1)
                                        .accentColor(.blue)
                                }
                            }
                            .padding(.vertical, 8)
                        } header: {
                            Text("Timer Settings")
                                .font(.headline)
                                .foregroundColor(.primary)
                                .textCase(nil)
                                .padding(.bottom, 8)
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
            .navigationTitle("Settings")
            .navigationBarItems(
                trailing: Button(action: {
                    timerManager.updateSettings(workTime: Int(workTime), breakTime: Int(breakTime), cycles: Int(cycles))
                    isPresented = false
                }) {
                    Text("Done")
                        .bold()
                        .foregroundColor(.blue)
                }
            )
        }
    }
    
    private func settingRow<Content: View>(
        icon: String,
        title: String,
        value: String,
        color: Color,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 20))
                    .frame(width: 30)
                
                Text(title)
                    .font(.system(size: 17, weight: .medium))
                
                Spacer()
                
                Text(value)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            content()
                .padding(.leading, 30)
        }
    }
}

struct ContentView: View {
    @StateObject private var timerManager = TimerManager()
    @State private var showSettings = false
    
    var body: some View {
        ZStack {
            backgroundGradient
                .edgesIgnoringSafeArea(.all)
                .animation(.easeInOut(duration: 0.3), value: timerManager.timeRemaining)
            
            if timerManager.isActive {
                VStack(spacing: 30) {
                    Spacer()
                    
                    Text(timerManager.isWorkTime ? "FOCUS" : "BREAK")
                        .font(.system(size: 80, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                        .scaleEffect(1.0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.6), value: timerManager.isWorkTime)
                    
                    ZStack {
                        // Background Circle
                        Circle()
                            .stroke(lineWidth: 20)
                            .opacity(0.3)
                            .foregroundColor(.white)
                        
                        // Timer Circle
                        Circle()
                            .trim(from: 0, to: CGFloat(timerManager.timeRemaining) / 
                                  CGFloat(timerManager.isWorkTime ? 
                                         timerManager.settings.workTime * 60 : 
                                         timerManager.settings.breakTime * 60))
                            .stroke(style: StrokeStyle(lineWidth: 20, lineCap: .round))
                            .foregroundColor(.white)
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 1), value: timerManager.timeRemaining)
                        
                        VStack(spacing: 10) {
                            Text("\(timerManager.timeRemaining / 60):\(String(format: "%02d", timerManager.timeRemaining % 60))")
                                .font(.system(size: 70, weight: .thin, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text("Cycle \(timerManager.currentCycle)/\(timerManager.settings.cycles)")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .frame(width: 300, height: 300)
                    .padding()
                    
                    Button(action: {
                        timerManager.pause()
                    }) {
                        Image(systemName: "stop.circle.fill")
                            .resizable()
                            .frame(width: 70, height: 70)
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 3)
                    }
                    
                    Spacer()
                }
            } else {
                VStack(spacing: 40) {
                    Spacer()
                    
                    Button(action: {
                        timerManager.start()
                    }) {
                        Image(systemName: "play.circle.fill")
                            .resizable()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                    }
                    
                    Button(action: {
                        showSettings = true
                    }) {
                        Image(systemName: "gear.circle.fill")
                            .resizable()
                            .frame(width: 40, height: 40)
                            .foregroundColor(.white.opacity(0.8))
                            .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 3)
                    }
                    
                    Spacer()
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(isPresented: $showSettings, timerManager: timerManager)
        }
    }
    
    private var backgroundGradient: LinearGradient {
        let progress = timerManager.isActive ? 
            Double(timerManager.timeRemaining) / Double(timerManager.isWorkTime ? 
                                                      timerManager.settings.workTime * 60 : 
                                                      timerManager.settings.breakTime * 60) : 1.0
        
        let startColor = timerManager.isWorkTime ?
            ColorSet.focusColors[timerManager.currentColorIndex].start :
            ColorSet.breakColors[timerManager.currentColorIndex].start
        
        let endColor = timerManager.isWorkTime ?
            ColorSet.focusColors[timerManager.currentColorIndex].end.opacity(progress) :
            ColorSet.breakColors[timerManager.currentColorIndex].end.opacity(progress)
        
        return LinearGradient(
            gradient: Gradient(colors: [startColor, endColor]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
