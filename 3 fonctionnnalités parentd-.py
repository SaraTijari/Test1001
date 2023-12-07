from microbit import *
import radio
import music

radio.config(group=22, power=7)
radio.on()

ENDORMI = "endormi"
AGITE = "agite"
TRES_AGITE = "tres_agite"

quantite_lait = 0

while True:
    etat_eveil = radio.receive()

    if etat_eveil == ENDORMI:
        display.show(Image.HAPPY)
    elif etat_eveil == AGITE:
        display.show(Image.SAD)
    elif etat_eveil == TRES_AGITE:
        display.show(Image.ANGRY)

    if button_a.was_pressed():
        quantite_lait += 1
        message = "dosage|" + str(len(str(quantite_lait))) + "|" + str(quantite_lait)
        radio.send(message)
        display.show(quantite_lait)

    if pin_logo.is_touched():
        quantite_lait = 0
        message = "reset|1|0"
        radio.send(message)
        display.show("0")
        
    if button_b.was_pressed():
        quantite_lait -= 1
        message = "dosage|" + str(len(str(quantite_lait))) + "|" + str(quantite_lait)
        radio.send(message)
        display.show(quantite_lait)

    sound_level = microphone.sound_level()
    if sound_level > 200:
        radio.send('cry')
        display.show(Image.SAD)
        music.play(music.WAWAWAWAA, wait=False, loop=True)
        sleep(2000)
        display.clear()
        music.stop()

    sleep(50)