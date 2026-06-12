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
                print("Problem loading ROM")
            }
        }
        else
        {
            print("Can't find ROM")
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
}

final class CRTC
{
    struct crtcRegisters
    {
        var R0 : UInt8 = 0x00                               // Ignored by emulator - Total length of line (displayed and non-displayed cycles (retrace) in CCLK cylces minus 1
        var R1 : UInt8 = 0x40                               // Number of characters displayed in a line - initialise as 64
        var R2 : UInt8 = 0x00                               // Ignored by emulator - The position of the horizontal sync pulse start in distance from line start
        var R3 : UInt8 = 0x00                               // Ignored by emulator
        var R4 : UInt8 = 0x12                               // The number of character lines of the screen minus 1 - initialise as 18
        var R5 : UInt8 = 0x00                               // Ignored by emulator - The additional number of scanlines to complete a screen
        var R6 : UInt8 = 0x10                               // Number character lines that are displayed - initialise as 16
        var R7 : UInt8 = 0x00                               // Ignored by emulator - Position of the vertical sync pulse in character lines.
        var R8 : UInt8 = 0x00                               // Ignored by emulator
        var R9 : UInt8 = 0x0F                               // Number of scanlines per character minus 1 - initialise as 15
        var R10 : UInt8 = 0x20                              // Cursor scanline start ( bits 0-4 ) and blink mode ( bits 5 and 6 )  - initialse as no cursor and scanline start of 0
        var R11 : UInt8 = 0x00                              // Cursor scanline end ( bits 0-4 ) - initialise as scanlin end of 0
        var R12 : UInt8 = 0x00                              // Character Generator Rom start address ( high byte )
        var R13 : UInt8 = 0x00                              // Character Generator Rom start address ( low byte )
        var R14 : UInt8 = 0x00                              // Cursor address ( high byte )
        var R15 : UInt8 = 0x00                              // Cursor address ( low byte )
        var R16 : UInt8 = 0x00                              // Ignored by emulator
        var R17 : UInt8 = 0x00                              // Ignored by emulator
        var R18 : UInt8 = 0x00                              // Ignored by emulator
        var R19 : UInt8 = 0x00                              // Ignored by emulator
        
        var statusRegister : UInt8 = 0b10000000
        
        var redBackgroundIntensity : UInt8 = 0x00                         // red background intensity 0 = half 1 = full
        var greenBackgroundIntensity : UInt8 = 0x00                       // green background intensity 0 = half 1 = full
        var blueBackgroundIntensity : UInt8 = 0x00                        // blue background intensity 0 = half 1 = full
        
    }
    
    var registers = crtcRegisters()
    
    func readStatusRegister() -> UInt8
    {
        return registers.statusRegister
    }
    
    func writeRegister(RegNum:UInt8, RegValue:UInt8)
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
        default: break
        }
    }
    
    func readRegister(RegNum:UInt8) -> UInt8
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
        case 16: return registers.R16
        case 17: return registers.R17
        case 18: return registers.R18
        case 19: return registers.R19
        default: return 0
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

final class BUS
{
    var ports = IOPorts()
    var crtc = CRTC()
    var mmu = memoryMapper()
    
    let mainRAM = memoryBlock(size: 0x8000)
    let basicROM = memoryBlock(size: 0x4000, deviceType : .ROM)
    let pakROM = memoryBlock(size: 0x2000, deviceType : .ROM)
    let netROM = memoryBlock(size: 0x1000, deviceType : .ROM)
    let videoRAM = memoryBlock(size: 0x800)
    let pcgRAM = memoryBlock(size: 0x800)
    let colourRAM = memoryBlock(size: 0x800)
    let fontROM = memoryBlock(size: 0x1000, deviceType : .ROM)
    
    let testRAM = memoryBlock(size:0x10000)
    
    init()
    {
        mmu.map(readDevice: mainRAM, writeDevice: mainRAM, memoryLocation: 0x0000)       // 32K System RAM
        mmu.map(readDevice: basicROM, writeDevice: basicROM, memoryLocation: 0x8000)     // 16K BASIC ROM
        mmu.map(readDevice: pakROM, writeDevice: pakROM , memoryLocation: 0xC000)        // 8K Optional ROM
        mmu.map(readDevice: netROM, writeDevice: netROM, memoryLocation: 0xE000)         // 4K Net ROM
        mmu.map(readDevice: videoRAM, writeDevice: videoRAM, memoryLocation: 0xF000)     // 2K Video RAM
        mmu.map(readDevice: pcgRAM, writeDevice: pcgRAM, memoryLocation: 0xF800)         // 2K PCG RAM
        
        basicROM.fillMemoryFromFile(fileName: "basic_5.22e", fileExtension: "rom")
//        pakROM.fillMemoryFromFile(fileName: "wordbee_1.2", fileExtension: "rom")
//        netROM.fillMemoryFromFile(fileName: "telcom_1.0", fileExtension: "rom")
        fontROM.fillMemoryFromFile(fileName: "charrom", fileExtension: "bin")
        
        mainRAM.fillMemoryFromFile(fileName: "demo", fileExtension: "bin", memOffset: 0x900)
    }
    
    @inline(__always)
    func writePort(portNum : UInt16, portValue : UInt8)
    {
        let realPort = Int(portNum & 0x00FF)
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
                   mmu.map(readDevice: fontROM, writeDevice: nil, memoryLocation: 0xF000)     // swap in font rom to 0xf000 for reading whilst still allowing writing to video ram and pcg ram
               }
               if portValue & 0x01 == 0
               {
                   mmu.map(readDevice: videoRAM, writeDevice: videoRAM, memoryLocation: 0xF000)  // swap in font rom to 0xf000 for reading whilst still allowing writing to video ram and pcg ram
                   mmu.map(readDevice: pcgRAM, writeDevice: pcgRAM, memoryLocation: 0xF800)  // swap video ram and pcg ram back into memory at 0xf000 for read and wrtie
               }
            case 0x0D: crtc.writeRegister(RegNum: ports.readPort(portNum: 0x000C), RegValue: portValue)
            default: break // other ports go here
        }
        ports.writePort(portNum : realPort, portValue : portValue)
    }
    
    @inline(__always)
    func readPort(portNum : UInt16) -> UInt8
    {
        var tempValue : UInt8 = 0
        let realPort = Int(portNum & 0x00FF)
        
        switch realPort
        {
            case 0x0C: tempValue = crtc.readStatusRegister()
            case 0x0D: tempValue = crtc.readRegister(RegNum:ports.readPort(portNum: 0x000C))
            default: tempValue = ports.readPort(portNum : realPort) // other ports go here
        }
        return tempValue
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
    func writeRegister(RegNum : UInt8, RegValue : UInt8)
    {
        crtc.writeRegister(RegNum : RegNum , RegValue : RegValue)
    }
    
    @inline(__always)
    func readRegister(RegNum : UInt8) -> UInt8
    {
        return crtc.readRegister(RegNum : RegNum)
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
}

