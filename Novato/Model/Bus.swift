import Foundation

enum memoryDeviceType: CaseIterable
{
    case ROM
    case RAM
}

enum memoryConstant
{
    static let memorySize = 0x10000
    static let pageSize = 0x800
    static let pageCount = memorySize/pageSize
    static let pageShift = pageSize.trailingZeroBitCount
    static let pageMask = pageSize - 1
}

final class memoryBlock
{
    var addressBlock: ContiguousArray<UInt8>
    let size: Int
    let deviceType : memoryDeviceType
    
    init(size: UInt, deviceType: memoryDeviceType = .RAM, fillValue: UInt8 = 0)
    {
        let clampedSize = min((Int(size) + memoryConstant.pageMask) & ~memoryConstant.pageMask,memoryConstant.memorySize)
        self.size = Int(clampedSize)
        self.deviceType  = deviceType
        self.addressBlock = ContiguousArray(repeating: fillValue, count: clampedSize)
    }
    
    func fillMemory(memValue: UInt8)
    {
        for counter in addressBlock.indices
        {
            addressBlock[counter] = memValue
        }
    }
    
    func fillMemoryFromArray(memValues: [UInt8], memOffset : UInt16 = 0)
    {
        let count = min(memValues.count, size)
        addressBlock.replaceSubrange(Int(memOffset)..<Int(memOffset)+count, with: memValues[0..<count])
    }
    
    func fillMemoryFromFile(fileName: String, fileExtension: String, memOffset : UInt16 = 0)
    {
        var LoadCounter : Int = Int(memOffset)
        
        if let urlPath = Bundle.main.url(forResource: fileName, withExtension: fileExtension )
        {
            do {
                let fileContents = try Data(contentsOf: urlPath)
                for fileValue in fileContents
                {
                    guard LoadCounter < size else { break }
                    addressBlock[LoadCounter] = UInt8(fileValue)
                    LoadCounter = LoadCounter + 1
                }
            }
            catch
            {
                print("Problem loading ROM "+fileName+"."+fileExtension)
            }
        }
        else
        {
            print("Can't find ROM "+fileName+"."+fileExtension)
        }
    }
    
    func bufferTransform() -> [Float]
    {
        return addressBlock.map { Float($0) }
    }
}

final class memoryMapper
{
    private var readPages: ContiguousArray<memoryBlock>
    private var writePages: ContiguousArray<memoryBlock>
    private var readOffset: ContiguousArray<Int>
    private var writeOffset: ContiguousArray<Int>
    
    init()
    {
        let emptyBlock = memoryBlock(size: UInt(memoryConstant.pageSize), deviceType: .ROM, fillValue: 0xFF)
        self.readPages = ContiguousArray(repeating: emptyBlock,count: memoryConstant.pageCount)
        self.writePages = ContiguousArray(repeating: emptyBlock, count: memoryConstant.pageCount)
        self.readOffset = ContiguousArray(repeating: 0, count: memoryConstant.pageCount)
        self.writeOffset = ContiguousArray(repeating: 0, count: memoryConstant.pageCount)
        for counter in 0...31
        {
            self.readOffset[counter] = memoryConstant.pageSize*counter
            self.writeOffset[counter] = memoryConstant.pageSize*counter
        }
    }
    
    func map(readDevice: memoryBlock? = nil, writeDevice: memoryBlock? = nil, memoryLocation: UInt16)
    {
        let pageIndex = Int(memoryLocation) >> memoryConstant.pageShift
        
        if let unwrapReadDevice = readDevice
        {
            let endReadPage = (Int(memoryLocation)+unwrapReadDevice.size-1) >> memoryConstant.pageShift
            
            for counter in pageIndex...endReadPage
            {
                guard counter <= memoryConstant.pageCount-1 else { break }
                readPages[counter] = unwrapReadDevice
                readOffset[counter] = pageIndex << memoryConstant.pageShift
            }
        }
        
        if let unwrapWriteDevice = writeDevice
        {
            let endWritePage = (Int(memoryLocation)+unwrapWriteDevice.size-1) >> memoryConstant.pageShift
            
            for counter in pageIndex...endWritePage
            {
                guard counter <= memoryConstant.pageCount-1 else { break }
                writePages[counter] = unwrapWriteDevice
                writeOffset[counter] = pageIndex << memoryConstant.pageShift
            }
        }
    }
    
    func memorySlice(address: UInt16, size: UInt16) -> [UInt8]
    {
        var tempAddress: UInt16 = address
        var tempSlice: [UInt8] = []
        
        for _ in 0..<size
        {
            tempSlice.append(readByte(address: tempAddress))
            tempAddress = tempAddress &+ 1
        }
        return tempSlice
    }
    
    @inline(__always)
    func readByte(address: UInt16) -> UInt8
    {
        let pageIndex = Int(address) >> memoryConstant.pageShift
        let pageOffset = Int(address)-readOffset[pageIndex]
        
        return readPages[pageIndex].addressBlock[pageOffset]
    }
    
