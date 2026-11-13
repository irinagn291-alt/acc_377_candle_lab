import SwiftUI

@main struct CandleLabApp: App {
    @State private var store: LabStore
    init() {
        #if DEBUG && targetEnvironment(simulator)
        if let launch = ScreenshotLaunch.current {
            _store = State(initialValue: launch.makeStore())
        } else {
            _store = State(initialValue: LabStore())
        }
        #else
        _store = State(initialValue: LabStore())
        #endif
    }
    var body: some Scene {
        WindowGroup {
            RootView(store:store)
                .preferredColorScheme(.dark)
                .tint(Palette.blue)
                .environment(\.locale, Locale(identifier:"en_GB"))
                .environment(\.layoutDirection, .leftToRight)
        }
    }
}
struct RootView: View {
    @Bindable var store: LabStore
    @State private var tab = 1
    @State private var confirmReset = false
    #if DEBUG && targetEnvironment(simulator)
    @State private var screenshotLessonPath: [Topic] = []
    #endif
    init(store: LabStore) {
        self.store = store
        #if DEBUG && targetEnvironment(simulator)
        if let launch = ScreenshotLaunch.current {
            _tab = State(initialValue: launch.tab)
            _screenshotLessonPath = State(initialValue: launch.key == "lesson-detail" ? [.candles] : [])
        }
        #endif
    }
    var body: some View {
        ZStack {
            Palette.background.ignoresSafeArea()
            if store.loading {
                ProgressView("Opening your lab…").task {
                    #if DEBUG
                    if ProcessInfo.processInfo.arguments.contains("--ui-testing") {
                        try? FileManager.default.removeItem(at:store.url)
                    }
                    #endif
                    store.load(); tab = store.state.started ? 0 : 1
                }
            } else {
                TabView(selection:$tab) {
                    NavigationStack { OverviewView(store:store,tab:$tab) }.tabItem { Label("Overview",systemImage:"square.grid.2x2") }.tag(0)
                    NavigationStack { PracticeView(store:store) }.tabItem { Label("Practice",systemImage:"chart.xyaxis.line") }.tag(1)
                    #if DEBUG && targetEnvironment(simulator)
                    if ScreenshotLaunch.current != nil {
                        NavigationStack(path:$screenshotLessonPath) {
                            LessonsView(store:store,tab:$tab)
                                .navigationDestination(for:Topic.self) { topic in
                                    LessonDetail(store:store,topic:topic,tab:$tab)
                                }
                        }.tabItem { Label("Lessons",systemImage:"book.closed") }.tag(2)
                    } else {
                        NavigationStack { LessonsView(store:store,tab:$tab) }.tabItem { Label("Lessons",systemImage:"book.closed") }.tag(2)
                    }
                    #else
                    NavigationStack { LessonsView(store:store,tab:$tab) }.tabItem { Label("Lessons",systemImage:"book.closed") }.tag(2)
                    #endif
                    NavigationStack { ProgressScreen(store:store,tab:$tab) }.tabItem { Label("Progress",systemImage:"chart.bar") }.tag(3)
                }
                .toolbarBackground(Palette.panel,for:.tabBar)
                .toolbarBackground(.visible,for:.tabBar)
                .safeAreaInset(edge:.top) {
                    if let error = store.error {
                        VStack(alignment:.leading,spacing:8) {
                            Label(error,systemImage:"exclamationmark.triangle").font(.footnote)
                            HStack {
                                Button("Retry") { if store.loadFailed { store.load() } else { store.save() } }
                                if store.loadFailed { Button("Reset local save",role:.destructive) { confirmReset=true } }
                            }.buttonStyle(.bordered)
                        }.padding(12).background(Palette.raised)
                    }
                }
                .confirmationDialog("Reset your saved progress and drawings?",isPresented:$confirmReset,titleVisibility:.visible) {
                    Button("Reset local save",role:.destructive) { store.reset() }
                }
            }
        }.foregroundStyle(Palette.text)
        .onOpenURL { url in
            if WidgetIdentity.accepts(url) { if store.loading { store.load() }
                #if DEBUG && targetEnvironment(simulator)
                store.applyWidgetQA(url)
                #endif
                tab = 1
            }
        }
        #if DEBUG && targetEnvironment(simulator)
        .transaction { transaction in
            if ScreenshotLaunch.current != nil { transaction.disablesAnimations = true; transaction.animation = nil }
        }
        #endif
    }
}

