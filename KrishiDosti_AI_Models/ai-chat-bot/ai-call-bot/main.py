from SpeachtoText import speech_to_text
from TexttoSpeach import text_to_speech
from ask_agri_ai import ask_agri_ai

# Supported languages
LANGUAGES = {
    "english": ("English", "en-IN", "en", "english"),
    "hindi":   ("Hindi",   "hi-IN", "hi", "hindi"),
}

INTRO_MESSAGES = {
    "en": "Hey! I am AgroBot, your agriculture assistant. How can I help you today?",
    "hi": "नमस्ते! मैं एग्रोबोट हूँ। आपकी खेती में कैसे मदद कर सकता हूँ?",
}

# Auto end words
EXIT_PHRASES = [
    "bye", "thank you", "thanks", "stop", "exit", "quit", "that's all",
    "धन्यवाद", "धन्यबाद", "बस", "ठीक है", "ठीक है धन्यवाद", "बंद करो", "अलविदा", "रुक जाओ", "समाप्त"
]


def main():

    # ---- Ask for language ----
    ask_msg = "Please tell me your language: English or Hindi."
    print("\n🤖:", ask_msg)
    text_to_speech(ask_msg, "asklang.mp3", "en")

    print("\n🎙️ Listening for language...")
    detected = speech_to_text("en-IN")

    if not detected:
        print("❌ Could not understand language.")
        return

    detected = detected.lower()
    print("🧑 You said:", detected)

    selected = None
    for key in LANGUAGES:
        if key in detected:
            selected = LANGUAGES[key]
            break

    if not selected:
        print("❌ Language not recognized. Say English or Hindi.")
        return

    lang_name, stt_lang, tts_lang, ai_lang = selected

    print(f"\n✅ Selected language: {lang_name}")

    # ---- Intro ----
    intro = INTRO_MESSAGES[tts_lang]
    print("🤖:", intro)
    text_to_speech(intro, "intro.mp3", tts_lang)

    # ---- Conversation Loop ----
    while True:
        print("\n🎙️ Speak now...")
        user = speech_to_text(stt_lang)

        if not user:
            print("❌ Could not understand.")
            continue

        print("🧑 You said:", user)

        # ---- Auto Exit Detection ----
        for phrase in EXIT_PHRASES:
            if phrase in user.lower():
                goodbye = {
                    "english": "Thank you for using AgroBot. Have a great day!",
                    "hindi": "धन्यवाद! एग्रोबोट का उपयोग करने के लिए आपका धन्यवाद। आपका दिन शुभ हो!"
                }.get(ai_lang, "Goodbye!")

                print("🤖:", goodbye)
                text_to_speech(goodbye, None, tts_lang)
                return

        # ---- AI Reply ----
        reply = ask_agri_ai(user, ai_lang)
        print("🌾 AgroBot:", reply)

        text_to_speech(reply, None, tts_lang)


if __name__ == "__main__":
    main()
