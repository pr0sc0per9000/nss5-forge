' TSlotStrip.Update
' VA 0x005787DD   836 bytes   vtable slot 0x34   sig ()i   KIND=Method
' byte-identical vs NSS5.exe (836/836, original length from Ghidra's inventory)
' One fruit-machine reel: decelerates, snaps to the nearest fruit, names it, stops.
'
' ASSUMPTIONS
'  Direct calls resolved: 0x005B9690 _bbFloatToInt (-> Int(...)), 0x004C5549 GetText,
'    0x0059B25E _brl_audio_PlaySound, 0x004A7AC0 _bbStringFromInt + 0x004A7C20
'    _bbStringConcat (-> "Fruit: " + Self.fruit), 0x00505B91 LogLine.
'  Module Globals (names ours, types load-bearing):
'    0x00C6EFD4 g_ticks:Int   (the millisecond clock, same Global TEngine.MatchLoop drives)
'    0x00C6C654 g_slotsound:TSound      0x00C6F090 g_slotchannel:TChannel
'    -- PlaySound pushes right-to-left, so 0x00C6C654 is argument 1 (the sound).
'  Field offsets from extracted/object_model.json: reelH 0x08, fruitCount 0x0C, yPos1 0x14,
'    yPos2 0x18, yVel 0x1C, spintime 0x20, spinlength 0x24, reelstopped 0x28, fruit 0x2C.
'  String literals read out of NSS5.exe with harness.read_string; case 8 pushes the SAME
'    address as case 0 (0x00C912D8 "Orange") and then zeroes Self.fruit.
'  Float constant 0x00C912D4 = 0.1.
' SHAPE NOTES (byte-observable)
'  * `Local s:String = ""` really is there: `mov ebx,<empty BBString>` precedes the Select,
'    and ebx is the same register that held h a moment earlier (disjoint live ranges).
'  * The fruit dispatch is a SELECT with no Default -- nine compares back to back then a jmp
'    (codegen-patterns 10.2).
'  * The `To` limit is hoisted into [ebp-4] once, which is what `For i = 0 To Self.fruitCount`
'    emits; the loop terminator is `jle`, i.e. To, not Until.
'  * The two float guards are written `Self.yPos1 > Self.reelH` -- fld the float FIRST, fild
'    the Int second, fxch/fucompp/setbe, so the float is the left operand.
	Method Update:Int()
		'!Global g_ticks:Int
		'!Global g_slotsound:TSound
		'!Global g_slotchannel:TChannel
		If Self.yVel > 0.0
			Self.yVel = Self.yVel - 0.1
			Self.yPos1 = Self.yPos1 + Self.yVel
			Self.yPos2 = Self.yPos2 + Self.yVel
		EndIf
		If Self.reelstopped = 0 And g_ticks > Self.spintime + Self.spinlength
			Local h:Int = Self.reelH / Self.fruitCount
			Local y:Int = Int(Self.yPos1)
			If y < 0 Then y = y + Self.reelH
			If y > Self.reelH Then y = y - Self.reelH
			For Local i:Int = 0 To Self.fruitCount
				If y >= i * h And y <= i * h + h / 2
					Self.yPos1 = i * h
					Self.yPos2 = Self.yPos1 - Self.reelH
					Self.fruit = i
					Local s:String = ""
					Select i
					Case 0
						s = GetText("Orange")
					Case 1
						s = GetText("Plum")
					Case 2
						s = GetText("Banana")
					Case 3
						s = GetText("Apple")
					Case 4
						s = GetText("Grapes")
					Case 5
						s = GetText("Cherries")
					Case 6
						s = GetText("Pineapple")
					Case 7
						s = GetText("Strawberry")
					Case 8
						s = GetText("Orange")
						Self.fruit = 0
					End Select
					PlaySound(g_slotsound, g_slotchannel)
					If Self.fruitCount = 6
						Self.fruit = Self.fruit Mod 3
						LogLine("Fruit: " + Self.fruit)
					Else
						LogLine(s)
					EndIf
					Self.reelstopped = 1
					Self.yVel = 0.0
					Exit
				EndIf
			Next
		EndIf
		If Self.yPos1 > Self.reelH Then Self.yPos1 = Self.yPos2 - Self.reelH
		If Self.yPos2 > Self.reelH Then Self.yPos2 = Self.yPos1 - Self.reelH
	End Method
