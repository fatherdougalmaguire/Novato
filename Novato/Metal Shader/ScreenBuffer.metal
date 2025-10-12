#include <metal_stdlib>
using namespace metal;

[[ stitchable ]] half4 ScreenBuffer(float2 position, half4 color, float eightycol, device const float *screenram, int screenramsize, device const float *pcgchar, int pcgcharsize)
{
    half4 thingy;
    half4 drawingcolor;
    int screenpos;
    int pcgpos;
    int xcursor;
    int ycursor;
    
    drawingcolor = half4(1.0,0.749,0,1);
 
    if (int(eightycol) == 1)
    {
        ycursor = int(position.y) % int(11); // 16 refers to pixels high - 16 for 64x16 and 11 for 80x24
        xcursor = int(position.x) % 8;  // 8 refers to pixels wide - 8 for 64x16 and 80x25
        
        screenpos = trunc(position.y/11)*int(80)+trunc(position.x/8.0); // screenram - 16 refers to pixels high - 16 for 64x16 and 11 for 80x24,8 refers to pixels wide - 8 for 64x16 and 80x25, 80 refers to columns of text
        pcgpos = int(2048)+int(screenram[screenpos])*16+int(ycursor);  // 16 refers to PCG data - 16 for 64x16 and 80x24
    }
    else
    {
        ycursor = int(position.y) % int(16); // 16 refers to pixels high - 16 for 64x16 and 11 for 80x24
        xcursor = int(position.x) % 8;  // 8 refers to pixels wide - 8 for 64x16 and 80x25
        
        screenpos = trunc(position.y/16)*int(64)+trunc(position.x/8.0); // screenram - 16 refers to pixels high - 16 for 64x16 and 11 for 80x24,8 refers to pixels wide - 8 for 64x16 and 80x25, 64 refers to columns of text
        pcgpos = int(0)+int(screenram[screenpos])*16+int(ycursor);  // 16 refers to PCG data - 16 for 64x16 and 80x24
    }
    
    int bitmask = (128 >> int(xcursor));
    
    if ((int(pcgchar[pcgpos]) & bitmask)  > 0 )
    {
        thingy = drawingcolor;
    }
    else
    {
        thingy = half4(0.0,0.0,0.0,1.0);
    }
    
    return thingy;
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
