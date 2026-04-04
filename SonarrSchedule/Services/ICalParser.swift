import Foundation

struct ICalParser {
    static func parse(_ icalString: String) -> [CalendarEvent] {
        var events: [CalendarEvent] = []
        let unfoldedString = unfoldLines(icalString)
        let lines = unfoldedString.components(separatedBy: "\n")

        var inEvent = false
        var uid = ""
        var summary = ""
        var description = ""
        var dtStart: Date?
        var dtEnd: Date?
        var categories = ""
        var status = ""

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)

            if trimmed == "BEGIN:VEVENT" {
                inEvent = true
                uid = ""
                summary = ""
                description = ""
                dtStart = nil
                dtEnd = nil
                categories = ""
                status = ""
                continue
            }

            if trimmed == "END:VEVENT" {
                if inEvent, let start = dtStart, let end = dtEnd {
                    let event = CalendarEvent(
                        id: uid.isEmpty ? UUID().uuidString : uid,
                        summary: unescapeICalText(summary),
                        description: unescapeICalText(description),
                        startDate: start,
                        endDate: end,
                        categories: unescapeICalText(categories),
                        status: status
                    )
                    events.append(event)
                }
                inEvent = false
                continue
            }

            guard inEvent else { continue }

            if let value = extractValue(from: trimmed, key: "UID") {
                uid = value
            } else if let value = extractValue(from: trimmed, key: "SUMMARY") {
                summary = value
            } else if let value = extractValue(from: trimmed, key: "DESCRIPTION") {
                description = value
            } else if let value = extractValue(from: trimmed, key: "DTSTART") {
                dtStart = parseDate(value)
            } else if let value = extractValue(from: trimmed, key: "DTEND") {
                dtEnd = parseDate(value)
            } else if let value = extractValue(from: trimmed, key: "CATEGORIES") {
                categories = value
            } else if let value = extractValue(from: trimmed, key: "STATUS") {
                status = value
            }
        }

        return events
    }

    // iCal spec: long lines are folded by inserting CRLF followed by a space/tab
    private static func unfoldLines(_ text: String) -> String {
        text.replacingOccurrences(of: "\r\n ", with: "")
            .replacingOccurrences(of: "\r\n\t", with: "")
            .replacingOccurrences(of: "\n ", with: "")
            .replacingOccurrences(of: "\n\t", with: "")
    }

    private static func extractValue(from line: String, key: String) -> String? {
        // Handle both "KEY:value" and "KEY;params:value"
        if line.hasPrefix("\(key):") {
            return String(line.dropFirst(key.count + 1))
        }
        if line.hasPrefix("\(key);") {
            if let colonIndex = line.firstIndex(of: ":") {
                return String(line[line.index(after: colonIndex)...])
            }
        }
        return nil
    }

    private static func parseDate(_ string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")

        // Try UTC format first: 20260331T024400Z
        if string.hasSuffix("Z") {
            formatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
            formatter.timeZone = TimeZone(identifier: "UTC")
            if let date = formatter.date(from: string) {
                return date
            }
        }

        // Try local format: 20260331T024400
        formatter.dateFormat = "yyyyMMdd'T'HHmmss"
        formatter.timeZone = TimeZone.current
        if let date = formatter.date(from: string) {
            return date
        }

        // Try date-only: 20260331
        formatter.dateFormat = "yyyyMMdd"
        return formatter.date(from: string)
    }

    private static func unescapeICalText(_ text: String) -> String {
        text.replacingOccurrences(of: "\\,", with: ",")
            .replacingOccurrences(of: "\\;", with: ";")
            .replacingOccurrences(of: "\\n", with: "\n")
            .replacingOccurrences(of: "\\N", with: "\n")
            .replacingOccurrences(of: "\\\\", with: "\\")
    }
}
