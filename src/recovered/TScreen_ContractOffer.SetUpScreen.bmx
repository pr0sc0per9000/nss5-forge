' TScreen_ContractOffer.SetUpScreen
' VA 0x005537BC   418 bytes   class-table slot 0x34   sig (:TContractOffer,()i,()i)i
' KIND=Function (static)
' byte-identical vs NSS5.exe (418/418, original length from Ghidra's inventory, mode=reloc,
' reloc_masked=39)
' Work-set class was BLOCKED; it is not.
'
' ASSUMPTIONS
'  Parameters: a0:TContractOffer, a1/a2 are `()i` function pointers (callbacks).
'  Module Globals -- NAMES ARE OURS, declared TYPES are load-bearing:
'    0x00C67B8C Int()          g_co_fn1   -- globals_final says Int; it is a FUNCTION
'    0x00C67B90 Int()          g_co_fn2      POINTER (`()i`), stored with a bare mov and
'                                            no refcount traffic, fed from the `()i`
'                                            parameters.  `Int()` and `Int` emit the same
'                                            store, so this is a typing choice not a
'                                            byte-level claim.
'    0x00C67B88 TContractOffer g_co_offer -- globals_final says Object/low; the store has
'                                            full retain/release traffic (inc [ebx+4],
'                                            dec [eax+4] + bbGCFree) so it IS a reference,
'                                            and the value comes from the :TContractOffer
'                                            parameter.
'    0x00C6F028 TProfile       g_profile  (globals_final construction/high, 3 sites)
'    0x00C67B80 TButton        g_co_btn561
'    0x00C67B50 TButton        g_co_btn549
'    0x00C67B4C TButton        g_co_btn548
'    0x00C67B14 TScreen        g_co_screen
'    0x00C67B18 TSound         g_co_snd   (arg1 of _brl_audio_PlaySound)
'    0x00C6F090 TChannel       g_chan     (arg2 of _brl_audio_PlaySound)
'    0x00C67B20 TButton        g_co_btn537
'  Fields:
'    TProfile +0x1D0 myclub(:TClub), +0x0F0 items([]i), +0x1C8 helppages([]i)
'      -- array data starts at +0x18, so [items+0x18] is items[0] and
'         [helppages+0x44] is helppages[11].
'    TGadget +0x38 alive
'  Slots resolved:
'    [0x00C61C88] = TScreen + 0x5C = TScreen.SetActive($,$):TScreen
'    [0x00C61CE0] = TScreen + 0xB4 = TScreen.Tutorial()
'    [0x00C67D5C/60/64/68] = TScreen_ContractOffer + 0x38/0x3C/0x40/0x44 =
'         UpdateCurrentContractDetails() / UpdateOfferDetails(i,i) /
'         HideCurrentContract() / ShowCurrentContract()
'         -> siblings of THIS Type: written WITHOUT the Type prefix
'    TScreen 0x60 = SetActiveGadget($)  -- KIND=Function called THROUGH an instance
'         (`mov eax,[g] / mov eax,[eax] / call [eax+0x60]` with NO Self push)
'    TGadget 0x54 = Hide, 0x58 = Show, 0x64 = SetText($,$,i,i)  (all INHERITED by TButton)
'    TButton 0x70 = SetAlph(f)
'  BRL: 0x0059B25E PlaySound, 0x004C5549 GetText (ONE argument -- `add esp,4`; the
'    `push -1 / push -1 / push ""` before it are SetText's).
'  Literals: 0x00C8984C "contractoffer", 0x00C5D284 "", 0x00C898DC "transfer_Consider",
'    0x00C8A134 "transfer_Reject", 0x00C89950 "accept".
'  SHAPE: both `cmp dword [eax+0x1D0],0x5C9C80 / je <else>` sites are `<> Null` with the
'  Show branch first -- the je goes to the ELSE arm, so the tested condition is "non-null".
	'!Global g_co_fn1:Int()
	'!Global g_co_fn2:Int()
	'!Global g_co_offer:TContractOffer
	'!Global g_profile:TProfile
	'!Global g_co_btn561:TButton
	'!Global g_co_btn549:TButton
	'!Global g_co_btn548:TButton
	'!Global g_co_screen:TScreen
	'!Global g_co_snd:TSound
	'!Global g_chan:TChannel
	'!Global g_co_btn537:TButton
	Function SetUpScreen:Int(a0:TContractOffer, a1:Int(), a2:Int())
		TScreen.SetActive("contractoffer", "")
		g_co_fn1 = a1
		g_co_fn2 = a2
		g_co_offer = a0
		If g_profile.myclub <> Null
			ShowCurrentContract()
			UpdateCurrentContractDetails()
			g_co_btn561.Show()
			g_co_btn549.SetText(GetText("transfer_Consider"), "", -1, -1)
		Else
			HideCurrentContract()
			g_co_btn561.Hide()
			g_co_btn549.SetText(GetText("transfer_Reject"), "", -1, -1)
		EndIf
		g_co_btn548.alive = 0
		g_co_btn548.SetAlph(0.5)
		UpdateOfferDetails(1, 0)
		g_co_screen.SetActiveGadget("accept")
		If g_profile.items[0] Then PlaySound(g_co_snd, g_chan)
		If g_profile.myclub <> Null
			g_co_btn537.Show()
			If g_profile.helppages[11] = 0
				TScreen.Tutorial()
				g_profile.helppages[11] = 1
			EndIf
		Else
			g_co_btn537.Hide()
		EndIf
	End Function
