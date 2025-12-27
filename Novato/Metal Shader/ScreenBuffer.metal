#include <metal_stdlib>
using namespace metal;

[[ stitchable ]] half4 ScreenBuffer(float2 position, half4 color, float ScanLineHeight, float DisplayColumns, float FontLocationOffset, float CursorPosition, float CursorStartScanLine, float CursorEndScanLine, float CursorBlinkType, float CursorBlinkCounter, float CursorFlashLimit, float PhosphorColour, device const float *screenram, int screenramsize, device const float *fontrom, int fontromsize, device const float *pcgram, int pcgramsize, device const float *colourram, int colourramsize)
{
    half4 ForegroundColour;
    half4 BackgroundColour;
    int screenpos;
    int fontpos;
    int xcursor;
    int ycursor;
    bool pixelset;
    
    int pixelLocation;
    
    const int CellWidth = 8;            // each character in font ROM is 8 pixels wide
    const int CellHeight = 16;          // each character in font ROM is 16 pixels high
    
    const half4 BlackColour = half4(0.0,0.0,0.0,1.0);
    const half4 WhiteColour = half4(1,1,1,1.0);
    const half4 GreenColour = half4(0,1,0.2,1);
    const half4 AmberColour = half4(1,0.749,0,1);
    const half4 BlueColour  = half4(0.68,0.85,0.9,1);
    
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
    case 3 :    // blue
        ForegroundColour = BlueColour;
        BackgroundColour = BlackColour;
        break;
    default :   // black on white
        ForegroundColour = BlackColour;
        BackgroundColour = WhiteColour;
    }
    
    ycursor = int(position.y) % int(ScanLineHeight);    // calculate x pixel position in cell
    xcursor = int(position.x) % CellWidth;              // calculate x pixel position in cell
        
    screenpos = trunc(position.y/int(ScanLineHeight))*int(DisplayColumns)+trunc(position.x/CellWidth);  // return linear co-ordinates of character location based on pixel position
    //fontpos = int(FontLocationOffset)+int(screenram[screenpos])*CellHeight+int(ycursor);                 // return linear co-ordinates of font rom data
    
    int bitmask = (128 >> int(xcursor));
    
    if (screenram[screenpos] < 128)
    {
        fontpos = int(FontLocationOffset)+int(screenram[screenpos])*CellHeight+int(ycursor);
        pixelLocation = int(fontrom[fontpos]);
    }
    else
    {
        fontpos = int(screenram[screenpos]-128)*CellHeight+int(ycursor);
        pixelLocation = int(pcgram[fontpos]);
    }
    
    if ( (pixelLocation & bitmask)  > 0 )  // test for pixel set in character definition in font rom/pcg ram
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
                    if ((ycursor >= int(CursorStartScanLine)) && (ycursor <= int(CursorEndScanLine)))
                    {
                        pixelset = !pixelset;
                    }
                    break;
            case 1: break; // 1 = always off
            case 2: // 2 = normal flash 1/16 frame rate
                    if ((ycursor >= int(CursorStartScanLine)) && (ycursor <= int(CursorEndScanLine)) && ( int(CursorBlinkCounter) < int(CursorFlashLimit) ))
                    {
                        pixelset = !pixelset;
                    }
                    break;
            case 3: // 3 = fast flash 1/32 frame rate
                    if ((ycursor >= int(CursorStartScanLine)) && (ycursor <= int(CursorEndScanLine)) && ( int(CursorBlinkCounter) < int(CursorFlashLimit) ))
                    {
                        pixelset = !pixelset;
                    }
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
