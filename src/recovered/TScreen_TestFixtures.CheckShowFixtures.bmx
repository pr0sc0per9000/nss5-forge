' TScreen_TestFixtures.CheckShowFixtures
' VA 0x00539938   306 bytes   vtable slot 0x38   sig (:TCompetition)i
' byte-identical vs NSS5.exe (306/306, original length from Ghidra's inventory)

'!Global g_tf_combocontinent:TCombo
'!Global g_tf_combonation:TCombo
Local cid:Int = g_tf_combocontinent.GetSelectedItemId()
Local nid:Int = g_tf_combonation.GetSelectedItemId()
LogLine("continentid:" + cid)
LogLine("nationid:" + nid)
Local ret:Int = 0
Select a0.level
Case 1
	ret = 1
Case 0
	Select a0.locale
	Case 0
		If cid = 0
			ret = 1
		ElseIf nid = 0
			Local n:TNation = TNation.SelectById(a0.based)
			If n <> Null And cid = n.continent Then ret = 1
		ElseIf a0.based = nid
			ret = 1
		EndIf
	Case 1
		If cid = 0 Or a0.based = cid Then ret = 1
	End Select
End Select
Return ret
