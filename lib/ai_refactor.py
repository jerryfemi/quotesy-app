import os
import json
import time
import requests
from dotenv import load_dotenv, find_dotenv

# Load API Key securely
load_dotenv(find_dotenv(usecwd=True))
api_key = os.getenv("GEMINI_API_KEY")

if not api_key:
    print("❌ ERROR: GEMINI_API_KEY not found in .env file.")
    exit(1)

# Configuration
INPUT_FILE = "quotesy_final.json"
OUTPUT_FILE = "quotesy_editorial.json"
STATE_FILE = "quotesy_editorial_state.json"
BATCH_SIZE = 20
DELAY_BETWEEN_BATCHES = 0  # Tier 1 API limits are extremely high
MODEL_URL = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key={api_key}"

SYSTEM_PROMPT = """You are a ruthless, brilliant literary editor and master translator for an elegant quote app.
Your job is to read a list of quotes and refine them into profound masterpieces.

RULES:
1. NON-ENGLISH: If a quote is in a non-English language, DO NOT reject it. Instead, expertly TRANSLATE it into beautiful, poetic English.
2. VAGUE/UNORIGINAL: If a quote is purely academic history, a rambling journal entry, vague, generic, or completely lacks a profound, poetic impact: return strictly the exact word REJECT.
3. RAMBLING/FLUFF: If a quote has a brilliant, profound core sentence but is buried in a massive rambling paragraph, vigorously TRIM it down to JUST the profound sentence(s). Remove all fluff.
4. PERFECT: If a quote is already perfect, punchy, and profound: return it EXACTLY AS WRITTEN.
5. You are only allowed to translate, trim, or reject.

RESPOND ONLY WITH VALID JSON.
Format your response exactly like this, where the keys are the IDs I give you:
{
  "12": "The perfectly trimmed or translated quote...",
  "13": "REJECT",
  "14": "The exact original perfect quote..."
}
"""

def load_data():
    try:
        with open(INPUT_FILE, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception as e:
        print(f"❌ Error loading {INPUT_FILE}: {e}")
        return []

def load_state():
    if os.path.exists(STATE_FILE):
        try:
            with open(STATE_FILE, "r", encoding="utf-8") as f:
                return json.load(f)
        except Exception:
            return {}
    return {}

def save_state(state):
    with open(STATE_FILE, "w", encoding="utf-8") as f:
        json.dump(state, f, indent=2, ensure_ascii=False)

def process_batch(quotes_batch):
    prompt_text = "Refine the following quotes and return the JSON map:\n\n"
    for q in quotes_batch:
        prompt_text += f"ID: {q['id']}\nText: {q['text']}\n\n"

    payload = {
        "contents": [{"parts": [{"text": SYSTEM_PROMPT + "\n\n" + prompt_text}]}],
        "generationConfig": {
            "temperature": 0.1,
            "response_mime_type": "application/json"
        }
    }

    retries = 3
    for attempt in range(retries):
        try:
            response = requests.post(MODEL_URL, json=payload, timeout=90)
            if response.status_code == 200:
                result_text = response.json()['candidates'][0]['content']['parts'][0]['text']
                # Gemini returns markdown sometimes, strip it
                result_text = result_text.replace("```json", "").replace("```", "").strip()
                return json.loads(result_text)
            else:
                print(f"  ⚠️ API Error {response.status_code}: {response.text}")
                time.sleep(2)
        except Exception as e:
            print(f"  ⚠️ Error (Attempt {attempt+1}/{retries}): {e}")
            time.sleep(2)
            
    print("  ❌ Failed to process batch after multiple attempts.")
    return None

def main():
    quotes = load_data()
    if not quotes:
        return

    # Assign IDs
    for i, q in enumerate(quotes):
        q['id'] = i

    state = load_state()
    
    # Extract IDs to process
    unprocessed_quotes = [q for q in quotes if str(q['id']) not in state]
    total_unprocessed = len(unprocessed_quotes)
    
    print(f"Starting AI Editorial pass.")
    print(f"Total quotes: {len(quotes)}")
    print(f"Already processed: {len(state)}")
    print(f"Remaining to process: {total_unprocessed}")

    if total_unprocessed == 0:
        print("All quotes have been processed!")
        finalize_editorial()
        return

    # Process in batches
    for i in range(0, total_unprocessed, BATCH_SIZE):
        batch = unprocessed_quotes[i:i + BATCH_SIZE]
        print(f"\nProcessing chunk {i // BATCH_SIZE + 1} / {-(total_unprocessed // -BATCH_SIZE)}...")
        
        results = process_batch(batch)
        if results:
            for quote_id, editorial_text in results.items():
                state[str(quote_id)] = editorial_text
            save_state(state)
            print(f"  Saved {len(results)} editorial tags.")
        else:
            print("  Halting due to recurring errors.")
            break
            
        time.sleep(DELAY_BETWEEN_BATCHES)

    print("\nAI Editorial process complete! Run this script again to finalize the JSON output.")

def finalize_editorial():
    print("Generating final curated library...")
    quotes = load_data()
    state = load_state()

    # Assign IDs
    for i, q in enumerate(quotes):
        q['id'] = i
    
    final_quotes = []
    rejected_count = 0
    trimmed_count = 0
    kept_count = 0

    for q in quotes:
        qid = str(q['id'])
        if qid in state:
            edit = state[qid].strip()
            
            # Check Reject
            if edit.upper() == "REJECT" or edit == "":
                rejected_count += 1
                continue
                
            original_text = q['text'].strip()
            
            if edit != original_text:
                trimmed_count += 1
            else:
                kept_count += 1
                
            q['text'] = edit
            final_quotes.append(q)

    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        json.dump(final_quotes, f, indent=2, ensure_ascii=False)

    print(f"Saved strictly curated library to: {OUTPUT_FILE}")
    print(f"Stats:")
    print(f"  - Original Length: {len(quotes)}")
    print(f"  - Total Kept Exactly as Was: {kept_count}")
    print(f"  - Total Trimmed / Improved: {trimmed_count}")
    print(f"  - Total Rejected (Fluff/Boring): {rejected_count}")
    print(f"  -> FINAL LENGTH: {len(final_quotes)}")

if __name__ == "__main__":
    state = load_state()
    quotes = load_data()
    if len(state) >= len(quotes) and len(quotes) > 0:
        finalize_editorial()
    else:
        main()
