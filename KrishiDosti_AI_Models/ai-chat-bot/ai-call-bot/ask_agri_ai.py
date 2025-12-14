import ollama
import re

# ======================================================
# LANGUAGE DETECTION HELPERS
# ======================================================

def contains_hindi(text):
    return any('\u0900' <= c <= '\u097F' for c in text)

def contains_english(text):
    return re.search(r"[A-Za-z]", text) is not None


# ======================================================
# HARD LANGUAGE ENFORCEMENT  (No mixing allowed)
# ======================================================

def enforce_language(reply, lang):

    if lang == "english":
        # If contains Hindi → block
        if contains_hindi(reply):
            return "I will reply only in English. Please ask again in English."
        return reply

    if lang == "hindi":
        # If contains English A–Z → block
        if contains_english(reply):
            return "मैं केवल हिंदी में उत्तर दूँगा। कृपया हिंदी में पूछें।"
        return reply

    return reply


# ======================================================
# MAIN AI FUNCTION
# ======================================================

def ask_agri_ai(prompt, lang):

    # Normalize language
    lang = lang.lower().strip()

    if lang in ["hi", "hindi"]:
        target_lang = "hindi"
    else:
        target_lang = "english"

    SYSTEM = f"""
You are AgroBot, India's agriculture advisor.

### LANGUAGE RULES:
- Reply ONLY in **{target_lang}**.
- STRICT NO-MIXING rule applies.
- Do NOT translate unless asked.
- Keep responses short, simple, and useful for Indian farmers.
- Avoid complex scientific terms unless needed.
- If user mixes languages, reply only in the selected language.

### EXAMPLES
English:
User: best crop for clay soil
Bot: Clay soil is good for cotton, wheat, and rice.

Hindi:
User: काली मिट्टी में कौनसी फसल अच्छी है?
Bot: काली मिट्टी में कपास, ज्वार और गेहूं अच्छी होती हैं।
"""

    response = ollama.chat(
        model="llama3.2:3b",
        messages=[
            {"role": "system", "content": SYSTEM},
            {"role": "user", "content": prompt}
        ]
    )

    raw = response["message"]["content"]

    # Hard enforce language
    final = enforce_language(raw, target_lang)

    return final
