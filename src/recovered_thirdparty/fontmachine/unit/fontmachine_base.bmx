' fontmachine_base: Font Machine's sub-unit, Imported by fontmachine.bmx. assemble.py emits
' it as src/assembled/fontmachine_base.bmx. The real file name is not recoverable.
' VA 0x00592780   135 bytes   FontMachineSubUnitInit
' byte-identical vs NSS5.exe (135/135, mode=reloc, compare_module_body.py --unit --in-build under NSS5_NO_LEARN=1)
'
'   +0     guard on [0x00C978F0]                                      (bcc template)
'   +31    call ___bb_blitz_blitz                                      implicit, first
'   +36    call ___bb_math_math (0x005B3490)                           Import BRL.Math
'   +41    call ___bb_basic_basic (0x0059CA88)                         Import BRL.Basic
'   +46    6 x bbObjectRegisterType, the Types in '!Types order
'   +124   epilogue; no top-level statements
' Math must come before Basic: Basic imports Math, so Basic first drops the Math call.
'!Parent fontmachine
'!Types z_84d6b1ac_20df_4ac4_b754_f05b5e01c02b_3_0 z_blide_bg84d6b1ac_20df_4ac4_b754_f05b5e01c02b z_My_84d6b1ac_20df_4ac4_b754_f05b5e01c02b TFontMachineVersion TRectangle TDrawingPoint
'!Functions Fn_00592967 Fn_00592A13 Fn_00592A37 Fn_00592B79 Fn_00592B87
SuperStrict
Import BRL.Math
Import BRL.Basic
