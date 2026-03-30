import os
import json
import re
import time
import requests
from bs4 import BeautifulSoup
from collections import Counter
from urllib.parse import quote
from urllib3.util.retry import Retry
from requests.adapters import HTTPAdapter
from dotenv import load_dotenv, find_dotenv

# ── Configuration ───────────────────────────────────────────────────────────────
load_dotenv(find_dotenv(usecwd=True))
api_key = os.getenv("GEMINI_API_KEY")

if not api_key:
    print("❌ ERROR: GEMINI_API_KEY not found in .env file.")
    exit(1)

MODEL_URL = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key={api_key}"
OUTPUT_FILE = "new_scraped_quotes.json"
EXISTING_QUOTES_FILE = "../assets/quotes.json" # Relative to scripts folder
BATCH_SIZE = 25
TARGET_FINAL_QUOTES = 100

HEADERS = {
    "User-Agent": "QuotesyBot/4.0 (AI Categorization & Duplicate Guard)"
}

JUNK_PATTERNS = re.compile(
    r"(ISBN|OCLC|Retrieved|wikiquote|Wikiquote|edit\]|^\s*\d+\s*$|see also|external links|references)",
    re.IGNORECASE,
)

# The exact 6 categories
CATEGORIES = [
    "Existential",
    "War & Epic",
    "Psychology & Self",
    "Wit & Wisdom",
    "Spirituality & Faith",
    "Love & Yearning"
]

# ── AI Prompt ────────────────────────────────────────────────────────────────
SYSTEM_PROMPT = f"""You are a ruthless, brilliant literary editor and master translator for an elegant quote app.
Your job is to read a list of raw quotes, pick the absolutely most profound ones, and strictly categorize them.

RULES:
1. NON-ENGLISH: If a quote is in a non-English language, expertly TRANSLATE it into beautiful, poetic English.
2. VAGUE/UNORIGINAL: If a quote is purely academic history, a rambling journal entry, vague, generic, or completely lacks a profound, poetic impact: return exactly "REJECT" for its text.
3. RAMBLING/FLUFF: If a quote has a brilliant core sentence buried in fluff, vigorously TRIM it down to JUST the profound sentence(s).
4. PERFECT: If a quote is already perfect, punchy, and profound: keep it exactly as written.
5. CATEGORIZE: You MUST pick the single best category for the quote from this exact list: {", ".join(CATEGORIES)}. If it does not strongly fit any of these 6 categories, return "REJECT" for its text.

RESPOND ONLY WITH VALID JSON.
Format your response exactly as a JSON object mapping the ID to a sub-object containing the edit and category.
Example:
{{
  "0": {{"text": "The trimmed, powerful quote...", "category": "Existential"}},
  "1": {{"text": "REJECT", "category": "REJECT"}},
  "2": {{"text": "The perfect quote as written.", "category": "Wit & Wisdom"}}
}}
"""

# ── Logic ──────────────────────────────────────────────────────────────

def get_fingerprint(text: str) -> str:
    """Create a unique fingerprint for a quote to detect duplicates. (First 50 alphanumeric chars)."""
    cleaned = re.sub(r'[^a-zA-Z0-9]', '', text.lower())
    return cleaned[:50]

def load_existing_fingerprints() -> set:
    """Load your current master library to prevent scraping identical quotes."""
    seen = set()
    try:
        # Check if running from root or within scripts/
        path = "assets/quotes.json" if os.path.exists("assets/quotes.json") else EXISTING_QUOTES_FILE
        with open(path, "r", encoding="utf-8") as f:
            data = json.load(f)
            for q in data:
                seen.add(get_fingerprint(q.get("text", "")))
        print(f"🛡️ Loaded {len(seen)} existing quotes into duplicate guard.")
    except Exception as e:
        print(f"⚠️ Could not load existing quotes for duplicate guard: {e}")
    return seen

def clean_text(raw: str) -> str:
    text = re.sub(r"\[\d+\]", "", raw)
    text = re.sub(r"\[edit\]", "", text, flags=re.IGNORECASE)
    text = re.sub(r"\s+", " ", text)
    return text.strip()

def scrape_author(author_name: str, seen_fingerprints: set) -> list[dict]:
    url = f"https://en.wikiquote.org/wiki/{quote(author_name.replace(' ', '_'))}"
    print(f"\n📖 Grabbing raw quotes from: {url}")

    session = requests.Session()
    retries = Retry(total=3, backoff_factor=1, status_forcelist=[429, 500, 502, 503, 504])
    session.mount("https://", HTTPAdapter(max_retries=retries))

    try:
        response = session.get(url, headers=HEADERS, timeout=15)
        response.raise_for_status()
    except Exception as e:
        print(f"❌ Network error: {e}")
        return []

    soup = BeautifulSoup(response.text, "html.parser")
    content_div = soup.find("div", {"id": "mw-content-text"})
    if not content_div:
        return []

    quotes = []
    current_section = "General"

    for element in content_div.find_all(['h2', 'h3', 'h4', 'li']):
        if element.name in ("h2", "h3", "h4"):
            current_section = clean_text(element.get_text(separator=" ", strip=True))
            continue

        if element.name == "li":
            parent = element.find_parent("ul")
            if parent and parent.find_parent("li"):
                continue # Skip citations sub-bullets

            el_copy = BeautifulSoup(str(element), "html.parser")
            source = "Unknown"
            sub_list = el_copy.find("ul")
            if sub_list:
                source_li = sub_list.find("li")
                if source_li:
                    source = clean_text(source_li.get_text(separator=" ", strip=True))
                sub_list.decompose()

            raw_text = clean_text(el_copy.get_text(separator=" ", strip=True))
            
            if len(raw_text) < 40 or JUNK_PATTERNS.search(raw_text):
                continue
                
            fingerprint = get_fingerprint(raw_text)
            if fingerprint in seen_fingerprints:
                continue # Duplicate Guard!
                
            seen_fingerprints.add(fingerprint) # Don't add duplicate in this run either
            
            quotes.append({
                "id": str(len(quotes)), # Temporary ID for batching
                "text": raw_text,
                "author": author_name,
                "source": source,
                "source_section": current_section
            })
                
    print(f"✅ Extracted {len(quotes)} totally new raw quotes for {author_name}.")
    return quotes

