' TScreen_BootShop.SetUpScreen
' VA 0x00543978   868 bytes   KIND=Function, class-table slot 0x34, sig ()i
' byte-identical vs NSS5.exe (868/868, original length from Ghidra's inventory)
'
' ASSUMPTIONS
'   g_profile:TProfile is the well-established Global at 0x00C6F028 (already used by
'     SponsorAmount and several TContractOffer bodies in this corpus).
'   g_screen_bootshop:TScreen / g_lbl_bootmoney:TLabel are dedicated Globals at
'     0x00C66E20 / 0x00C66E3C (globals_final.tsv: TScreen/TLabel by construction site).
'   TProfile fields from extracted/object_model.json: bank +0x28, boots:Int[] +0xEC,
'     helppages:Int[] +0x1C8. helppages[18] is read/written as a fixed compile-time
'     index -- the decompilation's `+0x60` is exactly `+0x18 + 18*4`.
'   TButton.SetAlph is (f)i at slot 0x70 (vtable_map.tsv); TProgressBar.Hide/Show/
'     SetPercent/SetColour/SetText reuse the ordinary TGadget/TProgressBar slots already
'     in this corpus (0x54/0x58/0x8c/0x6c/0x64).
'   `SponsorAmount(i)` returns amount, 1 (a1=1 for FormatMoney's "abbreviate" flag).
'   Boolean sense is load-bearing: the original tests `amt > 0` (jle/fallthrough to
'     FormatMoney), not `amt <= 0` -- written the other way round the branch and the
'     two FormatMoney/GetText argument-count deltas (2 vs 1 pushed args) cost 4 bytes.
'   `g_profile.boots[i-1] * 20` is INTEGER multiplication converted to Float only at the
'     SetPercent call boundary (imul then fild) -- writing `* 20.0` forces an x87 fmul
'     and is 3 bytes longer.
	Method SetUpScreen:Int()
		'!Global g_profile:TProfile
		'!Global g_screen_bootshop:TScreen
		'!Global g_lbl_bootmoney:TLabel
		TScreen.SetActive("bootshop", "")
		PlayTrack(5)
		g_lbl_bootmoney.SetText(FormatMoney(g_profile.bank, 0), "", -1, -1)
		For Local i:Int = 1 To 10
			Local lbl:TLabel = TLabel(g_screen_bootshop.GetGadgetByName("lbl_boots" + i))
			lbl.Show()
			Local amt:Int = SponsorAmount(i)
			If amt > 0
				lbl.SetText(FormatMoney(amt, 1), "", -1, -1)
			Else
				lbl.SetText(GetText("price_Free"), "", -1, -1)
			EndIf
			Local prg:TProgressBar = TProgressBar(g_screen_bootshop.GetGadgetByName("prg_boots" + i))
			prg.Hide()
			If g_profile.boots[i - 1] > 0
				g_screen_bootshop.GetGadgetByName("lbl_boots" + i).Hide()
				prg.Show()
				prg.SetPercent(g_profile.boots[i - 1] * 20, 1)
				prg.SetColour("", "00FF00")
				Local s:String = String(g_profile.boots[i - 1]) + " " + GetText("Matches")
				If g_profile.boots[i - 1] = 1
					s = String(g_profile.boots[i - 1]) + " " + GetText("Match")
				EndIf
				prg.SetText(s, "", -1, -1)
				If g_profile.boots[i - 1] < 3
					prg.SetColour("", "FF6600")
				EndIf
				If g_profile.boots[i - 1] < 2
					prg.SetColour("", "FF0000")
				EndIf
			EndIf
		Next
		For Local i:Int = 1 To 10
			g_screen_bootshop.GetGadgetByName("btn_boots" + i).SetAlph(1.0)
		Next
		If g_profile.helppages[18] = 0
			TScreen.Tutorial()
			g_profile.helppages[18] = 1
		EndIf
	End Method
