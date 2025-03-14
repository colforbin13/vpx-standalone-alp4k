' Attack & Revenge from Mars v5.5.1 - VPX8
' Based on the tables by Bally/Williams
' Can also use the freeplay ROM from Attack from Mars
' DOF by arngrim

Option Explicit
Randomize

Const Ballsize = 50
Const Ballmass = 1

On Error Resume Next
ExecuteGlobal GetTextFile("controller.vbs")
If Err Then MsgBox "You need the controller.vbs in order to run this table, available in the vp10 package"
On Error Goto 0

Const bRotateSaucers = True 'change this if you want the small saucers to rotate
Const bRotateBigUFO = True

Dim VarHidden, UseVPMColoredDMD
If Table1.ShowDT = true then
    UseVPMColoredDMD = true
    VarHidden = 1
Else
    UseVPMColoredDMD = False
    VarHidden = 0
End If

' Use Modulated Flashers
Const UseVPMModSol = False

LoadVPM "01560000", "WPC.VBS", 3.26

'********************
'Standard definitions
'********************

Const UseSolenoids = 2
Const UseLamps = 0
Const UseSync = 0
Const HandleMech = 0

' special fastflips
Const cSingleLFlip = 0
Const cSingleRFlip = 0

' Standard Sounds
Const SSolenoidOn = "fx_Solenoidon"
Const SSolenoidOff = "fx_solenoidoff"
Const SCoin = "fx_Coin"

' Set GiCallback2 = GetRef("UpdateGI2") 'modulated Gi
Set GiCallback = GetRef("UpdateGI")

Dim bsTrough, bsL, bsR, dtDrop, x, BallFrame, plungerIM, Mech3bank

'******************
' RealTime Updates
'******************

Sub RealTime_Timer
    BigUfoUpdate
    RollingUpdate
End Sub

'************
' Table init.
'************

Const cGameName = "afm_113b" 'arcade rom - with credits
'Const cGameName = "afm_113"  'home rom - free play

Sub Table1_Init
    vpmInit Me
    With Controller
        .GameName = cGameName
'		NVOffset (3)
        If Err Then MsgBox "Can't start Game " & cGameName & vbNewLine & Err.Description:Exit Sub
        .SplashInfoLine = "Attack & Revenge from Mars" & vbNewLine & "VPX table by JPSalas v5.5.1"
        .Games(cGameName).Settings.Value("rol") = 0
        .HandleKeyboard = 0
        .ShowTitle = 0
        .ShowDMDOnly = 1
        .ShowFrame = 0
        .HandleMechanics = 0
        .Hidden = VarHidden
        On Error Resume Next
        .Run GetPlayerHWnd
        If Err Then MsgBox Err.Description
        On Error Goto 0
        .Switch(22) = 1 'close coin door
        .Switch(24) = 1 'and keep it close
    End With

    ' Nudging
    vpmNudge.TiltSwitch = 14
    vpmNudge.Sensitivity = 1
    vpmNudge.TiltObj = Array(bumper1, bumper2, bumper3, LeftSlingshot, RightSlingshot)

    ' Trough
	Set bsTrough = New cvpmTrough
	With bsTrough
	.size = 4
	'.entrySw = 18
	.initSwitches Array(32, 33, 34, 35)
	.Initexit BallRelease, 80, 6
	.InitExitSounds SoundFX("fx_Solenoid",DOFContactors), SoundFX("fx_ballrel",DOFContactors)
	.Balls = 4
	End With

    ' Droptarget
    Set dtDrop = New cvpmDropTarget
    With dtDrop
        .InitDrop sw77, 77
        .initsnd SoundFX("fx_droptarget",DOFContactors), SoundFX("fx_resetdrop",DOFContactors)
    End With

    ' Left hole
    Set bsL = New cvpmTrough
    With bsL
		.size = 1
        .initSwitches Array(36)
        .Initexit sw36, 0, 2
        .InitExitSounds SoundFX("fx_Solenoid",DOFContactors), SoundFX("fx_popper",DOFContactors)
        .InitExitVariance 3, 2
    End With

    ' Right hole
    Set bsR = New cvpmTrough
    With bsR
        .size = 4
        .initSwitches Array(37)
        .Initexit sw37c, 201, 28
        .InitExitSounds SoundFX("fx_Solenoid",DOFContactors), SoundFX("fx_popper",DOFContactors)
        .InitExitVariance 2, 2
        .MaxBallsPerKick = 1
    End With

    '3 Targets Bank
    Set Mech3Bank = new cvpmMech
    With Mech3Bank
        .Sol1 = 24
        .Mtype = vpmMechLinear + vpmMechReverse + vpmMechOneSol
        .Length = 60
        .Steps = 50
        .AddSw 67, 0, 0
        .AddSw 66, 50, 50
        .Callback = GetRef("Update3Bank")
        .Start
    End With

    ' Impulse Plunger
    Const IMPowerSetting = 42 'Plunger Power
    Const IMTime = 0.6        ' Time in seconds for Full Plunge
    Set plungerIM = New cvpmImpulseP
    With plungerIM
        .InitImpulseP swplunger, IMPowerSetting, IMTime
        .Random 0.6
        .switch 18
        .InitExitSnd SoundFX("fx_plunger",DOFContactors), SoundFX("fx_plunger",DOFContactors)
        .CreateEvents "plungerIM"
    End With

    ' Main Timer init
    PinMAMETimer.Interval = PinMAMEInterval
    PinMAMETimer.Enabled = 1

    ' Init other dropwalls - animations
    UpdateGI 0, 0:UpdateGI 1, 0:UpdateGI 2, 0
    UFORotSpeedSlow
    UfoLed.Enabled = 1

    RealTime.Enabled = 1
    RotateUFO.Enabled = 1

	'Load LUT
	LoadLUT
End Sub

'**********
' Keys
'**********

Sub table1_KeyDown(ByVal Keycode)
    If keycode = PlungerKey Then Controller.Switch(11) = 1
    If keycode = LeftTiltKey Then Nudge 90, 6:PlaySound SoundFX("fx_nudge",0), 0, 1, -0.1, 0.25:aSaucerShake:a3BankShake2
    If keycode = RightTiltKey Then Nudge 270, 6:PlaySound SoundFX("fx_nudge",0), 0, 1, 0.1, 0.25:aSaucerShake:a3BankShake2
    If keycode = CenterTiltKey Then Nudge 0, 6:PlaySound SoundFX("fx_nudge",0), 0, 1, 0, 0.25:aSaucerShake:a3BankShake2
    If keycode = LeftMagnaSave Then bLutActive = True: SetLUTLine "Color LUT image " & table1.ColorGradeImage
    If keycode = RightMagnaSave AND bLutActive Then NextLUT:End If
    If vpmKeyDown(keycode) Then Exit Sub