def process_batch(quotes_batch: list[dict]):
    prompt_text = "Refine the following quotes and return the JSON map:\n\n"
    for q in quotes_batch:
        prompt_text += f'ID: {q["id"]}\nText: {q["text"]}\n\n'

    payload = {
        "contents": [{"parts": [{"text": SYSTEM_PROMPT + "\n\n" + prompt_text}]}],
        "generationConfig": {
            "temperature": 0.1,
            "response_mime_type": "application/json"
        }
    }

    try:
        response = requests.post(MODEL_URL, json=payload, timeout=90)
        if response.status_code == 200:
            result_text = response.json()['candidates'][0]['content']['parts'][0]['text']
            result_text = result_text.replace("```json", "").replace("```", "").strip()
            return json.loads(result_text)
        else:
            print(f"  ⚠️ Form Error: {response.text}")
    except Exception as e:
        print(f"  ⚠️ Error calling Gemini: {e}")
    return None

def refine_quotes(author_name: str, raw_quotes: list[dict]) -> list[dict]:
    final_quotes = []
    
    for i in range(0, len(raw_quotes), BATCH_SIZE):
        if len(final_quotes) >= TARGET_FINAL_QUOTES:
            print(f"  🎯 Hit our target of {TARGET_FINAL_QUOTES} profound quotes! Skipping the rest.")
            break
            
        batch = raw_quotes[i:i + BATCH_SIZE]
        print(f"  🧠 AI categorizing & editing batch {i // BATCH_SIZE + 1}...")
        results = process_batch(batch)
        
        if results:
            for q in batch:
                if len(final_quotes) >= TARGET_FINAL_QUOTES:
                    break
                    
                ai_data = results.get(q["id"], {})
                
                # Sometimes models return flat strings if they mess up, guard against it.
                if isinstance(ai_data, str):
                    continue
                    
                edit = ai_data.get("text", "").strip()
                cat = ai_data.get("category", "REJECT").strip()
                
                if edit.upper() == "REJECT" or cat == "REJECT" or not edit:
                    continue
                    
                if cat not in CATEGORIES:
                    continue # Rogue categorization fallback
                    
                q["text"] = edit
                q["category"] = cat
                # Let's keep source and source_section entirely untouched
                final_quotes.append(q)
                
        time.sleep(1) # Soft pause for API Limits
        
    return final_quotes

# ── Main Entry ─────────────────────────────────────────────────────────────────

def main():
    AUTHORS_TO_SCRAPE = [
        "Fyodor Dostoevsky",
        "Franz Kafka",
        "Charles Bukowski",
        "Sigmund Freud",
        "Michel de Montaigne",
        "George Eliot",
        "Ernest Hemingway"
    ]
    
    # 1. Load the Duplicate Guard
    global_seen_fingerprints = load_existing_fingerprints()
    
    all_final_quotes = []
    global_id_counter = 500000 # High ID to prevent clashes
    
    for author in AUTHORS_TO_SCRAPE:
        # 2. Scrape raw quotes (avoiding anything in duplicate guard)
        raw_quotes = scrape_author(author, global_seen_fingerprints)
        if not raw_quotes:
            continue
            
        # 3. Use AI to brutally filter, categorize, and hit exactly 100
        print(f"🤖 Passing {len(raw_quotes)} fresh quotes to Gemini AI Editor...")
        refined = refine_quotes(author, raw_quotes)
        print(f"🎯 Final keep rate for {author}: {len(refined)} highly profound, strictly categorized new quotes.\n")
        
        for idx, q in enumerate(refined):
            q["id"] = global_id_counter + idx
            del q["id"] # Let's remove the temporary string ID we used
            q["id"] = global_id_counter + idx # Re-assign as integer ID
            all_final_quotes.append(q)
            
        global_id_counter += 1000

    print(f"\n🎉 Finished! Processed {len(AUTHORS_TO_SCRAPE)} authors.")
    print(f"   Saved {len(all_final_quotes)} brilliant quotes total to {OUTPUT_FILE}.")
    
    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        json.dump(all_final_quotes, f, indent=2, ensure_ascii=False)

if __name__ == "__main__":
    main()
