import json
import os
import time
from typing import TypedDict
from dotenv import load_dotenv, find_dotenv
import google.generativeai as genai

# Load environment variables explicitly
load_dotenv(find_dotenv(usecwd=True))

api_key = os.getenv("GEMINI_API_KEY")
if not api_key or api_key == "your_api_key_here":
    print("❌ ERROR: Valid GEMINI_API_KEY not found in .env")
    print("Get your free key at: https://aistudio.google.com/")
    exit(1)

genai.configure(api_key=api_key)

# We use gemini-2.5-flash for the fastest available categorization with new Tier 1 limits
model = genai.GenerativeModel(
    "gemini-2.5-flash", 
    generation_config={"response_mime_type": "application/json"}
)

CATEGORIES = [
    "Existential",
    "Love & Yearning",
    "Psychology & Self",
    "War & Epic",
    "Spirituality & Faith",
    "Wit & Wisdom"
]

BATCH_SIZE = 40
DELAY_BETWEEN_BATCHES = 0  # Tier 1 rate limits (1000 RPM) allow us to run without delays!

SYSTEM_PROMPT = f"""
You are an expert literary analyst categorizing quotes for an app.
Categorize each quote by its deeply authentic contextual meaning.
You must choose exactly ONE of these categories:
{json.dumps(CATEGORIES)}

Given a JSON list of quotes, return a JSON object where the keys are the quote IDs (strings) and the values are the chosen category strings.
Example Output:
{{
  "0": "Wit & Wisdom",
  "1": "Existential",
  "2": "Psychology & Self"
}}
"""

def load_data(input_file="quotesy_library.json", output_file="quotesy_ai_tagged.json"):
    with open(input_file, "r", encoding="utf-8") as f:
        quotes = json.load(f)
        
    for idx, q in enumerate(quotes):
        q["ai_id"] = str(idx)

    tagged = {}
    if os.path.exists(output_file):
        try:
            with open(output_file, "r", encoding="utf-8") as f:
                tagged = json.load(f)
            print(f"🔄 Resuming: Found {len(tagged)} quotes already tagged.")
        except Exception:
            pass

    return quotes, tagged

def run_categorizer():
    quotes, tagged = load_data()
    untagged_quotes = [q for q in quotes if q["ai_id"] not in tagged]
    
    if not untagged_quotes:
        print("✅ All quotes have been tagged by AI!")
        return

    print(f"🤖 Sending {len(untagged_quotes)} quotes to Gemini 2.5 Flash in batches of {BATCH_SIZE}...")
    
    for i in range(0, len(untagged_quotes), BATCH_SIZE):
        batch = untagged_quotes[i : i + BATCH_SIZE]
        batch_payload = [{"id": q["ai_id"], "author": q["author"], "text": q["text"]} for q in batch]
        
        prompt = SYSTEM_PROMPT + "\n\nTarget Quotes:\n" + json.dumps(batch_payload, indent=2)
        
        print(f"⏳ Processing chunk {i//BATCH_SIZE + 1}...")
        
        retries = 3
        while retries > 0:
            try:
                response = model.generate_content(prompt)
                ai_results = json.loads(response.text)
                
                for quote_id, category in ai_results.items():
                    if category in CATEGORIES:
                        tagged[quote_id] = category
                    else:
                        print(f"  Warning: AI suggested bad category '{category}' for ID {quote_id}. Defaulting to Wit & Wisdom.")
                        tagged[quote_id] = "Wit & Wisdom"
                break
                
            except Exception as e:
                print(f"  ⚠️ Error calling Gemini: {e}")
                retries -= 1
                if retries == 0:
                    print("  ❌ Saving progress and exiting due to repeated errors. Run script again to resume.")
                    break
                print("  Waiting 5 seconds before retry...")
                time.sleep(5)

        with open("quotesy_ai_tagged.json", "w", encoding="utf-8") as f:
            json.dump(tagged, f, indent=2, ensure_ascii=False)
            
        if retries == 0:
            break
            
        print(f"  ✅ Done. Wait {DELAY_BETWEEN_BATCHES}s...")
        time.sleep(DELAY_BETWEEN_BATCHES)

    print("🎉 Done! Run 'python lib/ai_merger.py' to finish up.")

if __name__ == "__main__":
    run_categorizer()
