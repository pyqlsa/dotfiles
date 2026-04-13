import sys
import json
import urllib.request
import urllib.parse
import argparse
import os

def perform_search(query, output_format, base_url, num_results=10):
    """Performs a search using the SearXNG instance."""
    params = {
        "q": query,
        "format": "json",
        "pageno": 1,
    }
    # SearXNG uses 'count' parameter to limit results
    if num_results > 0:
        params["count"] = num_results
    url = f"{base_url}?{urllib.parse.urlencode(params)}"

    try:
        req = urllib.request.Request(
            url,
            headers={
                "User-Agent": "python-searxng-extension/1.0",
                "Accept": "application/json",
            }
        )
        with urllib.request.urlopen(req) as response:
            if response.status == 200:
                data = json.loads(response.read().decode('utf-8'))
                
                if output_format == "condensed":
                    results = data.get("results", [])
                    # Limit to num_results if specified
                    if num_results > 0:
                        results = results[:num_results]
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
    parser.add_argument(
        "--num-results",
        type=int,
        default=10,
        help="Number of results to return (default: 10)"
    )
    
    args = parser.parse_args()
    
    # Use provided base-url or fallback to a default
    base_url = args.base_url or "https://srx.bleak-shaula.ts.net/search"
    
    print(perform_search(args.query, args.format, base_url, args.num_results))

if __name__ == "__main__":
    main()
