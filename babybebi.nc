from microbit import *
import radio
import random
import music

#Can be used to filter the communication, only the ones with the same parameters will receive messages
radio.config(group=17, channel=2, address=0x11111111)
#default : channel=7 (0-83), address = 0x75626974, group = 0 (0-255)
radio.on()



global connexion_established
connexion_established = False
global connexion_key
connexion_key = None
key= "KEYWORD"
nonce_list = set()

#Possibilités de l'état d'éveil
global ENDORMI
ENDORMI = "endormi"
global AGITE
AGITE = "agite"
global TRES_AGITE
TRES_AGITE = "tres_agite"

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
        key_index = i % key_length
        #Letters encryption/decryption
        if char.isalpha():
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
    Envoie de données fournie en paramètres
    Cette fonction permet de construire, de chiffrer puis d'envoyer un paquet via l'interface radio du micro:bit

    :param (str) key:       Clé de chiffrement
           (str) type:      Type du paquet à envoyer
           (str) content:   Données à envoyer
	:return none
    """
    nonce = random.randint(10, 100000)
    while nonce in nonce_list:
        nonce = random.randint(10, 100000)
    nonce_list.add(nonce)
    content_= str(nonce)+':'+str(content)
    length = str(len(content_))
    message=str(type+'|'+length+ '|' + content_)
    
    radio.send(vigenere(message, key))
    display.scroll(vigenere(message,key))

#Decrypt and unpack the packet received and return the fields value
def unpack_data(encrypted_packet, key):
    """
    Déballe et déchiffre les paquets reçus via l'interface radio du micro:bit
    Cette fonction renvoit les différents champs du message passé en paramètre

    :param (str) encrypted_packet: Paquet reçu
           (str) key:              Clé de chiffrement
	:return (srt)type:             Type de paquet
            (int)lenght:           Longueur de la donnée en caractères
            (str) message:         Données reçues
    """
    if encrypted_packet:
        decrypted_packet=vigenere(encrypted_packet,key,True)
        parts = decrypted_packet.split('|')
        type = parts[0]
        length = parts[1]
        length= int(length)
        message = parts[2]
        return type,length,message
        
    else:
        return ""


#Unpack the packet, check the validity and return the type, length and content
def receive_packet(packet_received, key):
    """
    Traite les paquets reçue via l'interface radio du micro:bit
    Cette fonction permet de construire, de chiffrer puis d'envoyer un paquet via l'interface radio du micro:bit
    Si une erreur survient, les 3 champs sont retournés vides

    :param (str) packet_received: Paquet reçue
           (str) key:              Clé de chiffrement
	:return (srt)type:             Type de paquet
            (int)lenght:           Longueur de la donnée en caractère
            (str) message:         Données reçue
    """
    
    unpacked = unpack_data(packet_received, key)
    
   
    if unpacked:
        type=unpacked[0]
        
        length=int(unpacked[1])
        
        message=unpacked[2]
        
        nonce = message.split(':')[0]
        type_list=['0x01','0x02','0x03','0x04']
        if nonce in nonce_list and type in type_list and length== len(message):
            return ''
        else:
            nonce_list.add(nonce)
            return type,length,message
          
    else:    
        return ""
    
#Calculate the challenge response
def calculate_challenge_response(challenge):
    """
    Calcule la réponse au challenge initial de connection avec l'autre micro:bit

    :param (str) challenge:            Challenge reçu
	:return (srt)challenge_response:   Réponse au challenge
    """
    challenge = int(challenge)
    random.seed(challenge)
    challenge_prime = random.randint(0,255)
    challenge_prime = str(challenge_prime)
    return challenge_prime
    
def calculate_concatenation():
    """
    Réponse au challenge initial de connection avec l'autre micro:bit
    Si il y a une erreur, la valeur de retour est vide

    :param (str) key:                   Clé de chiffrement
	:return (srt) challenge_response:   Réponse au challenge"""
    
    encrypted_packet=radio.receive()
    message_recu=unpack_data(encrypted_packet, key)
    if message_recu[0]=="0x01":
        message=message_recu[2]
        challenge = message.split(':')[1]
        if calculate_challenge_response(challenge) != "" :
            connexion_key = key + calculate_challenge_response(challenge)
            connexion_established = True
        else:
            connexion_key = None
            connexion_established = False
        return connexion_key, connexion_established
        
    
#Ask for a new connection with a micro:bit of the same group
def establish_connexion(key):
    """
    Etablissement de la connexion avec l'autre micro:bit
    Si il y a une erreur, la valeur de retour est vide

    :param (str) key:                  Clé de chiffrement
	:return (srt)challenge_response:   Réponse au challenge
    """
    x=random.randint(1,1000)
    send_packet(key,'0x01',x )
    y=calculate_challenge_response(x)
    while True :
        message_recu=receive_packet(radio.receive(),key)
        type=message_recu[0]
        h=hashing(y)
        if type=='0x01':
            content=message_recu[2]
            challenge_recu=content.split(':')[1]
            if h==challenge_recu:
                return y
            else:
                return ''

def etat_agitation(connexion_key):
    etat_eveil = ENDORMI #État initial du nourrisson
    #Seuils pour déterminer l'état d'éveil du nourrisson
    SEUIL_AGITE = 2000
    SEUIL_TRES_AGITE = 4000
    while True:
        #Récupération des données de l'accéléromètre
        accelerometer_data = accelerometer.get_values()
        magnitude = (accelerometer_data[0]**2 + accelerometer_data[1]**2 + accelerometer_data[2]**2)**0.5

        #Surveillance de l'état d'éveil ou d'endormissement du nourrisson
        if magnitude < SEUIL_AGITE:
            etat_eveil = ENDORMI
        elif magnitude < SEUIL_TRES_AGITE:
            etat_eveil = AGITE
        else:
            etat_eveil = TRES_AGITE

        #Envoi de l'état d'éveil via radio
        send_packet(connexion_key,'0x02',etat_eveil)
    
        #Traitement en fonction de l'état d'éveil
        if etat_eveil == ENDORMI:
            send_packet(connexion_key,'0x02','endormi')
        elif etat_eveil == AGITE:
            send_packet(connexion_key,'0x02','agite')
        elif etat_eveil == TRES_AGITE:
            send_packet(connexion_key,'0x02','tres_agite')

        display.clear()

def quantite_de_lait():
    #Communication sur la quantité de lait ingurgitée
    while True:
        message_received=unpack_data(radio.receive(),connexion_key)
        message=message_received[2]
        type=message_received[0]
        content=message.split(':')[1]
        if type=='0x03':
            quantite_lait = int(content)
            display.show(quantite_lait)
            sleep(2000)
        sleep(50)

def fonctionnalite_sup(connexion_key):
    # Fonctionnalité supplémentaire : détection si le nourrisson
    while True:
        sound_level = microphone.sound_level()
        if sound_level > 100:
            send_packet(connexion_key,'0x04',sound_level)
            display.show(Image.SAD)
            music.play(music.ODE, wait=False, loop=True) #Joue une mélodie pour le calmer
            sleep(2000)
            display.clear()
            music.stop()
        sleep(50)

def main():
    
    while True:
        send_packet(key,'0x01',calculate_challenge_response(2))
        display.scroll('yes')
        set_volume(10)
        while connexion_established==False:
             calculate_concatenation()
        message_received = receive_packet(radio.receive(), key)
        if message_received:
            type = message_received[0]
            parts=message_received[2].split(':')
            challenge=parts[1]
            calculate_challenge_response(challenge) 
            if establish_connexion(key):
                if type=='0x02':
                    display.scroll("type 0X02")
                    etat_agitation(connexion_key)
                elif type=='0x03':
                    display.scroll("type 0X02")
                    quantite_de_lait()
                elif type =='0x04':
                    display.scroll('type 0X04')
                    fonctionnalite_sup(connexion_key)
main()