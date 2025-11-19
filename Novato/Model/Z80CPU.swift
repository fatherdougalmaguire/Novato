import Foundation

actor Z80CPU
{
    var registers = Registers()
 
    var ports = [UInt8](repeating: 0, count: 256)
    
    //    00 or 10 PIO port A data port
    //    01 or 11 PIO port A control port
    //    02 or 12 PIO port B data port
    //    03 or 13 PIO port B control port
    //    08 or 18 COLOUR control port
    //    09 or 19 Colour "Wait off"
    //    0A or 1A Extended addressing port
    //    OB or 1B Character ROM CPU access - makes character generator ROM appear from F000h to F7FFh when bit 0 of this port is set.
    //    OC or 1C 6545 CRTC address/status port
    //    OD or 1D 6545 CRTC data port
    //    44 FDC command/status
    //    45 FDC track register
    //    46 FDC sector register
    //    47 FDC data register
    //    48 Controller select/side/DD latch
        
    //    PORT B DATA PORT BIT ASSIGNMENTS
    //    bit 0 Cassette data in
    //    bit 1 Cassette data outddd
    //    bit 2 RS232 CLOCK or DTR line
    //    bit 3 RS232 CTS line (0-> clear to send)
    //    bit 4 RS232 input (0 = mark)
    //    bit 5 RS232 output (1 = mark)
    //    bit 6 Speaker bit (1 = on)
    //    bit 7 Network interrupt bit

    //    FLOPPY DISC CONTROLLER
    //    Controller select/side/DD latch bit assignments (write only)
    //    bit 0 LSB of drive address
    //    bit 1 MSB of drive address
    //    bit 2 Side select (0 = side 0; 1 = side 1)
    //    bit 3 DD select (0 = single density)
    //
    //    Controller TRANSFER status bit - bit 7 when port 48H is read gives (INTRQ or DRQ)

    //    COLOUR PORT BIT ASSIGNMENT
    //    bit 0 Not used
    //    bit 1 RED background intensity (1 = full)
    //    bit 2 GREEN backgroung intensity
    //    bit 3 BLUE background intensity
    //    bit 6 COLOUR RAM enable (0 = PCG, 1= RAM)
    
    var runcycles : UInt64 = 0
    var CPUstarttime : Date = Date()
    var CPUendtime : Date = Date()
    
    var emulatorHalted : Bool = false

    var MOS6545 = CRTC()
    
    var AddressSpace = MMU(MemorySize : 0x10000, MemoryValue : 0x00)
    var VDURAM = MMU(MemorySize : 0x800, MemoryValue : 0x20)
    var CharGenROM = MMU(MemorySize : 0x1000, MemoryValue : 0x00)
    
    init()
    {
        MOS6545.SetCursorDutyCycle()
        AddressSpace.memory[0xf000...0xf7ff] = VDURAM.memory[0...0x7ff]
        AddressSpace.LoadROM(FileName: "basic_5.22e", FileExtension: "rom",MemoryAddress : 0x8000)
        AddressSpace.LoadROM(FileName: "wordbee_1.2", FileExtension: "rom",MemoryAddress : 0xC000)
        AddressSpace.LoadROM(FileName: "telcom_1.0", FileExtension: "rom",MemoryAddress : 0xE000)
        CharGenROM.LoadROM(FileName: "charrom", FileExtension: "bin", MemoryAddress : 0x0000)
        AddressSpace.LoadROM(FileName: "hello", FileExtension: "bin",MemoryAddress : 0x0000)
    }

    private(set) var isRunning = false
    private var stepTask: Task<Void, Never>?

    func start()
    {
        guard !isRunning else { return }
        isRunning = true
        stepTask = Task
        {
            while isRunning
            {
                step()
                try? await Task.sleep(nanoseconds: 1000) // 1 microsecond
            }
        }
    }
    
    func step()
    {
        CPUstarttime = Date()
        let prefetch = fetch(ProgramCounter : registers.PC)
        MOS6545.ResetCursorDutyCycle()
        if !emulatorHalted
        {
            execute(opcodes : prefetch)
        }
        CPUendtime = Date()
        let ken = CPUendtime.timeIntervalSince1970-CPUstarttime.timeIntervalSince1970
        print("Instruction took ",ken / Double(runcycles)*1000*1000," microseconds to execute")
        runcycles = 0
    }

    func stop()
    {
        isRunning = false
        stepTask?.cancel()
    }

    private func fetch( ProgramCounter : UInt16) -> (UInt8,UInt8,UInt8,UInt8)
    {
        return ( opcode1 : AddressSpace.ReadMemory(MemoryAddress : ProgramCounter),
                 opcode2 : AddressSpace.ReadMemory(MemoryAddress : IncrementRegPair(BaseValue : ProgramCounter,Increment : 1)),
                 opcode3 : AddressSpace.ReadMemory(MemoryAddress : IncrementRegPair(BaseValue : ProgramCounter,Increment : 2)),
                 opcode4 : AddressSpace.ReadMemory(MemoryAddress : IncrementRegPair(BaseValue : ProgramCounter,Increment : 3))
                )
    }

    func IncrementRegPair ( BaseValue  : UInt16, Increment : UInt16 ) -> UInt16
    
    {
        return BaseValue &+ Increment
    }
    
    func DecrementRegPair ( BaseValue  : UInt16, Decrement : UInt16 ) -> UInt16
    
    {
        return BaseValue &- Decrement
    }
    
    func IncrementReg ( BaseValue  : UInt8, Increment : UInt8 ) -> UInt8
    
    {
        return BaseValue &+ Increment
        // flag code goes here
    }
    
    func DecrementReg ( BaseValue  : UInt8, Decrement : UInt8 ) -> UInt8
    
    {
        return BaseValue &- Decrement
        // flag code goes here
    }
    
    func UpdateProgramCounter ( CurrentPC : UInt16, Offset : UInt8 ) -> UInt16
    
    {
     return CurrentPC &+ UInt16(Int8(bitPattern: Offset))
    }
    
    func TestFlags ( FlagRegister : UInt8, Flag : Z80Flags ) -> Bool
    
    {
        return FlagRegister & Flag.rawValue != 0
    }
    
    func UpdateFlags ( FlagRegister : UInt8, Flag : Z80Flags, SetFlag : Bool ) -> UInt8
    {
        if (SetFlag)
        {
            return FlagRegister | Flag.rawValue
        }
        else
        {
            return FlagRegister & ~Flag.rawValue
        }
    }
    
    func SetFlags ( FlagRegister : UInt8, Flag : Z80Flags ) -> UInt8
    {
        let result = FlagRegister | Flag.rawValue
        return result
    }
    
    func ResetFlags ( FlagRegister : UInt8, Flag : Z80Flags ) -> UInt8
    {
        let result = FlagRegister & Flag.rawValue
        return result
    }

    private func execute( opcodes: ( opcode1 : UInt8, opcode2 : UInt8, opcode3 : UInt8, opcode4 : UInt8))
    {
        switch opcodes.opcode1
        {
        case 0x00: // NOP
            print("Executed NOP @ "+String(format:"%04X",registers.PC))
            registers.PC = UpdateProgramCounter(CurrentPC:registers.PC,Offset:1)
        case 0x01: // LD BC, nn
            print("Executed LD BC, nn @ "+String(format:"%04X",registers.PC))
            registers.BC = UInt16(opcodes.opcode3) << 8 | UInt16(opcodes.opcode2)
            registers.PC = UpdateProgramCounter(CurrentPC:registers.PC,Offset:3)
        case 0x04: // INC B
            print("Unimplemented opcode "+String(format: "%02X", opcodes.opcode1) + " @ "+String(format:"%04X",registers.PC))
            registers.PC = UpdateProgramCounter(CurrentPC:registers.PC,Offset:1)
        case 0x05: // DEC B
            print("Unimplemented opcode "+String(format: "%02X", opcodes.opcode1) + " @ "+String(format:"%04X",registers.PC))
            registers.PC = UpdateProgramCounter(CurrentPC:registers.PC,Offset:1)
        case 0x11: // LD DE, nn
            print("Executed LD DE, nn @ "+String(format:"%04X",registers.PC))
            registers.DE = UInt16(opcodes.opcode3) << 8 | UInt16(opcodes.opcode2)
            registers.PC = UpdateProgramCounter(CurrentPC:registers.PC,Offset:3)
        case 0x21: // LD HL, nn
            print("Executed LD HL, nn @ "+String(format:"%04X",registers.PC))
            registers.HL = UInt16(opcodes.opcode3) << 8 | UInt16(opcodes.opcode2)
            registers.PC = UpdateProgramCounter(CurrentPC:registers.PC,Offset:3)
        case 0x28: // JR Z,n
            print("Executed JR Z, n @ "+String(format:"%04X",registers.PC) + " ["+String(format:"%02X",opcodes.opcode1)+","+String(format:"%02X",opcodes.opcode2)+"]")
            if (TestFlags(FlagRegister:registers.F,Flag:Z80Flags.Zero))
            {
                registers.PC = UpdateProgramCounter(CurrentPC:registers.PC,Offset:opcodes.opcode2+2)
            }
            else
            {
                registers.PC = UpdateProgramCounter(CurrentPC:registers.PC,Offset:2)
            }
        case 0x23: // INC HL
            print("Executed INC HL @ "+String(format:"%04X",registers.PC))
            registers.HL = IncrementRegPair(BaseValue:registers.HL,Increment:1)
            registers.PC = UpdateProgramCounter(CurrentPC:registers.PC,Offset:1)
        case 0x3C: // INC A
            print("Executed INC A @ "+String(format:"%04X",registers.PC))
            registers.A = IncrementReg(BaseValue:registers.A,Increment:1)
            registers.PC = UpdateProgramCounter(CurrentPC:registers.PC,Offset:1)
        case 0x3E: // LD A, n
            print("Executed LD A, n @ "+String(format:"%04X",registers.PC) + " ["+String(format:"%02X",opcodes.opcode1)+","+String(format:"%02X",opcodes.opcode2)+"]")
            registers.A = opcodes.opcode2
            registers.PC = UpdateProgramCounter(CurrentPC:registers.PC,Offset:2)
        case 0x76: // HALT
            print("Executed HALT @ "+String(format:"%04X",registers.PC))
            emulatorHalted = true
        case 0x77: // LD (HL), A
            print("Executed LD (HL), A @ "+String(format:"%04X",registers.PC))
            if (0xF000...0xF7FF).contains(registers.HL)
            {
                VDURAM.WriteMemory(MemoryAddress : registers.HL-0xF000, MemoryValue : registers.A)
            }
            AddressSpace.WriteMemory(MemoryAddress : registers.HL, MemoryValue : registers.A)
            registers.PC = UpdateProgramCounter(CurrentPC:registers.PC,Offset:1)
        case 0x78: // LD A, B
            print("Executed LD A, B @ "+String(format:"%04X",registers.PC))
            registers.A = registers.B
            registers.PC = UpdateProgramCounter(CurrentPC:registers.PC,Offset:1)
        case 0x79: // LD A,C
            print("Executed LD A, C @ "+String(format:"%04X",registers.PC))
            registers.A = registers.C
            registers.PC = UpdateProgramCounter(CurrentPC:registers.PC,Offset:1)
        case 0x7A: // LD A,D
            print("Executed LD A, D @ "+String(format:"%04X",registers.PC))
            registers.A = registers.D
            registers.PC = UpdateProgramCounter(CurrentPC:registers.PC,Offset:1)
        case 0x7B: // LD A,E
            print("Executed LD A, E @ "+String(format:"%04X",registers.PC))
            registers.A = registers.E
            registers.PC = UpdateProgramCounter(CurrentPC:registers.PC,Offset:1)
        case 0x7C: // LD A,H
            print("Executed LD A, H @ "+String(format:"%04X",registers.PC))
            registers.A = registers.H
            registers.PC = UpdateProgramCounter(CurrentPC:registers.PC,Offset:1)
        case 0x7D: // LD A,L
            print("Executed LD A, L @ "+String(format:"%04X",registers.PC))
            registers.A = registers.L
            registers.PC = UpdateProgramCounter(CurrentPC:registers.PC,Offset:1)
        case 0xC2: // JP NZ,nn
            print("Executed JP NZ,nn @ "+String(format:"%04X",registers.PC))
            if (TestFlags(FlagRegister:registers.F,Flag:Z80Flags.Zero))
            {
                registers.PC = UpdateProgramCounter(CurrentPC:registers.PC,Offset:3)
            }
            else
            {
                registers.PC = UInt16(opcodes.opcode3) << 8 | UInt16(opcodes.opcode2)
            }
        case 0xC3: // JP nn
            print("Executed JP nn @ "+String(format:"%04X",registers.PC))
            registers.PC = UInt16(opcodes.opcode3) << 8 | UInt16(opcodes.opcode2)
        case 0xCA: // JP Z,nn
            print("Executed JP Z,nn @ "+String(format:"%04X",registers.PC))
            if (TestFlags(FlagRegister:registers.F,Flag:Z80Flags.Zero))
            {
                registers.PC = UInt16(opcodes.opcode3) << 8 | UInt16(opcodes.opcode2)
            }
            else
            {
                registers.PC = UpdateProgramCounter(CurrentPC:registers.PC,Offset:3)
            }
        case 0xD2: // JP NC,nn
            print("Executed JP NC,nn @ "+String(format:"%04X",registers.PC))
            if (TestFlags(FlagRegister:registers.F,Flag:Z80Flags.Carry))
            {
                registers.PC = UpdateProgramCounter(CurrentPC:registers.PC,Offset:3)
            }
            else
            {
                registers.PC = UInt16(opcodes.opcode3) << 8 | UInt16(opcodes.opcode2)
            }
        case 0xD3: // OUT (n),A
            print("Executed OUT (n),A @ "+String(format:"%04X",registers.PC) + " ["+String(format:"%02X",opcodes.opcode1)+","+String(format:"%02X",opcodes.opcode2)+"]")
            ports[Int(opcodes.opcode2)] = registers.A
            switch opcodes.opcode2
            {
                case 0x0C: break // writing to port 0x0C needs no further processing
                case 0x0D: MOS6545.WriteRegister(RegNum:ports[0x0C], RegValue:ports[0x0D])
                default: print("Whicha port ? Disaport !"+String(opcodes.opcode2))
            }
        
            //Writing to port 0x0C writes a register number
            //Writing port 0x0D writes the register selected on port 0x0C
            
            registers.PC = UpdateProgramCounter(CurrentPC:registers.PC,Offset:2)
        case 0xDA: // JP C,nn
            print("Executed JP C,nn @ "+String(format:"%04X",registers.PC))
            if (TestFlags(FlagRegister:registers.F,Flag:Z80Flags.Carry))
            {
                registers.PC = UInt16(opcodes.opcode3) << 8 | UInt16(opcodes.opcode2)
            }
            else
            {
                registers.PC = UpdateProgramCounter(CurrentPC:registers.PC,Offset:3)
            }
        case 0xDB: // IN A,(n)
            print("Executed IN A,(n) @ "+String(format:"%04X",registers.PC) + " ["+String(format:"%02X",opcodes.opcode1)+","+String(format:"%02X",opcodes.opcode2)+"]")
            registers.A = ports[Int(opcodes.opcode2)]
            switch opcodes.opcode2
            {
                case 0x0C: registers.A = MOS6545.ReadStatusRegister()
                case 0x0D: registers.A = MOS6545.ReadRegister(RegNum:ports[0x0C])
                default: print("Whicha port ? Disaport !"+String(opcodes.opcode2))
            }
            
            //Reading port 0x0D reads the register selected on port 0x0C
            //Reading from port 0x0C reads the status register
            
            registers.PC = UpdateProgramCounter(CurrentPC:registers.PC,Offset:2)
        case 0xE2: // JP PO,nn
            print("Executed JP PO,nn @ "+String(format:"%04X",registers.PC))
            if (TestFlags(FlagRegister:registers.F,Flag:Z80Flags.Parity_Overflow))
            {
                registers.PC = UpdateProgramCounter(CurrentPC:registers.PC,Offset:3)
            }
            else
            {
                registers.PC = UInt16(opcodes.opcode3) << 8 | UInt16(opcodes.opcode2)
            }
        case 0xEA: // JP PE,nn
            print("Executed JP PE,nn @ "+String(format:"%04X",registers.PC))
            if (TestFlags(FlagRegister:registers.F,Flag:Z80Flags.Parity_Overflow))
            {
                registers.PC = UInt16(opcodes.opcode3) << 8 | UInt16(opcodes.opcode2)
            }
            else
            {
                registers.PC = UpdateProgramCounter(CurrentPC:registers.PC,Offset:3)
            }
        case 0xED: // ED instructions
            switch opcodes.opcode2
            {
            case 0xB0:  // LDIR
                // doesn't cater for transfers to non VDU RAM
                // needs flags to be updated
                // S is not affected.
                // Z is not affected.
                // H is reset.
                // P/V is set if BC-1 != 0; otherwise, it is reset.
                // N is reset.
                // C is not affected.
                registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Half_Carry,SetFlag:false)
             //   registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Parity_Overflow,SetFlag:((registers.A ^ opcodes.opcode2) & (registers.A ^ temporaryResult) & 0x80 ) != 0)
                registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Negative,SetFlag:false)
                if registers.BC == 0
                {
                    registers.BC = 0xFFFF
                }
                while registers.BC > 0
                {
                    AddressSpace.WriteMemory(MemoryAddress : registers.DE, MemoryValue : AddressSpace.ReadMemory(MemoryAddress : registers.HL))
                    VDURAM.WriteMemory(MemoryAddress : registers.DE-0xF000, MemoryValue : AddressSpace.ReadMemory(MemoryAddress : registers.HL))
                    registers.HL = IncrementRegPair(BaseValue:registers.HL,Increment:1)
                    registers.DE = IncrementRegPair(BaseValue:registers.DE,Increment:1)
                    registers.BC = DecrementRegPair(BaseValue:registers.BC,Decrement:1)
                }
                registers.PC = UpdateProgramCounter(CurrentPC:registers.PC,Offset:2)
            default:
                print("Unknown opcode "+String(format: "%02X", opcodes.opcode1)+String(format: "%02X", opcodes.opcode2) + " @ "+String(format:"%04X",registers.PC))
                registers.PC = UpdateProgramCounter(CurrentPC:registers.PC,Offset:2)
            }
        case 0xF2: // JP P,nn
            print("Executed JP P,nn @ "+String(format:"%04X",registers.PC))
            if (TestFlags(FlagRegister:registers.F,Flag:Z80Flags.Sign))
            {
                registers.PC = UpdateProgramCounter(CurrentPC:registers.PC,Offset:3)
            }
            else
            {
                registers.PC = UInt16(opcodes.opcode3) << 8 | UInt16(opcodes.opcode2)
            }
        case 0xFA: // JP M,nn
            print("Executed JP M,nn @ "+String(format:"%04X",registers.PC))
            if (TestFlags(FlagRegister:registers.F,Flag:Z80Flags.Sign))
            {
                registers.PC = UInt16(opcodes.opcode3) << 8 | UInt16(opcodes.opcode2)
            }
            else
            {
                registers.PC = UpdateProgramCounter(CurrentPC:registers.PC,Offset:3)
            }
        case 0xFE: // CP n
            print("Executed CP n @ "+String(format:"%04X",registers.PC) + " ["+String(format:"%02X",opcodes.opcode1)+","+String(format:"%02X",opcodes.opcode2)+"]")
//            sign: (res8 & 0x80) != 0,
//            zero: a == n,
//            halfCarry: ((a & 0x0F) < (n & 0x0F)),
//            parityOverflow: ((a ^ n) & (a ^ res8) & 0x80) != 0,
//            subtract: true,
//            carry: a < n
            let temporaryResult = registers.A &- opcodes.opcode2
            registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Sign,SetFlag:(temporaryResult & 0x80) != 0)
            registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Zero,SetFlag:temporaryResult == 0)
            registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Half_Carry,SetFlag:((registers.A & 0x0F) < (opcodes.opcode2 & 0x0F)))
            registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Parity_Overflow,SetFlag:((registers.A ^ opcodes.opcode2) & (registers.A ^ temporaryResult) & 0x80 ) != 0)
            registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Negative,SetFlag:true)
            registers.F = UpdateFlags(FlagRegister:registers.F,Flag:Z80Flags.Carry,SetFlag:registers.A < opcodes.opcode2)
            registers.PC = UpdateProgramCounter(CurrentPC:registers.PC,Offset:2)
        default:
            print("Unknown opcode "+String(format: "%02X", opcodes.opcode1) + " @ "+String(format:"%04X",registers.PC))
            registers.PC = UpdateProgramCounter(CurrentPC:registers.PC,Offset:1)
        }
        runcycles = runcycles+1
    }

    func getState() async -> CPUState
    {
        guard Int(registers.PC)+0x0ff < 0x10000
        else
        {
            return CPUState( PC: registers.PC,
                             SP: registers.SP,
                             BC : registers.BC,
                             DE : registers.DE,
                             HL : registers.HL,
                             AltBC : registers.AltBC,
                             AltDE : registers.AltDE,
                             AltHL : registers.AltHL,
                             IX : registers.IX,
                             IY : registers.IY,
                             I: registers.I,
                             R: registers.R,
                             A: registers.A,
                             F: registers.F,
                             B: registers.B,
                             C: registers.C,
                             D: registers.D,
                             E: registers.E,
                             H: registers.H,
                             L: registers.L,
                             AltA: registers.AltA,
                             AltF: registers.AltF,
                             AltB: registers.AltB,
                             AltC: registers.AltC,
                             AltD: registers.AltD,
                             AltE: registers.AltE,
                             AltH: registers.AltH,
                             AltL: registers.AltL,
                             memoryDump: Array(AddressSpace.memory[Int(registers.PC)..<0xffff]),
                             VDU : VDURAM.memory.map { Float($0) },
                             CharRom : CharGenROM.memory.map { Float($0) },
                             
                             vmR1_HorizDisplayed : MOS6545.ReadRegister(RegNum: 1),
                             vmR6_VertDisplayed : MOS6545.ReadRegister(RegNum: 6),
                             vmR9_ScanLinesMinus1 : MOS6545.ReadRegister(RegNum: 9),
                             vmR10_CursorStartAndBlinkMode : MOS6545.ReadRegister(RegNum: 10),
                             vmR11_CursorEnd : MOS6545.ReadRegister(RegNum: 11),
                             vmR12_DisplayStartAddrH : MOS6545.ReadRegister(RegNum: 12),
                             vmR13_DisplayStartAddrL : MOS6545.ReadRegister(RegNum: 13),
                             vmR14_CursorPositionH : MOS6545.ReadRegister(RegNum: 14),
                             vmR15_CursorPositionL : MOS6545.ReadRegister(RegNum: 15),
                             vmCursorBlinkCounter: MOS6545.crtcRegisters.CursorBlinkCounter,
                             vmCursorFlashLimit: MOS6545.crtcRegisters.CursorFlashLimit
            )
        }
        return CPUState( PC: registers.PC,
                         SP: registers.SP,
                         BC : registers.BC,
                         DE : registers.DE,
                         HL : registers.HL,
                         AltBC : registers.AltBC,
                         AltDE : registers.AltDE,
                         AltHL : registers.AltHL,
                         IX : registers.IX,
                         IY : registers.IY,
                         I: registers.I,
                         R: registers.R,
                         A: registers.A,
                         F: registers.F,
                         B: registers.B,
                         C: registers.C,
                         D: registers.D,
                         E: registers.E,
                         H: registers.H,
                         L: registers.L,
                         AltA: registers.AltA,
                         AltF: registers.AltF,
                         AltB: registers.AltB,
                         AltC: registers.AltC,
                         AltD: registers.AltD,
                         AltE: registers.AltE,
                         AltH: registers.AltH,
                         AltL: registers.AltL,
                         
                         memoryDump: Array(AddressSpace.memory[Int(registers.PC)..<Int(registers.PC)+0x0ff]),
                         VDU : VDURAM.memory.map { Float($0) },
                         CharRom : CharGenROM.memory.map { Float($0) },
        
                         vmR1_HorizDisplayed : MOS6545.ReadRegister(RegNum: 1),
                         vmR6_VertDisplayed : MOS6545.ReadRegister(RegNum: 6),
                         vmR9_ScanLinesMinus1 : MOS6545.ReadRegister(RegNum: 9),
                         vmR10_CursorStartAndBlinkMode : MOS6545.ReadRegister(RegNum: 10),
                         vmR11_CursorEnd : MOS6545.ReadRegister(RegNum: 11),
                         vmR12_DisplayStartAddrH : MOS6545.ReadRegister(RegNum: 12),
                         vmR13_DisplayStartAddrL : MOS6545.ReadRegister(RegNum: 13),
                         vmR14_CursorPositionH : MOS6545.ReadRegister(RegNum: 14),
                         vmR15_CursorPositionL : MOS6545.ReadRegister(RegNum: 15),
                         vmCursorBlinkCounter: MOS6545.crtcRegisters.CursorBlinkCounter,
                         vmCursorFlashLimit: MOS6545.crtcRegisters.CursorFlashLimit,
        )
    }
}

