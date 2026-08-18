' TProfile.CheckPurchaseAchievements
' VA 0x0056D1E1   199 bytes
' byte-identical vs NSS5.exe
' parameter names are placeholders (a0, a1, ...); the original names are not recoverable

	Method CheckPurchaseAchievements:Int()
		Local a:Int = 0
		Local b:Int = 0
		Local c:Int = 0
		For Local i:Int = 0 To 9
			If items[i] > 0 Then a = a + 1
			If vehicles[i] > 0 Then b = b + 1
			If property[i] > 0 Then c = c + 1
		Next
		If a = 10 Then CheckAchievement(60)
		If b = 10 Then CheckAchievement(61)
		If c = 10 Then CheckAchievement(62)
		If GetLifestyle() >= 100 Then CheckAchievement(63)
	End Method
