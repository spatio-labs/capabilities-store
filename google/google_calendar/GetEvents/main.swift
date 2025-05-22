#!/usr/bin/swift sh
import SpatioSDK // @spatio-labs == main
import Foundation

/// Implementation of the Google Calendar Get Events capability
class GoogleCalendarGetEventsCapability: BaseRemoteCapability {
    override func configureRequest() -> APIRequest {
        return APIRequest(
            baseURL: "https://www.googleapis.com",
            endpoint: "/calendar/v3/calendars/{calendarId}/events",
            method: "GET",
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
                    name: "timeMin",
                    type: "string",
                    required: false,
                    location: .query,
                    description: "Lower bound for event's end time (RFC3339 timestamp)"
                ),
                APIParameter(
                    name: "timeMax",
                    type: "string",
                    required: false,
                    location: .query,
                    description: "Upper bound for event's start time (RFC3339 timestamp)"
                ),
                APIParameter(
                    name: "maxResults",
                    type: "integer",
                    required: false,
                    location: .query,
                    defaultValue: "250",
                    description: "Maximum number of events to return"
                ),
                APIParameter(
                    name: "orderBy",
                    type: "string",
                    required: false,
                    location: .query,
                    defaultValue: "startTime",
                    description: "Order of the events returned (startTime, updated)"
                ),
                APIParameter(
                    name: "q",
                    type: "string",
                    required: false,
                    location: .query,
                    description: "Free text search terms to find events that match"
                ),
                APIParameter(
                    name: "singleEvents",
                    type: "boolean",
                    required: false,
                    location: .query,
                    defaultValue: "true",
                    description: "Whether to expand recurring events into instances"
                ),
                APIParameter(
                    name: "showDeleted",
                    type: "boolean",
                    required: false,
                    location: .query,
                    defaultValue: "false",
                    description: "Whether to include deleted events"
                ),
                APIParameter(
                    name: "pageToken",
                    type: "string",
                    required: false,
                    location: .query,
                    description: "Token for pagination"
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
let capability = GoogleCalendarGetEventsCapability(
    organization: "google",
    group: "google_calendar",
    capability: "GetEvents"
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
