' TScreen_ContractOffer.SetUpScreen
' VA 0x005537BC   418 bytes   class-table slot 0x34   sig (:TContractOffer,()i,()i)i
' KIND=Function (static)
' byte-identical vs NSS5.exe (418/418, original length from Ghidra's inventory, mode=reloc,
' reloc_masked=39)
' Work-set class was BLOCKED; it is not.
'
' ASSUMPTIONS
'  Parameters: a0:TContractOffer, a1/a2 are `()i` function pointers (callbacks).
'  Module Globals -- NAMES ARE OURS, declared TYPES are load-bearing.
'  Keep the address immediately before the name, per CONTRIBUTING: the prose scanners in
'  build_alias_map.py and find_live_splits.py pair an address only with the identifier that
'  FOLLOWS it, so a `0x... Type name` block teaches them nothing and a second name on one
'  of these slots goes unreported.
'    0x00C67B8C g_co_fn1  :Int()          -- globals_final says Int; it is a FUNCTION
'    0x00C67B90 g_co_fn2  :Int()             POINTER (`()i`), stored with a bare mov and
'                                            no refcount traffic, fed from the `()i`
'                                            parameters.  `Int()` and `Int` emit the same
'                                            store, so this is a typing choice not a
'                                            byte-level claim.
'    0x00C67B88 g_co_offer:TContractOffer -- globals_final says Object/low; the store has
'                                            full retain/release traffic (inc [ebx+4],
'                                            dec [eax+4] + bbGCFree) so it IS a reference,
'                                            and the value comes from the :TContractOffer
'                                            parameter.  This is the ONLY writer of the
'                                            slot (`mov [0xc67b88],ebx` at 0x00553802);
'                                            UpdateOfferDetails, ButtonAccept and
'                                            ButtonNegotiate are its only readers and all
'                                            three must spell it the same way.
'    0x00C6F028 g_profile :TProfile       (globals_final construction/high, 3 sites)
'    0x00C67B80 g_co_btn561:TButton
'    0x00C67B50 g_co_btn549:TButton
'    0x00C67B4C g_co_btn548:TButton
'    0x00C67B14 g_co_screen:TScreen
'    0x00C67B18 g_co_snd  :TSound         (arg1 of _brl_audio_PlaySound)
'    0x00C6F090 g_chan    :TChannel       (arg2 of _brl_audio_PlaySound)
'    0x00C67B20 g_co_btn537:TButton
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
