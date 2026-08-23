' TScreen.AddGadget
' VA 0x005105CC  33 bytes  vtable slot 0x40
' byte-identical vs NSS5.exe (33/33, oracle status MATCH under NSS5_NO_LEARN=1)
' Parameter names are not recoverable from the binary and do not affect codegen;
' they are emitted as a0, a1, ... exactly as the harness compiles them.
'
' BOOT SHIM REMOVED -- the defect it was covering was found and fixed elsewhere.
' From 2026-08 this body carried a deliberate `If a0 = Null Then Return` guard, +54 bytes,
' because TList.AddLast throws "Can't insert Null object into list" and the first screen
' built died on `g_screen_home.AddGadget(g_pan_stable)`. The shim's header blamed missing
' gadget creators -- specifically TScreen_GameMenu.UpdateNavPanel, "one of the 41
' never-opened functions". That diagnosis was wrong on both halves:
'
'   * UpdateNavPanel creates no gadgets. It calls SetText/SetColour on g_lbl_year,
'     g_lbl_week and g_lbl_nextopp2. It is also no longer unimplemented.
'   * The shared bars are built by TScreen_GameMenu.CreateScreen, which is byte-verified
'     and already in this tree: :156 `g_pan_title = TPanel.CreatePanel("pan_title", ...)`
'     at 0x00C66768, :181 `g_pan_nav = TPanel.CreatePanel("pan_nav", ...)` at 0x00C667B0.
'     It runs before the seven screens that re-add them, so ordering was never the problem.
'
' The real cause was the Global name split CONTRIBUTING.md warns about. 0x00C667B0 is
' written as g_pan_nav and read as g_pan_money; the g_pan_nav -> g_pan_money edge in
' global_alias_map.tsv/global_alias_unified.tsv was being dropped by assemble.py because
' global_alias_adjudicated.tsv names g_pan_nav the canonical of g_panmenu at higher
' precedence. nss5_assembled.bmx therefore declared BOTH names as separate Globals: the
' writer updated one, seven readers saw Null forever. Its twin at 0x00C66768
' (g_pan_title -> g_pan_stable) did merge, which is why exactly the seven g_pan_money
' readers skipped a gadget at boot and none of the eleven g_pan_stable readers did.
' Fixed by restating the edge in extracted/global_alias_overrides.tsv, which outranks the
' adjudicated canonical. Measured after that fix: zero BOOT SHIM skips, all nine
' smoke_boot milestones through MAIN MENU reached.
	Method AddGadget:Int(a0:TGadget)
		gadgetlist.AddLast(a0)
	End Method
