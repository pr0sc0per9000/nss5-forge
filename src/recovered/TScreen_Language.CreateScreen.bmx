' TScreen_Language.CreateScreen
' VA 0x0051BC09   867 bytes   mode=reloc   byte-identical vs NSS5.exe (867/867)
' KIND=Function (static), SIG ()i, class-table slot 0x30
' ASSUMPTIONS -- module Globals (names ours; ADDRESS and TYPE are load-bearing)
'   0x00C638C0 -> g_langscreen:TScreen   (slot 0x40 = TScreen.AddGadget)
'   0x00C5A328 -> g_langmap:TMap         (passed to MapKeys; slot 0x40 = TMap.ValueForKey,
'                 and the per-language value downcasts to TMap again)
'   0x00C6EFDC -> g_screenwidth:Int      0x00C6EFE0 -> g_screenheight:Int
' Class-table slots: 0x00C61C64 TScreen+0x38 CreateScreen; 0x00C623CC TButton+0x88
'   CreateButton; 0x00C59A38 TNation+0x70 ButtonizeFlag(:TImage,i)i;
'   0x00C63988 TScreen_Language+0x38 ButtonLanguage (own Type -> bare name).
'   0x005B40BF resolved to CreateList by the following AddLast (slot 0x44), 10.8.
'   0x00599D0B resolved to MapKeys (its result is EachIn'd and the element downcasts to
'   String against 0x005C7D60); the other alias members (ChannelPlaying, GadgetY) do not fit.
' TWO THINGS GHIDRA DROPPED AS DEAD and both are load-bearing (-11 bytes without them):
'   * `n` is reset to 0 again after `ch` and incremented at the END of the third loop body.
'     Ghidra elides both because nothing reads `n` after loop 2.
'   * The TList built by the first loop is never read either; it is still constructed and
'     filled. Reproduce the original's quirks, do not tidy them (16.8).
' The image path must be a String LOCAL: the original pushes LoadImageChecked's -1 AFTER
'   evaluating the concat (16.2). Inlining it moves the `push -1` 28 bytes earlier.
' `String(m.ValueForKey(...))` is the `cmp eax,bbNullObject / jne / mov eax,bbEmptyString`
'   pair after each downcast -- an Object->String cast, not an If.
' Literals read out of .data.
'!Global g_langscreen:TScreen
'!Global g_langmap:TMap
'!Global g_screenwidth:Int
'!Global g_screenheight:Int
g_langscreen = TScreen.CreateScreen("language", Null, Null, Null)
g_langscreen.AddGadget(TButton.CreateButton("pan_title", "Select Language", 0, 0, 800, 60, 0, 4, "FFFFFF", "FFFFFF", Null, Null, 1.0, 0, ""))
Local l:TList = CreateList()
For Local k:String = EachIn MapKeys(g_langmap)
	l.AddLast(k)
Next
Local cols:Int = 5
Local n:Int = 0
For Local k:String = EachIn MapKeys(g_langmap)
	n = n + 1
Next
If n Mod 3 = 0 Then cols = 4
If n Mod 4 = 0 Then cols = 5
If n Mod 5 = 0 Then cols = 6
Local cw:Int = g_screenwidth / cols
Local ch:Int = g_screenheight / 3
n = 0
Local col:Int = 1
Local row:Int = 0
For Local k:String = EachIn MapKeys(g_langmap)
	Local m:TMap = TMap(g_langmap.ValueForKey(k))
	Local path:String = "GameMedia/Images/Nations/NationIm_" + String(m.ValueForKey("Tag_NationId")) + ".png"
	Local img:TImage = LoadImageChecked(path, -1)
	TNation.ButtonizeFlag(img, 0)
	g_langscreen.AddGadget(TButton.CreateButton(k, "", cw * col - 32, ch + row * 60 - 22, 64, 44, 1, 2, "FFFFFF", "FFFFFF", img, ButtonLanguage, 1.0, 1, String(m.ValueForKey("Tag_Language"))))
	col = col + 1
	If col = cols
		col = 1
		row = row + 1
	EndIf
	n = n + 1
Next
