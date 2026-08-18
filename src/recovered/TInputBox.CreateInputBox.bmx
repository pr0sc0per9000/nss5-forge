' TInputBox.CreateInputBox
' VA 0x00515643   269 bytes   vtable slot 0x88   KIND=Function (static)
' sig ($,i,i,i,i,i,i,$,$,i,f,()i,i,$):TInputBox
' byte-identical vs NSS5.exe (269/269, original length from Ghidra's inventory, mode=reloc)
' fHit is loaded from TInputBox's OWN class table + 0x90 = GetInputText, i.e. a sibling
' Function used as a value, so it is written with no Type prefix.
' The tooltip guard reads the String length word at +8: a13.Length <> 0.
	Function CreateInputBox:TInputBox(a0:String, a1:Int, a2:Int, a3:Int, a4:Int, a5:Int, a6:Int, a7:String, a8:String, a9:Int, a10:Float, a11:Int(), a12:Int, a13:String)
		Local b:TInputBox = New TInputBox
		b.limitchars = a9
		b.name = a0
		b.x = a1
		b.desx = a1
		b.y = a2
		b.desy = a2
		b.w = a3
		b.h = a4
		b.alive = a5
		b.colour = a7
		b.txtcolour = a8
		b.fHit = GetInputText
		b.alph = a10
		b.fntSize = a6
		b.fRet = a11
		b.hideinput = a12
		b.CreateInputImage()
		If a13.Length <> 0 Then b.CreateToolTip(a13)
		Return b
	End Function