End Sub

Sub table1_KeyUp(ByVal Keycode)
    If keycode = LeftMagnaSave Then bLutActive = False: HideLUT
    If keycode = PlungerKey Then Controller.Switch(11) = 0
    If vpmKeyUp(keycode) Then Exit Sub
End Sub

'************************************
'       LUT - Darkness control
' 10 normal level & 10 warmer levels 
'************************************

Dim bLutActive, LUTImage

Sub LoadLUT
    bLutActive = False
    x = LoadValue(cGameName, "LUTImage")
    If(x <> "")Then LUTImage = x Else LUTImage = 0
    UpdateLUT
End Sub

Sub SaveLUT
    SaveValue cGameName, "LUTImage", LUTImage
End Sub

Sub NextLUT:LUTImage = (LUTImage + 1)MOD 22:UpdateLUT:SaveLUT:SetLUTLine "Color LUT image " & table1.ColorGradeImage:End Sub

Sub UpdateLUT
    Select Case LutImage
        Case 0:table1.ColorGradeImage = "LUT0"
        Case 1:table1.ColorGradeImage = "LUT1"
        Case 2:table1.ColorGradeImage = "LUT2"
        Case 3:table1.ColorGradeImage = "LUT3"
        Case 4:table1.ColorGradeImage = "LUT4"
        Case 5:table1.ColorGradeImage = "LUT5"
        Case 6:table1.ColorGradeImage = "LUT6"
        Case 7:table1.ColorGradeImage = "LUT7"
        Case 8:table1.ColorGradeImage = "LUT8"
        Case 9:table1.ColorGradeImage = "LUT9"
        Case 10:table1.ColorGradeImage = "LUT10"
        Case 11:table1.ColorGradeImage = "LUT Warm 0"
        Case 12:table1.ColorGradeImage = "LUT Warm 1"
        Case 13:table1.ColorGradeImage = "LUT Warm 2"
        Case 14:table1.ColorGradeImage = "LUT Warm 3"
        Case 15:table1.ColorGradeImage = "LUT Warm 4"
        Case 16:table1.ColorGradeImage = "LUT Warm 5"
        Case 17:table1.ColorGradeImage = "LUT Warm 6"
        Case 18:table1.ColorGradeImage = "LUT Warm 7"
        Case 19:table1.ColorGradeImage = "LUT Warm 8"
        Case 20:table1.ColorGradeImage = "LUT Warm 9"
        Case 21:table1.ColorGradeImage = "LUT Warm 10"
    End Select
End Sub

Dim GiIntensity
GiIntensity = 1   'can be used by the LUT changing to increase the GI lights when the table is darker

Sub ChangeGiIntensity(factor) 'changes the intensity scale
    Dim bulb
    For each bulb in aGiLights
        bulb.IntensityScale = GiIntensity * factor
    Next
End Sub

' New LUT postit
Function GetHSChar(String, Index)
    Dim ThisChar
    Dim FileName
    ThisChar = Mid(String, Index, 1)
    FileName = "PostIt"
    If ThisChar = " " or ThisChar = "" then
        FileName = FileName & "BL"
    ElseIf ThisChar = "<" then
        FileName = FileName & "LT"
    ElseIf ThisChar = "_" then
        FileName = FileName & "SP"
    Else
        FileName = FileName & ThisChar
    End If
    GetHSChar = FileName
End Function

Sub SetLUTLine(String)
    Dim Index
    Dim xFor
    Index = 1
    LUBack.imagea="PostItNote"
    For xFor = 1 to 40
        Eval("LU" &xFor).imageA = GetHSChar(String, Index)
        Index = Index + 1
    Next
End Sub

Sub HideLUT
SetLUTLine ""
LUBack.imagea="PostitBL"
End Sub


'*********
' Switches
'*********

' Slings & div switches

Dim LStep, RStep

Sub LeftSlingShot_Slingshot
    PlaySoundAt SoundFX("fx_Slingshot", DOFContactors), Lemk
    LeftSling4.Visible = 1
    Lemk.RotX = 26
    LStep = 0
    vpmTimer.PulseSw 51
    LeftSlingShot.TimerEnabled = 1
End Sub

Sub LeftSlingShot_Timer
    Select Case LStep
        Case 1:LeftSLing4.Visible = 0:LeftSLing3.Visible = 1:Lemk.RotX = 14
        Case 2:LeftSLing3.Visible = 0:LeftSLing2.Visible = 1:Lemk.RotX = 2
        Case 3:LeftSLing2.Visible = 0:Lemk.RotX = -10:LeftSlingShot.TimerEnabled = 0
    End Select

    LStep = LStep + 1
End Sub

Sub RightSlingShot_Slingshot
    PlaySoundAt SoundFX("fx_Slingshot", DOFContactors), Remk
    RightSling4.Visible = 1
    Remk.RotX = 26
    RStep = 0
    vpmTimer.PulseSw 52
    RightSlingShot.TimerEnabled = 1
End Sub

Sub RightSlingShot_Timer
    Select Case RStep
        Case 1:RightSLing4.Visible = 0:RightSLing3.Visible = 1:Remk.RotX = 14
        Case 2:RightSLing3.Visible = 0:RightSLing2.Visible = 1:Remk.RotX = 2
        Case 3:RightSLing2.Visible = 0:Remk.RotX = -10:RightSlingShot.TimerEnabled = 0
    End Select

    RStep = RStep + 1
End Sub

' Bumpers
Sub Bumper1_Hit:vpmTimer.PulseSw 53:PlaySoundAt SoundFX("fx_bumper",DOFContactors),Bumper1:End Sub

Sub Bumper2_Hit:vpmTimer.PulseSw 54:PlaySoundAt SoundFX("fx_bumper", DOFContactors), Bumper2:End Sub

Sub Bumper3_Hit:vpmTimer.PulseSw 55:PlaySoundAt SoundFX("fx_bumper", DOFContactors), Bumper3:End Sub

' Drain holes, vuks & saucers
Sub Drain_Hit:PlaysoundAt "fx_drain", drain:bsTrough.AddBall Me:End Sub
Sub sw36a_Hit:PlaySoundAt "fx_kicker_enter", sw36a:bsL.AddBall Me:End Sub
Sub sw37a_Hit:PlaySoundAt "fx_hole_enter", sw37a:bsR.AddBall Me:End Sub
Sub sw78_Hit:vpmTimer.PulseSw 78:PlaySoundAt "fx_hole_enter", sw78:bsL.AddBall Me:End Sub
Sub sw37_Hit:PlaySoundAt "fx_hole_enter", sw37:bsR.AddBall Me:End Sub

