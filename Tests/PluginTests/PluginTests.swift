import Foundation
import Plugin
import Testing

// MARK: - Helpers

/// Records the order in which plugins ran.
private actor Recorder<Value: Sendable> {
    private(set) var values: [Value] = []

    func append(_ value: Value) {
        values.append(value)
    }
}

/// Suspends each caller until `count` callers have arrived, then releases them all.
/// It only finishes if the callers run at the same time.
private actor Barrier {
    private let count: Int
    private var waiting: [CheckedContinuation<Void, Never>] = []

    init(count: Int) {
        self.count = count
    }

    func arrive() async {
        if waiting.count + 1 == count {
            waiting.forEach { $0.resume() }
            waiting.removeAll()
        } else {
            await withCheckedContinuation { waiting.append($0) }
        }
    }
}

private struct TestError: Error, Equatable {
    let id: Int
}

private struct RecordPlugin: ImmutablePlugin {
    let id: Int
    let recorder: Recorder<Int>

    func handle(value: String) async throws {
        await recorder.append(id)
    }
}

private struct ThrowingPlugin: ImmutablePlugin {
    let id: Int

    func handle(value: String) async throws {
        throw TestError(id: id)
    }
}

private struct LengthPlugin: Plugin {
    func handle(value: String) async throws -> Int {
        value.count
    }
}

private struct DoublePlugin: Plugin {
    func handle(value: String) async throws -> Int {
        value.count * 2
    }
}

// MARK: - REQ-Plugin-1

@Suite("REQ-Plugin-1 Swift 6 and Sendable")
struct SendableTests {
    @Test("REQ-Plugin-1 public types are Sendable and cross tasks")
    func publicTypesAreSendable() async throws {
        func requireSendable<T: Sendable>(_: T.Type) {}
        requireSendable(Plugins<String, Int>.self)
        requireSendable(PluginToken.self)
        requireSendable((any Plugin<String, Int>).self)
        requireSendable((any ImmutablePlugin<String>).self)

        let plugins = Plugins<String, Int>([LengthPlugin()])
        let outputs = try await Task.detached {
            try await plugins.handle(value: "four")
        }.value
        #expect(outputs == [4])
    }
}

// MARK: - REQ-Plugin-2

@Suite("REQ-Plugin-2 typed plugins and the plugin list")
struct PluginsTests {
    @Test("REQ-Plugin-2 a plugin takes its declared input type")
    func typedInput() async throws {
        // The container's methods are typed by `Input`: passing an `Int` to a
        // `Plugins<String, Int>` or registering an `Int` plugin does not compile.
        let plugins = Plugins<String, Int>()
        plugins.register(LengthPlugin())
        let outputs: [Int] = try await plugins.handle(value: "abc")
        #expect(outputs == [3])

        // An immutable plugin is a plugin whose output is `Void`.
        let immutable: any ImmutablePlugin<String> = ThrowingPlugin(id: 0)
        let immutables = ImmutablePlugins<String>()
        immutables.register(immutable)
        #expect(immutables.snapshot.first is ThrowingPlugin)
    }

    @Test("REQ-Plugin-2 a Plugin returns its output, in registration order")
    func pluginReturnsOutput() async throws {
        let plugins = Plugins<String, Int>([LengthPlugin(), DoublePlugin()])
        #expect(try await plugins.handle(value: "hello") == [5, 10])
        #expect(try await plugins.handleInOrder(value: "hello") == [5, 10])
    }

    @Test("REQ-Plugin-2 running all at once calls every plugin", .timeLimit(.minutes(1)))
    func allAtOnceCallsEveryPlugin() async throws {
        let count = 50
        let barrier = Barrier(count: count)
        let recorder = Recorder<Int>()

        struct BarrierPlugin: ImmutablePlugin {
            let id: Int
            let barrier: Barrier
            let recorder: Recorder<Int>

            func handle(value: String) async throws {
                // Finishes only when every plugin is running at once.
                await barrier.arrive()
                await recorder.append(id)
            }
        }

        let plugins = ImmutablePlugins<String>()
        plugins.register(contentsOf: (0 ..< count).map {
            BarrierPlugin(id: $0, barrier: barrier, recorder: recorder)
        })

        let outputs: [Void] = try await plugins.handle(value: "go")

        #expect(outputs.count == count)
        #expect(await recorder.values.sorted() == Array(0 ..< count))
    }

    @Test("REQ-Plugin-2 running one at a time follows registration order")
    func inOrderFollowsRegistrationOrder() async throws {
        let recorder = Recorder<Int>()

        struct SlowPlugin: ImmutablePlugin {
            let id: Int
            let recorder: Recorder<Int>

            func handle(value: String) async throws {
                // Earlier plugins wait longer, so a concurrent run would reorder them.
                try await Task.sleep(for: .milliseconds(10 - id))
                await recorder.append(id)
            }
        }

        let plugins = ImmutablePlugins<String>()
        for id in 0 ..< 10 {
            plugins.register(SlowPlugin(id: id, recorder: recorder))
        }

        try await plugins.handleInOrder(value: "go")

        #expect(await recorder.values == Array(0 ..< 10))
    }

