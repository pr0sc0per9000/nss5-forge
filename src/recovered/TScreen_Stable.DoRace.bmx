' TScreen_Stable.DoRace
' VA 0x00588A89   528 bytes   class-table slot 0x60   sig ()i   KIND=Function (static)
' byte-identical vs NSS5.exe (528/528, original length from Ghidra's inventory)
' harness mode=reloc, reloc_masked=40.
' Body-only format: statements only, parameters are a0, a1, ...
' CALL TARGETS RESOLVED
'   FUN_00505b91 = the recovered module Function LogLine ($)
'   FUN_0059f089 = _brl_random_Rand ; here a genuine two-argument Rand(0,7)
'   FUN_0059b37e = _brl_audio_ResumeChannel
'   FUN_004a8f60 = _bbObjectDowncast (the For EachIn); the downcast class table is
'                  THorse (named as such in extracted/decomp_annotated)
'   slot 0x104 on 0x00c6f028 = TProfile.Bet(i)i
'   [0x00c66914] = TScreen_GameMenu class table (0x00c668dc) + 0x38 = UpdateTitlePanel()
'   [0x00c6b274] = TScreenMessage class table (0x00c6b234) + 0x40 = ClearAll(i)
'   slot 0x54 on each TPanel = TGadget.Hide() -- INHERITED, TPanel has no 0x54 of its own
'   slot 0x38 on the TChannel = SetVolume(f)
' THorse fields: img_myjockey +0xc (:TImage), frame +0x14, x +0x18, y +0x1c, oldx +0x20,
'   xvel +0x28, yvel +0x2c, energy +0x3c, strength +0x44, textpos +0x70.
' SHAPE NOTES (measured)
'   * the Bet test is an EARLY RETURN (`cmp eax,0 / jne body / mov eax,0 / jmp end`),
'     the section-3f guard shape.  As an If-block enclosing everything the body is
'     6 bytes short of 528 in the guard and cannot be fixed elsewhere.
'   * `h.y = yy` where yy is an Int Local emits `mov [ebp-0x10],edi / fild / fstp`.
'   * CONSTANTS CORRECTED: the four float constants were written 12.34 as
'     placeholders (the oracle masks the .rdata ADDRESS, so any value of the right width
'     matched equally at 0x00c93b30 / 0x00c93b34 / 0x00c93b38 / 0x00c93b3c).
'     scripts/check_floats.py + direct disassembly (code offsets +68/+165/+188/+484) give
'     the real values, in source order: g_stable_startx=5500.0, h.xvel *0.0015,
'     h.x = ... - h.xvel*30.0, g_stable_volume = g_options_volume/100.0.
'     Re-verified MATCH 528/528.  "DoRace" stands for the trace literal 0x00c93b18.
' module Globals assumed by this body (names ours, types load-bearing):
'   Global g_profile:TProfile        ' 0x00c6f028 (construction, high)
'   Global g_stable_bet:Int          ' 0x00c6df68
'   Global g_stable_startx:Float     ' 0x00c6df4c
'   Global g_runners:TList            ' 0x00c6e298 -- table says only "Object, usage,
'                                    '   low"; slot 0x8c (ObjectEnumerator) is used
'                                    '   and the members downcast to THorse.
'   Global g_jockeyimages:TImage[]   ' 0x00c6e2b8 -- table says Object[]; elements are
'                                    '   retained and stored into THorse.img_myjockey.
'   Global g_stable_arr04:Float[]    ' 0x00c6df60 -- table says Object[].  IT IS Float[]:
'                                    '   the three zero stores are `fldz / fstp`, not
'                                    '   `mov dword ...,0`.  Declaring it Int[] costs
'                                    '   exactly 2 bytes per element, 6 in total, and was
'                                    '   the last error in this body.
'   Global g_stable_state:Int        ' 0x00c6df70
'   Global g_stable_panel1..4:TPanel ' 0x00c66768 / 0x00c6dee4 / 0x00c6deb0 / 0x00c6dee8
'   Global g_stable_obj845:Object    ' 0x00c6df28 -- assigned Null with full retain of
'                                    '   bbNullObject + release of the old value, so it
'                                    '   holds a reference; nothing here narrows the Type.
'   Global g_stable_int01:Int        ' 0x00c6df2c
'   Global g_stable_channel:TChannel ' 0x00c6df1c -- ResumeChannel() takes it
'   Global g_stable_volume:Float     ' 0x00c6df18
'   Global g_options_volume:Float    ' 0x00c5d220
'!Global g_profile:TProfile
'!Global g_stable_bet:Int
'!Global g_stable_startx:Float
' 0x00C6E298 is the RACE RUNNERS list, not the master horse list. THorse.SelectRunners
' declares both in one body -- g_horses for 0x00C6E294 (the list it enumerates and
' sorts) and g_runners for 0x00C6E298 (the list it Clears and AddLasts into) -- so the
' two are provably different slots, and the module body creates them separately. Spelled
' g_runners here, this body's slot shared the emitted variable of the master list.
'!Global g_runners:TList
'!Global g_jockeyimages:TImage[]
'!Global g_stable_arr04:Float[]
'!Global g_stable_state:Int
'!Global g_stable_panel1:TPanel
'!Global g_stable_panel2:TPanel
'!Global g_stable_panel3:TPanel
'!Global g_stable_panel4:TPanel
'!Global g_stable_obj845:Object
'!Global g_stable_int01:Int
'!Global g_stable_channel:TChannel
'!Global g_stable_volume:Float
'!Global g_options_volume:Float = 100.0
LogLine("DoRace")
If Not g_profile.Bet(g_stable_bet) Then Return 0
TScreen_GameMenu.UpdateTitlePanel()
g_stable_startx = 5500.0
Local yy:Int = 280
Local n:Int = 0
For Local h:THorse = EachIn g_runners
	h.xvel = h.strength * h.energy * 0.0015
	h.yvel = 0
	h.x = g_stable_startx - h.xvel * 30.0
	h.oldx = h.x
	h.textpos = 0
	h.y = yy
	yy = yy + 40
	h.frame = Rand(0,7)
	h.img_myjockey = g_jockeyimages[n]
	n = n + 1
Next
g_stable_startx = -g_stable_startx
g_stable_arr04[0] = 0
g_stable_arr04[1] = 0
g_stable_arr04[2] = 0
g_stable_state = 2
TScreenMessage.ClearAll(0)
g_stable_panel1.Hide()
g_stable_panel2.Hide()
g_stable_panel3.Hide()
g_stable_panel4.Hide()
g_stable_obj845 = Null
g_stable_int01 = 0
ResumeChannel(g_stable_channel)
g_stable_volume = g_options_volume / 100.0
g_stable_channel.SetVolume(g_stable_volume)
