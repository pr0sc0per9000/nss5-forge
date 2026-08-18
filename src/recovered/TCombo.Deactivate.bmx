' TCombo.Deactivate
' VA 0x00518BF8   209 bytes
' byte-identical vs NSS5.exe (209/209, original length from Ghidra's inventory, mode=reloc)
' Verified through the oracle from scratch, with helper_map.record stubbed.
' Body-only format: statements only; parameters are a0, a1, ...
'!Global g_activecombo:TCombo
Self.activated = 0
g_activecombo = Self
Self.btn_head.SetButtonStyle(Self.bstyle)
Local i:Int = 1
For Local b:TButton = EachIn Self.buttons
	b.hidden = 1
	If i = Self.selecteditem
		Self.btn_head.SetText(b.txt, "", -1, -1)
	End If
	i = i + 1
Next
If Self.fRet Then Self.fRet()
