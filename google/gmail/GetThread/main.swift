#!/usr/bin/swift sh
import SpatioSDK // @spatio-labs == main
import Foundation

/// Implementation of the Gmail Get Thread capability
class GmailGetThreadCapability: BaseRemoteCapability {
    override func configureRequest() -> APIRequest {
        return APIRequest(
            baseURL: "https://gmail.googleapis.com",
            endpoint: "/gmail/v1/users/me/threads/{threadId}",
            method: "GET",
            parameters: [
                APIParameter(
                    name: "threadId",
                    type: "string",
                    required: true,
                    location: .path,
                    description: "The ID of the thread to retrieve"
                ),
                APIParameter(
                    name: "format",
                    type: "string",
                    required: false,
                    location: .query,
                    defaultValue: "full",
                    description: "The format to return the messages in (full, minimal, metadata)"
                ),
                APIParameter(
                    name: "metadataHeaders",
                    type: "string",
                    required: false,
                    location: .query,
                    description: "When format=metadata, only include headers specified (comma-separated)"
                )
            ]
        )
    }
}

// Configure Google API authentication at the organization level
func configureGoogleAuth() {
    let googleOAuth = AuthConfig(
        type: .oauth2,
        parameterName: "Authorization",
        location: .header,
        valuePrefix: "Bearer ",
        envVariable: "GOOGLE_AUTH_TOKEN"
    )
    
    // Set at organization level (will apply to all Google services)
    AuthManager.shared.setAuthConfig(for: "google", config: googleOAuth)
}

// Configure authentication
configureGoogleAuth()

// Create capability with proper identifiers
let capability = GmailGetThreadCapability(
    organization: "google",
    group: "gmail",
    capability: "GetThread"
)

// Parse command line arguments
let params = CommandLineUtils.parseArguments(for: capability.request.parameters)

// Execute the capability
do {
    let result = try await capability.execute(params: params)
    
    // Print the result to stdout
    CommandLineUtils.printResult(result)
} catch {
    print("Error: \(error)")
    exit(1)
}
