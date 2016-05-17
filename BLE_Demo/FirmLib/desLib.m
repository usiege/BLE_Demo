
//#include "stdafx.h"

#ifdef _DEBUG
#define new DEBUG_NEW
#undef THIS_FILE
static char THIS_FILE[] = __FILE__;
#endif


#define BYTE unsigned char

void doxor(BYTE *sourceaddr, BYTE *targetaddr, BYTE length);
void shrc(BYTE dat[7]);
void movram(BYTE *source, BYTE *target, BYTE length);
BYTE getbit(BYTE *dataddr, BYTE pos);
void shlc(BYTE *dat);
void strans(BYTE index[6], BYTE target[4]);
void setbit(BYTE* dataddr, BYTE pos, BYTE b0);
void selectbits(BYTE *source, BYTE *table, BYTE *target, BYTE count);
		BYTE IP[]={ 
					58, 50, 42, 34, 26, 18, 10, 2,
					60, 52, 44, 36, 28, 20, 12, 4,
					62, 54, 46, 38, 30, 22, 14, 6,
					64, 56, 48, 40, 32, 24, 16, 8,
					57, 49, 41, 33, 25, 17, 9,  1,
					59, 51, 43, 35, 27, 19, 11, 3,
					61, 53, 45, 37, 29, 21, 13, 5,
					63, 55, 47, 39, 31, 23, 15, 7
						};

		BYTE IP_1[]={
						40, 8,  48, 16, 56, 24, 64, 32,
						39, 7,  47, 15, 55, 23, 63, 31,
						38, 6,  46, 14, 54, 22, 62, 30,
						37, 5,  45, 13, 53, 21, 61, 29,
						36, 4,  44, 12, 52, 20, 60, 28,
						35, 3,  43, 11, 51, 19, 59, 27,
						34, 2,  42, 10, 50, 18, 58, 26,
						33, 1,  41, 9,  49, 17, 57, 25
						};

	BYTE  _S[8][4][16] = {
	{
		{14, 4, 13, 1, 2, 15, 11, 8, 3, 10, 6, 12, 5, 9, 0, 7},
		{0, 15, 7, 4, 14, 2, 13, 1, 10, 6, 12, 11, 9, 5, 3, 8},
		{4, 1, 14, 8, 13, 6, 2, 11, 15, 12, 9, 7, 3, 10, 5, 0},
		{15, 12, 8, 2, 4, 9, 1, 7, 5, 11, 3, 14, 10, 0, 6, 13}
	},
	{
		{15, 1, 8, 14, 6, 11, 3, 4, 9, 7, 2, 13, 12, 0, 5, 10},
		{3, 13, 4, 7, 15, 2, 8, 14, 12, 0, 1, 10, 6, 9, 11, 5},
		{0, 14, 7, 11, 10, 4, 13, 1, 5, 8, 12, 6, 9, 3, 2, 15},
		{13, 8, 10, 1, 3, 15, 4, 2, 11, 6, 7, 12, 0, 5, 14, 9}
	},
	{
		{10, 0, 9, 14, 6, 3, 15, 5, 1, 13, 12, 7, 11, 4, 2, 8},
		{13, 7, 0, 9, 3, 4, 6, 10, 2, 8, 5, 14, 12, 11, 15, 1},
		{13, 6, 4, 9, 8, 15, 3, 0, 11, 1, 2, 12, 5, 10, 14, 7},
		{1, 10, 13, 0, 6, 9, 8, 7, 4, 15, 14, 3, 11, 5, 2, 12}
	},
	{
		{7, 13, 14, 3, 0, 6, 9, 10, 1, 2, 8, 5, 11, 12, 4, 15},
		{13, 8, 11, 5, 6, 15, 0, 3, 4, 7, 2, 12, 1, 10, 14, 9},
		{10, 6, 9, 0, 12, 11, 7, 13, 15, 1, 3, 14, 5, 2, 8, 4},
		{3, 15, 0, 6, 10, 1, 13, 8, 9, 4, 5, 11, 12, 7, 2, 14}
	},
	{
		{2, 12, 4, 1, 7, 10, 11, 6, 8, 5, 3, 15, 13, 0, 14, 9},
		{14, 11, 2, 12, 4, 7, 13, 1, 5, 0, 15, 10, 3, 9, 8, 6},
		{4, 2, 1, 11, 10, 13, 7, 8, 15, 9, 12, 5, 6, 3, 0, 14},
		{11, 8, 12, 7, 1, 14, 2, 13, 6, 15, 0, 9, 10, 4, 5, 3}
	},
	{
		{12, 1, 10, 15, 9, 2, 6, 8, 0, 13, 3, 4, 14, 7, 5, 11},
		{10, 15, 4, 2, 7, 12, 9, 5, 6, 1, 13, 14, 0, 11, 3, 8},
		{9, 14, 15, 5, 2, 8, 12, 3, 7, 0, 4, 10, 1, 13, 11, 6},
		{4, 3, 2, 12, 9, 5, 15, 10, 11, 14, 1, 7, 6, 0, 8, 13}
	},
	{
		{4, 11, 2, 14, 15, 0, 8, 13, 3, 12, 9, 7, 5, 10, 6, 1},
		{13, 0, 11, 7, 4, 9, 1, 10, 14, 3, 5, 12, 2, 15, 8, 6},
		{1, 4, 11, 13, 12, 3, 7, 14, 10, 15, 6, 8, 0, 5, 9, 2},
		{6, 11, 13, 8, 1, 4, 10, 7, 9, 5, 0, 15, 14, 2, 3, 12}
	},
	{
		{13, 2, 8, 4, 6, 15, 11, 1, 10, 9, 3, 14, 5, 0, 12, 7},
		{1, 15, 13, 8, 10, 3, 7, 4, 12, 5, 6, 11, 0, 14, 9, 2},
		{7, 11, 4, 1, 9, 12, 14, 2, 0, 6, 10, 13, 15, 3, 5, 8},
		{2, 1, 14, 7, 4, 10, 8, 13, 15, 12, 9, 0, 3, 5, 6, 11}
	}
	};

	BYTE _E[] = {
					32, 1, 2, 3, 4, 5,
					4, 5, 6, 7, 8, 9,
					8, 9, 10, 11, 12,13,
					12, 13, 14, 15, 16, 17,
					16, 17, 18, 19, 20, 21,
					20, 21, 22, 23, 24, 25,
					24, 25, 26, 27, 28, 29,
					28, 29, 30, 31, 32, 1
						};

	BYTE P[] = {
					16, 7, 20, 21,
					29, 12, 28, 17,
					1, 15, 23, 26,
					5, 18, 31, 10,
					2, 8, 24,  14,
					32, 27, 3, 9,
					19, 13, 30, 6,
					22, 11, 4, 25
						};
	BYTE PC_1[]={
					57, 49, 41, 33, 25, 17, 9,
					1, 58, 50, 42, 34, 26, 18,
					10, 2, 59, 51, 43, 35, 27,
					19, 11, 3, 60, 52, 44, 36,
					63, 55, 47, 39, 31, 23, 15,
					7, 62, 54, 46, 38, 30, 22,
					14, 6, 61, 53, 45, 37, 29,
					21, 13, 5, 28, 20, 12, 4
						};

	BYTE PC_2[]={
					14, 17, 11, 24, 1, 5,
					3, 28, 15, 6, 21, 10,
					23, 19, 12, 4, 26, 8,
					16, 7, 27, 20, 13, 2,
					41, 52, 31, 37, 47, 55,
					30, 40, 51, 45, 33, 48,
					44, 49, 39, 56, 34, 53,
					46, 42, 50, 36, 29, 32
						};
	BYTE rots[]= {1, 1, 2, 2, 2, 2, 2, 2, 1, 2, 2, 2, 2, 2, 2, 1, 0};
		//BYTE rots[] = {1, 2, 4, 6, 8, 10, 12, 14, 15, 17, 19, 21, 23, 25, 27, 28};


