#include <metal_stdlib>
using namespace metal;

[[ stitchable ]] half4 ScreenBuffer(float2 position, half4 color, float ScanLineHeight, float DisplayColumns, float displayOffset, float alternateFontROM, float CursorPosition, float CursorStartScanLine, float CursorEndScanLine, float CursorBlinkType, float colorMode, float backGroundIntensity, float timeElapsed, device const float *screenram, int screenramsize, device const float *fontrom, int fontromsize, device const float *pcgram, int pcgramsize, device const float *colourram, int colourramsize)
{
    half4 ForegroundColour;
    half4 BackgroundColour;
    int screenpos;
    int fontpos;
    int xcursor;
    int ycursor;
    bool pixelset;
    
    float cursorblinkInterval;
    
    if (int(CursorBlinkType) == 2)
    {
        cursorblinkInterval = 0.25;  // not sure how this is 50zhz/16 but it appears to work
    }
    else
    {
        cursorblinkInterval = 0.125; // not sure how this is 50zhz/32 but it appears to work
    }
    
    uint cursorStep = (uint)floor(timeElapsed/cursorblinkInterval);
    bool cursorOn = (cursorStep & 1u) == 0u;
    
    int pixelLocation;
    
    const int CellWidth = 8;            // each character in font ROM is 8 pixels wide
    const int CellHeight = 16;          // each character in font ROM is 16 pixels high
    
    const half4 monoGreenColour = half4(0.45,0.96,0.36,1);          // monochrome - green
    const half4 monoAmberColour = half4(1,0.749,0,1);               // monochrome - amber
    const half4 monoBlueColour = half4(0.68,0.85,0.9,1);            // monochrome - blue
    const half4 monoWhiteColour = half4(1,1,1,1);                   // monochrome - white
    const half4 monoBlackColour = half4(0,0,0,1);                   // monochrome - black

    // background colours
    // 0 - black        1 - red         2 - green           3 - yellow      4 - blue        5 - magenta         6 - cyan            7 - white
    // foreground colours
    // 0 - black        1 - blue        2 - green           3 - cyan        4 - red         5 - magenta         6 - yellow          7 - white
    // 8 - unknown      9 - unknown     10 - unknown        11 - unknown    12 - unknown    13 - unknown        14 - unknown        15 - unknown
    // 16 - black II    17 - blue II    18 - green II       19 - cyan II    20 - red II     21 - magenta II     22 - yellow II      23 - white II
    // 24 - unknown     25 - unknown    26 - unknown        27 - unknown    28 - unknown    29 - unknown        30 - unknown        31 - unknown
    
    half4 backgroundColourArray[8][8] = {
            {half4(0,0,0,1), half4(0.61,0.12,0.08,1), half4(0.29,0.66,0.24,1), half4(0.66,0.67,0.25,1), half4(0.07,0.1,0.95,1), half4(0.61,0.21,0.64,1), half4(0.3,0.65,0.66,1), half4(0.67,0.67,0.67,1)},
            {half4(0.3,0.04,0.02,1), half4(0.92,0.2,0.14,1), half4(0.42,0.66,0.24,1), half4(0.95,0.68,0.26,1), half4(0.31,0.2,0.64,1), half4(0.92,0.23,0.65,1), half4(0.42,0.65,0.66,1), half4(0.95,0.68,0.67,1)},
            {half4(0.13,0.33,0.1,1), half4(0.62,0.35,0.13,1), half4(0.45,0.96,0.36,1), half4(0.74,0.96,0.36,1), half4(0.14,0.33,0.64,1), half4(0.62,0.35,0.65,1), half4(0.46,0.97,0.69,1), half4(0.74,0.98,0.69,1)},
            {half4(0.33,0.33,0.11,1), half4(0.93,0.38,0.16,1), half4(0.53,0.96,0.36,1), half4(1,0.96,0.37,1), half4(0.34,0.33,0.64,1), half4(0.92,0.38,0.66,1), half4(0.54,0.98,0.69,1), half4(1,0.98,0.7,1)},
            {half4(0,0.08,0.32,1), half4(0.61,0.12,0.33,1), half4(0.3,0.65,0.37,1), half4(0.67,0.67,0.38,1), half4(0.07,0.31,0.95,1), half4(0.61,0.31,0.95,1), half4(0.3,0.65,0.96,1), half4(0.67,0.67,0.97,1)},
            {half4(0.31,0.09,0.32,1), half4(0.92,0.2,0.35,1), half4(0.42,0.66,0.37,1), half4(0.95,0.68,0.4,1), half4(0.31,0.31,0.95,1), half4(0.31,0.31,0.95,1), half4(0.42,0.66,0.96,1), half4(0.95,0.68,0.97,1)},
            {half4(0.13,0.33,0.33,1), half4(0.62,0.35,0.34,1), half4(0.45,0.96,0.42,1), half4(0.74,0.96,0.43,1), half4(0.15,0.32,0.95,1), half4(0.63,0.35,0.95,1), half4(0.46,0.98,0.99,1), half4(0.74,0.99,0.99,1)},
            {half4(0.74,0.99,0.99,1), half4(0.93,0.38,0.36,1), half4(0.54,0.96,0.42,1), half4(1,0.97,0.44,1), half4(0.34,0.33,0.95,1), half4(0.93,0.38,0.95,1), half4(0.54,0.99,0.99,1), half4(1,1,1,1)}};
    
    half4 foregroundColourArray[32] = {half4(0,0,0,1), half4(0.07,0.1,0.95,1), half4(0.45,0.96,0.36,1), half4(0.46,0.98,0.99,1), half4(0.92,0.2,0.14,1), half4(0.92,0.33,0.95,1), half4(1,0.96,0.37,1), half4(1,1,1,1),
                                       half4(0.3,0.65,0.96,1), half4(0.46,0.98,0.7,1), half4(0.62,0.31,0.95,1), half4(0.92,0.33,0.95,1), half4(0.74,0.96,0.36,1), half4(0.95,0.68,0.26,1),  half4(0.67,0.66,0.67,1), half4(1,1,1,1),
                                       half4(0,0,0,1), half4(0.02,0.2,0.65,1), half4(0.29,0.65,0.24,1), half4(0.29,0.65,0.67,1), half4(0.62,0.12,0.08,1), half4(0.62,0.21,0.65,1), half4(0.67,0.66,0.24,1), half4(0.67,0.66,0.67,1),
                                       half4(0.67,0.66,0.96,1), half4(0.75,0.98,0.7,1), half4(0.75,0.99,1,1), half4(0.95,0.68,0.68,1), half4(0.95,0.68,0.97,1), half4(1,0.98,0.71,1), half4(0.67,0.66,0.67,1), half4(1,1,1,1)};
   
    ycursor = int(position.y) % int(ScanLineHeight);    // calculate x pixel position in cell
    xcursor = int(position.x) % CellWidth;              // calculate x pixel position in cell
        
    screenpos = trunc(position.y/int(ScanLineHeight))*int(DisplayColumns)+trunc(position.x/CellWidth);  // return linear co-ordinates of character location based on pixel position
    
    screenpos = (screenpos + int(displayOffset)) & 2047;
    
    int clampedCursorPosition = int(CursorPosition) & 2047;
    
    int bitmask = (128 >> int(xcursor));
    
    int FontLocationOffset = int(alternateFontROM)*2048;
        
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
    
    if (screenpos == clampedCursorPosition)
    {
        
        bool cursorInside = (ycursor >= int(CursorStartScanLine)) && (ycursor <= int(CursorEndScanLine));
        
        switch (int(CursorBlinkType))
        {
            case 0: // 0 = always on
                    if (cursorInside)
                    {
                        pixelset = !pixelset;
                    }
                    break;
            case 1: break; // 1 = always off
            case 2: // 2 = normal flash 1/16 frame rate
                    // if ((ycursor >= int(CursorStartScanLine)) && (ycursor <= int(CursorEndScanLine)) && ( int(CursorBlinkCounter) < int(CursorFlashLimit) ))
                    if (cursorInside && cursorOn)
                    {
                        pixelset = !pixelset;
                    }
                    break;
            case 3: // 3 = fast flash 1/32 frame rate
                    if (cursorInside && cursorOn)
                    //if ((ycursor >= int(CursorStartScanLine)) && (ycursor <= int(CursorEndScanLine)) && ( int(CursorBlinkCounter) < int(CursorFlashLimit) ))
                    {
                        pixelset = !pixelset;
                    }
                    break;
        }
    }
    
    switch (int(colorMode))
    {
        case 0 :    // Green on Black
            ForegroundColour = monoGreenColour;
            BackgroundColour = monoBlackColour;
            break;
        case 1 :    // Amber on Black
            ForegroundColour = monoAmberColour;
            BackgroundColour = monoBlackColour;
            break;
        case 2 :    // White on Black
            ForegroundColour = monoWhiteColour;
            BackgroundColour = monoBlackColour;
            break;
        case 3 :    // Blue on Black
            ForegroundColour = monoBlueColour;
            BackgroundColour = monoBlackColour;
            break;
        case 4 :    // Colour
            ForegroundColour = foregroundColourArray[int(colourram[screenpos]) & 0x1F];
            BackgroundColour = backgroundColourArray[int(backGroundIntensity)][(int(colourram[screenpos]) & 0xE0) >> 5];
            break;
        default :   // Colour
            ForegroundColour = foregroundColourArray[int(colourram[screenpos]) & 0x1F];
            BackgroundColour = backgroundColourArray[int(backGroundIntensity)][(int(colourram[screenpos]) & 0xE0) >> 5];
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

[[ stitchable ]]
half4 interlace(float2 position, half4 color, float spacing, float intensity, float brightnessBoost, float interlaceEnabled)
{
    if (interlaceEnabled > 0.5)
    {
        float yValue = fmod(position.y, spacing);
        
        if (yValue < (spacing * 0.5))
        {
            return color * half4(intensity, intensity, intensity, 1.0);
        }
        else
        {
            half4 boosted = color * brightnessBoost;
            boosted.a = color.a;
            return boosted;
        }
    }
    else
    {
        return color;
    }
}
