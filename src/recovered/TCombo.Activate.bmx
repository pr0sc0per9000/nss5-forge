' TCombo.Activate
' VA 0x00518A65   403 bytes
' byte-identical vs NSS5.exe (403/403, original length from Ghidra's inventory, mode=reloc)
' Verified through the oracle from scratch, with helper_map.record stubbed.
' Body-only format: statements only; parameters are a0, a1, ...
'!Global g_activegadget:TGadget
Local c:TCombo = TCombo(g_activegadget)
If Not c Or c.buttons.Count() = 0 Then Return 0
c.activated = 1
c.btn_head.SetText(c.txt, "", -1, -1)
Select c.bstyle
Case 1
	c.btn_head.SetButtonStyle(2)
Case 4
	c.btn_head.SetButtonStyle(6)
Case 5
	c.btn_head.SetButtonStyle(7)
End Select
If c.selecteditem = 0
	c.selecteditem = 1
	c.itemoffset = 0
EndIf
Local n:Int = 1
For Local b:TButton = EachIn c.buttons
	b.hidden = 0
	If n = c.selecteditem Then g_activegadget = b
	n :+ 1
Next
FlushAllInput()
