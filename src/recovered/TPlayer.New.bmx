' TPlayer.New
' VA 0x004ebcb4   977 bytes   mode=reloc   byte-identical vs NSS5.exe
' KIND=Method, SIG ()i, class-table slot 0x10
' ASSUMPTIONS
'  * Nearly all 977 bytes are bcc's implicit constructor: the ctor helper FUN_004A8E50,
'    the class-table store into +0, and one zero/empty-string/empty-array/fldz store per
'    declared field in offset order. Only three source lines exist.
'  * '!Field kickdirection = -1.0  -- field +0xC4 is the ONE non-zero default; the
'    original loads `fld dword [0x00C78AD4]` and that .rdata dword decodes to -1.0f.
'    Every other Float field is `fldz`.
'  * Module Global (name is OURS, TYPE is load-bearing):
'      g_playerlist:TList   0x00C5DE10
'    Typed TList because the very next statement dispatches slot 0x44 on it, which is
'    TList.AddLast(:Object).  The creator is 0x005B40BF, the CreateList|CreateMap|
'    TGNetHost.Create alias set (guide 10.8); CreateList is confirmed by that AddLast.
'  * The null test emits `mov eax,[g] / cmp eax,<bbNullObject> / setne al / movzx / cmp 0
'    / jne` -- the 21-byte `If Not x` form of guide 10.3, not `If x = Null`.
	Method New()
		'!Field kickdirection = -1.0
		'!Global g_playerlist:TList
		If Not g_playerlist Then g_playerlist = CreateList()
		g_playerlist.AddLast(Self)
	End Method
