' TScreen_BootShop.ButtonBuy
' VA 0x00543cdc   1957 bytes   mode=reloc (141 masked)   byte-identical vs NSS5.exe (1957/1957)
' KIND=Function (static, no implicit Self), SIG ()i, class-table slot 0x38.
'
' ASSUMPTIONS
'   Module Global 0x00C6F028 is :TProfile (established by SponsorAmount, TScreen_BootShop.
'     SetUpScreen and many others). 0x00C6F0D4 is :TSound / 0x00C6F090 is :TChannel, same
'     PlaySound-argument identification used by TScreen_Shop.ButtonBuy.
'   TProfile fields (object_model.json): bank:Int +0x28, boots:Int[] +0xEC (array data at
'     +0x18, so `boots[i]` is `[edx+0x18+i*4]`).
'   TProfile slots used (vtable_map.tsv): UpdateBank(i)i 0xFC, BuyBoots(i)i 0x12C,
'     CheckAchievement(i)i 0x150. NOTE this is CheckAchievement(91), NOT the sibling
'     TScreen_Shop.ButtonBuy's parameterless CheckPurchaseAchievements() (0x154) -- the two
'     screens' buy handlers call two DIFFERENT TProfile methods that happen to sit one slot
'     apart; the decompiled arg `0x5b` = 91 decimal is the boots-purchase achievement id.
'   0x00C621CC = TGadget class table (0x00C62150) + 0x7C = Function GetActiveGadgetName()$,
'     called unqualified-through-class-table (class_tables.tsv + vtable_map.tsv), so written
'     qualified `TGadget.GetActiveGadgetName()` because the owning Type is not this Type.
'   0x00C61CC0 = TScreen class table (0x00C61C2C) + 0x94 = Function DoMessage($,i,i)i.
'   0x00C66EFC = TScreen_BootShop's OWN class table (0x00C66EC0) + 0x3C = Function
'     ButtonPlay()i -- a SIBLING static Function, called unqualified. This is genuinely
'     surprising (ButtonBuy ends by invoking the Play-button handler, which itself does
'     `TScreen_MatchPrep.SetUpScreen()` + `PlayTrack(2)` -- see TScreen_BootShop.
'     ButtonPlay.bmx) but the class-table arithmetic is exact and unambiguous; the name is
'     the original's, not renamed.
'   SponsorAmount(i), FormatMoney(i,i)$, GetText($)$ are the verified src/recovered_module
'     bodies. SponsorAmount returns 0 when the player already has a live sponsorship, which
'     is what makes the "free boots" path (cost = 0) reachable below.
'
' NOTES that cost time, in case this shape recurs:
'   * BOTH Select cascades compare `n` (GetActiveGadgetName's result) against "btn_boots1"
'     .. "btn_boots10" via 10 back-to-back _bbStringCompare calls (section 10.2). Cascade 1
'     has `Default Return 0` inlined at the compares' fall-through (before any case body).
'     Cascade 2 has NO Default -- its fall-through, when no `boots[i-1]=5` case fires,
'     is a plain drop-through past End Select.
'   * `If cost > 0 And g_profile.bank < cost` is the standard short-circuit shape: a
'     `bVar=false` init, second test only evaluated when the first is true, then one branch
'     on the combined flag (section 10.9-style guard). This branch DOES end with an explicit
'     `Return 0` after the message -- unlike the fallthrough at the very end of the function,
'     which needs none because it already sits at the function's natural close.
'   * The confirm-purchase message is ONE chained expression, not a Local assigned then
'     read: `TScreen.DoMessage(GetText("CMESSAGE_CONFIRMPURCHASE").Replace("$cash",
'     FormatMoney(cost, 1)), 1, 0)`. Proven by argument push order (section 16.2 extended to
'     a Method's Self): DoMessage's trailing args (0, then 1) are pushed FIRST, ahead of
'     evaluating the whole nested GetText/Replace/FormatMoney chain that becomes its first
'     argument, which is pushed last, right before the call. Splitting this into
'     `Local msg:String = ...` then `confirmed = TScreen.DoMessage(msg,1,0)` compiles to a
'     different, longer byte sequence (an intermediate 4-byte gap plus a 4-byte insert,
'     found by scripts/localise_diff.py) because it forces DoMessage's args to be pushed in
'     a separate later statement instead of interleaved with the nested-call evaluation.
'   * `Local confirmed:Int = (cost = 0)` really is a boolean Local: free items (cost 0, from
'     SponsorAmount's already-sponsored guard) skip the confirm dialog entirely.
	'!Global g_profile:TProfile
	'!Global g_sound:TSound
	'!Global g_channel:TChannel
	Local n:String = TGadget.GetActiveGadgetName()
	Local cost:Int
	Select n
		Case "btn_boots1"
			cost = SponsorAmount(1)
		Case "btn_boots2"
			cost = SponsorAmount(2)
		Case "btn_boots3"
			cost = SponsorAmount(3)
		Case "btn_boots4"
			cost = SponsorAmount(4)
		Case "btn_boots5"
			cost = SponsorAmount(5)
		Case "btn_boots6"
			cost = SponsorAmount(6)
		Case "btn_boots7"
			cost = SponsorAmount(7)
		Case "btn_boots8"
			cost = SponsorAmount(8)
		Case "btn_boots9"
			cost = SponsorAmount(9)
		Case "btn_boots10"
			cost = SponsorAmount(10)
		Default
			Return 0
	End Select
	If cost > 0 And g_profile.bank < cost
		TScreen.DoMessage(GetText("CMESSAGE_NOTENOUGHCASH"), 0, 0)
		Return 0
	Else
		Select n
			Case "btn_boots1"
				If g_profile.boots[0] = 5
					TScreen.DoMessage(GetText("CMESSAGE_BOOTALREADYOWNED"), 0, 0)
					Return 0
				EndIf
			Case "btn_boots2"
				If g_profile.boots[1] = 5
					TScreen.DoMessage(GetText("CMESSAGE_BOOTALREADYOWNED"), 0, 0)
					Return 0
				EndIf
			Case "btn_boots3"
				If g_profile.boots[2] = 5
					TScreen.DoMessage(GetText("CMESSAGE_BOOTALREADYOWNED"), 0, 0)
					Return 0
				EndIf
			Case "btn_boots4"
				If g_profile.boots[3] = 5
					TScreen.DoMessage(GetText("CMESSAGE_BOOTALREADYOWNED"), 0, 0)
					Return 0
				EndIf
			Case "btn_boots5"
				If g_profile.boots[4] = 5
					TScreen.DoMessage(GetText("CMESSAGE_BOOTALREADYOWNED"), 0, 0)
					Return 0
				EndIf
			Case "btn_boots6"
				If g_profile.boots[5] = 5
					TScreen.DoMessage(GetText("CMESSAGE_BOOTALREADYOWNED"), 0, 0)
					Return 0
				EndIf
			Case "btn_boots7"
				If g_profile.boots[6] = 5
					TScreen.DoMessage(GetText("CMESSAGE_BOOTALREADYOWNED"), 0, 0)
					Return 0
				EndIf
			Case "btn_boots8"
				If g_profile.boots[7] = 5
					TScreen.DoMessage(GetText("CMESSAGE_BOOTALREADYOWNED"), 0, 0)
					Return 0
				EndIf
			Case "btn_boots9"
				If g_profile.boots[8] = 5
					TScreen.DoMessage(GetText("CMESSAGE_BOOTALREADYOWNED"), 0, 0)
					Return 0
				EndIf
			Case "btn_boots10"
				If g_profile.boots[9] = 5
					TScreen.DoMessage(GetText("CMESSAGE_BOOTALREADYOWNED"), 0, 0)
					Return 0
				EndIf
		End Select
		Local confirmed:Int = (cost = 0)
		If Not confirmed
			confirmed = TScreen.DoMessage(GetText("CMESSAGE_CONFIRMPURCHASE").Replace("$cash", FormatMoney(cost, 1)), 1, 0)
		EndIf
		If confirmed
			If cost = 0
				TScreen.DoMessage(GetText("CMESSAGE_FREEBOOTS"), 0, 0)
			Else
				g_profile.UpdateBank(-cost)
				PlaySound(g_sound, g_channel)
			EndIf
			For Local i:Int = 0 To 9
				g_profile.boots[i] = 0
			Next
			Select n
				Case "btn_boots1"
					g_profile.BuyBoots(1)
				Case "btn_boots2"
					g_profile.BuyBoots(2)
				Case "btn_boots3"
					g_profile.BuyBoots(3)
				Case "btn_boots4"
					g_profile.BuyBoots(4)
				Case "btn_boots5"
					g_profile.BuyBoots(5)
				Case "btn_boots6"
					g_profile.BuyBoots(6)
				Case "btn_boots7"
					g_profile.BuyBoots(7)
				Case "btn_boots8"
					g_profile.BuyBoots(8)
				Case "btn_boots9"
					g_profile.BuyBoots(9)
				Case "btn_boots10"
					g_profile.BuyBoots(10)
			End Select
			g_profile.CheckAchievement(91)
		EndIf
		ButtonPlay()
	EndIf