void des(BYTE *dat, BYTE *key1, BYTE mode)
{
	BYTE tempbuf[12], key[7];
	BYTE i,j, count;
	void (* f)(BYTE * dat);
	selectbits(dat, IP, tempbuf, 64);	/* 初始变换 */
	movram(tempbuf, dat, 8);
	selectbits(key1, PC_1, key, 56);	/* KEY的初始变换 */
	for (i = 0; i < 16; i ++){
		selectbits(dat + 4, _E, tempbuf, 48);	/* 膨胀变换 */
		if(mode == 0){
			f = shlc;
			count = i;
		}
		else{
			count = 16 - i;	
			f = shrc;
		}
		for (j = 0; j < rots[count]; j ++)	/* KEY 的移位 */
			f(key);
		selectbits(key, PC_2, tempbuf + 6, 48);	/* KEY 压缩变换 */
		doxor(tempbuf, tempbuf + 6, 6);
		strans(tempbuf, tempbuf + 6);
		selectbits(tempbuf + 6, P, tempbuf, 32);
		doxor(tempbuf, dat, 4);
		if (i < 15){
		movram(dat + 4, dat, 4);
		movram(tempbuf, dat + 4, 4);
		}
	}
	movram(tempbuf, dat, 4);
	selectbits(dat, IP_1, tempbuf, 64);
	movram(tempbuf, dat, 8);
}

/* This function is right */
void selectbits(BYTE *source, BYTE *table, BYTE *target, BYTE count)
{
	BYTE i;
	for (i = 0; i < count; i ++)
		setbit(target, i + 1, getbit(source, table[i])); 
}