' Rollovers & Ramp Switches
Sub sw16_Hit:Controller.Switch(16) = 1:PlaySoundAt "fx_sensor", sw16:End Sub
Sub sw16_UnHit:Controller.Switch(16) = 0:End Sub

Sub sw26_Hit:Controller.Switch(26) = 1:PlaySoundAt "fx_sensor", sw26:End Sub
Sub sw26_UnHit:Controller.Switch(26) = 0:End Sub

Sub sw17_Hit:Controller.Switch(17) = 1:PlaySoundAt "fx_sensor", sw17:End Sub
Sub sw17_UnHit:Controller.Switch(17) = 0:End Sub

Sub sw27_Hit:Controller.Switch(27) = 1:PlaySoundAt "fx_sensor", sw27:End Sub
Sub sw27_UnHit:Controller.Switch(27) = 0:End Sub

Sub sw38_Hit:Controller.Switch(38) = 1:PlaySoundAt "fx_sensor", sw38:End Sub
Sub sw38_Unhit:Controller.Switch(38) = 0:End Sub

Sub sw48_Hit:Controller.Switch(48) = 1:PlaySoundAt "fx_sensor", sw48:End Sub
Sub sw48_Unhit:Controller.Switch(48) = 0:End Sub

Sub sw71_Hit:Controller.Switch(71) = 1:PlaySoundAt "fx_sensor", sw71:End Sub
Sub sw71_UnHit:Controller.Switch(71) = 0:End Sub

Sub sw72_Hit:Controller.Switch(72) = 1:PlaySoundAt "fx_sensor", sw72:End Sub
Sub sw72_Unhit:Controller.Switch(72) = 0:End Sub

Sub sw73_Hit:Controller.Switch(73) = 1:PlaySoundAt "fx_sensor", sw73:End Sub
Sub sw73_Unhit:Controller.Switch(73) = 0:End Sub

Sub sw74_Hit:Controller.Switch(74) = 1:PlaySoundAt "fx_sensor", sw74:End Sub
Sub sw74_Unhit:Controller.Switch(74) = 0:End Sub

Sub sw61_Hit:Controller.Switch(61) = 1:End Sub
Sub sw61_Unhit:Controller.Switch(61) = 0:End Sub

Sub sw62_Hit:Controller.Switch(62) = 1:End Sub
Sub sw62_Unhit:Controller.Switch(62) = 0:End Sub

Sub sw63_Hit:Controller.Switch(63) = 1:End Sub
Sub sw63_Unhit:Controller.Switch(63) = 0:End Sub

Sub sw64_Hit:Controller.Switch(64) = 1:End Sub
Sub sw64_Unhit:Controller.Switch(64) = 0:End Sub

Sub sw65_Hit:Controller.Switch(65) = 1:End Sub
Sub sw65_Unhit:Controller.Switch(65) = 0:End Sub

Sub sw65a_Hit:Controller.Switch(65) = 1:End Sub
Sub sw65a_Unhit:Controller.Switch(65) = 0:End Sub


' Targets
Sub sw56_Hit:vpmTimer.PulseSw 56:PlaySoundAtBall SoundFX("fx_target", DOFTargets):End Sub
Sub sw57_Hit:vpmTimer.PulseSw 57:PlaySoundAtBall SoundFX("fx_target", DOFTargets):End Sub
Sub sw58_Hit:vpmTimer.PulseSw 58:PlaySoundAtBall SoundFX("fx_target", DOFTargets):End Sub
Sub sw41_Hit:vpmTimer.PulseSw 41:PlaySoundAtBall SoundFX("fx_target", DOFTargets):End Sub
Sub sw42_Hit:vpmTimer.PulseSw 42:PlaySoundAtBall SoundFX("fx_target", DOFTargets):End Sub
Sub sw43_Hit:vpmTimer.PulseSw 43:PlaySoundAtBall SoundFX("fx_target", DOFTargets):End Sub
Sub sw44_Hit:vpmTimer.PulseSw 44:PlaySoundAtBall SoundFX("fx_target", DOFTargets):End Sub
Sub sw75_Hit:vpmTimer.PulseSw 75:PlaySoundAtBall SoundFX("fx_target", DOFTargets):End Sub
Sub sw76_Hit:vpmTimer.PulseSw 76:PlaySoundAtBall SoundFX("fx_target", DOFTargets):End Sub

' 3 bank
Sub sw45_Hit:vpmTimer.PulseSw 45:a3BankShake:PlaySoundAtBall SoundFX("fx_target", DOFTargets):End Sub
Sub sw46_Hit:vpmTimer.PulseSw 46:a3BankShake:PlaySoundAtBall SoundFX("fx_target", DOFTargets):End Sub
Sub sw47_Hit:vpmTimer.PulseSw 47:a3BankShake:PlaySoundAtBall SoundFX("fx_target", DOFTargets):End Sub

' Droptarget

Sub sw77_Hit:PlaySoundAt SoundFX("fx_droptarget", DOFDropTargets), sw77:dtDrop.Hit 1:UFORotSpeedFast:End Sub

'*********
'Solenoids
'*********

SolCallback(1) = "Auto_Plunger"
SolCallback(2) = "SolRelease"
SolCallback(3) = "bsL.SolOut"
SolCallback(4) = "bsR.SolOut"
SolCallback(5) = "SolAlien5"
SolCallback(6) = "SolAlien6"
SolCallback(7) = "vpmSolSound SoundFX(""fx_Knocker"",DOFKnocker),"
SolCallback(8) = "SolAlien8"
SolCallback(14) = "SolAlien14"
SolCallBack(15) = "SolUfoShake"
SolCallback(16) = "SolDropTargetUp"
'SolCallback(24) = "SolBank" 'used in the Mech
SolCallback(34) = "vpmSolGate RGate,false,"
SolCallback(33) = "vpmSolGate LGate,false,"
SolCallback(36) = "vpmSolDiverter Diverter, SoundFX(""diverter"",DOFContactor),"
SolCallback(43) = "setlamp 130,"

