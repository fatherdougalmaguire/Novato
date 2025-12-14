import Foundation

final class MMU
{
    var memory: [UInt8]
    
    init(MemorySize : Int, MemoryValue : UInt8)
    {
        memory = Array(repeating: MemoryValue, count: MemorySize)
    }
    
    func WriteMemory( MemoryAddress : UInt16, MemoryValue : UInt8 )
    {
        guard MemoryAddress <= 0xFFFF else { return }
        memory[Int(MemoryAddress)] = MemoryValue
    }
    
    func ReadMemory( MemoryAddress : UInt16 ) -> UInt8
    {
        guard MemoryAddress <= 0xFFFF else { return 0 }
        return memory[Int(MemoryAddress)]
    }
    
    func LoadMemoryFromArray ( MemoryAddress : UInt16, MemoryData : [UInt8] )
    {
        let start = Int(MemoryAddress)
        let maxIndex = min(memory.count, start + MemoryData.count)
        var loadCounter = start
        
        for byte in MemoryData {
            if loadCounter >= maxIndex { break }
            memory[loadCounter] = byte
            loadCounter += 1
        }
    }
    
    func LoadROM ( FileName : String,  FileExtension : String, MemoryAddress : UInt16 )
    {
        var LoadCounter : Int = Int(MemoryAddress)
        
        if let urlPath = Bundle.main.url(forResource: FileName, withExtension: FileExtension )
        {
            do {
                let contents = try Data(contentsOf: urlPath)
                for MyIndex in contents
                {
                    if LoadCounter >= memory.count { break }
                    memory[LoadCounter] = UInt8(MyIndex)
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
    
    func LoadFile ( FilePath : String, MemoryAddress : UInt16 ) // need to work out how to do this
    {
        var LoadCounter : Int = Int(MemoryAddress)
        
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsURL.appendingPathComponent(FilePath)
        
        do {
            let contents = try Data(contentsOf: fileURL)
            for MyIndex in contents {
                if LoadCounter >= memory.count { break }
                memory[LoadCounter] = UInt8(MyIndex)
                LoadCounter = LoadCounter + 1
            }
        }
        catch {
            print("Problem loading file: \(error)")
        }
    }
}

protocol MemoryDevice: AnyObject
{
    /// Reads a byte from a relative offset within the device.
    func read(at offset: Int) -> UInt8
    
    /// Writes a byte to a relative offset within the device.
    func write(_ value: UInt8, at offset: Int)
    
    /// The size of this memory block in bytes.
    var size: Int { get }
}

final class MemoryBlock: MemoryDevice
{
    private var data: ContiguousArray<UInt8>
    public let size: Int
    public let isReadOnly: Bool
    
    init(size: Int, readOnly: Bool = false) {
        self.size = size
        self.isReadOnly = readOnly
        // Securely initialize memory with zeros.
        self.data = ContiguousArray(repeating: 0, count: size)
    }
    
    func read(at offset: Int) -> UInt8 {
        // Safe bounds check. Returns 0xFF for out-of-bounds (OOB) reads.
        guard offset >= 0 && offset < data.count else {
            return 0xFF
        }
        return data[offset]
    }
    
    func write(_ value: UInt8, at offset: Int) {
        // Safe bounds check and prevents writing to Read-Only memory.
        guard !isReadOnly, offset >= 0 && offset < data.count else {
            return
        }
        data[offset] = value
    }
    
    /// Loads initial data (e.g., ROM dump) safely.
    func load(_ bytes: [UInt8]) {
        let countToCopy = min(bytes.count, size)
        data.replaceSubrange(0..<countToCopy, with: bytes[0..<countToCopy])
    }
}

final class MemoryMapper
{
    // Z80 Constants
    static let addressSpaceSize = 65536 // 64KB
    static let pageSize = 0x1000        // 4KB pages
    static let pageMask = 0x0FFF        // Mask for offset within a page (4095)
    static let pageCount = addressSpaceSize / pageSize // 16 pages
    
    /// Lightweight structure for a single page entry.
    private struct PageMapping {
        // 'weak' prevents retain cycles between the mapper and the device.
        weak var device: MemoryDevice?
        var offset: Int               // The starting offset into the device for this page
        var isWritable: Bool
        var label : String
    }
    
    private var pageTable: [PageMapping]
    
    init()
    {
        self.pageTable = Array(
            repeating: PageMapping(device: nil, offset: 0, isWritable: false, label: ""),
            count: MemoryMapper.pageCount
        )
    }
    
    func map(device: MemoryDevice, sourceOffset: Int, destinationStart: Int, length: Int, writable: Bool = true, label : String = "" )
    {
        
        let startPage = destinationStart / MemoryMapper.pageSize
        let endPage = (destinationStart + length - 1) / MemoryMapper.pageSize
        
        // Safety: Clamp page indices to the valid table size (0 to 15)
        let safeEndPage = min(endPage, MemoryMapper.pageCount - 1)
        
        for pageIndex in startPage...safeEndPage {
            let pageAddress = pageIndex * MemoryMapper.pageSize
            
            // Calculates the physical offset inside the device for the start of this page.
            let relativeOffset = pageAddress - destinationStart + sourceOffset
            
            pageTable[pageIndex] = PageMapping(
                device: device,
                offset: relativeOffset,
                isWritable: writable,
                label: label
            )
        }
    }
    
    @inline(__always)
    func readByte(_ address: UInt16) -> UInt8
    {
        let addr = Int(address)
        let pageIndex = addr / MemoryMapper.pageSize
        
        guard pageIndex < pageTable.count else { return 0xFF }
        
        let mapping = pageTable[pageIndex]
        
        // Calculate offset within the mapped 4KB page
        let localOffset = addr & MemoryMapper.pageMask
        let finalOffset = mapping.offset + localOffset
        
        // Delegate read to the concrete device (e.g., MemoryBlock, HardwareRegisters)
        return mapping.device?.read(at: finalOffset) ?? 0xFF
    }
    
    @inline(__always)
    func writeByte(_ address: UInt16, _ value: UInt8)
    {
        let addr = Int(address)
        let pageIndex = addr / MemoryMapper.pageSize
        
        guard pageIndex < pageTable.count else { return }
        
        let mapping = pageTable[pageIndex]
        
        guard mapping.isWritable else { return }
        
        let localOffset = addr & MemoryMapper.pageMask
        let finalOffset = mapping.offset + localOffset
        
        mapping.device?.write(value, at: finalOffset)
    }
    
    @inline(__always)
    func readWord(_ address: UInt16) -> UInt16
    {
        let lo = readByte(address)
        // Use wrapping addition (&+) for hardware-accurate address incrementing
        let hi = readByte(address &+ 1)
        return (UInt16(hi) << 8) | UInt16(lo)
    }
    
    @inline(__always)
    func writeWord(_ address:UInt16, _ value: UInt16)
    {
        let lo = UInt8(value & 0xFF)
        let hi = UInt8(value >> 8)
        writeByte(address, lo)
        writeByte(address &+ 1, hi)
    }
}