    @inline(__always)
    func writeByte(address: UInt16, value: UInt8)
    {
        let pageIndex = Int(address) >> memoryConstant.pageShift
        let pageOffset = Int(address)-writeOffset[pageIndex]
        
        guard writePages[pageIndex].deviceType == .RAM else { return }
        
        writePages[pageIndex].addressBlock[pageOffset] = value
    }
    
    func returnCurrentRAM() -> ContiguousArray<UInt8>
    {
        var tempRAM: ContiguousArray<UInt8> = []
        for counter in 0..<readPages.count
        {
            tempRAM.append(contentsOf: readPages[counter].addressBlock)
        }
        return tempRAM
    }
    
    func quickLoad(path: URL, loadAddress: UInt16)
    {
        var memoryAddress : UInt16 = loadAddress
        
        guard path.startAccessingSecurityScopedResource()
        else
        {
            print("Unable to access \(path)")
            return
        }
        
        defer
        {
            path.stopAccessingSecurityScopedResource()
        }

        do
        {
            let fileContents = try Data(contentsOf: path)
            for fileValue in fileContents
            {
                writeByte(address: memoryAddress, value: fileValue)
                memoryAddress = memoryAddress &+ 1
            }
        }
        
        catch
        {
            print(error)
            print("Problem loading binary "+path.absoluteString)
        }
    }
}

final class IOPorts
{
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

    //    1C Premimum PCG bank switching
    //    50 128K Bank Switching
    
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
    //    bit 2 GREEN backgroung intensity (1 = full)
    //    bit 3 BLUE background intensity (1 = full)
    //    bit 6 COLOUR RAM enable (0 = PCG, 1 = RAM)
    
    var ports = [UInt8](repeating: 0, count: 256)
    
    func writePort(portNum : Int, portValue : UInt8)
    {
        ports[portNum] = portValue
    }
    
    func readPort(portNum : Int) -> UInt8
    {
        return ports[portNum]
    }
    
    func resetPorts()
    
    {
        ports = ports.map { _ in 0 }
    }
    
    func returnPorts() -> [UInt8]
    {
        return ports
    }
}

enum pioModeControl : UInt8
{
  case byteInput = 0, byteOutput, bidirectonal, bitControl
}

enum pioSignal
{
    case activeLow, activeHigh
}

enum pioMaskState
{
    case anyUnmasked, allUnmasked
}

enum pioPortTarget
{
    case portA, portB
}

final class PIO
{
//    The Z80 PIO has one control register per port, but it accepts several kinds of byte. The chip tells them apart by the bit pattern, or by what the previous byte asked for.
//
//    How the chip decodes a control write
//
//    If the previous byte asked for a mask, this byte is that mask, whatever its value.
//    Otherwise, if bit 0 is 0, it's an interrupt vector.
//    Otherwise, the low four bits pick the word type: 1111 is mode, 0111 is interrupt control, 0011 is interrupt enable/disable.
//
//    That's the order my writeControl uses.
//
//    The word types
//
//    Word                          Bit pattern                 Purpose
//    Interrupt vector              V7 V6 V5 V4 V3 V2 V1 0      Vector the port supplies on interrupt acknowledge. Bit 0 is always 0.
//    Mode                          M1 M0 x  x  1  1  1  1      Selects the mode. Bits 5 and 4 are ignored.
//    I/O mask                      I7 I6 I5 I4 I3 I2 I1 I0     Mode 3 only. For each bit, 1 = input and 0 = output.
//    Interrupt control             En AO HL MF 0  1  1  1      Sets the interrupt behavior (fields below).
//    Interrupt mask                M7 M6 M5 M4 M3 M2 M1 M0     Mode 3 only. For each bit, 0 = monitored and 1 = masked off.
//    Interrupt enable/disable      En x  x  x  0  0  1  1      Enables or disables interrupts without changing anything else.
//
//    Mode word (bits 7-6)
//
//    M1 M0    Mode
//    00        0, output
//    01        1, input
//    10        2, bidirectional (Port A only)
//    11        3, bit control
//
//    Selecting mode 3 makes the next control byte the I/O mask.
//
//    Interrupt control word fields
//
//    Bit       Name    Meaning
//    7         En      1 = interrupts enabled
//    6         AO      1 = AND (every monitored bit must be active), 0 = OR (any one is enough)
//    5         HL      1 = active high, 0 = active low
//    4         MF      1 = a mask byte follows
//    3-0               0111, identifies this word
//
//    Bits 6 and 5 only matter in mode 3. If bit 4 is set, the next byte is the interrupt mask.
//
//    Examples
//
//    Byte    Meaning
//    0x0F    Mode 0 (output)
//    0x4F    Mode 1 (input)
//    0xCF    Mode 3, followed by an I/O mask byte
//    0x99    If it follows a mode 3 word, it's the I/O mask (the Port B inputs we worked out). Otherwise bit 0 is 1, and the low nibble 1001 matches no word, so it would be ignored.
//    0x42    Interrupt vector 0x42 (bit 0 is 0)
//    0x97    Interrupts enabled, OR logic, active low, mask follows
//    0x03    Interrupts disabled
//    0x83    Interrupts enabled
//
//    Two things that catch people out
//
//    The two follow-up bytes (I/O mask and interrupt mask) have no marker of their own. A stray byte in the wrong place gets misread, so always send the mask immediately after the word that requests it.
//    The polarity of the two masks is opposite. In the I/O mask, 1 means input. In the interrupt mask, 1 means ignore this bit.
    