    @Test("REQ-Plugin-2 registering and removing from many tasks loses no plugin")
    func concurrentRegisterAndRemove() async throws {
        let recorder = Recorder<Int>()
        let plugins = ImmutablePlugins<String>()

        // Half the plugins are registered up front and then removed concurrently,
        // while the other half are registered concurrently.
        let doomed = (0 ..< 500).map { plugins.register(RecordPlugin(id: -1 - $0, recorder: recorder)) }

        let kept = await withTaskGroup(of: PluginToken?.self) { group in
            for id in 0 ..< 500 {
                group.addTask { plugins.register(RecordPlugin(id: id, recorder: recorder)) }
            }
            for token in doomed {
                group.addTask {
                    #expect(plugins.remove(token) != nil)
                    return nil
                }
            }
            for _ in 0 ..< 100 {
                group.addTask {
                    _ = plugins.snapshot
                    return nil
                }
            }
            var kept: Set<PluginToken> = []
            for await token in group {
                if let token { kept.insert(token) }
            }
            return kept
        }

        #expect(kept.count == 500)
        #expect(plugins.count == 500)

        try await plugins.handle(value: "go")
        #expect(await recorder.values.sorted() == Array(0 ..< 500))

        #expect(plugins.remove(doomed[0]) == nil)
        plugins.removeAll()
        #expect(plugins.isEmpty)
    }

    @Test("REQ-Plugin-2 running in order stops at the first error")
    func inOrderStopsAtFirstError() async throws {
        let recorder = Recorder<Int>()
        let plugins = ImmutablePlugins<String>([
            RecordPlugin(id: 0, recorder: recorder),
            ThrowingPlugin(id: 1),
            RecordPlugin(id: 2, recorder: recorder),
        ])

        await #expect(throws: TestError(id: 1)) {
            try await plugins.handleInOrder(value: "go")
        }
        #expect(await recorder.values == [0])
    }

    @Test("REQ-Plugin-2 running all at once throws a plugin's error")
    func allAtOnceThrows() async throws {
        let recorder = Recorder<Int>()
        let plugins = ImmutablePlugins<String>([
            RecordPlugin(id: 0, recorder: recorder),
            ThrowingPlugin(id: 1),
        ])

        await #expect(throws: TestError(id: 1)) {
            try await plugins.handle(value: "go")
        }
    }

    @Test("REQ-Plugin-2 a Pluginable type forwards to its plugins")
    func pluginableForwards() async throws {
        final class Service: Pluginable {
            let plugins = Plugins<Void, Int>()
        }

        struct OnePlugin: Plugin {
            func handle(value: Void) async throws -> Int { 1 }
        }

        let service = Service()
        let token = service.register(OnePlugin())
        service.register(contentsOf: [OnePlugin(), OnePlugin()])

        #expect(try await service.handle(value: ()) == [1, 1, 1])
        #expect(try await service.plugins.handleInOrder() == [1, 1, 1])

        #expect(service.remove(token) != nil)
        #expect(try await service.handleInOrder(value: ()) == [1, 1])
    }
}

// MARK: - REQ-Plugin-3

/// Stands in for Scribe's namespace so the refinement reads as Scribe would write it.
enum Scribe {
    struct PluginPayload: Sendable {
        let message: String
    }
}

/// Scribe 3.0's `ScribePlugin` requirement, written as a refinement of `ImmutablePlugin`.
protocol ScribePlugin: ImmutablePlugin where Input == Scribe.PluginPayload {}

/// Written only against Scribe 3.0's requirement, as an existing Scribe plugin is.
actor CountPlugin: ScribePlugin {
    private(set) var count = 0

    func handle(value: Scribe.PluginPayload) async throws {
        count += 1
    }
}

/// A struct written only against Scribe 3.0's requirement.
struct MessagesPlugin: ScribePlugin {
    let recorder: MessageRecorder

    func handle(value: Scribe.PluginPayload) async throws {
        await recorder.append(value.message)
    }
}

actor MessageRecorder {
    private(set) var messages: [String] = []

    func append(_ message: String) {
        messages.append(message)
    }
}

@Suite("REQ-Plugin-3 Scribe 3.0 compatibility")
struct ScribeCompatibilityTests {
    @Test("REQ-Plugin-3 a ScribePlugin-shaped refinement compiles and runs")
    func scribePluginRefinement() async throws {
        let counter = CountPlugin()
        let recorder = MessageRecorder()
        let scribePlugins: [any ScribePlugin] = [counter, MessagesPlugin(recorder: recorder)]

        let plugins = ImmutablePlugins<Scribe.PluginPayload>()
        for plugin in scribePlugins {
            plugins.register(plugin)
        }

        try await plugins.handleInOrder(value: Scribe.PluginPayload(message: "one"))
        try await plugins.handle(value: Scribe.PluginPayload(message: "two"))

        #expect(await counter.count == 2)
        #expect(await recorder.messages == ["one", "two"])

        // A Scribe plugin is still called directly, exactly as in Scribe 3.0.
        try await counter.handle(value: Scribe.PluginPayload(message: "three"))
        #expect(await counter.count == 3)
    }
}

// MARK: - REQ-Plugin-4

@Suite("REQ-Plugin-4 documentation")
struct DocumentationTests {
    @Test("REQ-Plugin-4 the README documents 3.0 and moving from 2.x")
    func readmeDocumentsMigration() throws {
        let readme = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("README.md")
        let text = try String(contentsOf: readme, encoding: .utf8)

        #expect(text.contains("## Moving from 2.x"))
        #expect(text.contains("Plugins<"))
        #expect(text.contains("ImmutablePlugin"))
        #expect(text.contains("from: \"3.0.0\""))
    }
}
