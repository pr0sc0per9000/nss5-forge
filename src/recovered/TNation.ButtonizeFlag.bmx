' TNation.ButtonizeFlag
' VA 0x004BF221   1411 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Function, SIG (:TImage,i)i, slot 0x70
' MATCH 1411/1411 (mode=reloc, reloc_masked=36) via harness.try_method under
' NSS5_NO_LEARN=1, NSS5_WORKER=417.
'
' WHAT IT DOES
'  Turns a plain nation-flag TImage into a BUTTON in place: it locks the image's pixmap,
'  shades it with a vertical light-to-dark gradient, then rounds all four corners by
'  fading their alpha, and unlocks. It returns nothing meaningful (0) -- the image the
'  caller passed in has been modified.
'
'  Gradient: brightness is a per-ROW offset added to R, G and B alike. It starts at
'  -50 on the BOTTOM row and rises by +3 per row going up, so a 34px flag runs from
'  -50 at the bottom to +49 at the top. Each channel is clamped back into 0..255 by
'  ClampInt after the add, so the top of a white flag saturates rather than wrapping.
'  Alpha is forced to 255 over the whole gradient pass.
'
'  Corners: a fixed 6x6 alpha mask is applied to each corner, indexed [x][y] from that
'  corner inward. Row 0 (the outermost column) is 0,0,0,0,128,192 -- i.e. the outer
'  4 pixels of the corner are fully transparent -- and the mask reaches 255 three
'  pixels in. The same table is reused for all four corners by walking x and/or y
'  backwards from width-1 / height-1, which is why the four blocks are near-identical.
'  RGB is re-read and re-written unchanged; only alpha changes.
'
'  a1 <> 0 dumps the finished pixmap to GameMedia/Images/ButtonNationIm_<Rand(999)>.png.
'  That is a developer debug path: Rand(999) is Rand(minValue=999, maxValue=1 default),
'  so the number is in 1..999 and the file name is effectively random. Both callers
'  (TScreen_Continents 0x0051BE9F and 0x0051FC88) are believed to pass 0; not checked.
'
' ASSUMPTIONS
'  * Module Functions, both already byte-matched in src/recovered_module/:
'      ClampInt  0x00505F6D (Int Ptr form; the original almost certainly used Int Var --
'                identical bytes either way, `lea eax,[ebp-4]; push eax`)
'      PackARGB  0x005071E5 (r,g,b,a) -> ARGB Int
'  * BRL: LockImage(img) with all three defaults (frame 0, read 1, write 1) is what the
'    original's `push 1/push 1/push 0/push img` is; UnlockImage(img) likewise defaults
'    frame 0. SavePixmapPNG's third argument 5 is the default compression level, so the
'    source wrote a two-argument call.
'  * ReadPixel/WritePixel are METHOD calls on the pixmap (vtable +0x48 / +0x4c), NOT the
'    BRL wrapper Functions ReadPixel(pixmap,x,y) -- those compile to a direct E8 (see
'    Fn_0050802D.GreyscaleImage.bmx, which uses the Function form and shows the contrast).
'  * The two Float constants are read straight out of .data: -50.0 at 0x00C7058C and
'    3.0 at 0x00C70590.
'  * Parameter names are harness placeholders (a0, a1); not recoverable from the binary.
'
' SHAPE NOTES -- these were measured, not chosen
'  * `Local a:Int = cols[x][y]` in each corner block IS LOAD-BEARING, and it is the whole
'    difference between 1414 bytes and 1411. Without it the alpha is an inline argument
'    expression, bcc evaluates the PackARGB arguments strictly right-to-left (alpha first,
'    then b, g, r, each pushed as it is computed), and the resulting interference graph
'    lets `pm` keep ebx across the whole function. The original instead computes r, g, b
'    and a into four registers in source order and only then pushes them, which is what
'    four separate Locals produce. The knock-on effect is the entire remaining delta:
'    with `pm` in ebx the four corner loops' inner counters spill instead (20 stack slots,
'    `sub esp,0x50`), with `pm` spilled to [ebp-0x40] they keep edi (17 slots,
'    `sub esp,0x44` -- exactly the original). Do not "simplify" the four `Local a` away.
'  * Likewise the corner blocks' `Local r/g/b` are real Locals, not inlined shifts: they
'    land in ecx/edx/eax (call-clobbered is fine, they die at the push). The MAIN loop's
'    r/g/b are forced to [ebp-4]/[ebp-8]/[ebp-0xc] instead because ClampInt takes their
'    address.
'  * One `ex` Local is shared between the top-right and bottom-right blocks (re-assigned
'    `ex = w - 1` before the fourth), which is why both use [ebp-0x24]; the two `ey`
'    Locals are separate declarations inside their own outer loops and get separate slots.
'  * The main loop is x-outer / y-inner with y counting DOWN (`For y = h-1 To 0 Step -1`,
'    `add esi,-1` / `cmp esi,0` / `jge`); f is reset per column, so the gradient is
'    vertical and identical in every column.
	Local cols:Int[][] = [[0,0,0,0,128,192],[0,0,64,192,255,255],[0,64,255,255,255,255],[0,192,255,255,255,255],[128,255,255,255,255,255],[192,255,255,255,255,255]]
	Local pm:TPixmap = LockImage(a0)
	Local w:Int = pm.width
	Local h:Int = pm.height
	For Local x:Int = 0 To w - 1
		Local f:Float = -50.0
		For Local y:Int = h - 1 To 0 Step -1
			Local c:Int = pm.ReadPixel(x, y)
			Local r:Int = (c Shr 16) & $ff
			Local g:Int = (c Shr 8) & $ff
			Local b:Int = c & $ff
			r = r + f
			g = g + f
			b = b + f
			ClampInt(Varptr r, 0, 255)
			ClampInt(Varptr g, 0, 255)
			ClampInt(Varptr b, 0, 255)
			pm.WritePixel(x, y, PackARGB(r, g, b, 255))
			f = f + 3.0
		Next
	Next
	For Local x:Int = 0 To 5
		For Local y:Int = 0 To 5
			Local c:Int = pm.ReadPixel(x, y)
			Local r:Int = (c Shr 16) & $ff
			Local g:Int = (c Shr 8) & $ff
			Local b:Int = c & $ff
			Local a:Int = cols[x][y]
			pm.WritePixel(x, y, PackARGB(r, g, b, a))
		Next
	Next
	Local ex:Int = w - 1
	For Local x:Int = 0 To 5
		For Local y:Int = 0 To 5
			Local c:Int = pm.ReadPixel(ex, y)
			Local r:Int = (c Shr 16) & $ff
			Local g:Int = (c Shr 8) & $ff
			Local b:Int = c & $ff
			Local a:Int = cols[x][y]
			pm.WritePixel(ex, y, PackARGB(r, g, b, a))
		Next
		ex :- 1
	Next
	For Local x:Int = 0 To 5
		Local ey:Int = h - 1
		For Local y:Int = 0 To 5
			Local c:Int = pm.ReadPixel(x, ey)
			Local r:Int = (c Shr 16) & $ff
			Local g:Int = (c Shr 8) & $ff
			Local b:Int = c & $ff
			Local a:Int = cols[x][y]
			pm.WritePixel(x, ey, PackARGB(r, g, b, a))
			ey :- 1
		Next
	Next
	ex = w - 1
	For Local x:Int = 0 To 5
		Local ey:Int = h - 1
		For Local y:Int = 0 To 5
			Local c:Int = pm.ReadPixel(ex, ey)
			Local r:Int = (c Shr 16) & $ff
			Local g:Int = (c Shr 8) & $ff
			Local b:Int = c & $ff
			Local a:Int = cols[x][y]
			pm.WritePixel(ex, ey, PackARGB(r, g, b, a))
			ey :- 1
		Next
		ex :- 1
	Next
	If a1 Then SavePixmapPNG(pm, "GameMedia/Images/ButtonNationIm_" + Rand(999) + ".png")
	UnlockImage(a0)
