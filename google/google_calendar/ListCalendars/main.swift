#!/usr/bin/swift sh
import SpatioSDK // @spatio-labs == main
import Foundation

/// Implementation of the Google Calendar List Calendars capability
class GoogleCalendarListCalendarsCapability: BaseRemoteCapability {
    override func configureRequest() -> APIRequest {
        return APIRequest(
            baseURL: "https://www.googleapis.com",
            endpoint: "/calendar/v3/users/me/calendarList",
            method: "GET",
            parameters: [
                APIParameter(
                    name: "maxResults",
                    type: "integer",
                    required: false,
                    location: .query,
                    defaultValue: "100",
                    description: "Maximum number of calendars to return"
                ),
                APIParameter(
                    name: "pageToken",
                    type: "string",
                    required: false,
                    location: .query,
                    description: "Token for pagination"
                ),
                APIParameter(
                    name: "showDeleted",
                    type: "boolean",
                    required: false,
                    location: .query,
                    defaultValue: "false",
                    description: "Whether to include deleted calendar list entries"
                ),
                APIParameter(
                    name: "showHidden",
                    type: "boolean",
                    required: false,
                    location: .query,
                    defaultValue: "false",
                    description: "Whether to show hidden calendars"
                )
            ]
        )
    }
    
    override func transformResponse(_ data: Data) -> Data? {
        // Transform response to match the expected output format
        guard let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            return data
        }
        
        // Rename "items" to "calendars" to match the expected output
        var modifiedJson = json
        if let items = json["items"] {
            modifiedJson["calendars"] = items
            modifiedJson.removeValue(forKey: "items")
        }
        
        return try? JSONSerialization.data(withJSONObject: modifiedJson)
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
let capability = GoogleCalendarListCalendarsCapability(
    organization: "google",
    group: "google_calendar",
    capability: "ListCalendars"
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
