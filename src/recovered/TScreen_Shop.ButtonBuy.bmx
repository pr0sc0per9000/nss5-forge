' TScreen_Shop.ButtonBuy
' VA 0x005424de   3278 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Function, SIG ()i, class-table slot 0x38
' ASSUMPTIONS
'   Module Global 0x00C6F028 is :TProfile (globals_final.tsv, construction, high, 3 sites).
'   Module Global 0x00C6F0D4 is :TSound   -- table says Object/low; typed here from being
'     PlaySound argument 1. Only affects nothing dispatched, no vtable slot depends on it.
'   Module Global 0x00C6F090 is :TChannel -- likewise, PlaySound argument 2.
'   TProfile layout: energy:Float +0x15C, bank:Int +0x28, items/vehicles/property:Int[]
'     at +0xF0/+0xF4/+0xF8 (array data at +0x18, so index 0..9 -> 0x18..0x3C).
'   TProfile slots 0x100=UpdateEnergy(f), 0xFC=UpdateBank(i), 0x154=CheckPurchaseAchievements().
'   TGadget+0x7C = GetActiveGadgetName()$ ; TScreen+0x94 = DoMessage($,i,i)i -- both written
'     qualified because the call goes through the OWNING Type table, not TScreen_Shop's.
'   [0x00C66E14] is TScreen_Shop+0x34 = SetUpScreen(), a sibling Function -> unqualified.
'   TierA/TierB/TierC and GetText/FormatMoney are the verified src/recovered_module bodies.
'
' NOTES that cost time, in case this shape recurs:
'   * BOTH cascades are Select (30 _bbStringCompare compares back to back, every je past
'     the last compare -- codegen-patterns 10.2). Cascade 1 has `Default Return 0`, whose
'     body bcc emits INLINE at the compares' fall-through, before the case bodies.
'     Cascade 2 has NO Default: its fall-through is a plain jmp past End Select.
'   * `If g_profile.energy < 10.0` materialises as fld/fld/fxch/fucompp/SETAE + jne -- the
'     NEGATED setcc plus an inverted branch. Same convention as the integer guard below it
'     (`cmp [eax+0x28],esi / jge`): bcc branches on the negation to skip the block.
'   * `If TScreen.DoMessage(msg,1,0) ... Else Return 0 ... EndIf` -- the Else really is
'     there. The then-block ends `jmp` OVER a `mov eax,0 / jmp epilogue`, and SetUpScreen()
'     sits after EndIf. Folding SetUpScreen() into the then-block loses that jump.
'   * The array increments are `a[i] = a[i] + 1`, not `a[i] :+ 1`: the base Global is
'     re-loaded for the store and again for the load (bcc does no CSE).
	Function ButtonBuy:Int()
		'!Global g_profile:TProfile
		'!Global g_sound:TSound
		'!Global g_channel:TChannel
		If g_profile.energy < 10.0
			TScreen.DoMessage(GetText("CMESSAGE_NOSHOPPINGTIRED"), 0, 0)
			Return 0
		EndIf
		Local n:String = TGadget.GetActiveGadgetName()
		Local cost:Int
		Select n
			Case "btn_items1"
				cost = TierC(1)
			Case "btn_items2"
				cost = TierC(2)
			Case "btn_items3"
				cost = TierC(3)
			Case "btn_items4"
				cost = TierC(4)
			Case "btn_items5"
				cost = TierC(5)
			Case "btn_items6"
				cost = TierC(6)
			Case "btn_items7"
				cost = TierC(7)
			Case "btn_items8"
				cost = TierC(8)
			Case "btn_items9"
				cost = TierC(9)
			Case "btn_items10"
				cost = TierC(10)
			Case "btn_vehicles1"
				cost = TierB(1)
			Case "btn_vehicles2"
				cost = TierB(2)
			Case "btn_vehicles3"
				cost = TierB(3)
			Case "btn_vehicles4"
				cost = TierB(4)
			Case "btn_vehicles5"
				cost = TierB(5)
			Case "btn_vehicles6"
				cost = TierB(6)
			Case "btn_vehicles7"
				cost = TierB(7)
			Case "btn_vehicles8"
				cost = TierB(8)
			Case "btn_vehicles9"
				cost = TierB(9)
			Case "btn_vehicles10"
				cost = TierB(10)
			Case "btn_property1"
				cost = TierA(1)
			Case "btn_property2"
				cost = TierA(2)
			Case "btn_property3"
				cost = TierA(3)
			Case "btn_property4"
				cost = TierA(4)
			Case "btn_property5"
				cost = TierA(5)
			Case "btn_property6"
				cost = TierA(6)
			Case "btn_property7"
				cost = TierA(7)
			Case "btn_property8"
				cost = TierA(8)
			Case "btn_property9"
				cost = TierA(9)
			Case "btn_property10"
				cost = TierA(10)
			Default
				Return 0
		End Select
		If g_profile.bank < cost
			TScreen.DoMessage(GetText("CMESSAGE_NOTENOUGHCASH"), 0, 0)
			Return 0
		EndIf
		Local msg:String = GetText("CMESSAGE_CONFIRMPURCHASEENERGYCOST")
		msg = msg.Replace("$cash", FormatMoney(cost, 1))
		msg = msg.Replace("$energy", "10")
		If TScreen.DoMessage(msg, 1, 0)
			g_profile.UpdateEnergy(-10.0)
			g_profile.UpdateBank(-cost)
			PlaySound(g_sound, g_channel)
			Select n
				Case "btn_items1"
					g_profile.items[0] = g_profile.items[0] + 1
				Case "btn_items2"
					g_profile.items[1] = g_profile.items[1] + 1
				Case "btn_items3"
					g_profile.items[2] = g_profile.items[2] + 1
				Case "btn_items4"
					g_profile.items[3] = g_profile.items[3] + 1
				Case "btn_items5"
					g_profile.items[4] = g_profile.items[4] + 1
				Case "btn_items6"
					g_profile.items[5] = g_profile.items[5] + 1
				Case "btn_items7"
					g_profile.items[6] = g_profile.items[6] + 1
				Case "btn_items8"
					g_profile.items[7] = g_profile.items[7] + 1
				Case "btn_items9"
					g_profile.items[8] = g_profile.items[8] + 1
				Case "btn_items10"
					g_profile.items[9] = g_profile.items[9] + 1
				Case "btn_vehicles1"
					g_profile.vehicles[0] = g_profile.vehicles[0] + 1
				Case "btn_vehicles2"
					g_profile.vehicles[1] = g_profile.vehicles[1] + 1
				Case "btn_vehicles3"
					g_profile.vehicles[2] = g_profile.vehicles[2] + 1
				Case "btn_vehicles4"
					g_profile.vehicles[3] = g_profile.vehicles[3] + 1
				Case "btn_vehicles5"
					g_profile.vehicles[4] = g_profile.vehicles[4] + 1
				Case "btn_vehicles6"
					g_profile.vehicles[5] = g_profile.vehicles[5] + 1
				Case "btn_vehicles7"
					g_profile.vehicles[6] = g_profile.vehicles[6] + 1
				Case "btn_vehicles8"
					g_profile.vehicles[7] = g_profile.vehicles[7] + 1
				Case "btn_vehicles9"
					g_profile.vehicles[8] = g_profile.vehicles[8] + 1
				Case "btn_vehicles10"
					g_profile.vehicles[9] = g_profile.vehicles[9] + 1
				Case "btn_property1"
					g_profile.property[0] = g_profile.property[0] + 1
				Case "btn_property2"
					g_profile.property[1] = g_profile.property[1] + 1
				Case "btn_property3"
					g_profile.property[2] = g_profile.property[2] + 1
				Case "btn_property4"
					g_profile.property[3] = g_profile.property[3] + 1
				Case "btn_property5"
					g_profile.property[4] = g_profile.property[4] + 1
				Case "btn_property6"
					g_profile.property[5] = g_profile.property[5] + 1
				Case "btn_property7"
					g_profile.property[6] = g_profile.property[6] + 1
				Case "btn_property8"
					g_profile.property[7] = g_profile.property[7] + 1
				Case "btn_property9"
					g_profile.property[8] = g_profile.property[8] + 1
				Case "btn_property10"
					g_profile.property[9] = g_profile.property[9] + 1
			End Select
			g_profile.CheckPurchaseAchievements()
		Else
			Return 0
		EndIf
		SetUpScreen()
	End Function
