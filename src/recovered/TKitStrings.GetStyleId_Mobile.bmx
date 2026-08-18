' TKitStrings.GetStyleId_Mobile
' VA 0x004dce33   727 bytes   vtable slot 0x44   sig ()i
' byte-identical vs NSS5.exe (727/727, original length from Ghidra's inventory)
' No assumptions beyond the field name TKitStrings.style (offset 0x8) from
' object_model.json; the string literals were read straight out of NSS5.exe's
' constant pool.  Matched in 'reloc' mode (string-constant addresses masked).
	Method GetStyleId_Mobile:Int()
		Select style
			Case "PLAIN"
				Return 0
			Case "TRIM"
				Return 1
			Case "STRIPES"
				Return 2
			Case "STRIPE"
				Return 2
			Case "STRIPE_L"
				Return 2
			Case "STRIPE_R"
				Return 2
			Case "STRIPE_LR"
				Return 3
			Case "STRIPE_RL"
				Return 4
			Case "STRIPE_C"
				Return 5
			Case "STRIPE_V"
				Return 6
			Case "SLEEVES"
				Return 10
			Case "SLEEVE"
				Return 11
			Case "SLEEVE_L"
				Return 11
			Case "SLEEVE_R"
				Return 11
			Case "HOOPS"
				Return 8
			Case "HOOP"
				Return 9
			Case "SINGLEHOOP"
				Return 9
			Case "SPLIT"
				Return 12
			Case "SPLIT_LR"
				Return 12
			Case "DIAGONALSPLIT_LR"
				Return 12
			Case "DIAGONALSPLIT_RL"
				Return 12
			Case "SEGMENTS"
				Return 14
			Case "CHEQUERED"
				Return 13
			Default
				Return 0
		End Select
	End Method
