#!/usr/bin/env python3
"""
Test script for Gmail ListMessages capability.
This script simulates how a macOS Swift app would utilize capability.json for metadata
and main.swift for execution of the Gmail API capabilities.
"""

import os
import json
import time
import base64
import socket
import webbrowser
import subprocess
import argparse
import urllib.parse
import http.server
import requests
from typing import Dict, Any, Optional, Tuple
from pathlib import Path

# Path constants
CURRENT_DIR = Path(os.path.dirname(os.path.abspath(__file__)))
CAPABILITY_JSON_PATH = CURRENT_DIR / "capability.json"
MAIN_SWIFT_PATH = CURRENT_DIR / "main.swift"
TOKEN_DIR = Path(os.path.expanduser("~/.spatio/tokens"))

# Load capability.json to extract metadata (simulating what the Swift app would do)
def load_capability_metadata() -> Dict[str, Any]:
    """Load and parse the capability.json file to extract metadata."""
    try:
        with open(CAPABILITY_JSON_PATH, 'r') as f:
            return json.load(f)
    except Exception as e:
        print(f"Error loading capability.json: {e}")
        return {}

# Extract auth configuration from capability metadata
def extract_auth_config(metadata: Dict[str, Any]) -> Dict[str, Any]:
    """Extract authentication configuration from capability metadata."""
    auth_config = metadata.get("auth", {})
    if not auth_config:
        print("Warning: No auth configuration found in capability.json")
    return auth_config

# Get capability metadata
CAPABILITY_METADATA = load_capability_metadata()
AUTH_CONFIG = extract_auth_config(CAPABILITY_METADATA)

# Extract OAuth configuration
CLIENT_ID = AUTH_CONFIG.get("client_id", "")
AUTH_URL = AUTH_CONFIG.get("auth_url", "")
TOKEN_URL = AUTH_CONFIG.get("token_url", "")
SCOPES = AUTH_CONFIG.get("scopes", [])
ENV_VARIABLE = AUTH_CONFIG.get("env_variable", "GOOGLE_AUTH_TOKEN")

# Additional configuration
# For desktop applications, we can use loopback IP with a dynamically assigned port
REDIRECT_URI = "http://localhost:8080/oauth2callback"
TOKEN_FILE = TOKEN_DIR / f"{CAPABILITY_METADATA.get('organization', 'google')}_token.json"

# Ensure token directory exists
os.makedirs(TOKEN_DIR, exist_ok=True)

class OAuthCallbackHandler(http.server.BaseHTTPRequestHandler):
    """Handle OAuth callback and capture the authorization code."""
    
    code = None
    
    def do_GET(self):
        """Process the callback request and extract the authorization code."""
        # Check if the path matches our callback path
        parsed_url = urllib.parse.urlparse(self.path)
        if not parsed_url.path.startswith('/oauth2callback'):
            self.send_response(404)
            self.end_headers()
            return
            
        query_components = urllib.parse.parse_qs(parsed_url.query)
        
        if 'code' in query_components:
            OAuthCallbackHandler.code = query_components['code'][0]
            self.send_response(200)
            self.send_header('Content-type', 'text/html')
            self.end_headers()
            
            response_content = """
            <html>
            <head><title>Authorization Successful</title></head>
            <body>
                <h1>Authorization Successful!</h1>
                <p>You have successfully authorized the application.</p>
                <p>You can close this window and return to the terminal.</p>
            </body>
            </html>
            """
            self.wfile.write(response_content.encode())
        else:
            self.send_response(400)
            self.send_header('Content-type', 'text/html')
            self.end_headers()
            
            error = query_components.get('error', ['Unknown error'])[0]
            response_content = f"""
            <html>
            <head><title>Authorization Failed</title></head>
            <body>
                <h1>Authorization Failed</h1>
                <p>Error: {error}</p>
                <p>Please try again.</p>
            </body>
            </html>
            """
            self.wfile.write(response_content.encode())
    
    def log_message(self, format, *args):
        """Suppress server logs."""
        return

def start_callback_server() -> http.server.HTTPServer:
    """Start a local server to receive the OAuth callback."""
    server = http.server.HTTPServer(('localhost', 8080), OAuthCallbackHandler)
    return server

def get_auth_url() -> str:
    """Generate the authorization URL for the OAuth flow."""
    params = {
        'client_id': CLIENT_ID,
        'redirect_uri': REDIRECT_URI,
        'scope': ' '.join(SCOPES),
        'response_type': 'code',
        'access_type': 'offline',
        'prompt': 'consent'
    }
    return f"{AUTH_URL}?{urllib.parse.urlencode(params)}"