struct BrandHeader: View {
    var body: some View {
        HStack(spacing:10) {
            ZStack {
                RoundedRectangle(cornerRadius:10).fill(Palette.blue.opacity(0.15)).frame(width:40,height:40)
                Image(systemName:"chart.bar.xaxis").font(.title3).foregroundStyle(Palette.blue)
            }
            VStack(alignment:.leading,spacing:2) {
                Text("CANDLE LAB").font(.system(size:16,weight:.heavy,design:.rounded)).tracking(2)
                Text("Learn to read the chart").font(.caption).foregroundStyle(Palette.muted)
            }
            Spacer()
            Image(systemName:"checkmark.icloud").foregroundStyle(Palette.muted).accessibilityLabel("Course available offline")
        }
    }
}
struct OverviewView: View {
    @Bindable var store: LabStore
    @Binding var tab: Int
    var body: some View {
        ScrollView {
            VStack(alignment:.leading,spacing:24) {
                BrandHeader()
                VStack(alignment:.leading,spacing:8) {
                    Text("A clearer view.\nOne candle at a time.").font(.system(size:32,weight:.bold,design:.rounded))
                    Text("Your personal chart-reading workspace.").font(.subheadline).foregroundStyle(Palette.muted)
                }
                Panel {
                    VStack(alignment:.leading,spacing:16) {
                        HStack {
                            Label("FOUNDATIONS",systemImage:"square.stack.3d.up").font(.caption.weight(.bold)).tracking(1.5).foregroundStyle(Palette.blue)
                            Spacer(); Text("\(store.state.mastered.count) / 24").font(.system(.subheadline,design:.monospaced))
                        }
                        Text(store.exercise.title).font(.title2.bold())
                        ProgressView(value:Double(store.state.mastered.count),total:24)
                        Button { tab=1 } label: { HStack { Text("Continue breakdown"); Spacer(); Image(systemName:"arrow.right") } }.buttonStyle(LabButton(prominent:true))
                    }
                }
                HStack { Text("Training instruments").font(.title3.bold()); Spacer(); Text("DEMO").font(.caption2.bold()).padding(6).background(Palette.raised,in:Capsule()) }
                VStack(spacing:1) {
                    ForEach(0..<3) { index in
                        let exercise = Exercise(id:4+index)
                        Button { store.select(exercise.id);tab=1 } label: {
                            HStack(spacing:16) {
                                Text(["€","£","¥"][exercise.id % 3]).font(.title2).frame(width:40,height:40).background(Palette.raised,in:Circle())
                                VStack(alignment:.leading,spacing:4) { Text(exercise.instrument).font(.headline);Text("Synthetic · 36 candles").font(.caption).foregroundStyle(Palette.muted) }
                                Spacer()
                                Sparkline(candles:exercise.candles).frame(width:70,height:32)
                                Image(systemName:"chevron.right").font(.caption).foregroundStyle(Palette.muted)
                            }.padding(16).background(Palette.panel)
                        }.buttonStyle(.plain)
                    }
                }.clipShape(RoundedRectangle(cornerRadius:12))
                Text("Build your eye").font(.title3.bold())
                ForEach(Topic.allCases) { topic in
                    Button { store.select(Topic.allCases.firstIndex(of:topic)!*4); tab=1 } label: {
                        HStack(spacing:14) {
                            Image(systemName:topic.symbol).foregroundStyle(Palette.blue).frame(width:32)
                            VStack(alignment:.leading,spacing:4) { Text(topic.rawValue).font(.headline);Text(topic.subtitle).font(.caption).foregroundStyle(Palette.muted) }
                            Spacer();Image(systemName:"arrow.up.right").foregroundStyle(Palette.muted)
                        }.padding(16).background(Palette.panel,in:RoundedRectangle(cornerRadius:10))
                    }.buttonStyle(.plain)
                }
                Text("Candle Lab synthetic course · Dataset v1\nBundled examples. No live feed. Works entirely offline.").font(.caption).foregroundStyle(Palette.muted)
            }.padding(16).frame(maxWidth:900)
        }.frame(maxWidth:.infinity,maxHeight:.infinity).background(Palette.background).toolbar(.hidden,for:.navigationBar)
    }
}

