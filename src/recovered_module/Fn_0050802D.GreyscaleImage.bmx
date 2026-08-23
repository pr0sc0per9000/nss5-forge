' GreyscaleImage  -- module-level Function (no Type). NAME IS OURS (no reflection record).
' VA 0x0050802d   260 bytes   sig (:TPixmap):TImage
' byte-identical vs NSS5.exe (260/260, original length from Ghidra's inventory), verified
' with harness.try_function under NSS5_NO_LEARN=1.
'
' Converts a pixmap to greyscale IN PLACE and returns it as a TImage. The weights are the
' standard luminance coefficients, read directly out of the exe as Float constants:
' 0.299 at 0x00C7C340, 0.587 at 0x00C7C344, 0.114 at 0x00C7C348.
'
' THE ONE FUNCTION IN THIS AUDIT WITH A LIVE CALLER: TScreen_Stable.Update (0x00588C99)
' calls it at 0x00588C99's single call site. That method is itself still unrecovered, so
' this body was blocking it in exactly the way the 83-byte clipboard helper blocked
' TInputBox.Update. Found by the unrecovered-function audit; see
' docs/reference/unrecovered-inventory.md.
'
' BUG (original), preserved: the alpha channel is discarded. The written pixel is
' (c Shl 16) | (c Shl 8) | c with no alpha term, so every pixel comes back fully
' transparent in a PF_RGBA8888 sense; it works only because the pixmap has just been
' converted to PF_RGB888 (4), which has no alpha to lose.
'
' THE THREE COMPONENT LOCALS ARE LOAD-BEARING. The original extracts r, g and b into three
' registers BEFORE any x87 work starts:
'     00508090  89 C8  mov eax, ecx / 25 0000FF00  and eax,0xFF0000 / C1 E8 10  shr eax,16
'     0050809A  89 D2  mov edx, eax                                  <- r
'     0050809C  89 C8  mov eax, ecx / 25 00FF0000  and eax,0xFF00   / C1 E8 08  shr eax,8
'     005080A6  81 E1  and ecx, 0xFF                                 <- b
'     005080AC  89 55 F8 / DB 45 F8 / D8 0D ..     fild r  * 0.299
' Folding them into one expression is still 257 bytes and still matches the first 58, but
' bcc then interleaves each `and`/`shr` with its own fild/fmul and the body comes out three
' bytes short. Measured both ways.
'
' PF_RGB888 is 4 in this BlitzMax (mod/brl.mod/pixmap.mod/pixel.bmx); the original pushes
' the bare literal 4, which is what the constant compiles to.
	Function GreyscaleImage:TImage(a0:TPixmap)
		If PixmapFormat(a0) <> PF_RGB888 Then a0 = ConvertPixmap(a0, PF_RGB888)
		For Local x:Int = 0 To a0.width - 1
			For Local y:Int = 0 To a0.height - 1
				Local p:Int = ReadPixel(a0, x, y)
				Local r:Int = (p & $FF0000) Shr 16
				Local g:Int = (p & $FF00) Shr 8
				Local b:Int = p & $FF
				Local c:Int = Int(r * 0.299 + g * 0.587 + b * 0.114)
				WritePixel(a0, x, y, (c Shl 16) | (c Shl 8) | c)
			Next
		Next
		Return LoadImage(a0)
	End Function
