import os, json, requests
from dotenv import load_dotenv, find_dotenv
load_dotenv(find_dotenv(usecwd=True))

api_key = os.getenv("GEMINI_API_KEY")
url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key={api_key}"

with open("quotesy_final.json", encoding="utf-8") as f:
    q = json.load(f)
sorted_q = sorted(q, key=lambda x: len(x['text']), reverse=True)
quote = sorted_q[1]['text']

prompt = f"""
You are a ruthless, brilliant literary editor. I will give you a quote. 
If it is non-English, boring, purely academic, or completely unpoetic, reply with strictly the word: REJECT
If it is long and rambling but has a profound, punchy, or poetic core sentence or two, trim it down to JUST the profound part. Remove all fluff.
If it is already perfect, return it exactly. 

Here is the quote:
{quote}
"""

payload = {
    "contents": [{"parts": [{"text": prompt}]}],
    "generationConfig": {"temperature": 0.2}
}

try:
    r = requests.post(url, json=payload, timeout=10)
    print(f"\n--- BEFORE ({len(quote.split())} words) ---")
    print(quote)
    print("\n--- AI TRIMMED OUTPUT ---")
    print(r.json()['candidates'][0]['content']['parts'][0]['text'].strip())
    print("-------------------------\n")
except Exception as e:
    print(f"Error: {e}")