    var input: UInt8 = 0
    var output: UInt8 = 0
    var ioMask: UInt8 = 0
    var interruptMask: UInt8 = 0
    
    var modeControl: pioModeControl = .byteInput
    var maskControl: pioMaskState = .anyUnmasked
    var signalControl: pioSignal =  .activeLow
     
    var ready: Bool = false
    var strobe: Bool = false
    
    var interruptsEnabled: Bool = false
    
    var interruptVector: UInt8 = 0

    var pendingIOMask : Bool = false
    var pendingInterruptMask : Bool = false
    
    var isPortA : Bool = false
    
    init(pioPort: pioPortTarget)
    {
        if pioPort == .portA
        {
            self.isPortA = true
        }
    }
    
    func reset()
    {
        input = 0
        output = 0
        ioMask = 0

        modeControl = .byteInput
        maskControl = .anyUnmasked
        signalControl =  .activeLow
        
        ready = false
        strobe = false
        
        interruptsEnabled = false
        
        interruptVector = 0
        interruptMask = 0
        
        pendingIOMask = false
        pendingInterruptMask = false
        
        isPortA = false
    }
    
    func writeData(portValue: UInt8)
    {
        output = portValue
        if modeControl == .byteOutput || modeControl == .bidirectonal
        {
            ready = true
        }
    }
    
    func writeControl(portValue: UInt8)
    {
        if pendingIOMask  // waiting on I/O mask
        {
            ioMask = portValue
            pendingIOMask = false
        }
        else if pendingInterruptMask // waiting on interrupt mask
            {
                interruptMask = portValue
                pendingInterruptMask = false
            }
            else if portValue & 0x01 == 0x00  // bit 0 == 0 means set interrupt vector
                {
                    interruptVector = portValue
                }
                else if portValue & 0x0f == 0x0f  // lower nibble == 1111 means set mode
                    {
                        switch portValue >> 6
                        {
                        case 0x00: modeControl = .byteOutput
                        case 0x01: modeControl = .byteInput
                        case 0x02: if isPortA { modeControl = .bidirectonal }
                        case 0x03:
                            modeControl = .bitControl
                            pendingIOMask = true
                        default: break
                        }
                    }
                    else if portValue & 0x07 == 0x07  // lower nibble == 0111 means set interrupt control
                    {
                        if portValue & 0x80 == 0x80
                        {
                            interruptsEnabled = true
                        }
                        if portValue & 0x80 == 0x00
                        {
                            interruptsEnabled = false
                        }
                        if portValue & 0x40 == 0x40
                        {
                            maskControl = .allUnmasked
                        }
                        if portValue & 0x40 == 0x00
                        {
                            maskControl = .anyUnmasked
                        }
                        if portValue & 0x20 == 0x20
                        {
                            signalControl = .activeHigh
                        }
                        if portValue & 0x20 == 0x00
                        {
                            signalControl = .activeLow
                        }
                        if portValue & 0x10 == 0x10
                        {
                            pendingInterruptMask = true
                        }
                    }
                    else if portValue & 0x03 == 0x03  // lower nibble == 0011 means set interrupt enable/disable
                    {
                        if portValue & 0x80 == 0x80
                        {
                            interruptsEnabled = true
                        }
                        if portValue & 0x80 == 0x00
                        {
                            interruptsEnabled = false
                        }
                    }
    }
    
    func readData() -> UInt8
    {
        switch modeControl
        {
        case .byteInput, .bidirectonal:
            ready = true
            return input
        case .byteOutput:
           return output
        case .bitControl:
            return 0xff  // not correct.  implement (pins & ioMask) | (output & ~ioMask)
        }
    }
}

final class z80PIO
{
    //    00 or 10 PIO port A data port
    //    01 or 11 PIO port A control port
    //    02 or 12 PIO port B data port
    //    03 or 13 PIO port B control port

    //    PORT B DATA PORT BIT ASSIGNMENTS
    //    bit 0 Cassette data in
    //    bit 1 Cassette data out
    //    bit 2 RS232 CLOCK or DTR line
    //    bit 3 RS232 CTS line (0-> clear to send)
    //    bit 4 RS232 input (0 = mark)
    //    bit 5 RS232 output (1 = mark)
    //    bit 6 Speaker bit (1 = on)
    //    bit 7 Network interrupt bit
    
