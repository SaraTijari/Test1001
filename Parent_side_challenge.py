from microbit import *
import radio
import random
import music

#Can be used to filter the communication, only the ones with the same parameters will receive messages
#radio.config(group=23, channel=2, address=0x11111111)
#default : channel=7 (0-83), address = 0x75626974, group = 0 (0-255)

#Initialisation des variables du micro:bit
radio.on()
connexion_established = False
key = "LARDON"
connexion_key = None
nonce_list = set()
baby_state = 0
set_volume(100)


def hashing(string):
	"""
	Hachage d'une chaîne de caractères fournie en paramètre.
	Le résultat est une chaîne de caractères.
	Attention : cette technique de hachage n'est pas suffisante (hachage dit cryptographique) pour une utilisation en dehors du cours.

	:param (str) string: la chaîne de caractères à hacher
	:return (str): le résultat du hachage
	"""
	def to_32(value):
		"""
		Fonction interne utilisée par hashing.
		Convertit une valeur en un entier signé de 32 bits.
		Si 'value' est un entier plus grand que 2 ** 31, il sera tronqué.

		:param (int) value: valeur du caractère transformé par la valeur de hachage de cette itération
		:return (int): entier signé de 32 bits représentant 'value'
		"""
		value = value % (2 ** 32)
		if value >= 2**31:
			value = value - 2 ** 32
		value = int(value)
		return value

	if string:
		x = ord(string[0]) << 7
		m = 1000003
		for c in string:
			x = to_32((x*m) ^ ord(c))
		x ^= len(string)
		if x == -1:
			x = -2
		return str(x)
	return ""
    
def vigenere(message, key, decryption=False):
    text = ""
    key_length = len(key)
    key_as_int = [ord(k) for k in key]

    for i, char in enumerate(str(message)):
        #Letters encryption/decryption
        if char.isalpha():
            key_index = i % key_length
            if decryption:
                modified_char = chr((ord(char.upper()) - key_as_int[key_index] + 26) % 26 + ord('A'))
            else : 
                modified_char = chr((ord(char.upper()) + key_as_int[key_index] - 26) % 26 + ord('A'))
            #Put back in lower case if it was
            if char.islower():
                modified_char = modified_char.lower()
            text += modified_char
        #Digits encryption/decryption
        elif char.isdigit():
            key_index = i % key_length
            if decryption:
                modified_char = str((int(char) - key_as_int[key_index]) % 10)
            else:  
                modified_char = str((int(char) + key_as_int[key_index]) % 10)
            text += modified_char
        else:
            text += char
    return text
    
def send_packet(key, type, content):
    """
    Envoi de données fournies en paramètres
    Cette fonction permet de construire, de chiffrer puis d'envoyer un paquet via l'interface radio du micro:bit

    :param (str) key:       Clé de chiffrement
           (str) type:      Type du paquet à envoyer
           (str) content:   Données à envoyer
	:return none
    """
    nonce=random.randint(0,1000)
    length=len(str(nonce))+len(content)+1
    message=(str(type)+'|'+str(length)+'|'+str(nonce)+':'+str(content))
    radio.send(vigenere(message,key,decryption=False))
    
    
    

#Unpack the packet, check the validity and return the type, length and content
def unpack_data(encrypted_packet, key):
    """
    Déballe et déchiffre les paquets reçus via l'interface radio du micro:bit
    Cette fonction renvoit les différents champs du message passé en paramètre

    :param (str) encrypted_packet: Paquet reçu
           (str) key:              Clé de chiffrement
	:return (srt)type:             Type de paquet
            (int)length:           Longueur de la donnée en caractères
            (str) message:         Données reçue
    """
    decrypted_packet = vigenere(encrypted_packet, key, decryption=True)
    champs = decrypted_packet.split('|')
    type = champs[0]
    length = champs[1]
    message = champs[2]
    return str(type),int(length),str(message)
    
    

    

def receive_packet(packet_received, key):
    """
    Traite les paquets reçus via l'interface radio du micro:bit
    Cette fonction utilise la fonction unpack_data pour renvoyer les différents champs du message passé en paramètre
    Si une erreur survient, les 3 champs sont retournés vides

    :param (str) packet_received: Paquet reçue
           (str) key:              Clé de chiffrement
	:return (srt)type:             Type de paquet
            (int)lenght:           Longueur de la donnée en caractère
            (str) message:         Données reçue
    """
    
    
    message_received=unpack_data(packet_received, key)
    print(message_received)
    type,length,message=message_received
    msg = message.split(':')
    print(msg)
    
    nonce=msg[0]
    if nonce in nonce_list:
        return None, None, None
    else:
        nonce_list.add(nonce)
        return type,length,msg[1]
    
    
