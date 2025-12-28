#include <metal_stdlib>
using namespace metal;

[[ stitchable ]] half4 ScreenBuffer(float2 position, half4 color, float ScanLineHeight, float DisplayColumns, float FontLocationOffset, float CursorPosition, float CursorStartScanLine, float CursorEndScanLine, float CursorBlinkType, float CursorBlinkCounter, float CursorFlashLimit, float colorMode, device const float *screenram, int screenramsize, device const float *fontrom, int fontromsize, device const float *pcgram, int pcgramsize, device const float *colourram, int colourramsize)
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
    
    const half4 monoGreenColour = half4(115/255,246/255,92/255,1);  // monochrome - green
    const half4 monoAmberColour = half4(1,0.749,0,1);               // monochrome - amber
    const half4 monoBlueColour = half4(0.68,0.85,0.9,1);            // monochrome - blue
    const half4 monoWhiteColour = half4(1,1,1,1);                   // monochrome - white
    const half4 monoBlackColour = half4(0,0,0,1);                   // monochrome - black
    
    half4 backgroundColourArray[8] = {half4(0,0,0,1), half4(1,0,0,1), half4(0,1,0.2,1), half4(0,1,0.2,1), half4(0.68,0.85,0.9,1),half4(1,1,1,1),half4(1,0,0,1),half4(1,1,1,1)};
    
    // background colours
    // 0 - black        1 - red         2 - green           3 - yellow      4 - blue        5 - magenta         6 - cyan            7 - white
    
    half4 foregroundColourArray[32] = {half4(0,0,0,1), half4(0,0.1,0.95,1), half4(115/255,246/255,92/255,1), half4(117/255,250/255,253/255,1), half4(234/255,51/255,35/255,1),half4(234/255,83/255,243/255,1),half4(1,246/255,95/255,1),half4(1,1,1,1),
                                       half4(0,0,0,1), half4(0,0.1,0.95,1), half4(115/255,246/255,92/255,1), half4(117/255,250/255,253/255,1), half4(234/255,51/255,35/255,1),half4(234/255,83/255,243/255,1),half4(1,246/255,95/255,1),half4(1,1,1,1),
                                       half4(0,0,0,1), half4(0,0.1,0.95,1), half4(115/255,246/255,92/255,1), half4(117/255,250/255,253/255,1), half4(234/255,51/255,35/255,1),half4(234/255,83/255,243/255,1),half4(1,246/255,95/255,1),half4(1,1,1,1),
                                       half4(0,0,0,1), half4(0,0.1,0.95,1), half4(115/255,246/255,92/255,1), half4(117/255,250/255,253/255,1), half4(234/255,51/255,35/255,1),half4(234/255,83/255,243/255,1),half4(1,246/255,95/255,1),half4(1,1,1,1)};
   
    // foreground colours
    // 0 - black        1 - blue        2 - green           3 - cyan        4 - red         5 - magenta         6 - yellow          7 - white
    // 8 - unknown      9 - unknown     10 - unknown        11 - unknown    12 - unknown    13 - unknown        14 - unknown        15 - unknown
    // 16 - black II    17 - blue II    18 - green II       19 - cyan II    20 - red II     21 - magenta II     22 - yellow II      23 - white II
    // 24 - unknown     25 - unknown    26 - unknown        27 - unknown    28 - unknown    29 - unknown        30 - unknown        31 - unknown
    
    ycursor = int(position.y) % int(ScanLineHeight);    // calculate x pixel position in cell
    xcursor = int(position.x) % CellWidth;              // calculate x pixel position in cell
        
    screenpos = trunc(position.y/int(ScanLineHeight))*int(DisplayColumns)+trunc(position.x/CellWidth);  // return linear co-ordinates of character location based on pixel position
    
    int bitmask = (128 >> int(xcursor));
    
    if (screenram[screenpos] < 128)
    {
        fontpos = int(FontLocationOffset)+int(screenram[screenpos])*CellHeight+int(ycursor);  // return linear co-ordinates of font rom data
        pixelLocation = int(fontrom[fontpos]);
    }
    else
    {
        fontpos = int(screenram[screenpos]-128)*CellHeight+int(ycursor);  // return linear co-ordinates of pcg ram data
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
    
    switch (int(colorMode))
    {
        case 0 :    // green
            ForegroundColour = monoGreenColour;
            BackgroundColour = monoBlackColour;
            break;
        case 1 :    // amber
            ForegroundColour = monoAmberColour;
            BackgroundColour = monoBlackColour;
            break;
        case 2 :    // white
            ForegroundColour = monoWhiteColour;
            BackgroundColour = monoBlackColour;
            break;
        case 3 :    // blue
            ForegroundColour = monoBlueColour;
            BackgroundColour = monoBlackColour;
            break;
        default :   // colour mode
            ForegroundColour = foregroundColourArray[int(colourram[screenpos]) & 0x1F];
            BackgroundColour = backgroundColourArray[(int(colourram[screenpos]) & 0xE0) >> 5];
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
