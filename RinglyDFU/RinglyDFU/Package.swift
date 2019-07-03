public struct Package
{
    // MARK: - Components

    /// The application component, which is required for all updates.
    public let application: PackageComponent

    /// The bootloader component, which is optional.
    public let bootloader: PackageComponent?
}
