' TProgressBar.CreateProgressBar
' VA 0x0051A4AA   329 bytes   KIND=Function, class-table slot 0x88
' sig ($,$,i,i,i,i,i,$,$,$,f,i,:TImage):TProgressBar
' byte-identical vs NSS5.exe (329/329, original length from Ghidra's inventory, mode=reloc)
'
' ASSUMPTIONS
'   Parameter order read off the decompilation and the two internal calls:
'     a0 name, a1 text, a2 x, a3 y, a4 w, a5 h, a6 fntSize, a7 colour, a8 fillcolour,
'     a9 txtcolour, a10 alph, a11 icon-style (passed to CreateGadgetImage), a12 fillicon.
'   TGadget.name is confirmed at +0xC by TGadget.GetActiveGadgetName ("g.name" reads
'     piVar[3]). x/y/w/h/colour/fillcolour/image/fillimage/fillicon offsets confirmed by
'     TProgressBar.Draw and TProgressBar.SetColour, already in this corpus.
'   CreateGadgetImage is the recovered module Function at 0x0051AC96
'     (src/recovered_module/CreateGadgetImage.bmx); fillimage always uses the fixed
'     32x32/style-0/button-1 icon-holder image, matching every other CreateXxx factory
'     in this Type family (TLabel.CreateLabel etc.) that builds a second plate this way.
	Function CreateProgressBar:TProgressBar(a0:String, a1:String, a2:Int, a3:Int, a4:Int, a5:Int, a6:Int, a7:String, a8:String, a9:String, a10:Float, a11:Int, a12:TImage)
		Local p:TProgressBar = New TProgressBar
		p.name = a0
		p.x = a2
		p.y = a3
		p.w = a4
		p.h = a5
		p.alph = a10
		p.colour = a7
		p.fillcolour = a8
		p.image = CreateGadgetImage(a4, a5, a11, 0, 0)
		p.fillimage = CreateGadgetImage(32, 32, 0, 1, 0)
		p.fillicon = a12
		p.SetPercent(1.0, 1)
		p.SetText(a1, a9, 1, a6)
		Return p
	End Function
