#!/usr/bin/env python3

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
	print(f"binary: {b_str}")
	return b_str

def niblfp(n):
	bias = 128
	sign = 0
	if n < 0 :
		sign = 1
		# take absolute value
		n = n * (-1)
	p = 40
	dec = float_bin(n, places = p)
	dotPlace = dec.find('.')
	onePlace = dec.find('1')
	print("dot:", dotPlace, "one:", onePlace)
	# ignore leading zeros
	start = onePlace
	#if onePlace > dotPlace:
		# zero before comma, number less than 1
		#dec = dec.replace(".", "")
		#onePlace -= 1
		#dotPlace -= 1
	if onePlace < dotPlace:
		# ones before fractional point
		dec = dec.replace(".", "")
		dotPlace -= 1
		start = 0
	# slice from first one until end
	mantStr = dec[start:]
	# add sign to binary representation, justify to the left, add zeros if required
	mantissa = '0' + mantStr.ljust(23, '0')
	if sign:
		# build two's complement
		mantissa = ''.join('1' if c == '0' else '0' for c in mantissa)
		mant = int(mantissa,2) + 1
		mant &= 0xFFFFFF
		mantissa = str(bin(mant)).replace('0b','')
	exponent = dotPlace - onePlace
	exponent_bits = exponent + bias
	chara = f"{exponent_bits:08b}"
	binary_str = chara + mantissa
	num = int(binary_str, 2)
	hex_str = f"{num:8X}"
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

