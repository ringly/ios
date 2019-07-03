import CoreGraphics

/// The data model for `GraphViewController`.
struct GraphData
{
    /// The columns of data.
    let columns: [CGFloat?]

    /// The maximum value to render.
    let maximumValue: CGFloat
    
    /// The goal to display on the graph.
    let goal: Int

    /// A function to determine the label for a given column.
    let labelForColumn: ((Int) -> String?)?
}

extension GraphData
{
    static func empty(goal: Int) -> GraphData {
        let formatter = DateFormatter(localizedFormatTemplate: "Md")
        
        return GraphData(columns: [0], maximumValue: CGFloat(goal) * 1.5, goal: goal, labelForColumn: { column in column == 0 ? formatter.string(from: Date()) : "" })
    }
}