    let pioA = PIO(pioPort: .portA)
    let pioB = PIO(pioPort: .portB)
    
    init()
    {
        reset()
    }
    
    func reset()
    {
        pioA.reset()
        pioB.reset()
    }
    
    func writeData(portNum: UInt8, portValue: UInt8)
    {
        if portNum == 0x00
        {
            pioA.writeData(portValue: portValue)        // Port A
        }
        else
        {
            pioB.writeData(portValue: portValue)        // Port B
        }
    }
    
    func writeControl(portNum: UInt8, portValue: UInt8)
    {
        if portNum == 0x01
        {
            pioA.writeControl(portValue: portValue)     // Port A
        }
        else
        {
            pioA.writeControl(portValue: portValue)     // Port B
        }
    }
    
    func readData(portNum: UInt8) -> UInt8
    {
        var pioResult : UInt8 = 0xff
        
        if portNum == 0x00
        {
            pioResult = pioA.readData()                 // Port A
        }
        else
        {
            pioResult = pioB.readData()                 // Port B
        }
        return pioResult
    }
}

final class CRTC
{
    struct crtcRegisters
    {
        // initialise as 64x16
        
        var R0 : UInt8 = 0x6B                               // Horizontal Total-1 : Total length of line (displayed and non-displayed) in CCLK cylces minus 1
        var R1 : UInt8 = 0x40                               // Horizontal Displayed : number of characters displayed in a line
        var R2 : UInt8 = 0x51                               // Horizontal Sync Position : The position of the horizontal sync pulse start in distance from line start
        var R3 : UInt8 = 0x37                               // Sync Width : lower 4 bits are width of hsync pulse in character clock periods, upper 4 bits are width of vsync pulse in character clock periods
        var R4 : UInt8 = 0x12                               // Vertical Total-1 : The number of character lines of the screen minus 1
        var R5 : UInt8 = 0x09                               // Vertical Total Adjust : The additional number of scanlines to complete a screen
        var R6 : UInt8 = 0x10                               // Vertical Displayed : Number character lines that are displayed
        var R7 : UInt8 = 0x00                               // Vert Sync Position : Position of the vertical sync pulse in character lines
        var R8 : UInt8 = 0x48                               // Mode Control : ignored by emulator at this point
        var R9 : UInt8 = 0x0F                               // Scan Lines-1 : Number of scanlines per character minus 1
        var R10 : UInt8 = 0x20                              // Cursor Start : Cursor scanline start ( bits 0-4 ) and blink mode ( bits 5 and 6 )  - initialse as no cursor and scanline start of 0
        var R11 : UInt8 = 0x00                              // Cursor End : Cursor scanline end ( bits 0-4 ) - initialise as scanlin end of 0
        var R12 : UInt8 = 0x00                              // Display Start Address ( high byte ) :  6 bits  - bit 5 switches in 80x24 font - clamped to 3 bits inside the shader so R12/R13 offset address is 0x0000-0x7FF
        var R13 : UInt8 = 0x00                              // Display Start Address ( low byte ) : 8 bits
        var R14 : UInt8 = 0x00                              // Cursor Position ( high byte ) : 6 bits - clamped to 3 bits inside the shader so R14/R15 offset address is 0x0000-0x7FF
        var R15 : UInt8 = 0x00                              // Cursor Position ( low byte ) : 8 bits
        var R16 : UInt8 = 0x00                              // Light Pen Register ( high byte ) : 6 bits -
        var R17 : UInt8 = 0x00                              // Light Pen Register ( high byte ) : 8 bits
        var R18 : UInt8 = 0x00                              // Update Address Register ( high byte ) : 6 bits -
        var R19 : UInt8 = 0x00                              // Update Address Register ( low byte ) : 8 bits
        var R31 : UInt8 = 0x00                              // Dummy Location Register : when read or written to,  will
        
        var statusRegister : UInt8            // Status register.  Bit 7 is update strobe.  Goes low during R31 read. initially set high.  Bit 6 is light pen strobe.  Goes high if key is pressed.  bit 5 is vblank.  Goes high if in vertical blank
        {
            var status: UInt8 = 0

            if verticalBlank {
                status |= verticalBlankingMask
            }

            if lightPenReady {
                status |= lightPenReadyMask
            }

            if updateReady {
                status |= updateReadyMask
            }

            return status
        }
        
        let verticalBlankingMask : UInt8 = 0x20
        let lightPenReadyMask : UInt8 = 0x40
        let updateReadyMask : UInt8 = 0x80
        
        var redBackgroundIntensity : UInt8 = 0x00           // red background intensity 0 = half 1 = full
        var greenBackgroundIntensity : UInt8 = 0x00         // green background intensity 0 = half 1 = full
        var blueBackgroundIntensity : UInt8 = 0x00          // blue background intensity 0 = half 1 = full
        
        var verticalBlank : Bool = false
        var lightPenReady : Bool = false
        var updateReady : Bool = true
    }
    
