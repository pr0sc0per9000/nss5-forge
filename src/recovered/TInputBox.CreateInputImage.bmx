' TInputBox.CreateInputImage
' byte-identical vs NSS5.exe
' VA 0x00515750   391 bytes   mode=reloc   MATCH 391/391
' KIND=Method, SIG ()i, class-table slot 0x8c.
' Body-only format: statements only, parameters are a0, a1, ...
' Paints the input box's vertical grey gradient into a pixmap and loads it as Self.image.
'
' ASSUMPTIONS
'  * TInputBox Extends TGadget, so Self.w = +0x2c and Self.h = +0x28 (object_model.json).
'    Self.image = +0x68 (:TImage), and the decompiled release-then-store is bcc's inlined
'    BBRELEASE for that field, not source.
'  * 0x005B20BB is the alias set _brl_pixmap_CreatePixmap|_brl_ramstream_CreateRamStream;
'    CreatePixmap is the member that fits (four Int args, result gets ClearPixels/WritePixel
'    dispatched on it). 0x005AE256 = _brl_max2d_LoadImage. 0x005071E5 = PackARGB from
'    src/recovered_module/. 0x005B9690 = _bbFloatToInt, i.e. every Int(...) below.
'  * Ghidra merges the following call's pushes into _bbFloatToInt's argument list, so its
'    "FUN_005b9690((double)Self.h,6,4)" is a ONE-argument Int(Self.h); the 6 and 4 are
'    CreatePixmap's format and align. Confirmed against the raw disassembly.
'  * TPixmap slot 0x58 = ClearPixels, slot 0x4c = WritePixel (BRL brl.pixmap).
'  * The seven float constants were read out of NSS5.exe .rdata:
'      0x00C7E02C=1.0  0x00C7E030=1.0  0x00C7E034=255.0  0x00C7E038=96.0
'      0x00C7E03C=2.0  0x00C7E040=245.0 0x00C7E044=96.0
'  * The comparison is spelled y >= Self.h / 2.0 (y evaluated FIRST -- fild before the
'    fld/fdiv), not Ghidra's normalised "Self.h / 2.0 <= y".
'  * No Globals used.
Local p:TPixmap = CreatePixmap(Int(Self.w), Int(Self.h), 6, 4)
p.ClearPixels(0)
For Local x:Int = 0 To Int(Self.w - 1.0)
	For Local y:Int = Int(Self.h - 1.0) To 0 Step -1
		Local c:Float = 255.0 - 96.0 / Self.h * y
		If y >= Self.h / 2.0 Then c = 245.0 - 96.0 / Self.h * y
		p.WritePixel(x, y, PackARGB(Int(c), Int(c), Int(c), 255))
	Next
Next
Self.image = LoadImage(p, -1)
