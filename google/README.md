# Google Remote Capabilities

This directory contains Swift-based remote capabilities for Google services that use the SpatioSDK package.

## Overview

The capabilities are organized by Google service:

- **Gmail**: Email-related capabilities
- **Google Calendar**: Calendar and event capabilities
- **Google Drive**: File storage and management capabilities

## Prerequisites

- [Swift](https://www.swift.org/download/) installed on your machine
- [swift-sh](https://github.com/mxcl/swift-sh) tool for running Swift scripts with dependencies

Install swift-sh using Homebrew:

```bash
brew install swift-sh
```

## Development Workflow

### Running Scripts Directly

You can run the Swift scripts directly during development:

```bash
chmod +x gmail/ListMessages/main.swift  # Make the script executable
./gmail/ListMessages/main.swift "search term"
```

### Compiling to Binaries

For distribution, compile the Swift scripts to standalone binaries:

```bash
cd gmail/ListMessages
swift sh main.swift --compile -o main
```

This will produce a binary named `main` that can be run without Swift being installed on the target machine.

## Authentication

All Google capabilities use a unified authentication system based on OAuth2:

1. Set up a Google Cloud Project
2. Enable the relevant APIs (Gmail, Drive, Calendar)
3. Create OAuth credentials
4. Set the authentication token in the `GOOGLE_AUTH_TOKEN` environment variable

The capabilities are configured to use this single environment variable for authentication across all Google services. This simplifies credential management while providing the flexibility to override authentication at the group or capability level if needed.

### Authentication Configuration

Authentication is configured at the organization level by default, which means all Google capabilities will use the same OAuth2 token. The configuration is defined in each capability's main.swift file:

```swift
// Configure Google API authentication
func configureGoogleAuth() {
    let googleOAuth = AuthConfig(
        type: .oauth2,
        parameterName: "Authorization",
        location: .header,
        valuePrefix: "Bearer ",
        envVariable: "GOOGLE_AUTH_TOKEN"
    )
    
    // Set at organization level (applies to all Google services)
    AuthManager.shared.setAuthConfig(for: "google", config: googleOAuth)
}
```

For service-specific authentication, you can override at the group level.

## Batch Compilation

Use the provided build script to compile all Swift capabilities:

```bash
# From the google directory
./build_all.sh
```

This will compile all capabilities and update their capability.json files to use the compiled binaries.

## Using in Production

For production use, deploy the compiled binaries:

1. Compile all capabilities using the build script
2. Deploy the binaries and capability.json files
3. Ensure proper authentication is set up on the target system

## Adding New Capabilities

1. Create a new directory under the appropriate service
2. Create a capability.json file defining the capability
3. Create a main.swift file implementing the capability using SpatioSDK
4. Test and compile the capability 