    var logInstructions: Bool = false
    
    var registers = crtcRegisters()
    
    var characterClock : UInt8 = 0
    
    var tStatesPerCharacterClock : UInt8 = 2                        // 3.375Mhz divide by 1.6875 Mhz - Default value but can be changed if CPU multiplier changes
    
    var columnCounter : UInt8 = 0
    var rowCounter : UInt8 = 0
    
    var scanlineCounter : UInt8 = 0
       
    var displayEnable : Bool = false
    
    var verticalAdjustCounter : UInt8 = 0
    var inVerticalAdjust : Bool = false
    
    var frameComplete : Bool = false
    
    var lightPenAddress : UInt64 = 0
    
    var keyboardScanPosition : UInt8 = 0
    
    var romReadLatch : Bool = false
    
    private let keyboard: MicrobeeKeyboard
    
    init(keyboard: MicrobeeKeyboard)
    {
        self.keyboard = keyboard
    }
    
    func setCharacterClock(clockSpeedMultiplier: Double )
    {
        tStatesPerCharacterClock = UInt8((3.375*clockSpeedMultiplier)/1.6875)
    }
    
    func toggleLogging()
    
    {
        logInstructions.toggle( )
    }
    
    func readStatusRegister() -> UInt8
    {
        return registers.statusRegister
    }
    
    func writeRegister(RegNum: UInt8, RegValue: UInt8)
    {
        switch RegNum
        {
        case 0: registers.R0 = RegValue
        case 1: registers.R1 = RegValue
        case 2: registers.R2 = RegValue
        case 3: registers.R3 = RegValue
        case 4: registers.R4 = RegValue
        case 5: registers.R5 = RegValue
        case 6: registers.R6 = RegValue
        case 7: registers.R7 = RegValue
        case 8: registers.R8 = RegValue
        case 9: registers.R9 = RegValue
        case 10: registers.R10 = RegValue
        case 11: registers.R11 = RegValue
        case 12: registers.R12 = RegValue
        case 13: registers.R13 = RegValue
        case 14: registers.R14 = RegValue
        case 15: registers.R15 = RegValue
        case 16:
            registers.R16 = RegValue
        case 17:
            registers.R17 = RegValue
        case 18:
            registers.R18 = RegValue
        case 19:
            registers.R19 = RegValue
        case 31:
            registers.updateReady = false
            scanForKey()
            registers.R31 = RegValue
        default: break
        }
    }
    
    func readRegister(RegNum: UInt8) -> UInt8
    {
        switch RegNum
        {
        case 0: return registers.R0
        case 1: return registers.R1
        case 2: return registers.R2
        case 3: return registers.R3
        case 4: return registers.R4
        case 5: return registers.R5
        case 6: return registers.R6
        case 7: return registers.R7
        case 8: return registers.R8
        case 9: return registers.R9
        case 10: return registers.R10
        case 11: return registers.R11
        case 12: return registers.R12
        case 13: return registers.R13
        case 14: return registers.R14
        case 15: return registers.R15
        case 16:
            registers.lightPenReady = false
            return registers.R16
        case 17:
            registers.lightPenReady = false
            return registers.R17
        case 18:
            return registers.R18
        case 19:
            return registers.R19
        case 31:  // never called as far as I can tell
            registers.updateReady = false
            scanForKey()
            return registers.R31
        default: return 0
        }
    }
    
    func startNewFrame()
    {
        columnCounter = 0
        rowCounter = 0
        scanlineCounter = 0

        verticalAdjustCounter = 0
        inVerticalAdjust = false

        registers.verticalBlank = false
        frameComplete = true
    }
    
    func endScanline()
    {
        if inVerticalAdjust
        {
           verticalAdjustCounter = verticalAdjustCounter + 1

           if verticalAdjustCounter >= registers.R5
           {
               startNewFrame()
           }

           return
        }

        scanlineCounter = scanlineCounter + 1

        if scanlineCounter <= registers.R9
        {
           return
        }

        scanlineCounter = 0
        
        rowCounter = rowCounter + 1
        
        if rowCounter >= registers.R6
        {
            registers.verticalBlank = true
        }
        
        if rowCounter >= registers.R4 + 1
        {
            inVerticalAdjust = true
            verticalAdjustCounter = 0
        }
    }
    
    func tick(tStates: UInt8)
    {        
        characterClock = characterClock + tStates
        
        while characterClock >= tStatesPerCharacterClock
        {
            characterClock = characterClock - 2
            columnCounter = columnCounter + 1
            
            checkKeyboard(position: keyboardScanPosition)

            keyboardScanPosition = keyboardScanPosition + 1

            if keyboardScanPosition > 63
            {
                keyboardScanPosition = 0
            }
        }
        
        if columnCounter > registers.R0
        {
            columnCounter = 0
            endScanline()
        }
    }
    
