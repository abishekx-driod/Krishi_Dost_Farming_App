import speech_recognition as sr

MIC_DEVICE_ID = None   # auto-select

def speech_to_text(language="en-IN"):
    recognizer = sr.Recognizer()

    recognizer.energy_threshold = 300
    recognizer.pause_threshold = 1.0

    with sr.Microphone(device_index=MIC_DEVICE_ID) as source:
        print("🎤 Listening...")
        recognizer.adjust_for_ambient_noise(source, duration=1)

        try:
            audio = recognizer.listen(source, timeout=8, phrase_time_limit=10)
        except sr.WaitTimeoutError:
            print("⏳ No speech detected.")
            return None

    try:
        print("⏳ Recognizing...")
        return recognizer.recognize_google(audio, language=language)

    except sr.UnknownValueError:
        print("❌ Could not understand.")
        return None
    except Exception as e:
        print("❌ STT Error:", e)
        return None
