Strict
Framework brl.audio
Import brl.standardio
Global g_chn1:TChannel
Print "chn1 is Null: " + (g_chn1 = Null)
Print "about to StopChannel(Null)"
StopChannel(g_chn1)
Print "survived"
