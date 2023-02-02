import XCTest
@testable import Plugin

final class PluginTests: XCTestCase {
    func testExample() async throws {
        class MockService: Pluginable {
            var plugins: [any Plugin] = []
            
            var count: Int = 0
        }
        
        struct ExamplePlugin: Plugin {
            var keyPath: WritableKeyPath<MockService, Int>
            
            func handle(value: Void, output: inout Int) async throws {
                output += 1
            }
        }
        
        let service = MockService()
        
        XCTAssertEqual(service.pluginTypes, [])
        
        service.register(
            plugin: ExamplePlugin(
                keyPath: \.count
            )
        )
        
        XCTAssertEqual(service.pluginTypes, ["(input: (), output: Int)"])
        
        try await service.handle(value: "Woot")
        
        XCTAssertEqual(service.count, 0)
        
        try await service.handle()
        
        XCTAssertEqual(service.count, 1)
        
        service.register(
            plugin: ExamplePlugin(
                keyPath: \.count
            )
        )
        
        XCTAssertEqual(service.pluginTypes.count, 2)
        
        try await service.handle()
        
        XCTAssertEqual(service.count, 3)
    }
    
    func testURLRequestExample() async throws {
        class PluginURLRequest: Pluginable {
            var plugins: [any Plugin] = []
            
            var request: URLRequest
            
            init(url: URL) {
                self.request = URLRequest(url: url)
            }
        }
        
        struct AuthPlugin: Plugin {
            var keyPath: WritableKeyPath<PluginURLRequest, URLRequest>
            
            func handle(value: Void, output: inout URLRequest) async throws {
                output.allHTTPHeaderFields = ["auth": "token"]
            }
        }
        
        let urlRequest = PluginURLRequest(
            url: try XCTUnwrap(URL(string: "localhost"))
        )
        
        XCTAssertEqual(urlRequest.pluginTypes, [])
        
        XCTAssertNil(urlRequest.request.allHTTPHeaderFields)
        
        urlRequest.register(plugin: AuthPlugin(keyPath: \.request))
        
        XCTAssertEqual(urlRequest.pluginTypes, ["(input: (), output: URLRequest)"])
        
        try await urlRequest.handle()
        
        let token = try XCTUnwrap(urlRequest.request.allHTTPHeaderFields)["auth"]
        XCTAssertEqual(token, "token")
    }

    func testImmutablePlugin() async throws {
        class MockService: Pluginable {
            var plugins: [any Plugin] = []
        }

        class CountPlugin: ImmutablePlugin {
            static let shared = CountPlugin()
            
            var count: Int = 0
            
            private init() {}

            func handle(value: Void) async throws {
                count += 1
            }
        }

        let service = MockService()

        XCTAssertEqual(service.pluginTypes, [])

        service.register(
            plugin: CountPlugin.shared
        )

        XCTAssertEqual(service.pluginTypes, ["(input: (), output: ())"])

        try await service.handle(value: "Woot")

        XCTAssertEqual(CountPlugin.shared.count, 0)

        try await service.handle()

        XCTAssertEqual(CountPlugin.shared.count, 1)
    }
}
