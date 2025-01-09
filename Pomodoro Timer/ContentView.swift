import SwiftUI

struct ColorSet {
    static let focusColors: [(start: Color, end: Color)] = [
        (Color(red: 0.98, green: 0.29, blue: 0.25), Color(red: 0.90, green: 0.22, blue: 0.20)), // Kırmızı
        (Color(red: 0.20, green: 0.60, blue: 0.86), Color(red: 0.10, green: 0.40, blue: 0.80)), // Mavi
        (Color(red: 0.60, green: 0.35, blue: 0.71), Color(red: 0.45, green: 0.25, blue: 0.65)), // Mor
        (Color(red: 1.00, green: 0.65, blue: 0.00), Color(red: 0.90, green: 0.55, blue: 0.00)), // Turuncu
        (Color(red: 0.18, green: 0.18, blue: 0.18), Color(red: 0.10, green: 0.10, blue: 0.10)), // Siyah
    ]
    
    static let breakColors: [(start: Color, end: Color)] = [
        (Color(red: 0.16, green: 0.71, blue: 0.46), Color(red: 0.10, green: 0.60, blue: 0.40)), // Yeşil
        (Color(red: 0.90, green: 0.80, blue: 0.20), Color(red: 0.80, green: 0.70, blue: 0.10)), // Sarı
        (Color(red: 0.87, green: 0.44, blue: 0.63), Color(red: 0.75, green: 0.35, blue: 0.55)), // Pembe
        (Color(red: 0.40, green: 0.80, blue: 0.90), Color(red: 0.30, green: 0.70, blue: 0.85)), // Açık Mavi
        (Color(red: 0.55, green: 0.90, blue: 0.77), Color(red: 0.45, green: 0.80, blue: 0.67)), // Turkuaz
    ]
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
        self.currentColorIndex = Int.random(in: 0..<5)
    }
    
    func start() {
        isActive = true
        currentColorIndex = Int.random(in: 0..<5)
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
        currentColorIndex = Int.random(in: 0..<5)  // Her mod değişiminde yeni renk
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
            Form {
                Section(header: Text("Timer Settings")) {
                    VStack {
                        Text("Work Time: \(Int(workTime)) min")
                        Slider(value: $workTime, in: 1...60, step: 1)
                    }
                    
                    VStack {
                        Text("Break Time: \(Int(breakTime)) min")
                        Slider(value: $breakTime, in: 1...30, step: 1)
                    }
                    
                    VStack {
                        Text("Cycles: \(Int(cycles))")
                        Slider(value: $cycles, in: 1...10, step: 1)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarItems(
                trailing: Button("Done") {
                    timerManager.updateSettings(workTime: Int(workTime), breakTime: Int(breakTime), cycles: Int(cycles))
                    isPresented = false
                }
            )
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
