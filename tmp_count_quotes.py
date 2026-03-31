import json
import collections
import os

def count_quotes(file_path, author_name):
    counts = collections.Counter()
    if not os.path.exists(file_path):
        return counts
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
            for item in data:
                if author_name.lower() in item.get('author', '').lower():
                    category = item.get('category', 'Uncategorized')
                    counts[category] += 1
    except Exception as e:
        print(f"Error reading {file_path}: {e}")
    return counts

author = "Fyodor Dostoevsky"
assets_path = r'c:\Users\jerem\StudioProjects\quotes\assets\quotes.json'

total_counts = count_quotes(assets_path, author)

print(f"Quote counts for {author} in assets/quotes.json:")
for cat, count in total_counts.most_common():
    print(f"- {cat}: {count}")

# Also check for other variations just in case
print("\nUnique author strings found matching 'Dostoevsky':")
unique_authors = set()
if os.path.exists(assets_path):
    with open(assets_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
        for item in data:
            if 'dostoevsky' in item.get('author', '').lower():
                unique_authors.add(item.get('author'))
for a in sorted(unique_authors):
    print(f"  * {a}")
