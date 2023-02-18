public final class ImmutablePluginable: Pluginable {
    /// An array that contains the plugins that have been registered to the object.
    public var plugins: [any Plugin]

    public init(plugins: [any Plugin] = []) {
        self.plugins = plugins
    }
}
