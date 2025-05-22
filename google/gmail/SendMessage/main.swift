#!/usr/bin/swift sh
import SpatioSDK // @spatio-labs == main
import Foundation

/// Implementation of the Gmail Send Message capability
class GmailSendMessageCapability: BaseRemoteCapability {
    override func configureRequest() -> APIRequest {
        return APIRequest(
            baseURL: "https://gmail.googleapis.com",
            endpoint: "/gmail/v1/users/me/messages/send",
            method: "POST",
            parameters: [
                APIParameter(
                    name: "to",
                    type: "string",
                    required: true,
                    location: .body,
                    description: "Recipient email address(es), comma-separated for multiple recipients"
                ),
                APIParameter(
                    name: "subject",
                    type: "string",
                    required: true,
                    location: .body,
                    description: "Email subject line"
                ),
                APIParameter(
                    name: "body",
                    type: "string",
                    required: true,
                    location: .body,
                    description: "Email body content"
                ),
                APIParameter(
                    name: "cc",
                    type: "string",
                    required: false,
                    location: .body,
                    description: "CC recipient email address(es), comma-separated for multiple recipients"
                ),
                APIParameter(
                    name: "bcc",
                    type: "string",
                    required: false,
                    location: .body,
                    description: "BCC recipient email address(es), comma-separated for multiple recipients"
                ),
                APIParameter(
                    name: "contentType",
                    type: "string",
                    required: false,
                    location: .body,
                    defaultValue: "text/plain",
                    description: "Content type of the email body (text/plain or text/html)"
                ),
                APIParameter(
                    name: "attachments",
                    type: "string",
                    required: false,
                    location: .body,
                    description: "File paths of attachments, comma-separated for multiple files"
                )
            ]
        )
    }
    
    override func prepareRequestBody(from parameters: [String: String]) -> Data? {
        // Create a proper MIME email message format
        // This is a simplified example - actual implementation would need to:
        // 1. Create proper MIME headers
        // 2. Handle attachments
        // 3. Encode the message in base64 format as required by Gmail API
        
        guard let to = parameters["to"],
              let subject = parameters["subject"],
              let body = parameters["body"] else {
            return nil
        }
        
        let contentType = parameters["contentType"] ?? "text/plain"
        let cc = parameters["cc"] ?? ""
        let bcc = parameters["bcc"] ?? ""
        
        // Create a simple email message structure
        var emailData: [String: Any] = [
            "raw": createRawEmailString(
                to: to,
                cc: cc,
                bcc: bcc,
                subject: subject,
                body: body,
                contentType: contentType
            )
        ]
        
        // Convert to JSON data
        return try? JSONSerialization.data(withJSONObject: emailData)
    }
    
    private func createRawEmailString(to: String, cc: String, bcc: String, subject: String, 
                                     body: String, contentType: String) -> String {
        // Create email headers
        var emailString = "To: \(to)\n"
        
        if !cc.isEmpty {
            emailString += "Cc: \(cc)\n"
        }
        
        if !bcc.isEmpty {
            emailString += "Bcc: \(bcc)\n"
        }
        
        emailString += "Subject: \(subject)\n"
        emailString += "Content-Type: \(contentType)\n\n"
        emailString += body
        
        // In a real implementation, we would encode this in base64
        // Here we just return a placeholder for demonstration
        let dummyBase64 = Data(emailString.utf8).base64EncodedString()
        return dummyBase64
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
let capability = GmailSendMessageCapability(
    organization: "google",
    group: "gmail",
    capability: "SendMessage"
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
