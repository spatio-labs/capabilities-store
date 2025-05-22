#!/usr/bin/swift sh
import SpatioSDK // @spatio-labs == main
import Foundation

/// Capability to get details about an IP address using IPinfo.io API
class IPDetailsCapability: BaseRemoteCapability {
    override func configureRequest() -> APIRequest {
        return APIRequest(
            baseURL: "https://ipinfo.io",
            endpoint: "/{ip}",
            method: "GET",
            parameters: [
                APIParameter(
                    name: "ip",
                    type: "string",
                    required: true,
                    location: .path,
                    description: "IP address to lookup"
                ),
                APIParameter(
                    name: "token",
                    type: "string",
                    required: true,
                    location: .query,
                    description: "IPinfo API token"
                )
            ]
        )
    }
    
    /// Provide mock data for testing
    override func provideMockData(for params: [String: String]) -> String {
        let ip = params["ip"] ?? "8.8.8.8"
        return """
        {
            "ip": "\(ip)",
            "hostname": "dns.google",
            "city": "Mountain View",
            "region": "California",
            "country": "US",
            "loc": "37.4056,-122.0775",
            "org": "AS15169 Google LLC",
            "postal": "94043",
            "timezone": "America/Los_Angeles"
        }
        """
    }
}

// Create capability instance
let capability = IPDetailsCapability(
    organization: "ipinfo",
    capability: "ip-details"
)

// Manually parse command line arguments
var parsedParams: [String: String] = [:]
for arg in CommandLine.arguments.dropFirst() {
    if arg.hasPrefix("--") {
        let parts = arg.dropFirst(2).split(separator: "=", maxSplits: 1)
        if parts.count == 2 {
            let key = String(parts[0])
            let value = String(parts[1])
            parsedParams[key] = value
        }
    }
}

// Validate required parameters
if parsedParams["token"] == nil {
    print("Error: No API token provided. Use --token=YOUR_TOKEN")
    exit(1)
}

if parsedParams["ip"] == nil {
    print("Error: No IP address provided. Use --ip=IP_ADDRESS")
    exit(1)
}

// Execute the capability
do {
    let result = try await capability.execute(params: parsedParams)
    CommandLineUtils.printResult(result)
} catch {
    print("Error: \(error)")
    exit(1)
} 