#Calculate the challenge response
def calculate_challenge_response(challenge):
    """
    Calcule la réponse au challenge initial de connection envoyé par l'autre micro:bit

    :param (str) challenge:            Challenge reçu
	:return (srt)challenge_response:   Réponse au challenge
    """
    
    random.seed(int(challenge))
    response_chal = random.random()
    return response_chal

#Respond to a connexion request by sending the hash value of the number received
def respond_to_connexion_request(key):
    """
    Réponse au challenge initial de connection avec l'autre micro:bit
    Si il y a une erreur, la valeur de retour est vide

    :param (str) key:                   Clé de chiffrement
	:return (srt) challenge_response:   Réponse au challenge
    """
    send_packet(key, 0x01,hashing(str(calculate_challenge_response(challenge))))
    
def main():
    type = 0
    lait=0
    
    radio.config(group=42, power=7)
    
    sleep(1000)
    audio.play(Sound.HAPPY, wait=False)
    audio.play(Sound.GIGGLE, wait=False)
    display.scroll('PARENT', delay=75)
    sleep(1000)
    display.scroll('A = SLEEP   B = TEMPERATURE   PIN LOGO = MILK    ', delay=25)		#interface
    
    while True:
        
        key = "LARDON"
        type = 0
        music.set_tempo(bpm=45)
        music.pitch(440)
        set_volume(10)
        music.play(music.PRELUDE, wait=False)
            
        while True:
            
            packet_received = radio.receive()
            
            if packet_received:
                type,length,message = receive_packet(packet_received, key)
                display.scroll(str(type), delay=75)
                break
            
            elif accelerometer.is_gesture('shake'):	#reset interface
                display.scroll('A = SLEEP   B = TEMPERATURE   PIN LOGO = MILK    ', delay=100)		#interface
                break
            
            elif pin_logo.is_touched():		#milk condition
                music.play(music.POWER_UP, wait=False)
                display.scroll('MILK', delay=100)
                
                
                while True: 
                    
                    if button_a.was_pressed():		#gave 1 dozen of milk 
                        lait+=1 
                    
                    if button_b.was_pressed():		#supress 1 dozen of milk 
                        lait-=1 
                    
                    if button_b.is_pressed() and button_a.is_pressed():		#reset milk
                        lait = 0
                    
                    if pin_logo.is_touched():		#exit milk condition
                        music.play(music.POWER_DOWN, wait=False)
                        display.show(Image.HAPPY)
                        sleep(2750)
                        display.clear()
                        break
			    
                    send_packet(key, 0x04, str(lait))
                    display.scroll(str(lait), delay=100)		#show dozen of milk
            
            elif button_a.was_pressed():		#sleep condition
                music.play(music.POWER_UP, wait=False)
                display.scroll('SLEEP', delay=75)
                send_packet(key, "0x02", "none")
                
            
            if button_b.was_pressed():		#temperature condition
                music.play(music.POWER_UP, wait=False)
                display.scroll('TEMPERATURE', delay=75)
                send_packet(key, "0x03", "none")
                
               

                    
                            
                    
        
        if type == "0x01" :				#connexion
            respond_to_connexion_request(key,message)
            
        if type == "0x02" : 				#temperature
            
            display.scroll(message)
            
            if int(message) > 16 and int(message) < 25:
                display.scroll('TEMPERATURE is good for the baby.', delay=100)
                
            if int(message) < 16 :
                display.scroll('TEMPERATURE is too cold for the baby.', delay=100)
                
            if int(message) > 25:
                display.scroll('Temperature is too hot for the baby.', delay=100)
                
        if type == "0x03" :										#sleep state
            if message == "0":
                display.scroll('The baby is sleeping peacefully', delay=100)
            if message == "1":
                display.scroll('The baby is lightly agitated', delay=100)
            if message == "2":
                display.scroll('the  baby is severelly agitated', delay=100)   
        
                
        if type == "0x05":                                      #changing key      
            key+=str(calculate_challenge_response(challenge))




main()