If UseVPMModSol Then
SolModCallback(17) = "SetModLamp 117,"
SolModCallback(18) = "SetModLamp 118,"
SolModCallback(19) = "SetModLamp 119,"
SolModCallback(20) = "SetModLamp 120,"
SolModCallback(21) = "SetModLamp 121,"
SolModCallback(22) = "SetModLamp 122,"
SolModCallback(23) = "SetModLamp 123,"
SolModCallback(25) = "SetModLamp 125,"
SolModCallback(26) = "SetModLamp 126,"
SolModCallback(27) = "SetModLamp 127,"
SolModCallback(28) = "SetModLamp 128,"
Else
SolCallback(17) = "SetLamp 117,"
SolCallback(18) = "SetLamp 118,"
SolCallback(19) = "SetLamp 119,"
SolCallback(20) = "SetLamp 120,"
SolCallback(21) = "SetLamp 121,"
SolCallback(22) = "SetLamp 122,"
SolCallback(23) = "SetLamp 123,"
SolCallback(25) = "SetLamp 125,"
SolCallback(26) = "SetLamp 126,"
SolCallback(27) = "SetLamp 127,"
SolCallback(28) = "SetLamp 128,"
End If

Sub SolRelease(Enabled)
    If Enabled And bsTrough.Balls > 0 Then
        vpmTimer.PulseSw 31
        bsTrough.ExitSol_On
    End If
End Sub

Sub Auto_Plunger(Enabled)
    If Enabled Then
        PlungerIM.AutoFire
    End If
End Sub

Sub SolDropTargetUp(Enabled)
    If Enabled Then
        dtDrop.DropSol_On
    End If
End Sub

'****************
' Alien solenoids
'****************

Sub SolAlien5(Enabled)
    If Enabled Then
        Alien5.TransZ = 20
    PlaySoundAt "fx_gion", Alien5
    Else
        Alien5.TransZ = 0
    PlaySoundAt "fx_gioff", Alien5
    End If
End Sub

Sub SolAlien6(Enabled)
    If Enabled Then
        Alien6.TransZ = 20
    PlaySoundAt "fx_gion", Alien6
    Else
        Alien6.TransZ = 0
    PlaySoundAt "fx_gioff", Alien6
    End If
End Sub

Sub SolAlien8(Enabled)
    If Enabled Then
        Alien8.TransZ = 20
    PlaySoundAt "fx_gion", Alien8
    Else
        Alien8.TransZ = 0
    PlaySoundAt "fx_gioff", Alien8
    End If
End Sub

Sub SolAlien14(Enabled)
    If Enabled Then
        Alien14.TransZ = 20
    PlaySoundAt "fx_gion", Alien14
    Else
        Alien14.TransZ = 0
    PlaySoundAt "fx_gioff", Alien14
    End If
End Sub

'*******************
' Flipper Subs Rev3
'*******************

SolCallback(sLRFlipper) = "SolRFlipper"
SolCallback(sLLFlipper) = "SolLFlipper"

Sub SolLFlipper(Enabled)
    If UseSolenoids = 2 then Controller.Switch(swULFlip) = Enabled
    If Enabled Then
        PlaySoundAt SoundFX("fx_flipperup", DOFContactors), LeftFlipper
        LeftFlipper.RotateToEnd
        LeftFlipperOn = 1
    Else
        PlaySoundAt SoundFX("fx_flipperdown", DOFContactors), LeftFlipper
        LeftFlipper.RotateToStart
        LeftFlipperOn = 0
    End If
End Sub

Sub SolRFlipper(Enabled)
    if UseSolenoids = 2 then Controller.Switch(swURFlip) = Enabled
    If Enabled Then
        PlaySoundAt SoundFX("fx_flipperup", DOFContactors), RightFlipper
        RightFlipper.RotateToEnd
        RightFlipperOn = 1
    Else
        PlaySoundAt SoundFX("fx_flipperdown", DOFContactors), RightFlipper
        RightFlipper.RotateToStart
        RightFlipperOn = 0
    End If
End Sub

' flippers top animations

Sub LeftFlipper_Animate:LeftFlipperTop.RotZ = LeftFlipper.CurrentAngle: End Sub
Sub RightFlipper_Animate: RightFlipperTop.RotZ = RightFlipper.CurrentAngle: End Sub

Sub LeftFlipper_Collide(parm)
    PlaySound "fx_rubber_flipper", 0, parm / 60, pan(ActiveBall), 0.1, 0, 0, 0, AudioFade(ActiveBall)
End Sub

Sub RightFlipper_Collide(parm)
    PlaySound "fx_rubber_flipper", 0, parm / 60, pan(ActiveBall), 0.1, 0, 0, 0, AudioFade(ActiveBall)
End Sub


'*********************************************************
' Real Time Flipper adjustments - by JLouLouLou & JPSalas
'        (to enable flipper tricks) 
'*********************************************************

Dim FlipperPower
Dim FlipperElasticity
Dim SOSTorque, SOSAngle
Dim FullStrokeEOS_Torque, LiveStrokeEOS_Torque
Dim LeftFlipperOn
Dim RightFlipperOn

Dim LLiveCatchTimer
Dim RLiveCatchTimer
Dim LiveCatchSensivity

FlipperPower = 5000
FlipperElasticity = 0.8
FullStrokeEOS_Torque = 0.3 	' EOS Torque when flipper hold up ( EOS Coil is fully charged. Ampere increase due to flipper can't move or when it pushed back when "On". EOS Coil have more power )
LiveStrokeEOS_Torque = 0.2	' EOS Torque when flipper rotate to end ( When flipper move, EOS coil have less Ampere due to flipper can freely move. EOS Coil have less power )

LeftFlipper.EOSTorqueAngle = 10
RightFlipper.EOSTorqueAngle = 10

SOSTorque = 0.1
SOSAngle = 6

LiveCatchSensivity = 10

LLiveCatchTimer = 0
RLiveCatchTimer = 0

LeftFlipper.TimerInterval = 1
LeftFlipper.TimerEnabled = 1

Sub LeftFlipper_Timer 'flipper's tricks timer
'Start Of Stroke Flipper Stroke Routine : Start of Stroke for Tap pass and Tap shoot
    If LeftFlipper.CurrentAngle >= LeftFlipper.StartAngle - SOSAngle Then LeftFlipper.Strength = FlipperPower * SOSTorque else LeftFlipper.Strength = FlipperPower : End If
 
'End Of Stroke Routine : Livecatch and Emply/Full-Charged EOS
	If LeftFlipperOn = 1 Then
		If LeftFlipper.CurrentAngle = LeftFlipper.EndAngle then
			LeftFlipper.EOSTorque = FullStrokeEOS_Torque
			LLiveCatchTimer = LLiveCatchTimer + 1
			If LLiveCatchTimer < LiveCatchSensivity Then
				LeftFlipper.Elasticity = 0
			Else
				LeftFlipper.Elasticity = FlipperElasticity
				LLiveCatchTimer = LiveCatchSensivity
			End If
		End If
	Else
		LeftFlipper.Elasticity = FlipperElasticity
		LeftFlipper.EOSTorque = LiveStrokeEOS_Torque
		LLiveCatchTimer = 0
	End If
	

