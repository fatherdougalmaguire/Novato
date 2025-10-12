import SwiftUI

struct EmulatorView: View
{
    @Environment(EmulatorViewModel.self) private var vm
    @Environment(\.openWindow) var openWindow
    
    let eightyCol = 0.0 // set to 1 if 80 col mode is turned on
    
    let charWidth : CGFloat =  8 // pixel width per character - 8 for 64x16 and 80x24
    let charHeight : CGFloat =  16 // pixel height per character - 16 for 64x16 and 11 for 80x24
    let charCols : CGFloat =  64 // Characters per row
    let charRows : CGFloat =  16 // Number of rows
    
    //        let charWidth : CGFloat =  8 // pixel width per character - 8 for 64x16 and 80x24
    //        let charHeight : CGFloat =  11 // pixel height per character - 16 for 64x16 and 11 for 80x24
    //        let charCols : CGFloat =  80 // Characters per row
    //        let charRows : CGFloat =  24 // Number of rows
    
    let charScale : CGFloat = 2.0 // Scale for visibility on 27" screen ( 2560 x 1440 )
    let charAspect : CGFloat = 4/3 // Correction for CRT aspect ratio
    
    var body: some View
    {
        ZStack {
            Color.white
            VStack {
                Rectangle()
                    .frame(width: charWidth*charCols, height: charHeight*charRows,alignment: .center)
                    .colorEffect(ShaderLibrary.ScreenBuffer(.float(eightyCol),.floatArray(vm.VDU),.floatArray(vm.CharRom)))
                    .scaleEffect(x: charScale,y:charScale*charAspect)
                    .frame(width: charWidth*charCols*charScale, height: charHeight*charRows*charScale*charAspect,alignment: .center)
                
                HStack
                {
                    Button("Start", systemImage:"play.fill")
                    {
                        Task { await vm.startEmulation() }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.orange)
                    //.symbolEffect(.pulse, value: true)
                    
                    Button("Stop", systemImage:"stop.fill")
                    {
                        Task { await vm.stopEmulation() }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.orange)
                    
                    Button("Step", systemImage:"play.square.fill")
                    {
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.orange)
                    .disabled(true)
                    
                } //hstack
                
                HStack
                {
                    Button("Reset", systemImage:"arrow.trianglehead.clockwise.rotate.90")
                    {
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.orange)
                    .disabled(true)
                    
                    Button("Quit", systemImage:"power")
                    {
                        NSApp.terminate(nil)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.orange)
                } //hstack
                
                Spacer()
                
            } //vstack
        }  //zstack
        .onAppear
        {
            openWindow(id: "DebugWindow")
        }
    }
} // struct
