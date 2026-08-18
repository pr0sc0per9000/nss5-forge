' TScreen_EditNations.ButtonNextNat
' VA 0x0052af6c   136 bytes   vtable slot 0x40   sig ()i
' byte-identical vs NSS5.exe (136/136, original length from Ghidra's inventory)
' assumptions: module Global at 0x00c596f0 declared as g_nations:TList
'              module Global at 0x00c65034 declared as g_curnat:TNation
	Function ButtonNextNat:Int()
		'!Global g_nations:TList
		'!Global g_curnat:TNation
		TScreen_EditNations.UpdateNat()
		TNation.SortListBy(1,1)
		For Local n:TNation=EachIn g_nations
			If n.id>g_curnat.id Then
				TScreen_EditNations.SetUpScreen(n.id)
				Return 0
			EndIf
		Next
	End Function
