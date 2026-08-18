' TScreen_CreateAccount.SetUpScreen
' VA 0x00525694   65 bytes   vtable slot 0x34   sig ()i
' byte-identical vs NSS5.exe (65/65, original length from Ghidra's inventory)
' Parameter names are not recoverable from the binary and do not affect codegen;
' they are emitted as a0, a1, ... exactly as the harness compiles them.
' ASSUMPTIONS: Global 0x00c6f028 declared TProfile (+0x14 = TProfile.name),
' Global 0x00c6443c declared TGadget (slot 0x64 = TGadget.SetText).
' Both string arguments are literals (address-of form in the decompilation); their
' contents are masked as absolute data addresses and do not affect the bytes.

	Function SetUpScreen:Int()
		'!Global g_profile:TProfile
		'!Global g_inpName:TGadget
		TScreen.SetActive("createaccount","")
		g_inpName.SetText(g_profile.name,"",-1,-1)
	End Function
