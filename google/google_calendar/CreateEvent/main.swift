#!/usr/bin/swift sh
import SpatioSDK // @spatio-labs == main
import Foundation

/// Implementation of the Google Calendar Create Event capability
class GoogleCalendarCreateEventCapability: BaseRemoteCapability {
    override func configureRequest() -> APIRequest {
        return APIRequest(
            baseURL: "https://www.googleapis.com",
            endpoint: "/calendar/v3/calendars/{calendarId}/events",
            method: "POST",
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
                    name: "summary",
                    type: "string",
                    required: true,
                    location: .body,
                    description: "Title of the event"
                ),
                APIParameter(
                    name: "startDateTime",
                    type: "string",
                    required: true,
                    location: .body,
                    description: "Start time of the event (RFC3339 timestamp)"
                ),
                APIParameter(
                    name: "endDateTime",
                    type: "string",
                    required: true,
                    location: .body,
                    description: "End time of the event (RFC3339 timestamp)"
                ),
                APIParameter(
                    name: "description",
                    type: "string",
                    required: false,
                    location: .body,
                    description: "Description of the event"
                ),
                APIParameter(
                    name: "location",
                    type: "string",
                    required: false,
                    location: .body,
                    description: "Geographic location of the event"
                ),
                APIParameter(
                    name: "attendees",
                    type: "string",
                    required: false,
                    location: .body,
                    description: "Comma-separated list of attendee email addresses"
                ),
                APIParameter(
                    name: "colorId",
                    type: "string",
                    required: false,
                    location: .body,
                    description: "The color of the event"
                ),
                APIParameter(
                    name: "sendUpdates",
                    type: "string",
                    required: false,
                    location: .query,
                    defaultValue: "none",
                    description: "Whether to send notifications (none, all, externalOnly)"
                ),
                APIParameter(
                    name: "transparency",
                    type: "string",
                    required: false,
                    location: .body,
                    defaultValue: "opaque",
                    description: "Whether the event blocks time on the calendar"
                ),
                APIParameter(
                    name: "visibility",
                    type: "string",
                    required: false,
                    location: .body,
                    defaultValue: "default",
                    description: "Visibility of the event"
                ),
                APIParameter(
                    name: "reminders",
                    type: "string",
                    required: false,
                    location: .body,
                    description: "Comma-separated list of reminders in minutes"
                )
            ]
        )
    }
    
    override func prepareRequestBody(from parameters: [String: String]) -> Data? {
        // Create the event structure
        var eventData: [String: Any] = [:]
        
        // Required fields
        if let summary = parameters["summary"] {
            eventData["summary"] = summary
        } else {
            return nil
        }
        
        // Handle start and end times
        if let startDateTime = parameters["startDateTime"],
           let endDateTime = parameters["endDateTime"] {
            eventData["start"] = ["dateTime": startDateTime]
            eventData["end"] = ["dateTime": endDateTime]
        } else {
            return nil
        }
        
        // Optional fields
        if let description = parameters["description"] {
            eventData["description"] = description
        }
        
        if let location = parameters["location"] {
            eventData["location"] = location
        }
        
        // Handle attendees
        if let attendeesString = parameters["attendees"], !attendeesString.isEmpty {
            let emails = attendeesString.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) }
            let attendees = emails.map { ["email": $0] }
            eventData["attendees"] = attendees
        }
        
        if let colorId = parameters["colorId"] {
            eventData["colorId"] = colorId
        }
        
        if let transparency = parameters["transparency"] {
            eventData["transparency"] = transparency
        }
        
        if let visibility = parameters["visibility"] {
            eventData["visibility"] = visibility
        }
        
        // Handle reminders
        if let remindersString = parameters["reminders"], !remindersString.isEmpty {
            let minutes = remindersString.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) }
            var overrides: [[String: Any]] = []
            
            for minute in minutes {
                if let minutesInt = Int(minute) {
                    overrides.append(["method": "popup", "minutes": minutesInt])
                }
            }
            
            eventData["reminders"] = ["useDefault": false, "overrides": overrides]
        }
        
        // Convert to JSON data
        return try? JSONSerialization.data(withJSONObject: eventData)
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
let capability = GoogleCalendarCreateEventCapability(
    organization: "google",
    group: "google_calendar",
    capability: "CreateEvent"
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
