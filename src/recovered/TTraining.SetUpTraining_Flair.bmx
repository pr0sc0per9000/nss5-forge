' TTraining.SetUpTraining_Flair
' VA 0x0057F1C8   973 bytes   KIND=Function (static, no implicit Self)   vtable slot 0x4c   sig ()i
' byte-identical vs NSS5.exe (973/973, original length from Ghidra's inventory, mode=reloc)
'
' Simpler twin of SetUpTraining_Shooting/Dribbling: only 10 levels (not 20), so the Select
' on g_training_int04 needs no odd/even reordering -- Case 1..10 in plain numeric order
' matches the je-chain at 0x0057F30C byte for byte. No trailing "Select g_trainingstate"
' block (Shooting's Case 9/10 dummy-line setup) -- this function ends right after
' ResetTraining().
'
' Ghidra's decompile mis-orders the final four assignments (it prints
' `g_training_int12 = Int(...)` then `g_training_int14 = g_training_int12`), but the
' disassembly stores in a different order: int13=0, then int14=Int(YardsToPixels(-10.0))
' (the call result is stored to int14 directly), THEN int11=int13, int12=int14. bcc always
' stores in source order, so the source reads int13, int14, int11, int12 -- and that is
' what reproduces the byte sequence at 0x0057F544-0x0057F57E. Ghidra's SSA renaming is not
' evidence for statement order (10.1).
'
' Globals: 0x00C6F028 g_profile:TProfile (field flair=+0xBC, contractwage=+0x78)
'   0x00C6CF94 int04   0x00C6CF9C int06   0x00C6CFA4 int08$   0x00C6CFA8 int09$
'   0x00C6CFAC int10$  0x00C6CFB8 g_traininglabel1:TLabel (slot 0x64 SetText, inherited)
'   0x00C6CFD0 int11   0x00C6CFD4 int12   0x00C6CFD8 int13   0x00C6CFDC int14
'   0x00C6CFF4 int20   0x00C6CFFC int22   0x00C6D008 float03   0x00C6D00C float04
' Class-table slot calls: TPitch+0x6C=YardsToPixels(f)f, TTraining+0xB4=ResetTraining()i
'   (this Type, unqualified).
	Function SetUpTraining_Flair:Int()
		'!Global g_profile:TProfile
		'!Global g_training_int04:Int
		'!Global g_training_int06:Int
		'!Global g_training_int08:String
		'!Global g_training_int09:String
		'!Global g_training_int10:String
		'!Global g_traininglabel1:TLabel
		'!Global g_training_int11:Int
		'!Global g_training_int12:Int
		'!Global g_training_int13:Int
		'!Global g_training_int14:Int
		'!Global g_training_int20:Int
		'!Global g_training_int22:Int
		' g_training_float03/04 original data-section values 0.25/5.0
		' (0x00C6D008/0x00C6D00C), read directly from NSS5.exe. See codegen-patterns
		' 21.1/21.3.
		'!Global g_training_float03:Float = 0.25
		'!Global g_training_float04:Float = 5.0
		LogLine("SetUpTraining_Flair")
		g_training_int04 = g_profile.flair / 10 + 1
		ClampInt(Varptr g_training_int04, 1, 10)
		g_training_int08 = GetText("Flair Training")
		g_training_int09 = GetText("Level") + " " + g_training_int04
		g_training_int10 = GetText("CTRAINING_FLAIR1")
		If g_training_int04 = 1 And g_profile.contractwage = 0
			g_traininglabel1.SetText(GetText("CMESSAGE_TRIALFLAIR"), "", -1, -1)
		EndIf
		g_training_int06 = -1
		Select g_training_int04
			Case 1
				g_training_int22 = 20
				g_training_float03 = 0.45
				g_training_int20 = 4
				g_training_float04 = 1.75
			Case 2
				g_training_int22 = 18
				g_training_float03 = -0.45
				g_training_int20 = 4
				g_training_float04 = 1.7
			Case 3
				g_training_int22 = 16
				g_training_float03 = 0.5
				g_training_int20 = 5
				g_training_float04 = 1.65
			Case 4
				g_training_int22 = 14
				g_training_float03 = -0.5
				g_training_int20 = 5
				g_training_float04 = 1.6
			Case 5
				g_training_int22 = 12
				g_training_float03 = 0.55
				g_training_int20 = 6
				g_training_float04 = 1.55
			Case 6
				g_training_int22 = 10
				g_training_float03 = -0.55
				g_training_int20 = 6
				g_training_float04 = 1.5
			Case 7
				g_training_int22 = 10
				g_training_float03 = 0.6
				g_training_int20 = 6
				g_training_float04 = 1.5
			Case 8
				g_training_int22 = 8
				g_training_float03 = -0.6
				g_training_int20 = 6
				g_training_float04 = 1.5
			Case 9
				g_training_int22 = 6
				g_training_float03 = 0.75
				g_training_int20 = 7
				g_training_float04 = 1.5
			Case 10
				g_training_int22 = 4
				g_training_float03 = -0.75
				g_training_int20 = 7
				g_training_float04 = 1.5
		End Select
		g_training_int13 = 0
		g_training_int14 = Int(TPitch.YardsToPixels(-10.0))
		g_training_int11 = g_training_int13
		g_training_int12 = g_training_int14
		ResetTraining()
	End Function
