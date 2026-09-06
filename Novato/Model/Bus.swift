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
    
    //    PORT B DATA PORT BIT ASSIGNMENTS
    //    bit 0 Cassette data in
    //    bit 1 Cassette data out
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
        
        var statusRegister : UInt8 = 0b10000000             // Status registers Bit 7 is required to be intially set.  but how is it turned off ?
        
        var redBackgroundIntensity : UInt8 = 0x00           // red background intensity 0 = half 1 = full
        var greenBackgroundIntensity : UInt8 = 0x00         // green background intensity 0 = half 1 = full
        var blueBackgroundIntensity : UInt8 = 0x00          // blue background intensity 0 = half 1 = full
        
    }
    
    var registers = crtcRegisters()
    
    var characterClock : UInt8 = 0
    
    let tStatesPerCharacterClock = 2                        // 3.375Mhz divide by 1.6875 Mhz.  Make this speed independent later
    
    var columnCounter : UInt8 = 0
    var rowCounter : UInt8 = 0
    
    var scanlineCounter : UInt8 = 0
       
    var displayEnable : Bool = false
    
    var verticalAdjustCounter : UInt8 = 0
    var inVerticalAdjust : Bool = false

    var verticalBlank : Bool = false
    
    var frameComplete : Bool = false
    
    var lightPenReady : Bool = false
    
    var updateReady : Bool = false
    
    var lightPenAddress : UInt64 = 0
    
    let verticalBlankingMask : UInt8 = 0x20
    
    var keyboardScanPosition : UInt8 = 0
    
    var romReadLatch : Bool = false
    
    var triggerKeyScan : Bool = false
    
    private let keyboard: MicrobeeKeyboard
    
    init(keyboard: MicrobeeKeyboard)
    {
        self.keyboard = keyboard
    }
    
    func readStatusRegister() -> UInt8
    {
        var tempStatus : UInt8 = registers.statusRegister
        
        if verticalBlank
        {
            tempStatus = tempStatus | verticalBlankingMask
        }
 
        return tempStatus
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
        case 16: registers.R16 = RegValue
        case 17: registers.R17 = RegValue
        case 18: registers.R18 = RegValue
        case 19: registers.R19 = RegValue
        case 31:
            registers.statusRegister = registers.statusRegister & 0x7F
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
        case 13: return readStatusRegister()
        case 14: return registers.R14
        case 15: return registers.R15
        case 16:
            registers.statusRegister = registers.statusRegister & ~0x40
            lightPenReady = false
            return registers.R16
        case 17:
            registers.statusRegister = registers.statusRegister & ~0x40
            lightPenReady = false
            return registers.R17
        case 18: return registers.R18
        case 19: return registers.R19
        case 31:
            registers.statusRegister = registers.statusRegister & 0x7F
            return 0
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

        verticalBlank = false
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
            verticalBlank = true
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

            if keyboardScanPosition == 64
            {
                    keyboardScanPosition = 0
            }
        }
        
        if columnCounter >= registers.R0
        {
            columnCounter = 0
            endScanline()
        }
    }
    
    func scanForKey()
    { 
        let address = (UInt16(registers.R18) << 8) | UInt16(registers.R19)

        let position = Int((address >> 4) & 0x3F)

        let mask = UInt64(1) << UInt64(position)

        let pressed = (keyboard.keyMatrix & mask) != 0

        if pressed
        {
          registers.R16 = UInt8((address >> 8) & 0xFF)

          registers.R17 = UInt8(address & 0xFF)

          registers.statusRegister = registers.statusRegister | 0x40
          
          lightPenReady = true
        }
        
        registers.statusRegister = registers.statusRegister | 0x80
    }
    
    func checkKeyboard(position: UInt8)
    {
        guard !romReadLatch
        else
        {
            return
        }
        
        guard !lightPenReady
        else
        {
            return
        }
        
        let mask = UInt64(1) << UInt64(position)
        
        let pressed = (keyboard.keyMatrix & mask) != 0
        
        guard pressed
        else
        {
            return
        }
        
        registers.statusRegister = registers.statusRegister | 0x40
    
        registers.R16 = (position & 0x30) >> 4   // keypress loaded into bits 0..2 of R16 and bits 4..7 of R17
        registers.R17 = (position & 0x0F) << 4
        
            print("position", position)
            print("r16",registers.R16)
            print("r17",registers.R17)
        
        lightPenReady = true
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
        
        registers.statusRegister = 0b10000000
        
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

        verticalBlank = false
        
        frameComplete = false
        
        lightPenReady = false
        
        updateReady = false
        
        lightPenAddress = 0
    
        keyboardScanPosition = 0
    
        romReadLatch = false
    
        triggerKeyScan = false
    
    }
}

final class BUS
{
    var ports = IOPorts()
    let keyboard: MicrobeeKeyboard
    let crtc : CRTC
    var mmu = memoryMapper()
    
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
        netROM.fillMemoryFromFile(fileName: "telcom_1.0", fileExtension: "rom")
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
                    crtc.registers.greenBackgroundIntensity = 1 // set global background blue intensity to 1 = full
                }
                if portValue & 0x02 == 0x00
                {
                    crtc.registers.greenBackgroundIntensity = 0 // set global background blue intensity to 0 = half
                }
                if portValue & 0x04 == 0x04
                {
                    crtc.registers.blueBackgroundIntensity = 1 // set global background green intensity to 1 = full
                }
                if portValue & 0x04 == 0x00
                {
                    crtc.registers.blueBackgroundIntensity = 0 // set global background green intensity to 0 = half
                }
                if portValue & 0x40 == 0x40
                {
                    mmu.map(readDevice: colourRAM, writeDevice: colourRAM, memoryLocation: 0xF800)  // swap in colour ram
                }
                if portValue & 0x40 == 0x00
                {
                    mmu.map(readDevice: pcgRAM, writeDevice: pcgRAM, memoryLocation: 0xF800)        // swap in pcg ram
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
                    mmu.map(readDevice: pcgRAM, writeDevice: pcgRAM, memoryLocation: 0xF800)  // swap video ram and pcg ram back into memory at 0xf000 for read and wrtie
                }
            case 0x0C :
                crtc.writeRegister(RegNum: UInt8(realPort), RegValue: portValue)
            case 0x0D:
                let tempPort = ports.readPort(portNum: 0x0C)
                crtc.writeRegister(RegNum: tempPort, RegValue: portValue)
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
            case 0x0C:
                return crtc.readStatusRegister()
            case 0x0D:
                let tempPort = ports.readPort(portNum: 0x0C)
                return crtc.readRegister(RegNum: tempPort)
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

