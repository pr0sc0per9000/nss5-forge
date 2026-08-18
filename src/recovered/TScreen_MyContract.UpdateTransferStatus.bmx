' TScreen_MyContract.UpdateTransferStatus
' VA 0x00555195   1090 bytes   mode=reloc   byte-identical vs NSS5.exe (1090/1090,
' original length from Ghidra's inventory, reloc_masked=97)
' KIND=Function (static, NO implicit Self), SIG ()i, class-table slot 0x44
' Verified under NSS5_NO_LEARN=1 -- MATCH on first attempt.
'
' ASSUMPTIONS -- Global ADDRESSES are fact, NAMES/TYPES are ours (module Globals carry no
' debug record). Reused, with the SAME names, from already-verified TScreen_MyContract files:
'   0x00C6F028 g_profile:TProfile                  (TScreen_MyContract.ButtonRequestTransfer)
'   0x00C67D88 g_mc_lbl_translisted1:TLabel         "Transfer Listed" caption
'   0x00C67D8C g_mc_lbl_translisted2:TLabel         value label (colour + text change)
'   0x00C67D90 g_mc_btn_requesttransfer:TButton
'   0x00C67D94 g_mc_btn_requestloan:TButton
'   0x00C67D98 g_mc_lbl_desired:TLabel              "Desired Transfer" caption
' (all five construction sites are TScreen_MyContract.CreateScreen, VA 0x005542E9)
'
' FIELDS (object_model.json)
'   TProfile +0x134 transferlisted:Int   +0x138 desiredcontinentid:Int
'   +0x13C desirednationid:Int   +0x140 desiredleagueid:Int   +0x144 desiredclubid:Int
'   +0x1D0 myclub:TClub   +0x3C retired:Int
'   TBase_Team (TClub's super) +0x1C labelname:String -- read straight into SetText with
'     NO GetText() wrapper (case 4 passes the field itself, not a translation key).
'
' CALLS: 0x004C5549 GetText (ONE real argument -- Ghidra folds the following SetText
'   pushes ("", -1, -1) into its printed arg list, same idiom as every other GetText call
'   in this corpus). TGadget slot 0x64 SetText($,$,i,i), slot 0x6C SetColour($,$), slot
'   0x70 SetAlph(f). Final call is TScreen_MyContract+0x48 UpdateDesiredCombos()i, reached
'   through the raw class-table slot (classtable base 0x00C67FD8 + 0x48 = 0x00C68020),
'   exactly like TScreen_MainMenu.UpdateVersionInfo's self-call idiom in ResetScreen.
'
' SHAPE: plain Select (subject `g_profile.transferlisted` loaded once), Case 0..4, no
' Default -- matches guide 10.2. Case 3's first two statements target
' g_mc_lbl_translisted1/g_mc_lbl_desired (the object left in the "current" register slot
' from the reload just before the Select), not g_mc_lbl_translisted2 -- easy to misread
' from the raw decompile without tracking which Global was last loaded.
' Literals read out of NSS5.exe with harness.read_string: "Transfer Listed", "Desired
' Transfer", "No", "Yes", "Loan Listed", "Desired Loan", "On Loan", "FF0000", "00FF00",
' "FFFFFF", "transfer_Request", "transfer_RequestLoan", "transfer_CancelRequest",
' "transfer_ComeOffList", "transfer_CancelLoan" (translation keys/hex colours).

	Function UpdateTransferStatus:Int()
		'!Global g_profile:TProfile
		'!Global g_mc_lbl_translisted1:TLabel
		'!Global g_mc_lbl_translisted2:TLabel
		'!Global g_mc_btn_requesttransfer:TButton
		'!Global g_mc_btn_requestloan:TButton
		'!Global g_mc_lbl_desired:TLabel
		g_mc_lbl_translisted1.SetText(GetText("Transfer Listed"), "", -1, -1)
		g_mc_lbl_desired.SetText(GetText("Desired Transfer"), "", -1, -1)
		g_mc_btn_requesttransfer.SetAlph(1.0)
		g_mc_btn_requestloan.SetAlph(1.0)
		Select g_profile.transferlisted
		Case 0
			g_mc_lbl_translisted2.SetColour("FF0000", "FFFFFF")
			g_mc_lbl_translisted2.SetText(GetText("No"), "", -1, -1)
			g_mc_btn_requesttransfer.SetText(GetText("transfer_Request"), "", -1, -1)
			g_mc_btn_requestloan.SetText(GetText("transfer_RequestLoan"), "", -1, -1)
		Case 1
			g_mc_lbl_translisted2.SetColour("00FF00", "FFFFFF")
			g_mc_lbl_translisted2.SetText(GetText("Yes"), "", -1, -1)
			g_mc_btn_requesttransfer.SetText(GetText("transfer_CancelRequest"), "", -1, -1)
			g_mc_btn_requestloan.SetAlph(0.5)
		Case 2
			g_mc_lbl_translisted2.SetColour("00FF00", "FFFFFF")
			g_mc_lbl_translisted2.SetText(GetText("Yes"), "", -1, -1)
			g_mc_btn_requesttransfer.SetText(GetText("transfer_ComeOffList"), "", -1, -1)
			g_mc_btn_requestloan.SetAlph(0.5)
		Case 3
			g_mc_lbl_translisted1.SetText(GetText("Loan Listed"), "", -1, -1)
			g_mc_lbl_desired.SetText(GetText("Desired Loan"), "", -1, -1)
			g_mc_lbl_translisted2.SetColour("00FF00", "FFFFFF")
			g_mc_lbl_translisted2.SetText(GetText("Yes"), "", -1, -1)
			g_mc_btn_requesttransfer.SetAlph(0.5)
			g_mc_btn_requestloan.SetText(GetText("transfer_ComeOffList"), "", -1, -1)
		Case 4
			g_mc_lbl_translisted1.SetText(GetText("On Loan"), "", -1, -1)
			g_mc_lbl_desired.SetText(GetText("Desired Transfer"), "", -1, -1)
			g_mc_lbl_translisted2.SetColour("00FF00", "FFFFFF")
			g_mc_lbl_translisted2.SetText(g_profile.myclub.labelname, "", -1, -1)
			g_mc_btn_requesttransfer.SetAlph(0.5)
			g_mc_btn_requestloan.SetText(GetText("transfer_CancelLoan"), "", -1, -1)
			g_profile.desiredcontinentid = 0
			g_profile.desirednationid = 0
			g_profile.desiredleagueid = 0
			g_profile.desiredclubid = 0
		End Select
		If g_profile.retired
			g_mc_btn_requesttransfer.SetAlph(0.5)
			g_mc_btn_requestloan.SetAlph(0.5)
		EndIf
		TScreen_MyContract.UpdateDesiredCombos()
	End Function
