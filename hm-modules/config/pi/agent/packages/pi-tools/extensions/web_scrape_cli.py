#!/usr/bin/env python3
"""
Web Scraping CLI Tool

Fetches and extracts text content from web pages with retry logic.
Designed to be called from the pi web_scrape tool.

Usage:
    python web_scrape_cli.py <url1> [url2 ...] [--retries N] [--max-chars N]
"""

import sys
import json
import urllib.request
import argparse
import time
import re
import gzip
import zlib


def fetch_page_content(url: str, max_retries: int = 3, user_agent: str = None) -> dict:
    """
    Fetch and parse HTML content from a URL with retry logic.

    Args:
        url: The URL to fetch
        max_retries: Maximum number of retry attempts
        user_agent: User-Agent header to use (default: python-web-scrape-extension/1.0)

    Returns:
        Dictionary with url, title, text, error, and retry_count
    """
    # Default User-Agent if not specified
    if user_agent is None:
        user_agent = "python-web-scrape-extension/1.0"

    last_error = None

    for attempt in range(1, max_retries + 1):
        try:
            # Create request with proper headers
            req = urllib.request.Request(
                url,
                headers={
                    "User-Agent": user_agent,
                    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
                    "Accept-Language": "en-US,en;q=0.9",
                    "Accept-Encoding": "gzip;q=1.0, deflate;q=0.8, identity;q=0.5",  # Explicit priority, forbids br, zstd, etc.
                    "Connection": "keep-alive",
                },
            )

            with urllib.request.urlopen(req, timeout=30) as response:
                if response.status != 200:
                    raise Exception(f"HTTP {response.status}: {response.reason}")

                # Check content type
                content_type = response.headers.get("content-type", "")
                if "text/html" not in content_type:
                    return {
                        "url": url,
                        "error": f"Non-HTML content type: {content_type}",
                        "retry_count": attempt - 1,
                    }

                # Read and decode content, handling gzip compression
                raw_data = response.read()
                content_encoding = response.headers.get("content-encoding", "")

                # Try to detect and decompress based on format
                try:
                    # Check if it looks like gzip data (magic number: 1f 8b)
                    # This handles servers that send gzip without setting content-encoding header
                    if raw_data[:2] == b"\x1f\x8b":
                        html = gzip.decompress(raw_data).decode(
                            "utf-8", errors="ignore"
                        )
                    # Handle properly-labeled gzip responses
                    elif content_encoding in ("gzip", "x-gzip"):
                        html = gzip.decompress(raw_data).decode(
                            "utf-8", errors="ignore"
                        )
                    # Handle deflate/zlib responses (raw deflate stream)
                    elif content_encoding in ("deflate", "zlib"):
                        try:
                            # Try raw deflate first
                            html = zlib.decompress(raw_data).decode(
                                "utf-8", errors="ignore"
                            )
                        except zlib.error:
                            # Try with zlib headers (some servers send zlib-wrapped data)
                            try:
                                html = zlib.decompress(
                                    raw_data, -zlib.MAX_WBITS
                                ).decode("utf-8", errors="ignore")
                            except zlib.error:
                                # Try with full zlib headers
                                html = zlib.decompress(raw_data, zlib.MAX_WBITS).decode(
                                    "utf-8", errors="ignore"
                                )
                    # Uncompressed response
                    else:
                        html = raw_data.decode("utf-8", errors="ignore")
                except Exception:
                    # If decompression fails, try raw decode
                    html = raw_data.decode("utf-8", errors="ignore")

                # Extract title
                title_match = re.search(
                    r"<title[^>]*>([^<]+)</title>", html, re.IGNORECASE
                )
                title = title_match.group(1).strip() if title_match else None

                # Remove unwanted content using regex
                cleaned = html

                # Remove script, style, noscript tags
                cleaned = re.sub(
                    r"<script[^>]*>.*?</script>",
                    "",
                    cleaned,
                    flags=re.IGNORECASE | re.DOTALL,
                )
                cleaned = re.sub(
                    r"<style[^>]*>.*?</style>",
                    "",
                    cleaned,
                    flags=re.IGNORECASE | re.DOTALL,
                )
                cleaned = re.sub(
                    r"<noscript[^>]*>.*?</noscript>",
                    "",
                    cleaned,
                    flags=re.IGNORECASE | re.DOTALL,
                )

                # Remove nav, footer, header, aside tags
                cleaned = re.sub(
                    r"<nav[^>]*>.*?</nav>", "", cleaned, flags=re.IGNORECASE | re.DOTALL
                )
                cleaned = re.sub(
                    r"<footer[^>]*>.*?</footer>",
                    "",
                    cleaned,
                    flags=re.IGNORECASE | re.DOTALL,
                )
                cleaned = re.sub(
                    r"<header[^>]*>.*?</header>",
                    "",
                    cleaned,
                    flags=re.IGNORECASE | re.DOTALL,
                )
                cleaned = re.sub(
                    r"<aside[^>]*>.*?</aside>",
                    "",
                    cleaned,
                    flags=re.IGNORECASE | re.DOTALL,
                )

                # Remove iframe, object, embed
                cleaned = re.sub(
                    r"<(iframe|object|embed)[^>]*>.*?</\1>",
                    "",
                    cleaned,
                    flags=re.IGNORECASE | re.DOTALL,
                )

                # Remove elements with ad-related classes
                cleaned = re.sub(
                    r'<[^>]+class=["\'][^"\']*\b(ad|advertisement|adsbygoogle|nav|navigation|sidebar|widget|comment|share|social)\b[^"\']*["\'][^>]*>.*?</[^>]+>',
                    "",
                    cleaned,
                    flags=re.IGNORECASE | re.DOTALL,
                )

                # Remove all remaining HTML tags
                cleaned = re.sub(r"<[^>]+>", "", cleaned)

                # Decode HTML entities
                cleaned = cleaned.replace("&nbsp;", " ")
                cleaned = cleaned.replace("&amp;", "&")
                cleaned = cleaned.replace("&lt;", "<")
                cleaned = cleaned.replace("&gt;", ">")
                cleaned = cleaned.replace("&quot;", '"')
                cleaned = cleaned.replace("&#39;", "'")

                # Normalize whitespace
                cleaned = re.sub(r"\s+", " ", cleaned).strip()

                # Limit to max_chars (passed via environment or default)
                max_chars = (
                    int(sys.argv[1])
                    if len(sys.argv) > 1 and sys.argv[1].isdigit()
                    else 15000
                )
                text = cleaned[:max_chars]

                # Only return if we have meaningful content
                if text and len(text) > 50:
                    return {
                        "url": url,
                        "title": title,
                        "text": text,
                        "retry_count": attempt - 1,
                    }
                else:
                    raise Exception("No meaningful content extracted")

        except Exception as e:
            last_error = str(e)

            # Don't retry on certain errors
            if "Non-HTML" in str(e):
                return {"url": url, "error": str(e), "retry_count": attempt - 1}

            # Wait before retrying (exponential backoff)
            if attempt < max_retries:
                wait_time = min(1.0 * (2 ** (attempt - 1)), 5.0)  # Max 5 seconds
                time.sleep(wait_time)

    # All retries exhausted
    return {
        "url": url,
        "error": f"Failed after {max_retries} attempts: {last_error}",
        "retry_count": max_retries,
    }


