param(
    [string]$FrameDirectory = '.godot/wisp_motion_preview',
    [string]$OutputPath = 'docs/previews/moon_wisp_afterimages.gif',
    [ValidateRange(1,65535)][int]$FrameDelayCentiseconds = 8
)

# Encode rendered gameplay screenshots, never the source animation assets.
# Each frame keeps its own palette; no resizing or cropping is performed.
Add-Type -AssemblyName System.Drawing
Add-Type -TypeDefinition @'
using System;
using System.IO;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;
using System.Collections.Generic;
public static class WispPreviewGif {
    private sealed class Bin {
        public long count, r, g, b;
        public int R { get { return (int)(r / count); } }
        public int G { get { return (int)(g / count); } }
        public int B { get { return (int)(b / count); } }
    }
    private sealed class Box {
        public List<Bin> bins;
        public long count;
        public int channel, range;
        public Box(List<Bin> values) {
            bins = values;
            int[] low = {255,255,255}, high = {0,0,0};
            foreach (var v in values) {
                count += v.count;
                int[] rgb = {v.R,v.G,v.B};
                for (int c=0;c<3;c++) {
                    low[c]=Math.Min(low[c],rgb[c]); high[c]=Math.Max(high[c],rgb[c]);
                }
            }
            for (int c=0;c<3;c++) if (high[c]-low[c] > range) {
                range=high[c]-low[c]; channel=c;
            }
        }
    }
    private static byte[] Pixels(Bitmap bitmap) {
        var locked=bitmap.LockBits(new Rectangle(0,0,bitmap.Width,bitmap.Height),ImageLockMode.ReadOnly,PixelFormat.Format32bppArgb);
        byte[] pixels=new byte[bitmap.Width*bitmap.Height*4];
        for(int y=0;y<bitmap.Height;y++) Marshal.Copy(IntPtr.Add(locked.Scan0,y*locked.Stride),pixels,y*bitmap.Width*4,bitmap.Width*4);
        bitmap.UnlockBits(locked);
        return pixels;
    }
    private static Color[] BuildPalette(string[] files) {
        Bin[] histogram=new Bin[32768];
        foreach (var file in files) using(var bitmap=new Bitmap(file)) {
            byte[] pixels=Pixels(bitmap);
            for(int p=0;p<pixels.Length;p+=16) { // quarter-pixel sampling
                int b=pixels[p],g=pixels[p+1],r=pixels[p+2];
                int key=((r>>3)<<10)|((g>>3)<<5)|(b>>3);
                if(histogram[key]==null) histogram[key]=new Bin();
                var bin=histogram[key]; bin.count++; bin.r+=r; bin.g+=g; bin.b+=b;
            }
        }
        var used=new List<Bin>();
        foreach(var bin in histogram) if(bin!=null) used.Add(bin);
        var boxes=new List<Box>(); boxes.Add(new Box(used));
        while(boxes.Count<248) {
            int best=-1; double score=-1;
            for(int i=0;i<boxes.Count;i++) if(boxes[i].bins.Count>1) {
                double candidate=boxes[i].range*Math.Sqrt(boxes[i].count);
                if(candidate>score) {score=candidate;best=i;}
            }
            if(best<0) break;
            var box=boxes[best]; int channel=box.channel;
            box.bins.Sort(delegate(Bin a,Bin b) {
                return (channel==0?a.R:channel==1?a.G:a.B).CompareTo(channel==0?b.R:channel==1?b.G:b.B);
            });
            long mass=0; int split=1;
            for(int i=0;i<box.bins.Count-1;i++) {
                mass+=box.bins[i].count; split=i+1;
                if(mass>=box.count/2) break;
            }
            boxes[best]=new Box(box.bins.GetRange(0,split));
            boxes.Add(new Box(box.bins.GetRange(split,box.bins.Count-split)));
        }
        Color[] palette=new Color[256];
        for(int i=0;i<248;i++) {
            if(i>=boxes.Count) {palette[i]=Color.Black;continue;}
            long r=0,g=0,b=0,count=0;
            foreach(var bin in boxes[i].bins) {r+=bin.r;g+=bin.g;b+=bin.b;count+=bin.count;}
            palette[i]=Color.FromArgb((int)(r/count),(int)(g/count),(int)(b/count));
        }
        // Preserve the rare bright spirit/UI highlights in a dark scene.
        Color[] highlights={Color.White,Color.FromArgb(255,235,235),Color.FromArgb(255,200,210),Color.FromArgb(255,160,180),Color.FromArgb(240,120,155),Color.FromArgb(220,190,210),Color.FromArgb(200,170,190),Color.FromArgb(230,220,225)};
        Array.Copy(highlights,0,palette,248,8);
        return palette;
    }
    private static byte[] ColorMap(Color[] palette) {
        byte[] map=new byte[32768];
        for(int key=0;key<map.Length;key++) {
            int r=((key>>10)&31)*8+4,g=((key>>5)&31)*8+4,b=(key&31)*8+4;
            int best=0; double distance=Double.MaxValue;
            for(int i=0;i<256;i++) {
                double dr=r-palette[i].R,dg=g-palette[i].G,db=b-palette[i].B;
                double d=dr*dr*.3+dg*dg*.59+db*db*.11;
                if(d<distance) {distance=d;best=i;}
            }
            map[key]=(byte)best;
        }
        return map;
    }
    private static byte[] IndexedGif(string file,Color[] colors,byte[] map) {
        using(var source=new Bitmap(file))
        using(var bitmap=new Bitmap(source.Width,source.Height,PixelFormat.Format8bppIndexed))
        using(var buffer=new MemoryStream()) {
            var palette=bitmap.Palette;
            for(int i=0;i<256;i++) palette.Entries[i]=colors[i];
            bitmap.Palette=palette;
            byte[] pixels=Pixels(source);
            var locked=bitmap.LockBits(new Rectangle(0,0,bitmap.Width,bitmap.Height),ImageLockMode.WriteOnly,PixelFormat.Format8bppIndexed);
            byte[] row=new byte[bitmap.Width];
            for(int y=0;y<bitmap.Height;y++) {
                for(int x=0;x<bitmap.Width;x++) {
                    int p=(y*bitmap.Width+x)*4;
                    int key=((pixels[p+2]>>3)<<10)|((pixels[p+1]>>3)<<5)|(pixels[p]>>3);
                    row[x]=map[key];
                }
                Marshal.Copy(row,0,IntPtr.Add(locked.Scan0,y*locked.Stride),row.Length);
            }
            bitmap.UnlockBits(locked);
            bitmap.Save(buffer,ImageFormat.Gif);
            return buffer.ToArray();
        }
    }
    public static void Encode(string[] files, string output, int delay) {
        Color[] colors=BuildPalette(files);
        byte[] colorMap=ColorMap(colors);
        using (var writer = new BinaryWriter(File.Create(output))) {
            bool started = false;
            foreach (var file in files) {
                byte[] gif=IndexedGif(file,colors,colorMap);
                int globalBits = gif[10] & 7;
                int paletteLength = 3 * (1 << (globalBits + 1));
                byte[] palette = new byte[paletteLength];
                Array.Copy(gif, 13, palette, 0, paletteLength);
                int position = 13 + paletteLength;
                if (!started) {
                    writer.Write(System.Text.Encoding.ASCII.GetBytes("GIF89a"));
                    writer.Write(gif, 6, 4); // original width and height
                    writer.Write(new byte[] {0x70, 0, 0}); // local palettes
                    writer.Write(new byte[] {0x21,0xff,0x0b});
                    writer.Write(System.Text.Encoding.ASCII.GetBytes("NETSCAPE2.0"));
                    writer.Write(new byte[] {3,1,0,0,0}); // loop forever
                    started = true;
                }
                while (gif[position] == 0x21) {
                    position += 2;
                    while (gif[position] != 0) position += 1 + gif[position];
                    position++;
                }
                if (gif[position++] != 0x2c) throw new Exception("Missing GIF image");
                byte[] descriptor = new byte[9];
                Array.Copy(gif, position, descriptor, 0, 9);
                position += 9;
                int bits = globalBits;
                if ((descriptor[8] & 0x80) != 0) {
                    bits = descriptor[8] & 7;
                    paletteLength = 3 * (1 << (bits + 1));
                    palette = new byte[paletteLength];
                    Array.Copy(gif, position, palette, 0, paletteLength);
                    position += paletteLength;
                }
                writer.Write(new byte[] {0x21,0xf9,4,4,(byte)(delay & 255),(byte)(delay >> 8),0,0});
                writer.Write((byte)0x2c);
                descriptor[8] = (byte)((descriptor[8] & 0x40) | 0x80 | bits);
                writer.Write(descriptor);
                writer.Write(palette);
                int dataStart = position++; // LZW minimum code size
                while (gif[position] != 0) position += 1 + gif[position];
                position++;
                writer.Write(gif, dataStart, position - dataStart);
            }
            writer.Write((byte)0x3b);
        }
    }
}
'@ -ReferencedAssemblies System.Drawing

$frameFiles = @(Get-ChildItem -LiteralPath $FrameDirectory -Filter 'frame_*.png' |
    Sort-Object Name | ForEach-Object { $_.FullName })
[WispPreviewGif]::Encode($frameFiles, [IO.Path]::GetFullPath($OutputPath), $FrameDelayCentiseconds)
$preview = [Drawing.Image]::FromFile([IO.Path]::GetFullPath($OutputPath))
$dimension = [Drawing.Imaging.FrameDimension]::new($preview.FrameDimensionsList[0])
Write-Output ('GIF: {0} frames, {1}x{2}' -f $preview.GetFrameCount($dimension), $preview.Width, $preview.Height)
$preview.Dispose()