def exchange_code_for_token(code: str) -> Dict[str, Any]:
    """Exchange the authorization code for an access token."""
    data = {
        'client_id': CLIENT_ID,
        'redirect_uri': REDIRECT_URI,
        'code': code,
        'grant_type': 'authorization_code'
    }
    
    response = requests.post(TOKEN_URL, data=data)
    
    if response.status_code != 200:
        raise Exception(f"Failed to exchange code for token: {response.text}")
    
    return response.json()

def save_token(token_data: Dict[str, Any]) -> None:
    """Save the token data to a file."""
    with open(TOKEN_FILE, 'w') as f:
        json.dump(token_data, f)
    print(f"Token saved to {TOKEN_FILE}")

def load_token() -> Optional[Dict[str, Any]]:
    """Load the token data from a file if it exists."""
    if os.path.exists(TOKEN_FILE):
        try:
            with open(TOKEN_FILE, 'r') as f:
                return json.load(f)
        except Exception as e:
            print(f"Error loading token: {e}")
    return None

def refresh_token(refresh_token_str: str) -> Dict[str, Any]:
    """Refresh an expired access token."""
    data = {
        'client_id': CLIENT_ID,
        'refresh_token': refresh_token_str,
        'grant_type': 'refresh_token'
    }
    
    response = requests.post(TOKEN_URL, data=data)
    
    if response.status_code != 200:
        raise Exception(f"Failed to refresh token: {response.text}")
    
    token_data = response.json()
    
    # Preserve the refresh token as it's not always returned
    if 'refresh_token' not in token_data:
        token_data['refresh_token'] = refresh_token_str
    
    return token_data

def get_valid_token() -> str:
    """Get a valid access token, refreshing if necessary or initiating OAuth flow."""
    token_data = load_token()
    
    # If we have a token, check if it's expired
    if token_data:
        # Check if token is expired (with 5 min buffer)
        expires_at = token_data.get('created_at', 0) + token_data.get('expires_in', 0) - 300
        
        if 'created_at' not in token_data:
            # Add creation timestamp if not present
            token_data['created_at'] = int(time.time())
            save_token(token_data)
        
        if time.time() > expires_at:
            print("Token expired, refreshing...")
            if 'refresh_token' in token_data:
                try:
                    token_data = refresh_token(token_data['refresh_token'])
                    token_data['created_at'] = int(time.time())
                    save_token(token_data)
                except Exception as e:
                    print(f"Error refreshing token: {e}")
                    token_data = None
            else:
                print("No refresh token available, need to re-authenticate")
                token_data = None
    
    # If we don't have a valid token, start the OAuth flow
    if not token_data:
        token_data = start_oauth_flow()
        if token_data:
            token_data['created_at'] = int(time.time())
            save_token(token_data)
    
    return token_data.get('access_token', '')

def start_oauth_flow() -> Optional[Dict[str, Any]]:
    """Start the OAuth flow by opening the browser and waiting for the callback."""
    auth_url = get_auth_url()
    
    # Start the callback server
    server = start_callback_server()
    
    # Open the browser
    print(f"Opening browser for Google authentication...")
    webbrowser.open(auth_url)
    
    # Wait for the callback
    print("Waiting for authentication to complete in the browser...")
    try:
        server.handle_request()
    except KeyboardInterrupt:
        print("Authentication cancelled")
        return None
    finally:
        server.server_close()
    
    # Check if we got the code
    if not OAuthCallbackHandler.code:
        print("Failed to get authorization code")
        return None
    
    # Exchange the code for a token
    print("Exchanging authorization code for token...")
    try:
        token_data = exchange_code_for_token(OAuthCallbackHandler.code)
        return token_data
    except Exception as e:
        print(f"Error exchanging code for token: {e}")
        return None

