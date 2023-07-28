#!/usr/bin/env python3
# curses example: <https://gist.github.com/claymcleod/b670285f334acd56ad1c>
# NOTICE: add breakpoints at line 265

import curses, binascii, os, re, sys
from scmp import CScmp

def greeting():
    print("SC/MP simple emulator by Sipke de Wal (Henry Mason)")
    print("<http://xgistor-echo.scorchingbay.nz/files/SCMPNIBL/>")
    print("rewritten for python > 3.9 and curses May 2023")
    print("by Erich Küster, Krefeld / Germany")

def usage():
    print("Usage: ./scmp_curses.py filename [hex load_address] [hex program_start]")
    print("Example: ./scmp_curses.py NIBLE 1000 1000")
    print("file can be in Intel HEX or binary format")
    quit()

def RenderStatus(stdscr, opcode, s):
    # read standard screen dimensions
    height, width = stdscr.getmaxyx()
    # Render status bar
    stdscr.attron(curses.color_pair(3))
    statusbarstr = \
f" STATUS: pc:{s.ptr[0]:04X} op: {opcode} \
acc:{s.m_acc:02X} ext:{s.m_ext:02X} stat:{s.m_stat:02X} \
p1:{s.ptr[1]:04X} p2:{s.ptr[2]:04X} p3:{s.ptr[3]:04X} ea:{s.m_ea:04X}"
    stdscr.addstr(height-1, 0, statusbarstr)
    stdscr.addstr(height-1, len(statusbarstr), " " * (width - len(statusbarstr) - 1))
    stdscr.attroff(curses.color_pair(3))

def emulate(stdscr, debug):
    # init class CScmp
    s = CScmp(s_memory, start)
    k = 0
    cursor_x = 0
    cursor_y = 1
    # Clear and refresh the screen for a blank canvas
    stdscr.clear()
    # read standard screen dimensions
    height, width = stdscr.getmaxyx()
    stdscr.scrollok(True)
    # set scrolling region
    stdscr.setscrreg(1, height - 3)
    stdscr.addstr(0, 1, "SC/MP EMULATOR 2000 - 2023")
    stdscr.refresh()

    # define 3 color pairs, 1- header/footer , 2 - dynamic text, 3 - background
    curses.start_color()
    curses.init_pair(1, curses.COLOR_CYAN, curses.COLOR_BLACK)
    curses.init_pair(2, curses.COLOR_RED, curses.COLOR_WHITE)
    curses.init_pair(3, curses.COLOR_BLACK, curses.COLOR_WHITE)
    opcode = ""
    # Loop where k is the last character pressed
    while (k != ord('q') and not s.m_stop):
        if k == curses.KEY_DOWN:
            cursor_y = cursor_y + 1
        elif k == curses.KEY_UP:
            cursor_y = cursor_y - 1
        elif k == curses.KEY_RIGHT:
            cursor_x = cursor_x + 1
        elif k == curses.KEY_LEFT:
            cursor_x = cursor_x - 1

        cursor_x = max(0, cursor_x)
        cursor_x = min(width-1, cursor_x)

        cursor_y = max(0, cursor_y)
        cursor_y = min(height-1, cursor_y)

        # some special cases
        bs = False
        ht = False
        cr = False

        opcode = s.FetchCode()
        if opcode == "20":
            # char is in acc
            c = s.m_acc & 0x7f
            #stdscr.addstr(height -4, 2, f"WRITECH: {c:02X}")
            if c == 8:
                # backspace, use Control-H >> not backspace key
                if cursor_x > 2:
                    cursor_x -= 1
            elif c == 9:
                # horizontal tab, use Control-I or tab key
                cursor_x += 1
            elif c == 10:
                cursor_x = 1
                cursor_y +=1
                if cursor_y == height-3:
                    stdscr.scroll()
                    cursor_y -=1
            elif c == 12:
                cursor_x += 2
            elif c == 13:
                cursor_x = 1
            elif c > 31:
                stdscr.addch(cursor_y, cursor_x, chr(c))
                cursor_x += 1
        elif opcode == "21":
            stdscr.attron(curses.color_pair(2))
            stdscr.addstr(height-2, 0, " READCHAR ")
            stdscr.attroff(curses.color_pair(2))
            # update cursor
            stdscr.move(cursor_y, cursor_x)
            # refresh screen
            stdscr.refresh()
            c = stdscr.getch()
            if c == 10: c = 13
            # digit or letter
            if c & 0x40:
                # change to uppercase
                c = c & 0x5f
            s.m_acc = s.m_ext = c
            stdscr.addstr(height-2, 0, "          ")
        else:
            result = s.Decode()
            if s.m_stop:
                stdscr.addstr(height - 2, 2, "FINISHED, PRESS KEY")
                k = stdscr.getch()
                break
            elif result != "OK":
                stdscr.addstr(height - 2, 2, f"{result} {opcode} PREMATURE END")
                k = stdscr.getch()
        stdscr.addstr(height - 3, 2, "        ")
        pc = s.ptr[0]
        # loook for breakpoint
        if brkpnt_lst:
            if pc in brkpnt_lst:
                stdscr.addstr(height - 3, 2, f"BREAKPOINT: {pc:04X}")
                k = stdscr.getch()
                # set to True for single step after breakpoint
                if k == ord('t'):
                    debug = True
                else:
                    debug = False
                    stdscr.addstr(height - 3, 2, f"                ")
        if not turbo:
            RenderStatus(stdscr, opcode, s)
        stdscr.move(cursor_y, cursor_x)
        # refresh screen
        stdscr.refresh()
        if debug:
            # Wait for next input
            k = stdscr.getch()
    curses.endwin()
    # convert the key to ASCII and print ordinal value
    print("Last pressed %s which is keycode %d." % (chr(k), k))

