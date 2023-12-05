import random

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
def types(le_code):
    if le_code == "0*01":
        return "conection"
    elif le_code =="0*03":
        return " Etat d’éveil"
    else:
        return "INKONNU"
le_code=chiffre_en_nombre(vigenere('B*AC|AH|FEF:BACC','BABA','dechiffrer'))[0:4] #a la place de B*AC|AH|FEF:BACC doit etre le message reçu
long=chiffre_en_nombre(vigenere('B*AC|AH|FEF:BACC','BABA','dechiffrer'))[5:7]
nonce=chiffre_en_nombre(vigenere('B*AC|AH|FEF:BACC','BABA','dechiffrer'))[8:11]
seed=chiffre_en_nombre(vigenere('B*AC|AH|FEF:BACC','BABA','dechiffrer'))[12:]
#etape de verifier le type de code 
if types(le_code)=="conection":
    #etape de calculer le challenge'
    random.seed(seed)
    challenge_prime= random.random()
    #etape de calculer le hash
    h=hash(challenge_prime)
    #etape de calculer le nonce prime
    nonce_prime=random.randint(0,999)
    #chiffrer et envoyer
    le_message=vigenere(nombre_en_chiffre(le_code+'|'+ long +'|' + nonce +':'+ str(h)),'BABA','chiffrer')
    #radio.send(le_message)


