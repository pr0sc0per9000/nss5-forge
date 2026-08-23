Strict
Framework brl.audio
Import brl.standardio
Global c:TChannel
Print "A: about to SetVolume on Null"
c.SetVolume(1.0)
Print "B: survived SetVolume"
c.SetPaused(0)
Print "C: survived SetPaused"
c.Stop()
Print "D: survived Stop"
