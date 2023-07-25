class CScmp:
    def __init__(self, memory, start):
        # stop flag
        self.m_stop = False
        # scmp registers
        self.m_acc = 0
        # store effective address
        self.m_ea = 0
        self.m_ext = 0
        # set bit 5 of status (sense b)
        self.m_stat = 0x20
        # op code
        self.m_instr = 0
        self.m_disp = 0
        # scmp pointers
        self.ptr = [start, 0, 0, 0]
        # give memory
        self.memory = memory

    def FetchCode(self):
        pc = self.ptr[0] + 1
        pc = (pc & 0x0fff) + (self.ptr[0] & 0xf000)
        self.m_instr = self.memory[pc]
        opcode = f'{self.m_instr:02X}'
        self.ptr[0] = pc
        if (self.m_instr & 0x80):
            pc = pc + 1
            pc = (pc & 0x0fff) + (self.ptr[0] & 0xf000)
            self.m_disp = self.memory[pc]
            self.ptr[0] = pc
            opcode += f'{self.m_disp:02X}'
        return opcode

    def Decode(self):
        idx = self.m_instr & 0x03
        match self.m_instr:
            case 0:
                self.m_stop = True
            case 0x01:
                # XAE
                self.m_acc, self.m_ext = self.m_ext, self.m_acc
            case 0x02:
                # CCL, clear carry link
                self.m_stat &= 0x7f
            case 0x03:
                # SCL, set carry link
                self.m_stat |= 0x80
            case 0x04:
                # DINT
                self.m_stat &= 0xf7
            case 0x05:
                # IEN
                self.m_stat |= 0x08
            case 0x06:
                # CSA: copy status to acc
                self.m_acc = self.m_stat
            case 0x07:
                # CAS: copy acc to status, bit 4 of staus is not affectes
                self.m_stat = (self.m_acc & 0xef) | (self.m_stat & 0x10)
            case 0x08:
                # NOP: no operation
                nop = 0
            case 0x19:
                # SIO: serial in/out (no hardware)
                self.m_ext >>= 1
            case 0x1c:
                # SR: shift right
                self.m_acc >>= 1
            case 0x1d:
                # SRL: shift right with link
                self.m_acc >>= 1
                stat = self.m_stat & 0x80
                self.m_acc |= stat
            case 0x1e:
                # RR: rotate right
                acc = self.m_acc
                self.m_acc >>= 1
                if (acc & 1):
                    self.m_acc |= 0x80
            case 0x1f:
                # RRL: rotate right with link
                acc = self.m_acc
                stat = self.m_stat
                self.m_acc >>= 1
                if acc & 1:
                    self.m_stat |= 0x80
                else:
                    self.m_stat &= 0x7f
                if (stat & 0x80):
                    self.m_acc |= 0x80
                else:
                    self.m_acc &= 0x7f
            case 0x30 | 0x31 | 0x32 | 0x33:
                # XPAL: exchange acc with pointer low
                low = self.ptr[idx] & 0xff
                new = (self.ptr[idx] & 0xff00) | self.m_acc
                self.ptr[idx] = new
                self.m_acc = low
            case 0x34 | 0x35 | 0x36 | 0x37:
                # XPAH: exchange acc with pointer high
                high = (self.ptr[idx] >> 8) & 0xff
                new = (self.m_acc << 8) | (self.ptr[idx] & 0x00ff)
                self.ptr[idx] = new
                self.m_acc = high
            case 0x3c | 0x3d | 0x3e | 0x3f:
                # XPPC, exchange pointer with pc
                xch = self.ptr[idx]
                self.ptr[idx] = self.ptr[0]
                self.ptr[0] = xch
            case 0x40:
                # LDE
                self.m_acc = self.m_ext
            case 0x50:
                # ANE
                self.m_acc &= self.m_ext
            case 0x58:
                # ORE
                self.m_acc |= self.m_ext
            case 0x60:
                # XRE
                self.m_acc ^= self.m_ext
            case 0x68:
                # DAE: add acc and ext as binary coded decimals
                self.m_acc = self.DecAdd(self.m_ext)
            case 0x70:
                # ADE: add acc and ext binary
                self.m_acc = self.BinAdd(self.m_ext)
            case 0x78:
                # CAE: add acc and complement ext
                self.m_acc = self.BinAdd(self.m_ext ^ 0xFF)
            case 0x90 | 0x91 | 0x92 | 0x93:
                # JMP: unconditional jump
                self.CalcPC(idx)
            case 0x94 | 0x95 | 0x96 | 0x97:
                # JP: jump if acc is greater or equal zero
                acc = self.m_acc & 0x80
                # > 0, if sign bit not set
                if (acc == 0):
                    self.CalcPC(idx)
            case 0x98 | 0x99 | 0x9A | 0x9B:
                # JZ: jump if acc is zero
                acc = self.m_acc & 0xff
                if (acc == 0):
                    self.CalcPC(idx)
            case 0x9C | 0x9D | 0x9E | 0x9F:
                # JNZ: jump if acc not equal zero
                acc = self.m_acc & 0xff
                if (acc != 0):
                    self.CalcPC(idx)
            case 0xa8 | 0xa9 | 0xaa | 0xab:
                # ILD: increment content by one and load
                ea = self.CalcEA(idx)
                acc = self.memory[ea] + 1
                self.memory[ea] = self.m_acc = acc & 0xff
            case 0xb8 | 0xb9 | 0xba | 0xbb:
                # DLD: decrement content by one and load
                ea = self.CalcEA(idx)
                acc = self.memory[ea] - 1
                self.memory[ea] = self.m_acc = acc & 0xff
            case 0xc0 | 0xc1 | 0xc2 | 0xc3:
                # LD: load pointer indexed
                ea = self.CalcEA(idx)
                self.m_acc = self.memory[ea] & 0xff
            case 0xc4:
                # LDI: load accu with displacement
                self.m_acc = self.m_disp
            case 0xc5 | 0xc6 | 0xc7:
                # LD: load pointer autoindexed
                ai = self.CalcAI(idx)
                self.m_acc = self.memory[ai]
            case 0xc8 | 0xc9 | 0xca | 0xcb:
                # ST: store pointer indexed
                ea = self.CalcEA(idx)
                self.memory[ea] = self.m_acc & 0xff
            case 0xcd | 0xce | 0xcf:
                # ST: store pointer autoindexed
                ai = self.CalcAI(idx)
                self.memory[ai] = self.m_acc & 0xff
            case 0xd0 | 0xd1 | 0xd2 | 0xd3:
                # AND: pointer indexed
                ea = self.CalcEA(idx)
                self.m_acc &= self.memory[ea]
            case 0xd4:
                # ANI: and accu with displacement
                self.m_acc &= self.m_disp
            case 0xd5 | 0xd6 | 0xd7:
                # AND: and pointer autoindexed
                ai = self.CalcAI(idx)
                self.m_acc &= self.memory[ai]
            case 0xd9 | 0xda | 0xdb:
                # OR: and pointer indexed
                ea = self.CalcEA(idx)
                self.m_acc |= self.memory[ea]
            case 0xdc:
                # ORI: and accu with displacement
                self.m_acc |= self.m_disp
            case 0xdd | 0xde | 0xdf:
                # OR: or pointer autoindexed
                ai = self.CalcAI(idx)
                self.m_acc |= self.memory[ai]
            case 0xe0 | 0xe1 | 0xe2 | 0xe3:
                # XOR: xor pointer indexed
                ea = self.CalcEA(idx)
                self.m_acc ^= self.memory[ea]
            case 0xe4:
                # XRI: xor accu with displacement
                self.m_acc ^= self.m_disp
            case 0xe5 | 0xe6 | 0xe7:
                # XOR: xor pointer autoindexed
                ai = self.CalcAI(idx)
                self.m_acc ^= self.memory[ai]
            case 0xe8 | 0xe9 | 0xea | 0xeb:
                # DAD: decimal add pointer indexed
                ea = self.CalcEA(idx)
                self.m_acc = self.DecAdd(self.memory[ea])
            case 0xec:
                # DAI: decimal add displacement
                self.m_acc = self.DecAdd(self.m_disp)
            case 0xf0 | 0xf1 | 0xf2 | 0xf3:
                # ADD: binary add displacement indexed
                ea = self.CalcEA(idx)
                self.m_acc = self.BinAdd(self.memory[ea])
            case 0xf4:
                # ADI: binary add displacement immediate
                self.m_acc = self.BinAdd(self.m_disp)
            case 0xf5 | 0xf6 | 0xf7:
                # ADD: binry add pointer autoindexed
                ai = self.CalcAI(idx)
                self.m_acc = self.BinAdd(self.memory[ai])
            case 0xf8 | 0xf9 | 0xfa | 0xfb:
                # CAD: complement and add pointer indexed
                ea = self.CalcEA(idx)
                self.m_acc = self.BinAdd(self.memory[ea] ^ 0xFF)
            case 0xfc:
                # CAI: complement displacement and add binary immediate
                self.m_acc = self.BinAdd(self.m_disp ^ 0xFF)
            case 0xfd | 0xfe | 0xff:
                # CAD: complement and add pointer autoindexed
                ai = self.CalcAI(idx)
                self.m_acc = self.BinAdd(self.memory[ai] ^ 0xff)
            case _:
                # unrecognized code
                return "UNKNOWN"
        return "OK"

    def BinAdd(self, val):
        # add on two binaries, CY/L is included
        sum = self.m_acc + val + ((self.m_stat >> 7) & 1)
        if (((self.m_acc & 0x80) == (val & 0x80)) and ((self.m_acc & 0x80) != (sum & 0x80))):
            ov = 0x40
        else:
            ov = 0x00
        # clear CY/L and OV flag
        self.m_stat &= 0x3f
        # set CY/L
        if sum & 0x100:
            self.m_stat |= 0x80
        else:
            self.m_stat |= 0x00
        self.m_stat |= ov
        return (sum & 0xff)

    def DecAdd(self, val):
        # add on two bcd coded bytes. CY/L is included
        # the resulting carry is updated in status
        sum = self.m_acc + val + ((self.m_stat >> 7) & 1)
        if ((sum & 0x0f) > 9):
            sum +=6
        # clear CY/L flag
        self.m_stat &= 0x7f
        if sum > 0x99:
            self.m_stat |= 0x80
        else:
            self.m_stat |= 0x00
        return (sum % 0xa0)

    def CalcPC(self, idx):
        # avoid coding over page limit (address space only 12 bit)
        p = self.ptr[idx]
        disp = self.m_disp
        if disp & 0x80:
            disp += 0xff00
        n_pc = p + disp
        # stay in same page
        self.ptr[0] = (n_pc & 0x0fff) + (p & 0xf000)
    '''
    def CalcPC(self, idx):
        # avoid coding over page limit (address space only 12 bit)
        p = self.ptr[idx]
        if self.m_disp == 0x80 and idx > 0:
            disp = self.m_ext
        else:
            disp = self.m_disp
        if disp & 0x80:
            disp += 0xff00
        n_pc = p + disp
        if idx == 0:
            # stay in same page
            self.ptr[0] = (n_pc & 0x0fff) + (p & 0xf000)
        else:
            # stay in 64k address space, pointer > 0 are not affected
            self.ptr[0] = n_pc & 0xffff
    '''

    def CalcEA(self, idx):
        # pointer indexed, no autoindex
        p = self.ptr[idx]
        ea = 0
        disp = self.m_disp
        if (disp == 0x80):
            # take disp from extension
            disp = self.m_ext
        if (self.m_disp == 0x80):
            disp = self.m_ext
        if disp & 0x80:
            disp += 0xff00
        ea = p + disp
        # stay in same page
        ea = (ea & 0x0fff) + (p & 0xf000)
        self.m_ea = ea
        return ea

    def CalcAI(self, idx):
        # pointer autoindexed
        p = self.ptr[idx]
        ea = 0
        disp = self.m_disp
        if (disp == 0x80):
            # take disp from extension
            disp = self.m_ext
        if disp & 0x80:
            # decrement pointer by displacement and THEN use as ea
            disp |= 0xff00
            ea = p + disp
            # stay in 64k address space
            ea = (ea & 0x0fff) + (p & 0xf000)
            self.ptr[idx] = self.m_ea = ea
            return ea
        else:
            # use pointer as ea and THEN increment by displacement and use than as ea
            self.m_ea = p
            ea = p + disp
            # stay in 64k address space
            ea &= 0xffff
            self.ptr[idx] = (ea & 0x0fff) + (p & 0xf000)
            return p

