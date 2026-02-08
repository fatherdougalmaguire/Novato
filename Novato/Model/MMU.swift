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
    let uuid: String
    let label: String
    var pageStart : Int
    
    init(size: UInt, deviceType: memoryDeviceType = .RAM,label: String = "", fillValue: UInt8 = 0)
    {
        let clampedSize = min((Int(size) + memoryConstant.pageMask) & ~memoryConstant.pageMask,memoryConstant.memorySize)
        self.size = Int(clampedSize)
        self.deviceType  = deviceType
        self.label  = label
        self.addressBlock = ContiguousArray(repeating: fillValue, count: clampedSize)
        self.uuid = UUID().uuidString
        self.pageStart = 0
    }
    
    func setPageStart(pageStart: Int)
    {
        self.pageStart = pageStart
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
    private var readPages: [memoryBlock]
    private var writePages: [memoryBlock]
    
    init()
    {
        let emptyBlock = memoryBlock(size: UInt(memoryConstant.pageSize))
        self.readPages = Array(repeating: emptyBlock,count: memoryConstant.pageCount)
        self.writePages = Array(repeating: emptyBlock, count: memoryConstant.pageCount)
    }
    
    func printMemoryMap()
    {
        for counter in 0...7
        {
            print(String(format: "%02d",counter*4) + "  " + readPages[counter*4].label.padding(toLength: 8, withPad: " ", startingAt: 0) + "  " + writePages[counter*4].label.padding(toLength: 8, withPad: " ", startingAt: 0) + "  " +
                  String(format: "%02d",counter*4+1) + "  " + readPages[counter*4+1].label.padding(toLength: 8, withPad: " ", startingAt: 0) + "  " + writePages[counter*4+1].label.padding(toLength: 8, withPad: " ", startingAt: 0) + "  " + String(format: "%02d",counter*4+2) + "  " + readPages[counter*4+2].label.padding(toLength: 8, withPad: " ", startingAt: 0) + "  " + writePages[counter*4+2].label.padding(toLength: 8, withPad: " ", startingAt: 0) + "  " + String(format: "%02d",counter*4+3) + "  " + readPages[counter*4+3].label.padding(toLength: 8, withPad: " ", startingAt: 0) + "  " + writePages[counter*4+3].label.padding(toLength: 8, withPad: " ", startingAt: 0))
        }
    }
    
    func map(readDevice: memoryBlock, writeDevice: memoryBlock, memoryLocation: UInt16)
    {
        let pageIndex = Int(memoryLocation) >> memoryConstant.pageShift

        let endReadPage = (Int(memoryLocation)+readDevice.size-1) >> memoryConstant.pageShift
        let endWritePage = (Int(memoryLocation)+writeDevice.size-1) >> memoryConstant.pageShift
        
        readDevice.pageStart = pageIndex
        writeDevice.pageStart = pageIndex
        
        for counter in pageIndex...endReadPage
        {
            guard counter <= memoryConstant.pageCount-1 else { break }
            readPages[counter] = readDevice
        }
        
        for counter in pageIndex...endWritePage
        {
            guard counter <= memoryConstant.pageCount-1 else { break }
            writePages[counter] = writeDevice
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
        let pageOffset = (pageIndex - readPages[pageIndex].pageStart) << memoryConstant.pageShift + (Int(address) & memoryConstant.pageMask)
        
        let blockSize = readPages[pageIndex].size
        
        guard blockSize > 0 else { return 0xFF }
        
        return readPages[pageIndex].addressBlock[pageOffset]
    }
    
    @inline(__always)
    func writeByte(address: UInt16, value: UInt8)
    {
        let pageIndex = Int(address) >> memoryConstant.pageShift
        let pageOffset = (pageIndex - writePages[pageIndex].pageStart) << memoryConstant.pageShift + (Int(address) & memoryConstant.pageMask)
        
        let blockSize = writePages[pageIndex].size
        
        guard blockSize > 0 else { return }
        guard writePages[pageIndex].deviceType == .RAM else { return }
        
        writePages[pageIndex].addressBlock[pageOffset] = value
    }
}

