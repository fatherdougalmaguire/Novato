import Foundation

class MMU
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