def decode(hexlines):
    # convert Intel HEX into binary
    addresses = []
    lines = []
    for h_line in hexlines:
        check = h_line[1:-3]
        line_sum = int(h_line[-3:-1],16)
        hex_bytes = binascii.unhexlify(check)
        hex_bytes_sum = sum(hex_bytes)
        # one's complement
        hex_bytes_sum ^= 0xFF
        # add one for two's complement
        check_sum = (hex_bytes_sum + 1) % 256
        # compare check sums
        if check_sum != line_sum:
            print("checksum error in file")
            quit()
        count = int(h_line[1:3],16)
        address = int(h_line[3:7],16)
        addresses.append(address)
        line = h_line[9:-3]
        lines.append(line)
    h_bytes = bytearray()
    next_address = addresses[0]
    for i, address in enumerate(addresses):
        if address > next_address:
            # fill gaps with bytes
            fill = address - next_address
            fill_bytes = ([255]*fill)
            h_bytes.extend(fill_bytes)
            next_address += fill
        h_bytes.extend(binascii.unhexlify(lines[i]))
        count = len(lines[i]) >> 1
        next_address = address + count
    # return load address and binary as byte array
    load = addresses[0]
    return load, h_bytes

greeting()
argc = len(sys.argv)
if (argc != 2 and argc != 3 and argc != 4):
    usage()
base = sys.argv[1]
# address to load into memory
load = 0
# program start address
start = 0
if (argc > 2):
    addr = sys.argv[2]
    load = start = int(addr,16)
if (argc == 4):
    addr = sys.argv[3]
    start = int(addr,16)

inp_len = 0
s_bytes = bytearray()
h_lines = []
while not inp_len:
    prompt = 'read from [b]inary or [h]ex file? '
    choice = input(prompt).lower()
    if not re.match(r"^[bh]+$", choice):
        continue
    inp_len = len(choice)
    if choice[0] == "b":
        file_bin = base + ".bin"
        file_stats = os.stat(file_bin)
        print(f'Will read file {file_bin} with {file_stats.st_size} Bytes')
        with open(file_bin, "rb") as bin_f:
            s_bytes = bytearray(bin_f.read())
        break
    if choice[0] == "h":
        file_hex = base + ".hex"
        file_stats = os.stat(file_hex)
        print(f'Will read file {file_hex} with {file_stats.st_size} Bytes')
        with open(file_hex, "r") as hex_f:
            for h_line in hex_f:
                h_lines.append(h_line)
        load, s_bytes = decode(h_lines)
        break

# reserve 64 kByte memory as work space
s_memory = bytearray(0x10000)

print(f'into sc/mp memory with {len(s_memory)} Bytes at address hex {load:04X}')
# now copy the program bytes into scmp memory beginning at load
for i, byte in enumerate(s_bytes):
    s_memory[load + i] = byte
print(f'{i} bytes copied')

inp_len = 0
debug = False
snapshot = False
turbo = False
while not inp_len:
    prompt = '[d]ebug, [g]o, [q]uit, [r]ead, [s]napshot, [t]urbo: '
    choice = input(prompt).lower()
    if not re.match(r"^[dgqrst]+$", choice):
        continue
    inp_len = len(choice)
    if choice[0] == "q":
        quit()
    if choice[0] == "r":
        # read BASIC program into page 1
        file_snap = base + ".snap"
        file_stats = os.stat(file_snap)
        print(f'Will read file {file_snap} with {file_stats.st_size} Bytes')
        with open(file_snap, "rb") as snap_f:
            snap_bytes = bytearray(snap_f.read())
            # read in page 1
            s_bytes = snap_bytes[4096:8192]
            for i, byte in enumerate(s_bytes):
                s_memory[4096 + i] = byte
            print(f'{i} bytes copied')
        break
    elif choice[0] == "d":
        debug = True
        break
    elif choice[0] == "s":
        snapshot = True
        print("will make a snapshot at exit")
        inp_len = 0
    elif choice[0] == "t":
        # accelerate, no status bar
        turbo = True
        break
# define breakpoint list
brkpnt_lst = []
# add break points as list when desired
brkpnt_lst.extend([0])
# use curses
curses.wrapper(emulate, debug)

if snapshot:
    # snapshot 64 kiB scmp memory
    snapshot = base + ".snap"
    with open(snapshot, "wb") as snap_f:
        snap_f.write(s_memory)
print()
print("Done.")

