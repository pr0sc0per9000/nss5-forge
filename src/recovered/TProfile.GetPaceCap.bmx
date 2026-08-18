' TProfile.GetPaceCap
' VA 0x0056C3D8   113 bytes
' byte-identical vs NSS5.exe
' parameter names are placeholders (a0, a1, ...); the original names are not recoverable

	Method GetPaceCap:Int()
		Local age:Int = GetAge()
		If age < 30 Then Return 100
		Select age
			Case 30
				Return 90
			Case 31
				Return 80
			Case 32
				Return 70
			Case 33
				Return 60
			Case 34
				Return 50
			Case 35
				Return 30
			Default
				Return 10
		End Select
	End Method
