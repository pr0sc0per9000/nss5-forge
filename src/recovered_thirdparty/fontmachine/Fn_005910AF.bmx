' Fn_005910AF  --  fontmachine module Function
' VA 0x005910AF   87 bytes
' byte-identical vs NSS5.exe (87/87, mode=reloc, reloc_masked=3, verified via try_function)
'
' UNCERTAIN: the original name. Module-level Functions carry no reflection record, so the
' name is ours to choose; named by VA, following Fn_00592A13.bmx. Nothing in the binary
' or in this repository records what Font Machine called it, so no guess is written here.
'
' WHAT IT IS: the module's one-call font loader. `bbObjectNew(0x00C967C8)` is
' `New TBitmapFont` (0x00C967C8 is TBitmapFont's class table, extracted/class_tables.tsv),
' then slots 0x40 / 0x44 / 0x48 off that object, which object_model.json gives as
' SetProgressFunction ((f)i)i, Load (:Object,i)i and FontLoaded ()i.
'
' ORDER: the progress callback is installed BEFORE Load runs, which is the only order that
' lets it report progress at all. a1 is pushed at 0x005910CC and a0 at 0x005910DA, so the
' url is the FIRST parameter and the callback the second.
'
' `cmp eax, 1`, not `test eax, eax`: the result of FontLoaded() is compared against the
' literal 1, so the source says `= True` rather than using it as a bare condition.
'
' The `2` handed to Load is the image-flags argument it passes on to LoadImage; it is a
' literal in the original (`push 2`), not a default.

Function Fn_005910AF:TBitmapFont(a0:Object, a1:Int(p0:Float))
	Local f:TBitmapFont = New TBitmapFont
	f.SetProgressFunction(a1)
	f.Load(a0, 2)
	If f.FontLoaded() = True Then Return f
	Return Null
End Function
