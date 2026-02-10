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
}

