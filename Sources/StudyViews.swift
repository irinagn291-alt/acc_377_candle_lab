import SwiftUI

struct MarkupView: View {
    @Bindable var store: LabStore
    @Environment(\.dismiss) private var dismiss
    @State private var mode = ChartMode.level
    @State private var cursor = 35
    @State private var undoStack: [[Mark]] = []
    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ScrollView {
                    VStack(alignment:.leading,spacing:16) {
                        Text(store.exercise.instrument).font(.title2.bold())
                        Text("Synthetic training · \(store.exercise.date(at:cursor))").font(.caption.monospaced()).foregroundStyle(Palette.muted)
                        ScrollView(.horizontal,showsIndicators:false) {
                            HStack(spacing:8) {
                                ForEach(ChartMode.allCases,id:\.self) { item in
                                    Button(item.rawValue) { mode=item }.buttonStyle(LabButton(prominent:mode==item)).fixedSize(horizontal:true,vertical:false)
                                }
                            }
                        }
                        CandleChart(exercise:store.exercise,revealed:36,marks:Binding(get:{store.marks},set:{ value in undoStack.append(store.marks);store.marks=value }),cursor:$cursor,mode:mode,chartID:"markupChart")
                            .frame(height:max(340,geo.size.height*0.61))
                        Text(instruction).font(.subheadline).foregroundStyle(Palette.muted)
                        Stepper("Selected candle: \(cursor+1)",value:$cursor,in:0...35).font(.subheadline)
                        HStack {
                            Button("Level at selected high") {
                                undoStack.append(store.marks)
                                let c=store.exercise.candles[cursor]
                                store.marks.append(Mark(kind:.level,x1:Double(cursor),y1:c.high,x2:35,y2:c.high))
                            }.buttonStyle(LabButton(prominent:true)).accessibilityIdentifier("accessibleLevel")
                            Button { if let last=undoStack.popLast() { store.marks=last } else if !store.marks.isEmpty { store.marks.removeLast() } } label: { Label("Undo",systemImage:"arrow.uturn.backward") }.buttonStyle(LabButton()).disabled(store.marks.isEmpty && undoStack.isEmpty)
                        }
                        Text("\(store.marks.count) saved annotations · \(store.error == nil ? "Saved on this device" : "Save needs attention")").font(.caption).foregroundStyle(Palette.muted)
                        if !store.marks.isEmpty {
                            ForEach(store.marks) { mark in
                                HStack { Text(mark.kind.rawValue);Spacer();Text(String(format:"%.2f → %.2f",mark.y1,mark.y2)).monospacedDigit() }.font(.caption).foregroundStyle(Palette.muted)
                            }
                        }
                    }.padding(16).frame(maxWidth:1200)
                }.frame(maxWidth:.infinity,maxHeight:.infinity).background(Palette.background)
            }.navigationTitle("Mark up").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement:.confirmationAction) { Button("Done") { dismiss() }.accessibilityIdentifier("markupDone") } }
        }.preferredColorScheme(.dark)
    }
    var instruction: String {
        switch mode {
        case .cursor: "Drag across the chart to select a candle."
        case .pan: "Pinch to zoom, then drag horizontally to explore the section."
        case .level: "Drag to position a horizontal level. Or select a candle below and place its high precisely."
        case .trend: "Drag from the first observation to the second to connect a trend line."
        case .zone: "Drag diagonally across a region to highlight a price zone."
        }
    }
}
struct ReviewView: View {
    @Bindable var store: LabStore
    let next: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var reference = true
    @State private var cursor = 35
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment:.leading,spacing:16) {
                    Text("See the reasoning.").font(.largeTitle.bold())
                    Text("\(store.exercise.instrument) · Synthetic training").font(.subheadline).foregroundStyle(Palette.muted)
                    Text(store.exercise.date(at:cursor)).font(.caption.monospaced()).foregroundStyle(Palette.muted)
                    Picker("Chart overlay",selection:$reference) { Text("My markup").tag(false);Text("Breakdown").tag(true) }.pickerStyle(.segmented)
                    CandleChart(exercise:store.exercise,revealed:36,marks:$store.marks,cursor:$cursor,reference:reference,chartID:"reviewChart").frame(height:360)
                    if !reference && store.marks.isEmpty { Label("No annotations yet. Add your observations in Mark up.",systemImage:"pencil.tip").font(.subheadline).foregroundStyle(Palette.muted) }
                    Panel {
                        VStack(alignment:.leading,spacing:12) {
                            Label("The criterion",systemImage:"checkmark.seal").font(.headline).foregroundStyle(Palette.blue)
                            Text(store.exercise.explanation).font(.body)
                            Divider()
                            Text("A useful description has a boundary.").font(.headline)
                            Text("This answer applies to this section and the stated rule. Other time frames and other definitions can produce different interpretations.").font(.subheadline).foregroundStyle(Palette.muted)
                        }
                    }
                    Text("Source: Candle Lab synthetic course, dataset v1. Fixed educational examples; no market update time applies.").font(.caption).foregroundStyle(Palette.muted)
                    Button("Next exercise") { dismiss();next() }.buttonStyle(LabButton(prominent:true)).accessibilityIdentifier("nextExercise")
                }.padding(16).frame(maxWidth:900)
            }.frame(maxWidth:.infinity,maxHeight:.infinity).background(Palette.background).navigationTitle("Breakdown").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement:.confirmationAction) { Button("Done") { dismiss() } } }
        }.preferredColorScheme(.dark)
    }
}
struct LessonsView: View {
    @Bindable var store: LabStore
    @Binding var tab: Int
    @State private var query = ""
    var filtered: [Topic] { Topic.allCases.filter { query.isEmpty || $0.rawValue.localizedCaseInsensitiveContains(query) || $0.subtitle.localizedCaseInsensitiveContains(query) } }
    var body: some View {
        ScrollView {
            VStack(alignment:.leading,spacing:16) {
                Text("Less guessing.\nMore understanding.").font(.system(size:30,weight:.bold,design:.rounded))
                Text("Six short reads. Twenty-four ways to practise.").foregroundStyle(Palette.muted)
                HStack { Image(systemName:"magnifyingglass");TextField("Search lessons",text:$query).accessibilityIdentifier("lessonSearch");if !query.isEmpty { Button { query="" } label: { Image(systemName:"xmark.circle.fill").frame(width:44,height:44) }.accessibilityLabel("Clear search") } }.padding(.horizontal,12).frame(minHeight:48).background(Palette.panel,in:RoundedRectangle(cornerRadius:8))
                if filtered.isEmpty { ContentUnavailableView("No matching lessons",systemImage:"magnifyingglass",description:Text("Try candles, trends, levels or volume.")).accessibilityIdentifier("emptyLessons") }
                ForEach(filtered) { topic in
                    NavigationLink {
                        LessonDetail(store:store,topic:topic,tab:$tab)
                    } label: {
                        Panel {
                            HStack(alignment:.top,spacing:16) {
                                Image(systemName:topic.symbol).font(.title2).foregroundStyle(Palette.blue).frame(width:40,height:44)
                                VStack(alignment:.leading,spacing:8) {
                                    Text(topic.rawValue).font(.headline)
                                    Text(topic.subtitle).font(.subheadline).foregroundStyle(Palette.muted)
                                    Label(store.state.readTopics.contains(topic.rawValue) ? "Read · 4 exercises" : "3 min · 4 exercises",systemImage:store.state.readTopics.contains(topic.rawValue) ? "checkmark.circle":"clock").font(.caption).foregroundStyle(Palette.blue)
                                }
                                Spacer();Image(systemName:"chevron.right").font(.caption).foregroundStyle(Palette.muted)
                            }
                        }
                    }.buttonStyle(.plain).accessibilityIdentifier("lesson-\(topic.rawValue)")
                }
            }.padding(16).frame(maxWidth:900)
        }.frame(maxWidth:.infinity,maxHeight:.infinity).background(Palette.background).navigationTitle("The library")
    }
}
struct LessonDetail: View {
    @Bindable var store: LabStore
    let topic: Topic
    @Binding var tab: Int
    var body: some View {
        ScrollView {
            VStack(alignment:.leading,spacing:24) {
                Image(systemName:topic.symbol).font(.system(size:40)).foregroundStyle(Palette.blue)
                Text(topic.rawValue).font(.largeTitle.bold())
                Text(topic.subtitle).font(.title3).foregroundStyle(Palette.muted)
                ForEach(topic.sections,id:\.0) { section in
                    VStack(alignment:.leading,spacing:12) { Text(section.0).font(.title2.bold());Text(section.1).font(.body).lineSpacing(5).foregroundStyle(Palette.muted) }
                }
                Button(store.state.readTopics.contains(topic.rawValue) ? "Read ✓" : "Mark as read") { store.state.readTopics.insert(topic.rawValue);store.save() }.buttonStyle(LabButton()).accessibilityIdentifier("markRead")
                Button("Practise this topic") { store.select(Topic.allCases.firstIndex(of:topic)!*4);tab=1 }.buttonStyle(LabButton(prominent:true))
            }.padding(16).frame(maxWidth:800)
        }.frame(maxWidth:.infinity,maxHeight:.infinity).background(Palette.background).navigationBarTitleDisplayMode(.inline)
    }
}
struct ProgressScreen: View {
    @Bindable var store: LabStore
    @Binding var tab: Int
    var body: some View {
        ScrollView {
            VStack(alignment:.leading,spacing:24) {
                Text("Understanding,\nmade visible.").font(.system(size:30,weight:.bold,design:.rounded))
                HStack(spacing:12) {
                    stat("Accuracy",store.accuracy().map{"\($0)%"} ?? "—")
                    stat("Mastered","\(store.state.mastered.count)/24")
                    stat("Read","\(store.state.readTopics.count)/6")
                }
                Text("Accuracy by topic").font(.title3.bold())
                Panel {
                    VStack(spacing:20) {
                        ForEach(Topic.allCases) { topic in
                            VStack(spacing:8) {
                                HStack { Text(topic.rawValue).font(.subheadline);Spacer();Text(store.accuracy(topic:topic).map{"\($0)%"} ?? "Not tried").font(.caption.monospacedDigit()).foregroundStyle(Palette.muted) }
                                ProgressView(value:Double(store.accuracy(topic:topic) ?? 0),total:100)
                            }.accessibilityElement(children:.combine)
                        }
                    }
                }
                Button { store.select(Topic.allCases.firstIndex(of:store.weakest)!*4);tab=1 } label: { HStack { Image(systemName:"arrow.clockwise");Text("Practise \(store.weakest.rawValue.lowercased())");Spacer();Image(systemName:"arrow.right") } }.buttonStyle(LabButton(prominent:true))
                Text("Recent mistakes").font(.title3.bold())
                let mistakes=Array(store.state.attempts.filter{ !$0.correct }.suffix(12).reversed())
                if mistakes.isEmpty {
                    Panel {
                        VStack(alignment:.leading,spacing:12) {
                            Image(systemName:"checklist").font(.title).foregroundStyle(Palette.blue)
                            Text(store.state.attempts.isEmpty ? "Your practice story starts here." : "No mistakes to revisit yet.").font(.headline)
                            Text("Every checked answer builds a picture of what to practise next.").font(.subheadline).foregroundStyle(Palette.muted)
                        }
                    }
                } else {
                    ForEach(mistakes) { attempt in
                        Button { store.select(attempt.exerciseID);tab=1 } label: {
                            Panel {
                                HStack {
                                    VStack(alignment:.leading,spacing:6) {
                                        Text(Exercise(id:attempt.exerciseID).topic.rawValue).font(.headline)
                                        Text(attempt.answer).font(.subheadline).foregroundStyle(Palette.muted)
                                        Text(attempt.date,format:.dateTime.month(.abbreviated).day().hour().minute()).font(.caption).foregroundStyle(Palette.muted)
                                    }
                                    Spacer();Image(systemName:"arrow.clockwise").foregroundStyle(Palette.blue)
                                }
                            }
                        }.buttonStyle(.plain)
                    }
                }
                Text("Accuracy includes all attempts. Mastery counts each correctly completed exercise once. Your progress stays on this device.").font(.caption).foregroundStyle(Palette.muted)
            }.padding(16).frame(maxWidth:900)
        }.frame(maxWidth:.infinity,maxHeight:.infinity).background(Palette.background).navigationTitle("Your progress")
    }
    func stat(_ label: String,_ value: String) -> some View {
        VStack(alignment:.leading,spacing:8) { Text(value).font(.system(size:28,weight:.bold,design:.rounded)).monospacedDigit().minimumScaleFactor(0.65).lineLimit(1);Text(label).font(.caption).foregroundStyle(Palette.muted) }.frame(maxWidth:.infinity,alignment:.leading).padding(12).background(Palette.panel,in:RoundedRectangle(cornerRadius:10))
    }
}
