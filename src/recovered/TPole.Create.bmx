' TPole.Create  -- KIND=Function (static method on TPole, no implicit Self)
' VA 0x005838CE   268 bytes   sig (i,i,$)i   slot 0x48
' byte-identical vs NSS5.exe (268/268, original length from Ghidra's inventory, mode=reloc,
' reloc_masked=19)
'
' ASSUMPTIONS
'  * Globals declared here (names are OURS -- module Globals have no debug record):
'      g_pole_img:TImage   at 0x00C6D8F0   (retain/release traffic => reference; the
'                                           LoadAnimImageChecked return type fixes TImage)
'      g_pole_snd:TSound   at 0x00C6D8F4   (callee 0x004BC564 is LoadSoundChecked:TSound,
'                                           NOT LoadImageChecked -- the annotated decomp's
'                                           "img" inference for this one is wrong)
'  * String literals are ours: the two data addresses (0x00C92B54, 0x00C92BA4) are masked by
'    the oracle, so literal CONTENT is not byte-observable here. Paths are plausible, not proven.
'  * Callees resolved: 0x004BC664 = LoadAnimImageChecked ($,i,i,i,i,i):TImage (6 args),
'    0x005AE336 = _brl_max2d_SetImageHandle, 0x004BC564 = LoadSoundChecked ($,i):TSound,
'    0x004A8F20 = bbObjectNew with ClassTable_TPole => New TPole.
'  * The null guard is the `If Not g` form (21 bytes: cmp/setne/movzx/cmp/jne, guide 10.3),
'    not `If g = Null` (12 bytes).
'  * Fields img/frame/x/y are inherited from TTrainingObject (+0x08/+0x0C/+0x10/+0x14);
'    colour (+0x24) is TPole's own.
'!Global g_pole_img:TImage
'!Global g_pole_snd:TSound
	Function Create:Int(a0:Int, a1:Int, a2:String)
		If Not g_pole_img
			g_pole_img = LoadAnimImageChecked("EngineMedia/Match/Pitch/Poles.png", 16, 80, 0, 3, -1)
			SetImageHandle(g_pole_img, 7, 79)
			g_pole_snd = LoadSoundChecked("EngineMedia/Match/Sounds/PoleBoing.ogg", 0)
		End If
		Local p:TPole = New TPole
		p.img = g_pole_img
		p.frame = 0
		p.x = a0
		p.y = a1
		p.colour = a2
	End Function
