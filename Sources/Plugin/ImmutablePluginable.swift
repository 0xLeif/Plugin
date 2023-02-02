public final class ImmutablePluginable: Pluginable {
    public var plugins: [any Plugin]

    public init(plugins: [any Plugin] = []) {
        self.plugins = plugins
    }
}
