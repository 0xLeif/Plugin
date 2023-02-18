import Fork

/// The `Pluginable` protocol defines the structure for an object that can have plugins registered to it.
public protocol Pluginable: AnyObject {
    /// An array that contains the plugins that have been registered to the object.
    /// The order of the plugins only matters if you are using the `syncHandle` function.
    var plugins: [any Plugin] { get set }

    /// This method is used to register a plugin to the object.
    ///
    /// - Parameter plugin: The plugin to be registered.
    func register(plugin: any Plugin)

    /// This method is used to register an array of plugins to the object.
    ///
    /// - Parameter plugin: The array of plugins to be registered.
    func register(plugins: [any Plugin])

    /// This method is used to handle a value, and applies any registered plugins to the value.
    /// This functions runs **all** plugins at the same time.
    ///
    /// - Parameter value: The value to be handled.
    /// - Throws: An error if any of the registered plugins throws an error.
    func handle(value: Any) async throws

    /// This method is used to handle a value, and applies any registered plugins to the value.
    /// This functions runs the plugins **one** at a time
    ///
    /// - Parameter value: The value to be handled.
    /// - Throws: An error if any of the registered plugins throws an error.
    func syncHandle(value: Any) async throws
}

// MARK: Public Implementation

public extension Pluginable {
    /// An array of strings representing the input types of the registered plugins.
    var pluginInputTypes: [String] { plugins.map(\.inputType) }
    /// An array of strings representing the output types of the registered plugins.
    var pluginOutputTypes: [String] { plugins.map(\.outputType) }
    /// An array of strings representing the input and output types of the registered plugins in the format "(input: [input type], output: [output type])".
    var pluginTypes: [String] {
        zip(pluginInputTypes, pluginOutputTypes)
            .map { inputType, outputType in
                "(input: \(inputType), output: \(outputType))"
            }
    }

    /// A key path property to represent immutability.
    var immutable: Void {
        get { () }
        set { }
    }

    /// This method is used to register a plugin to the object.
    ///
    /// - Parameter plugin: The plugin to be registered.
    func register(plugin: any Plugin) {
        plugins.append(plugin)
    }

    /// This method is used to register an array of plugins to the object.
    ///
    /// - Parameter plugin: The array of plugins to be registered.
    func register(plugins: [any Plugin]) {
        self.plugins.append(contentsOf: plugins)
    }

    /// This method is used to handle a value, and applies any registered plugins to the value.
    /// This functions runs **all** plugins at the same time.
    ///
    /// - Parameter value: The value to be handled.
    /// - Throws: An error if any of the registered plugins throws an error.
    func handle(value: Any) async throws {
        let validPlugins: [any Plugin] = plugins
            .filter { plugin in
                plugin.isValid(value: value)
            }

        try await validPlugins.asyncForEach { plugin in
            var source = self as Any
            try await plugin.handle(value, source: &source)
        }
    }

    /// This method is used to handle a value, and applies any registered plugins to the value.
    /// This functions runs the plugins **one** at a time in order.
    ///
    /// - Parameter value: The value to be handled.
    /// - Throws: An error if any of the registered plugins throws an error.
    func syncHandle(value: Any) async throws {
        let validPlugins: [any Plugin] = plugins
            .filter { plugin in
                plugin.isValid(value: value)
            }

        for plugin in validPlugins {
            var source = self as Any
            try await plugin.handle(value, source: &source)
        }
    }

    /// Handle the value of `Void`, passing it through all the registered plugins. This functions runs all plugins at the same time.
    func handle() async throws {
        try await handle(value: ())
    }

    /// Handle the value of `Void`, passing it through all the registered plugins. This functions runs the plugins one at a time in order.
    func syncHandle() async throws {
        try await syncHandle(value: ())
    }
}
