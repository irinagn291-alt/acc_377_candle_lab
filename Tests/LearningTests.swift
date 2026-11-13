import XCTest
@testable import CandleLab

final class LearningTests: XCTestCase {
    func testAllCourseDataAndAnswers() {
        XCTAssertEqual(Exercise.all.count,24)
        for ex in Exercise.all {
            XCTAssertEqual(ex.candles.count,36)
            for c in ex.candles {
                XCTAssertGreaterThanOrEqual(c.high,max(c.open,c.close))
                XCTAssertLessThanOrEqual(c.low,min(c.open,c.close))
                XCTAssertGreaterThan(c.volume,0)
            }
            if ex.topic != .levels { XCTAssertTrue(ex.choices.indices.contains(ex.correctChoice)) }
            switch ex.topic {
            case .candles,.structures,.volume,.limits,.trends: XCTAssertEqual(ex.correctChoice,ex.variant%2,"Exercise \(ex.id)")
            case .levels: break
            }
        }
    }
    func testAggregationPreservesOHLCAndPartialIntervals() {
        let raw=Exercise(id:0).candles
        let grouped=Candle.aggregate(raw,period:6)
        XCTAssertEqual(grouped.count,6)
        XCTAssertEqual(grouped[0].open,raw[0].open)
        XCTAssertEqual(grouped[0].close,raw[5].close)
        XCTAssertEqual(grouped[0].high,raw.prefix(6).map(\.high).max()!)
        XCTAssertEqual(grouped[0].low,raw.prefix(6).map(\.low).min()!)
        XCTAssertEqual(grouped[0].volume,raw.prefix(6).reduce(0.0){$0+$1.volume})
        let partial=Candle.aggregate(Array(raw.prefix(5)),period:3)
        XCTAssertEqual(partial.count,2)
        XCTAssertEqual(partial[1].id,3)
        XCTAssertEqual(partial[1].close,raw[4].close)
    }
    func testFlatAndShortSectionsAreNotTrends() {
        let flat=(0..<36).map{ Candle(id:$0,open:10,high:11,low:9,close:10,volume:1) }
        XCTAssertEqual(Exercise.trend(flat),2)
        XCTAssertEqual(Exercise.trend(Array(flat.prefix(5))),2)
    }
    func testDojiUsesBodyToRangeNotAbsoluteBody() {
        XCTAssertTrue(Candle(id:0,open:10,high:11,low:9,close:10.1,volume:1).isDoji)
        XCTAssertFalse(Candle(id:0,open:10,high:10.15,low:9.95,close:10.1,volume:1).isDoji)
    }
    func testLevelToleranceAndWrongTool() {
        let ex=Exercise(id:8)
        func mark(_ kind:MarkKind,_ y:Double)->Mark { Mark(kind:kind,x1:0,y1:y,x2:35,y2:y) }
        XCTAssertTrue(ex.accepts([mark(.level,ex.highest+ex.tolerance*0.99)]))
        XCTAssertFalse(ex.accepts([mark(.level,ex.highest+ex.tolerance*1.01)]))
        XCTAssertFalse(ex.accepts([mark(.trend,ex.highest)]))
        XCTAssertFalse(ex.accepts([]))
    }
    @MainActor func testPersistenceMasteryAndAccuracy() throws {
        let url=FileManager.default.temporaryDirectory.appending(path:UUID().uuidString+"/progress.json")
        defer { try? FileManager.default.removeItem(at:url.deletingLastPathComponent()) }
        let store=LabStore(url:url);store.load();store.select(8)
        store.marks=[Mark(kind:.level,x1:3,y1:store.exercise.highest,x2:35,y2:store.exercise.highest)]
        store.record(correct:false,answer:"Wrong level")
        store.record(correct:true,answer:"Correct level")
        store.record(correct:true,answer:"Repeat")
        store.state.readTopics.insert(Topic.levels.rawValue);store.revealed=19;store.save()
        let restored=LabStore(url:url);restored.load()
        XCTAssertNil(restored.error)
        XCTAssertEqual(restored.state.current,8)
        XCTAssertEqual(restored.marks,store.marks)
        XCTAssertEqual(restored.revealed,19)
        XCTAssertEqual(restored.state.mastered.count,1)
        XCTAssertEqual(restored.accuracy(),67)
        XCTAssertEqual(restored.weakest,.levels,"Repeat attempted weak topics before unattempted topics")
        XCTAssertEqual(restored.state.readTopics,[Topic.levels.rawValue])
    }
    @MainActor func testCorruptSaveIsPreservedUntilReset() throws {
        let url=FileManager.default.temporaryDirectory.appending(path:UUID().uuidString+".json")
        defer { try? FileManager.default.removeItem(at:url) }
        let bytes=Data("broken".utf8);try bytes.write(to:url)
        let store=LabStore(url:url);store.load()
        XCTAssertTrue(store.loadFailed);XCTAssertNotNil(store.error)
        store.record(correct:true,answer:"Attempt")
        XCTAssertEqual(try Data(contentsOf:url),bytes)
        store.reset();XCTAssertFalse(store.loadFailed)
        XCTAssertNoThrow(try JSONDecoder().decode(SavedState.self,from:Data(contentsOf:url)))
    }
    @MainActor func testReplayAndSelectionBounds() {
        let store=LabStore(url:FileManager.default.temporaryDirectory.appending(path:UUID().uuidString))
        defer { try? FileManager.default.removeItem(at:store.url) }
        store.select(-4);XCTAssertEqual(store.state.current,0)
        store.select(99);XCTAssertEqual(store.state.current,23)
        store.revealed=100;XCTAssertEqual(store.revealed,36)
        store.revealed=0;XCTAssertEqual(store.revealed,6)
    }
}
