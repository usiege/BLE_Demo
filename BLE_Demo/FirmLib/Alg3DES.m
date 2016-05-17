// ALG3DES.cpp : Defines the entry point for the console application.


#include "string.h"
#include "Alg3DES.h"

//
void generateHostCryptogram(unsigned char *resultBuf, unsigned char *sequence, unsigned char *cardChallenge, unsigned char *hostChallenge, unsigned char *sesKey)
{
	unsigned char tempBuf[24];
	unsigned char padding[8] = {0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};
	unsigned char icv[8] = {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};
	unsigned char keyBuff[16]; //= {0x40, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49, 0x4A, 0x4B, 0x4C, 0x4D, 0x4E, 0x4F};
    printf("/////////////////////\n");
    for (int i=0; i<8; i++) {
        printf("%02x",resultBuf[i]);
    }
    
    printf("\n");
    for (int i=0; i<2; i++) {
        printf("%02x",sequence[i]);
    }
    printf("\n");
    for (int i=0; i<6; i++) {
        printf("%02x",cardChallenge[i]);
    }
    printf("\n");
    for (int i=0; i<8; i++) {
        printf("%02x",hostChallenge[i]);
    }
    printf("\n");
    for (int i=0; i<16; i++) {
        printf("%02x",sesKey[i]);
    }
    
	memcpy(tempBuf, sequence, 2);
	memcpy(&tempBuf[2], cardChallenge, 6);
	memcpy(&tempBuf[8], hostChallenge, 8);
	memcpy(&tempBuf[16], padding, 8);
	memcpy(keyBuff, sesKey, 16);

	Triple_DES(tempBuf, keyBuff, tempBuf, 24, icv, CBC_Encrypt);

	memcpy(resultBuf, icv, 8);

}

//
void generateMac(unsigned char *resultBuf, unsigned char *MAC, unsigned char* macKey)
{
	unsigned char inData[16] = {0x84, 0x82, 0x00, 0x00, 0x10};
	unsigned char keyBuff[16];// = {0x40, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49, 0x4A, 0x4B, 0x4C, 0x4D, 0x4E, 0x4F};
	unsigned char icv[8] = {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};
	unsigned char dataOut[8];

	memcpy(keyBuff, macKey, 16);
	memcpy(&inData[5], resultBuf, 8);
	inData[13] = 0x80;
	inData[14] = 0x00;
	inData[15] = 0x00;
    printf("/////////111111/////\n");
    for (int i=0; i<8; i++) {
        printf("%02x",resultBuf[i]);
    }
     printf("\n");
    for (int i=0; i<16; i++) {
        printf("%02x",keyBuff[i]);
    }
    printf("\n");
    for (int i=0; i<16; i++) {
        printf("%02x",inData[i]);
    }
	single_DESMAC(inData, keyBuff, dataOut, 8, icv);
    printf("\n");
    for (int i=0; i<8; i++) {
        printf("%02x",icv[i]);
    }
	Triple_DES(inData + 8, keyBuff, dataOut, 8, icv, CBC_Encrypt);
    printf("\n");
    for (int i=0; i<8; i++) {
        printf("%02x",icv[i]);
    }
	memcpy(MAC, icv, 8);

}

//
void generateSessionKey(unsigned char *sequenceBuf, unsigned char *sesKey, unsigned char *macKey)
{
	  unsigned char staticKey[16] = {0x40, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49, 0x4A, 0x4B, 0x4C, 0x4D, 0x4E, 0x4F};
	  unsigned char icv[8] = {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};
	  unsigned char derivationData[16] = {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};

	  //memset(icv, 0, 8);
	  //memset(derivationData, 0, 16);
	  derivationData[0] = 0x01;
	  derivationData[1] = 0x82;
	  memcpy(&derivationData[2], sequenceBuf, 2);
	  Triple_DES(derivationData, staticKey, sesKey, 16, icv, CBC_Encrypt);

	  memset(icv, 0, 8);
	  memset(derivationData, 0, 16);
	  derivationData[0] = 0x01;
	  derivationData[1] = 0x01;
	  memcpy(&derivationData[2], sequenceBuf, 2);

	  Triple_DES(derivationData, staticKey, macKey, 16, icv, CBC_Encrypt);
    
    for (int i=0; i<16; i++) {
        printf("%02x",sesKey[i]);
    }
    printf("\n");
    for (int i=0; i<16; i++) {
        printf("%02x",macKey[i]);
    }

}