struct PracticeView: View {
    @Bindable var store: LabStore
    @State private var cursor = 35
    @State private var period = 1
    @State private var mode = ChartMode.cursor
    @State private var editor = false
    @State private var result: Bool?
    @State private var reviewing = false
    @State private var playing = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var ex: Exercise { store.exercise }
    init(store: LabStore) {
        self.store = store
        #if DEBUG && targetEnvironment(simulator)
        if let launch = ScreenshotLaunch.current {
            _editor = State(initialValue: ["markup", "drawing-tools"].contains(launch.key))
            _reviewing = State(initialValue: launch.key == "breakdown")
            _result = State(initialValue: launch.key == "feedback" ? false : (launch.key == "breakdown" ? true : nil))
        }
        #endif
    }
    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(alignment:.leading,spacing:12) {
                    header
                    if !store.state.started {
                        HStack(alignment:.top,spacing:12) {
                            Image(systemName:"hand.draw").foregroundStyle(Palette.blue)
                            Text("Your first 60 seconds: inspect a candle, then answer below. Every chart is a synthetic learning example.").font(.subheadline)
                        }.padding(12).background(Palette.blue.opacity(0.12),in:RoundedRectangle(cornerRadius:8))
                    }
                    selectors
                    VStack(alignment:.leading,spacing:8) {
                        HStack { Label("TRAINING DATA",systemImage:"circle.hexagongrid").foregroundStyle(Palette.blue);Spacer();Text("1H SOURCE") }.font(.system(size:10,weight:.bold,design:.monospaced))
                        Text(ex.date(at:min(cursor,store.revealed-1))).font(.system(size:12,design:.monospaced)).foregroundStyle(Palette.muted)
                        ohlc
                        CandleChart(exercise:ex,revealed:store.revealed,period:period,marks:$store.marks,cursor:$cursor,mode:mode)
                            .frame(height:max(300,min(540,geo.size.height*0.55)))
                        HStack {
                            Picker("Interaction",selection:$mode) { Text("Cursor").tag(ChartMode.cursor);Text("Pan").tag(ChartMode.pan) }.pickerStyle(.segmented)
                            Button { playing=false;editor=true } label: { Label("Mark up",systemImage:"pencil.tip.crop.circle") }.buttonStyle(LabButton()).accessibilityIdentifier("markup")
                        }
                        Stepper(value:$cursor,in:0...max(0,store.revealed-1)) { Text("Candle \(cursor+1) / \(store.revealed)").font(.caption.monospacedDigit()) }.accessibilityIdentifier("cursorStepper")
                    }.padding(12).background(Palette.panel,in:RoundedRectangle(cornerRadius:10))
                    replayControls
                    taskPanel
                }.padding(16).frame(maxWidth:1100)
            }
            #if DEBUG && targetEnvironment(simulator)
            .defaultScrollAnchor(ScreenshotLaunch.current?.key == "feedback" ? .bottom : .top)
            #endif
            .frame(maxWidth:.infinity,maxHeight:.infinity).background(Palette.background)
        }
        .toolbar(.hidden,for:.navigationBar)
        .fullScreenCover(isPresented:$editor) { MarkupView(store:store) }
        .sheet(isPresented:Binding(get:{ reviewing && !captureReview },set:{ reviewing=$0 })) { ReviewView(store:store) { result=nil;store.select((store.state.current+1)%24) } }
        #if DEBUG && targetEnvironment(simulator)
        .fullScreenCover(isPresented:Binding(get:{ reviewing && captureReview },set:{ reviewing=$0 })) { ReviewView(store:store) { result=nil;store.select((store.state.current+1)%24) } }
        #endif
        .onChange(of:store.state.current) { _,_ in result=nil;cursor=store.revealed-1;playing=false;period=1 }
        .task(id:playing) {
            guard playing else { return }
            while !Task.isCancelled && playing && store.revealed < 36 {
                try? await Task.sleep(for:.milliseconds(800))
                if Task.isCancelled { return }
                store.revealed += 1;cursor=store.revealed-1
            }
            playing=false
        }
        .onAppear { cursor=min(cursor,store.revealed-1) }
        .onChange(of:store.revealed) { _,value in cursor=min(cursor,value-1) }
        .onDisappear { playing=false }
    }
    private var captureReview: Bool {
        #if DEBUG && targetEnvironment(simulator)
        ScreenshotLaunch.current?.key == "breakdown"
        #else
        false
        #endif
    }
    var header: some View {
        HStack {
            VStack(alignment:.leading,spacing:4) {
                Text("PRACTICE LAB").font(.system(size:11,weight:.bold)).tracking(2).foregroundStyle(Palette.blue)
                Text(ex.topic.rawValue).font(.title2.bold())
            }
            Spacer()
            Menu {
                ForEach(Exercise.all) { exercise in Button("\(exercise.id+1). \(exercise.topic.rawValue) · \(exercise.variant+1)") { store.select(exercise.id) } }
            } label: { VStack { Text("Lesson").font(.caption);Text("\(ex.id+1) / 24").font(.system(.headline,design:.monospaced)) }.padding(10).background(Palette.raised,in:RoundedRectangle(cornerRadius:8)) }
            .accessibilityLabel("Choose lesson").accessibilityIdentifier("chooseLesson")
        }
    }
    var selectors: some View {
        HStack(spacing:12) {
            Menu {
                ForEach(0..<3) { instrument in
                    Button(["EUR / USD","GBP / USD","USD / JPY"][instrument]) {
                        let base=ex.id/4*4
                        let id=(base..<base+4).first { $0%3 == instrument } ?? base
                        store.select(id)
                    }
                }
            } label: { HStack { Image(systemName:"chart.bar.xaxis");Text(ex.instrument).bold();Image(systemName:"chevron.down").font(.caption) }.frame(minHeight:44) }
            Spacer()
            Picker("Candle interval",selection:$period) { Text("1H").tag(1);Text("3H").tag(3);Text("6H").tag(6) }.pickerStyle(.segmented).frame(maxWidth:190)
        }
    }
    var ohlc: some View {
        let aggregated = Candle.aggregate(Array(ex.candles.prefix(store.revealed)),period:period)
        let candle = aggregated[min(max(0,cursor/period),aggregated.count-1)]
        return ViewThatFits {
            HStack(spacing:12) { price("O",candle.open);price("H",candle.high);price("L",candle.low);price("C",candle.close) }
            VStack(alignment:.leading) { HStack { price("O",candle.open);price("H",candle.high) };HStack { price("L",candle.low);price("C",candle.close) } }
        }.accessibilityElement(children:.combine)
    }
    func price(_ label: String,_ value: Double) -> some View {
        HStack(spacing:4) { Text(label).foregroundStyle(Palette.muted);Text(String(format:"%.2f",value)) }.font(.system(size:11,weight:.medium,design:.monospaced))
    }
    var replayControls: some View {
        HStack(spacing:8) {
            Button { playing=false;store.revealed=6;cursor=5;result=nil } label: { Image(systemName:"backward.end").frame(width:44,height:44) }.accessibilityLabel("Restart replay")
            Button { if store.revealed==36 { store.revealed=6;cursor=5 };playing.toggle() } label: { Image(systemName:playing ? "pause.fill":"play.fill").frame(width:44,height:44) }.accessibilityLabel(playing ? "Pause replay":"Play replay")
            Text("\(store.revealed) / 36").font(.system(size:12,design:.monospaced)).monospacedDigit()
            Spacer()
            Button { playing=false;store.revealed+=1;cursor=store.revealed-1 } label: { Label("Step",systemImage:"forward.frame") }.buttonStyle(LabButton()).disabled(store.revealed==36)
            Button { playing=false;store.revealed=36;cursor=35 } label: { Text("All") }.buttonStyle(LabButton()).accessibilityLabel("Reveal all candles")
        }.foregroundStyle(Palette.blue)
    }
    var taskPanel: some View {
        Panel {
            VStack(alignment:.leading,spacing:12) {
                HStack { Text("\(String(format:"%02d",ex.id+1))  /  OBSERVE & EXPLAIN").font(.caption.weight(.bold)).foregroundStyle(Palette.blue);Spacer();Image(systemName:"lightbulb") }
                Text(ex.prompt).font(.headline)
                if period != 1 { Text("Chart aggregated to \(period)H. Answers use the full 1H source section.").font(.caption).foregroundStyle(Palette.muted) }
                if store.revealed < 36 {
                    Label("Reveal all 36 candles before checking this section.",systemImage:"info.circle").font(.subheadline).foregroundStyle(Palette.muted)
                } else if let result {
                    Label(result ? "Criterion met" : "Let’s look again",systemImage:result ? "checkmark.circle.fill":"arrow.clockwise").foregroundStyle(Palette.blue).font(.headline)
                    Text(ex.explanation).font(.subheadline).foregroundStyle(Palette.muted)
                    HStack {
                        Button("Review chart") { reviewing=true }.buttonStyle(LabButton(prominent:true)).accessibilityIdentifier("review")
                        Button("Try again") { self.result=nil }.buttonStyle(LabButton())
                    }
                } else if ex.topic == .levels {
                    Text("Add a Level in Mark up. Tolerance: ±\(String(format:"%.2f",ex.tolerance)).").font(.caption).foregroundStyle(Palette.muted)
                    Button("Check my level") { submit(ex.accepts(store.marks),"Horizontal level") }.buttonStyle(LabButton(prominent:true)).disabled(!store.marks.contains{$0.kind == .level})
                } else {
                    ForEach(Array(ex.choices.enumerated()),id:\.offset) { i,choice in
                        Button { submit(i==ex.correctChoice,choice) } label: { HStack { Text(choice);Spacer();Image(systemName:"arrow.right") } }.buttonStyle(LabButton(prominent:i==0)).accessibilityIdentifier("answer\(i)")
                    }
                }
            }
        }
    }
    func submit(_ correct: Bool,_ answer: String) {
        withAnimation(reduceMotion ? nil : .easeInOut(duration:0.2)) { result=correct }
        store.record(correct:correct,answer:answer)
    }
}