def main():
    parser = argparse.ArgumentParser(
        description="Web Scraping CLI - Fetch and extract content from URLs"
    )
    parser.add_argument("urls", nargs="+", help="URLs to scrape (space-separated)")
    parser.add_argument(
        "--retries",
        type=int,
        default=3,
        help="Maximum retry attempts per URL (default: 3)",
    )
    parser.add_argument(
        "--max-chars",
        type=int,
        default=15000,
        help="Maximum characters to extract per page (default: 15000)",
    )
    parser.add_argument(
        "--output",
        choices=["json", "formatted"],
        default="json",
        help="Output format (default: json)",
    )
    parser.add_argument(
        "--user-agent",
        type=str,
        default=None,
        help="User-Agent header to use (default: python-web-scrape-extension/1.0)",
    )

    args = parser.parse_args()

    results = []

    # Process each URL
    for url in args.urls:
        result = fetch_page_content(url, args.retries, args.user_agent)

        # Add max_chars to the result for TypeScript to use
        if "text" in result:
            result["text"] = result["text"][: args.max_chars]

        results.append(result)

    # Output results
    if args.output == "json":
        print(json.dumps(results, indent=2))
    else:
        # Formatted output for debugging
        total = len(results)
        success = sum(1 for r in results if "text" in r)
        failed = total - success
        total_retries = sum(r.get("retry_count", 0) for r in results)

        print(f"== Web Scraping Results ==")
        print(f"Total URLs: {total}")
        print(f"Successful: {success}")
        print(f"Failed: {failed}")
        print(f"Total retries: {total_retries}")
        print()

        for i, result in enumerate(results, 1):
            print(f"--- Result {i} ---")
            print(f"URL: {result['url']}")

            if result.get("title"):
                print(f"Title: {result['title']}")

            if result.get("retry_count", 0) > 0:
                print(f"Retries: {result['retry_count']}")

            if result.get("error"):
                print(f"Error: {result['error']}")
            elif result.get("text"):
                print()
                print("Content:")
                print(
                    result["text"][:500] + "..."
                    if len(result.get("text", "")) > 500
                    else result.get("text", "")
                )

            print()
            print("-" * 50)
            print()


if __name__ == "__main__":
    main()
