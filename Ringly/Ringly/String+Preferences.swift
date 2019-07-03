
extension String
{
    /// An attributed string representation of the receiver, for use as body text in the preferences views.
    var preferencesBodyAttributedString: NSAttributedString
    {
        return UIFont.gothamBook(12).track(150, self)
            .attributes(paragraphStyle: .with(alignment: .center, lineSpacing: 3))
    }

    /// An attributed string representation of the receiver, for use as the title of a preferences activity control.
    var preferencesActivityControlTitleString: NSAttributedString
    {
        return UIFont.gothamBook(12).track(250, self).attributedString
    }
    
    /// An attributed string representation of the receiver, for use as the title of a preferences activity control.
    var settingsActivityControlTitleString: NSAttributedString
    {
        return UIFont.gothamBook(18).track(250, self).attributedString
    }
}
