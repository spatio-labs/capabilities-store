#!/usr/bin/swift sh
import SpatioSDK // @spatio-labs == main
import Foundation

/// Implementation of the Gmail List Messages capability
class GmailListMessagesCapability: BaseRemoteCapability {
    override func configureRequest() -> APIRequest {
        return APIRequest(
            baseURL: "https://gmail.googleapis.com",
            endpoint: "/gmail/v1/users/me/messages",
            method: "GET",
            parameters: [
                APIParameter(
                    name: "q",
                    type: "string",
                    required: false,
                    location: .query,
                    description: "Search query for filtering messages"
                ),
                APIParameter(
                    name: "maxResults",
                    type: "integer",
                    required: false,
                    location: .query,
                    defaultValue: "20",
                    description: "The maximum number of messages to return"
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
                    description: "Only return messages with matching label IDs"
                ),
                APIParameter(
                    name: "includeSpamTrash",
                    type: "boolean",
                    required: false,
                    location: .query,
                    defaultValue: "false",
                    description: "Include messages from SPAM and TRASH"
                )
            ]
        )
    }
}

// Configure Google API authentication at the organization level
func configureGoogleAuth() {
    // Top-level Google organization auth config
    let googleOAuth = AuthConfig(
        type: .oauth2,
        parameterName: "Authorization",
        location: .header,
        valuePrefix: "Bearer ",
        envVariable: "GOOGLE_AUTH_TOKEN"
    )
    
    // Set at organization level
    AuthManager.shared.setAuthConfig(for: "google", config: googleOAuth)
    
    // Gmail child organization with specific scopes
    let gmailOAuth = AuthConfig(
        type: .oauth2,
        parameterName: "Authorization",
        location: .header,
        valuePrefix: "Bearer ",
        envVariable: "GOOGLE_AUTH_TOKEN",
        scopes: ["https://www.googleapis.com/auth/gmail.readonly"]
    )
    
    // Set Gmail as a child of Google organization
    AuthManager.shared.setAuthConfig(for: "gmail", parentOrganization: "google", config: gmailOAuth)
}

// Configure authentication
configureGoogleAuth()

// Create capability with proper identifiers
let capability = GmailListMessagesCapability(
    organization: "gmail",
    capability: "ListMessages"
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
