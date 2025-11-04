import Foundation

func percentComplete(for goal: Goal) -> Int {
    let total = max(1, goal.milestones.count)
    let done = goal.milestones.filter { $0.status == .done }.count
    return Int(round(Double(done) / Double(total) * 100.0))
}

let dateFormatterShort: DateFormatter = {
    let df = DateFormatter()
    df.dateStyle = .short
    return df
}()
