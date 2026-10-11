' fontmachine: Font Machine 1.5.1's main compile unit. assemble.py emits it as
' src/assembled/fontmachine.bmx. The module name is not recoverable.
' VA 0x0058FDD4   293 bytes   FontMachineModuleInit
' byte-identical vs NSS5.exe (293/293, mode=reloc, compare_module_body.py --unit --in-build under NSS5_NO_LEARN=1)
'
'   +0     guard on [0x00C95F78]                                      (bcc template)
'   +31    call ___bb_blitz_blitz                                      implicit, first
'   +36    call ___bb_max2d_max2d (0x005ACB0C)                         Import BRL.Max2D
'   +41    call ___bb_pngloader_pngloader (0x0059BF40)                 Import BRL.PNGLoader
'   +46    call ___bb_retro_retro, ___bb_reflection_reflection         the next two
'   +56    call 0x00592780, the sub-unit's init                        Import "fontmachine_base.bmx"
'   +61    17 x bbObjectRegisterType, the Types in '!Types order
'   +282   epilogue; no top-level statements and no Global initialisers
' An Import is called only if no earlier Import already reaches it, so the order is forced.
'!Types z_e3390d53_c8a7_41d3_9293_f4dcf0f638b5_3_0 z_blide_bge3390d53_c8a7_41d3_9293_f4dcf0f638b5 z_My_e3390d53_c8a7_41d3_9293_f4dcf0f638b5
'!Types TBitmapFont TPrivateBitmapFont TRenderStatus EConstBlend TDrawTextException TBitmapFontLoadException TPrivateException TBitMapChar
'!Types iTextRendererFXBase TDrawTextAction TDrawCharAction eDrawCharStatus TFontKerning TPrivateFontKerning
'!Functions Fn_005910AF Fn_00591106
SuperStrict
Import BRL.Max2D
Import BRL.PNGLoader
Import BRL.Retro
Import BRL.Reflection
Import "fontmachine_base.bmx"