def test_list_messages(**kwargs) -> Dict[str, Any]:
    """
    Test the Gmail ListMessages capability with the provided parameters.
    Simulates how a macOS Swift app would execute the capability.
    
    Args:
        Accepts keyword arguments that match the parameters defined in capability.json
        
    Returns:
        Dict containing the API response
    """
    # 1. Get capability metadata (simulating what a Swift app would do)
    capability_inputs = CAPABILITY_METADATA.get("inputs", [])
    entry_point = CAPABILITY_METADATA.get("entry_point", "main.swift")
    
    # 2. Get a valid token through OAuth flow (simulating Swift app's auth process)
    access_token = get_valid_token()
    if not access_token:
        return {"error": "Failed to obtain access token"}
    
    # 3. Set the token in the environment using the variable name from capability.json
    os.environ[ENV_VARIABLE] = access_token
    
    # 4. Build command to execute the capability using the entry point from capability.json
    cmd = ["swift", str(MAIN_SWIFT_PATH)]
    
    # 5. Add parameters to command line (simulating how Swift would pass parameters)
    for name, value in kwargs.items():
        if value is not None:
            if isinstance(value, bool):
                cmd.extend([f"--{name}", str(value).lower()])
            else:
                cmd.extend([f"--{name}", str(value)])
    
    try:
        # Execute the capability
        print(f"Executing capability with command: {' '.join(cmd)}")
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            check=True
        )
        
        # Parse and return the JSON response
        return json.loads(result.stdout)
    
    except subprocess.CalledProcessError as e:
        print(f"Error executing capability: {e}")
        print(f"Stderr: {e.stderr}")
        return {"error": e.stderr}
    
    except json.JSONDecodeError as e:
        print(f"Error parsing JSON response: {e}")
        if 'result' in locals():
            print(f"Raw output: {result.stdout}")
        return {"error": "Invalid JSON response"}

def display_results(response: Dict[str, Any]) -> None:
    """Display the results in a readable format"""
    if "error" in response:
        print(f"Error: {response['error']}")
        return
    
    messages = response.get("messages", [])
    next_page_token = response.get("nextPageToken")
    
    print(f"Found {len(messages)} messages")
    
    for i, message in enumerate(messages, 1):
        print(f"{i}. Message ID: {message.get('id')}")
        
        # Print snippet if available
        if "snippet" in message:
            print(f"   Snippet: {message.get('snippet')[:60]}...")
    
    if next_page_token:
        print(f"\nNext page token: {next_page_token}")
        print("Use this token with --page-token to get the next page of results")

if __name__ == "__main__":
    # Print capability information (simulating app UI showing capability details)
    print(f"\n{'='*80}")
    print(f"CAPABILITY: {CAPABILITY_METADATA.get('name', 'Gmail List Messages')}")
    print(f"DESCRIPTION: {CAPABILITY_METADATA.get('description', 'Lists messages in Gmail')}")
    print(f"ORGANIZATION: {CAPABILITY_METADATA.get('organization', 'gmail')}")
    print(f"{'='*80}\n")
    
    # Create argument parser based on capability.json inputs (simulating Swift app UI)
    parser = argparse.ArgumentParser(description=CAPABILITY_METADATA.get('description', 'Test Gmail ListMessages capability'))
    
    # Add arguments based on capability.json inputs
    for input_def in CAPABILITY_METADATA.get('inputs', []):
        name = input_def.get('name')
        input_type = input_def.get('type')
        required = input_def.get('required', False)
        description = input_def.get('description', '')
        default_value = input_def.get('default', None)
        
        # Convert argument name for command line (e.g., maxResults -> --max-results)
        arg_name = f"--{name.replace('_', '-')}"
        short_name = f"-{name[0]}"
        
        if input_type == 'boolean':
            parser.add_argument(arg_name, short_name, action='store_true', help=description)
        elif input_type == 'integer':
            parser.add_argument(arg_name, short_name, type=int, 
                              default=default_value, required=required, help=description)
        else:  # string or other types
            parser.add_argument(arg_name, short_name, default=default_value, 
                              required=required, help=description)
    
    # Add special arguments for the test script
    parser.add_argument("--force-login", "-f", action="store_true", 
                      help="Force a new login even if a token exists")
    parser.add_argument("--verbose", "-v", action="store_true", 
                      help="Show detailed execution information")
    
    args = parser.parse_args()
    args_dict = vars(args)
    
    # Force new login if requested (simulating app logout function)
    if args_dict.pop('force_login', False) and os.path.exists(TOKEN_FILE):
        os.remove(TOKEN_FILE)
        print("Removed existing token, will perform new login")
    
    verbose = args_dict.pop('verbose', False)
    
    if verbose:
        print("\nCapability execution parameters:")
        for name, value in args_dict.items():
            if value is not None:
                print(f"  {name}: {value}")
        print()
    
    # Map CLI args back to capability parameters
    capability_args = {}
    for input_def in CAPABILITY_METADATA.get('inputs', []):
        name = input_def.get('name')
        cli_name = name.replace('_', '-')
        if cli_name in args_dict and args_dict[cli_name] is not None:
            capability_args[name] = args_dict[cli_name]
    
    # Run the test (simulating app execution of capability)
    print("Executing Gmail ListMessages capability...\n")
    response = test_list_messages(**capability_args)
    
    # Display the results (simulating app UI showing results)
    display_results(response)
    
    print(f"\n{'='*80}")
    print(f"Capability execution complete.")
    print(f"{'='*80}\n")
