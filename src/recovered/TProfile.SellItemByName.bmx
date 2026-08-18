' TProfile.SellItemByName
' VA 0x0056B1DE   894 bytes  mode=reloc  byte-identical vs NSS5.exe
' KIND=Method (implicit Self), SIG ($)i, slot 0xEC
' ASSUMPTIONS
'   Self.items []i at +0xF0, Self.vehicles []i at +0xF4, Self.property []i at +0xF8
'   (object_model.json); Self.UpdateBank is slot 0xFC (i)i; TScreen slot 0x94 = DoMessage.
'   ItemName/VehicleName/PropertyName/TierA/TierB/TierC are the already-verified module
'   Functions in src/recovered_module (all (i)$ / (i)i).
'   0x00C8EC34/68/6C/70/74/78 are this function's six copies of the float literal 0.5,
'   not Globals -- bcc emits one .rdata slot per textual occurrence.
' SHAPE NOTES
'   * `If a0 = "" Then Return 0` is an EARLY RETURN (`jne / mov eax,0 / jmp epilogue`).
'     Wrapping the whole body in `If a0 <> ""` is 888 bytes.
'   * `For Local i:Int = 1 To 10` -- the original tests `cmp ebx,0xa / jle`.
'   * The three arms are an If/ElseIf cascade, not a Select: each _bbStringCompare is
'     followed immediately by its own body.
	Method SellItemByName:Int(a0:String)
		If a0 = "" Then Return 0
			For Local i:Int = 1 To 10
				If a0 = ItemName(i)
					If Self.items[i - 1] = 0
						TScreen.DoMessage(GetText("CMESSAGE_ITEMNOTOWNED"), 0, 0)
						Return 0
					End If
					If TScreen.DoMessage(GetText("CMESSAGE_SELLITEM").Replace("$value", FormatMoney(Int(TierC(i) * 0.5), 0)), 1, 0) <> 0
						Self.items[i - 1] = Self.items[i - 1] - 1
						Self.UpdateBank(Int(TierC(i) * 0.5))
						Return 0
					End If
				ElseIf a0 = VehicleName(i)
					If Self.vehicles[i - 1] = 0
						TScreen.DoMessage(GetText("CMESSAGE_ITEMNOTOWNED"), 0, 0)
						Return 0
					End If
					If TScreen.DoMessage(GetText("CMESSAGE_SELLITEM").Replace("$value", FormatMoney(Int(TierB(i) * 0.5), 0)), 1, 0) <> 0
						Self.vehicles[i - 1] = Self.vehicles[i - 1] - 1
						Self.UpdateBank(Int(TierB(i) * 0.5))
						Return 0
					End If
				ElseIf a0 = PropertyName(i)
					If Self.property[i - 1] = 0
						TScreen.DoMessage(GetText("CMESSAGE_ITEMNOTOWNED"), 0, 0)
						Return 0
					End If
					If TScreen.DoMessage(GetText("CMESSAGE_SELLITEM").Replace("$value", FormatMoney(Int(TierA(i) * 0.5), 0)), 1, 0) <> 0
						Self.property[i - 1] = Self.property[i - 1] - 1
						Self.UpdateBank(Int(TierA(i) * 0.5))
						Return 0
					End If
				End If
			Next
	End Method
