#!/usr/bin/swift sh
import SpatioSDK // @spatio-labs == main
import Foundation

/// Implementation of the Gmail Modify Message Labels capability
class GmailModifyMessageLabelsCapability: BaseRemoteCapability {
    override func configureRequest() -> APIRequest {
        return APIRequest(
            baseURL: "https://gmail.googleapis.com",
            endpoint: "/gmail/v1/users/me/messages/{messageId}/modify",
            method: "POST",
            parameters: [
                APIParameter(
                    name: "messageId",
                    type: "string",
                    required: true,
                    location: .path,
                    description: "The ID of the message to modify"
                ),
                APIParameter(
                    name: "addLabelIds",
                    type: "string",
                    required: false,
                    location: .body,
                    description: "Labels to add to the message (comma-separated IDs)"
                ),
                APIParameter(
                    name: "removeLabelIds",
                    type: "string",
                    required: false,
                    location: .body,
                    description: "Labels to remove from the message (comma-separated IDs)"
                )
            ]
        )
    }
    
    override func prepareRequestBody(from parameters: [String: String]) -> Data? {
        var requestData: [String: Any] = [:]
        
        // Process addLabelIds
        if let addLabelsString = parameters["addLabelIds"], !addLabelsString.isEmpty {
            let labelIds = addLabelsString.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) }
            requestData["addLabelIds"] = labelIds
        }
        
        // Process removeLabelIds
        if let removeLabelsString = parameters["removeLabelIds"], !removeLabelsString.isEmpty {
            let labelIds = removeLabelsString.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) }
            requestData["removeLabelIds"] = labelIds
        }
        
        // If both parameters are missing, nothing to modify
        if requestData.isEmpty {
            return nil
        }
        
        // Convert to JSON data
        return try? JSONSerialization.data(withJSONObject: requestData)
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
let capability = GmailModifyMessageLabelsCapability(
    organization: "google",
    group: "gmail",
    capability: "ModifyMessageLabels"
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
