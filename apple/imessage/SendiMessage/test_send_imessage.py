#!/usr/bin/env python3
"""
Test script for the SendiMessage capability.
This script demonstrates how to invoke the SendiMessage capability directly.
"""

import os
import json
import subprocess
import argparse

def test_send_imessage(recipient_phone, message):
    """
    Test the SendiMessage capability by directly invoking the shell script.
    
    Args:
        recipient_phone (str): The phone number to send the message to
        message (str): The message content to send
    
    Returns:
        dict: The parsed JSON response from the capability
    """
    # Path to the capability script
    script_path = "/Users/matt/dev/spatiolabs/capabilities-store/apple/imessage/SendiMessage/main.zsh"
    
    # Ensure the script is executable
    os.chmod(script_path, 0o755)
    
    print(f"Sending iMessage to {recipient_phone}: '{message}'")
    
    try:
        # Execute the script with the parameters
        result = subprocess.run(
            [script_path, recipient_phone, message],
            capture_output=True,
            text=True,
            check=True
        )
        
        # Parse the JSON output
        output = json.loads(result.stdout)
        print(f"Result: {json.dumps(output, indent=2)}")
        
        if output.get("status") == "success":
            print("✅ Message sent successfully!")
        else:
            print(f"❌ Failed to send message: {output.get('status')}")
        
        return output
    
    except subprocess.CalledProcessError as e:
        print(f"❌ Error executing script: {e}")
        print(f"Script output: {e.stdout}")
        print(f"Script error: {e.stderr}")
        return {"status": "error", "error": str(e)}
    
    except json.JSONDecodeError as e:
        print(f"❌ Error parsing JSON response: {e}")
        print(f"Raw output: {result.stdout}")
        return {"status": "error", "error": f"Invalid JSON response: {e}"}

def main():
    """Main function to parse arguments and run the test"""
    parser = argparse.ArgumentParser(description="Test the SendiMessage capability")
    parser.add_argument("--phone", "-p", required=True, help="Recipient phone number")
    parser.add_argument("--message", "-m", required=True, help="Message content to send")
    
    args = parser.parse_args()
    
    test_send_imessage(args.phone, args.message)

if __name__ == "__main__":
    main()
