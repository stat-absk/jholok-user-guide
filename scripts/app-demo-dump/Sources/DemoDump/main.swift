// Writes the app's demo shop (JholokDemo) to CSV, so the guide's tests can check
// that the R simulation matches it sale for sale. Run it whenever the app's demo
// changes, then run the guide's tests:
//
//   cd user-guide/scripts/app-demo-dump
//   swift run DemoDump ../../tests/testthat/fixtures
//
// A development tool only; the guide itself is R and Quarto.
import Foundation
import JholokDemo

var calendar = Calendar(identifier: .gregorian)
calendar.timeZone = TimeZone(identifier: "Asia/Kolkata")!
let end = calendar.date(from: DateComponents(year: 2026, month: 9, day: 24, hour: 18))!
let scenario = DemoScenario.make(endingOn: end, calendar: calendar, counting: true)

let format = DateFormatter()
format.calendar = calendar
format.timeZone = calendar.timeZone
format.dateFormat = "yyyy-MM-dd HH:mm"

func quote(_ text: String) -> String { "\"" + text.replacingOccurrences(of: "\"", with: "\"\"") + "\"" }

var events = ["event,sku,date,kind,quantity,note"]
var counts = ["location,started_at,completed_at,scope,sku,counted,counted_at,unticked"]
for event in scenario.events {
    switch event {
    case .createProduct(let sku, let date):
        events.append("create,\(sku),\(format.string(from: date)),,,")
    case .movement(let sku, let date, let kind, let quantity, let note):
        events.append("movement,\(sku),\(format.string(from: date)),\(kind.rawValue),\(quantity),\(quote(note))")
    case .archive(let sku, let date):
        events.append("archive,\(sku),\(format.string(from: date)),,,")
    case .count(let count):
        for line in count.lines {
            counts.append([
                quote(count.location), format.string(from: count.startedAt),
                count.completedAt.map(format.string(from:)) ?? "",
                quote(count.scopeTypes.joined(separator: ";")), line.sku, String(line.counted),
                format.string(from: line.countedAt), count.unticked.contains(line.sku) ? "TRUE" : "FALSE",
            ].joined(separator: ","))
        }
    }
}
let out = CommandLine.arguments[1]
try events.joined(separator: "\n").appending("\n").write(toFile: out + "/app_events.csv", atomically: true, encoding: .utf8)
try counts.joined(separator: "\n").appending("\n").write(toFile: out + "/app_counts.csv", atomically: true, encoding: .utf8)
print(events.count - 1, "events,", counts.count - 1, "count lines")
