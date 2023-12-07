from microbit import *
import radio
import music

radio.config(group=22, power=7)
radio.on()

SEUIL_AGITE = 2000
SEUIL_TRES_AGITE = 4000
DUREE_TRES_AGITE = 5000

ENDORMI = "endormi"
AGITE = "agite"
TRES_AGITE = "tres_agite"

etat_eveil = ENDORMI
quantite_lait = 0

while True:
    accelerometer_data = accelerometer.get_values()
    magnitude = (accelerometer_data[0]**2 + accelerometer_data[1]**2 + accelerometer_data[2]**2)**0.5

    if magnitude < SEUIL_AGITE:
        etat_eveil = ENDORMI
    elif magnitude < SEUIL_TRES_AGITE:
        etat_eveil = AGITE
    else:
        etat_eveil = TRES_AGITE

    radio.send(etat_eveil)

    if etat_eveil == ENDORMI:
        radio.send('endormi')
    elif etat_eveil == AGITE:
        radio.send('agite')
    elif etat_eveil == TRES_AGITE:
        radio.send('tres_agite')

    display.clear()

    message = radio.receive()
    if message:
        message_parts = message.split('|')
        if message_parts[0] == "dosage":
            quantite_lait = int(message_parts[2])
            display.show(quantite_lait)
            sleep(2000)
        elif message_parts[0] == "reset":
            quantite_lait = 0
            display.show("0")
            sleep(2000)
            

    sound_level = microphone.sound_level()
    if sound_level > 200:
        radio.send('cry')
        display.show(Image.SAD)
        music.play(music.ODE, wait=False, loop=True)
        sleep(2000)
        display.clear()
        music.stop()

    sleep(50)