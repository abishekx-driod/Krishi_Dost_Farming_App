import winsound

def beep_start():
    # frequency, duration(ms)
    winsound.Beep(1200, 150)   # high beep

def beep_end():
    winsound.Beep(800, 180)    # low beep
