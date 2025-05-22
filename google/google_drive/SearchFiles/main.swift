#!/usr/bin/swift sh
import SpatioSDK // @spatio-labs == main
import Foundation

/// Implementation of the Google Drive Search Files capability
class GoogleDriveSearchFilesCapability: BaseRemoteCapability {
    override func configureRequest() -> APIRequest {
        return APIRequest(
            baseURL: "https://www.googleapis.com",
            endpoint: "/drive/v3/files",
            method: "GET",
            parameters: [
                APIParameter(
                    name: "q",
                    type: "string",
                    required: true,
                    location: .query,
                    description: "Search query (e.g., 'name contains \"report\"')"
                ),
                APIParameter(
                    name: "fields",
                    type: "string",
                    required: false,
                    location: .query,
                    defaultValue: "files(id,name,mimeType,webViewLink)",
                    description: "Fields to include in the response"
                ),
                APIParameter(
                    name: "pageSize",
                    type: "integer",
                    required: false,
                    location: .query,
                    defaultValue: "100",
                    description: "Maximum number of files to return"
                ),
                APIParameter(
                    name: "pageToken",
                    type: "string",
                    required: false,
                    location: .query,
                    description: "Token for continuing a previous list request"
                ),
                APIParameter(
                    name: "includeTrash",
                    type: "boolean",
                    required: false,
                    location: .query,
                    defaultValue: "false",
                    description: "Whether to include files in the trash"
                )
            ]
        )
    }
}

// Configure Google API authentication at the organization level
// This would typically be done in a shared initialization script
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
    
    // You could override for specific groups/capabilities if needed:
    // AuthManager.shared.setAuthConfig(for: "google", group: "google_drive", config: customConfig)
}

// Configure authentication
configureGoogleAuth()

// Create capability with proper identifiers
let capability = GoogleDriveSearchFilesCapability(
    organization: "google",
    group: "google_drive",
    capability: "SearchFiles"
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
