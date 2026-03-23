import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry
from bs4 import BeautifulSoup
from collections import Counter
import json
import re
import time
import argparse
from urllib.parse import quote


# ── Helpers ────────────────────────────────────────────────────────────────────

HEADERS = {
    "User-Agent": (
        "QuotesyBot/2.0 (educational scraper; "
        "contact: yourname@example.com)"
    )
}

JUNK_PATTERNS = re.compile(
    r"(ISBN|OCLC|Retrieved|wikiquote|Wikiquote|edit\]|"
    r"^\s*\d+\s*$|see also|external links|references)",
    re.IGNORECASE,
)

SECTION_CATEGORY_MAP = {
    # literature / philosophy
    "novels": "Literature",
    "works": "Literature",
    "letters": "Literature/Personal",
    "speeches": "Speeches",
    "interviews": "Interviews",
    # thematic
    "love": "Love",
    "life": "Life",
    "death": "Death",
    "god": "Religion/God",
    "religion": "Religion",
    "faith": "Religion/Faith",
    "philosophy": "Philosophy",
    "politics": "Politics",
    "society": "Society",
    "human nature": "Human Nature",
    "suffering": "Existential/Suffering",
    "freedom": "Freedom",
    "truth": "Truth",
    "beauty": "Beauty",
    "time": "Time",
    "science": "Science",
    "war": "War",
    "money": "Economy",
}


def infer_category(section_heading: str, author_name: str) -> str:
    """Map a section heading to a friendly category label."""
    heading_lower = section_heading.lower()
    for keyword, category in SECTION_CATEGORY_MAP.items():
        if keyword in heading_lower:
            return category
    # Fall back to the raw heading if it's informative, else author-based
    if len(section_heading) > 2 and section_heading.lower() not in (
        "quotes", "quotations", "sourced", "unsourced", "attributed",
        "misattributed", "see also",
    ):
        return section_heading.title()
    return "General"


def clean_text(raw: str) -> str:
    """Strip footnote markers, whitespace, and citation brackets."""
    text = re.sub(r"\[\d+\]", "", raw)   # [1], [2], …
    text = re.sub(r"\[edit\]", "", text, flags=re.IGNORECASE)
    text = re.sub(r"\s+", " ", text)
    return text.strip()


def is_valid_quote(text: str, min_length: int = 40) -> bool:
    """Return True only for clean, substantive quote text."""
    if len(text) < min_length:
        return False
    if JUNK_PATTERNS.search(text):
        return False
    # Skip lines that are mostly numbers / dates
    if re.fullmatch(r"[\d\s\-–,.:;()]+", text):
        return False
    return True


# ── Core scraper ───────────────────────────────────────────────────────────────

