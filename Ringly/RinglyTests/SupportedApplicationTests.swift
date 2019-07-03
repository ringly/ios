@testable import Ringly
import Nimble
import XCTest

class SupportedApplicationTests: XCTestCase
{
    func testUniqueness()
    {
        expect(SupportedApplication.all).to(containUniqueItems())
    }
}

func containUniqueItems<Value: Hashable>() -> NonNilMatcherFunc<[Value]>
{
    return NonNilMatcherFunc { expression, message in
        message.postfixMessage = "to not contain duplicates"
        
        if let actual = try expression.evaluate()
        {
            if Set(actual).count == actual.count
            {
                return true
            }
            else
            {
                var counts = [Value:Int]()
                actual.forEach({ value in counts[value] = (counts[value] ?? 0) + 1 })

                let duplicates = counts
                    .filter({ _, count in count > 1 })
                    .map({ value, count in "“\(value)” \(count) times" })
                    .joined(separator: ", ")

                message.actualValue = "had duplicates: \(duplicates)"

                return false
            }
        }
        else
        {
            return false
        }
    }
}
