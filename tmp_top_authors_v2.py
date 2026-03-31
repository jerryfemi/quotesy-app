import json
import collections
import os

def get_author_counts_by_category(file_paths):
    # data[category][author] = count
    data_map = collections.defaultdict(lambda: collections.Counter())
    
    for file_path in file_paths:
        if not os.path.exists(file_path):
            continue
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                data = json.load(f)
                for item in data:
                    author = item.get('author', 'Unknown Author').strip()
                    category = item.get('category', 'Uncategorized').strip()
                    if author and category:
                        data_map[category][author] += 1
        except Exception as e:
            print(f"Error reading {file_path}: {e}")
            
    return data_map

# Only use the main assets file as requested
assets_path = r'c:\Users\jerem\StudioProjects\quotes\assets\quotes.json'

all_counts = get_author_counts_by_category([assets_path])

print("# Top 10 Authors by Category (From assets/quotes.json only)\n")

for category in sorted(all_counts.keys()):
    print(f"## {category}")
    top_authors = all_counts[category].most_common(10)
    for i, (author, count) in enumerate(top_authors, 1):
        print(f"{i}. {author}: {count}")
    print()
