' TButton.CreateButton
' VA 0x00514FDC   342 bytes   KIND=Function (static), class-table slot 0x88
' sig ($,$,i,i,i,i,i,i,$,$,:TImage,()i,f,i,$):TButton
' byte-identical vs NSS5.exe (342/342, original length from Ghidra's inventory, mode=reloc)
'
' ASSUMPTIONS
'   Parameter order read off the decompilation:
'     a0 name, a1 txt, a2 x, a3 y, a4 w, a5 h, a6 alive, a7 fntSize, a8 colour,
'     a9 txtcolour, a10 icon, a11 fHit, a12 alph, a13 bstyle, a14 tooltip text.
'   Field offsets confirmed against already-recovered TButton.SetImage/SetButtonStyle/Delete
'   (bstyle +0x5C, image +0x60, imageoverride +0x64, icon +0x68) and TGadget's object-model
'   layout (name +0xC, x/y/h/w/desx/desy, alph +0x44, fntSize +0x4C, alive +0x38, colour
'   +0x30, txtcolour +0x34, fHit +0x40).
'   txt is not stored directly; it is passed through TGadget.SetText(a1, "", -1, -1) (slot
'   100), matching the empty-string-literal idiom used elsewhere in this corpus
'   (e.g. TCombo.CreateCombo).
'   0x0051AC96 = CreateGadgetImage, the recovered module Function
'   (src/recovered_module/CreateGadgetImage.bmx). image is only built when bstyle <> 10.
'   The icon guard is `If a10 <> Null Then b.SetIcon(a10)` (slot 0x90); the tooltip guard
'   reads the String length word: `If a14.Length <> 0 Then b.CreateToolTip(a14)` (slot 0x80).
	Function CreateButton:TButton(a0:String, a1:String, a2:Int, a3:Int, a4:Int, a5:Int, a6:Int, a7:Int, a8:String, a9:String, a10:TImage, a11:Int(), a12:Float, a13:Int, a14:String)
		Local b:TButton = New TButton
		b.name = a0
		b.x = a2
		b.desx = a2
		b.y = a3
		b.desy = a3
		b.w = a4
		b.h = a5
		b.alph = a12
		b.fntSize = a7
		b.SetText(a1, "", -1, -1)
		b.alive = a6
		b.colour = a8
		b.txtcolour = a9
		b.fHit = a11
		b.bstyle = a13
		If a13 <> 10 Then b.image = CreateGadgetImage(a4, a5, a13, 1, 0)
		If a10 <> Null Then b.SetIcon(a10)
		If a14.Length <> 0 Then b.CreateToolTip(a14)
		Return b
	End Function