    func scanForKey()
    {
        if !romReadLatch
        {
            return
        }
        
        let address = (UInt16(registers.R18) << 8) | UInt16(registers.R19)
    
        //print(" r18=",registers.R18," r19=",registers.R19," address=",address)
        

        let position = (address >> 4) & 0x3F
        
        if keyboard.isPressed(Int(position))
        {
            registers.R16 = UInt8((position & 0x30) >> 4)
            registers.R17 = UInt8((position & 0x0F) << 4)
            registers.lightPenReady = true
            print("keyboard pressed r16=",registers.R16," r17=",registers.R17," r18=",registers.R18," r19=",registers.R19," position=",position," address=",address," lightpenready=",registers.lightPenReady)
        }

        registers.updateReady = true
    }
    
    func checkKeyboard(position: UInt8)
    {
        if romReadLatch
        {
            return
        }
        
        if registers.lightPenReady
        {
            return
        }
            
        if keyboard.isPressed(Int(position))
        {
            registers.R16 = (position & 0x30) >> 4
            registers.R17 = (position & 0x0F) << 4
        
            registers.lightPenReady = true
        }
    }
    
    func reset()
    {
        registers.R0 = 0x6B
        registers.R1 = 0x40
        registers.R2 = 0x51
        registers.R3 = 0x37
        registers.R4 = 0x12
        registers.R5 = 0x09
        registers.R6 = 0x10
        registers.R7 = 0x00
        registers.R8 = 0x48
        registers.R9 = 0x0F
        registers.R10 = 0x20
        registers.R11 = 0x00
        registers.R12 = 0x00
        registers.R13 = 0x00
        registers.R14 = 0x00
        registers.R15 = 0x00
        registers.R16 = 0x00
        registers.R17 = 0x00
        registers.R18 = 0x00
        registers.R19 = 0x00
        registers.R31 = 0x00

        registers.redBackgroundIntensity = 0x00
        registers.greenBackgroundIntensity = 0x00
        registers.blueBackgroundIntensity = 0x00
     
        characterClock = 0
        
        columnCounter = 0
        rowCounter = 0
        
        scanlineCounter = 0
           
        displayEnable = false
        
        verticalAdjustCounter = 0
        inVerticalAdjust = false
        frameComplete = false
        
        registers.verticalBlank = false
        registers.lightPenReady = false
        registers.updateReady = true
        
        keyboardScanPosition = 0
    
        romReadLatch = false
        
        keyboard.releaseAll()

    }
}

final class BUS
{
    let ports = IOPorts()
    let keyboard: MicrobeeKeyboard
    let crtc : CRTC
    let mmu = memoryMapper()
    let pio = z80PIO()
    
    var underTest : Bool = false
    
    let mainRAM = memoryBlock(size: 0x8000)
    let basicROM = memoryBlock(size: 0x4000, deviceType : .ROM)
    let pakROM = memoryBlock(size: 0x2000, deviceType : .ROM)
    let netROM = memoryBlock(size: 0x1000, deviceType : .ROM)
    let videoRAM = memoryBlock(size: 0x800, fillValue: 0x20)
    let pcgRAM = memoryBlock(size: 0x800)
    let colourRAM = memoryBlock(size: 0x800, fillValue: 0x02)
    let fontROM = memoryBlock(size: 0x1000, deviceType : .ROM)
    
    let testRAM = memoryBlock(size:0x10000)
    
    init(keyboard: MicrobeeKeyboard)
    {
        self.keyboard = keyboard
        self.crtc = CRTC(keyboard: keyboard)
            
        mmu.map(readDevice: mainRAM, writeDevice: mainRAM, memoryLocation: 0x0000)       // 32K System RAM
        mmu.map(readDevice: basicROM, writeDevice: basicROM, memoryLocation: 0x8000)     // 16K BASIC ROM
        mmu.map(readDevice: pakROM, writeDevice: pakROM , memoryLocation: 0xC000)        // 8K Optional ROM
        mmu.map(readDevice: netROM, writeDevice: netROM, memoryLocation: 0xE000)         // 4K Net ROM
        mmu.map(readDevice: videoRAM, writeDevice: videoRAM, memoryLocation: 0xF000)     // 2K Video RAM
        mmu.map(readDevice: pcgRAM, writeDevice: pcgRAM, memoryLocation: 0xF800)         // 2K PCG RAM
        
        basicROM.fillMemoryFromFile(fileName: "basic_5.22e", fileExtension: "rom")
        pakROM.fillMemoryFromFile(fileName: "wordbee_1.2", fileExtension: "rom")
        //pakROM.fillMemoryFromFile(fileName: "mytek_wordprocessor", fileExtension: "rom")
        netROM.fillMemoryFromFile(fileName: "telcom_1.2", fileExtension: "rom")
        fontROM.fillMemoryFromFile(fileName: "charrom", fileExtension: "bin")

        mainRAM.fillMemoryFromArray(memValues: [0xff], memOffset: 0x99)   // 0xff means this is a colour microbee.  Required here to force basic to clear colour ram
    }
    
