import random
#fonction pour transformer les nombres en alphabet pour qu'on puisse les chiffrer 
def nombre_en_chiffre(nombre):
    lettres=""
    alphabet='ABCDEFGHIJ'
    for chiffre in str(nombre):
        if chiffre =='|'or chiffre=='*'or chiffre==':':
            lettres+=chiffre
        else:
            chiffre=int(chiffre)
            lettres+=alphabet[chiffre]
    return lettres
def chiffre_en_nombre(chiffre):
    num=''
    alphabet='ABCDEFGHIJ'
    for i in chiffre:
        a=alphabet.find(i.upper())
        if a!=-1:
            num +=str(a)
        else:
            num+=i
    return num
#le chiffrement de vigenere
def vigenere(text,key,mode):
    letters='ABCDEFGHIJ'
    translat=[]
    keyindex=0
    key=key.upper()
    for i in text:
        num=letters.find(i.upper())
        if num!=-1:
            if mode=='chiffrer':
                num+=letters.find(key[keyindex])
            elif mode=='dechiffrer':
                num-=letters.find(key[keyindex])
            num%=len(letters)
            if i.isupper():
                translat.append(letters[num])
            elif i.islower():
                translat.append(letters[num].lower())
            keyindex+=1
            if keyindex==len(key):
                keyindex=0
        else:
            translat.append(i)
    return ''.join(translat)
#send the encrypted message
#radio.send(vigenere(nombre_en_chiffre('0*01|06|535:0012'),'BABA','chiffrer'))
#recevoire le message envoye de bebe parent 
#le_message=radio.recieve()
#definir les variables
le_message_dechiffre=chiffre_en_nombre(vigenere('B*AC|AH|FEF:CBCFFGJIFBHDEGDHEJD','BABA','dechiffrer'))#au lieu de B*AC|AH|FEF:BACC ecrire le_message
h=le_message_dechiffre[12:]
seed ='0012'
random.seed(seed)
if h == str(hash(random.random())):
    #la partie de concatination que je ne comprends pas exactement comment
    #A continuer