#if DEBUG && targetEnvironment(simulator)
/// Explicit capture launches use their own disposable store and the app's normal views.
private struct ScreenshotLaunch {
    let key: String
    private static let keys = ["overview", "practice", "markup", "breakdown", "lessons", "lesson-detail", "progress", "feedback", "drawing-tools"]
    static let current: ScreenshotLaunch? = {
        let process = ProcessInfo.processInfo
        let args = process.arguments
        func value(after flag: String) -> String? {
            guard let index = args.firstIndex(of: flag), args.indices.contains(index + 1) else { return nil }
            return args[index + 1]
        }
        if let key = value(after: "-ReviewScreen"), keys.contains(key) {
            return ScreenshotLaunch(key: key)
        }
        let envFlag = process.environment["APPSTORE_SCREENSHOTS"]?.lowercased()
        let enabled = args.contains("-AppStoreScreenshots") || (envFlag != nil && !["", "0", "false", "no"].contains(envFlag!))
        guard enabled else { return nil }
        let rawIndex = value(after: "-AppStoreScreenshotScreen") ?? process.environment["APPSTORE_SCREENSHOT_SCREEN"] ?? "0"
        guard let index = Int(rawIndex), keys.indices.contains(index) else { return nil }
        return ScreenshotLaunch(key: keys[index])
    }()
    var tab: Int {
        switch key {
        case "overview": 0
        case "practice", "markup", "breakdown", "feedback", "drawing-tools": 1
        case "lessons", "lesson-detail": 2
        default: 3
        }
    }
    @MainActor func makeStore() -> LabStore {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("CandleLab-screenshot-\(UUID().uuidString)", isDirectory: true)
            .appendingPathComponent("progress.json")
        let store = LabStore(url: url)
        store.loading = false
        store.state.current = key == "markup" ? 8 : 0
        store.state.replay[String(store.state.current)] = 36
        if ["overview", "breakdown", "progress"].contains(key) {
            if key == "progress" {
                store.state.attempts.append(Attempt(exerciseID: 0, correct: false, answer: "Not the widest"))
            }
            store.state.attempts.append(Attempt(exerciseID: 0, correct: true, answer: "Widest range"))
            store.state.started = true
        }
        if ["lessons", "lesson-detail", "progress"].contains(key) {
            store.state.readTopics.insert(Topic.candles.rawValue)
        }
        if key == "feedback" { store.state.started = true }
        if key == "drawing-tools" {
            store.state.started = true
            let candles = store.exercise.candles
            store.state.marks["0"] = [
                Mark(kind: .zone, x1: 10, y1: candles[10].low, x2: 24, y2: candles[24].high),
                Mark(kind: .trend, x1: 4, y1: candles[4].low, x2: 29, y2: candles[29].low)
            ]
        }
        if key == "markup" {
            store.state.started = true
            let candles = store.exercise.candles
            store.state.marks["8"] = [
                Mark(kind: .level, x1: 35, y1: candles[35].high, x2: 35, y2: candles[35].high),
                Mark(kind: .trend, x1: 4, y1: candles[4].low, x2: 29, y2: candles[29].low)
            ]
        }
        return store
    }
}
#endif
