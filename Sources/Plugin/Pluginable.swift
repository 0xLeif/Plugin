public protocol Pluginable: AnyObject {
    var plugins: [any Plugin] { get set }
    
    func register(plugin: any Plugin)
    func handle(value: Any) async throws
}

// MARK: Public Implementation

public extension Pluginable {
    var pluginInputTypes: [String] { plugins.map(\.inputType) }
    var pluginOutputTypes: [String] { plugins.map(\.outputType) }
    var pluginTypes: [String] {
        zip(pluginInputTypes, pluginOutputTypes)
            .map { inputType, outputType in
                "(input: \(inputType), output: \(outputType))"
            }
    }

    func register(plugin: any Plugin) {
        plugins.append(plugin)
    }
    
    func handle(value: Any) async throws {
        let validPlugins: [any Plugin] = plugins
            .filter { plugin in
                plugin.isValid(value: value)
            }
        
        for plugin in validPlugins {
            var source = self as Any
            try await plugin.handle(value, source: &source)
        }
    }
    
    func handle() async throws {
        try await handle(value: ())
    }
}

