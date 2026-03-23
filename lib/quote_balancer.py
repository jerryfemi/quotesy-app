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


def balance_library(quotes: list[dict], max_per_cat: int = MAX_PER_CATEGORY) -> list[dict]:
    """Balance quotes across categories and authors."""

    # Group quotes by category
    by_category: dict[str, list[dict]] = defaultdict(list)
    dropped_general = 0

    for q in quotes:
        cat = q.get("category", "General")
        if cat in APP_CATEGORIES:
            by_category[cat].append(q)
        else:
            dropped_general += 1

    print(f"\n🗑️  Dropped {dropped_general} quotes not in app categories (General/other)")

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
    parser = argparse.ArgumentParser(description="Balance scraped quotes by category and author.")
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
