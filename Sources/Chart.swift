import SwiftUI

enum Palette {
    static let background = Color(red: 16/255, green: 21/255, blue: 34/255)
    static let panel = Color(red: 26/255, green: 34/255, blue: 51/255)
    static let raised = Color(red: 38/255, green: 49/255, blue: 71/255)
    static let blue = Color(red: 67/255, green: 139/255, blue: 1)
    static let up = Color(red: 40/255, green: 201/255, blue: 145/255)
    static let down = Color(red: 239/255, green: 89/255, blue: 104/255)
    static let text = Color(red: 242/255, green: 245/255, blue: 250/255)
    static let muted = Color(red: 143/255, green: 156/255, blue: 178/255)
}

struct Panel<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View { content.padding(16).frame(maxWidth: .infinity, alignment: .leading).background(Palette.panel, in: RoundedRectangle(cornerRadius: 12)) }
}
struct LabButton: ButtonStyle {
    var prominent = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.system(.subheadline, design: .rounded, weight: .semibold))
            .padding(.horizontal, 14).frame(minHeight: 44).frame(maxWidth: .infinity)
            .background(prominent ? Palette.blue : Palette.raised, in: RoundedRectangle(cornerRadius: 8))
            .foregroundStyle(Palette.text).opacity(configuration.isPressed ? 0.7 : 1)
    }
}
struct Sparkline: View {
    let candles: [Candle]
    var body: some View {
        Canvas { ctx, size in
            let lo = candles.map(\.low).min() ?? 0
            let hi = candles.map(\.high).max() ?? 1
            var path = Path()
            for (i,c) in candles.enumerated() {
                let p = CGPoint(x: Double(i) / Double(max(1,candles.count - 1)) * size.width, y: size.height * (1 - (c.close - lo)/(hi - lo)))
                if i == 0 { path.move(to:p) } else { path.addLine(to:p) }
            }
            ctx.stroke(path, with: .color(Palette.blue), lineWidth: 2)
        }.accessibilityHidden(true)
    }
}

enum ChartMode: String, CaseIterable { case cursor = "Cursor", pan = "Pan", level = "Level", trend = "Trend line", zone = "Zone" }

struct CandleChart: View {
    let exercise: Exercise
    let revealed: Int
    var period = 1
    @Binding var marks: [Mark]
    @Binding var cursor: Int
    var mode: ChartMode = .cursor
    var reference = false
    var chartID = "candleChart"
    @State private var zoom: Double = 1
    @State private var offset: Double = 0
    @State private var dragOffset: Double?
    @State private var pinchStart: Double?
    @State private var preview: Mark?
    var candles: [Candle] {
        Candle.aggregate(Array(exercise.candles.prefix(revealed)), period: period)
    }