//
void single_DESMAC(unsigned char* dataIn, unsigned char* keyBuff, unsigned char* dataOut, unsigned short length, unsigned char* ICVBuff)
{
	unsigned char srcData[8], destData[8], blockNum, i, j;
 
	// length not multiple of DES_BlOCKSIZE or length is zero.
	if (((length & DES_BLOCKSIZE_MASK) != 0x00) || (length == 0x00))
	{
		return;
	}

	blockNum = length >> 3;
	
	for(i = 0; i < blockNum; i++)
	{
		memcpy(srcData, &dataIn[i * 8], 8);
		for(j = 0; j < 0x08; j++)
		{
			srcData[j] ^= ICVBuff[j];
		}
	
		//8bytes data single encrypt
		//_DES(&dataOut[i * 8], srcData, keyBuff, ENcrypt_SINGLE_DES);
		_DES(destData, srcData, keyBuff, ENcrypt_SINGLE_DES);
	
		// update ICVBuff
		//memcpy(ICVBuff, &dataOut[i * 8], 8);	
		memcpy(dataOut, destData, 8);			
		memcpy(ICVBuff, destData, 8);	
	
	}
}


//
void Triple_DES(unsigned char* dataIn, unsigned char* keyBuff, unsigned char* dataOut, unsigned short length, unsigned char* ICVBuff, unsigned char mode)
{
	unsigned char blockNum, srcData[8], i, optionMode = 0, j;
	
	// length not multiple of DES_BlOCKSIZE or length is zero.
	if (((length & DES_BLOCKSIZE_MASK) != 0x00) || (length == 0x00))
	{
		return;
	}
	
	blockNum = length >> 3;
	
	optionMode = (mode & 0x01)?ENcrypt_TRIPLE_DES : DEcrypt_TRIPLE_DES; //1:encrypt 0:decrypt

	for(i = 0; i < blockNum; i++)
	{
		memcpy(srcData, &dataIn[i * 8], 8);
		
		for(j = 0; j < 0x08; j++)
		{
			if(mode == CBC_Encrypt)
			{
				srcData[j] ^= ICVBuff[j];
			}
			else
			{
				//∆‰À˚ƒ£ Ω≤ª–Ë“™“ÏªÚ
				break;
			}
		}
		
		_DES(&dataOut[i * 8], srcData, keyBuff, optionMode);
		
		for(j = 0; j < 0x08; j++)
		{
			if(mode == CBC_Decrypt)
			{
				dataOut[i * 8 + j] ^= ICVBuff[j];
				// ‰»Îµƒº”√‹ ˝æ›«∞∞À◊÷Ω⁄◊˜Œ™œ¬“ª∏ˆ≥ı ºœÚ¡ø
				ICVBuff[j] = srcData[j];
			}
			else
			{
				//∆‰À˚ƒ£ Ω≤ª–Ë“™“ÏªÚ
				break;
			}
		}
			
		// fetch the updated ICV
		//CBCº”√‹≥ı º¡¥øÈ «…œ¥Œº”√‹µƒΩ·π˚
		if(mode != CBC_Decrypt)
		{
			memcpy(ICVBuff, &dataOut[i * 8], 8);
		}
	
	}

}

void _DES(unsigned char* dataOut, unsigned char* srcData, unsigned char* keyBuff, unsigned char optionMode)
{

	if(optionMode == ENcrypt_SINGLE_DES)
	{
		des(srcData, keyBuff, 0);	//µ•DESº”√‹
	}
	else if(optionMode == DEcrypt_SINGLE_DES)
	{
	
	}
	else if(optionMode == ENcrypt_TRIPLE_DES)
	{
		tri_des(srcData, keyBuff, keyBuff + 8, 0);	//3DESº”√‹
	}
	else if(optionMode == DEcrypt_TRIPLE_DES)
	{
	
	}
	
	memcpy(dataOut, srcData, 8);

}


