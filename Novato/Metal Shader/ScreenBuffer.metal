#include <metal_stdlib>
using namespace metal;

[[ stitchable ]] half4 ScreenBuffer(float2 position, half4 color, float ScanLineHeight, float DisplayColumns, float FontLocationOffset, float CursorPosition, float PhosphorColour, device const float *screenram, int screenramsize, device const float *pcgchar, int pcgcharsize)
{
    half4 pixelcolor;
    int screenpos;
    int pcgpos;
    int xcursor;
    int ycursor;
    
    const int CellWidth = 8;            // each character in font ROM is 8 pixels wide
    const int CellHeight = 16;          // each character in font ROM is 16 pixels high
    
    switch (int(PhosphorColour))
    {
    case 0 :    // green
        pixelcolor = half4(0,1,0.2,1);
        break;
    case 1 :    // amber
        pixelcolor = half4(1,0.749,0,1);
        break;
    case 2 :    // white
        pixelcolor = half4(1,1,1,1);
        break;
    default :   // red
        pixelcolor = half4(1,0,0,1);
    }
    
    ycursor = int(position.y) % int(ScanLineHeight);    // calculate x pixel position in cell
    xcursor = int(position.x) % CellWidth;              // calculate x pixel position in cell
        
    screenpos = trunc(position.y/int(ScanLineHeight))*int(DisplayColumns)+trunc(position.x/CellWidth);  // return linear co-ordinates of character location based on pixel position
    pcgpos = int(FontLocationOffset)+int(screenram[screenpos])*CellHeight+int(ycursor);                 // return linear co-ordinates of font rom data
    
    int bitmask = (128 >> int(xcursor));
    
    if ((int(pcgchar[pcgpos]) & bitmask)  > 0 )
    {
        return pixelcolor;
    }
    else
    {
        return half4(0.0,0.0,0.0,1.0);
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