'Start Of Stroke Flipper Stroke Routine : Start of Stroke for Tap pass and Tap shoot
    If RightFlipper.CurrentAngle <= RightFlipper.StartAngle + SOSAngle Then RightFlipper.Strength = FlipperPower * SOSTorque else RightFlipper.Strength = FlipperPower : End If
 
'End Of Stroke Routine : Livecatch and Emply/Full-Charged EOS
 	If RightFlipperOn = 1 Then
		If RightFlipper.CurrentAngle = RightFlipper.EndAngle Then
			RightFlipper.EOSTorque = FullStrokeEOS_Torque
			RLiveCatchTimer = RLiveCatchTimer + 1
			If RLiveCatchTimer < LiveCatchSensivity Then
				RightFlipper.Elasticity = 0
			Else
				RightFlipper.Elasticity = FlipperElasticity
				RLiveCatchTimer = LiveCatchSensivity
			End If
		End If
	Else
		RightFlipper.Elasticity = FlipperElasticity
		RightFlipper.EOSTorque = LiveStrokeEOS_Torque
		RLiveCatchTimer = 0
	End If
End Sub

'******************
'Motor Bank Up Down
'******************

Sub Update3Bank(currpos, currspeed, lastpos)
    If currpos <> lastpos Then
		PlaySound "fx_motor"
        BackBank.Z = 25 - currpos
        swp45.Z = -(22 + currpos)
        swp46.Z = -(22 + currpos)
        swp47.Z = -(22 + currpos)
    End If
    If currpos > 40 Then
        sw45.Isdropped = 1
        sw46.Isdropped = 1
        sw47.Isdropped = 1
        UFORotSpeedMedium
    End If
    If currpos < 10 Then
        sw45.Isdropped = 0
        sw46.Isdropped = 0
        sw47.Isdropped = 0
        UFORotSpeedSlow
    End If
End Sub

'***********
' Update GI
'***********

Sub UpdateGI2(no, step)
    Dim gistep, ii, a
    gistep = step / 8
    Select Case no
        Case 0
            For each ii in aGiLLights
                ii.IntensityScale = gistep
            Next
        Case 1
            For each ii in aGiMLights
                ii.IntensityScale = gistep
            Next
        Case 2 ' also the bumpers er GI
            For each ii in aGiTLights
                ii.IntensityScale = gistep
            Next
    End Select
End Sub

Sub UpdateGI(no, step)
    Dim gistep, ii, a
    gistep = ABS(step)
    Select Case no
        Case 0
            For each ii in aGiLLights
                ii.state = gistep
            Next
        Case 1
            For each ii in aGiMLights
                ii.state = gistep
            Next
        Case 2 ' also the bumpers er GI
            For each ii in aGiTLights
                ii.state = gistep
            Next
    End Select
End Sub

'*************
' 3Bank Shake
'*************

Dim ccBall
Const cMod = .65 'percentage of hit power transfered to the 3 Bank of targets

a3BankInit

Sub a3BankShake
    ccball.velx = activeball.velx * cMod
    ccball.vely = activeball.vely * cMod
    a3BankTimer.enabled = True
    b3BankTimer.enabled = True
End Sub

Sub a3BankShake2 'when nudging
    a3BankTimer.enabled = True
    b3BankTimer.enabled = True
End Sub

Sub a3BankInit
    Set ccBall = hball.createball
    hball.Kick 0, 0
    ccball.Mass = 1.6
End Sub

Sub a3BankTimer_Timer            'start animation
    Dim x, y
    x = (hball.x - ccball.x) / 4 'reduce the X axis movement
    y = (hball.y - ccball.y) / 2
    backbank.transy = x
    backbank.transx = - y
    swp45.transy = x
    swp45.transx = - y
    swp46.transy = x
    swp46.transx = - y
    swp47.transy = x
    swp47.transx = - y
End Sub

Sub b3BankTimer_Timer 'stop animation
    backbank.transx = 0
    backbank.transy = 0
    swp45.transz = 0
    swp45.transx = 0
    swp46.transz = 0
    swp46.transx = 0
    swp47.transz = 0
    swp47.transx = 0
    a3BankTimer.enabled = False
    b3BankTimer.enabled = False
End Sub

'***************
' Big UFO Shake
'***************
Dim cBall, UFOLedPos
BigUfoInit

Sub BigUfoInit
    UFOLedPos = 0
    Set cBall = ckicker.createball
    ckicker.Kick 0, 0
End Sub

Sub SolUfoShake(Enabled)
    If Enabled Then
        BigUfoShake
    End If
End Sub

Sub BigUfoShake
    cball.velx = 10 + 2 * RND(1)
    cball.vely = 2 * (RND(1) - RND(1) )
End Sub

Sub UFOLed_Timer()
    Select Case UfoLedPos
        Case 0:ufo1.image = "bigufo1":UfoLedPos = 1
        Case 1:ufo1.image = "bigufo2":UfoLedPos = 2
        Case 2:ufo1.image = "bigufo3":UfoLedPos = 0
    End Select
End Sub

Sub BigUfoUpdate
    Dim a, b, c
    a = (ckicker.y - cball.y)
    b = (ckicker.y - cball.y) / 2
    c = cball.x - ckicker.x

    Ufo1.rotx = a
    Ufo1d.rotx = a
    Ufo1.transx = b
    Ufo1d.transx = b
    Ufo1.roty = c
    Ufo1d.roty = c
End Sub

'**********************************
' Small and Big UFOs Rotation Speed
'**********************************

Sub UFORotSpeedSlow()
    UfoLed.Interval = 600
    RotateUFO.Interval = 300
End Sub

Sub UFORotSpeedMedium()
    UfoLed.Interval = 300
    RotateUFO.Interval = 150
End Sub

Sub UFORotSpeedFast()
    UfoLed.Interval = 150
    RotateUFO.Interval = 75
End Sub

Dim UFOSmallPos
UFOSmallPos = 0

Sub RotateUFO_Timer()
If bRotateSaucers Then
    Ufo2.RotZ = (Ufo2.RotZ - 1) MOD 360
    Ufo4.RotZ = (Ufo4.RotZ - 1) MOD 360
    Ufo5.RotZ = (Ufo5.RotZ - 1) MOD 360
    Ufo6.RotZ = (Ufo6.RotZ - 1) MOD 360
    Ufo7.RotZ = (Ufo7.RotZ - 1) MOD 360
    Ufo8.RotZ = (Ufo8.RotZ - 1) MOD 360
