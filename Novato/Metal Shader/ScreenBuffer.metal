#include <metal_stdlib>
using namespace metal;

[[ stitchable ]] half4 ScreenBuffer(float2 position, half4 color, float ScanLineHeight, float DisplayColumns, float FontLocationOffset, float CursorPosition, float CursorStartScanLine, float CursorEndScanLine, float CursorBlinkType, float CursorBlinkCounter, float PhosphorColour, device const float *screenram, int screenramsize, device const float *pcgchar, int pcgcharsize)
{
    half4 ForegroundColour;
    half4 BackgroundColour;
    int screenpos;
    int pcgpos;
    int xcursor;
    int ycursor;
    bool pixelset;
    
    const int CellWidth = 8;            // each character in font ROM is 8 pixels wide
    const int CellHeight = 16;          // each character in font ROM is 16 pixels high
    
    const half4 BlackColour = half4(0.0,0.0,0.0,1.0);
    const half4 WhiteColour = half4(1,1,1,1.0);
    const half4 GreenColour = half4(0,1,0.2,1);
    const half4 AmberColour = half4(1,0.749,0,1);
    
    switch (int(PhosphorColour))
    {
    case 0 :    // green
        ForegroundColour = GreenColour;
        BackgroundColour = BlackColour;
        break;
    case 1 :    // amber
        ForegroundColour = AmberColour;
        BackgroundColour = BlackColour;
        break;
    case 2 :    // white
        ForegroundColour = WhiteColour;
        BackgroundColour = BlackColour;
        break;
    default :   // black on white
        ForegroundColour = BlackColour;
        BackgroundColour = WhiteColour;
    }
    
    ycursor = int(position.y) % int(ScanLineHeight);    // calculate x pixel position in cell
    xcursor = int(position.x) % CellWidth;              // calculate x pixel position in cell
        
    screenpos = trunc(position.y/int(ScanLineHeight))*int(DisplayColumns)+trunc(position.x/CellWidth);  // return linear co-ordinates of character location based on pixel position
    pcgpos = int(FontLocationOffset)+int(screenram[screenpos])*CellHeight+int(ycursor);                 // return linear co-ordinates of font rom data
    
    int bitmask = (128 >> int(xcursor));
    
    if ((int(pcgchar[pcgpos]) & bitmask)  > 0 )  // test for pixel set in character definition in font rom
    {
        pixelset = true;
    }
    else
    {
        pixelset = false;
    }
    
    if (screenpos == int(CursorPosition))
    {
        switch (int(CursorBlinkType))
        {
            case 0: // 0 = always on
//                if ((int(position.x) >= int((xcursorpos-1)*8)) && (int(position.x) <= int((xcursorpos*8)-1)) && ( int(position.y) >= int(((ycursorpos-1)*ypixels)+cursorstart)) && ( int(position.y) <= int((int(ycursorpos-1)*ypixels)+cursorend)))
//                {
//                    pixelset = true;
//                }
//                break;
            case 1: break; // 1 = always off
            case 2: // 2 = normal flash 1/16 frame rate
//                if (( tick > 20 ) && (int(position.x) >= int((xcursorpos-1)*8)) && (int(position.x) <= int((xcursorpos*8)-1)) && ( int(position.y) >= int(((ycursorpos-1)*ypixels)+cursorstart)) && ( int(position.y) <= int((int(ycursorpos-1)*ypixels)+cursorend)))
//                {
//                    thingy = drawingcolor;
//                }
                break;
            case 3: // 3 = fast flash 1/32 frame rate
//                if (( tick > 10 ) && (int(position.x) >= int((xcursorpos-1)*8)) && (int(position.x) <= int((xcursorpos*8)-1)) && ( int(position.y) >= int(((ycursorpos-1)*ypixels)+cursorstart)) && ( int(position.y) <= int((int(ycursorpos-1)*ypixels)+cursorend)))
//                {
//                    thingy = drawingcolor;
//                }
                break;
        }
    }
    
    if (pixelset)
    {
        return ForegroundColour;
    }
    else
    {
        return BackgroundColour;
    }
}

[[ stitchable ]] half4 interlace ( float2 position, half4 color, float interlaceon )
{
    half4 InterlaceColor = half4(0.0, 0.0, 0.0, 1.0);

    // 2 pixels wide, change for more/less
    // or change fragCoord.y to fragCoord.x for vertical lines
    if ((int(position.y) % 2 == 0) && (interlaceon == 1))
    {
        return InterlaceColor;
    }
    else
    {
        return color;
    }
}
