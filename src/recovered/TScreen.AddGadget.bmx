' TScreen.AddGadget
' VA 0x005105CC  33 bytes  vtable slot 0x40
' Parameter names are not recoverable from the binary and do not affect codegen;
' they are emitted as a0, a1, ... exactly as the harness compiles them.
'
' ############################################################################
' # BOOT SHIM -- DELIBERATE DIVERGENCE. This body does not byte-match and    #
' # scripts/reverify.py WILL report it as NOT MATCHING. That is               #
' # correct and intended: the project rule is to change a body for            #
' # functional reasons only with the reason in its header, and to expect the  #
' # flag. Revert to the two-line original (kept below) once the gadget        #
' # creators listed there are implemented.                                    #
' ############################################################################
'
' ORIGINAL (byte-identical, 33/33):
'     Method AddGadget:Int(a0:TGadget)
'         gadgetlist.AddLast(a0)
'     End Method
'
' WHY THE GUARD EXISTS
' TList.AddLast throws "Can't insert Null object into list". Screens are built by adding
' gadgets that other functions created, and while those creators are still empty stubs they
' return Null -- so the FIRST screen built killed the boot at
'     g_screen_home.AddGadget(g_pan_stable)
' g_pan_stable and g_pan_money are read by seven screens and assigned by nobody: the shared
' nav-bar panels are built by TScreen_GameMenu.UpdateNavPanel, one of the 41 never-opened
' functions (1,361 bytes). There is no ordering fix; the
' object does not exist yet.
'
' WHY IT IS SAFE
' In the original every gadget passed here is non-Null, so this branch is unreachable in a
' complete build and the change cannot alter real behaviour. It only converts "die at boot"
' into "render without that widget" for the incomplete state we are actually in, which is
' exactly the boot-first rule -- stubs are fine.
'
' IT IS ALSO A PROGRESS METER, NOT A CARPET
' Each skip is logged, so the debug log names every widget still missing rather than hiding
' it. Turn logging on with debug=1 in Settings/Settings.txt.
	Method AddGadget:Int(a0:TGadget)
		If a0 = Null
			LogLine("BOOT SHIM: skipped a Null gadget on screen '" + Self.name + "' -- its creator is still an unimplemented stub")
			Return 0
		EndIf
		gadgetlist.AddLast(a0)
	End Method
