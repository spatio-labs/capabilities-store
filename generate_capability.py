#!/usr/bin/env python3
import json
import os
import re
import sys

def to_pascal_case(text):
    """Convert text to PascalCase (removing spaces and punctuation)."""
    words = re.split(r'\s|_|\W+', text)
    return ''.join(word.capitalize() for word in words if word)

def camel_to_kebab(name):
    """
    Convert a CamelCase string to kebab-case.
    Example: "GoogleCalendar" becomes "google-calendar"
    """
    s1 = re.sub('(.)([A-Z][a-z]+)', r'\1-\2', name)
    kebab = re.sub('([a-z0-9])([A-Z])', r'\1-\2', s1).lower()
    return kebab

def derive_org_name(filename):
    """
    Derive the organization name from the Postman collection file name.
    It removes the ".postman_collection.json" suffix if present, then
    converts the remaining string from CamelCase to kebab-case.
    """
    base = os.path.basename(filename)
    suffix = ".postman_collection.json"
    if base.endswith(suffix):
        base = base[:-len(suffix)]
    return camel_to_kebab(base)

def substitute_placeholders(raw_url):
    """
    Replace all placeholders in the raw URL with shell variable references.
    For example:
      - {{base_url}} becomes ${base_url}
      - {{item_id}} becomes ${item_id}
    """
    return re.sub(r"\{\{(.*?)\}\}", lambda m: '${' + m.group(1) + '}', raw_url)

def process_items(items, endpoints):
    """
    Recursively process the collection items.
    For every item with a "request", record its name, raw URL, HTTP method,
    and extract header info if present.
    """
    for item in items:
        if "item" in item:
            process_items(item["item"], endpoints)
        elif "request" in item:
            endpoint = {}
            endpoint['name'] = item.get("name", "unnamed")
            # Extract raw URL.
            if isinstance(item["request"].get("url"), dict) and "raw" in item["request"]["url"]:
                endpoint['raw_url'] = item["request"]["url"]["raw"]
            else:
                host = item["request"]["url"].get("host", [])
                path = item["request"]["url"].get("path", [])
                endpoint['raw_url'] = "/".join(host + path)
            endpoint['method'] = item["request"].get("method", "GET").upper()
            
            # Process headers.
            endpoint["headers"] = []
            headers = item["request"].get("header", [])
            auth_input = None
            auth_type = None
            for header in headers:
                key = header.get("key", "")
                value = header.get("value", "")
                # If this is an Authorization header with Bearer, treat it as an auth input.
                if key.lower() == "authorization" and value.startswith("Bearer"):
                    auth_type = "OAuth2.0"  # Updated capitalization.
                    m = re.search(r"\{\{(.*?)\}\}", value)
                    if m:
                        auth_input = m.group(1)
                    # Do not add this header to the headers list.
                else:
                    endpoint["headers"].append({
                        "key": key,
                        "value": value
                    })
            endpoint["auth_type"] = auth_type if auth_type else "None"
            if auth_input:
                endpoint["auth_input"] = auth_input
            endpoints.append(endpoint)

def generate_atomic_capabilities(postman_path, org_dir):
    """
    Process a single Postman collection file and generate capabilities
    in the provided org_dir.
    """
    organization = os.path.basename(os.path.normpath(org_dir))
    os.makedirs(org_dir, exist_ok=True)
    
    # Load the Postman collection JSON.
    with open(postman_path, 'r') as f:
        collection = json.load(f)
    
    # Collection-level info.
    collection_vars = {var['key']: var['value'] for var in collection.get('variable', [])}
    base_url_value = collection_vars.get("base_url", "")
    
    # Gather endpoints recursively.
    endpoints = []
    process_items(collection.get("item", []), endpoints)
    
    group = ""  # Adjust group if needed.
    
    # For each endpoint, create its own atomic capability.
    for ep in endpoints:
        # Create a directory name using PascalCase of the endpoint's name.
        dir_name = to_pascal_case(ep['name'])
        cap_dir = os.path.join(org_dir, dir_name)
        os.makedirs(cap_dir, exist_ok=True)
        
        # Determine parameters present in the endpoint URL.
        raw_url = ep['raw_url']
        params = set(re.findall(r"\{\{(.*?)\}\}", raw_url))
        inputs = []
        for param in params:
            if param == "base_url":
                continue  # Handled via dedicated field.
            inputs.append({
                "name": param,
                "datatype": "string",
                "inputType": "text",
                "required": True,
                "defaultValue": "",
                "description": ""
            })
        # If an auth token was extracted, add it as an input with type OAuth2.0.
        if ep.get("auth_type", "None") != "None" and "auth_input" in ep:
            auth_var = ep["auth_input"]
            if not any(inp["name"] == auth_var for inp in inputs):
                inputs.append({
                    "name": auth_var,
                    "datatype": "OAuth2.0",
                    "inputType": "text",
                    "required": True,
                    "defaultValue": "",
                    "description": "Bearer token for OAuth2.0 authentication"
                })
        
        # Build capability.json.
        cap_json = {
            "schemaVersion": "1.0",
            "type": "api",
            "name": ep['name'],
            "description": ep['name'],  # Description same as name.
            "entry_point": "main.zsh",
            "organization": organization,
            "group": group,
            "base_url": base_url_value,
            "inputs": inputs,
            "output": "json",
            "auth_type": ep.get("auth_type", "None"),
            "headers": ep.get("headers", [])
        }
        
        with open(os.path.join(cap_dir, "capability.json"), "w") as f:
            json.dump(cap_json, f, indent=2)
        
        # Process raw URL.
        processed_url = substitute_placeholders(raw_url)
        
        # Build main.zsh script.
        curl_command = f'curl -s -X {ep["method"]}'
        # If an auth token is present, include an Authorization header.
        if ep.get("auth_type", "None") != "None" and "auth_input" in ep:
            curl_command += f' -H "Authorization: Bearer ${{{ep["auth_input"]}}}"'
        # Append any additional headers.
        for header in ep.get("headers", []):
            header_value = re.sub(r"\{\{(.*?)\}\}", lambda m: '${' + m.group(1) + '}', header["value"])
            curl_command += f' -H "{header["key"]}: {header_value}"'
        curl_command += f' "$URL" | jq'
        
        zsh_lines = [
            "#!/bin/zsh",
            f'URL="{processed_url}"',
            curl_command
        ]
        
        main_zsh_path = os.path.join(cap_dir, "main.zsh")
        with open(main_zsh_path, "w") as f:
            f.write("\n".join(zsh_lines))
        os.chmod(main_zsh_path, 0o755)
        
        print(f"Created atomic capability for endpoint '{ep['name']}' in directory: {cap_dir}")

def main():
    # If no command-line argument is provided, use current directory.
    if len(sys.argv) < 2:
        input_path = "."
    else:
        input_path = sys.argv[1]

    if os.path.isdir(input_path):
        # Process all files ending with .postman_collection.json in the directory.
        files = [os.path.join(input_path, f) for f in os.listdir(input_path)
                 if f.endswith(".postman_collection.json")]
        if not files:
            print("No Postman collection JSON files found in", input_path)
            sys.exit(1)
        for f in files:
            org_dir = "./" + derive_org_name(f)
            print(f"Processing file: {f} -> Org: {org_dir}")
            generate_atomic_capabilities(f, org_dir)
    elif os.path.isfile(input_path):
        org_dir = "./" + derive_org_name(input_path)
        generate_atomic_capabilities(input_path, org_dir)
    else:
        print("Invalid input path:", input_path)
        sys.exit(1)

if __name__ == "__main__":
    main()