End If
If bRotateBigUFO Then
    Ufo1.RotZ = (Ufo1.RotZ - 1) MOD 360
    Ufo1d.RotZ = Ufo1.RotZ
End If
    Select Case UFOSmallPos
        Case 0:ufo2.image = "saucer1":ufo4.image = "saucer4":ufo5.image = "saucer5":ufo6.image = "saucer6":ufo7.image = "saucer7":ufo8.image = "saucer8":UFOSmallPos = 1
        Case 1:ufo2.image = "saucer2":ufo4.image = "saucer5":ufo5.image = "saucer6":ufo6.image = "saucer7":ufo7.image = "saucer8":ufo8.image = "saucer1":UFOSmallPos = 2
        Case 2:ufo2.image = "saucer3":ufo4.image = "saucer6":ufo5.image = "saucer7":ufo6.image = "saucer8":ufo7.image = "saucer1":ufo8.image = "saucer2":UFOSmallPos = 3
        Case 3:ufo2.image = "saucer4":ufo4.image = "saucer7":ufo5.image = "saucer8":ufo6.image = "saucer1":ufo7.image = "saucer2":ufo8.image = "saucer3":UFOSmallPos = 4
        Case 4:ufo2.image = "saucer5":ufo4.image = "saucer8":ufo5.image = "saucer1":ufo6.image = "saucer2":ufo7.image = "saucer3":ufo8.image = "saucer4":UFOSmallPos = 5
        Case 5:ufo2.image = "saucer6":ufo4.image = "saucer1":ufo5.image = "saucer2":ufo6.image = "saucer3":ufo7.image = "saucer4":ufo8.image = "saucer5":UFOSmallPos = 6
        Case 6:ufo2.image = "saucer7":ufo4.image = "saucer2":ufo5.image = "saucer3":ufo6.image = "saucer4":ufo7.image = "saucer5":ufo8.image = "saucer6":UFOSmallPos = 7
        Case 7:ufo2.image = "saucer8":ufo4.image = "saucer3":ufo5.image = "saucer4":ufo6.image = "saucer5":ufo7.image = "saucer6":ufo8.image = "saucer7":UFOSmallPos = 0
    End Select
End Sub

'**********************************************************
' Small shake of small Ufos and other objects when nudging
'**********************************************************

Dim SmallShake:SmallShake = 0

Sub aSaucerShake
    SmallShake = 6
    SaucerShake.Enabled = True
End Sub

Sub SaucerShake_Timer
    ufo2.Roty = SmallShake
    ufo2a.Roty = SmallShake
    ufo7.Roty = SmallShake
    ufo7a.Roty = SmallShake
    ufo8.Roty = SmallShake
    ufo8a.Roty = SmallShake
    ufo6.Roty = SmallShake
    ufo6a.Roty = SmallShake
    ufo5.Roty = SmallShake
    ufo5a.Roty = SmallShake
    ufo4.Roty = SmallShake
    ufo4a.Roty = SmallShake
    alien5.Transz = SmallShake / 2
    alien6.Transz = SmallShake / 2
    alien8.Transz = SmallShake / 2
    alien14.Transz = SmallShake / 2
    If SmallShake = 0 Then SaucerShake.Enabled = False:Exit Sub
    If SmallShake < 0 Then
        SmallShake = ABS(SmallShake) - 0.1
    Else
        SmallShake = - SmallShake + 0.1
    End If
End Sub

'**********************************************************
'     JP's Lamp Fading for VPX and Vpinmame v4.0
' FadingStep used for all kind of lamps
' FlashLevel used for modulated flashers
'**********************************************************

Dim FadingStep(200), FlashLevel(200)

InitLamps() ' turn off the lights and flashers and reset them to the default parameters

' vpinmame Lamp & Flasher Timers

Sub LampTimer_Timer()
    Dim chgLamp, num, chg, ii
    chgLamp = Controller.ChangedLamps
    If Not IsEmpty(chgLamp)Then
        For ii = 0 To UBound(chgLamp)
            FadingStep(chgLamp(ii, 0)) = chgLamp(ii, 1)
        Next
    End If
    UpdateLamps
End Sub

Sub UpdateLamps
    Lamp 11, l11
    Lamp 12, l12
    Lamp 13, l13
    Lamp 14, l14
    Lampm 15, l15a
    Lampm 15, l15b
    Lamp 15, l15
    Lamp 16, l16
    Lamp 17, l17
    Lampm 18, l18a
    Lamp 18, l18
    Lamp 21, l21
    Lamp 22, l22
    Lamp 23, l23
    Lamp 24, l24
    Lamp 25, l25
    Lamp 26, l26
    Lamp 27, l27
    Lampm 28, l28a
    Lamp 28, l28
    Lamp 31, l31
    Lamp 32, l32
    Lamp 33, l33
    Lamp 34, l34
    Lamp 35, l35
    Lamp 36, l36
    Lamp 37, l37
    Lamp 38, l38
    Lamp 41, l41
    Lamp 42, l42
    Lamp 43, l43
    Lamp 44, l44
    Lampm 45, l45a
    Lamp 45, l45
    Lampm 46, l46a
    Lamp 46, l46
    Lampm 47, l47a
    Lamp 47, l47
    Lamp 48, l48
    Lamp 51, l51
    Lamp 52, l52
    Lamp 53, l53
    Lamp 54, l54
    Lamp 55, l55
    Lamp 56, l56
    Lamp 57, l57
    Lamp 58, l58
    Lamp 61, l61
    Lamp 62, l62
    Lamp 63, l63
    Lamp 64, l64
    Lamp 65, l65
    Lamp 66, l66
    Lamp 67, l67
    Lamp 68, l68
    Lamp 71, l71
    Lamp 72, l72
    Lamp 73, l73
    Lamp 74, l74
    Lamp 75, l75
    Lamp 76, l76
    Lamp 77, l77
    Lamp 78, l78
    Lamp 81, l81
    Lamp 82, l82
    Lamp 83, l83
    Lamp 84, l84
    Lamp 85, l85
    Lamp 86, l86
    Lamp 88, l88
    ' ufo red lights
    Lamp 91, l91
    Lamp 92, l92
    'Lamp 93, l93
    Lamp 94, l94
    Lamp 95, l95
    Lamp 96, l96
    Lamp 97, l97
    Lamp 98, l98
    Lamp 101, l101
    Lamp 102, l102
    Lamp 103, l103
    Lamp 104, l104
    'Lamp 105, l105
    'Lamp 106, l106
    'Lamp 107, l107
    'Lamp 108, l108
    'flashers
    Flashm 123, F23big
    Lampm 123, f23
    Lamp 123, f23a
    Flash 130, Strobe