    @inline(__always)
    func writePort(portNum : UInt16, portValue : UInt8)
    {
        let realPort = Int(portNum & 0x00FF)
        if underTest
        {
        }
        else
        {
            switch realPort
            {
            case 0x00,0x02: pio.writeData(portNum: UInt8(realPort), portValue: portValue)
            case 0x01,0x03: pio.writeControl(portNum: UInt8(realPort), portValue: portValue)
            case 0x08:
                if portValue & 0x01 == 0x01
                {
                    crtc.registers.redBackgroundIntensity = 1  // set global background red intensity to 1 = full
                }
                if portValue & 0x01 == 0x00
                {
                    crtc.registers.redBackgroundIntensity = 0 // set global background red intensity to 0 = half
                }
                if portValue & 0x02 == 0x02
                {
                    crtc.registers.greenBackgroundIntensity = 1 // set global background green intensity to 1 = full
                }
                if portValue & 0x02 == 0x00
                {
                    crtc.registers.greenBackgroundIntensity = 0 // set global background green intensity to 0 = half
                }
                if portValue & 0x04 == 0x04
                {
                    crtc.registers.blueBackgroundIntensity = 1 // set global background blue intensity to 1 = full
                }
                if portValue & 0x04 == 0x00
                {
                    crtc.registers.blueBackgroundIntensity = 0 // set global background blue intensity to 0 = half
                }
                if portValue & 0x40 == 0x40
                {
                    mmu.map(readDevice: colourRAM, writeDevice: colourRAM, memoryLocation: 0xF800)  // swap in colour ram
                   // print("Switch in Colour RAM. Setting port 8 to",ports.readPort(portNum : realPort))
                }
                if portValue & 0x40 == 0x00
                {
                    mmu.map(readDevice: pcgRAM, writeDevice: pcgRAM, memoryLocation: 0xF800)        // swap in pcg ram
                   // print("Switch in PCG RAM. Setting port 8 to",ports.readPort(portNum : realPort))
                }
            case 0x0B:
                if portValue & 0x01 == 1
                {
                    crtc.romReadLatch = true
                    mmu.map(readDevice: fontROM, writeDevice: nil, memoryLocation: 0xF000)     // swap in font rom to 0xf000 for reading whilst still allowing writing to video ram and pcg ram
                }
                if portValue & 0x01 == 0
                {
                    crtc.romReadLatch = false
                    mmu.map(readDevice: videoRAM, writeDevice: videoRAM, memoryLocation: 0xF000)  // swap in font rom to 0xf000 for reading whilst still allowing writing to video ram and pcg ram
                    mmu.map(readDevice: pcgRAM, writeDevice: pcgRAM, memoryLocation: 0xF800)  // swap video ram and pcg ram back into memory at 0xf000 for read and write
                }
            case 0x0D:
                let tempPort = ports.readPort(portNum: 0x0C)
                crtc.writeRegister(RegNum: tempPort, RegValue: portValue)
            case 0x1C: break
                // Premium PCG bankswitching goes here
                
                // To enable PCG RAM bank switching
                // LD A,10100nnn
                // OUT (0x1C),A
                
                // This selects bank nnn as the current bank
                
                // To enable attribute RAM bank switching
                // LD A,10110000
                // OUT (0x1C),A
                
                // To select the normal screen ram use
                // LD A,10100000
                // OUT (0x1C),A
            case 0x50: break
                // 128k bank switching.  All bits are set to zero upon power up or RESET.
                // Bit 5 ROM Select.
                // When low, ROM 2 (IC 2) is enabled from C000h to FFFFh, if bit 2 is also low. When high, ROM 3 (IC 1) is enabled from C000h to FFFFh, if bit 2 is also low.
                // Bit 4 VDU Address.
                // When low, the VDU RAM is enabled from F000h through to FFFFh. When high, it is enabled from 8000h through to 8FFFh.
                // Bit 3 VDU Enable.
                // VDU RAM is disabled. When low, the VDU RAM is enabled. When high, the VDU RAM is disabled.
                // Bit 2 ROM Enable.
                // When low, ROM 1 (IC 3) is enabled from 8000h to BFFFh, and either ROM 2 or ROM 3 is enabled from C000 to FFFFh depending upon the state of bit 5. When high, no ROMs appear in the memory map.
                // Bit 1,0 RAM Select.
                // These two bits select which 32k bank of RAM appears from 0000h to 7FFFh. Which banks are enabled depends upon the state of bit 2. The possible combinations are shown below.
                // Map port Value Selected Bank
                // Bit 1     Bit 0       Bit 2 low   Bit 2 high
                // 0         0 Bank      0 upper     Bank 0 lower
                // 0         1 Bank      1 upper     Bank 1 lower
                // 1         0 Bank      0 lower     Bank 0 higher*
                // 1         1 Bank      1 lower     Bank 1 higher
                // * _ this bank of RAM also appears from 8000h-FFFFh in this instance.
                // Notes.
                // 1. VDU RAM has precedence over both ROM and main system RAM. That is, VDU RAM will always appear in the desired location if enabled.
                // 2. When the ROMs are disabled, bank 0 upper appears from 8000h to FFFFh.
            default: break // other ports go here
            }
        }
        ports.writePort(portNum : realPort, portValue : portValue)
    }
    
