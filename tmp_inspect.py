import json
from collections import Counter

data = json.load(open('quotesy_raw.json', 'r', encoding='utf-8'))
cats = Counter(q['category'] for q in data)
print('Category distribution:')
for cat, count in cats.most_common():
    print(f'  {cat}: {count}')

general = [q for q in data if q['category'] == 'General']
print(f'\n--- Sample "General" quotes ({len(general)} total) ---')
for q in general[:25]:
    print(f'  [{q["author"]}] {q["text"][:120]}')