If UseVPMModSol Then
    LampMod 117, f17
    FlashMod 117, f17a
    FlashMod 117, F17big
    LampMod 118, f18
    FlashMod 118, f18a
    FlashMod 118, F18big
    LampMod 119, f19
    FlashMod 119, f19a
    FlashMod 119, F19big
    LampMod 120, f20
    FlashMod 121, f21a
    LampMod 122, f22
    LampMod 123, f23
    LampMod 123, f23a
    FlashMod 123, F23big
    LampMod 125, f25
    FlashMod 125, f25a
    FlashMod 125, F25big
    LampMod 126, f26
    FlashMod 126, f26a
    FlashMod 126, F26big
    LampMod 127, f27
    FlashMod 127, f27a
    FlashMod 127, F27big
    LampMod 128, f28
Else
    Lampm 117, f17
    Flashm 117, F17big
    Flash 117, f17a
    Lampm 118, f18
    Flashm 118, F18big
    Flash 118, f18a
    Lampm 119, f19
    Flashm 119, F19big
    Flash 119, f19a
    Lamp 120, f20
    Flash 121, f21a
    Lamp 122, f22
    Lampm 123, f23a
    Lampm 123, f23
    Flash 123, F23big
    Lampm 125, f25
    Flashm 125, F25big
    Flash 125, f25a
    Lampm 126, f26
    Flashm 126, F26big
    Flash 126, f26a
    Lampm 127, f27
    Flash 127, f27a
    Lampm 128, f28
End If
End Sub

' div lamp subs

' Normal Lamp & Flasher subs

Sub InitLamps()
    Dim x
    LampTimer.Interval = 10
    LampTimer.Enabled = 1
    For x = 0 to 200
        FadingStep(x) = 0
        FlashLevel(x) = 0
    Next
End Sub

Sub SetLamp(nr, value) ' 0 is off, 1 is on
    FadingStep(nr) = abs(value)
End Sub

' Lights: used for VPX standard lights, the fading is handled by VPX itself, they are here to be able to make them work together with the flashers

Sub Lamp(nr, object)
    Select Case FadingStep(nr)
        Case 1:object.state = 1:FadingStep(nr) = -1
        Case 0:object.state = 0:FadingStep(nr) = -1
    End Select
End Sub

Sub Lampm(nr, object) ' used for multiple lights, it doesn't change the fading state
    Select Case FadingStep(nr)
        Case 1:object.state = 1
        Case 0:object.state = 0
    End Select
End Sub

' Flashers:  0 starts the fading until it is off

Sub Flash(nr, object)
    Dim tmp
    Select Case FadingStep(nr)
        Case 1:Object.IntensityScale = 1:FadingStep(nr) = -1
        Case 0
            tmp = Object.IntensityScale * 0.85 - 0.01
            If tmp > 0 Then
                Object.IntensityScale = tmp
            Else
                Object.IntensityScale = 0
                FadingStep(nr) = -1
            End If
    End Select
End Sub

Sub Flashm(nr, object) 'multiple flashers, it doesn't change the fading state
    Dim tmp
    Select Case FadingStep(nr)
        Case 1:Object.IntensityScale = 1
        Case 0
            tmp = Object.IntensityScale * 0.85 - 0.01
            If tmp > 0 Then
                Object.IntensityScale = tmp
            Else
                Object.IntensityScale = 0
            End If
    End Select
End Sub

' Desktop Objects: Reels & texts

' Reels - 4 steps fading
Sub Reel(nr, object)
    Select Case FadingStep(nr)
        Case 1:object.SetValue 1:FadingStep(nr) = -1
        Case 0:object.SetValue 2:FadingStep(nr) = 2
        Case 2:object.SetValue 3:FadingStep(nr) = 3
        Case 3:object.SetValue 0:FadingStep(nr) = -1
    End Select
End Sub

Sub Reelm(nr, object)
    Select Case FadingStep(nr)
        Case 1:object.SetValue 1
        Case 0:object.SetValue 2
        Case 2:object.SetValue 3
        Case 3:object.SetValue 0
    End Select
End Sub

' Reels non fading
Sub NfReel(nr, object)
    Select Case FadingStep(nr)
        Case 1:object.SetValue 1:FadingStep(nr) = -1
        Case 0:object.SetValue 0:FadingStep(nr) = -1
    End Select
End Sub

Sub NfReelm(nr, object)
    Select Case FadingStep(nr)
        Case 1:object.SetValue 1
        Case 0:object.SetValue 0
    End Select
End Sub

'Texts

Sub Text(nr, object, message)
    Select Case FadingStep(nr)
        Case 1:object.Text = message:FadingStep(nr) = -1
        Case 0:object.Text = "":FadingStep(nr) = -1
    End Select
End Sub

Sub Textm(nr, object, message)
    Select Case FadingStep(nr)
        Case 1:object.Text = message
        Case 0:object.Text = ""
    End Select
End Sub

' Modulated Subs for the WPC tables

Sub SetModLamp(nr, level)
    FlashLevel(nr) = level / 150 'lights & flashers
End Sub

Sub LampMod(nr, object)          ' modulated lights used as flashers
    Object.IntensityScale = FlashLevel(nr)
    Object.State = 1             'in case it was off
End Sub

Sub FlashMod(nr, object)         'sets the flashlevel from the SolModCallback
    Object.IntensityScale = FlashLevel(nr)
End Sub

'Walls, flashers, ramps and Primitives used as 4 step fading images
'a,b,c,d are the images used from on to off

Sub FadeObj(nr, object, a, b, c, d)
    Select Case FadingStep(nr)
        Case 1:object.image = a:FadingStep(nr) = -1
        Case 0:object.image = b:FadingStep(nr) = 2
        Case 2:object.image = c:FadingStep(nr) = 3
        Case 3:object.image = d:FadingStep(nr) = -1
    End Select
End Sub

Sub FadeObjm(nr, object, a, b, c, d)
    Select Case FadingStep(nr)
        Case 1:object.image = a
        Case 0:object.image = b
        Case 2:object.image = c
        Case 3:object.image = d
    End Select
End Sub

Sub NFadeObj(nr, object, a, b)
    Select Case FadingStep(nr)
        Case 1:object.image = a:FadingStep(nr) = -1
        Case 0:object.image = b:FadingStep(nr) = -1
    End Select
End Sub

Sub NFadeObjm(nr, object, a, b)
    Select Case FadingStep(nr)
        Case 1:object.image = a
        Case 0:object.image = b
    End Select
