/*
 * Rowan: This file will be linked into the first half of uboot.
 * It contains:
 * 1) move serial init as early as possible. Which is more helpful for us to debug.
 * 2) nand initalize , load all uboot code from nand into sdram.  To support boot from nand flash.
 */

/*
 * UART register definition
 */
#define SERIAL0_ULCON0 (*((volatile unsigned long*)0x50000000))
#define SERIAL0_UFCON0 (*((volatile unsigned long*)0x50000008))
#define SERIAL0_UMCON0 (*((volatile unsigned long*)0x5000000c))
#define SERIAL0_UCON0  (*((volatile unsigned long*)0x50000004))
#define SERIAL0_UBRDIV0 (*((volatile unsigned long*)0x50000028))
#define SERIAL0_UTRSTAT0 (*((volatile unsigned long*)0x50000010))
#define SERIAL0_UTXH   (*((volatile unsigned long*)0x50000023))

void mini2440_serial0_init(void)
{
	int i = 0;
	SERIAL0_UFCON0 = 0x06;
	SERIAL0_UMCON0 = 0x00;
	SERIAL0_ULCON0 = 0x03;
	SERIAL0_UCON0 = 0x05;

	unsigned int reg = (50000000) / (16 * 115200) - 1;
	SERIAL0_UBRDIV0 = reg;
	for (i = 0;i < 100;i++)
		;
}

void serial0_output(char* message)
{
	char* ptr;
	for (ptr = message;ptr != '\0';ptr++)
		serial0_putc(*ptr);
}

void mini2440_test_serial(void)
{
	while (!(SERIAL0_UTRSTAT0 & 0x2))
		;
	SERIAL0_UTXH = 'R';

	while (!(SERIAL0_UTRSTAT0 & 0x2))
		;
	SERIAL0_UTXH = 'o';

	while (!(SERIAL0_UTRSTAT0 & 0x2))
		;
	SERIAL0_UTXH = 'w';

	while (!(SERIAL0_UTRSTAT0 & 0x2))
		;
	SERIAL0_UTXH = 'a';

	while (!(SERIAL0_UTRSTAT0 & 0x2))
		;
	SERIAL0_UTXH = 'n';
}
