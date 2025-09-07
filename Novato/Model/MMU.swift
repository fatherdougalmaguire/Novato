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
        guard MemoryAddress > 0xFFFF
        else
        {
            memory[Int(MemoryAddress)] = MemoryValue
            return
        }
        return
    }
    
    func ReadMemory( MemoryAddress : UInt16 ) -> UInt8
    {
        guard MemoryAddress > 0xFFFF
        else
        {
            return memory[Int(MemoryAddress)]
        }
        return 0
    }
    
    func LoadMemoryFromArray ( MemoryAddress : UInt16, MemoryData : [UInt8] )
    {
        var LoadCounter : Int = Int(MemoryAddress)
        
        for MyIndex in MemoryData
        {
            memory[LoadCounter] = UInt8(MyIndex)
            LoadCounter = LoadCounter + 1
        }
        
    }
    
    func LoadMemoryFromFile ( FileName : String,  FileExtension : String, MemoryAddress : UInt16 )
    
    {
        var LoadCounter : Int = Int(MemoryAddress)
        
        if let urlPath = Bundle.main.url(forResource: FileName, withExtension: FileExtension )
        {
            do {
                let contents = try Data(contentsOf: urlPath)
                for MyIndex in contents
                {
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
}
