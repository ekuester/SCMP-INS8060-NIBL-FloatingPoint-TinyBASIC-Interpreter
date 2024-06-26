#!/usr/bin/env python3
# Calculate the binary floating point equivalent to a decimal floating point number.
# The binary consists out of an signed exponent byte and a 3-byte signed mantissa.
# The format was used by Apple for the 6502 processor, and shortly later adapted for
# use in the NIBLFP interpreter for the SC/MP.
# This is a predecessor of the well-known IEEE754 format.
# Conversion program in python > 3.9 by Erich Küster, Krefeld/Germany
# February 2024

import re

# convert floating point decimal number into floating point binary
def float_bin(number, places = 6):
	numberStr = f"{number:.9f}"
	# split number at decimal point 
	n_whole, n_dec = numberStr.split(".")
	n_whole = int(n_whole)
	# format integer to binary, add '.'
	b_str = f"{n_whole:b}."
	#b_str = (str(bin(n_whole)) + ".").replace('0b','')
	for x in range(places):
		n_dec = str('0.') + str(n_dec)
		temp = '%1.20f' % (float(n_dec) * 2)
		# split again at decimal point
		n_whole, n_dec = temp.split(".")
		b_str += n_whole
	#print(f"binary: {b_str}")
	return b_str

def niblfp(n):
	bias = 128
	sign = 1
	if n < 0 :
		sign = -1
		# take absolute value
		n = n * (-1)
	# 32 Bit
	p = 32
	bin_str = float_bin(n, places = p)
	# find fractional point
	dotPlace = bin_str.find('.')
	# find first 'one'
	onePlace = bin_str.find('1')
	# ignore leading zeros
	start = onePlace
	if onePlace < dotPlace:
		# 'one's before fractional point
		bin_str = bin_str.replace(".", "")
		dotPlace -= 1
		start = 0
	# calculate preliminary exponent
	exponent = dotPlace - onePlace
	if onePlace < 0:
		# no 'one' found, number is zero
		sign = 0
		exponent = -bias
	# slice mantissa string from first 'one' until end
	mantStr = bin_str[start:]
	# justify to the left, add zeros if required and limit to 23 bits
	mantStrJust = mantStr.ljust(23, '0')
	mantStr23 = mantStrJust[:23]
	if sign >= 0:
		mantissa = '0' + mantStr23
	else:
		print("so negative")
		# build two's complement
		mant = int(mantStr23, 2)
		mant ^= 0xFFFFFF
		mant += 1
		if (mant & 0x400000) != 0:
			mant *= 2
			exponent -= 1
		mant &= 0xFFFFFF
		mantissa = f"{mant:024b}"
	#print(f"mantissa: {mantissa}")
	exp_bits = exponent + bias
	chara = f"{exp_bits:08b}"
	binary_str = chara + mantissa
	num = int(binary_str, 2)
	hex_str = f"{num:08X}"
	return (hex_str, binary_str)

if __name__ == "__main__" :
	inp_len = 0
	prompt = "Floating Point Decimal: "
	while not inp_len:
		fpDecStr = input(prompt).lower()
		# match floating point decimal
		if not re.match(r"^[+-]?[0-9]+\.[0-9]+$", fpDecStr):
			continue
		inp_len = len(fpDecStr)
	fpd = float(fpDecStr)
	print ("fpd: ", niblfp(fpd))