End Sub

'************************************
' Diverse Collection Hit Sounds v3.0
'************************************

Sub aMetals_Hit(idx):PlaySoundAtBall "fx_MetalHit":End Sub
Sub aMetalWires_Hit(idx):PlaySoundAtBall "fx_MetalWire":End Sub
Sub aRubber_Bands_Hit(idx):PlaySoundAtBall "fx_rubber_band":End Sub
Sub aRubber_LongBands_Hit(idx):PlaySoundAtBall "fx_rubber_longband":End Sub
Sub aRubber_Posts_Hit(idx):PlaySoundAtBall "fx_rubber_post":End Sub
Sub aRubber_Pins_Hit(idx):PlaySoundAtBall "fx_rubber_pin":End Sub
Sub aRubber_Pegs_Hit(idx):PlaySoundAtBall "fx_rubber_peg":End Sub
Sub aPlastics_Hit(idx):PlaySoundAtBall "fx_PlasticHit":End Sub
Sub aGates_Hit(idx):PlaySoundAtBall "fx_Gate":End Sub
Sub aWoods_Hit(idx):PlaySoundAtBall "fx_Woodhit":End Sub

'***************************************************************
'             Supporting Ball & Sound Functions v4.0
'  includes random pitch in PlaySoundAt and PlaySoundAtBall
'***************************************************************

Dim TableWidth, TableHeight

TableWidth = Table1.width
TableHeight = Table1.height

Function Vol(ball) ' Calculates the Volume of the sound based on the ball speed
    Vol = Csng(BallVel(ball) ^2 / 2000)
End Function

Function Pan(ball) ' Calculates the pan for a ball based on the X position on the table. "table1" is the name of the table
    Dim tmp
    tmp = ball.x * 2 / TableWidth-1
    If tmp > 0 Then
        Pan = Csng(tmp ^10)
    Else
        Pan = Csng(-((- tmp) ^10))
    End If
End Function

Function Pitch(ball) ' Calculates the pitch of the sound based on the ball speed
    Pitch = BallVel(ball) * 20
End Function

Function BallVel(ball) 'Calculates the ball speed
    BallVel = (SQR((ball.VelX ^2) + (ball.VelY ^2)))
End Function

Function AudioFade(ball) 'only on VPX 10.4 and newer
    Dim tmp
    tmp = ball.y * 2 / TableHeight-1
    If tmp > 0 Then
        AudioFade = Csng(tmp ^10)
    Else
        AudioFade = Csng(-((- tmp) ^10))
    End If
End Function

Sub PlaySoundAt(soundname, tableobj) 'play sound at X and Y position of an object, mostly bumpers, flippers and other fast objects
    PlaySound soundname, 0, 1, Pan(tableobj), 0.2, 0, 0, 0, AudioFade(tableobj)
End Sub

Sub PlaySoundAtBall(soundname) ' play a sound at the ball position, like rubbers, targets, metals, plastics
    PlaySound soundname, 0, Vol(ActiveBall), pan(ActiveBall), 0.2, Pitch(ActiveBall) * 10, 0, 0, AudioFade(ActiveBall)
End Sub

Function RndNbr(n) 'returns a random number between 1 and n
    Randomize timer
    RndNbr = Int((n * Rnd) + 1)
End Function

'***********************************************
'   JP's VP10 Rolling Sounds + Ballshadow v4.0
'   uses a collection of shadows, aBallShadow
'***********************************************

Const tnob = 19   'total number of balls
Const lob = 2     'number of locked balls
Const maxvel = 42 'max ball velocity
ReDim rolling(tnob)
InitRolling

Sub InitRolling
    Dim i
    For i = 0 to tnob
        rolling(i) = False
    Next
End Sub

Sub RollingUpdate()
    Dim BOT, b, ballpitch, ballvol, speedfactorx, speedfactory
    BOT = GetBalls

    ' stop the sound of deleted balls
    For b = UBound(BOT) + 1 to tnob
        rolling(b) = False
        StopSound("fx_ballrolling" & b)
        aBallShadow(b).Y = 3000
    Next

    ' exit the sub if no balls on the table
    If UBound(BOT) = lob - 1 Then Exit Sub 'there no extra balls on this table

    ' play the rolling sound for each ball and draw the shadow
    For b = lob to UBound(BOT)
        aBallShadow(b).X = BOT(b).X
        aBallShadow(b).Y = BOT(b).Y
        aBallShadow(b).Height = BOT(b).Z -Ballsize/2

        If BallVel(BOT(b))> 1 Then
            If BOT(b).z <30 Then
                ballpitch = Pitch(BOT(b))
                ballvol = Vol(BOT(b))
            Else
                ballpitch = Pitch(BOT(b)) + 50000 'increase the pitch on a ramp
                ballvol = Vol(BOT(b)) * 5
            End If
            rolling(b) = True
            PlaySound("fx_ballrolling" & b), -1, ballvol, Pan(BOT(b)), 0, ballpitch, 1, 0, AudioFade(BOT(b))
        Else
            If rolling(b) = True Then
                StopSound("fx_ballrolling" & b)
                rolling(b) = False
            End If
        End If

        ' rothbauerw's Dropping Sounds
        If BOT(b).VelZ <-1 and BOT(b).z <55 and BOT(b).z> 27 Then 'height adjust for ball drop sounds
            PlaySound "fx_balldrop", 0, ABS(BOT(b).velz) / 17, Pan(BOT(b)), 0, Pitch(BOT(b)), 1, 0, AudioFade(BOT(b))
        End If

        ' jps ball speed & spin control
        BOT(b).AngMomZ = BOT(b).AngMomZ * 0.95
        If BOT(b).VelX AND BOT(b).VelY <> 0 Then
            speedfactorx = ABS(maxvel / BOT(b).VelX)
            speedfactory = ABS(maxvel / BOT(b).VelY)
            If speedfactorx <1 Then
                BOT(b).VelX = BOT(b).VelX * speedfactorx
                BOT(b).VelY = BOT(b).VelY * speedfactorx
            End If
            If speedfactory <1 Then
                BOT(b).VelX = BOT(b).VelX * speedfactory
                BOT(b).VelY = BOT(b).VelY * speedfactory
            End If
        End If
    Next
End Sub

'**********************
' Ball Collision Sound
'**********************

Sub OnBallBallCollision(ball1, ball2, velocity)
    PlaySound("fx_collide"), 0, Csng(velocity) ^2 / 2000, Pan(ball1), 0, Pitch(ball1), 0, 0, AudioFade(ball1)
End Sub
