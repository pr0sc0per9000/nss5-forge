' TProfile.ResetTutorial
' VA 0x0056D2A8   60 bytes
' byte-identical vs NSS5.exe
' parameter names are placeholders (a0, a1, ...); the original names are not recoverable

	Method ResetTutorial:Int(a0:Int)
		For Local i:Int = 0 To helppages.length - 1
			helppages[i] = a0
		Next
	End Method
