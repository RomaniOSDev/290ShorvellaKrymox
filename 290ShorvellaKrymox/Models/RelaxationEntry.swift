import Foundation

struct RelaxationEntry: Identifiable, Codable, Equatable {
    var id: UUID
    var date: Date
    var duration: Int
    var note: String

    init(id: UUID = UUID(), date: Date = Date(), duration: Int, note: String = "") {
        self.id = id
        self.date = date
        self.duration = duration
        self.note = note
    }
}
