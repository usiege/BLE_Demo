
#if 0

#define BYTE unsigned char

#define DES_BLOCKSIZE_MASK		0x07

#define ENcrypt_SINGLE_DES			0x00
#define DEcrypt_SINGLE_DES			0x40
#define ENcrypt_TRIPLE_DES			0x20
#define DEcrypt_TRIPLE_DES			0x60

#define	ECB_Encrypt   0x01
#define	ECB_Decrypt   0x00

#define CBC_Encrypt   0x11
#define CBC_Decrypt   0x10

extern void des(BYTE *dat, BYTE *key1, BYTE mode);
extern void tri_des(BYTE *dat, BYTE *key1, BYTE *key2, BYTE mode);
extern void _DES(unsigned char* dataOut, unsigned char* srcData, unsigned char* keyBuff, unsigned char optionMode);

extern void single_DESMAC(unsigned char* dataIn, unsigned char* keyBuff, unsigned char* dataOut, unsigned short length, unsigned char* ICVBuff);
extern void Triple_DES(unsigned char* dataIn, unsigned char* keyBuff, unsigned char* dataOut, unsigned short length, unsigned char* ICVBuff, unsigned char mode);


unsigned short algMain(char *cDispInfo);
////2    8   2   6    8(11223344...88)  16
void generateHostCryptogram(unsigned char *resultBuf, unsigned char *sequence, unsigned char *cardChallenge, unsigned char *hostChallenge, unsigned char *sesKey);

/////3  8  8   16
void generateMac(unsigned char *resultBuf, unsigned char *MAC, unsigned char* macKey);

/////1   2   16  16
void generateSessionKey(unsigned char *sequenceBuf, unsigned char *sesKey, unsigned char *macKey);

#endif