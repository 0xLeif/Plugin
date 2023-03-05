open class ImmutablePluginable: Pluginable {
    /// An array that contains the plugins that have been registered to the object.
    open var plugins: [any Plugin]

    public init(plugins: [any Plugin] = []) {
        self.plugins = plugins
    }
}
