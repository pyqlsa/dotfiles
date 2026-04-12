import sys
import json
import urllib.request
import urllib.parse
import argparse
import os

def perform_search(query, output_format, base_url):
    """Performs a search using the SearXNG instance."""
    params = {
        "q": query,
        "format": "json"
    }
    url = f"{base_url}?{urllib.parse.urlencode(params)}"

    try:
        req = urllib.request.Request(url)
        with urllib.request.urlopen(req) as response:
            if response.status == 200:
                data = json.loads(response.read().decode('utf-8'))
                
                if output_format == "condensed":
                    results = data.get("results", [])
                    if not results:
                        return "No results found."
                    
                    output = []
                    for i, result in enumerate(results, 1):
                        title = result.get("title", "No title")
                        url = result.get("url", "")
                        snippet = result.get("snippet", "").replace("\n", " ").strip()
                        output.append(f"{i}. [{title}]({url}) - {snippet}")
                    return "\n\n".join(output)
                else:
                    return json.dumps(data, indent=2)
            else:
                return f"Error: Search failed with status {response.status}"
    except Exception as e:
        return f"Error: {str(e)}"

def main():
    parser = argparse.ArgumentParser(description="SearXNG CLI Search Tool")
    parser.add_argument("query", help="The search query")
    parser.add_argument(
        "--format", 
        choices=["condensed", "json"], 
        default="condensed", 
        help="The format of the output"
    )
    parser.add_argument(
        "--base-url",
        help="The SearXNG base URL (e.g., https://srx.example.com/search)"
    )
    
    args = parser.parse_args()
    
    # Use provided base-url or fallback to a default
    base_url = args.base_url or "https://srx.bleak-shaula.ts.net/search"
    
    print(perform_search(args.query, args.format, base_url))

if __name__ == "__main__":
    main()
