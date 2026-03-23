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
    # literature / philosophy — map to closest app category
    "novels": "Existential",
    "works": "Existential",
    "letters": "Psychology & Self",
    "diary": "Psychology & Self",
    "speeches": "War & Epic",
    "interviews": "Wit & Wisdom",
    # thematic (aligned to app categories)
    "love": "Love & Yearning",
    "life": "Wit & Wisdom",
    "death": "Existential",
    "god": "Spirituality & Faith",
    "religion": "Spirituality & Faith",
    "faith": "Spirituality & Faith",
    "philosophy": "Existential",
    "politics": "War & Epic",
    "society": "Wit & Wisdom",
    "human nature": "Psychology & Self",
    "suffering": "Existential",
    "freedom": "War & Epic",
    "truth": "Wit & Wisdom",
    "beauty": "Love & Yearning",
    "time": "Existential",
    "science": "Wit & Wisdom",
    "war": "War & Epic",
    "money": "Wit & Wisdom",
    "psychology": "Psychology & Self",
    "soul": "Spirituality & Faith",
    "poetry": "Love & Yearning",
    "art": "Love & Yearning",
    "morality": "Spirituality & Faith",
    "wisdom": "Wit & Wisdom",
    "humor": "Wit & Wisdom",
    "nature": "Love & Yearning",
}

# ── Keyword-based category fallback (scans quote TEXT) ─────────────────────────

KEYWORD_CATEGORIES = {
    "Spirituality & Faith": [
        "christ", "god", "faith", "soul", "prayer", "divine", "sin",
        "holy", "heaven", "hell", "sacred", "eternal", "salvation",
        "grace", "worship", "spirit", "blessed", "resurrection",
        "scripture", "prophets", "church", "believe", "saviour",
        "miracle", "redemption", "gospel", "mercy", "angels",
        "creator", "almighty", "righteous", "pious", "temple",
        "sermon", "devout", "communion", "psalm", "bible",
    ],
    "Love & Yearning": [
        "love", "heart", "longing", "beloved", "passion", "desire",
        "tenderness", "kiss", "embrace", "yearning", "affection",
        "devotion", "beauty", "romance", "lover", "intimacy",
        "wedding", "marriage", "adore", "gentle", "compassion",
        "tears", "weep", "sorrow", "miss you", "together",
        "apart", "wound", "cherish", "caress", "warmth",
        "tender", "rose", "flower", "sweet", "darling",
        "loneliness", "absence", "grief", "mourn",
    ],
    "Existential": [
        "absurd", "meaningless", "existence", "suffering", "despair",
        "void", "nothingness", "anxiety", "dread", "alienation",
        "fate", "doom", "mortality", "futile", "hopeless",
        "anguish", "solitude", "burden", "abyss", "death",
        "die", "dying", "grave", "darkness", "chaos",
        "purpose", "meaning", "reason", "why", "question",
        "truth", "lie", "reality", "nothing", "everything",
        "impossible", "absurdity", "tragedy", "tragic", "finite",
        "infinite", "eternity", "time", "end", "beginning",
        "human", "mankind", "humanity", "civilization", "world",
        "life", "live", "living", "born", "creation",
        "philosophy", "philosopher", "think", "thought", "reason",
        "cruel", "pain", "torment", "misery", "wretched",
    ],
    "Psychology & Self": [
        "unconscious", "shadow", "ego", "psyche", "dream", "self",
        "consciousness", "instinct", "archetype", "persona",
        "identity", "mind", "madness", "insanity", "neurosis",
        "repression", "memory", "illusion", "perception",
        "character", "nature", "understand", "feeling", "emotion",
        "fear", "anger", "guilt", "shame", "pride",
        "desire", "impulse", "motive", "behavior", "habit",
        "change", "grow", "become", "transform", "accept",
        "deny", "resist", "struggle", "inner", "within",
        "mirror", "face", "mask", "pretend", "hide",
        "strength", "weakness", "courage", "coward", "honest",
        "aware", "realize", "discover", "learn", "teach",
        "judge", "blame", "forgive", "responsible",
    ],
    "War & Epic": [
        "war", "soldier", "battle", "power", "empire", "conquer",
        "sword", "army", "victory", "defeat", "commander", "enemy",
        "revolution", "freedom", "nation", "glory", "courage",
        "resistance", "tyranny", "king", "ruler", "fight",
        "honour", "honor", "hero", "heroic", "brave",
        "country", "people", "state", "govern", "political",
        "justice", "law", "right", "defend", "protect",
        "sacrifice", "duty", "serve", "struggle", "rebel",
        "oppression", "liberty", "democracy", "republic",
    ],
    "Wit & Wisdom": [
        "fool", "wise", "laugh", "clever", "irony", "jest",
        "humor", "wit", "satire", "common sense", "experience",
        "education", "knowledge", "opinion", "society", "money",
        "success", "failure", "habit", "virtue", "advice",
        "man", "woman", "men", "women", "people",
        "always", "never", "everyone", "nobody", "secret",
        "true", "false", "simple", "difficult", "easy",
        "rich", "poor", "young", "old", "age",
        "book", "read", "write", "word", "speak",
        "friend", "friendship", "enemy", "marriage", "work",
        "happy", "happiness", "pleasure", "enjoy", "comfort",
    ],
}


def infer_category_from_text(quote_text: str) -> str:
    """Scan the quote text for keywords and return the best-matching category."""
    text_lower = quote_text.lower()
    scores: dict[str, int] = {cat: 0 for cat in KEYWORD_CATEGORIES}

    for category, keywords in KEYWORD_CATEGORIES.items():
        for kw in keywords:
            if kw in text_lower:
                scores[category] += 1

    best_cat = max(scores, key=scores.get)
    if scores[best_cat] > 0:
        return best_cat
    return "General"


def infer_category(section_heading: str, author_name: str, quote_text: str = "") -> str:
    """
    Map a section heading to a category label.
    Falls back to keyword-scanning the quote text if the heading is uninformative.
    """
    heading_lower = section_heading.lower()
    for keyword, category in SECTION_CATEGORY_MAP.items():
        if keyword in heading_lower:
            return category

    # Scan the actual quote text for keyword matches
    if quote_text:
        return infer_category_from_text(quote_text)

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
    # Skip non-English quotes (Cyrillic, CJK, etc.)
    ascii_chars = sum(1 for c in text if ord(c) < 128)
    if ascii_chars / len(text) < 0.7:
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

    # Find all headings and list items in document order
    elements = content_div.find_all(['h2', 'h3', 'h4', 'li'])

    for element in elements:
        # Track which section we are in
        if element.name in ("h2", "h3", "h4"):
            heading_text = element.get_text(separator=" ", strip=True)
            heading_text = re.sub(r"\[edit\]", "", heading_text, flags=re.IGNORECASE).strip()
            current_section = heading_text
            continue

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

            category = infer_category(current_section, author_name, text)

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