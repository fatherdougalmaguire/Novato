import Foundation

enum memoryDeviceType: CaseIterable
{
    case ROM
    case RAM
}

final class memoryBlock
{
    public var addressBlock: ContiguousArray<UInt8>
    public let size: Int
    public let deviceType : memoryDeviceType
    public let uuid: String
    public let label: String
    
    init( size: Int, deviceType: memoryDeviceType = .RAM,label: String = "", fillValue: UInt8 = 0 )
    {
        self.size = size
        self.deviceType  = deviceType
        self.label  = label
        self.addressBlock = ContiguousArray(repeating: fillValue, count: size)
        self.uuid = UUID().uuidString
    }
    
    func printBlockContents(offset: Int = 0)
    {
        print(label)
        let upperBound = (size/32)-1
        for counter in 0...upperBound
        {
            print(offset+counter*32,addressBlock[offset+counter*32..<offset+counter*32+32])
        }
    }
    
    func fillMemory( memValue: UInt8 )
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
    
    func fillMemoryFromFile(FileName: String, FileExtension: String )
    {
        var LoadCounter : Int = 0
        
        if let urlPath = Bundle.main.url(forResource: FileName, withExtension: FileExtension )
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
    private var memoryStorage: [[memoryBlock]]
    
    let pageSize = 2048
    let pageCount = 32
    let bankCount = 2
    
    init()
    {
        let emptyBlock = memoryBlock(size: 0)
        self.memoryStorage = Array(repeating: Array(repeating: emptyBlock, count: bankCount),count: pageCount)
    }
    
    func printMemoryMap()
    {
        for counter1 in 0...31
        {
            print("*",counter1,"0",String(format: "0x%04X", counter1*pageSize),String(format: "0x%04X", memoryStorage[counter1][0].size),memoryStorage[counter1][0].label,terminator: " | ")
            print(counter1,"0",String(format: "0x%04X", counter1*pageSize),String(format: "0x%04X", memoryStorage[counter1][1].size),memoryStorage[counter1][1].label)
        }
    }
    
    func map(readDevice: [memoryBlock], writeDevice: [memoryBlock], memoryLocation: UInt16)
    {
        var startPage : Int
        var endPage : Int
        var pageIndex : Int
        var pageOffset : Int
        
        pageOffset = Int(memoryLocation) / pageSize
        
        guard readDevice.count > 0 else { return }
        guard writeDevice.count > 0 else { return }
        
        for counter in 0...readDevice.count-1
        {
            startPage = pageOffset
            endPage = min(startPage-1+readDevice[counter].size/pageSize, pageCount-1)
            pageIndex = startPage
            while pageIndex <= endPage
            {
                memoryStorage[pageIndex][0] = readDevice[counter]
                pageIndex = pageIndex+1
            }
            pageOffset = pageIndex
        }
        
        pageOffset = Int(memoryLocation) / pageSize
        
        for counter in 0...writeDevice.count-1
        {
            startPage = pageOffset
            endPage = min(startPage-1+writeDevice[counter].size/pageSize, pageCount-1)
            pageIndex = startPage
            while pageIndex <= endPage
            {
                memoryStorage[pageIndex][1] = writeDevice[counter]
                pageIndex = pageIndex+1
            }
            pageOffset = pageIndex
        }
    }
    
    func deallocate(device: memoryBlock)
    {
    // may not be implemented
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
        let addr = Int(address)
        let pageIndex = addr/pageSize
        
        guard memoryStorage[pageIndex][0].size > 0 else { return 0xFF }
        
        let localOffset = addr & (pageSize-1)
        return memoryStorage[pageIndex][0].addressBlock[localOffset]
    }
    
    @inline(__always)
    func writeByte(address: UInt16, value: UInt8)
    {
        let addr = Int(address)
        let pageIndex = addr/pageSize

        guard memoryStorage[pageIndex][1].size > 0 else { return }

        guard (memoryStorage[pageIndex][1].deviceType == .RAM) else { return }

        let localOffset = addr & (pageSize-1)
        memoryStorage[pageIndex][1].addressBlock[localOffset] = value
    }
}

