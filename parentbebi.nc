from microbit import *
import radio
import random
import music

#Can be used to filter the communication, only the ones with the same parameters will receive messages
#radio.config(group=17, channel=2, address=0x11111111)
#default : channel=7 (0-83), address = 0x75626974, group = 0 (0-255)
radio.on()

#Initialisation des variables du micro:bit

global connexion_established
connexion_established = False
key = "KEYWORD"
global connexion_key
connexion_key = None 
nonce_list = set()

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
    Envoie de données fournie en paramètres
    Cette fonction permet de construire, de chiffrer puis d'envoyer un paquet via l'interface radio du micro:bit

    :param (str) key:       Clé de chiffrement
           (str) type:      Type du paquet à envoyer
           (str) content:   Données à envoyer
	:return none
    """
    nonce = random.randrange(10, 100000)
    while nonce in nonce_list:
        nonce = random.randint(10, 100000)
    nonce_list.add(nonce)
    content= str(nonce)+':'+str(content)
    length = len(content)
    message=str(type+'|'+length+ '|' + content)
    radio.send(vigenere(message, key))
    
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
    
    unpacked = unpack_data(packet_received, key)
    
    type_list=['0x01','0x02','0x03','0x04']
    if unpacked:
        type=unpacked[0]
        
        length=int(unpacked[1])
        
        message=unpacked[2]
        
        nonce = message.split(':')[0]
        
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
    Calcule la réponse au challenge initial de connection envoyé par l'autre micro:bit

    :param (str) challenge:            Challenge reçu
	:return (srt)challenge_response:   Réponse au challenge
    """
    challenge = int(challenge)
    random.seed(challenge)
    challenge_prime = random.randint(0,255)
    challenge_prime = str(challenge_prime)
    return challenge_prime
     

#Respond to a connexion request by sending the hash value of the number received
def respond_to_connexion_request(key):
    """
    Réponse au challenge initial de connection avec l'autre micro:bit
    Si il y a une erreur, la valeur de retour est vide

    :param (str) key:                   Clé de chiffrement
	:return (srt) challenge_response:   Réponse au challenge
    """
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



def etat_agitation(connexion_key):
    while True:
        #Possibilités de l'état du nourrisson
        ENDORMI = "endormi"
        AGITE = "agite"
        TRES_AGITE = "tres_agite"
        message_received = unpack_data(radio.receive(),connexion_key) 
        parts=message_received[2]
        if message_received[0]=='0x02':
            content=parts.split(':')[1]
           #Surveillance de l'état de veille ou d'endormissement du nourrisson
            if content == ENDORMI:
                display.show(Image.HAPPY)
            elif content == AGITE:
                display.show(Image.SAD)
                #Joue une mélodie pour indiquer un bébé agité
                music.play(music.BIRTHDAY,wait=False,loop=True)
                sleep(2000)
                music.stop()
            elif content == TRES_AGITE:
                display.show(Image.ANGRY)
                #Joue une mélodie différente pour un bébé très agité
                music.play(music.WAWAWAWAA,wait=False,loop=True)
                sleep(2000)
                music.stop()
        sleep(50)

def quantite_lait(connexion_key):
   #Communication sur la quantité de lait ingurgitée
    quantite_lait = 0  #Initialisation du compteur de dose de lait
    while True:
        if button_a.was_pressed():
            quantite_lait += 1
            #Envoie un message avec la quantité de lait
            send_packet(connexion_key,'0x03',quantite_lait)
            display.show(quantite_lait)
        
        #Réinitialise la quantité de lait à 0 si le logo est touché
        if pin_logo.is_touched():
            quantite_lait = 0
            send_packet(connexion_key,'0x03',quantite_lait)
            display.show("0")
        
        # Enlève -1 quantité de lait si le bouton B est pressé    
        if button_b.was_pressed():
            quantite_lait -= 1
            send_packet(connexion_key,'0x03',quantite_lait)
            display.show(quantite_lait)
        sleep(50)

def fonctionnalite_sup(connexion_key):
    message_received=unpack_data(radio.receive(),connexion_key)
    type= message_received[0]
    while True:
         if type=='0x04':
            display.show(Image.SAD)
            music.play(music.WAWAWAWAA, wait=False, loop=True)
            sleep(2000)
            music.stop()
         sleep(50)
      
def main():
    radio.config(group=17, channel=2, address=0x11111111)
    sleep(1000)
    
    while True:
        set_volume(10)
        while True:
            message_received = receive_packet(radio.receive(), key)
            
            if message_received:
                type = message_received[0]
                respond_to_connexion_request(key)
                
                if type=='0x02':
                    etat_agitation(connexion_key)
                elif type=='0x03':
                    quantite_lait(connexion_key)
                elif type =='0x04':
                    fonctionnalite_sup(connexion_key)
                
                    
                
main()