' TDate.GetStringWeekday
' VA 0x0053702a   154 bytes   vtable slot 0x58   sig (i,i)$
' byte-identical vs NSS5.exe (154/154, original length from Ghidra's inventory)
' No Globals. The seven locale keys are read out of NSS5.exe as BlitzMax string objects
' at 0x00C84CEC..0x00C84DD0. GetText is the recovered module Function at 0x004C5549;
' 0x004A7C90 is _bbStringSlice, i.e. the [0..a1] slice.
	Function GetStringWeekday:String(a0:Int, a1:Int)
		Local d:String[] = ["date_Monday","date_Tuesday","date_Wednesday","date_Thursday","date_Friday","date_Saturday","date_Sunday"]
		If a1 = 0 Then Return GetText(d[a0])
		Return GetText(d[a0])[0..a1]
	End Function
