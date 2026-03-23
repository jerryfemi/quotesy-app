import json

def merge_ai_tags():
    try:
        with open("quotesy_library.json", "r", encoding="utf-8") as f:
            library = json.load(f)
        with open("quotesy_ai_tagged.json", "r", encoding="utf-8") as f:
            tags = json.load(f)
    except FileNotFoundError:
        print("❌ ERROR: Ensure both 'quotesy_library.json' and 'quotesy_ai_tagged.json' exist.")
        return

    # tags is a dict of {"0": "Existential", "1": "Wit & Wisdom"}
    # The IDs correspond exactly to the index in library
    
    updated = 0
    for idx, q in enumerate(library):
        quote_id = str(idx)
        if quote_id in tags:
            q["category"] = tags[quote_id]
            updated += 1
            
    print(f"✅ Merged {updated} AI categories into the library.")
    
    with open("quotesy_final.json", "w", encoding="utf-8") as f:
        json.dump(library, f, indent=2, ensure_ascii=False)
        
    print("💾 Saved → quotesy_final.json")

if __name__ == "__main__":
    merge_ai_tags()
