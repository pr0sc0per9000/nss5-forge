' TScreen_MyContract.SetUpScreen
' VA 0x00554cd1   195 bytes   vtable slot 0x34   sig ()i
' byte-identical vs NSS5.exe (195/195, original length from Ghidra's inventory, mode=reloc)
' Assumptions: 0x00C67B24 declared TPanel and 0x00C67B4C declared TButton (globals_final.tsv,
'   construction-site typed); 0x00C6F028 declared TProfile (high confidence).
'   0x00C61C88 = TScreen class table + 0x5C = SetActive($,$):TScreen;
'   0x00C67D5C = TScreen_ContractOffer + 0x38 = UpdateCurrentContractDetails();
'   0x00C6801C / 0x00C68014 / 0x00C68040 = TScreen_MyContract + 0x44 / 0x3C / 0x68 =
'   sibling Functions UpdateTransferStatus / UpdateClubsInterestedLabel / UpdateOfferButtons;
'   0x00C61CE0 = TScreen + 0xB4 = Tutorial().
'   TGadget field at +0x38 is `alive`; TProfile.helppages is []i and the decompilation's
'   +0x30 is BBArray data (+0x18) + 6*4, i.e. helppages[6].
'   FUN_00505B91 = recovered module Function LogLine.
'!Global g_mycontract_panel:TPanel
'!Global g_mycontract_btnplay:TButton
'!Global g_profile:TProfile
	Function SetUpScreen()
		TScreen.SetActive("mycontract", "btn_play")
		TScreen_ContractOffer.UpdateCurrentContractDetails()
		g_mycontract_panel.Show()
		LogLine("Updated Details")
		g_mycontract_btnplay.alive = 1
		g_mycontract_btnplay.SetAlph(1.0)
		UpdateTransferStatus()
		LogLine("Updated Transfer Status")
		UpdateClubsInterestedLabel()
		LogLine("Updated Label")
		UpdateOfferButtons()
		LogLine("Updated Buttons")
		If g_profile.helppages[6] = 0
			TScreen.Tutorial()
			g_profile.helppages[6] = 1
		End If
	End Function
