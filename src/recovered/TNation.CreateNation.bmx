' TNation.CreateNation
' VA 0x004bd649   2986 bytes   vtable slot 0x44   sig ($)i
' byte-identical vs NSS5.exe (2986/2986, original length from Ghidra's inventory)
' VA        0x004BD649   classtable slot 0x44   KIND=Function (static)   SIG=($)i
' ORACLE    MATCH mode=reloc  2986/2986 bytes  reloc_masked=181
'           Re-run under NSS5_NO_LEARN=1: MATCH 2986/2986, learned_helpers=none.
'
' MODULE GLOBAL
'   0x00C596F8 -> g_flagdefault:TImage  (name is ours). globals_final.tsv types it
'   `Object` from usage only; TImage is CONSTRUCTION-SITE evidence -- it is assigned from
'   LoadImageChecked (declared :TImage) and passed to MidHandleImage. This is the single
'   fallback flag, loaded once and shared by every nation whose own flag file is missing.
'
' CALL TARGETS RESOLVED
'   0x00505BCB -> module Function NextFieldInt($ Var,$)i   (src/recovered_module)
'   0x00505C64 -> module Function NextField($ Var,$)$      (src/recovered_module)
'   0x005064A2 -> module Function ResizeImage(:TImage,i,i):TImage
'   0x004BC372 -> module Function LoadImageChecked($,i):TImage
'   0x004A8F20 -> `New TNation` (bbObjectNew on the TNation class table 0x00C599C8)
'   0x004A6E90 -> _bbStringToFloat, i.e. the `Float(...)` cast of a String
'   0x004A75B0 -> _bbStringReplace  ->  .Replace("CKITTYPE_", "")
'   0x004A7AC0 / 0x004A7C20 -> _bbStringFromInt / _bbStringConcat (the path concat)
'   0x005AE38D -> _brl_max2d_MidHandleImage
'   0x004A8590 -> inlined BBRELEASE's GC free; never written in source
'   call [eax+0x38] on a TKitStrings -> TKitStrings.CheckKitColours
'   call [0x00C5C030] -> TFormation class table + 0x74 = PickRandomFormation()
'   call [eax+0x70] on the TNation -> TNation.ButtonizeFlag(:TImage,i)
'
' LITERALS -- read out of NSS5.exe with harness.read_string, not guessed (a MATCH masks a
' literal's ADDRESS, so it can never certify the text):
'   0x00C6FCC0 "~t"   0x00C6FCD0 "CKITTYPE_"   0x00C5D284 ""
'   0x00C6FCF0 "GameMedia/Images/Nations/NationIm_0.png"
'   0x00C6FD60 "GameMedia/Images/Nations/NationIm_"   0x00C6FD4C ".png"
'
' FIELD OFFSETS (object_model.json; TNation Extends TBase_Team, instance size 116)
'   TBase_Team: +0x08 randno  +0x0C id  +0x10 name  +0x14 shortname  +0x18 tla
'     +0x1C labelname  +0x20 labelshortname  +0x24 strength  +0x28..0x30 rivalid1..3
'     +0x34 stadiumname  +0x38 stadiumcapacity  +0x3C stadiumlongitude:Float
'     +0x40 stadiumlatitude:Float  +0x44/0x48/0x4C/0x50 kitcolsHome/Away/Third/Keeper
'     :TKitStrings  +0x54 formation  +0x58 imgFlag  +0x5C imgFlagSmall
'   TNation: +0x60 nationality  +0x64 continent  +0x68 climate  +0x6C primaryskin
'     +0x70 secondaryskin
'   TKitStrings: +0x08 style  +0x0C shirt1  +0x10 shirt2  +0x14 shorts  +0x18 socks
'
' SOURCE FORM -- `sub esp,4` is ONE dword slot, and it holds `line`. Every other Local in
' this 2,986-byte body is register-resident and costs nothing (guide 6 / 16.2).
' Same family as TContinent.CreateContinent, TStadium.CreateStadium,
' TPromotionPlace.CreatePromotionPlace: one tab-separated line parsed field by field.
'
' THREE SPELLINGS WERE DISCRIMINATED AGAINST NEGATIVE CONTROLS (all NSS5_NO_LEARN=1):
'   1. `n.ButtonizeFlag(...)` -- instance-qualified, NOT `TNation.ButtonizeFlag(...)`.
'      The original emits `mov eax,[esi] / call [eax+0x70]` (through the object's own
'      class table); the Type-qualified spelling emits `call [abs]` and gives 2373/2986.
'   2. `If Not g_flagdefault` / `If Not n.imgFlag`, NOT `= Null` (guide 10.3): the tell is
'      `cmp eax,0x5C9C80 / setne al / movzx eax,al / cmp eax,0 / jne`. The `= Null`
'      spelling gives 2249/2986.
'   3. The guard is the EARLY-RETURN spelling `< 1` (`cmp ebx,1 / jge`), as in the two
'      sibling Create* functions.
' NOT discriminated (measured equal): writing the kit style as one inline expression, or
' as `Local k:String = NextField(...)` then `k.Replace(...)`, gives BYTE-IDENTICAL output
' (both 2986/2986) -- bcc evaluates a String method's receiver before pushing the
' arguments, so guide 16.2's push-order tell does not apply to a method receiver. The
' inline form is kept because it invents no name.
'
' The `Or` is a real short-circuit: `sete/movzx/cmp/jne` over the first test jumps past the
' second, then one `cmp eax,0 / je` guards the body.

