' TKitStrings.GetFileName
' VA 0x004dcb5c   727 bytes   vtable slot 0x40   sig ()$
' byte-identical vs NSS5.exe (727/727, original length from Ghidra's inventory)
' No assumptions beyond the field name TKitStrings.style (offset 0x8) from
' object_model.json; the string literals were read straight out of NSS5.exe's
' constant pool.  Matched in 'reloc' mode (string-constant addresses masked).
	Method GetFileName:String()
		Select style
			Case "PLAIN"
				Return "Player_Plain.png"
			Case "TRIM"
				Return "Player_Trim.png"
			Case "STRIPES"
				Return "Player_Stripes.png"
			Case "STRIPE"
				Return "Player_StripeR.png"
			Case "STRIPE_L"
				Return "Player_StripeR.png"
			Case "STRIPE_R"
				Return "Player_StripeR.png"
			Case "STRIPE_LR"
				Return "Player_StripeLR.png"
			Case "STRIPE_RL"
				Return "Player_StripeLR.png"
			Case "STRIPE_C"
				Return "Player_StripeC.png"
			Case "STRIPE_V"
				Return "Player_V.png"
			Case "SLEEVES"
				Return "Player_Sleeves.png"
			Case "SLEEVE"
				Return "Player_SleeveR.png"
			Case "SLEEVE_L"
				Return "Player_SleeveR.png"
			Case "SLEEVE_R"
				Return "Player_SleeveR.png"
			Case "HOOPS"
				Return "Player_Hoops.png"
			Case "HOOP"
				Return "Player_Hoop.png"
			Case "SINGLEHOOP"
				Return "Player_Hoop.png"
			Case "SPLIT"
				Return "Player_Split.png"
			Case "SPLIT_LR"
				Return "Player_DiagonalSplit.png"
			Case "DIAGONALSPLIT_LR"
				Return "Player_DiagonalSplit.png"
			Case "DIAGONALSPLIT_RL"
				Return "Player_DiagonalSplit.png"
			Case "SEGMENTS"
				Return "Player_Segments.png"
			Case "CHEQUERED"
				Return "Player_Chequered.png"
			Default
				Return "Player_Plain.png"
		End Select
	End Method
