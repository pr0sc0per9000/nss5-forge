' TProfile.WearBoots
' VA 0x0056A310   86 bytes
' byte-identical vs NSS5.exe
' parameter names are placeholders (a0, a1, ...); the original names are not recoverable

	Method WearBoots:Int()
		For Local i:Int = 0 To 9
			If boots[i] > 0 Then boots[i] = boots[i] - 1
		Next
		If shinpads > 0 Then shinpads = shinpads - 1
	End Method
