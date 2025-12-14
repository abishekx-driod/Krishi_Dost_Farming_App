from gtts import gTTS
import vlc
import time
import uuid
import os

def text_to_speech(text, filename=None, lang="en"):
    # create temporary filename if not provided
    if filename is None:
        filename = f"tts_{uuid.uuid4().hex}.mp3"

    # generate audio
    tts = gTTS(text=text, lang=lang)
    tts.save(filename)

    try:
        # Play using VLC
        player = vlc.MediaPlayer(filename)
        player.play()

        # Wait until audio finishes
        time.sleep(0.5)
        duration = 0
        while player.is_playing():
            time.sleep(0.1)
            duration += 0.1
            if duration > 60:
                break  # avoid infinite loop

    except Exception as e:
        print("❌ Audio Playback Error:", e)

    # delete after playback
    if os.path.exists(filename):
        os.remove(filename)
