import json
import urllib.request
import urllib.parse
import argparse


def perform_search(query, output_format, base_url, num_results=10, user_agent=None):
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

    # Default User-Agent if not specified
    if user_agent is None:
        user_agent = "python-searxng-extension/1.0"

    try:
        req = urllib.request.Request(
            url,
            headers={
                "User-Agent": user_agent,
                "Accept": "application/json",
            },
        )
        with urllib.request.urlopen(req) as response:
            if response.status == 200:
                data = json.loads(response.read().decode("utf-8"))

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
        help="The format of the output",
    )
    parser.add_argument(
        "--base-url",
        required=True,
        help="The SearXNG base URL (e.g., https://srx.example.com/search). Required.",
    )
    parser.add_argument(
        "--num-results",
        type=int,
        default=10,
        help="Number of results to return (default: 10)",
    )
    parser.add_argument(
        "--user-agent",
        type=str,
        default=None,
        help="User-Agent header to use (default: python-searxng-extension/1.0)",
    )

    args = parser.parse_args()

    print(
        perform_search(
            args.query, args.format, args.base_url, args.num_results, args.user_agent
        )
    )


if __name__ == "__main__":
    main()
