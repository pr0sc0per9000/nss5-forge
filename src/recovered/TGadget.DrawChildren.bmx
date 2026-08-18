' TGadget.DrawChildren
' VA 0x00513bf9   99 bytes   vtable slot 0x48   sig ()i
' byte-identical vs NSS5.exe (99/99, original length from Ghidra's inventory)
	Method DrawChildren:Int()
		If hidden = 0
			For Local g:TGadget = EachIn children
				g.Draw()
			Next
		End If
	End Method
