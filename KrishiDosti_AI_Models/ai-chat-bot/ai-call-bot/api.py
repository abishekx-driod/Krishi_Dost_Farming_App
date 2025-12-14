from flask import Flask, request, jsonify, send_file
from SpeachtoText import speech_to_text
from ask_agri_ai import ask_agri_ai
import os

app = Flask(__name__)

TEMP_FOLDER = "temp_audio"
os.makedirs(TEMP_FOLDER, exist_ok=True)

# -------------------------------------------------------------------
# 🎤 1. SPEECH → TEXT  (MULTILANGUAGE)
# -------------------------------------------------------------------
@app.route("/stt", methods=["GET"])
def stt_api():
    lang = request.args.get("lang", "en")      # <-- Flutter sends ?lang=hi or ?lang=en

    stt_lang = "hi-IN" if lang == "hi" else "en-IN"

    print(f"\n🎙️ STT request - Listening in: {stt_lang}")

    text = speech_to_text(stt_lang)

    if not text:
        print("❌ STT failed")
        return jsonify({"text": "", "error": "Could not understand"}), 400

    print(f"📝 Recognized Text: {text}\n")
    return jsonify({"text": text})


# -------------------------------------------------------------------
# 🤖 2. TEXT CHAT BOT (MULTILANGUAGE AI)
# -------------------------------------------------------------------
@app.route("/chat", methods=["POST"])
def chat_api():
    data = request.json

    text = data.get("text", "")
    lang = data.get("lang", "en")   # <-- MUST come from Flutter

    if not text:
        return jsonify({"reply": "Please say something"}), 400

    print("\n======================")
    print(f"User says: {text}")
    print(f"Language mode received: {lang}")

    # Correct language routing
    ai_lang = "hindi" if lang == "hi" else "english"

    print(f"AI will reply in: {ai_lang}")

    # Call your AI function
    reply = ask_agri_ai(text, ai_lang)

    print(f"Bot reply: {reply}")
    print("======================\n")

    return jsonify({"reply": reply})


# -------------------------------------------------------------------
# 🔊 3. AUDIO SERVE (if needed)
# -------------------------------------------------------------------
@app.route("/audio/<filename>")
def serve_audio(filename):
    return send_file(f"{TEMP_FOLDER}/{filename}", as_attachment=True)


# -------------------------------------------------------------------
# 🚀 RUN SERVER
# -------------------------------------------------------------------
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8000)