    var shown: [Candle] {
        let n = max(4, Int(Double(candles.count) / zoom))
        let end = max(min(candles.count, n), candles.count - Int(offset))
        return Array(candles[max(0, end - n)..<end])
    }
    var body: some View {
        VStack(spacing: 8) {
            GeometryReader { geometry in
                let width = max(1, geometry.size.width - 58)
                let height = max(1, geometry.size.height - 54)
                let data = shown
                let lo = (data.map(\.low).min() ?? 0) - 0.8
                let hi = (data.map(\.high).max() ?? 1) + 0.8
                let first = Double(data.first?.id ?? 0)
                let count = Double(max(1, data.count * period))
                let point: (Double, Double) -> CGPoint = { x,y in
                    CGPoint(x: (x - first + Double(period)/2) / count * width, y: (hi-y)/(hi-lo) * height)
                }
                Canvas { context, size in
                    for row in 0...5 {
                        let y = Double(row) / 5 * height
                        var line = Path(); line.move(to: CGPoint(x: 0, y: y)); line.addLine(to: CGPoint(x: width, y: y))
                        context.stroke(line, with: .color(Palette.raised), lineWidth: 0.7)
                        let value = hi - Double(row)/5 * (hi-lo)
                        context.draw(Text(String(format: "%.2f", value)).font(.system(size: 10, design: .monospaced)).foregroundColor(Palette.muted), at: CGPoint(x:width+6, y:max(7,min(height-7,y))), anchor:.leading)
                    }
                    for col in 0...6 {
                        let x = Double(col)/6 * width
                        var line = Path(); line.move(to:CGPoint(x:x, y:0)); line.addLine(to:CGPoint(x:x,y:height+30))
                        context.stroke(line, with:.color(Palette.raised.opacity(0.6)),lineWidth:0.7)
                    }
                    let maxVolume = data.map(\.volume).max() ?? 1
                    for c in data {
                        let p = point(Double(c.id), c.open)
                        let colour = c.rising ? Palette.up : Palette.down
                        var wick = Path(); wick.move(to:point(Double(c.id), c.high)); wick.addLine(to:point(Double(c.id),c.low))
                        context.stroke(wick, with:.color(colour),lineWidth:1.3)
                        let closeY = point(Double(c.id),c.close).y
                        let barWidth = max(2,width/Double(data.count)*0.58)
                        let body = CGRect(x:p.x-barWidth/2,y:min(p.y,closeY),width:barWidth,height:max(2,abs(p.y-closeY)))
                        context.fill(Path(body),with:.color(colour))
                        let volumeHeight = c.volume/maxVolume*26
                        context.fill(Path(CGRect(x:p.x-barWidth/2,y:height+32-volumeHeight,width:barWidth,height:volumeHeight)),with:.color(colour.opacity(0.35)))
                    }
                    var visibleMarks = reference ? referenceMarks : marks
                    if let preview { visibleMarks.append(preview) }
                    var clip = context
                    clip.clip(to:Path(CGRect(x:0,y:0,width:width,height:height)))
                    for mark in visibleMarks {
                        let p1 = point(mark.x1,mark.y1), p2 = point(mark.x2,mark.y2)
                        var path = Path()
                        switch mark.kind {
                        case .level: path.move(to:CGPoint(x:0,y:p1.y)); path.addLine(to:CGPoint(x:width,y:p1.y))
                        case .trend: path.move(to:p1); path.addLine(to:p2)
                        case .zone:
                            path.addRect(CGRect(x:min(p1.x,p2.x),y:min(p1.y,p2.y),width:max(3,abs(p2.x-p1.x)),height:max(3,abs(p2.y-p1.y))))
                            clip.fill(path,with:.color(Palette.blue.opacity(0.16)))
                        }
                        clip.stroke(path,with:.color(reference ? .orange : Palette.blue),style:StrokeStyle(lineWidth:2,dash:mark.kind == .level ? [5,4]:[]))
                    }
                    let selected = data.first { $0.id <= cursor && cursor < $0.id + period }
                    if let c = selected {
                        let p = point(Double(c.id),c.close)
                        var cross = Path(); cross.move(to:CGPoint(x:p.x,y:0)); cross.addLine(to:CGPoint(x:p.x,y:height+32)); cross.move(to:CGPoint(x:0,y:p.y)); cross.addLine(to:CGPoint(x:width,y:p.y))
                        context.stroke(cross,with:.color(Palette.text.opacity(0.55)),style:StrokeStyle(lineWidth:1,dash:[3,4]))
                        context.fill(Path(ellipseIn:CGRect(x:p.x-3,y:p.y-3,width:6,height:6)),with:.color(Palette.text))
                    }
                    context.draw(Text("\(data.first?.id ?? 0):00").font(.system(size:10,design:.monospaced)).foregroundColor(Palette.muted),at:CGPoint(x:4,y:size.height-7),anchor:.leading)
                    context.draw(Text("\(data.last?.id ?? 0):00 · section hours").font(.system(size:10,design:.monospaced)).foregroundColor(Palette.muted),at:CGPoint(x:width,y:size.height-7),anchor:.trailing)
                }
                .contentShape(Rectangle())
                .gesture(DragGesture(minimumDistance:0).onChanged { value in
                    if reference { return }
                    if mode == .pan {
                        if dragOffset == nil { dragOffset = offset }
                        offset = min(Double(max(0,candles.count-data.count)), max(0,(dragOffset ?? 0)+value.translation.width/width*Double(data.count)))
                    } else if mode == .cursor {
                        cursor = min(revealed-1,max(0,Int(first + value.location.x/width*count)))
                    } else {
                        let x1 = min(35,max(0,first+value.startLocation.x/width*count))
                        let y1 = hi-min(height,max(0,value.startLocation.y))/height*(hi-lo)
                        let x2 = min(35,max(0,first+value.location.x/width*count))
                        let y2 = hi-min(height,max(0,value.location.y))/height*(hi-lo)
                        let kind: MarkKind = mode == .level ? .level : (mode == .trend ? .trend : .zone)
                        preview = Mark(kind:kind,x1:x1,y1:mode == .level ? y2 : y1,x2:x2,y2:y2)
                    }
                }.onEnded { _ in
                    if let preview { marks.append(preview) }
                    preview = nil; dragOffset = nil
                })
                .simultaneousGesture(MagnificationGesture().onChanged { value in
                    if pinchStart == nil { pinchStart = zoom }
                    zoom = min(4,max(1,(pinchStart ?? 1)*value)); offset = 0
                }.onEnded { _ in pinchStart = nil })
                .accessibilityElement(children:.ignore)
                .accessibilityLabel("Candlestick chart. \(data.count) candles. \(exercise.instrument). Synthetic training data.")
                .accessibilityValue("Selected candle \(cursor+1). Use the candle stepper below to inspect prices.")
                .accessibilityIdentifier(chartID)
            }
            HStack {
                Label("Synthetic units · Offline", systemImage:"square.stack.3d.up").font(.system(size:11, weight:.medium)).foregroundStyle(Palette.muted)
                Spacer()
                Button { zoom = max(1,zoom-0.5); offset = 0 } label: { Image(systemName:"minus.magnifyingglass").frame(width:44,height:44) }.accessibilityLabel("Zoom out")
                Text(String(format:"%.1f×",zoom)).font(.system(size:12,design:.monospaced))
                Button { zoom = min(4,zoom+0.5); offset = 0 } label: { Image(systemName:"plus.magnifyingglass").frame(width:44,height:44) }.accessibilityLabel("Zoom in")
                Button { zoom=1; offset=0 } label: { Image(systemName:"arrow.up.left.and.arrow.down.right").frame(width:44,height:44) }.accessibilityLabel("Fit chart")
            }.foregroundStyle(Palette.blue)
        }
        .onChange(of: exercise.id) { _,_ in zoom=1;offset=0;cursor=0 }
        .onChange(of: period) { _,_ in zoom=1;offset=0;cursor=(cursor/period)*period }
        .onChange(of: shown.map(\.id)) { _,ids in
            if let first=ids.first, let last=ids.last { cursor=min(max(cursor,first),min(revealed-1,last+period-1)) }
        }
    }
    var referenceMarks: [Mark] {
        let data = exercise.candles
        if exercise.topic == .volume {
            return [Mark(kind:.zone,x1:0,y1:data.map(\.high).max()!,x2:5,y2:data.map(\.low).min()!), Mark(kind:.zone,x1:30,y1:data.map(\.high).max()!,x2:35,y2:data.map(\.low).min()!)]
        }
        if exercise.topic == .levels { return [Mark(kind:.level,x1:0,y1:exercise.highest,x2:35,y2:exercise.highest)] }
        if exercise.topic == .structures || exercise.topic == .candles {
            return [Mark(kind:.zone,x1:34,y1:data.last!.high,x2:36,y2:data.last!.low)]
        }
        return [Mark(kind:.trend,x1:0,y1:data.first!.close,x2:35,y2:data.last!.close)]
    }
}
