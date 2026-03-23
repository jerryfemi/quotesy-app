"""
Quote Balancer — Post-processes scraped quotes to produce a balanced library.

Reads a raw JSON file of scraped quotes and outputs a balanced version:
  • Keeps only quotes in the 6 app categories (drops "General")
  • Caps each category at a configurable max (default 400)
  • Balances authors within each category (no author > 30%)
  • Shuffles for variety
"""

import json
import random
import argparse
import re
from collections import Counter, defaultdict

# The 6 app categories
APP_CATEGORIES = [
    "Existential",
    "Love & Yearning",
    "Psychology & Self",
    "War & Epic",
    "Spirituality & Faith",
    "Wit & Wisdom",
]

MAX_PER_CATEGORY = 400
MAX_AUTHOR_SHARE = 0.30  # No single author > 30% of a category

# Strict mapping: Authors to their authentically allowed categories.
# First category in a list is the "Primary" default if no keywords match.
AUTHOR_MAP = {
    "Franz Kafka": ["Existential"],
    "Albert Camus": ["Existential"],
    "Soren Kierkegaard": ["Existential"],
    "Carl Jung": ["Psychology & Self"],
    "Marcus Aurelius": ["Psychology & Self"],
    "Rainer Maria Rilke": ["Love & Yearning"],
    "John Keats": ["Love & Yearning"],
    "Sun Tzu": ["War & Epic"],
    "Homer": ["War & Epic"],
    "Rumi": ["Spirituality & Faith"],
    "Khalil Gibran": ["Spirituality & Faith"],
    "C. S. Lewis": ["Spirituality & Faith"],
    "Fyodor Dostoevsky": ["Existential", "Spirituality & Faith", "Psychology & Self"],
    "Friedrich Nietzsche": ["Existential", "Psychology & Self", "Wit & Wisdom"],
    "Leo Tolstoy": ["War & Epic", "Spirituality & Faith"],
    "Winston Churchill": ["War & Epic", "Wit & Wisdom"],
    "Oscar Wilde": ["Wit & Wisdom", "Love & Yearning", "Spirituality & Faith"],
    "Mark Twain": ["Wit & Wisdom"],
    "Voltaire": ["Wit & Wisdom", "Existential"]
}

# Used purely for tie-breaking multi-category authors
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

def resolve_author_category(quote: dict) -> str:
    """Determine category purely based on strict author mapping."""
    author = quote["author"]
    allowed = AUTHOR_MAP.get(author)
    
    if not allowed:
        return "Unknown Author"
        
    if len(allowed) == 1:
        return allowed[0]
        
    # Tie-breaker for multi-category authors
    text_lower = quote["text"].lower()
    for cat in allowed:
        keywords = KEYWORD_CATEGORIES.get(cat, [])
        for kw in keywords:
            # Word boundary match to avoid substring matches (e.g., 'art' in 'part')
            if re.search(rf"\b{re.escape(kw)}\b", text_lower):
                return cat
                
    # If no keywords match, default to their primary (first) category
    return allowed[0]

def balance_library(quotes: list[dict], max_per_cat: int = MAX_PER_CATEGORY) -> list[dict]:
    """Balance quotes across categories strictly derived from authorship."""

    by_category: dict[str, list[dict]] = defaultdict(list)
    dropped_authors = 0

    for q in quotes:
        resolved_cat = resolve_author_category(q)
        if resolved_cat in APP_CATEGORIES:
            q["category"] = resolved_cat  # Overwrite raw category
            by_category[resolved_cat].append(q)
        else:
            dropped_authors += 1

    print(f"\n🗑️  Dropped {dropped_authors} quotes from non-roster authors")

    balanced: list[dict] = []

    for cat in APP_CATEGORIES:
        pool = by_category[cat]
        random.shuffle(pool)

        if len(pool) == 0:
            print(f"⚠️  {cat}: 0 quotes found!")
            continue

        # Count authors in this category
        author_counts = Counter(q["author"] for q in pool)
        max_per_author = max(int(max_per_cat * MAX_AUTHOR_SHARE), 1)

        # First pass: cap each author at max_per_author
        capped: list[dict] = []
        author_used: dict[str, int] = defaultdict(int)

        for q in pool:
            author = q["author"]
            if author_used[author] < max_per_author:
                capped.append(q)
                author_used[author] += 1

        # Second pass: cap the category total
        selected = capped[:max_per_cat]
        balanced.extend(selected)

        # Print stats for this category
        final_authors = Counter(q["author"] for q in selected)
        print(f"\n📂  {cat}: {len(selected)} quotes (from pool of {len(pool)})")
        for author, count in final_authors.most_common():
            print(f"      • {author}: {count}")

    return balanced


def main():
    parser = argparse.ArgumentParser(description="Balance scraped quotes strictly against author boundaries.")
    parser.add_argument("input", help="Input raw JSON file")
    parser.add_argument("--output", "-o", default="quotesy_library.json", help="Output balanced JSON file")
    parser.add_argument("--max-per-category", type=int, default=MAX_PER_CATEGORY, help="Max quotes per category (default: 400)")
    parser.add_argument("--seed", type=int, default=42, help="Random seed for reproducibility")
    args = parser.parse_args()

    random.seed(args.seed)

    with open(args.input, "r", encoding="utf-8") as f:
        raw_quotes = json.load(f)

    print(f"📥  Loaded {len(raw_quotes)} raw quotes")

    balanced = balance_library(raw_quotes, max_per_cat=args.max_per_category)

    # Final summary
    cats = Counter(q["category"] for q in balanced)
    print(f"\n── Final Library ────────────────────────")
    print(f"  Total quotes: {len(balanced)}")
    for cat in APP_CATEGORIES:
        print(f"    • {cat}: {cats.get(cat, 0)}")
    print(f"─────────────────────────────────────────\n")

    with open(args.output, "w", encoding="utf-8") as f:
        json.dump(balanced, f, indent=2, ensure_ascii=False)

    print(f"💾  Saved → {args.output}")


if __name__ == "__main__":
    main()