    @inline(__always)
    func readPort(portNum : UInt16) -> UInt8
    {
        let realPort = Int(portNum & 0x00FF)
        
        if underTest
        {
            return ports.readPort(portNum : realPort)
        }
        else
        {
            switch realPort
            {
            case 0x00,0x02: return pio.readData(portNum: UInt8(realPort))
            case 0x01,0x03: return 0xff // PIO control reads apparently aren't defined
            case 0x08:
                //print("Port 8 is set to",ports.readPort(portNum : realPort))
                return ports.readPort(portNum : realPort)
            case 0x0C:
                return crtc.readStatusRegister()
            case 0x0D:
                let tempPort = ports.readPort(portNum: 0x0C)
                return crtc.readRegister(RegNum: tempPort)
            case 0x1C: return ports.readPort(portNum : realPort)
                // Premium PCG bankswitching goes here
                
                // To enable PCG RAM bank switching
                // LD A,10100nnn
                // OUT (0x1C),A
                                             
                // This selects bank nnn as the current bank
                
                // To enable attribute RAM bank switching
                // LD A,10110000
                // OUT (0x1C),A
                
                // To select the normal screen ram use
                // LD A,10100000
                // OUT (0x1C),A
            case 0x50: return ports.readPort(portNum : realPort)
                // 128k bank switching
                // 128k bank switching.  All bits are set to zero upon power up or RESET.
                // Bit 5 ROM Select.
                // When low, ROM 2 (IC 2) is enabled from C000h to FFFFh, if bit 2 is also low. When high, ROM 3 (IC 1) is enabled from C000h to FFFFh, if bit 2 is also low.
                // Bit 4 VDU Address.
                // When low, the VDU RAM is enabled from F000h through to FFFFh. When high, it is enabled from 8000h through to 8FFFh.
                // Bit 3 VDU Enable.
                // VDU RAM is disabled. When low, the VDU RAM is enabled. When high, the VDU RAM is disabled.
                // Bit 2 ROM Enable.
                // When low, ROM 1 (IC 3) is enabled from 8000h to BFFFh, and either ROM 2 or ROM 3 is enabled from C000 to FFFFh depending upon the state of bit 5. When high, no ROMs appear in the memory map.
                // Bit 1,0 RAM Select.
                // These two bits select which 32k bank of RAM appears from 0000h to 7FFFh. Which banks are enabled depends upon the state of bit 2. The possible combinations are shown below.
                // Map port Value Selected Bank
                // Bit 1     Bit 0       Bit 2 low   Bit 2 high
                // 0         0 Bank      0 upper     Bank 0 lower
                // 0         1 Bank      1 upper     Bank 1 lower
                // 1         0 Bank      0 lower     Bank 0 higher*
                // 1         1 Bank      1 lower     Bank 1 higher
                // * _ this bank of RAM also appears from 8000h-FFFFh in this instance.
                // Notes.
                // 1. VDU RAM has precedence over both ROM and main system RAM. That is, VDU RAM will always appear in the desired location if enabled.
                // 2. When the ROMs are disabled, bank 0 upper appears from 8000h to FFFFh.
            default:
                return ports.readPort(portNum : realPort) // other ports go here
            }
        }
    }
    
    @inline(__always)
    func resetPorts()
    {
        ports.resetPorts()
    }
    
    @inline(__always)
    func readStatusRegister() -> UInt8
    {
        return crtc.readStatusRegister()
    }
    
    @inline(__always)
    func map(readDevice: memoryBlock? = nil, writeDevice: memoryBlock? = nil, memoryLocation: UInt16)
    {
        mmu.map(readDevice: readDevice, writeDevice: writeDevice, memoryLocation: memoryLocation)
    }
    
    @inline(__always)
    func memorySlice(address: UInt16, size: UInt16) -> [UInt8]
    {
        return mmu.memorySlice(address: address, size: size)
    }
    
    @inline(__always)
    func readByte(address: UInt16) -> UInt8
    {
        return mmu.readByte(address: address)
    }
    
    @inline(__always)
    func writeByte(address: UInt16, value: UInt8)
    {
        mmu.writeByte(address: address, value: value)
    }
    
    @inline(__always)
    func returnCurrentRAM() -> ContiguousArray<UInt8>
    {
        return mmu.returnCurrentRAM()
    }
    
    func portTesting()
    {
      underTest = true
    }
    
    func quickLoad(path: URL, loadAddress: UInt16)
    {
        mmu.quickLoad(path: path, loadAddress: loadAddress)
    }
}
