' TPlayer.DoAnimJump
' VA 0x004fcf5d   103 bytes   vtable slot 0x1d4   sig ()i
' byte-identical vs NSS5.exe (103/103, original length from Ghidra's inventory)
' harness mode=reloc: absolute addresses differ by construction; emitted code identical.
' The BBRETAIN/BBRELEASE pair around `currentanim = g_anim_jump` is compiler-emitted
'   (inc [g+4] / dec [old+4] / bbGCFree) -- it is not written in source.
' slot 0x3c on TJoy = TJoy.Clear().
' module Globals assumed by this body (names ours, types load-bearing):
'   Global g_anim_jump:Int[]      ' 0x00c5deb8, init = bbEmptyArray
'   Global g_jumpzvel:Float       ' 0x00c5de5c
	Method DoAnimJump:Int()
		'!Global g_anim_jump:Int[]
		'!Global g_jumpzvel:Float
		LogLine("DoAnimJump")
		currentanim = g_anim_jump
		frame = 0
		joy.Clear()
		zvel = g_jumpzvel
	End Method