def fetch_quotes_from_page(
    author_name: str,
    max_quotes: int = 100,
    min_length: int = 40,
) -> list[dict]:
    """
    Scrape Wikiquote for *author_name* and return up to *max_quotes* quotes,
    each tagged with author + inferred category.
    """
    url = f"https://en.wikiquote.org/wiki/{quote(author_name.replace(' ', '_'))}"
    print(f"\n📖  Fetching: {url}")

    # Set up a session with automatic retries for transient errors
    session = requests.Session()
    retries = Retry(
        total=3,
        backoff_factor=1,          # 1s, 2s, 4s between retries
        status_forcelist=[429, 500, 502, 503, 504],
        allowed_methods=["GET"],
    )
    session.mount("https://", HTTPAdapter(max_retries=retries))

    try:
        response = session.get(url, headers=HEADERS, timeout=15)
        response.raise_for_status()
    except requests.RequestException as e:
        print(f"❌  Network error: {e}")
        return []

    soup = BeautifulSoup(response.text, "html.parser")
    content_div = soup.find("div", {"id": "mw-content-text"})
    if not content_div:
        print("❌  Could not locate content on the page.")
        return []

    quotes: list[dict] = []
    seen: set[str] = set()
    current_section = "General"

    for element in content_div.descendants:
        # Track which section we are in
        if element.name in ("h2", "h3", "h4"):
            heading_text = element.get_text(separator=" ", strip=True)
            heading_text = re.sub(r"\[edit\]", "", heading_text, flags=re.IGNORECASE).strip()
            current_section = heading_text

        # Harvest quotes from list items only
        if element.name == "li":
            # Avoid nested <li> inside <ul> that are sub-bullets (citations)
            parent = element.find_parent("ul")
            grandparent = parent.find_parent("li") if parent else None
            if grandparent:
                continue  # skip citation sub-bullets

            # ── Extract source from nested sub-list (citation) ──
            # Wikiquote nests sources as <ul><li>...</li></ul> inside the quote <li>.
            # We work on a copy so we don't corrupt the live tree mid-iteration.
            from copy import copy
            el_copy = copy(element)
            # Re-parse the copy so we get a standalone tree to safely decompose
            el_copy = BeautifulSoup(str(element), "html.parser")

            source = "Unknown"
            sub_list = el_copy.find("ul")
            if sub_list:
                source_li = sub_list.find("li")
                if source_li:
                    source = clean_text(source_li.get_text(separator=" ", strip=True))
                sub_list.decompose()  # remove citation from copy

            # Now get clean quote text (without the source/citation)
            raw = el_copy.get_text(separator=" ", strip=True)
            text = clean_text(raw)

            if not is_valid_quote(text, min_length):
                continue

            # Deduplicate by first 80 chars (catches near-duplicates too)
            fingerprint = text[:80].lower()
            if fingerprint in seen:
                continue
            seen.add(fingerprint)

            category = infer_category(current_section, author_name)

            quotes.append(
                {
                    "text": text,
                    "author": author_name,
                    "source": source,
                    "category": category,
                    "source_section": current_section,
                }
            )

            if len(quotes) >= max_quotes:
                break

    if len(quotes) == 0:
        print(f"⚠️  No quotes found for '{author_name}'. The page structure may have changed.")
    else:
        print(f"✅  Collected {len(quotes)} quotes.")
    return quotes


# ── Multi-author support ───────────────────────────────────────────────────────

def fetch_multiple_authors(
    authors: list[str],
    max_per_author: int = 100,
    min_length: int = 40,
    delay: float = 1.0,
) -> list[dict]:
    """Fetch quotes for several authors with a polite delay between requests."""
    all_quotes: list[dict] = []
    for i, author in enumerate(authors):
        quotes = fetch_quotes_from_page(author, max_quotes=max_per_author, min_length=min_length)
        all_quotes.extend(quotes)
        if i < len(authors) - 1:
            print(f"⏳  Waiting {delay}s before next request…")
            time.sleep(delay)
    return all_quotes


# ── Output ─────────────────────────────────────────────────────────────────────

def save_library(quotes: list[dict], output_file: str = "quotesy_library.json") -> None:
    with open(output_file, "w", encoding="utf-8") as f:
        json.dump(quotes, f, indent=4, ensure_ascii=False)
    print(f"\n💾  Saved {len(quotes)} quotes → {output_file}")


def print_summary(quotes: list[dict]) -> None:
    cats = Counter(q["category"] for q in quotes)
    authors = Counter(q["author"] for q in quotes)
    print("\n── Summary ──────────────────────────────")
    print(f"  Total quotes : {len(quotes)}")
    print(f"  Authors      : {len(authors)}")
    for author, count in authors.most_common():
        print(f"    • {author}: {count}")
    print(f"  Categories   : {len(cats)}")
    for cat, count in cats.most_common(10):
        print(f"    • {cat}: {count}")
    print("─────────────────────────────────────────\n")


# ── CLI entry point ────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(
        description="Scrape literary quotes from Wikiquote."
    )
    parser.add_argument(
        "authors",
        nargs="*",
        default=["Fyodor Dostoevsky"],
        help="One or more author names (default: Fyodor Dostoevsky)",
    )
    parser.add_argument(
        "--max", "-m",
        type=int,
        default=100,
        help="Max quotes per author (default: 100)",
    )
    parser.add_argument(
        "--output", "-o",
        default="quotesy_library.json",
        help="Output JSON file (default: quotesy_library.json)",
    )
    parser.add_argument(
        "--min-length",
        type=int,
        default=40,
        help="Minimum character length for a quote (default: 40)",
    )
    args = parser.parse_args()

    quotes = fetch_multiple_authors(args.authors, max_per_author=args.max, min_length=args.min_length)
    print_summary(quotes)
    save_library(quotes, args.output)


if __name__ == "__main__":
    main()