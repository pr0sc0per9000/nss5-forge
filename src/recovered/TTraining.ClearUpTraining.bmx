' TTraining.ClearUpTraining
' VA 0x00581CC9   182 bytes   vtable slot 0x9c   sig ()i
' byte-identical vs NSS5.exe (182/182, original length from Ghidra's inventory)
' assumptions: Globals 0x00C6CFB8/BC/C0/C4 declared TLabel (slot 0x64 = TGadget.SetText,
' inherited), 0x00C6CF90 Int, 0x00C6F028 TProfile (slot 0x100 = UpdateEnergy(f));
' 0x00505B91 = LogLine and 0x005071C3 = FlushAllInput from src/recovered_module.
	Function ClearUpTraining:Int()
		'!Global g_traininglabel1:TLabel
		'!Global g_traininglabel2:TLabel
		'!Global g_traininglabel3:TLabel
		'!Global g_traininglabel4:TLabel
		'!Global g_trainingstate:Int
		'!Global g_profile:TProfile
		LogLine("ClearUpTraining")
		TTrainingObject.ClearAll()
		g_trainingstate = 0
		g_traininglabel1.SetText("", "", -1, -1)
		g_traininglabel2.SetText("", "", -1, -1)
		g_traininglabel3.SetText("", "", -1, -1)
		g_traininglabel4.SetText("", "", -1, -1)
		g_profile.UpdateEnergy(-20.0)
		FlushAllInput()
	End Function
