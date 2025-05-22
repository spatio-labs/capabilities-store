#!/usr/bin/swift sh
import SpatioSDK // @spatio-labs == main
import Foundation

/// Implementation of the Google Calendar Delete Event capability
class GoogleCalendarDeleteEventCapability: BaseRemoteCapability {
    override func configureRequest() -> APIRequest {
        return APIRequest(
            baseURL: "https://www.googleapis.com",
            endpoint: "/calendar/v3/calendars/{calendarId}/events/{eventId}",
            method: "DELETE",
            parameters: [
                APIParameter(
                    name: "calendarId",
                    type: "string",
                    required: true,
                    location: .path,
                    defaultValue: "primary",
                    description: "Calendar identifier"
                ),
                APIParameter(
                    name: "eventId",
                    type: "string",
                    required: true,
                    location: .path,
                    description: "Event identifier"
                ),
                APIParameter(
                    name: "sendUpdates",
                    type: "string",
                    required: false,
                    location: .query,
                    defaultValue: "none",
                    description: "Whether to send notifications about the deletion"
                )
            ]
        )
    }
    
    override func handleEmptyResponse(statusCode: Int) -> String? {
        // For DELETE requests that return no content but are successful
        if (200...204).contains(statusCode) {
            return """
            {
                "success": true
            }
            """
        }
        return nil
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
let capability = GoogleCalendarDeleteEventCapability(
    organization: "google",
    group: "google_calendar",
    capability: "DeleteEvent"
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
