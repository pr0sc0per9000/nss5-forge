' CreateGadgetImage  -- module-level Function (no Type)
' VA 0x0051ac96   1787 bytes   sig (i,i,i,i,i):TImage   ** 15 call sites across 6 functions **
' byte-identical vs NSS5.exe (1787/1787, original length from Ghidra's inventory)
' harness mode=reloc, reloc_masked=49, NSS5_NO_LEARN=1, no learned helpers.
'
' NAME IS OURS. Paints a gadget background into a TPixmap and returns it as a TImage:
' a vertical grey gradient (255 -> 159 down the height), optionally darkened by 10 over the
' bottom half, then up to four 6x6 alpha-feathered corners chosen by the style code, then
' LoadImage. Reached from TButton.SetButtonStyle, TPanel and TCombo image builders.
'
' PARAMETERS, read off the call sites and the body:
'   a0 w, a1 h            pixel size; under 12 in either axis returns Null
'   a2 style              corner bitmask-by-enumeration, see the four guards below
'   a3 button             1 = button (darker bottom half + "btn_" dump name), 0 = label
'   a4 savepng            debug: dump the pixmap to <name>.png before loading it
'
' ASSUMPTIONS
'  * 0x005B20BB is the alias set _brl_pixmap_CreatePixmap|_brl_ramstream_CreateRamStream;
'    CreatePixmap is the member that fits, and its format/align arguments are written as the
'    bare 6 and 4 the original pushes -- our headers bind PF_BGRA8888 to 5, which emits
'    `push 5` and mismatches. Same spelling as the verified TInputBox.CreateInputImage.
'  * TPixmap slots: 0x48 ReadPixel, 0x4c WritePixel, 0x58 ClearPixels (BRL brl.pixmap).
'  * 0x005071E5 = PackARGB (src/recovered_module/PackARGB.bmx, 38/38 exact).
'    0x0059C456 = _brl_pngloader_SavePixmapPNG, its compression=5 default emitted at the
'    call site. 0x005AE256 = _brl_max2d_LoadImage. 0x005B9690 = _bbFloatToInt = Int(...).
'  * 0x00C5BC8C is the BBArray element descriptor "[]i" and 0x00C59097 is "i", so the colour
'    table is Int[][] -- read directly out of NSS5.exe, not inferred.
'  * The four float constants are in this function's own literal pool:
'      0x00C7E2E8 = 255.0   0x00C7E2EC = 96.0   0x00C7E2F0 = 245.0   0x00C7E2F4 = 96.0
'  * The four string literals were read with harness.read_string:
'      0x00C7E308 'btn_'  0x00C7E31C 'lbl_'  0x00C7E2F8 'x'  0x00C6FD4C '.png'
'  * No Globals used.
'
' WHY THE r/g/b/al LOCALS ARE LOAD-BEARING (this was the whole 77-byte deficit).
' Written as one nested expression -- PackARGB((p Shr 16) & 255, ..., cols[i][j]) -- the body
' is 1710 bytes: bcc pushes right-to-left evaluating each argument as it goes, which leaves
' enough registers free that `pix` stays in ebx and each outer `i` keeps edi. The original
' computes all four arguments into registers in SOURCE order (ecx, edx, eax, esi) and only
' then pushes in reverse, which is what four named Locals produce. Those four extra live
' values are exactly the register pressure that spills `pix`, `cols` and all four outer
' loop counters to the frame -- original `sub esp,0x34` (13 slots) against our `sub esp,0x20`
' (8). See codegen-patterns 18.4: the lever was liveness, not declaration order.
	Function CreateGadgetImage:TImage(a0:Int, a1:Int, a2:Int, a3:Int, a4:Int)
		If a0 < 12 Or a1 < 12 Then Return Null
		Local cols:Int[][] = [ [0,0,0,0,128,192], [0,0,64,192,255,255], [0,64,255,255,255,255], [0,192,255,255,255,255], [128,255,255,255,255,255], [192,255,255,255,255,255] ]
		Local pix:TPixmap = CreatePixmap(a0, a1, 6, 4)
		pix.ClearPixels(0)
		For Local x:Int = 0 To a0 - 1
			For Local y:Int = a1 - 1 To 0 Step -1
				Local c:Float = 255.0 - 96.0 / a1 * y
				If a3 And y >= a1 / 2
					c = 245.0 - 96.0 / a1 * y
				EndIf
				pix.WritePixel(x, y, PackARGB(Int(c), Int(c), Int(c), 255))
			Next
		Next
		If a2 = 1 Or a2 = 2 Or a2 = 4 Or a2 = 6
			For Local i:Int = 0 To 5
				For Local j:Int = 0 To 5
					Local p:Int = pix.ReadPixel(i, j)
					Local r:Int = (p Shr 16) & 255
					Local g:Int = (p Shr 8) & 255
					Local b:Int = p & 255
					Local al:Int = cols[i][j]
					pix.WritePixel(i, j, PackARGB(r, g, b, al))
				Next
			Next
		EndIf
		If a2 = 1 Or a2 = 2 Or a2 = 5 Or a2 = 7
			Local xx:Int = a0 - 1
			For Local i:Int = 0 To 5
				For Local j:Int = 0 To 5
					Local p:Int = pix.ReadPixel(xx, j)
					Local r:Int = (p Shr 16) & 255
					Local g:Int = (p Shr 8) & 255
					Local b:Int = p & 255
					Local al:Int = cols[i][j]
					pix.WritePixel(xx, j, PackARGB(r, g, b, al))
				Next
				xx :- 1
			Next
		EndIf
		If a2 = 1 Or a2 = 3 Or a2 = 4 Or a2 = 9
			For Local i:Int = 0 To 5
				Local yy:Int = a1 - 1
				For Local j:Int = 0 To 5
					Local p:Int = pix.ReadPixel(i, yy)
					Local r:Int = (p Shr 16) & 255
					Local g:Int = (p Shr 8) & 255
					Local b:Int = p & 255
					Local al:Int = cols[i][j]
					pix.WritePixel(i, yy, PackARGB(r, g, b, al))
					yy :- 1
				Next
			Next
		EndIf
		If a2 = 1 Or a2 = 3 Or a2 = 5 Or a2 = 8
			Local xr:Int = a0 - 1
			For Local i:Int = 0 To 5
				Local yr:Int = a1 - 1
				For Local j:Int = 0 To 5
					Local p:Int = pix.ReadPixel(xr, yr)
					Local r:Int = (p Shr 16) & 255
					Local g:Int = (p Shr 8) & 255
					Local b:Int = p & 255
					Local al:Int = cols[i][j]
					pix.WritePixel(xr, yr, PackARGB(r, g, b, al))
					yr :- 1
				Next
				xr :- 1
			Next
		EndIf
		If a4
			If a3
				SavePixmapPNG(pix, "btn_" + a0 + "x" + a1 + ".png")
			Else
				SavePixmapPNG(pix, "lbl_" + a0 + "x" + a1 + ".png")
			EndIf
		EndIf
		Return LoadImage(pix, -1)
	End Function
