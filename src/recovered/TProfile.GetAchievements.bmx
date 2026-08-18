' TProfile.GetAchievements
' VA 0x0056CF38   56 bytes
' byte-identical vs NSS5.exe
' parameter names are placeholders (a0, a1, ...); the original names are not recoverable

	Method GetAchievements:Int()
		Local c:Int = 0
		For Local a:Int = EachIn achievements
			If a > 0 Then c = c + 1
		Next
		Return c
	End Method
