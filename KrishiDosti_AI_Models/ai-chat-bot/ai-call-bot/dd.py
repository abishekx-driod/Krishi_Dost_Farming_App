import sounddevice as sd

def list_mics():
    print("\n=== Available Microphones ===")
    devices = sd.query_devices()

    for i, dev in enumerate(devices):
        print(f"{i}: {dev['name']} (channels: {dev['max_input_channels']})")

if __name__ == "__main__":
    list_mics()