Function CreateNation(a0:String)
	'!Global g_flagdefault:TImage
	Local line:String = a0
	Local id:Int = NextFieldInt(line, "~t")
	If id < 1 Then Return 0
	Local n:TNation = New TNation
	n.id = id
	n.name = NextField(line, "~t")
	n.shortname = NextField(line, "~t")
	n.labelname = n.name
	n.labelshortname = n.shortname
	n.tla = NextField(line, "~t")
	n.strength = NextFieldInt(line, "~t")
	n.rivalid1 = NextFieldInt(line, "~t")
	n.rivalid2 = NextFieldInt(line, "~t")
	n.rivalid3 = NextFieldInt(line, "~t")
	n.stadiumname = NextField(line, "~t")
	n.stadiumcapacity = NextFieldInt(line, "~t")
	n.stadiumlongitude = Float(NextField(line, "~t"))
	n.stadiumlatitude = Float(NextField(line, "~t"))
	n.kitcolsHome.style = NextField(line, "~t").Replace("CKITTYPE_", "")
	n.kitcolsHome.shirt1 = NextField(line, "~t")
	n.kitcolsHome.shirt2 = NextField(line, "~t")
	n.kitcolsHome.shorts = NextField(line, "~t")
	n.kitcolsHome.socks = NextField(line, "~t")
	n.kitcolsAway.style = NextField(line, "~t").Replace("CKITTYPE_", "")
	n.kitcolsAway.shirt1 = NextField(line, "~t")
	n.kitcolsAway.shirt2 = NextField(line, "~t")
	n.kitcolsAway.shorts = NextField(line, "~t")
	n.kitcolsAway.socks = NextField(line, "~t")
	n.kitcolsThird.style = NextField(line, "~t").Replace("CKITTYPE_", "")
	n.kitcolsThird.shirt1 = NextField(line, "~t")
	n.kitcolsThird.shirt2 = NextField(line, "~t")
	n.kitcolsThird.shorts = NextField(line, "~t")
	n.kitcolsThird.socks = NextField(line, "~t")
	n.kitcolsKeeper.style = NextField(line, "~t").Replace("CKITTYPE_", "")
	n.kitcolsKeeper.shirt1 = NextField(line, "~t")
	n.kitcolsKeeper.shirt2 = NextField(line, "~t")
	n.kitcolsKeeper.shorts = NextField(line, "~t")
	n.kitcolsKeeper.socks = NextField(line, "~t")
	n.kitcolsHome.CheckKitColours()
	n.kitcolsAway.CheckKitColours()
	n.kitcolsThird.CheckKitColours()
	n.kitcolsKeeper.CheckKitColours()
	n.formation = NextFieldInt(line, "~t")
	If n.formation = 0 Or n.formation > 10
		n.formation = TFormation.PickRandomFormation()
	EndIf
	n.nationality = NextField(line, "~t")
	n.continent = NextFieldInt(line, "~t")
	n.climate = NextFieldInt(line, "~t")
	n.primaryskin = NextFieldInt(line, "~t")
	n.secondaryskin = NextFieldInt(line, "~t")
	If Not g_flagdefault
		g_flagdefault = LoadImageChecked("GameMedia/Images/Nations/NationIm_0.png", -1)
	EndIf
	MidHandleImage(g_flagdefault)
	n.imgFlag = LoadImageChecked("GameMedia/Images/Nations/NationIm_" + n.id + ".png", -1)
	If Not n.imgFlag
		n.imgFlag = g_flagdefault
	EndIf
	n.ButtonizeFlag(n.imgFlag, 0)
	n.imgFlagSmall = ResizeImage(n.imgFlag, 42, 30)
	MidHandleImage(n.imgFlag)
	MidHandleImage(n.imgFlagSmall)
End Function
