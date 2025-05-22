#!/usr/bin/swift sh
import SpatioSDK // @spatio-labs == main
import Foundation

/// Implementation of the Gmail List Threads capability
class GmailListThreadsCapability: BaseRemoteCapability {
    override func configureRequest() -> APIRequest {
        return APIRequest(
            baseURL: "https://gmail.googleapis.com",
            endpoint: "/gmail/v1/users/me/threads",
            method: "GET",
            parameters: [
                APIParameter(
                    name: "q",
                    type: "string",
                    required: false,
                    location: .query,
                    description: "Search query for filtering threads"
                ),
                APIParameter(
                    name: "maxResults",
                    type: "integer",
                    required: false,
                    location: .query,
                    defaultValue: "20",
                    description: "The maximum number of threads to return"
                ),
                APIParameter(
                    name: "pageToken",
                    type: "string",
                    required: false,
                    location: .query,
                    description: "Token for continuing a previous list request"
                ),
                APIParameter(
                    name: "labelIds",
                    type: "string",
                    required: false,
                    location: .query,
                    description: "Only return threads with matching label IDs"
                ),
                APIParameter(
                    name: "includeSpamTrash",
                    type: "boolean",
                    required: false,
                    location: .query,
                    defaultValue: "false",
                    description: "Include threads from SPAM and TRASH"
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
let capability = GmailListThreadsCapability(
    organization: "google",
    group: "gmail",
    capability: "ListThreads"
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
