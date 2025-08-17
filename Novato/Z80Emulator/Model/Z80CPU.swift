import Foundation

actor Z80CPU {
    var registers = Registers()
    
    var runcycles : UInt64 = 0
    var CPUstarttime : Date = Date()
    var CPUendtime : Date = Date()

    var memory: [UInt8] = Array(repeating: 0, count: 0x10000)
    var VDURAM : [UInt8] = Array(repeating: 0, count: 0x800)
    
    init()
    {
        VDURAM = [
            76, 111, 114, 101, 109, 32, 105, 112, 115, 117, 109, 32, 100, 111, 108, 111,
                114, 32, 115, 105, 116, 32, 97, 109, 101, 116, 44, 32, 99, 111, 110, 115,
                101, 99, 116, 101, 116, 117, 114, 32, 97, 100, 105, 112, 105, 115, 99, 105,
                110, 103, 32, 101, 108, 105, 116, 44, 32, 115, 101, 100, 32, 100, 111, 32,
                101, 105, 117, 115, 109, 111, 100, 32, 116, 101, 109, 112, 111, 114, 32, 105,
                110, 99, 105, 100, 105, 100, 117, 110, 116, 32, 117, 116, 32, 108, 97, 98,
                111, 114, 101, 32, 101, 116, 32, 100, 111, 108, 111, 114, 101, 32, 109, 97,
                103, 110, 97, 32, 97, 108, 105, 113, 117, 97, 46, 32, 66, 97, 99, 111,
                110, 32, 105, 112, 115, 117, 109, 32, 100, 111, 108, 111, 114, 32, 97, 109,
                101, 116, 32, 112, 111, 114, 107, 32, 98, 101, 108, 108, 121, 32, 112, 111,
                114, 107, 32, 108, 111, 105, 110, 46, 32, 85, 116, 32, 101, 110, 105, 109,
                32, 97, 100, 32, 109, 105, 110, 105, 109, 32, 118, 101, 110, 105, 97, 109,
                44, 32, 113, 117, 105, 115, 32, 110, 111, 115, 116, 114, 117, 100, 32, 101,
                120, 101, 114, 99, 105, 116, 97, 116, 105, 111, 110, 32, 117, 108, 108, 97,
                109, 99, 111, 32, 108, 97, 98, 111, 114, 105, 115, 32, 110, 105, 115, 105,
                32, 117, 116, 32, 97, 108, 105, 113, 117, 105, 112, 32, 101, 120, 32, 101,
                97, 32, 99, 111, 109, 109, 111, 100, 111, 32, 99, 111, 110, 115, 101, 113,
                117, 97, 116, 46, 32, 66, 97, 99, 111, 110, 32, 105, 112, 115, 117, 109,
                32, 100, 111, 108, 111, 114, 32, 97, 109, 101, 116, 32, 112, 97, 110, 99,
                101, 116, 116, 97, 46, 32, 68, 117, 105, 115, 32, 97, 117, 116, 101, 32,
                105, 114, 117, 114, 101, 32, 100, 111, 108, 111, 114, 32, 105, 110, 32, 114,
                101, 112, 114, 101, 104, 101, 110, 100, 101, 114, 105, 116, 32, 105, 110, 32,
                118, 111, 108, 117, 112, 116, 97, 116, 101, 32, 118, 101, 108, 105, 116, 32,
                101, 115, 115, 101, 32, 99, 105, 108, 108, 117, 109, 32, 100, 111, 108, 111,
                114, 101, 32, 101, 117, 32, 102, 117, 103, 105, 97, 116, 32, 110, 117, 108,
                108, 97, 32, 112, 97, 114, 105, 97, 116, 117, 114, 46, 32, 66, 97, 99,
                111, 110, 32, 105, 112, 115, 117, 109, 32, 100, 111, 108, 111, 114, 32, 97,
                109, 101, 116, 32, 107, 105, 101, 108, 98, 97, 115, 97, 46, 32, 69, 120,
                99, 101, 112, 116, 101, 117, 114, 32, 115, 105, 110, 116, 32, 111, 99, 99,
                97, 101, 99, 97, 116, 32, 99, 117, 112, 105, 100, 97, 116, 97, 116, 32, 110,
                111, 110, 32, 112, 114, 111, 105, 100, 101, 110, 116, 44, 32, 115, 117, 110,
                116, 32, 105, 110, 32, 99, 117, 108, 112, 97, 32, 113, 117, 105, 32, 111,
                102, 102, 105, 99, 105, 97, 32, 100, 101, 115, 101, 114, 117, 110, 116, 32,
                109, 111, 108, 108, 105, 116, 32, 97, 110, 105, 109, 32, 105, 100, 32, 101,
                115, 116, 32, 108, 97, 98, 111, 114, 117, 109, 46, 32, 66, 97, 99, 111,
                110, 32, 105, 112, 115, 117, 109, 32, 100, 111, 108, 111, 114, 32, 97, 109,
                101, 116, 32, 115, 104, 111, 114, 116, 32, 114, 105, 98, 115, 46, 32, 73,
                110, 116, 101, 103, 101, 114, 32, 110, 101, 99, 32, 111, 100, 105, 111, 46,
                32, 80, 114, 97, 101, 115, 101, 110, 116, 32, 108, 105, 98, 101, 114, 111,
                46, 32, 83, 101, 100, 32, 99, 117, 114, 115, 117, 115, 32, 97, 110, 116,
                101, 32, 100, 97, 112, 105, 98, 117, 115, 32, 100, 105, 97, 109, 44, 32,
                101, 103, 101, 116, 32, 97, 108, 105, 113, 117, 101, 116, 32, 108, 111, 114,
                101, 109, 46, 32, 66, 97, 99, 111, 110, 32, 105, 112, 115, 117, 109, 32,
                100, 111, 108, 111, 114, 32, 97, 109, 101, 116, 32, 112, 97, 110, 99, 101,
                116, 116, 97, 46, 32, 83, 101, 100, 32, 110, 105, 115, 105, 46, 32, 78,
                117, 108, 108, 97, 32, 113, 117, 105, 115, 32, 115, 101, 109, 32, 97, 116,
                32, 110, 105, 98, 104, 32, 101, 108, 101, 109, 101, 110, 116, 117, 109, 32,
                105, 109, 112, 101, 114, 100, 105, 101, 116, 46, 32, 85, 116, 32, 101, 110,
                105, 109, 32, 97, 100, 32, 109, 105, 110, 105, 109, 32, 118, 101, 110, 105,
                97, 109, 44, 32, 113, 117, 105, 115, 32, 110, 111, 115, 116, 114, 117, 100,
                32, 101, 120, 101, 114, 99, 105, 116, 97, 116, 105, 111, 110, 32, 117, 108,
                108, 97, 109, 99, 111, 32, 108, 97, 98, 111, 114, 105, 115, 46, 32, 66,
                97, 99, 111, 110, 32, 105, 112, 115, 117, 109, 32, 100, 111, 108, 111, 114,
                32, 97, 109, 101, 116, 32, 112, 114, 111, 115, 99, 105, 117, 116, 116, 111,
                46, 32, 70, 117, 115, 99, 101, 32, 110, 101, 99, 32, 116, 101, 108, 108,
                117, 115, 32, 115, 101, 100, 32, 97, 117, 103, 117, 101, 32, 115, 101, 109,
                112, 101, 114, 32, 112, 111, 114, 116, 97, 46, 32, 77, 111, 114, 98, 105,
                32, 108, 101, 99, 116, 117, 115, 32, 114, 105, 115, 117, 115, 44, 32, 105,
                97, 99, 117, 108, 105, 115, 32, 118, 101, 108, 44, 32, 115, 117, 115, 99,
                105, 112, 105, 116, 32, 113, 117, 105, 115, 44, 32, 108, 117, 99, 116, 117,
                115, 32, 110, 111, 110, 46, 32, 66, 97, 99, 111, 110, 32, 105, 112, 115,
                117, 109, 32, 100, 111, 108, 111, 114, 32, 97, 109, 101, 116, 32, 115, 116,
                114, 105, 112, 32, 115, 116, 101, 97, 107, 46, 32, 78, 117, 108, 108, 97,
                32, 102, 97, 99, 105, 108, 105, 115, 105, 46, 32, 80, 114, 97, 101, 115,
                101, 110, 116, 32, 101, 103, 101, 115, 116, 97, 115, 32, 108, 101, 111, 32,
                105, 110, 32, 112, 101, 100, 101, 46, 32, 86, 101, 115, 116, 105, 98, 117,
                108, 117, 109, 32, 116, 117, 114, 105, 110, 103, 111, 46, 32, 85, 116, 32,
                108, 97, 111, 114, 101, 101, 116, 32, 97, 108, 105, 113, 117, 97, 109, 32,
                109, 97, 103, 110, 97, 46, 32, 66, 97, 99, 111, 110, 32, 105, 112, 115,
                117, 109, 32, 100, 111, 108, 111, 114, 32, 97, 109, 101, 116, 32, 98, 97,
                99, 111, 110, 46, 32, 80, 101, 108, 108, 101, 110, 116, 101, 115, 113, 117,
                101, 32, 102, 101, 114, 109, 101, 110, 116, 117, 109, 46, 32, 69, 116, 105,
                97, 109, 32, 118, 101, 108, 32, 108, 101, 99, 116, 117, 115, 46, 32, 78,
                117, 108, 108, 97, 32, 105, 100, 32, 100, 111, 108, 111, 114, 46, 32, 73,
                110, 32, 104, 97, 99, 32, 104, 97, 98, 105, 116, 97, 115, 115, 101, 32,
                112, 108, 97, 116, 101, 97, 32, 100, 105, 99, 116, 117, 109, 115, 116, 46,
                32, 83, 101, 100, 32, 115, 101, 109, 112, 101, 114, 32, 110, 117, 108, 108,
                97, 46, 32, 66, 97, 99, 111, 110, 32, 105, 112, 115, 117, 109, 32, 100,
                111, 108, 111, 114, 32, 97, 109, 101, 116, 32, 98, 114, 101, 115, 97, 111,
                108, 97, 46, 32, 85, 116, 32, 115, 101, 109, 46, 32, 68, 117, 105, 115,
                32, 99, 117, 114, 115, 117, 115, 46, 32, 73, 110, 32, 104, 97, 99, 32,
                104, 97, 98, 105, 116, 97, 115, 115, 101, 32, 112, 108, 97, 116, 101, 97,
                32, 100, 105, 99, 116, 117, 109, 115, 116, 46, 32, 77, 111, 114, 98, 105,
                32, 111, 100, 105, 111, 46, 32, 81, 117, 105, 115, 113, 117, 101, 32, 99,
                117, 114, 115, 117, 115, 46, 32, 66, 97, 99, 111, 110, 32, 105, 112, 115,
                117, 109, 32, 100, 111, 108, 111, 114, 32, 97, 109, 101, 116, 32, 103, 114,
                111, 117, 110, 100, 46, 32, 80, 114, 111, 105, 110, 32, 115, 111, 100, 97,
                108, 101, 115, 32, 108, 105, 103, 117, 108, 97, 46, 32, 86, 105, 118, 97,
                109, 117, 115, 32, 97, 116, 32, 97, 117, 103, 117, 101, 46, 32, 76, 111,
                114, 101, 109, 32, 105, 112, 115, 117, 109, 32, 100, 111, 108, 111, 114, 32,
                115, 105, 116, 32, 97, 109, 101, 116, 44, 32, 99, 111, 110, 115, 101, 99,
                116, 101, 116, 117, 114, 32, 97, 100, 105, 112, 105, 115, 99, 105, 110, 103,
                32, 101, 108, 105, 116, 46, 32, 66, 97, 99, 111, 110, 32, 105, 112, 115,
                117, 109, 32, 100, 111, 108, 111, 114, 32, 97, 109, 101, 116, 32, 116, 45,
                98, 111, 110, 101, 46, 32, 68, 111, 110, 101, 99, 32, 99, 111, 110, 103,
                117, 101, 46, 32, 83, 117, 115, 112, 101, 110, 100, 105, 115, 115, 101, 32,
                110, 115, 108, 46, 32, 78, 117, 110, 99, 32, 115, 101, 100, 32, 115, 101,
                109, 46, 32, 77, 97, 101, 99, 101, 110, 97, 115, 32, 110, 111, 110, 46,
                32, 66, 97, 99, 111, 110, 32, 105, 112, 115, 117, 109, 32, 100, 111, 108,
                111, 114, 32, 97, 109, 101, 116, 46, 32, 73, 110, 32, 104, 97, 99, 32,
                104, 97, 98, 105, 116, 97, 115, 115, 101, 32, 112, 108, 97, 116, 101, 97,
                32, 100, 105, 99, 116, 117, 109, 115, 116, 46, 32, 65, 101, 110, 101, 97,
                110, 32, 108, 101, 99, 116, 117, 115, 46, 32, 83, 101, 100, 32, 115, 97,
                103, 105, 116, 116, 105, 115, 46, 32, 85, 116, 32, 118, 111, 108, 117, 116,
                112, 97, 116, 46, 32, 66, 97, 99, 111, 110, 32, 105, 112, 115, 117, 109,
                32, 100, 111, 108, 111, 114, 32, 97, 109, 101, 116, 46, 32, 80, 104, 97,
                115, 101, 108, 108, 117, 115, 32, 98, 108, 97, 110, 100, 105, 116, 46, 32,
                83, 101, 100, 32, 115, 101, 100, 46, 32, 77, 97, 101, 99, 101, 110, 97,
                115, 32, 112, 111, 114, 116, 97, 46, 32, 66, 97, 99, 111, 110, 32, 105,
                112, 115, 117, 109, 32, 100, 111, 108, 111, 114, 32, 97, 109, 101, 116, 46,
                32, 81, 117, 105, 115, 113, 117, 101, 32, 118, 101, 108, 105, 116, 46, 32,
                80, 104, 97, 115, 101, 108, 108, 117, 115, 46, 32, 67, 114, 97, 115, 32,
                118, 101, 110, 101, 110, 97, 116, 105, 115, 46, 32, 66, 97, 99, 111, 110,
                32, 105, 112, 115, 117, 109, 32, 100, 111, 108, 111, 114, 32, 97, 109, 101,
                116, 46, 32, 86, 101, 115, 116, 105, 98, 117, 108, 117, 109, 46, 32, 65,
                108, 105, 113, 117, 97, 109, 46, 32, 83, 101, 100, 32, 117, 116, 46, 32,
                81, 117, 105, 115, 32, 101, 110, 105, 109, 46, 32, 85, 116, 32, 99, 111,
                110, 100, 105, 109, 101, 110, 116, 117, 109, 46, 32, 66, 97, 99, 111, 110,
                32, 105, 112, 115, 117, 109, 32, 100, 111, 108, 111, 114, 32, 97, 109, 101,
                116, 46, 32, 80, 114, 97, 101, 115, 101, 110, 116, 32, 97, 116, 46, 32, 73,
                110, 46, 32, 78, 105, 98, 104, 32, 99, 111, 110, 100, 105, 109, 101, 110,
                116, 117, 109, 46, 32, 68, 111, 110, 101, 99, 46, 32, 66, 97, 99, 111, 110,
                32, 105, 112, 115, 117, 109, 32, 100, 111, 108, 111, 114, 32, 97, 109, 101,
                116, 46, 32, 78, 117, 108, 108, 97, 109, 46, 32, 78, 105, 115, 105, 46, 32,
                83, 101, 100, 46, 32, 86, 105, 118, 97, 109, 117, 115, 46, 32, 78, 117,
                108, 108, 97, 46, 32, 66, 97, 99, 111, 110, 32, 105, 112, 115, 117, 109,
                32, 100, 111, 108, 111, 114, 32, 97, 109, 101, 116, 46, 32, 69, 103, 101,
                115, 116, 97, 115, 46, 32, 68, 117, 105, 115, 46, 32, 77, 111, 114, 98,
                105, 46, 32, 85, 116, 46, 32, 67, 114, 97, 115, 46, 32, 66, 97, 99, 111,
                110, 32, 105, 112, 115, 117, 109, 32, 100, 111, 108, 111, 114, 32, 97, 109,
                101, 116, 46, 32, 73, 110, 116, 101, 103, 101, 114, 46, 32, 68, 117, 105,
                115, 46, 32, 76, 111, 114, 101, 109, 46, 32, 85, 116, 46, 32, 78, 117,
                108, 108, 97, 109, 46, 32, 83, 117, 115, 112, 101, 110, 100, 105, 115, 115,
                101, 46, 32, 76, 111, 114, 101, 109, 32, 105, 112, 115, 117, 109, 32, 100,
                111, 108, 111, 114, 32, 115, 105, 116, 32, 97, 109, 101, 116, 44, 32, 99,
                111, 110, 115, 101, 99, 116, 101, 116, 117, 114, 32, 97, 100, 105, 112, 105,
                115, 99, 105, 110, 103, 32, 101, 108, 105, 116, 46, 32, 66, 97, 99, 111,
                110, 32, 105, 112, 115, 117, 109, 32, 100, 111, 108, 111, 114, 32, 97, 109,
                101, 116, 46, 32, 65, 108, 105, 113, 117, 97, 109, 46, 32, 83, 117, 115,
                112, 101, 110, 100, 105, 115, 115, 101, 32, 112, 111, 116, 101, 110, 116, 105,
                46, 32, 85, 116, 32, 99, 111, 110, 100, 105, 109, 101, 110, 116, 117, 109,
                46, 32, 67, 114, 97, 115, 46, 32, 78, 117, 108, 108, 97, 46, 32, 68, 111,
                110, 101, 99, 46, 32, 66, 97, 99, 111, 110, 32, 105, 112, 115, 117, 109,
                32, 100, 111, 108, 111, 114, 32, 97, 109, 101, 116, 46, 32, 73, 110, 116,
                101, 103, 101, 114, 32, 101, 117, 46, 32, 83, 101, 100, 46, 32, 73, 110,
                46, 32, 68, 111, 110, 101, 99, 46, 32, 69, 110, 100, 46]
                //  Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Bacon ipsum dolor amet pork belly pork loin. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Bacon ipsum dolor amet pancetta. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Bacon ipsum dolor amet kielbasa. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum. Bacon ipsum dolor amet short ribs. Integer nec odio. Praesent libero. Sed cursus ante dapibus diam, eget aliquet lorem. Bacon ipsum dolor amet pancetta. Sed nisi. Nulla quis sem at nibh elementum imperdiet. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris. Bacon ipsum dolor amet prosciutto. Fusce nec tellus sed augue semper porta. Morbi lectus risus, iaculis vel, suscipit quis, luctus non. Bacon ipsum dolor amet strip steak. Nulla facilisi. Praesent egestas leo in pede. Vestibulum turingo. Ut laoreet aliquam magna. Bacon ipsum dolor amet bacon. Pellentesque fermentum. Etiam vel lectus. Nulla id dolor. In hac habitasse platea dictumst. Sed semper nulla. Bacon ipsum dolor amet bresaola. Ut sem. Duis cursus. In hac habitasse platea dictumst. Morbi odio. Quisque cursus. Bacon ipsum dolor amet ground. Proin sodales ligula. Vivamus at augue. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Bacon ipsum dolor amet t-bone. Donec congue. Suspendisse nisl. Nunc sed sem. Maecenas non. Bacon ipsum dolor amet. In hac habitasse platea dictumst. Aenean lectus. Sed sagittis. Ut volutpat. Bacon ipsum dolor amet. Phasellus blandit. Sed sed. Maecenas porta. Bacon ipsum dolor amet. Quisque velit. Phasellus. Cras venenatis. Bacon ipsum dolor amet. Vestibulum. Aliquam. Sed ut. Quis enim. Ut condimentum. Bacon ipsum dolor amet. Praesent at. In. Nibh condimentum. Donec. Bacon ipsum dolor amet. Nullam. Nisi. Sed. Vivamus. Nulla. Bacon ipsum dolor amet. Egestas. Duis. Morbi. Ut. Cras. Bacon ipsum dolor amet. Integer. Duis. Lorem. Ut. Nullam. Suspendisse. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Bacon ipsum dolor amet. Aliquam. Suspendisse potenti. Ut condimentum. Cras. Nulla. Donec. Bacon ipsum dolor amet. Integer eu. Sed. In. Donec. End.
        memory[0xf000...0xf7ff] = VDURAM[0...0x7ff]
        memory[0x000...0x0016] = [0x21,0x00,0xF0,0x3E,0x48,0x77,0x23,0x3E,0x45,0x77,0x23,0x3E,0x4C,0x23,0x3E,0x4C,0x77,0x23,0x3E,0x4F,0x77,0x23]
        //        0000   21 00 F0               LD   HL,$F000
        //        0003   3E 48                  LD   A,"H"
        //        0005   77                     LD   (HL),A
        //        0006   23                     INC   HL
        //        0007   3E 45                  LD   A,"E"
        //        0009   77                     LD   (HL),A
        //        000A   23                     INC   HL
        //        000B   3E 4C                  LD   A,"L"
        //        000D   77                     LD   (HL),A
        //        000E   23                     INC   HL
        //        000F   3E 4C                  LD   A,"L"
        //        0011   77                     LD   (HL),A
        //        0012   23                     INC   HL
        //        0013   3E 4F                  LD   A,"O"
        //        0015   77                     LD   (HL),A
        //        0016   23                     INC   HL
    }

    private(set) var running = false

    func start()
    {
        CPUstarttime = Date()
        guard !running else { return }
        running = true
        Task.detached(priority: .background) { await self.runLoop() }
    }

    func stop()
    {
        CPUendtime = Date()
        running = false
        let ken = CPUendtime.timeIntervalSince1970-CPUstarttime.timeIntervalSince1970
        print(ken,"seconds")
        print(runcycles," instructions")
        print("Each instruction takes ",ken / Double(runcycles)*1000*1000," microseconds to execute")
        runcycles = 0
    }

    private func runLoop() async
    {
        while running
        {
            let prefetch = fetch(pc:Int(registers.PC))
            await execute( opcodes : prefetch)
            // Roughly emulate 1 Mhz (≈1 µs per instruction) – tweak as needed.
            try? await Task.sleep(nanoseconds: 100)
        }
    }

    private func fetch( pc : Int) -> (UInt8,UInt8,UInt8,UInt8)
    {
        return ( opcode1 : memory[Int(registers.PC)], opcode2 : memory[Int(IncrementRegPair(BaseValue:registers.PC,Increment:1))], opcode3 : memory[Int(IncrementRegPair(BaseValue:registers.PC,Increment:2))], opcode4 : memory[Int(IncrementRegPair(BaseValue:registers.PC,Increment:3))] )
    }

    func IncrementRegPair ( BaseValue  : UInt16, Increment : UInt16 ) -> UInt16
    
    {
        return BaseValue &+ Increment
    }
    
    func DecrementRegPair ( BaseValue  : UInt16, Increment : UInt16 ) -> UInt16
    
    {
        return BaseValue &- Increment
    }
    
    func IncrementReg ( BaseValue  : UInt8, Increment : UInt8 ) -> UInt8
    
    {
        return BaseValue &+ Increment
        // flag code goes here
    }
    
    func DecrementReg ( BaseValue  : UInt8, Increment : UInt8 ) -> UInt8
    
    {
        return BaseValue &- Increment
        // flag code goes here
    }

    private func execute( opcodes: ( opcode1 : UInt8, opcode2 : UInt8, opcode3 : UInt8, opcode4 : UInt8)) async {
        switch opcodes.opcode1
        {
        case 0x00: // NOP
            registers.PC = IncrementRegPair(BaseValue:registers.PC,Increment:1)
        case 0x21: // LD HL, nn
            registers.HL = UInt16(opcodes.opcode2 << 8 | opcodes.opcode3)
            registers.PC = IncrementRegPair(BaseValue:registers.PC,Increment:3)
        case 0x23: // INC HL
            registers.HL = IncrementRegPair(BaseValue:registers.HL,Increment:1)
            registers.PC = IncrementRegPair(BaseValue:registers.PC,Increment:1)
        case 0x3C: // INC A
            registers.A = IncrementReg(BaseValue:registers.A,Increment:1)
            registers.PC = IncrementRegPair(BaseValue:registers.PC,Increment:1)
        case 0x78: // LD A, B
            registers.A = registers.B
            registers.PC = IncrementRegPair(BaseValue:registers.PC,Increment:1)
        case 0x79: // LD A,C
            registers.A = registers.C
            registers.PC = IncrementRegPair(BaseValue:registers.PC,Increment:1)
        case 0x7A: // LD A,D
            registers.A = registers.D
            registers.PC = IncrementRegPair(BaseValue:registers.PC,Increment:1)
        case 0x7B: // LD A,E
            registers.A = registers.E
            registers.PC = IncrementRegPair(BaseValue:registers.PC,Increment:1)
        case 0x7C: // LD A,H
            registers.A = registers.H
            registers.PC = IncrementRegPair(BaseValue:registers.PC,Increment:1)
        case 0x7D: // LD A,L
            registers.A = registers.L
            registers.PC = IncrementRegPair(BaseValue:registers.PC,Increment:1)
        case 0x04: // INC B
            print("Unimplemented opcode: \(String(format: "%02X", opcodes.opcode1))")
            registers.PC = IncrementRegPair(BaseValue:registers.PC,Increment:1)
        case 0x05: // DEC B
            print("Unimplemented opcode: \(String(format: "%02X", opcodes.opcode1))")
            registers.PC = IncrementRegPair(BaseValue:registers.PC,Increment:1)
        default:
            print("Unknown opcode: \(String(format: "%02X", opcodes.opcode1))")
            registers.PC = IncrementRegPair(BaseValue:registers.PC,Increment:1)
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
                             memoryDump: Array(memory[Int(registers.PC)..<0xffff]),
                             VDU : VDURAM)
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
                         memoryDump: Array(memory[Int(registers.PC)..<Int(registers.PC)+0x0ff]),
                         VDU : VDURAM)
    }
}

