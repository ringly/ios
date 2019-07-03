/// Equivalent to `tr(...).uppercased()`.
///
/// - Parameter string: The localized string key.
/// - Returns: An uppercased version of the localized string.
func trUpper(_ string: L10n) -> String
{
    return tr(string).uppercased()
}