/* The problem is about yielded in this function */
void strans(BYTE *index, BYTE *target)
{
	BYTE row , line , t , i, j, b0, b1;
	for (i = 0; i < 4; i ++){
		row = line = t = 0;
		setbit(&line, 7, b0 = getbit(index, i * 12 + 1));
		setbit(&line, 8, b1 = getbit(index, i * 12 + 6));
		for (j = 2; j < 6; j ++){
			setbit(&row, 3 + j, getbit(index, i * 12 + j));
		}
		t = _S[i * 2][line][row];
		t <<= 4;
		line = row = 0; 
		setbit(&line, 7, getbit(index, i * 12 + 7));
		setbit(&line, 8, getbit(index, i * 12 + 12));
		for (j = 2; j < 6; j ++){
			setbit(&row, 3 + j, getbit(index, i * 12 + 6 + j));
		}
		t |= _S[i * 2 + 1][line][row];
		target[i] = t;
	}
}

/* This function is right */
void setbit(BYTE* dataddr, BYTE pos, BYTE b0)	
{
	BYTE byte_count, bit_count, temp = 1;
	byte_count = (pos - 1) / 8;
	bit_count = 7 - ((pos - 1) % 8);
	temp <<= bit_count;
	if (b0)
		dataddr[byte_count] |= temp;
	else{
		temp = ~temp;
		dataddr[byte_count] &= temp;
	}
}

/* This function is right */
BYTE getbit(BYTE *dataddr, BYTE pos)	
{
	BYTE byte_count, bit_count, temp = 1;
	byte_count = (pos - 1) / 8;
	bit_count = 7 - ((pos - 1) % 8);
	temp <<= bit_count;
	if (dataddr[byte_count] & temp)
		return 1;
	else 
		return 0;
}

/* This function is right */
void movram(BYTE *source, BYTE *target, BYTE length)	/* this function is right */
{
    BYTE i;
	for(i = 0;i < length;i ++)	/*移动数据块*/
	    target[i] = source[i];
}

/* This function is right */
void doxor(BYTE *sourceaddr, BYTE *targetaddr, BYTE length)	/* This function is right */
{
	BYTE i;
	for (i = 0; i < length; i ++)	/* 求异或 */
		sourceaddr[i] ^= targetaddr[i];
}

/* This function is right */
void shlc(BYTE *dat)
{
	BYTE i, b0;
	b0 = getbit(dat, 1);
	for (i = 0; i < 7; i ++){
		dat[i] <<= 1;
		if (i != 6)
			setbit(& dat[i], 8, getbit(&dat[i + 1],1));
	}
	setbit(dat, 56, getbit(dat, 28));
	setbit(dat, 28, b0);
}

/* This function is right */
void shrc(BYTE *dat)
{
	BYTE b0;
	int i;
	b0 = getbit(dat, 56);
	for (i = 6; i >= 0; i --){
		dat[i] >>= 1;
		if (i != 0)
			setbit(& dat[i], 1, getbit(&dat[i - 1], 8)); 
	}
	setbit(dat, 1, getbit(dat, 29));
	setbit(dat, 29, b0);
}

 
void tri_des(BYTE *dat, BYTE *key1, BYTE *key2, BYTE mode)
{
	des(dat, key1, mode);
	des(dat, key2, 1 - mode);
	des(dat, key1, mode);
}

BYTE extautk[][16]={{0x12, 0x23, 0x34, 0x45, 0x56, 0x67, 0x78, 0x89, 0x9a, 0xab, 0xbc, 0xcd, 0xde, 0xef, 0xf0, 0x01},
				{0x12, 0x23, 0x34, 0x45, 0x56, 0x67, 0x78, 0x89, 0x9a, 0xab, 0xbc, 0xcd, 0xde, 0xef, 0xf0, 0x01},
				{0x12, 0x23, 0x34, 0x45, 0x56, 0x67, 0x78, 0x89, 0x9a, 0xab, 0xbc, 0xcd, 0xde, 0xef, 0xf0, 0x01}},
	 intautk[16]={0x31, 0x41, 0x51, 0x61, 0x71, 0x81, 0x91, 0xa1, 0x46, 0x46, 0x46, 0x46, 0x46, 0x46, 0x46, 0x46},
	 cryptk[][16]={{0x12, 0x23, 0x34, 0x45, 0x56, 0x67, 0x78, 0x89, 0x9a, 0xab, 0xbc, 0xcd, 0xde, 0xef, 0xf0, 0x01},
				{0x12, 0x23, 0x34, 0x45, 0x56, 0x67, 0x78, 0x89, 0x9a, 0xab, 0xbc, 0xcd, 0xde, 0xef, 0xf0, 0x01}};






