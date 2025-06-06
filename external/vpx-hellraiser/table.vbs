' ***************************************************************************
'                       <<<  MAGO DE OZ  >>>
'   an original table based on the layout and rules of Stern's Iron Maiden
'
'                          VISUAL PINBALL X
'                    JPSalas original DMD Pinball Script
'              VPX script using core.vbs for supporting functions
'         and controller.vbs to load B2S server and other controllers
'                  Including JP's Arcade Physics 3.0.0
' ***************************************************************************

Option Explicit
Randomize
'*************************************TABLE OPTIONS**************************************

Const BackDrop = 0		' Red Backwall = 1  Original = 0

Const BloodRamps = 0	' Blood on the ramps = 1  No Blood = 0


Const LCDScreen = True '( DMD- LCD Screen = True, RealDMD = False )

Const PupScreen1 = 0	'(Apron Videos to see videos choose "1"(Recommended Exclusive Fullscreen on VPX editor) No videos "0") ONE Screen users Turn this option to 0

Const FPS = 0			' Slow PC Recommended "0" Fast PC  1




'******************
'Playfield Option
'******************
'1 = playfiel with pinhead girl  or 0 = playfield darker without pinhead girl
Const PinheadGirl = 1


'************************
'Glowball
'*************************
Dim GlowAura,GlowIntensity

Const ChooseBall 			= 0		' *** Ball Settings **********
									' *** 0 = Normal Ball	
									' *** 1 = Purple GlowBall
									' *** 2 = Green GlowBall																		
									' *** 3 = Blue Glowball
									' *** 4 = Orange Glowball 
									' *** 5 = Red Glowball
									' *** 6 = White Glowball
									' *** 7 = Yellow Glowball
									' *** 8 = Gold Glowball
									

'******************
'Additional Ball Settings
'******************

GlowAura=210 'GlowBlob Auroa radius
GlowIntensity=15 'Glowblob intensity




'***********************************************************************************************************************************




'************************************END OF TABLE OPTIONS*************************************
Const BallSize = 50       ' 50 is the normal size used in the core.vbs, VP kicker routines uses this value divided by 2
Const BallMass = 1.7      ' standard ball mass in JP's VPX Physics 3.0
Const SongVolume = 0.7   ' 1 is full volume.

' Load the core.vbs for supporting Subs and functions
LoadCoreFiles

Sub LoadCoreFiles
    On Error Resume Next
    ExecuteGlobal GetTextFile("core.vbs")
    If Err Then MsgBox "Can't open core.vbs"
    ExecuteGlobal GetTextFile("controller.vbs")
    If Err Then MsgBox "Can't open controller.vbs"
    On Error Goto 0
End Sub

' Define any Constants
Const cGameName = "HellRaiser"
Const myVersion = "1.0.1"
Const MaxPlayers = 4          ' from 1 to 4
Const MaxMultiplier = 3       ' limit playfield multiplier
Const MaxBonusMultiplier = 50 'limit Bonus multiplier
Const BallsPerGame = 3        ' usually 3 or 5
Const MaxMultiballs = 6       ' max number of balls during multiballs
Dim BallSaverTime             ' 20 in seconds

' Use FlexDMD if in FS mode
Dim UseFlexDMD
If Table1.ShowDT = True then
    UseFlexDMD = True
Else
    UseFlexDMD = True
End If

' Define Global Variables
Dim PlayersPlayingGame
Dim CurrentPlayer
Dim Credits
Dim BonusPoints(4)
Dim BonusHeldPoints(4)
Dim BonusMultiplier(4)
Dim PlayfieldMultiplier(4)
Dim PFxSeconds
Dim bBonusHeld
Dim BallsRemaining(4)
Dim ExtraBallsAwards(4)
Dim Score(4)
Dim HighScore(4)
Dim HighScoreName(4)
Dim Jackpot(4)
Dim SuperJackpot(4)
Dim Tilt
Dim TiltSensitivity
Dim Tilted
Dim TotalGamesPlayed
Dim mBalls2Eject
Dim SkillshotValue(4)
Dim SuperSkillshotValue(4)
Dim bAutoPlunger
Dim bInstantInfo
Dim bAttractMode
Dim x

' Define Game Control Variables
Dim LastSwitchHit
Dim BallsOnPlayfield
Dim BallsInLock(4)
Dim BallsInHole

' Define Game Flags
Dim bFreePlay
Dim bGameInPlay
Dim bOnTheFirstBall
Dim bBallInPlungerLane
Dim bBallSaverActive
Dim bBallSaverReady
Dim bMultiBallMode
Dim bMusicOn
Dim bSkillshotReady
Dim bExtraBallWonThisBall
Dim bJustStarted
Dim bJackpot
Dim bSongSelect

' core.vbs variables
Dim plungerIM 'used mostly as an autofire plunger during multiballs
Dim cbRight   'captive ball Clown

' *********************************************************************
'                Visual Pinball Defined Script Events
' *********************************************************************

Sub Table1_Init()
    LoadEM
    Dim i
    Randomize
		If BackDrop = 1 Then
		PinCab_Blades.Image = "blade_bake_off"
		End If
	If BloodRamps = 1 Then
		BloodRampsStart
		End If
    ' core.vbs definitions
    'Impulse Plunger as autoplunger
    Const IMPowerSetting = 44 ' Plunger Power
    Const IMTime = 0.6        ' Time in seconds for Full Plunge
    Set plungerIM = New cvpmImpulseP
    With plungerIM
        .InitImpulseP swplunger, IMPowerSetting, IMTime
        .Random 1.5
        .InitExitSnd SoundFXDOF("fx_kicker", 141, DOFPulse, DOFContactors), SoundFXDOF("fx_solenoid", 141, DOFPulse, DOFContactors)
        .CreateEvents "plungerIM"
    End With

    Set cbRight = New cvpmCaptiveBall
    With cbRight
        .InitCaptive CapTrigger2, CapWall2, Array(CapKicker2, CapKicker2a), 0
        .NailedBalls = 1
        .ForceTrans = .9
        .MinForce = 3.5
        .CreateEvents "cbRight"
        .Start
    End With
    CapKicker2.CreateSizedBallWithMass BallSize / 2, BallMass
    CapKicker1.CreateSizedBallWithMass BallSize / 2, BallMass

    ' Misc. VP table objects Initialisation, droptargets, animations...
    VPObjects_Init

    ' load saved values, highscore, names, jackpot
    Loadhs

    ' Initalise the DMD display
    DMD_Init

    ' freeplay or coins
    bFreePlay = True 'we want coins

    if bFreePlay Then DOF 125, DOFOn

    ' Init main variables and any other flags
    bAttractMode = False
    bOnTheFirstBall = False
    bBallInPlungerLane = False
    bBallSaverActive = False
    bBallSaverReady = False
    bMultiBallMode = False
    PFxSeconds = 0
    bGameInPlay = False
    bAutoPlunger = False
    bMusicOn = True
    BallsOnPlayfield = 0
    BallsInLock(1) = 0
    BallsInLock(2) = 0
    BallsInLock(3) = 0
    BallsInLock(4) = 0
    BallsInHole = 0
    LastSwitchHit = ""
    Tilt = 0
    TiltSensitivity = 6
    Tilted = False
    bBonusHeld = False
    bJustStarted = True
    bJackpot = False
    bInstantInfo = False
    bSongSelect = False
    ' set any lights for the attract mode
    StartAttractMode



    ' Start the RealTime timer
    RealTime.Enabled = 1

    ' Load table color
    LoadLut
	Glowball_Init 'Start Glowballs
End Sub

Sub BloodRampsStart
		Ramp007.Image = "ramp_pentagram"
		Ramp016.Image = "metal-ramp-with-holes"
		Ramp017.Image = "metal-ramp-with-holes"
		Ramp008.Image = "metal-ramp-with-holes"
		Ramp011.Image = "metal-ramp-with-holes"
		Ramp012.Image = "metal-ramp-with-holes"
		Ramp018.Image = "metal-ramp-with-holes"
		wall018.SideImage = "newmetal9"
		Wall041.SideImage = "newmetal9"
		Wall038.SideImage = "newmetal9-long"
		Wall015.SideImage = "newmetal9"
		Wall017.SideImage = "newmetal9"
		Wall023.SideImage = "newmetal9"
		Wall025.SideImage = "newmetal9"
		Wall026.SideImage = "newmetal9"
		Wall028.SideImage = "newmetal9"
		Wall029.SideImage = "newmetal9"
		Wall042.SideImage = "newmetal9"
		Wall019.SideImage = "newmetal9-long"
End Sub

'******
' Keys
'******

Sub Table1_KeyDown(ByVal Keycode)
    If keycode = LeftMagnaSave Then bLutActive = True
    If keycode = RightMagnaSave Then
        If bLutActive Then NextLUT:End If
    End If

    If Keycode = AddCreditKey Then
        Credits = Credits + 1
        if bFreePlay = False Then DOF 125, DOFOn
        If(Tilted = False)Then
            DMDFlush
            DMD "_", CL(1, "SOULS " & Credits), "", eNone, eNone, eNone, 500, True, "fx_coin"
            If NOT bGameInPlay Then ShowTableInfo
        End If
    End If

    If keycode = PlungerKey Then
        Plunger.Pullback
        PlaySoundAt "fx_plungerpull", plunger
    End If

    If hsbModeActive Then
        EnterHighScoreKey(keycode)
        Exit Sub
    End If

    ' Table specific

    If bsongSelect Then
        SelectSong(keycode)
    End If

    ' Normal flipper action

    If bGameInPlay AND NOT Tilted Then

        If keycode = LeftTiltKey Then Nudge 90, 8:PlaySound "fx_nudge", 0, 1, -0.1, 0.25:CheckTilt
        If keycode = RightTiltKey Then Nudge 270, 8:PlaySound "fx_nudge", 0, 1, 0.1, 0.25:CheckTilt
        If keycode = CenterTiltKey Then Nudge 0, 9:PlaySound "fx_nudge", 0, 1, 1, 0.25:CheckTilt
		If keycode = MechanicalTilt Then CheckTilt' Tilt Bob
        If keycode = LeftFlipperKey Then SolLFlipper 1:InstantInfoTimer.Enabled = True:RotateActivateX
        If keycode = RightFlipperKey Then SolRFlipper 1:InstantInfoTimer.Enabled = True:RotateActivateX

        If keycode = StartGameKey Then
            If((PlayersPlayingGame <MaxPlayers)AND(bOnTheFirstBall = True))Then

                If(bFreePlay = True)Then
                    PlayersPlayingGame = PlayersPlayingGame + 1
                    TotalGamesPlayed = TotalGamesPlayed + 1
                    DMD "_", CL(1, PlayersPlayingGame & " VICTIMS"), "", eNone, eBlink, eNone, 1000, True, ""
                Else
                    If(Credits> 0)then
                        PlayersPlayingGame = PlayersPlayingGame + 1
                        TotalGamesPlayed = TotalGamesPlayed + 1
                        Credits = Credits - 1
                        DMD "_", CL(1, PlayersPlayingGame & " VICTIMS"), "", eNone, eBlink, eNone, 1000, True, ""
                        If Credits <1 And bFreePlay = False Then DOF 125, DOFOff
                        Else
                            ' Not Enough Credits to start a game.
                            DMD CL(0, "SOULS " & Credits), CL(1, "INSERT SOULS"), "", eNone, eBlink, eNone, 1000, True, "vo_nocredits"
                    End If
                End If
            End If
        End If
        Else ' If (GameInPlay)

            If keycode = StartGameKey Then
                If(bFreePlay = True)Then
					pupevent 901
                    PlaySound "vo_freeplay"
                    If(BallsOnPlayfield = 0)Then
                        ResetForNewGame()
                    End If
                Else
                    If(Credits> 0)Then
                        If(BallsOnPlayfield = 0)Then
                            Credits = Credits - 1
                            If Credits <1 And bFreePlay = False Then DOF 125, DOFOff
                            ResetForNewGame()
                        End If
                    Else
                        ' Not Enough Credits to start a game.
                        DMDFlush
                        DMD CL(0, "SOULS " & Credits), CL(1, "INSERT SOULS"), "", eNone, eBlink, eNone, 1000, True, "vo_nocredits"
                        ShowTableInfo
                    End If
                End If
            End If
    End If ' If (GameInPlay)
End Sub

Sub Table1_KeyUp(ByVal keycode)

    If keycode = LeftMagnaSave Then bLutActive = False

    If keycode = PlungerKey Then
        Plunger.Fire
        PlaySoundAt "fx_plunger", plunger
    End If

    If hsbModeActive Then
        Exit Sub
    End If

    ' Table specific

    If bGameInPLay AND NOT Tilted Then

        If keycode = LeftFlipperKey Then
            SolLFlipper 0
            InstantInfoTimer.Enabled = False
            If bInstantInfo Then
                DMDScoreNow
                bInstantInfo = False
            End If
        End If
        If keycode = RightFlipperKey Then
            SolRFlipper 0
            InstantInfoTimer.Enabled = False
            If bInstantInfo Then
                DMDScoreNow
                bInstantInfo = False
            End If
        End If
    End If
End Sub

Sub InstantInfoTimer_Timer
    InstantInfoTimer.Enabled = False
    If NOT hsbModeActive Then
        bInstantInfo = True
        DMDFlush
        InstantInfo
    End If
End Sub

'*************
' Pause Table
'*************

Sub table1_Paused
End Sub

Sub table1_unPaused
End Sub

Sub Table1_Exit
    Savehs
    If UseFlexDMD Then FlexDMD.Run = False
    If B2SOn = True Then Controller.Stop
End Sub


if PinheadGirl = 1 Then	
	FlasherChick.visible = true
Else
	FlasherChick.visible = False
end if




'********************
'     Flippers
'********************

Sub SolLFlipper(Enabled)
    If Enabled Then
        PlaySoundAt SoundFXDOF("fx_flipperup2", 101, DOFOn, DOFFlippers), LeftFlipper
        LeftFlipper.EOSTorque = 0.75:LeftFlipper.RotateToEnd
        LeftFlipper1.EOSTorque = 0.75:LeftFlipper1.RotateToEnd
    Else
        PlaySoundAt SoundFXDOF("fx_flipperdown", 101, DOFOff, DOFFlippers), LeftFlipper
        LeftFlipper.EOSTorque = 0.2:LeftFlipper.RotateToStart
        LeftFlipper1.EOSTorque = 0.2:LeftFlipper1.RotateToStart
    End If
End Sub

Sub SolRFlipper(Enabled)
    If Enabled Then
        PlaySoundAt SoundFXDOF("fx_flipperup2", 102, DOFOn, DOFFlippers), RightFlipper
        RightFlipper.EOSTorque = 0.75:RightFlipper.RotateToEnd
        RightFlipper1.EOSTorque = 0.75:RightFlipper1.RotateToEnd
    Else
        PlaySoundAt SoundFXDOF("fx_flipperdown", 102, DOFOff, DOFFlippers), RightFlipper
        RightFlipper.EOSTorque = 0.2:RightFlipper.RotateToStart
        RightFlipper1.EOSTorque = 0.2:RightFlipper1.RotateToStart
    End If
End Sub

' flippers hit Sound

Sub LeftFlipper_Collide(parm)
    PlaySound "fx_rubber_flipper", 0, parm / 60, pan(ActiveBall), 0, Pitch(ActiveBall), 0, 0, AudioFade(ActiveBall)
End Sub

Sub RightFlipper_Collide(parm)
    PlaySound "fx_rubber_flipper", 0, parm / 60, pan(ActiveBall), 0, Pitch(ActiveBall), 0, 0, AudioFade(ActiveBall)
End Sub

'*********
' TILT
'*********

'NOTE: The TiltDecreaseTimer Subtracts .01 from the "Tilt" variable every round

Sub CheckTilt                                  'Called when table is nudged
    Tilt = Tilt + TiltSensitivity              'Add to tilt count
    TiltDecreaseTimer.Enabled = True
    If(Tilt> TiltSensitivity)AND(Tilt <15)Then 'show a warning
        DMD "_", CL(1, "CAREFUL!"), "", eNone, eBlinkFast, eNone, 1000, True, "vo_dontshakethegame" : pupevent 825
    End if
    If Tilt> 15 Then 'If more that 15 then TILT the table
        'display Tilt
        DMDFlush
        DMD "", "", "TILT", eNone, eNone, eBlink, 2000, True, "vo_tilt" : pupevent 826
        Tilted = True
        DisableTable True
        TiltRecoveryTimer.Enabled = True 'start the Tilt delay to check for all the balls to be drained
    End If
End Sub

Sub TiltDecreaseTimer_Timer
    ' DecreaseTilt
    If Tilt> 0 Then
        Tilt = Tilt - 0.1
    Else
        TiltDecreaseTimer.Enabled = False
    End If
End Sub

Sub DisableTable(Enabled)
    If Enabled Then
        'turn off GI and turn off all the lights
        GiOff
        LightSeqTilt.Play SeqAllOff
        'Disable slings, bumpers etc
        LeftFlipper.RotateToStart
        RightFlipper.RotateToStart
        Bumper1.Threshold = 100
        Bumper2.Threshold = 100
        Bumper3.Threshold = 100
        LeftSlingshot.Disabled = 1
        RightSlingshot.Disabled = 1
    Else
        'turn back on GI and the lights
        GiOn
        LightSeqTilt.StopPlay
        Bumper1.Threshold = 1
        Bumper2.Threshold = 1
        Bumper3.Threshold = 1
        LeftSlingshot.Disabled = 0
        RightSlingshot.Disabled = 0
        'clean up the buffer display
        DMDFlush
    End If
End Sub

Sub TiltRecoveryTimer_Timer()
    ' if all the balls have been drained then..
    If(BallsOnPlayfield = 0)Then
        ' do the normal end of ball thing (this doesn't give a bonus if the table is tilted)
        vpmtimer.Addtimer 2000, "EndOfBall() '"
        TiltRecoveryTimer.Enabled = False
    End If
' else retry (checks again in another second or so)
End Sub

'*****************************************
'         Music as wav sounds
' in VPX 10.7 you may use also mp3 or ogg
'*****************************************

Dim Playlist, Song, Songnr
PlayList = ""
Song = ""
Songnr = INT(RND * 12)

Sub PlaySong(listname, name)
    If bMusicOn Then
        If Song <> name Then
	        Playlist = listname
            Song = name
	        PlayMusic "./pupvideos/" & cGameName & "/" & listname & "/" & name, SongVolume
        End If
    End If
End Sub

Sub StopSong()
	EndMusic
	PlayList = ""
	Song = ""
End Sub

Sub Table1_MusicDone
    If Song <> "" Then
        Dim prevSong : prevSong = Song
        Song = ""
        PlaySong Playlist, prevSong
    End If
End Sub

Sub PlayRandomSong
    Songnr = INT(RND * 12)
    PLaySelectedSong
End Sub

Sub PLaySelectedSong
    Select Case Songnr
        Case 0:PlaySong "Music1", "01- Hellraiser 1 Suite 1.mp3" 
        Case 1:PlaySong "Music2", "02- Hellraiser 1 Suite 2.mp3" 
        Case 2:PlaySong "Music3", "03- Hellraiser 1 Suite 3.mp3" 
        Case 3:PlaySong "Music4", "04- Hellraiser 1 Suite 4.mp3" 
        Case 4:PlaySong "Music5", "05- Hellraiser 1 Suite 5.mp3" 
        Case 5:PlaySong "Music6", "06- Hellraiser 1 Suite 6.mp3" 
        Case 6:PlaySong "Music7", "07- Hellraiser 1 Suite 7.mp3" 
        Case 7:PlaySong "Music8", "08- Hellraiser 2 Suite 1.mp3" 
        Case 8:PlaySong "Music9", "09- Hellraiser 2 Suite 2.mp3" 
        Case 9:PlaySong "Music10", "10- Hellraiser 2 Suite 3.mp3"
        Case 10:PlaySong "Music11", "11- Hellraiser 2 Suite 4.mp3"
        Case 11:PlaySong "Music12", "12- Hellraiser 2 Suite 5.mp3"
        Case 12:PlaySong "Music13", "13- Hellraiser 2 Suite 6.mp3"
        Case 13:PlaySong "Music14", "14- Hellraiser 2 Suite 7.mp3"
    End Select
End Sub

Sub PlayRandomGameOverSong
    Dim number
    number = INT(RND * 14)
    Select Case number
	Case 0: PlaySong "GameoverMusic", "Ministry - Burning Inside.mp3"
	Case 1: PlaySong "GameoverMusic", "Ministry - Just One Fix.mp3"
	Case 2: PlaySong "GameoverMusic", "Ministry - Stigmata.mp3"
	Case 3: PlaySong "GameoverMusic", "Motorhead - Born To Raise Hell.mp3"
	Case 4: PlaySong "GameoverMusic", "Motorhead - Hellraiser.mp3"
	Case 5: PlaySong "GameoverMusic", "Nine Inch Nails - March Of The Pigs.mp3"
	Case 6: PlaySong "GameoverMusic", "Rammstein - Asche zu Asche.mp3"
	Case 7: PlaySong "GameoverMusic", "Rammstein - Du Riechst So Gut.mp3"
	Case 8: PlaySong "GameoverMusic", "Rammstein - Feuer Frei.mp3"
	Case 9: PlaySong "GameoverMusic", "Ramones - Pinhead.mp3"
	Case 10: PlaySong "GameoverMusic", "Rob Zombie - Get Your Boots On! That's The End Of Rock And Roll.mp3"
	Case 11: PlaySong "GameoverMusic", "Rob Zombie - Lucifer Rising.mp3"
	Case 12: PlaySong "GameoverMusic", "Rob Zombie - The Hideous Exhibitions Of A Dedicated Gore Whore.mp3"
	Case 13: PlaySong "GameoverMusic", "Scum of the Earth - Murder Song.mp3"
	Case 14: PlaySong "GameoverMusic", "Young Gods - Kissing The Sun.mp3"
    End Select
End Sub


Sub SelectSong(keycode)
    If keycode = PlungerKey OR keycode = StartGameKey Then
        bsongSelect = False
    End If
    If keycode = LeftFlipperKey Then
        Songnr = (Songnr - 1)
        If Songnr <0 Then Songnr = 13
        UpdateDMDSong
    End If
    If keycode = RightFlipperKey Then
        Songnr = (Songnr + 1)MOD 14
        UpdateDMDSong
    End If
End Sub

Sub UpdateDMDSong() 'Updates the DMD with the chosen song
    DMDFlush
    Select Case Songnr
        Case 0:DMD "", "", "deja", eNone, eNone, eNone, 2000, True, ""
        Case 1:DMD "", "", "libro", eNone, eNone, eNone, 2000, True, ""
        Case 2:DMD "", "", "fiesta", eNone, eNone, eNone, 2000, True, ""
        Case 3:DMD "", "", "hasta", eNone, eNone, eNone, 2000, True, ""
        Case 4:DMD "", "", "hoy", eNone, eNone, eNone, 2000, True, ""
        Case 5:DMD "", "", "leyenda", eNone, eNone, eNone, 2000, True, ""
        Case 6:DMD "", "", "posada", eNone, eNone, eNone, 2000, True, ""
        Case 7:DMD "", "", "viuda", eNone, eNone, eNone, 2000, True, ""
        Case 8:DMD "", "", "voz", eNone, eNone, eNone, 2000, True, ""
        Case 9:DMD "", "", "molinos", eNone, eNone, eNone, 2000, True, ""
        Case 10:DMD "", "", "traere", eNone, eNone, eNone, 2000, True, ""
        Case 11:DMD "", "", "seras", eNone, eNone, eNone, 2000, True, ""
        Case 12:DMD "", "", "mercado", eNone, eNone, eNone, 2000, True, ""
        Case 13:DMD "", "", "brujas", eNone, eNone, eNone, 2000, True, "vo_lovethissong"
    End Select
    PLaySelectedSong
End Sub

'**********************
'     GI effects
' independent routine
' it turns on the gi
' when there is a ball
' in play
'**********************

Dim OldGiState
OldGiState = -1   'start witht the Gi off

Sub ChangeGi(col) 'changes the gi color
    Dim bulb
    For each bulb in aGILights
        SetLightColor bulb, col, -1
    Next

    Select Case col
        Case 0
'            PinCab_BladesON.color = RGB(18, 0, 0)
            FlasherGI.color = RGB(18, 0, 0)

        Case red
'            PinCab_BladesON.color = RGB(32, 0, 0)
			FlasherGI.color = RGB(32, 0, 0)

        Case orange
'            PinCab_BladesON.color = RGB(18, 3, 0)
            FlasherGI.color = RGB(18, 3, 0)
        Case amber
'            PinCab_BladesON.color = RGB(193, 49, 0)
            FlasherGI.color = RGB(193, 49, 0)
        Case yellow
'            PinCab_BladesON.color = RGB(18, 18, 0)
            FlasherGI.color = RGB(18, 18, 0)
        Case darkgreen
'            PinCab_BladesON.color = RGB(0, 8, 0)
            FlasherGI.color = RGB(0, 8, 0)
        Case green
'            PinCab_BladesON.color = RGB(0, 16, 0)
            FlasherGI.color = RGB(0, 16, 0)
        Case blue
'            PinCab_BladesON.color = RGB(0, 18, 18)
            FlasherGI.color = RGB(0, 18, 18)
        Case darkblue
'            PinCab_BladesON.color = RGB(0, 4, 18)
            FlasherGI.color = RGB(0, 4, 18)
        Case purple
'            PinCab_BladesON.color = RGB(64, 0, 96)
            FlasherGI.color = RGB(64, 0, 96)
        Case white
'            PinCab_BladesON.color = RGB(255, 252, 224)
            FlasherGI.color = RGB(255, 252, 224)
    End Select

End Sub

Sub GIUpdateTimer_Timer 'not used in this table
    Dim tmp, obj
    tmp = Getballs
    If UBound(tmp) <> OldGiState Then
        OldGiState = Ubound(tmp)
        If UBound(tmp) = 1 Then '-1 means no balls, 0 is the first captive ball, 1 is the second captive ball...)
            GiOff               ' turn off the gi if no active balls on the table, we could also have used the variable ballsonplayfield.
        Else
            Gion
        End If
    End If
End Sub

dim GiLvlTarget, GiLvl
Sub GiOn
    DOF 118, DOFOn
'    Dim bulb
'    For each bulb in aGiLights
'        bulb.State = 1
'    Next
'    For each bulb in aGiFlashers
'        bulb.Visible = 1
'    Next
	GiLvlTarget = 1
	GiFade_timer
'	PinCab_BladesON.opacity = 40
'	FlasherGI.opacity = 400
End Sub

Sub GiOff
    DOF 118, DOFOff
'    Dim bulb
'    For each bulb in aGiLights
'        bulb.State = 0
'    Next
'    For each bulb in aGiFlashers
'        bulb.Visible = 0
'    Next
	GiLvlTarget = 0
	GiFade_timer

'	PinCab_BladesON.opacity = 0
'	FlasherGI.opacity = 0
End Sub

dim xxx
For each xxx in aGiLights
	xxx.State = 1
Next
For each xxx in aGiFlashers
	xxx.Visible = 1
Next

sub GiFade_timer
	dim bulb
	If not GiFade.Enabled Then GiFade.Enabled = True

	if GiLvlTarget = 1 then
		gilvl = gilvl + 0.34
		if gilvl > 1 then gilvl = 1
	Else
		gilvl = gilvl * 0.8 - 0.01
		if gilvl < 0 then gilvl = 0
	end if

	
	
'	PinCab_BladesON.opacity = 60 * gilvl
	FlasherPL_RS.opacity = 300 * gilvl
	FlasherPL_LS.opacity = 300 * gilvl
	FlasherPL_BS.opacity = 200 * gilvl

	
	FlasherGI.opacity = 800 * gilvl

    For each bulb in aGiLights
        bulb.intensityscale = gilvl
    Next
    For each bulb in aGiFlashers
        bulb.intensityscale = gilvl
    Next

	pCube1.blenddisablelighting = 2*gilvl + 1.1
	pCube2.blenddisablelighting = 2*gilvl + 1.1

	'toys
	Primitive040.blenddisablelighting = 0.18 * gilvl
	Primitive056.blenddisablelighting = 0.7 * gilvl + 0.3

	'bumpertops
	Primitive29.blenddisablelighting = 0.2 * gilvl - 0.2
	Primitive006.blenddisablelighting = 0.2 * gilvl - 0.2
	Primitive011.blenddisablelighting = 0.2 * gilvl - 0.2

'	debug.print gilvl

	if gilvl = 1 or gilvl = 0 then GiFade.Enabled = False

end sub


' GI, light & flashers sequence effects

Sub GiEffect(n)
    Dim ii

	if gilvl = 1 then 
		GiEffectState = 1
		GiEffectPrevState = 1
	Else
		GiEffectState = 0
		GiEffectPrevState = 0
	end if

    Select Case n
        Case 0 'all off
            GiOff
        Case 1 'all blink
			GiEffectTmr.interval = 15
			GiEffectLength = 20
			GiEffectTmr_timer
        Case 2 'random
			GiEffectTmr.interval = 15
			GiEffectLength = 50
			GiEffectTmr_timer
        Case 3 'all blink fast
			GiEffectTmr.interval = 10
			GiEffectLength = 10
			GiEffectTmr_timer
        Case 4 'seq up
			GiEffectTmr.interval = 3
			GiEffectLength = 25
			GiEffectTmr_timer
			gion
        Case 5 'seq down
			GiEffectTmr.interval = 3
			GiEffectLength = 25
			GiEffectTmr_timer
			gion
    End Select
End Sub

dim GiEffectState, GiEffectLength, GiEffectPrevState
sub GiEffectTmr_timer
	If not GiEffectTmr.Enabled Then GiEffectTmr.Enabled = True
	if GiEffectLength > 0 then
		if GiEffectState = 1 then
			GiOff
			GiEffectState = 0
		Else
			GiOn
			GiEffectState = 1
		end if
		GiEffectLength = GiEffectLength - 1
	Else
		if GiEffectPrevState = 1 then
			GiOn
		Else
			GiOff
		end if
		GiEffectTmr.Enabled = false
	end if

	
end sub

Sub GiEffect2(n)
    Dim ii
    Select Case n
        Case 0 'all off
            LightSeqGi.Play SeqAlloff
        Case 1 'all blink
            LightSeqGi.UpdateInterval = 15
            LightSeqGi.Play SeqBlinking, , 20, 10
        Case 2 'random
            LightSeqGi.UpdateInterval = 15
            LightSeqGi.Play SeqRandom, 50, , 1000
        Case 3 'all blink fast
            LightSeqGi.UpdateInterval = 10
            LightSeqGi.Play SeqBlinking, , 10, 10
        Case 4 'seq up
            LightSeqGi.UpdateInterval = 3
            LightSeqGi.Play SeqUpOn, 25, 3
        Case 5 'seq down
            LightSeqGi.UpdateInterval = 3
            LightSeqGi.Play SeqDownOn, 25, 3
    End Select
End Sub

Sub LightEffect(n)
    Select Case n
        Case 0 ' all off
            LightSeqInserts.Play SeqAlloff
        Case 1 'all blink
            LightSeqInserts.UpdateInterval = 15
            LightSeqInserts.Play SeqBlinking, , 20, 10
            PlaySound "thunder1"
			LightSeqThunder.Play SeqBlinking, , 20, 10
        Case 2 'random
            LightSeqInserts.UpdateInterval = 10
            LightSeqInserts.Play SeqRandom, 50, , 1000
            PlaySound "thunder2"
			LightSeqThunder.Play SeqBlinking, , 10, 20
        Case 3 'all blink fast
            LightSeqInserts.UpdateInterval = 10
            'LightSeqInserts.Play SeqBlinking, , 10, 10
            PlaySound "thunder3"
			'LightSeqThunder.Play SeqBlinking, , 10, 10
        Case 4 ' seq up
            LightSeqInserts.UpdateInterval = 3
            LightSeqInserts.Play SeqUpOn, 15, 3
            PlaySound "thunder1"
			LightSeqThunder.Play SeqBlinking, , 20, 10
        Case 5 'seq down
            LightSeqInserts.UpdateInterval = 3
            LightSeqInserts.Play SeqDownOn, 15, 3
            PlaySound "thunder1"
			LightSeqThunder.Play SeqBlinking, , 20, 10
    End Select
End Sub

Sub FlashEffect(n) 'adjusted for this table
    Select Case n
        Case 1:    ' all blink
            SetFlash Flasher004, 4, 2000, 50
            SetFlash Flasher005, 5, 2000, 50
            SetFlash Flasher003, 3, 2000, 50
            SetFlash Flasher002, 2, 2000, 50
            SetFlash Flasher001, 1, 2000, 50
            SetFlash Flasher009, 9, 2000, 50
            SetFlash Flasher010, 10, 2000, 50
        case 2: 'random
            SetFlash Flasher004, 4, 2000, 50
            vpmtimer.addtimer 200, "SetFlash Flasher005,5,2000,50 '"
            vpmtimer.addtimer 1200, "SetFlash Flasher003,3,2000,50 '"
            vpmtimer.addtimer 400, "SetFlash Flasher002,2,2000,50 '"
            vpmtimer.addtimer 800, "SetFlash Flasher001,1,2000,50 '"
            vpmtimer.addtimer 600, "SetFlash Flasher009,9,2000,50 '"
            vpmtimer.addtimer 1000, "SetFlash Flasher010,10,2000,50 '"
        Case 1: ' all blink fast
            SetFlash Flasher004, 4, 1000, 50
            SetFlash Flasher005, 5, 1000, 50
            SetFlash Flasher003, 3, 1000, 50
            SetFlash Flasher002, 2, 1000, 50
            SetFlash Flasher001, 1, 1000, 50
            SetFlash Flasher009, 9, 1000, 50
            SetFlash Flasher010, 10, 1000, 50
        Case 4 ' seq up
            vpmtimer.addtimer 400, "SetFlash Flasher004,4,2000,50 '"
            vpmtimer.addtimer 400, "SetFlash Flasher005,5,2000,50 '"
            vpmtimer.addtimer 300, "SetFlash Flasher003,3,2000,50 '"
            vpmtimer.addtimer 200, "SetFlash Flasher002,2,2000,50 '"
            vpmtimer.addtimer 200, "SetFlash Flasher001,1,2000,50 '"
            vpmtimer.addtimer 10, "SetFlash Flasher009,9,2000,50 '"
            vpmtimer.addtimer 10, "SetFlash Flasher010,10,2000,50 '"
        Case 5 'seq down
            vpmtimer.addtimer 10, "SetFlash Flasher004,4,2000,50 '"
            vpmtimer.addtimer 10, "SetFlash Flasher005,5,2000,50 '"
            vpmtimer.addtimer 200, "SetFlash Flasher003,3,2000,50 '"
            vpmtimer.addtimer 300, "SetFlash Flasher002,2,2000,50 '"
            vpmtimer.addtimer 300, "SetFlash Flasher001,1,2000,50 '"
            vpmtimer.addtimer 400, "SetFlash Flasher009,9,2000,50 '"
            vpmtimer.addtimer 400, "SetFlash Flasher010,10,2000,50 '"
    End Select
End Sub

'***************************************************************
'             Supporting Ball & Sound Functions v3.0
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
    If tmp> 0 Then
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
    If tmp> 0 Then
        AudioFade = Csng(tmp ^10)
    Else
        AudioFade = Csng(-((- tmp) ^10))
    End If
End Function

Sub PlaySoundAt(soundname, tableobj) 'play sound at X and Y position of an object, mostly bumpers, flippers and other fast objects
    PlaySound soundname, 0, 1, Pan(tableobj), 0.1, 0, 0, 0, AudioFade(tableobj)
End Sub

Sub PlaySoundAtBall(soundname) ' play a sound at the ball position, like rubbers, targets, metals, plastics
    PlaySound soundname, 0, Vol(ActiveBall), pan(ActiveBall), 0.4, 0, 0, 0, AudioFade(ActiveBall)
End Sub

'***********************************************
'   JP's VP10 Rolling Sounds + Ballshadow v3.0
'   uses a collection of shadows, aBallShadow
'***********************************************

Const tnob = 19   'total number of balls, 20 balls, from 0 to 19
Const lob = 3     'number of locked balls
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

    ' stop the sound of deleted balls and hide the shadow
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
        aBallShadow(b).Height = BOT(b).Z -24

        If BallVel(BOT(b))> 1 Then
            If BOT(b).z <30 Then
                ballpitch = Pitch(BOT(b))
                ballvol = Vol(BOT(b))
            Else
                ballpitch = Pitch(BOT(b)) + 25000 'increase the pitch on a ramp
                ballvol = Vol(BOT(b)) * 10
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

        ' jps ball speed control
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
    PlaySound "fx_collide", 0, Csng(velocity) ^2 / 2000, Pan(ball1), 0, Pitch(ball1), 0, 0, AudioFade(ball1)
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
Sub aTargets_Hit(idx):ActiveBall.VelZ = BallVel(Activeball) * (RND / 2):End Sub

' *********************************************************************
'                        User Defined Script Events
' *********************************************************************

' Initialise the Table for a new Game
'
Sub ResetForNewGame()
    Dim i

    bGameInPLay = True

    'resets the score display, and turn off attract mode
    StopAttractMode
    TotalGamesPlayed = TotalGamesPlayed + 1
    CurrentPlayer = 1
    PlayersPlayingGame = 1
    bOnTheFirstBall = True
    For i = 1 To MaxPlayers
        Score(i) = 0
        BonusPoints(i) = 0
        BonusHeldPoints(i) = 0
        BonusMultiplier(i) = 1
        PlayfieldMultiplier(i) = 1
        BallsRemaining(i) = BallsPerGame
        ExtraBallsAwards(i) = 0
    Next

    ' initialise any other flags
    Tilt = 0

    ' initialise Game variables
    Game_Init()

    ' you may wish to start some music, play a sound, do whatever at this point

    vpmtimer.addtimer 1500, "FirstBall '"
End Sub

' This is used to delay the start of a game to allow any attract sequence to
' complete.  When it expires it creates a ball for the player to start playing with

Sub FirstBall
    ' reset the table for a new ball
    ResetForNewPlayerBall()
    ' create a new ball in the shooters lane
    CreateNewBall()
End Sub

' (Re-)Initialise the Table for a new ball (either a new ball after the player has
' lost one or we have moved onto the next player (if multiple are playing))

Sub ResetForNewPlayerBall()
    ' make sure the correct display is upto date
    AddScore 0

    ' set the current players bonus multiplier back down to 1X
    BonusMultiplier(CurrentPlayer) = 1:UpdateBonusxLights

    ' set the playfield multiplier
    ' reset any drop targets, lights, game Mode etc..

    BonusPoints(CurrentPlayer) = 0
    bBonusHeld = False
    bExtraBallWonThisBall = False

    'Reset any table specific
    ResetNewBallVariables
    ResetNewBallLights()

    'This is a new ball, so activate the ballsaver
    bBallSaverReady = True

    'and the skillshot
    bSkillShotReady = True

	GiOn 'GI ON after draining.

'Change the music ?
End Sub

' Create a new ball on the Playfield

Sub CreateNewBall()
    ' create a ball in the plunger lane kicker.
    BallRelease.CreateSizedBallWithMass BallSize / 2, BallMass

    ' There is a (or another) ball on the playfield
    BallsOnPlayfield = BallsOnPlayfield + 1

    ' kick it out..
    PlaySoundAt SoundFXDOF("fx_Ballrel", 123, DOFPulse, DOFContactors), BallRelease
    BallRelease.Kick 90, 4

' if there is 2 or more balls then set the multibal flag (remember to check for locked balls and other balls used for animations)
' set the bAutoPlunger flag to kick the ball in play automatically
    If BallsOnPlayfield> 1 Then
        DOF 143, DOFPulse
        bMultiBallMode = True
        bAutoPlunger = True
    End If
End Sub

' Add extra balls to the table with autoplunger
' Use it as AddMultiball 4 to add 4 extra balls to the table

Sub AddMultiball(nballs)
    mBalls2Eject = mBalls2Eject + nballs
    CreateMultiballTimer.Enabled = True
    'and eject the first ball
    CreateMultiballTimer_Timer
End Sub

' Eject the ball after the delay, AddMultiballDelay
Sub CreateMultiballTimer_Timer()
    ' wait if there is a ball in the plunger lane
    If bBallInPlungerLane Then
        Exit Sub
    Else
        If BallsOnPlayfield <MaxMultiballs Then
            CreateNewBall()
            mBalls2Eject = mBalls2Eject -1
            If mBalls2Eject = 0 Then 'if there are no more balls to eject then stop the timer
                CreateMultiballTimer.Enabled = False
            End If
        Else 'the max number of multiballs is reached, so stop the timer
            mBalls2Eject = 0
            CreateMultiballTimer.Enabled = False
        End If
    End If
End Sub

' The Player has lost his ball (there are no more balls on the playfield).
' Handle any bonus points awarded

Sub EndOfBall()
    Dim AwardPoints, TotalBonus, ii
    AwardPoints = 0
    TotalBonus = 0
    ' the first ball has been lost. From this point on no new players can join in
    bOnTheFirstBall = False

    ' only process any of this if the table is not tilted.  (the tilt recovery
    ' mechanism will handle any extra balls or end of game)

    If NOT Tilted Then

        'Count the bonus. This table uses several bonus
        DMD CL(0, "SOUL LOST"), "", "", eNone, eNone, eNone, 1000, True, "" : pupevent 817

        'Switch Bonus
        AwardPoints = SwitchBonusCount * 3500
        TotalBonus = AwardPoints
        DMD CL(0, "SWITCHES X " & SwitchBonusCount), CL(1, FormatScore(AwardPoints)), "", eNone, eNone, eNone, 1000, True, ""

        'Ilussia letters
        AwardPoints = IlussiaBonusCount * 25000
        TotalBonus = TotalBonus + AwardPoints
        DMD CL(0, "PINHEAD LETTERS X " & IlussiaBonusCount), CL(1, FormatScore(AwardPoints)), "", eNone, eNone, eNone, 1000, True, ""

        'Deathblows
        AwardPoints = DeathblowBonusCount * 45000
        TotalBonus = TotalBonus + AwardPoints
        DMD CL(0, "DEATHBLOWS X " & DeathblowBonusCount), CL(1, FormatScore(AwardPoints)), "", eNone, eNone, eNone, 1000, True, ""

        'Loops
        AwardPoints = LoopsBonusCount * 50000
        TotalBonus = TotalBonus + AwardPoints
        DMD CL(0, "LOOPS X " & LoopsBonusCount), CL(1, FormatScore(AwardPoints)), "", eNone, eNone, eNone, 1000, True, ""

        'Pyramid awards completed
        AwardPoints = PyramidBonusCount * 75000
        TotalBonus = TotalBonus + AwardPoints
        DMD CL(0, "HELL AWARD X " & PyramidBonusCount), CL(1, FormatScore(AwardPoints)), "", eNone, eNone, eNone, 1000, True, ""

        'Mancha Xanandra completed
        AwardPoints = ManchaXBonusCount * 250000
        TotalBonus = TotalBonus + AwardPoints
        DMD CL(0, "PINHEAD X " & ManchaXBonusCount), CL(1, FormatScore(AwardPoints)), "", eNone, eNone, eNone, 1000, True, ""

        ' calculate the totalbonus
        TotalBonus = TotalBonus * BonusMultiplier(CurrentPlayer)

' handle the bonus held
' reset the bonus held value since it has been already added to the bonus
'BonusHeldPoints(CurrentPlayer) = 0

' the player has won the bonus held award so do something with it :)
'If bBonusHeld Then
'    If Balls = BallsPerGame Then ' this is the last ball, so if bonus held has been awarded then double the bonus
'        TotalBonus = TotalBonus * 2
'    End If
'Else ' this is not the last ball so save the bonus for the next ball
'    BonusHeldPoints(CurrentPlayer) = TotalBonus
'End If
        bBonusHeld = False

        ' Add the bonus to the score
        DMD CL(0, "TOTAL BONUS " & " X" & BonusMultiplier(CurrentPlayer)), CL(1, FormatScore(TotalBonus)), "", eNone, eNone, eNone, 2000, True, ""

        AddScore TotalBonus

        ' add a bit of a delay to allow for the bonus points to be shown & added up
        vpmtimer.addtimer 9500, "EndOfBall2 '"
    Else 'if tilted then only add a short delay and go to the next end of ball routine.
	MusicVolume = SongVolume
        vpmtimer.addtimer 200, "EndOfBall2 '"
    End If
End Sub

' The Timer which delays the machine to allow any bonus points to be added up
' has expired.  Check to see if there are any extra balls for this player.
' if not, then check to see if this was the last ball (of the CurrentPlayer)
'
Sub EndOfBall2()
    ' if were tilted, reset the internal tilted flag (this will also
    ' set TiltWarnings back to zero) which is useful if we are changing player LOL
    Tilted = False
    Tilt = 0
    DisableTable False 'enable again bumpers and slingshots

    ' has the player won an extra-ball ? (might be multiple outstanding)
    If(ExtraBallsAwards(CurrentPlayer) <> 0)Then
        'debug.print "Extra Ball"

        ' yep got to give it to them
        ExtraBallsAwards(CurrentPlayer) = ExtraBallsAwards(CurrentPlayer)- 1 : pupevent 819

        ' if no more EB's then turn off any shoot again light
        If(ExtraBallsAwards(CurrentPlayer) = 0)Then
            LightShootAgain.State = 0
        End If

        ' You may wish to do a bit of a song AND dance at this point
        DMD CL(0, "EXTRA SOUL"), CL(1, "SHOOT AGAIN"), "", eNone, eNone, eBlink, 1000, True, ""

        ' In this table an extra ball will have the skillshot and ball saver, so we reset the playfield for the new ball
        ResetForNewPlayerBall()

        ' Create a new ball in the shooters lane
        CreateNewBall()
    Else ' no extra balls

        BallsRemaining(CurrentPlayer) = BallsRemaining(CurrentPlayer)- 1

        ' was that the last ball ?
        If(BallsRemaining(CurrentPlayer) <= 0)Then
            'debug.print "No More Balls, High Score Entry"

            ' Submit the CurrentPlayers score to the High Score system
            CheckHighScore()
        ' you may wish to play some music at this point

        Else

            ' not the last ball (for that player)
            ' if multiple players are playing then move onto the next one
            EndOfBallComplete()
        End If
    End If
End Sub

' This function is called when the end of bonus display
' (or high score entry finished) AND it either end the game or
' move onto the next player (or the next ball of the same player)
'
Sub EndOfBallComplete()
    Dim NextPlayer

    'debug.print "EndOfBall - Complete"

    ' are there multiple players playing this game ?
    If(PlayersPlayingGame> 1)Then
        ' then move to the next player
        NextPlayer = CurrentPlayer + 1
        ' are we going from the last player back to the first
        ' (ie say from player 4 back to player 1)
        If(NextPlayer> PlayersPlayingGame)Then
            NextPlayer = 1
        End If
    Else
        NextPlayer = CurrentPlayer
    End If

    'debug.print "Next Player = " & NextPlayer

    ' is it the end of the game ? (all balls been lost for all players)
    If((BallsRemaining(CurrentPlayer) <= 0)AND(BallsRemaining(NextPlayer) <= 0))Then
        ' you may wish to do some sort of Point Match free game award here
        ' generally only done when not in free play mode

        ' set the machine into game over mode
        EndOfGame() : pupevent 820

    ' you may wish to put a Game Over message on the desktop/backglass

    Else
        ' set the next player
        CurrentPlayer = NextPlayer

        ' make sure the correct display is up to date
        AddScore 0

        ' reset the playfield for the new player (or new ball)
        ResetForNewPlayerBall()

        ' AND create a new ball
        CreateNewBall()

        ' play a sound if more than 1 player
        If PlayersPlayingGame> 1 Then
            Select Case CurrentPlayer
                Case 1:DMD "", "", "player1", eNone, eNone, eNone, 1000, True, "vo_player1" : pupevent 827
                Case 2:DMD "", "", "player2", eNone, eNone, eNone, 1000, True, "vo_player2" : pupevent 828
                Case 3:DMD "", "", "player3", eNone, eNone, eNone, 1000, True, "vo_player3" : pupevent 829
                Case 4:DMD "", "", "player4", eNone, eNone, eNone, 1000, True, "vo_player4" : pupevent 830
            End Select
        Else
            DMD "", "", "player1", eNone, eNone, eNone, 1000, True, "vo_youareup"
        End If
    End If
End Sub

' This function is called at the End of the Game, it should reset all
' Drop targets, AND eject any 'held' balls, start any attract sequences etc..

Sub EndOfGame()
    'debug.print "End Of Game"
    bGameInPLay = False
    ' just ended your game then play the end of game tune
    If NOT bJustStarted Then

    End If
    bJustStarted = False
    ' ensure that the flippers are down
    SolLFlipper 0
    SolRFlipper 0

    ' terminate all Mode - eject locked balls
    ' most of the Mode/timers terminate at the end of the ball

    ' set any lights for the attract mode
    StartAttractMode
' you may wish to light any Game Over Light you may have
End Sub

Function Balls
    Dim tmp
    tmp = BallsPerGame - BallsRemaining(CurrentPlayer) + 1
    If tmp> BallsPerGame Then
        Balls = BallsPerGame
    Else
        Balls = tmp
    End If
End Function

' *********************************************************************
'                      Drain / Plunger Functions
' *********************************************************************

' lost a ball ;-( check to see how many balls are on the playfield.
' if only one then decrement the remaining count AND test for End of game
' if more than 1 ball (multi-ball) then kill of the ball but don't create
' a new one
'
Sub Drain_Hit()
    ' Destroy the ball
    Drain.DestroyBall
    If bGameInPLay = False Then Exit Sub 'don't do anything, just delete the ball
    ' Exit Sub ' only for debugging - this way you can add balls from the debug window

    BallsOnPlayfield = BallsOnPlayfield - 1

    ' pretend to knock the ball into the ball storage mech
    PlaySoundAt "fx_drain", Drain
    'if Tilted the end Ball Mode
    If Tilted Then
        StopEndOfBallMode
    End If

    ' if there is a game in progress AND it is not Tilted
    If(bGameInPLay = True)AND(Tilted = False)Then

        ' is the ball saver active,
        If(bBallSaverActive = True)Then

            ' yep, create a new ball in the shooters lane
            ' we use the Addmultiball in case the multiballs are being ejected
            AddMultiball 1
            ' we kick the ball with the autoplunger
            bAutoPlunger = True
            ' you may wish to put something on a display or play a sound at this point
            DMD "_", CL(1, "SOUL SAVED"), "", eNone, eNone, eNone, 1800, True, "vo_playagain" : pupevent 824
        Else
            ' cancel any multiball if on last ball (ie. lost all other balls)
            If(BallsOnPlayfield = 1)Then
                ' AND in a multi-ball??
                If(bMultiBallMode = True)then
                    ' not in multiball mode any more
                    bMultiBallMode = False
                    ' you may wish to change any music over at this point and

                    ' turn off any multiball specific lights
                    ChangeGi white
                    'stop any multiball modes
                    StopMultiballModes
                End If
            End If

            ' was that the last ball on the playfield
            If(BallsOnPlayfield = 0)Then
                ' End Mode and timers

                'ChangeGi white
				GiOff 'set GI off for EOB
                ' Show the end of ball animation
                ' and continue with the end of ball
                ' DMD something?
                StopEndOfBallMode
                vpmtimer.addtimer 200, "EndOfBall '" 'the delay is depending of the animation of the end of ball, if there is no animation then move to the end of ball
            End If
        End If
    End If
End Sub

' The Ball has rolled out of the Plunger Lane and it is pressing down the trigger in the shooters lane
' Check to see if a ball saver mechanism is needed and if so fire it up.

Sub swPlungerRest_Hit()
    'debug.print "ball in plunger lane"
    ' some sound according to the ball position
    PlaySoundAt "fx_sensor", swPlungerRest
    bBallInPlungerLane = True
    ' turn on Launch light is there is one

    'be sure to update the Scoreboard after the animations, if any

    ' kick the ball in play if the bAutoPlunger flag is on
    If bAutoPlunger Then
        'debug.print "autofire the ball"
        PlungerIM.AutoFire
        PlaySoundAt SoundFXDOF("fx_kicker",141,DOFPulse,DOFContactors), swPlungerRest
        bAutoPlunger = False
    End If
    ' if there is a need for a ball saver, then start off a timer
    ' only start if it is ready, and it is currently not running, or else it will reset the time period
    If(bBallSaverReady = True)AND(BallSaverTime <> 0)And(bBallSaverActive = False)Then
        EnableBallSaver BallSaverTime
    End If
    'Start the Selection of the song and skillshot if ready
    If bSkillShotReady Then
        UpdateSkillshot()
        'If Balls = 1 Then PlaySound "vo_changetrack"play
        bSongSelect = True
        vpmtimer.addtimer 2000, "UpdateDMDSong '"
    End If
    ' show the message to shoot the ball in case the player has fallen sleep :)
    swPlungerRest.TimerEnabled = 1
    ' remember last trigger hit by the ball.
    LastSwitchHit = "swPlungerRest"
End Sub

' The ball is released from the plunger turn off some flags and check for skillshot

Sub swPlungerRest_UnHit()
    swPlungerRest.TimerEnabled = 0
    DMDScorenow
    bBallInPlungerLane = False
    bsongSelect = False
    swPlungerRest.TimerEnabled = 0 'stop the launch ball timer if active
    If bSkillShotReady Then
        ResetSkillShotTimer.Enabled = 1
    End If
    LightEffect 4
' turn off LaunchLight
' LaunchLight.State = 0
End Sub

' swPlungerRest timer to show the "launch ball" if the player has not shot the ball during 6 seconds

Sub swPlungerRest_Timer
    Dim tmp
    DMDFlush
    tmp = INT(RND * 4)
    Select case tmp
        case 0:DMD "_", CL(1, "SOUL READY"), "", eNone, eNone, eNone, 1500, True, "vo_punchtheball"
        case 1:DMD "_", CL(1, "SOUL READY"), "", eNone, eNone, eNone, 1500, True, "vo_itsgotime"
        case 2:DMD "_", CL(1, "SOUL READY"), "", eNone, eNone, eNone, 1500, True, "vo_letsball"
        case 3:DMD "_", CL(1, "SOUL READY"), "", eNone, eNone, eNone, 1500, True, "vo_showwhatyougot"
    End Select
End Sub

Sub EnableBallSaver(seconds)
    'debug.print "Ballsaver started"
    ' set our game flag
    bBallSaverActive = True
    bBallSaverReady = False
    ' start the timer
    BallSaverTimerExpired.Interval = 1000 * seconds
    BallSaverTimerExpired.Enabled = True
    BallSaverSpeedUpTimer.Interval = 1000 * seconds -(1000 * seconds) / 3
    BallSaverSpeedUpTimer.Enabled = True
    ' if you have a ball saver light you might want to turn it on at this point (or make it flash)
    LightShootAgain.BlinkInterval = 160
    LightShootAgain.State = 2
End Sub

' The ball saver timer has expired.  Turn it off AND reset the game flag
'
Sub BallSaverTimerExpired_Timer()
    'debug.print "Ballsaver ended"
    BallSaverTimerExpired.Enabled = False
    ' clear the flag
    bBallSaverActive = False
    ' if you have a ball saver light then turn it off at this point
    LightShootAgain.State = 0
End Sub

Sub BallSaverSpeedUpTimer_Timer()
    'debug.print "Ballsaver Speed Up Light"
    BallSaverSpeedUpTimer.Enabled = False
    ' Speed up the blinking
    LightShootAgain.BlinkInterval = 80
    LightShootAgain.State = 2
End Sub

' *********************************************************************
'                      Supporting Score Functions
' *********************************************************************

' Add points to the score AND update the score board

Sub AddScore(points)
    If Tilted Then Exit Sub
    ' add the points to the current players score variable
    If PFxActivated Then
        Score(CurrentPlayer) = Score(CurrentPlayer) + points * PlayfieldMultiplier(CurrentPlayer)
    Else
        Score(CurrentPlayer) = Score(CurrentPlayer) + points
    End if
' you may wish to check to see if the player has gotten a replay
End Sub

' Add bonus to the bonuspoints AND update the score board

Sub AddBonus(points) 'not used in this table, since there are many different bonus items.
    If Tilted Then Exit Sub
    ' add the bonus to the current players bonus variable
    BonusPoints(CurrentPlayer) = BonusPoints(CurrentPlayer) + points
End Sub

' Add some points to the current Jackpot.
'
Sub AddJackpot(points)
    ' Jackpots only generally increment in multiball mode AND not tilted, but this doesn't have to be the case
    If Tilted Then Exit Sub
    ' If(bMultiBallMode = True) Then
    Jackpot(CurrentPlayer) = Jackpot(CurrentPlayer) + points
'DMD "_", CL(1, "INCREASED JACKPOT"), "", eNone, eNone, eNone, 800, True, ""
' you may wish to limit the jackpot to a upper limit, ie..
'	If (Jackpot >= 6000) Then
'		Jackpot = 6000
' 	End if
'End if
End Sub

Sub AddSuperJackpot(points) 'not used in this table
    If(Tilted = False)Then
    End if
    SuperJackpot(CurrentPlayer) = SuperJackpot(CurrentPlayer) + points
End Sub

Sub AddBonusMultiplier(n)
    ' if not at the maximum bonus level
    if(BonusMultiplier(CurrentPlayer) + n <= MaxBonusMultiplier)then
        ' then add and set the lights
        BonusMultiplier(CurrentPlayer) = BonusMultiplier(CurrentPlayer) + n
        UPdateBonusXLights
        DMD "_", CL(1, "BONUS X IS " &BonusMultiplier(CurrentPlayer)), "", eNone, eNone, eNone, 1500, True, "fanfare8"
    Else
        AddScore 50000
        DMD "_", CL(1, "50000 POINTS"), "", eNone, eNone, eNone, 1500, True, ""
    End if
End Sub

Sub UpdateBonusXLights
' Update the lights
'Select Case BonusMultiplier(CurrentPlayer)
'Case 1:light54.State = 0:light55.State = 0:light56.State = 0:light57.State = 0
'Case 2:light54.State = 1:light55.State = 0:light56.State = 0:light57.State = 0
'Case 3:light54.State = 0:light55.State = 1:light56.State = 0:light57.State = 0
'Case 4:light54.State = 0:light55.State = 0:light56.State = 1:light57.State = 0
'Case 5:light54.State = 0:light55.State = 0:light56.State = 0:light57.State = 1
'End Select
End Sub

Sub AddPlayfieldMultiplier(n)
    ' if not at the maximum level x
    if(PlayfieldMultiplier(CurrentPlayer) + n <= MaxMultiplier)then
        ' then add and set the lights
        PlayfieldMultiplier(CurrentPlayer) = PlayfieldMultiplier(CurrentPlayer) + n
        PFxSeconds = PFxSeconds + 30 * n
        UpdatePFXLights
        DMD "_", CL(1, "PLAYFIELD X " &PlayfieldMultiplier(CurrentPlayer)), "", eNone, eNone, eNone, 1500, True, ""
        If PlayfieldMultiplier(CurrentPlayer)> 1 Then PlaySound "Fanfare5"
    End if
'Start the timer to reduce the playfield x every 30 seconds
'in this table this timer is activated from the inlanes
'pfxtimer.Enabled = 1
End Sub

Sub pfxtimer_Timer
    debug.print PFxSeconds
    PFxSeconds = PFxSeconds - 1
    Select Case PFxSeconds
        Case 29:PlayfieldMultiplier(CurrentPlayer) = 2:UpdatePFxLights
        Case 10:light013.blinkinterval = 125
        Case 0:
            PlayfieldMultiplier(CurrentPlayer) = 1
            PFxActivated = 0
            Me.Enabled = 0
            UpdatePFxLights
    End Select
End Sub

Sub UpdatePFxLights
    ' Update the lights
    Select Case PlayfieldMultiplier(CurrentPlayer)
        Case 1:light013.State = 0:light012.State = 0
            light001.State = 0
            light002.State = 0
            light013.blinkinterval = 250
            light012.blinkinterval = 250
        Case 2:light013.State = 1 + PFxActivated:light012.State = 0
            If light001.State = 0 AND light002.State = 0 Then light001.State = 1
        Case 3:light013.State = 0:light012.State = 1 + PFxActivated
            If light001.State = 0 AND light002.State = 0 Then light001.State = 1
    End Select
' show the multiplier in the DMD?
End Sub

Sub AwardExtraBall()
    If NOT bExtraBallWonThisBall Then
        DMD "_", CL(1, ("EXTRA SOUL WON")), "", eNone, eBlink, eNone, 1000, True, SoundFXDOF("fx_Knocker", 122, DOFPulse, DOFKnocker) : pupevent 832
        DOF 121, DOFPulse
        ExtraBallsAwards(CurrentPlayer) = ExtraBallsAwards(CurrentPlayer) + 1
        bExtraBallWonThisBall = True
        LightShootAgain.State = 1 'light the shoot again lamp
        GiEffect 2
        LightEffect 2
    END If
End Sub

Sub AwardSpecial()
    DMD "_", CL(1, ("EXTRA GAME WON")), "", eNone, eBlink, eNone, 1000, True, SoundFXDOF("fx_Knocker", 122, DOFPulse, DOFKnocker) : pupevent 833
    DOF 121, DOFPulse
    Credits = Credits + 1
    If bFreePlay = False Then DOF 125, DOFOn
    LightEffect 2
    Flasheffect 2
End Sub

Sub AwardJackpot() 'award a normal jackpot,
    Dim tmp
    DOF 126, DOFPulse
    tmp = INT(RND * 2)
    Select Case tmp
        Case 0:DMD CL(0, FormatScore(Jackpot(CurrentPlayer))), CL(1, "JACKPOT"), "", eBlinkFast, eNone, eNone, 1500, True, "vo_jackpot" : pupevent 750
        Case 1:DMD CL(0, FormatScore(Jackpot(CurrentPlayer))), CL(1, "JACKPOT"), "", eBlinkFast, eNone, eNone, 1500, True, "vo_jackpot2" : pupevent 750
    End Select
    AddScore Jackpot(CurrentPlayer)
    AddJackpot 150000
    LightEffect 2
    Flasheffect 2
End Sub

Sub AwardDoubleJackpot() 'award a double jackpot
    Dim tmp
    tmp = Jackpot(CurrentPlayer) * 2
    DMD CL(0, FormatScore(tmp)), CL(1, "DOUBLE JACKPOT"), "", eBlinkFast, eNone, eNone, 1500, True, "vo_doublejackpot" : pupevent 751
    DOF 126, DOFPulse
    AddScore Jackpot(CurrentPlayer) * 2
    AddJackpot 300000
    LightEffect 2
    Flasheffect 2
End Sub

Sub AwardSuperJackpot()
    AddBonusMultiplier 1
    DMD CL(0, FormatScore(SuperJackpot(CurrentPlayer))), CL(1, "SUPER JACKPOT"), "", eBlinkFast, eNone, eNone, 1500, True, "vo_superjackpot" : pupevent 752
    DOF 126, DOFPulse
    AddScore SuperJackpot(CurrentPlayer)
    AddSuperJackpot 250000
    LightEffect 2
    Flasheffect 2
End Sub

Sub AwardSuperJackpot_Witch()
    Dim tmp
    tmp = SuperJackpot(CurrentPlayer) * WitchMultiplier
    DOF 126, DOFPulse
    If WitchMultiplier> 1 Then
        DMD CL(0, FormatScore(tmp)), CL(1, "SUPER JACKPOT X" & WitchMultiplier), "", eBlinkFast, eNone, eNone, 1500, True, "vo_superduperjackpot" : pupevent 753
    Else
        DMD CL(0, FormatScore(tmp)), CL(1, "SUPER JACKPOT"), "", eBlinkFast, eNone, eNone, 1500, True, "vo_superjackpot" : pupevent 752
    End If
    AddScore tmp
    AddSuperJackpot 250000
    LightEffect 2
    Flasheffect 2
End Sub

Sub AwardJackpot_WitchTarget() 'target hit
    Dim tmp
    tmp = Jackpot(CurrentPlayer) * WitchMultiplier
    DOF 126, DOFPulse
    Select Case WitchMultiplier
        Case 1:DMD CL(0, FormatScore(tmp)), CL(1, "JACKPOT X" & WitchMultiplier), "", eBlinkFast, eNone, eNone, 1500, True, "vo_jackpot" : pupevent 750
        Case 2:DMD CL(0, FormatScore(tmp)), CL(1, "DOUBLE JACKPOT X" & WitchMultiplier), "", eBlinkFast, eNone, eNone, 1500, True, "vo_doublejackpot" : pupevent 751
        Case 3:DMD CL(0, FormatScore(tmp)), CL(1, "TRIPLE JACKPOT X" & WitchMultiplier), "", eBlinkFast, eNone, eNone, 1500, True, "vo_triplejackpot" : pupevent 754
    End Select
    AddScore tmp
    LightEffect 2
    Flasheffect 2
End Sub

Sub AwardJackpot_WitchArrow(n) 'Jackpot Arrow hit
    Dim tmp
    tmp = Jackpot(CurrentPlayer) * WitchMBMultiplier(n)
    DOF 126, DOFPulse
    Select Case WitchMBMultiplier(n)
        Case 1:DMD CL(0, FormatScore(tmp)), CL(1, "JACKPOT"), "", eBlinkFast, eNone, eNone, 1500, True, "vo_jackpot" : pupevent 750
        Case 2:DMD CL(0, FormatScore(tmp)), CL(1, "DOUBLE JACKPOT"), "", eBlinkFast, eNone, eNone, 1500, True, "vo_doublejackpot" : pupevent 751
        Case 3:DMD CL(0, FormatScore(tmp)), CL(1, "TRIPLE JACKPOT"), "", eBlinkFast, eNone, eNone, 1500, True, "vo_triplejackpot" : pupevent 754
        Case Else DMD CL(0, FormatScore(tmp)), CL(1, "JACKPOT X" & WitchMBMultiplier(n)), "", eBlinkFast, eNone, eNone, 1500, True, "Fanfare9"
    End Select
    AddScore tmp
    AddJackpot 150000
    LightEffect 2
    Flasheffect 2
End Sub

Sub AwardSkillshot()
    ResetSkillShotTimer_Timer
    'show dmd animation
    DMD CL(0, FormatScore(SkillshotValue(CurrentPlayer))), CL(1, ("SKILLSHOT")), "", eBlinkFast, eNone, eNone, 1500, True, "fanfare2" : pupevent 834
    DOF 127, DOFPulse
    Addscore SkillShotValue(CurrentPlayer)
    ' increment the skillshot value with 1 Million
    SkillShotValue(CurrentPlayer) = SkillShotValue(CurrentPlayer) + 1000000
    'do some light show
    GiEffect 2
    LightEffect 2
End Sub

Sub AwardSuperSkillshot()
    ResetSkillShotTimer_Timer
    'show dmd animation
    DMD CL(0, FormatScore(SuperSkillshotValue(CurrentPlayer))), CL(1, ("SUPER SKILLSHOT")), "", eBlinkFast, eNone, eNone, 1500, True, "fanfare3" : pupevent 835
    DOF 127, DOFPulse
    Addscore SuperSkillShotValue(CurrentPlayer)
    ' increment the superskillshot value with 5 Million
    SuperSkillShotValue(CurrentPlayer) = SuperSkillShotValue(CurrentPlayer) + 5000000
    'do some light show
    GiEffect 2
    LightEffect 2
    Flasheffect 2
End Sub

Sub AwardSecretSkillshot(points)
    ResetSkillShotTimer_Timer
    'show dmd animation
    DMD CL(0, FormatScore(points)), CL(1, ("SECRET SKILLSHOT")), "", eBlinkFast, eNone, eNone, 1500, True, "fanfare3" : pupevent 836
    DOF 127, DOFPulse
    Addscore points
    'do some light show
    GiEffect 2
    LightEffect 2
    Flasheffect 2
End Sub

'*****************************
'    Load / Save / Highscore
'*****************************

Sub Loadhs
    Dim x
    x = LoadValue(cGameName, "HighScore1")
    If(x <> "")Then HighScore(0) = CDbl(x)Else HighScore(0) = 100000 End If
    x = LoadValue(cGameName, "HighScore1Name")
    If(x <> "")Then HighScoreName(0) = x Else HighScoreName(0) = "AAA" End If
    x = LoadValue(cGameName, "HighScore2")
    If(x <> "")then HighScore(1) = CDbl(x)Else HighScore(1) = 100000 End If
    x = LoadValue(cGameName, "HighScore2Name")
    If(x <> "")then HighScoreName(1) = x Else HighScoreName(1) = "BBB" End If
    x = LoadValue(cGameName, "HighScore3")
    If(x <> "")then HighScore(2) = CDbl(x)Else HighScore(2) = 100000 End If
    x = LoadValue(cGameName, "HighScore3Name")
    If(x <> "")then HighScoreName(2) = x Else HighScoreName(2) = "CCC" End If
    x = LoadValue(cGameName, "HighScore4")
    If(x <> "")then HighScore(3) = CDbl(x)Else HighScore(3) = 100000 End If
    x = LoadValue(cGameName, "HighScore4Name")
    If(x <> "")then HighScoreName(3) = x Else HighScoreName(3) = "DDD" End If
    x = LoadValue(cGameName, "Credits")
    If(x <> "")then Credits = CInt(x)Else Credits = 0:If bFreePlay = False Then DOF 125, DOFOff:End If
    x = LoadValue(cGameName, "TotalGamesPlayed")
    If(x <> "")then TotalGamesPlayed = CInt(x)Else TotalGamesPlayed = 0 End If
End Sub

Sub Savehs
    SaveValue cGameName, "HighScore1", HighScore(0)
    SaveValue cGameName, "HighScore1Name", HighScoreName(0)
    SaveValue cGameName, "HighScore2", HighScore(1)
    SaveValue cGameName, "HighScore2Name", HighScoreName(1)
    SaveValue cGameName, "HighScore3", HighScore(2)
    SaveValue cGameName, "HighScore3Name", HighScoreName(2)
    SaveValue cGameName, "HighScore4", HighScore(3)
    SaveValue cGameName, "HighScore4Name", HighScoreName(3)
    SaveValue cGameName, "Credits", Credits
    SaveValue cGameName, "TotalGamesPlayed", TotalGamesPlayed
End Sub

Sub Reseths
    HighScoreName(0) = "AAA"
    HighScoreName(1) = "BBB"
    HighScoreName(2) = "CCC"
    HighScoreName(3) = "DDD"
    HighScore(0) = 150000
    HighScore(1) = 140000
    HighScore(2) = 130000
    HighScore(3) = 120000
    Savehs
End Sub

' ***********************************************************
'  High Score Initals Entry Functions - based on Black's code
' ***********************************************************

Dim hsbModeActive
Dim hsEnteredName
Dim hsEnteredDigits(3)
Dim hsCurrentDigit
Dim hsValidLetters
Dim hsCurrentLetter
Dim hsLetterFlash

Sub CheckHighscore()
    Dim tmp
    tmp = Score(1)
    If Score(2)> tmp Then tmp = Score(2)
    If Score(3)> tmp Then tmp = Score(3)
    If Score(4)> tmp Then tmp = Score(4)

    If tmp> HighScore(1)Then 'add 1 credit for beating the highscore
        Credits = Credits + 1
        DOF 125, DOFOn
    End If

    If tmp> HighScore(3)Then
        PlaySound SoundFXDOF("fx_Knocker", 122, DOFPulse, DOFKnocker)
        DOF 121, DOFPulse
        HighScore(3) = tmp
        'enter player's name
        HighScoreEntryInit()
    Else
        EndOfBallComplete()
    End If
End Sub

Sub HighScoreEntryInit()
    hsbModeActive = True
    PlaySound "vo_enterinitials" : pupevent 837
    hsLetterFlash = 0

    hsEnteredDigits(0) = " "
    hsEnteredDigits(1) = " "
    hsEnteredDigits(2) = " "
    hsCurrentDigit = 0

    hsValidLetters = " ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789<" ' ` is back arrow
    hsCurrentLetter = 1
    DMDFlush()
    HighScoreDisplayNameNow()

    HighScoreFlashTimer.Interval = 250
    HighScoreFlashTimer.Enabled = True
End Sub

Sub EnterHighScoreKey(keycode)
    If keycode = LeftFlipperKey Then
        playsound "fx_Previous"
        hsCurrentLetter = hsCurrentLetter - 1
        if(hsCurrentLetter = 0)then
            hsCurrentLetter = len(hsValidLetters)
        end if
        HighScoreDisplayNameNow()
    End If

    If keycode = RightFlipperKey Then
        playsound "fx_Next"
        hsCurrentLetter = hsCurrentLetter + 1
        if(hsCurrentLetter> len(hsValidLetters))then
            hsCurrentLetter = 1
        end if
        HighScoreDisplayNameNow()
    End If

    If keycode = PlungerKey OR keycode = StartGameKey Then
        if(mid(hsValidLetters, hsCurrentLetter, 1) <> "<")then
            playsound "fx_Enter"
            hsEnteredDigits(hsCurrentDigit) = mid(hsValidLetters, hsCurrentLetter, 1)
            hsCurrentDigit = hsCurrentDigit + 1
            if(hsCurrentDigit = 3)then
                HighScoreCommitName()
            else
                HighScoreDisplayNameNow()
            end if
        else
            playsound "fx_Esc"
            hsEnteredDigits(hsCurrentDigit) = " "
            if(hsCurrentDigit> 0)then
                hsCurrentDigit = hsCurrentDigit - 1
            end if
            HighScoreDisplayNameNow()
        end if
    end if
End Sub

Sub HighScoreDisplayNameNow()
    HighScoreFlashTimer.Enabled = False
    hsLetterFlash = 0
    HighScoreDisplayName()
    HighScoreFlashTimer.Enabled = True
End Sub

Sub HighScoreDisplayName()
    Dim i
    Dim TempTopStr
    Dim TempBotStr

    TempTopStr = "YOUR NAME:"
    dLine(0) = ExpandLine(TempTopStr, 0)
    DMDUpdate 0

    TempBotStr = "    > "
    if(hsCurrentDigit> 0)then TempBotStr = TempBotStr & hsEnteredDigits(0)
    if(hsCurrentDigit> 1)then TempBotStr = TempBotStr & hsEnteredDigits(1)
    if(hsCurrentDigit> 2)then TempBotStr = TempBotStr & hsEnteredDigits(2)

    if(hsCurrentDigit <> 3)then
        if(hsLetterFlash <> 0)then
            TempBotStr = TempBotStr & "_"
        else
            TempBotStr = TempBotStr & mid(hsValidLetters, hsCurrentLetter, 1)
        end if
    end if

    if(hsCurrentDigit <1)then TempBotStr = TempBotStr & hsEnteredDigits(1)
    if(hsCurrentDigit <2)then TempBotStr = TempBotStr & hsEnteredDigits(2)

    TempBotStr = TempBotStr & " <    "
    dLine(1) = ExpandLine(TempBotStr, 1)
    DMDUpdate 1
End Sub

Sub HighScoreFlashTimer_Timer()
    HighScoreFlashTimer.Enabled = False
    hsLetterFlash = hsLetterFlash + 1
    if(hsLetterFlash = 2)then hsLetterFlash = 0
    HighScoreDisplayName()
    HighScoreFlashTimer.Enabled = True
End Sub

Sub HighScoreCommitName()
    HighScoreFlashTimer.Enabled = False
    hsbModeActive = False

    hsEnteredName = hsEnteredDigits(0) & hsEnteredDigits(1) & hsEnteredDigits(2)
    if(hsEnteredName = "   ")then
        hsEnteredName = "YOU"
    end if

    HighScoreName(3) = hsEnteredName
    SortHighscore
    EndOfBallComplete()
End Sub

Sub SortHighscore
    Dim tmp, tmp2, i, j
    For i = 0 to 3
        For j = 0 to 2
            If HighScore(j) <HighScore(j + 1)Then
                tmp = HighScore(j + 1)
                tmp2 = HighScoreName(j + 1)
                HighScore(j + 1) = HighScore(j)
                HighScoreName(j + 1) = HighScoreName(j)
                HighScore(j) = tmp
                HighScoreName(j) = tmp2
            End If
        Next
    Next
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

Sub NextLUT:LUTImage = (LUTImage + 1)MOD 22:UpdateLUT:SaveLUT:End Sub

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



' *************************************************************************
'   JP's Reduced Display Driver Functions (based on script by Black)
' only 5 effects: none, scroll left, scroll right, blink and blinkfast
' 3 Lines, treats all 3 lines as text. 3rd line is just 1 character
' Example format:
' DMD "text1","text2","backpicture", eNone, eNone, eNone, 250, True, "sound"
' Short names:
' dq = display queue
' de = display effect
' *************************************************************************

Const eNone = 0        ' Instantly displayed
Const eScrollLeft = 1  ' scroll on from the right
Const eScrollRight = 2 ' scroll on from the left
Const eBlink = 3       ' Blink (blinks for 'TimeOn')
Const eBlinkFast = 4   ' Blink (blinks for 'TimeOn') at user specified intervals (fast speed)

Const dqSize = 64

Dim dqHead
Dim dqTail
Dim deSpeed
Dim deBlinkSlowRate
Dim deBlinkFastRate

Dim dCharsPerLine(2)
Dim dLine(2)
Dim deCount(2)
Dim deCountEnd(2)
Dim deBlinkCycle(2)

Dim dqText(2, 64)
Dim dqEffect(2, 64)
Dim dqTimeOn(64)
Dim dqbFlush(64)
Dim dqSound(64)

Dim FlexDMD
Dim DMDScene

Sub DMD_Init() 'default/startup values
    If UseFlexDMD Then
        Set FlexDMD = CreateObject("FlexDMD.FlexDMD")
        If Not FlexDMD is Nothing Then
            FlexDMD.TableFile = Table1.Filename & ".vpx"
            FlexDMD.RenderMode = 2
		If LCDScreen = False Then
			FlexDMD.Width = 128
			FlexDMD.Height = 32
		End If
		If LCDScreen = True Then
			FlexDMD.Width = 256
			FlexDMD.Height = 64
		End If
	            FlexDMD.Clear = True
	            FlexDMD.GameName = cGameName
	            FlexDMD.Run = True
	            Set DMDScene = FlexDMD.NewGroup("Scene")
	            DMDScene.AddActor FlexDMD.NewImage("Back", "VPX.bkempty")
	            DMDScene.GetImage("Back").SetSize FlexDMD.Width, FlexDMD.Height
	            For i = 0 to 40
	                DMDScene.AddActor FlexDMD.NewImage("Dig" & i, "VPX.dempty&dmd=2")
	                Digits(i).Visible = False
	            Next
	            digitgrid.Visible = False
	            For i = 0 to 19 ' Top
			If LCDScreen = False Then
		                DMDScene.GetImage("Dig" & i).SetBounds 4 + i * 6, 3, 7, 10
			End If
			If LCDScreen = True Then
				DMDScene.GetImage("Dig" & i).SetBounds 8 + i * 12, 6, 14, 20
			End If
        	    Next
	            For i = 20 to 39 ' Bottom
			If LCDScreen = False Then
		                DMDScene.GetImage("Dig" & i).SetBounds 4 + (i - 20) * 6, 3 + 12 + 2, 7, 10
			End If
			If LCDScreen = True Then
				DMDScene.GetImage("Dig" & i).SetBounds 8 + (i - 20) * 12, 34, 14, 20
			End If
	            Next
	            FlexDMD.LockRenderThread
	            FlexDMD.Stage.AddActor DMDScene
	            FlexDMD.UnlockRenderThread
		End If
	End If
    Dim i, j
    DMDFlush()
    deSpeed = 30
    deBlinkSlowRate = 5
    deBlinkFastRate = 2
    dCharsPerLine(0) = 20 'characters lower line
    dCharsPerLine(1) = 20 'characters top line
    dCharsPerLine(2) = 1  'characters back line
    For i = 0 to 2
        dLine(i) = Space(dCharsPerLine(i))
        deCount(i) = 0
        deCountEnd(i) = 0
        deBlinkCycle(i) = 0
        dqTimeOn(i) = 0
        dqbFlush(i) = True
        dqSound(i) = ""
    Next
    For i = 0 to 2
        For j = 0 to 64
            dqText(i, j) = ""
            dqEffect(i, j) = eNone
        Next
    Next
    DMD dLine(0), dLine(1), dLine(2), eNone, eNone, eNone, 25, True, ""
End Sub

Sub DMDFlush()
    Dim i
    DMDTimer.Enabled = False
    DMDEffectTimer.Enabled = False
    dqHead = 0
    dqTail = 0
    For i = 0 to 2
        deCount(i) = 0
        deCountEnd(i) = 0
        deBlinkCycle(i) = 0
    Next
End Sub

Sub DMDScore()
    Dim tmp, tmp1, tmp2
    if(dqHead = dqTail)Then
        tmp = FL(0, "PL " &CurrentPlayer, FormatScore(Score(Currentplayer)))
        tmp1 = CL(1, "SOULS " & Credits & " SOUL " & Balls)
        If bskillshotready Then
            tmp1 = " HIT THE SKILLSHOT"
        ElseIf LoopCount> 0 Then
            tmp1 = CL(1, "SHOOT THE LOOP")
        ElseIf Light050.State then
            tmp1 = CL(1, "SHOOT THE HOLE")
        ElseIf Light008.State then
            tmp1 = CL(1, "LOCK THE SOUL")
        ElseIf bTombTreasureReady Then
            tmp1 = "PLEASURE IS LIT"
        ELSE
            Select Case Mode(CurrentPlayer, 0)
                Case 1:tmp1 = "  PINHEAD MAYHEM" : pupevent 838
                Case 2:tmp1 = "    SOULS MAYHEM" : pupevent 839
                Case 3:tmp1 = "SUFFERING MAYHEM" : pupevent 840
                Case 4:tmp1 = "JULIA AND FRANK" : pupevent 841
                Case 5:tmp1 = "        BUTTERBALL" : pupevent 842
                Case 6:tmp1 = "      CHATTERER" : pupevent 843
                Case 7:tmp1 = "   THE DOCTOR" : pupevent 844
                Case 8:tmp1 = "       DEEPTHROAT" : pupevent 845
                Case 9:tmp1 = "          PINHEAD" : pupevent 846
                Case 10:tmp1 = "COLLECT SOULS LETTER" : pupevent 847
                Case 11:tmp1 = "  PAIN AND PLEASURE" : pupevent 848
                Case 12:tmp1 = "     GOOD SUFFERING" : pupevent 849
            End Select
            tmp2 = ""
        End If
    End If
    DMD tmp, tmp1, tmp2, eNone, eNone, eNone, 25, True, ""
End Sub

Sub DMDScoreNow
    DMDFlush
    DMDScore
End Sub

Sub DMD(Text0, Text1, Text2, Effect0, Effect1, Effect2, TimeOn, bFlush, Sound)
    if(dqTail <dqSize)Then
        if(Text0 = "_")Then
            dqEffect(0, dqTail) = eNone
            dqText(0, dqTail) = "_"
        Else
            dqEffect(0, dqTail) = Effect0
            dqText(0, dqTail) = ExpandLine(Text0, 0)
        End If

        if(Text1 = "_")Then
            dqEffect(1, dqTail) = eNone
            dqText(1, dqTail) = "_"
        Else
            dqEffect(1, dqTail) = Effect1
            dqText(1, dqTail) = ExpandLine(Text1, 1)
        End If

        if(Text2 = "_")Then
            dqEffect(2, dqTail) = eNone
            dqText(2, dqTail) = "_"
        Else
            dqEffect(2, dqTail) = Effect2
            dqText(2, dqTail) = Text2 'it is always 1 letter in this table
        End If

        dqTimeOn(dqTail) = TimeOn
        dqbFlush(dqTail) = bFlush
        dqSound(dqTail) = Sound
        dqTail = dqTail + 1
        if(dqTail = 1)Then
            DMDHead()
        End If
    End If
End Sub

Sub DMDHead()
    Dim i
    deCount(0) = 0
    deCount(1) = 0
    deCount(2) = 0
    DMDEffectTimer.Interval = deSpeed

    For i = 0 to 2
        Select Case dqEffect(i, dqHead)
            Case eNone:deCountEnd(i) = 1
            Case eScrollLeft:deCountEnd(i) = Len(dqText(i, dqHead))
            Case eScrollRight:deCountEnd(i) = Len(dqText(i, dqHead))
            Case eBlink:deCountEnd(i) = int(dqTimeOn(dqHead) / deSpeed)
                deBlinkCycle(i) = 0
            Case eBlinkFast:deCountEnd(i) = int(dqTimeOn(dqHead) / deSpeed)
                deBlinkCycle(i) = 0
        End Select
    Next
    if(dqSound(dqHead) <> "")Then
        PlaySound(dqSound(dqHead))
    End If
    DMDEffectTimer.Enabled = True
End Sub

Sub DMDEffectTimer_Timer()
    DMDEffectTimer.Enabled = False
    DMDProcessEffectOn()
End Sub

Sub DMDTimer_Timer()
    Dim Head
    DMDTimer.Enabled = False
    Head = dqHead
    dqHead = dqHead + 1
    if(dqHead = dqTail)Then
        if(dqbFlush(Head) = True)Then
            DMDScoreNow()
        Else
            dqHead = 0
            DMDHead()
        End If
    Else
        DMDHead()
    End If
End Sub

Sub DMDProcessEffectOn()
    Dim i
    Dim BlinkEffect
    Dim Temp

    BlinkEffect = False

    For i = 0 to 2
        if(deCount(i) <> deCountEnd(i))Then
            deCount(i) = deCount(i) + 1

            select case(dqEffect(i, dqHead))
                case eNone:
                    Temp = dqText(i, dqHead)
                case eScrollLeft:
                    Temp = Right(dLine(i), dCharsPerLine(i)- 1)
                    Temp = Temp & Mid(dqText(i, dqHead), deCount(i), 1)
                case eScrollRight:
                    Temp = Mid(dqText(i, dqHead), (dCharsPerLine(i) + 1)- deCount(i), 1)
                    Temp = Temp & Left(dLine(i), dCharsPerLine(i)- 1)
                case eBlink:
                    BlinkEffect = True
                    if((deCount(i)MOD deBlinkSlowRate) = 0)Then
                        deBlinkCycle(i) = deBlinkCycle(i)xor 1
                    End If

                    if(deBlinkCycle(i) = 0)Then
                        Temp = dqText(i, dqHead)
                    Else
                        Temp = Space(dCharsPerLine(i))
                    End If
                case eBlinkFast:
                    BlinkEffect = True
                    if((deCount(i)MOD deBlinkFastRate) = 0)Then
                        deBlinkCycle(i) = deBlinkCycle(i)xor 1
                    End If

                    if(deBlinkCycle(i) = 0)Then
                        Temp = dqText(i, dqHead)
                    Else
                        Temp = Space(dCharsPerLine(i))
                    End If
            End Select

            if(dqText(i, dqHead) <> "_")Then
                dLine(i) = Temp
                DMDUpdate i
            End If
        End If
    Next

    if(deCount(0) = deCountEnd(0))and(deCount(1) = deCountEnd(1))and(deCount(2) = deCountEnd(2))Then

        if(dqTimeOn(dqHead) = 0)Then
            DMDFlush()
        Else
            if(BlinkEffect = True)Then
                DMDTimer.Interval = 10
            Else
                DMDTimer.Interval = dqTimeOn(dqHead)
            End If

            DMDTimer.Enabled = True
        End If
    Else
        DMDEffectTimer.Enabled = True
    End If
End Sub

Function ExpandLine(TempStr, id) 'id is the number of the dmd line
    If TempStr = "" Then
        TempStr = Space(dCharsPerLine(id))
    Else
        if(Len(TempStr)> Space(dCharsPerLine(id)))Then
            TempStr = Left(TempStr, Space(dCharsPerLine(id)))
        Else
            if(Len(TempStr) <dCharsPerLine(id))Then
                TempStr = TempStr & Space(dCharsPerLine(id)- Len(TempStr))
            End If
        End If
    End If
    ExpandLine = TempStr
End Function

Function FormatScore(ByVal Num) 'it returns a string with commas (as in Black's original font)
    dim i
    dim NumString

    NumString = CStr(abs(Num))

    For i = Len(NumString)-3 to 1 step -3
        if IsNumeric(mid(NumString, i, 1))then
            NumString = left(NumString, i-1) & chr(asc(mid(NumString, i, 1)) + 48) & right(NumString, Len(NumString)- i)
        end if
    Next
    FormatScore = NumString
End function

Function FL(id, NumString1, NumString2) 'Fill line
    Dim Temp, TempStr
    Temp = dCharsPerLine(id)- Len(NumString1)- Len(NumString2)
    TempStr = NumString1 & Space(Temp) & NumString2
    FL = TempStr
End Function

Function CL(id, NumString) 'center line
    Dim Temp, TempStr
    Temp = (dCharsPerLine(id)- Len(NumString)) \ 2
    TempStr = Space(Temp) & NumString & Space(Temp)
    CL = TempStr
End Function

Function RL(id, NumString) 'right line
    Dim Temp, TempStr
    Temp = dCharsPerLine(id)- Len(NumString)
    TempStr = Space(Temp) & NumString
    RL = TempStr
End Function

'**************
' Update DMD
'**************

Sub DMDUpdate(id)
    Dim digit, value
    If UseFlexDMD Then FlexDMD.LockRenderThread
    Select Case id
        Case 0 'top text line
            For digit = 0 to 19
                DMDDisplayChar mid(dLine(0), digit + 1, 1), digit
            Next
        Case 1 'bottom text line
            For digit = 20 to 39
                DMDDisplayChar mid(dLine(1), digit -19, 1), digit
            Next
        Case 2 ' back image - back animations
            If dLine(2) = "" OR dLine(2) = " " Then dLine(2) = "bkempty"
            Digits(40).ImageA = dLine(2)
            If UseFlexDMD Then DMDScene.GetImage("Back").Bitmap = FlexDMD.NewImage("", "VPX." & dLine(2) & "&dmd=2").Bitmap
    End Select
    If UseFlexDMD Then FlexDMD.UnlockRenderThread
End Sub

Sub DMDDisplayChar(achar, adigit)
    If achar = "" Then achar = " "
    achar = ASC(achar)
    Digits(adigit).ImageA = Chars(achar)
    If UseFlexDMD Then DMDScene.GetImage("Dig" & adigit).Bitmap = FlexDMD.NewImage("", "VPX." & Chars(achar) & "&dmd=2&add").Bitmap
End Sub

'****************************
' JP's new DMD using flashers
'****************************

Dim Digits, Chars(255), Images(255)

DMDInit

Sub DMDInit
    Dim i
    Digits = Array(digit001, digit002, digit003, digit004, digit005, digit006, digit007, digit008, digit009, digit010, _
        digit011, digit012, digit013, digit014, digit015, digit016, digit017, digit018, digit019, digit020,            _
        digit021, digit022, digit023, digit024, digit025, digit026, digit027, digit028, digit029, digit030,            _
        digit031, digit032, digit033, digit034, digit035, digit036, digit037, digit038, digit039, digit040,            _
        digit041)
    For i = 0 to 255:Chars(i) = "dempty":Next

    Chars(43) = "dplus"   '+
    Chars(46) = "ddot"    '.
    Chars(48) = "d0"      '0
    Chars(49) = "d1"      '1
    Chars(50) = "d2"      '2
    Chars(51) = "d3"      '3
    Chars(52) = "d4"      '4
    Chars(53) = "d5"      '5
    Chars(54) = "d6"      '6
    Chars(55) = "d7"      '7
    Chars(56) = "d8"      '8
    Chars(57) = "d9"      '9
    Chars(60) = "dless"   '<
    Chars(61) = "dequal"  '=
    Chars(62) = "dmore"   '>
    Chars(64) = "bkempty" '@
    Chars(65) = "da"      'A
    Chars(66) = "db"      'B
    Chars(67) = "dc"      'C
    Chars(68) = "dd"      'D
    Chars(69) = "de"      'E
    Chars(70) = "df"      'F
    Chars(71) = "dg"      'G
    Chars(72) = "dh"      'H
    Chars(73) = "di"      'I
    Chars(74) = "dj"      'J
    Chars(75) = "dk"      'K
    Chars(76) = "dl"      'L
    Chars(77) = "dm"      'M
    Chars(78) = "dn"      'N
    Chars(79) = "do"      'O
    Chars(80) = "dp"      'P
    Chars(81) = "dq"      'Q
    Chars(82) = "dr"      'R
    Chars(83) = "ds"      'S
    Chars(84) = "dt"      'T
    Chars(85) = "du"      'U
    Chars(86) = "dv"      'V
    Chars(87) = "dw"      'W
    Chars(88) = "dx"      'X
    Chars(89) = "dy"      'Y
    Chars(90) = "dz"      'Z
    Chars(94) = "dup"     '^
    '    Chars(95) = '_
    Chars(96) = "d0a"  '0.
    Chars(97) = "d1a"  '1. 'a
    Chars(98) = "d2a"  '2. 'b
    Chars(99) = "d3a"  '3. 'c
    Chars(100) = "d4a" '4. 'd
    Chars(101) = "d5a" '5. 'e
    Chars(102) = "d6a" '6. 'f
    Chars(103) = "d7a" '7. 'g
    Chars(104) = "d8a" '8. 'h
    Chars(105) = "d9a" '9  'i
End Sub

'********************
' Real Time updates
'********************
'used for all the real time updates

Sub Realtime_Timer
    RollingUpdate
    ramp007.heightbottom = Witchflipper.currentangle
' add any other real time update subs, like gates or diverters, flippers
	UpdateCube

End Sub


dim cubeAngle, cubeTargetAngle, cubeAnim, cubeAnimCounter, cubeAnimValue1, cubeAnimValue2, cubeAnimLength
cubeAnimCounter = 0
cubeAnimValue1 = 1
cubeAnimLength = 5
cubeAnimValue2 = 1

dim transCntr : transCntr = 0
dim rotCntr : rotCntr = 0
Const CubeRotSpeed = 1 '1 or 3
Const CubeTransSpeed = 1 '1, 2, 3, 5, 10


sub UpdateCube

	if cubeAnim = 1 Or cubeAnim = 2 Then
		cubeAnimCounter = cubeAnimCounter + cubeAnimValue1
		if cubeAnimCounter => 360 then 
			cubeAnimCounter = cubeAnimCounter - 360
			cubeAnimLength = cubeAnimLength - 1
			if cubeAnimLength = 0 Then
				cubeAnim = 0
				'reset orientation
'				pCube1.Roty = 0		'left this out because it may bug on some cases...
				pCube2.Roty = 0
				pCube1.transy = 0
				cubeAnimCounter = 0
				cubeAnimValue1 = 1
				cubeAnimLength = 10
				cubeAnimValue2 = 1
				cubeflasher.blenddisablelighting = 0
				exit Sub
			end if
		end if

'		cubeAnimValue1 = cubeAnimValue2 * cubeAnimValue1^2
		if cubeAnimValue2 = 1 then
			cubeflasher.blenddisablelighting = 300
			cubeAnimValue1 = cubeAnimValue1 + cubeAnimValue2 * 0.4 * cubeAnimValue1
		Elseif cubeAnimValue2 = 0 then
			if cubeAnimLength = 3 then cubeAnimValue2 = -1
		else
'			debug.print "subs"
			cubeAnimValue1 = cubeAnimValue1 + (cubeAnimValue2 * 0.05)
			if cubeAnimValue1 =< 3 then cubeAnimValue1 = 3
		end if
'		debug.print cubeAnimValue1 & "  dir: " & cubeAnimValue2

		if cubeAnimValue1 > 10 And cubeAnimValue2 = 1 then cubeAnimValue2 = 0	

		if cubeAnim = 1 then
			pCube1.Roty = cubeAnimCounter
			pCube2.Roty = -cubeAnimCounter
		Else
			pCube1.Roty = -cubeAnimCounter
			pCube2.Roty = cubeAnimCounter
		end if
	elseif cubeAnim = 3 Then
		if transCntr = 0 then
			cubeflasher.blenddisablelighting = 300
'			debug.print pCube1.transy & " - ctrl: " & transCntr
			pCube1.transy = pCube1.transy - CubeTransSpeed * 0.4
			if pCube1.transy <= -128 then
				pCube1.transy = -128
				transCntr = 1
			end if
		Elseif transCntr = 1 then
'			debug.print pCube1.Roty & " - ctrl: " & transCntr
			pCube1.Roty = pCube1.Roty + CubeRotSpeed * 0.7
			rotCntr = rotCntr + CubeRotSpeed * 0.7
			if rotCntr >= 45 Then
				transCntr = 2
				rotCntr = 0
			end if
		elseif transCntr = 2 Then
'			debug.print pCube1.transz & " - ctrl: " & transCntr
			pCube1.transy = pCube1.transy + CubeTransSpeed * 0.4
			if pCube1.transy >= 0  Then
				pCube1.transy = 0
				transCntr = 3
			end if
		elseif transCntr >= 3 And transCntr < 100 Then
			transCntr = transCntr + 1
		else
			cubeflasher.blenddisablelighting = 0
'			pCube1.Roty = 0
			pCube2.Roty = 0
			pCube1.transy = 0
			transCntr = 0
			cubeAnim = 0
		end if

	end If
end Sub


'**********************************************************
'     JP's Flasher Fading for VPX original tables
'       (Based on Pacdude's Fading Light System)
'**********************************************************

Dim FadingState(100), FlashLevel(100)

InitLamps() ' turn off the lights and flashers and reset them to the default parameters

Sub LampTimer_Timer()
    Lampm 1, LFlasher001
    Flash 1, flasher001
    Lampm 2, LFlasher002
    Flashm 2, flasher002a
    Flash 2, flasher002
    Lampm 3, LFlasher003
    Flash 3, flasher003
    Lampm 4, LFlasher004
    Flashm 4, flasher004a
    Flashm 4, flasher004b
    Flash 4, flasher004
    Lampm 5, LFlasher005
    Flashm 5, flasher005a
    Flashm 5, flasher005b
    Flash 5, flasher005
    Flash 6, flasher006
    Lampm 7, LFlasher006
    Lampm 7, LFlasher007
    Flashm 7, flasher007
    Flash 7, flasher008
    Lampm 9, LFlasher009
    Flash 9, flasher009
    Lampm 10, LFlasher010
    Flash 10, flasher010
    Lamp 11, ORBLight
    Flashm 12, flasher012a
    Flashm 12, flasher012b
    Flash 12, flasher012
    Flash 13, flasher013
    Flash 14, flasher014
End Sub
Sub InitLamps()
    Dim x
    LampTimer.Interval = 40 ' flasher fading speed
    LampTimer.Enabled = 1
    For x = 0 to 100
        FadingState(x) = 3 ' used to track the fading state
        FlashLevel(x) = 0
    Next
End Sub

Sub SetLamp(nr, value) ' 0 is off, 1 is on
    FadingState(nr) = abs(value) + 3
End Sub

Sub SetFlash(MyLamp, nr, TotalPeriod, BlinkPeriod) 'similar to FlashForms, works on all kind of objects with the fading light systems
    Dim steps
    ' Store all blink information
    steps = (TotalPeriod / BlinkPeriod + .5) \ 2 'Number of ON/OFF steps to perform
    steps = steps + nr / 100                     'steps + fading lights number
    MyLamp.UserValue = steps                     'Store # of blinks & Lamp number

    ' Start the flasher timer
    MyLamp.TimerInterval = BlinkPeriod
    MyLamp.TimerEnabled = 0
    MyLamp.TimerEnabled = 1
    ExecuteGlobal "Sub " & MyLamp.Name & "_Timer:" & "SetLamp 100 * (me.UserValue - INT(me.UserValue)), me.UserValue MOD 2:me.UserValue= me.UserValue -1:If me.UserValue < 0 then Me.TimerEnabled=0:End If:End Sub"
End Sub

' standard VPX objects

' Lights: used for VPX standard lights,
' the fading is handled by VPX itself,
' they are here to be able to make them work together with the flashers

Sub Lamp(nr, object)
    Select Case FadingState(nr)
        Case 4:object.state = 1:FadingState(nr) = 0
        Case 3:object.state = 0:FadingState(nr) = 0
    End Select
End Sub

Sub Lampm(nr, object) ' used for multiple lights, it doesn't change the fading state
    Select Case FadingState(nr)
        Case 4:object.state = 1
        Case 3:object.state = 0
    End Select
End Sub

' Flashers: 4 is on,3,2,1 fade steps. 0 is off

Sub Flash(nr, object)
    Select Case FadingState(nr)
        Case 4:Object.IntensityScale = 1:FadingState(nr) = 0
        Case 3:Object.IntensityScale = 0.66:FadingState(nr) = 2
        Case 2:Object.IntensityScale = 0.33:FadingState(nr) = 1
        Case 1:Object.IntensityScale = 0:FadingState(nr) = 0
    End Select
End Sub

Sub Flashm(nr, object) 'multiple flashers, it doesn't change the fading state
    Select Case FadingState(nr)
        Case 4:Object.IntensityScale = 1
        Case 3:Object.IntensityScale = 0.66
        Case 2:Object.IntensityScale = 0.33
        Case 1:Object.IntensityScale = 0
    End Select
End Sub

' Desktop Objects: Reels & texts (you may also use lights on the desktop)

' Reels

Sub Reel(nr, object)
    Select Case FadingState(nr)
        Case 4:object.SetValue 1:FadingState(nr) = 0
        Case 3:object.SetValue 2:FadingState(nr) = 2
        Case 2:object.SetValue 3:FadingState(nr) = 1
        Case 1:object.SetValue 0:FadingState(nr) = 0
    End Select
End Sub

Sub Reelm(nr, object)
    Select Case FadingState(nr)
        Case 4:object.SetValue 1
        Case 3:object.SetValue 2
        Case 2:object.SetValue 3
        Case 1:object.SetValue 0
    End Select
End Sub

'Texts

Sub Text(nr, object, message)
    Select Case FadingState(nr)
        Case 4:object.Text = message:FadingState(nr) = 0
        Case 3:object.Text = "":FadingState(nr) = 0
    End Select
End Sub

Sub Textm(nr, object, message)
    Select Case FadingState(nr)
        Case 4:object.Text = message
        Case 3:object.Text = ""
    End Select
End Sub

'Walls and mostly Primitives used as 4 step fading lights
'a,b,c,d are the images used from on to off

Sub FadeObj(nr, object, a, b, c, d)
    Select Case FadingState(nr)
        Case 4:object.image = a:FadingState(nr) = 0 'fading to off...
        Case 3:object.image = b:FadingState(nr) = 2
        Case 2:object.image = c:FadingState(nr) = 1
        Case 1:object.image = d:FadingState(nr) = 0
    End Select
End Sub

Sub FadeObjm(nr, object, a, b, c, d)
    Select Case FadingState(nr)
        Case 4:object.image = a
        Case 3:object.image = b
        Case 2:object.image = c
        Case 1:object.image = d
    End Select
End Sub

Sub NFadeObj(nr, object, a, b)
    Select Case FadingState(nr)
        Case 4:object.image = a:FadingState(nr) = 0 'off
        Case 3:object.image = b:FadingState(nr) = 0 'on
    End Select
End Sub

Sub NFadeObjm(nr, object, a, b)
    Select Case FadingState(nr)
        Case 4:object.image = a
        Case 3:object.image = b
    End Select
End Sub

'********************************************************************************************
' Only for VPX 10.2 and higher.
' FlashForMs will blink light or a flasher for TotalPeriod(ms) at rate of BlinkPeriod(ms)
' When TotalPeriod done, light or flasher will be set to FinalState value where
' Final State values are:   0=Off, 1=On, 2=Return to previous State
' the flashers do not work if are using the fading lights system, use SetFlash instead
'********************************************************************************************

Sub FlashForMs(MyLight, TotalPeriod, BlinkPeriod, FinalState) 'thanks gtxjoe for the first version

    If TypeName(MyLight) = "Light" Then

        If FinalState = 2 Then
            FinalState = MyLight.State 'Keep the current light state
        End If
        MyLight.BlinkInterval = BlinkPeriod
        MyLight.Duration 2, TotalPeriod, FinalState
    ElseIf TypeName(MyLight) = "Flasher" Then

        Dim steps

        ' Store all blink information
        steps = Int(TotalPeriod / BlinkPeriod + .5) 'Number of ON/OFF steps to perform
        If FinalState = 2 Then                      'Keep the current flasher state
            FinalState = ABS(MyLight.Visible)
        End If
        MyLight.UserValue = steps * 10 + FinalState 'Store # of blinks, and final state

        ' Start blink timer and create timer subroutine
        MyLight.TimerInterval = BlinkPeriod
        MyLight.TimerEnabled = 0
        MyLight.TimerEnabled = 1
        ExecuteGlobal "Sub " & MyLight.Name & "_Timer:" & "Dim tmp, steps, fstate:tmp=me.UserValue:fstate = tmp MOD 10:steps= tmp\10 -1:Me.Visible = steps MOD 2:me.UserValue = steps *10 + fstate:If Steps = 0 then Me.Visible = fstate:Me.TimerEnabled=0:End if:End Sub"
    End If
End Sub

'******************************************
' Change light color - simulate color leds
' changes the light color and state
' 10 colors: red, orange, amber, yellow...
'******************************************

Dim red, orange, amber, yellow, darkgreen, green, blue, darkblue, purple, white

red = 10
orange = 9
amber = 8
yellow = 7
darkgreen = 6
green = 5
blue = 4
darkblue = 3
purple = 2
white = 1

Sub SetLightColor(n, col, stat) ' n = light, col = color, stat 0, 1, 2 or -1 to do not change the light state
    Select Case col
        Case 0
            n.color = RGB(18, 0, 0)
            n.colorfull = RGB(255, 0, 0)
        Case red
            n.color = RGB(32, 0, 0)
            n.colorfull = RGB(224, 0, 0)
        Case orange
            n.color = RGB(18, 3, 0)
            n.colorfull = RGB(255, 64, 0)
        Case amber
            n.color = RGB(193, 49, 0)
            n.colorfull = RGB(255, 153, 0)
        Case yellow
            n.color = RGB(18, 18, 0)
            n.colorfull = RGB(255, 255, 0)
        Case darkgreen
            n.color = RGB(0, 8, 0)
            n.colorfull = RGB(0, 64, 0)
        Case green
            n.color = RGB(0, 16, 0)
            n.colorfull = RGB(0, 128, 0)
        Case blue
            n.color = RGB(0, 18, 18)
            n.colorfull = RGB(0, 255, 255)
        Case darkblue
            n.color = RGB(0, 4, 18)
            n.colorfull = RGB(0, 64, 64)
        Case purple
            n.color = RGB(64, 0, 96)
            n.colorfull = RGB(128, 0, 192)
        Case white
            n.color = RGB(255, 252, 224)
            n.colorfull = RGB(193, 91, 0)
    End Select
    If stat <> -1 Then
        n.State = 0
        n.State = stat
    End If
End Sub

'*************************
' Rainbow Changing Lights
'*************************

Dim RGBStep, RGBFactor, rRed, rGreen, rBlue, RainbowLights

Sub StartRainbow(n) 'uses a collection as parameter
    set RainbowLights = n
    RGBStep = 0
    RGBFactor = 5
    rRed = 255
    rGreen = 0
    rBlue = 0
    RainbowTimer.Enabled = 1
End Sub

Sub StopRainbow()
    RainbowTimer.Enabled = 0
    For each x in aLightArrows
        SetLightColor x, white, 0
    Next
End Sub

Sub RainbowTimer_Timer 'rainbow led light color changing
    Dim obj
    Select Case RGBStep
        Case 0 'Green
            rGreen = rGreen + RGBFactor
            If rGreen> 255 then
                rGreen = 255
                RGBStep = 1
            End If
        Case 1 'Red
            rRed = rRed - RGBFactor
            If rRed <0 then
                rRed = 0
                RGBStep = 2
            End If
        Case 2 'Blue
            rBlue = rBlue + RGBFactor
            If rBlue> 255 then
                rBlue = 255
                RGBStep = 3
            End If
        Case 3 'Green
            rGreen = rGreen - RGBFactor
            If rGreen <0 then
                rGreen = 0
                RGBStep = 4
            End If
        Case 4 'Red
            rRed = rRed + RGBFactor
            If rRed> 255 then
                rRed = 255
                RGBStep = 5
            End If
        Case 5 'Blue
            rBlue = rBlue - RGBFactor
            If rBlue <0 then
                rBlue = 0
                RGBStep = 0
            End If
    End Select
    For each obj in RainbowLights
        obj.color = RGB(rRed \ 10, rGreen \ 10, rBlue \ 10)
        obj.colorfull = RGB(rRed, rGreen, rBlue)
    Next
End Sub

' ********************************
'   Table info & Attract Mode
' ********************************

Sub ShowTableInfo
    Dim ii
    'info goes in a loop only stopped by the credits and the startkey
    If Score(1)Then
        DMD CL(0, "LAST SCORE"), CL(1, "VICTIM 1 " &FormatScore(Score(1))), "", eNone, eNone, eNone, 3000, False, ""
    End If
    If Score(2)Then
        DMD CL(0, "LAST SCORE"), CL(1, "VICTIM 2 " &FormatScore(Score(2))), "", eNone, eNone, eNone, 3000, False, ""
    End If
    If Score(3)Then
        DMD CL(0, "LAST SCORE"), CL(1, "VICTIM 3 " &FormatScore(Score(3))), "", eNone, eNone, eNone, 3000, False, ""
    End If
    If Score(4)Then
        DMD CL(0, "LAST SCORE"), CL(1, "VICTIM 4 " &FormatScore(Score(4))), "", eNone, eNone, eNone, 3000, False, ""
    End If
    DMD "", "", "gameover", eNone, eNone, eBlink, 1500, False, ""
    If bFreePlay Then
        DMD "", CL(1, "FREE PLAY"), "", eNone, eBlink, eNone, 1500, False, ""
    Else
        If Credits> 0 Then
            DMD CL(0, "SOULS " & Credits), CL(1, "PRESS START"), "", eNone, eBlink, eNone, 1500, False, ""
        Else
            DMD CL(0, "SOULS " & Credits), CL(1, "INSERT SOULS"), "", eNone, eBlink, eNone, 1500, False, ""
        End If
    End If
    DMD "", "", "jppresents", eNone, eNone, eNone, 3000, False, ""
    DMD "", "", "magodeoz", eNone, eNone, eNone, 4000, False, ""
    DMD CL(0, "HIGHSCORES"), Space(dCharsPerLine(1)), "", eScrollLeft, eScrollLeft, eNone, 20, False, ""
    DMD CL(0, "HIGHSCORES"), "", "", eBlinkFast, eNone, eNone, 1000, False, ""
    DMD CL(0, "HIGHSCORES"), "1> " &HighScoreName(0) & " " &FormatScore(HighScore(0)), "", eNone, eScrollLeft, eNone, 1500, False, ""
    DMD "_", "2> " &HighScoreName(1) & " " &FormatScore(HighScore(1)), "", eNone, eScrollLeft, eNone, 1500, False, ""
    DMD "_", "3> " &HighScoreName(2) & " " &FormatScore(HighScore(2)), "", eNone, eScrollLeft, eNone, 1500, False, ""
    DMD "_", "4> " &HighScoreName(3) & " " &FormatScore(HighScore(3)), "", eNone, eScrollLeft, eNone, 1500, False, ""
    DMD Space(dCharsPerLine(0)), Space(dCharsPerLine(1)), "", eScrollLeft, eScrollLeft, eNone, 500, False, ""
End Sub

Sub StartAttractMode
    GiOff
    StartLightSeq
    DMDFlush
    ShowTableInfo
    StartRainbow aLightArrows
    AttractTimer.Enabled = 1
End Sub

Sub AttractTimer_Timer
    Dim tmp
    tmp = INT(RND * 5)
    Select Case tmp
        Case 0:PlaySound "vo_itsgotime"
        Case 1:PlaySound "vo_pushplay"
        Case 2:PlaySound "vo_pushstart"
        Case 3:PlaySound "vo_pushstartbutton"
        Case 4:PlaySound "vo_comeon"
    End Select
End Sub

Sub StopAttractMode
    GiOn
    DMDScoreNow
    LightSeqAttract.StopPlay
    StopRainbow
    AttractTimer.Enabled = 0
End Sub

Sub StartLightSeq()
    'lights sequences
    LightSeqAttract.UpdateInterval = 25
    LightSeqAttract.Play SeqBlinking, , 5, 150
    LightSeqAttract.Play SeqRandom, 40, , 4000
    LightSeqAttract.Play SeqAllOff
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqUpOn, 50, 1
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqDownOn, 25, 1
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqCircleOutOn, 15, 2
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqUpOn, 25, 1
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqDownOn, 25, 1
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqUpOn, 25, 1
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqDownOn, 25, 1
    LightSeqAttract.UpdateInterval = 10
    LightSeqAttract.Play SeqCircleOutOn, 15, 3
    LightSeqAttract.UpdateInterval = 5
    LightSeqAttract.Play SeqRightOn, 50, 1
    LightSeqAttract.UpdateInterval = 5
    LightSeqAttract.Play SeqLeftOn, 50, 1
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqRightOn, 50, 1
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqLeftOn, 50, 1
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqRightOn, 40, 1
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqLeftOn, 40, 1
    LightSeqAttract.UpdateInterval = 10
    LightSeqAttract.Play SeqRightOn, 30, 1
    LightSeqAttract.UpdateInterval = 10
    LightSeqAttract.Play SeqLeftOn, 30, 1
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqRightOn, 25, 1
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqLeftOn, 25, 1
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqRightOn, 15, 1
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqLeftOn, 15, 1
    LightSeqAttract.UpdateInterval = 10
    LightSeqAttract.Play SeqCircleOutOn, 15, 3
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqLeftOn, 25, 1
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqRightOn, 25, 1
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqLeftOn, 25, 1
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqUpOn, 25, 1
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqDownOn, 25, 1
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqUpOn, 25, 1
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqDownOn, 25, 1
    LightSeqAttract.UpdateInterval = 5
    LightSeqAttract.Play SeqStripe1VertOn, 50, 2
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqCircleOutOn, 15, 2
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqStripe1VertOn, 50, 3
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqLeftOn, 25, 1
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqRightOn, 25, 1
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqLeftOn, 25, 1
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqUpOn, 25, 1
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqDownOn, 25, 1
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqCircleOutOn, 15, 2
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqStripe2VertOn, 50, 3
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqLeftOn, 25, 1
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqRightOn, 25, 1
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqLeftOn, 25, 1
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqUpOn, 25, 1
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqDownOn, 25, 1
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqUpOn, 25, 1
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqDownOn, 25, 1
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqStripe1VertOn, 25, 3
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqStripe2VertOn, 25, 3
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqUpOn, 15, 1
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqDownOn, 15, 1
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqUpOn, 15, 1
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqDownOn, 15, 1
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqUpOn, 15, 1
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqDownOn, 15, 1
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqRightOn, 15, 1
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqLeftOn, 15, 1
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqRightOn, 15, 1
    LightSeqAttract.UpdateInterval = 8
    LightSeqAttract.Play SeqLeftOn, 15, 1
End Sub

Sub LightSeqAttract_PlayDone()
    StartLightSeq()
End Sub

Sub LightSeqTilt_PlayDone()
    LightSeqTilt.Play SeqAllOff
End Sub

Sub LightSeqSkillshot_PlayDone()
    LightSeqSkillshot.Play SeqAllOff
End Sub

'***********************************************************************
' *********************************************************************
'                     Table Specific Script Starts Here
' *********************************************************************
'***********************************************************************

' droptargets, animations, etc
Sub VPObjects_Init
    post001.IsDropped = 1
    post002.IsDropped = 1
    post003.IsDropped = 1
    post004.IsDropped = 1
    post005.IsDropped = 1
    bruja_target1.IsDropped = 1
End Sub

' tables variables and Mode init
Dim Mode(4, 15) '4 players, 15 posible modes
Dim WitchMultiplier
Dim BrujaLetter(4)
Dim NewMode
Dim bILUSSIASJP
Dim ILUSSIATimes(4)
Dim ILUSSIACount(4)
Dim bAddaBall
Dim AddaBallCount
Dim AddaBallLevel
Dim bAddaBallActivated
Dim DropCount
Dim DropPos(4)
Dim DropValue(4)
Dim DropBankValue(4)
Dim bMystery
Dim MysteryLevel(4)
Dim BallsLocked(4)
Dim bLockActive(4)
Dim bWitchMBJackpotReady
Dim bWitchMBFirstHit
Dim WitchMBMultiplier(8)
Dim WitchMBArrowCount
Dim SuperSpinnersCount(4)
Dim SuperPopsCount(4)
Dim SuperRampsCount(4)
Dim SuperTargetsCount(4)
Dim SuperOrbitsCount(4)
Dim bSuperSpinners(4)
Dim bSuperPops(4)
Dim bSuperRamps(4)
Dim bSuperTargets(4)
Dim bSuperOrbits(4)
Dim SuperPyramidValue
Dim SuperPyramidMultiplier
Dim bSPJActivated
Dim bFinisterraMBReady
Dim FinisterraSJPValue(4)
Dim bFinisterraSJPActivated
Dim FinisterraSJPMultiplier
Dim FinisterraSJPCount
Dim FinisterraDifficulty
Dim PFxCount
Dim PFxActivated
Dim FolkCount
Dim HechizoCount
Dim HechizoSpinnerValue
Dim ArbolesCount
Dim ArbolesJPValue
Dim ArbolesSJPCount
Dim ArbolesStep
Dim AtlantiaCount
Dim AtlantiaTimerCount
Dim CelticValue
Dim CelticMultiplier
Dim CelticTimerCount
Dim ManchaXanandraHitCount
Dim ManchaXanandraTimerCount
Dim LoopValue
Dim LoopJackpot(4)
Dim LoopJackpotMulti
Dim LoopCount
Dim ExtraBallCount(4)
Dim MiniLoopMulti
Dim BallSaveCount
Dim bComboActivated
Dim Combo(6)
Dim ComboCount
Dim ComboValue
Dim bSuperCombo
Dim SwitchBonusCount 'to bonus
Dim IlussiaBonusCount
Dim DeathblowBonusCount
Dim LoopsBonusCount
Dim PyramidBonusCount
Dim ManchaXBonusCount
Dim SlingshotValue
Dim TombTreasureCount
Dim bTombTreasureReady
Dim LeftTombHits(4)
Dim LeftTombHits2(4)
Dim RightTombHits(4)
Dim FNCStep
Dim bLDDFSJPEnabled

Sub Game_Init() 'called at the start of a new game
    Dim i, j
    bExtraBallWonThisBall = False
    TurnOffPlayfieldLights()
    'Play some Music

    'Init Variables
    For i = 0 to 4
        For j = 0 to 15
            Mode(i, j) = 0
        Next
    Next
    For i = 0 to 4
        Jackpot(i) = 1000000
        SuperJackpot(i) = 5000000
        SkillshotValue(i) = 1000000
        SuperSkillshotValue(i) = 5000000
        BrujaLetter(i) = 0
        ILUSSIATimes(i) = 0
        ILUSSIACount(i) = 4
        BallsLocked(i) = 0
        bLockActive(i) = False
        DropPos(i) = 1
        SuperSpinnersCount(i) = 0
        SuperPopsCount(i) = 0
        SuperRampsCount(i) = 0
        SuperTargetsCount(i) = 0
        SuperOrbitsCount(i) = 0
        bSuperSpinners(i) = 0 '0 not started, 2 started, 1 completed, corresponds to the light states
        bSuperPops(i) = 0
        bSuperRamps(i) = 0
        bSuperTargets(i) = 0
        bSuperOrbits(i) = 0
        FinisterraSJPValue(i) = 4000000
        ExtraBallCount(i) = 0
        LoopJackpot(i) = 1000000
        DropValue(i) = 50000
        DropBankValue(i) = 250000
        MysteryLevel(i) = 1
        LeftTombHits(i) = 0
        LeftTombHits2(i) = 0
        RightTombHits(i) = 0
    Next
    For i = 0 to 8
        WitchMBMultiplier(i) = 1
    Next
    WitchMultiplier = 1
    BallSaverTime = 20
    bILUSSIASJP = False
    bAddaBall = False
    AddaBallCount = 0
    AddaBallLevel = 0
    bAddaBallActivated = False
    ResetDrop
    bMystery = False
    CheckLockedBalls
    bWitchMBJackpotReady = False
    WitchMBArrowCount = 0
    bWitchMBFirstHit = True
    SuperPyramidValue = 0
    SuperPyramidMultiplier = 0
    bSPJActivated = False
    bFinisterraMBReady = false
    bFinisterraSJPActivated = false
    FinisterraSJPMultiplier = 1
    FinisterraSJPCount = 0
    FinisterraDifficulty = 1
    PFxCount = 0
    PFxActivated = 0
    NewMode = INT(RND * 5) + 4
    FolkCount = 0
    HechizoCount = 0
    HechizoSpinnerValue = 0
    ArbolesCount = 0
    ArbolesJPValue = 1000000
    ArbolesSJPCount = 0
    ArbolesStep = 0
    CelticValue = 2000000
    LoopValue = 250000
    LoopCount = 0
    MiniLoopMulti = 1
    LoopJackpotMulti = 1
    BallSaveCount = 0
    bComboActivated = False
    Combo(1) = 0
    Combo(2) = 0
    Combo(3) = 0
    Combo(4) = 0
    Combo(5) = 0
    Combo(6) = 0
    ComboCount = 0
    ComboValue = 500000
    bSuperCombo = False
    TombTreasureCount = 0
    bTombTreasureReady = False
    FNCStep = 0
    bLDDFSJPEnabled = False

'Init Delays/Timers
'MainMode Init()
'Init lights
End Sub

Sub InstantInfo
    Dim tmp
    DMD CL(0, "INSTANT INFO"), "", "", eNone, eNone, eNone, 800, False, ""
    DMD CL(0, "JACKPOT VALUE"), CL(1, Jackpot(CurrentPlayer)), "", eNone, eNone, eNone, 800, False, ""
    DMD CL(0, "SPR JACKPOT VALUE"), CL(1, SuperJackpot(CurrentPlayer)), "", eNone, eNone, eNone, 800, False, ""
    DMD CL(0, "SUFFERING JACKPOT"), CL(1, FinisterraSJPValue(Currentplayer)), "", eNone, eNone, eNone, 800, False, ""
    tmp = FormatScore(SuperPyramidValue) & " X " & SuperPyramidMultiplier
    DMD CL(0, "HELL AWARD VALUE"), CL(1, tmp), "", eNone, eNone, eNone, 800, False, ""
    DMD CL(0, "BONUS X"), CL(1, BonusMultiplier(CurrentPlayer)), "", eNone, eNone, eNone, 800, False, ""
    DMD CL(0, "PLAYFIELD X"), CL(1, PlayfieldMultiplier(CurrentPlayer)), "", eNone, eNone, eNone, 800, False, ""
    DMD CL(0, "HIGHEST SCORE"), CL(1, HighScoreName(0) & " " & HighScore(0)), "", eNone, eNone, eNone, 800, False, ""
End Sub

Sub StopMultiballModes 'called at the end of multiball
    Select case Mode(CurrentPLayer, 0)
        Case 1:StopILUSSIA:StartBRUJAletter
        Case 2:StopWitchMultiball:StartBRUJAletter
        Case 3:StopFinisterra:StartBRUJALEtter
        Case 4: 'no multi-ball
        Case 5: 'no multi-ball
        Case 6:StopFoltergeist:ResetBRUJALetter:StartBRUJAletter
        Case 7: 'no multi-ball
        Case 8:StopArboles:ResetBRUJALetter:StartBRUJALetter
        Case 9: 'no multi-ball
        Case 11:StopFNC:StartBRUJALetter
        Case 12:StartBRUJALetter
    End Select
End Sub

Sub StopEndOfBallMode() 'this sub is called after the last ball is drained, reset skillshot, modes, timers
    Dim tmp
    tmp = INT(RND * 16)
    Select Case tmp
        Case 0:PlaySound "vo_dobetterthanthat"
        Case 1:PlaySound "vo_hahaha"
        Case 2, 12:PlaySound "vo_hahaha2"
        Case 3, 13:PlaySound "vo_hahaha3"
        Case 4, 14:PlaySound "vo_hohoho"
        Case 5, 15:PlaySound "vo_hohoho2"
        Case 6:PlaySound "vo_keepitup"
        Case 7:PlaySound "vo_firsttime"
        Case 8:PlaySound "vo_lookatthatscore"
        Case 9:PlaySound "vo_notbad"
        Case 10:PlaySound "vo_notbad2"
        Case 11:PlaySound "vo_flippers"
        case 12:PlaySound "vo_notagoodplayer"
    End Select
    If bSkillShotReady Then ResetSkillShotTimer_Timer
    If bAddaBallActivated Then StopAddaBall
    Select case Mode(CurrentPLayer, 0)
        Case 4:StopCelticLand:ResetBRUJALetter
        Case 5:StopHechizo:ResetBRUJALetter
        Case 7:StopAtlantia:ResetBRUJALetter
        Case 9:StopManchaXanandra:ResetBRUJALetter
    End Select
    BrujaFlasher.Enabled = 0
    StopSuperPyramid
    post005_Timer
End Sub

Sub StopCurrentMode 'called during Tomb awards
    Select case Mode(CurrentPLayer, 0)
        Case 1:StopILUSSIA
        Case 2:StopWitchMultiball
        Case 3:StopFinisterra
        Case 4:StopCelticLand
        Case 5:StopHechizo
        Case 6:StopFoltergeist
        Case 7:StopAtlantia
        Case 8:StopArboles
        Case 9:StopManchaXanandra
    End Select
End Sub

Sub ResetNewBallVariables() 'reset variables for a new ball or player
    'reset the Super features if all are completed
    If(bSuperPops(CurrentPlayer) = 1)AND(bSuperSpinners(CurrentPlayer) = 1)AND(bSuperRamps(CurrentPlayer) = 1)AND(bSuperTargets(CurrentPlayer) = 1)AND(bSuperOrbits(CurrentPlayer) = 1)Then
        ResetPyramid
    Else
        UpdateSuperPyramid
    End If
    StopCombo
    'bonus counts
    SwitchBonusCount = 0
    IlussiaBonusCount = 0
    DeathblowBonusCount = 0
    LoopsBonusCount = 0
    PyramidBonusCount = 0
    ManchaXBonusCount = 0
    SlingshotValue = 10210
    bSuperCombo = False
    bTombTreasureReady = False
    post003.IsDropped = 1
    post004.IsDropped = 1
    post005.IsDropped = 1
End Sub

Sub ResetNewBallLights() 'turn on or off the needed lights before a new ball is released
    StopRainbow          ' Set Arrow lights to white and turn them off
    UpdatePFXLights      'ensure the multiplier is displayed right
    UpdateBrujaLetter
    UpdateILUSSIA
    SetLightColor Light057, white, 0
    Light058.State = 0
    Light050.State = 0
    Light008.State = 0
    Light005.State = 2
    RampDown
    ResetPFxTargetLights
    CheckLockedBalls
    If ExtraBallCount(CurrentPlayer) >= 30 then 'lit Extra Ball
        light047.State = 1
    End If
End Sub

Sub TurnOffPlayfieldLights()
    Dim a
    For each a in aLights
        a.State = 0
    Next
End Sub

Sub UpdateSkillShot() 'Setup and updates the skillshot lights
    LightSeqSkillshot.Play SeqAllOff
    Light048.State = 2
    Light051.State = 2
End Sub

Sub ResetSkillShotTimer_Timer 'timer to reset the skillshot lights & variables
    ResetSkillShotTimer.Enabled = 0
    bSkillShotReady = False
    LightSeqSkillshot.StopPlay
    Light048.State = 0
    Light051.State = 0
    DMDScoreNow
    StartBRUJAletter
End Sub

'***********************
' Crows follow the ball
'***********************
' they do not move during multiball

Sub CrowPos_Hit(idx)
    If NOT bMultiBallMode Then
        CrowLeft.Rotz = -(idx * 2)-16
'        CrowRight.RotZ = idx * 2 + 16
'		pCube1.Roty = idx * 2 + 16
'		pCube2.Roty = -(idx * 2 + 16)
    End If
End Sub



' *********************************************************************
'                        Table Object Hit Events
'
' Any target hit Sub will follow this:
' - play a sound
' - do some physical movement
' - add a score, bonus
' - check some variables/Mode this trigger is a member of
' - set the "LastSwitchHit" variable in case it is needed later
' *********************************************************************

'*********************************************************
' Slingshots has been hit

Dim LStep, RStep

Sub LeftSlingShot_Slingshot
    If Tilted Then Exit Sub
    If bSkillShotReady Then
        ResetSkillShotTimer_Timer
    End If
    PlaySoundAt SoundFXDOF("fx_slingshot", 103, DOFPulse, DOFcontactors), Lemk
    DOF 105, DOFPulse
    LeftSling004.Visible = 1
    Lemk.RotX = 26
    LStep = 0
    LeftSlingShot.TimerEnabled = True
    ' add some points
    AddScore SlingshotValue
    ' add some effect to the table?
    SetFlash Flasher009, 9, 2000, 50
    ' check modes
    StopCombo
    ' remember last trigger hit by the ball
    LastSwitchHit = "LeftSlingShot"
End Sub

Sub LeftSlingShot_Timer
    Select Case LStep
        Case 1:LeftSLing004.Visible = 0:LeftSLing003.Visible = 1:Lemk.RotX = 14
        Case 2:LeftSLing003.Visible = 0:LeftSLing002.Visible = 1:Lemk.RotX = 2
        Case 3:LeftSLing002.Visible = 0:Lemk.RotX = -10:LeftSlingShot.TimerEnabled = 0
    End Select
    LStep = LStep + 1
End Sub

Sub RightSlingShot_Slingshot
    If Tilted Then Exit Sub
    If bSkillShotReady Then
        ResetSkillShotTimer_Timer
    End If
    PlaySoundAt SoundFXDOF("fx_slingshot", 104, DOFPulse, DOFcontactors), Remk
    DOF 106, DOFPulse
    RightSling004.Visible = 1
    Remk.RotX = 26
    RStep = 0
    RightSlingShot.TimerEnabled = True
    ' add some points
    AddScore SlingshotValue
    ' add some effect to the table?
    SetFlash Flasher010, 10, 2000, 50
    ' check modes
    StopCombo
    ' remember last trigger hit by the ball
    LastSwitchHit = "RightSlingShot"
End Sub

Sub RightSlingShot_Timer
    Select Case RStep
        Case 1:RightSLing004.Visible = 0:RightSLing003.Visible = 1:Remk.RotX = 14
        Case 2:RightSLing003.Visible = 0:RightSLing002.Visible = 1:Remk.RotX = 2
        Case 3:RightSLing002.Visible = 0:Remk.RotX = -10:RightSlingShot.TimerEnabled = 0
    End Select
    RStep = RStep + 1
End Sub

'*********
' Bumpers
'*********

Sub Bumper1_Hit
    If Tilted Then Exit Sub
    PlaySoundAt SoundFXDOF("fx_bumper",113,DOFPulse,DOFContactors), Bumper1
    DOF 128, DOFPulse
    Flashforms LBumper1, 2000, 50, 0
    ' add some points
    Addscore 125000 + 125000 * bSuperPops(CurrentPlayer)
    ' check for modes
    StopCombo
    Select Case Mode(CurrentPlayer, 0)
        Case 3 'simply lit the super bumpers light
            light024.State = 1
            CheckFinisterra
    End Select
    If Mode(CurrentPlayer, 0) <> 3 AND bSuperPops(CurrentPlayer) <> 1 Then 'this if it is not finished
        SuperPopsCount(CurrentPlayer) = SuperPopsCount(CurrentPlayer) + 1
        If SuperPopsCount(CurrentPlayer) = 30 * FinisterraDifficulty Then
            bSuperPops(CurrentPlayer) = 2 'this means it is activated
            Select case Balls
                Case 1:DMD "", "", "superpopsislit", eNone, eNone, eBlink, 1500, True, "vo_bumpers" : pupevent 850
                Case 2:DMD "", "", "superpopsislit", eNone, eNone, eBlink, 1500, True, "vo_superbumperarelit" : pupevent 851
                Case 3:DMD "", "", "superpopsislit", eNone, eNone, eBlink, 1500, True, "vo_superbumperarelit2" : pupevent 851
            End Select
            UpdateSuperPyramid
            SuperPyramidValue = SuperPyramidValue + 1500000 * FinisterraDifficulty
        ElseIf SuperPopsCount(CurrentPlayer)> 30 * FinisterraDifficulty Then 'add more points to the SP jackpot
            SuperPyramidValue = SuperPyramidValue + 75000 * FinisterraDifficulty
        End If
    End If

    ' remember last trigger hit by the ball
    LastSwitchHit = "Bumper1"
End Sub

Sub Bumper2_Hit
    If Tilted Then Exit Sub
    PlaySoundAt SoundFXDOF("fx_bumper",115,DOFPulse,DOFContactors), Bumper2
    DOF 130, DOFPulse
    Flashforms LBumper2, 2000, 50, 0
    ' add some points
    Addscore 125000 + 125000 * bSuperPops(CurrentPlayer)
    ' check for modes
    StopCombo
    Select Case Mode(CurrentPlayer, 0)
        Case 3 'simply lit the super bumpers light
            light024.State = 1
            CheckFinisterra
    End Select
    If Mode(CurrentPlayer, 0) <> 3 AND bSuperPops(CurrentPlayer) <> 1 Then 'this if it is not finished
        SuperPopsCount(CurrentPlayer) = SuperPopsCount(CurrentPlayer) + 1
        If SuperPopsCount(CurrentPlayer) = 30 * FinisterraDifficulty Then
            bSuperPops(CurrentPlayer) = 2 'this means it is activated
            Select case Balls
                Case 1:DMD "", "", "superpopsislit", eNone, eNone, eBlink, 1500, True, "vo_bumpers" : pupevent 850
                Case 2:DMD "", "", "superpopsislit", eNone, eNone, eBlink, 1500, True, "vo_superbumperarelit" : pupevent 851
                Case 3:DMD "", "", "superpopsislit", eNone, eNone, eBlink, 1500, True, "vo_superbumperarelit2" : pupevent 851
            End Select
            UpdateSuperPyramid
            SuperPyramidValue = SuperPyramidValue + 1500000 * FinisterraDifficulty
        ElseIf SuperPopsCount(CurrentPlayer)> 30 * FinisterraDifficulty Then 'add more points to the SP jackpot
            SuperPyramidValue = SuperPyramidValue + 75000 * FinisterraDifficulty
        End If
    End If

    ' remember last trigger hit by the ball
    LastSwitchHit = "Bumper2"
End Sub

Sub Bumper3_Hit
    If Tilted Then Exit Sub
    PlaySoundAt SoundFXDOF("fx_bumper",114,DOFPulse,DOFContactors), Bumper3
    DOF 129, DOFPulse
    Flashforms LBumper3, 2000, 50, 0
    ' add some points
    Addscore 125000 + 125000 * bSuperPops(CurrentPlayer)
    ' check for modes
    StopCombo
    Select Case Mode(CurrentPlayer, 0)
        Case 3 'simply lit the super bumpers light
            light024.State = 1
            CheckFinisterra
    End Select
    If Mode(CurrentPlayer, 0) <> 3 AND bSuperPops(CurrentPlayer) <> 1 Then 'this if it is not finished
        SuperPopsCount(CurrentPlayer) = SuperPopsCount(CurrentPlayer) + 1
        If SuperPopsCount(CurrentPlayer) = 30 * FinisterraDifficulty Then
            bSuperPops(CurrentPlayer) = 2 'this means it is activated
            Select case Balls
                Case 1:DMD "", "", "superpopsislit", eNone, eNone, eBlink, 1500, True, "vo_bumpers" : pupevent 850
                Case 2:DMD "", "", "superpopsislit", eNone, eNone, eBlink, 1500, True, "vo_superbumperarelit" : pupevent 851
                Case 3:DMD "", "", "superpopsislit", eNone, eNone, eBlink, 1500, True, "vo_superbumperarelit2" : pupevent 851
            End Select
            UpdateSuperPyramid
            SuperPyramidValue = SuperPyramidValue + 1500000 * FinisterraDifficulty
        ElseIf SuperPopsCount(CurrentPlayer)> 30 * FinisterraDifficulty Then 'add more points to the SP jackpot
            SuperPyramidValue = SuperPyramidValue + 75000 * FinisterraDifficulty
        End If
    End If

    ' remember last trigger hit by the ball
    LastSwitchHit = "Bumper3"
End Sub

'*************************
'      Triggers
'*************************

Sub aSwitches_Hit(idx) 'stop skillshot if any switch is hit
    'debug.print idx
    If bSkillShotReady Then
        ResetSkillShotTimer_Timer
    End If
End Sub

Sub Trigger001_Hit 'Left outlane
    PlaySoundAt "fx_sensor", Trigger001
    If Tilted Then Exit Sub
    Addscore 25000
    ' check for modes
    StopCombo
    If bSkillShotReady Then
        AwardSecretSkillshot 20000000
        AddPlayfieldMultiplier 2
        BallSaverTime = BallSaverTime + 10
    End If
    ' remember last trigger hit by the ball
    LastSwitchHit = "Trigger001"
End Sub

Sub Trigger002_Hit 'Left inlane
    PlaySoundAt "fx_sensor", Trigger002
    If Tilted Then Exit Sub
    Addscore 25000
    'PFx
    If light001.State Then
        PFxActivated = 1
        pfxtimer.Enabled = 1
        UpdatePFxLights
        light001.State = 0
    End If
    ' check for modes
    If bSkillShotReady Then
        AwardSecretSkillshot 5000000
        AddPlayfieldMultiplier 2
        BallSaverTime = BallSaverTime + 10
    End If
    ' remember last trigger hit by the ball
    LastSwitchHit = "Trigger002"
End Sub

Sub Trigger003_Hit 'Right inlane
    PlaySoundAt "fx_sensor", Trigger003
    If Tilted Then Exit Sub
    Addscore 25000
    'PFx
    If light002.State Then
        PFxActivated = 1
        pfxtimer.Enabled = 1
        UpdatePFxLights
        light002.State = 0
    End If
    ' check for modes
    ' remember last trigger hit by the ball
    LastSwitchHit = "Trigger003"
End Sub

Sub Trigger004_Hit 'Right outlane
    PlaySoundAt "fx_sensor", Trigger004
    If Tilted Then Exit Sub
    Addscore 25000
    ' check for modes
    StopCombo
    ' remember last trigger hit by the ball
    LastSwitchHit = "Trigger004"
End Sub

Sub Trigger005_Hit 'Start Right Orbit
    PlaySoundAt "fx_sensor", Trigger005
    If Tilted Then Exit Sub
    SetFlash Flasher002, 2, 2000, 100
    DOF 203, DOFPulse
    Addscore 330
    ' check for modes
    ' remember last trigger hit by the ball
    LastSwitchHit = "Trigger005"
End Sub

Sub Trigger012_Hit 'Mini Loop
    PlaySoundAt "fx_sensor", Trigger012
    If Tilted Then Exit Sub
    Addscore 330
    ' check for modes
    ' remember last trigger hit by the ball
    LastSwitchHit = "Trigger012"
End Sub

Sub Trigger006_Hit 'Right Orbit, opto
    If Tilted Then Exit Sub
    GiEffect 1
    MiniLoopMulti = 1
    Addscore 125000
    'loops, skillshots, addaballs
    LoopsBonusCount = LoopsBonusCount + 1
    If LastSwitchHit = "Trigger005" Then
        CheckCombo 6
        If bSkillShotReady Then
            AwardSecretSkillshot 6000000
            AddPlayfieldMultiplier 2
            BallSaverTime = BallSaverTime + 10
        End If
        If bAddaBall AND Light052.State = 2 Then
            AddaBallCount = AddaBallCount + 1
            Light052.State = 0
            CheckAddaBall
        End If
        CheckLoop
    End If
    If LastSwitchHit = "Trigger012" Then
        CheckCombo 4
        If bAddaBall AND Light049.State = 2 Then
            AddaBallCount = AddaBallCount + 1
            Light049.State = 0
            CheckAddaBall
        End If
        MiniLoopMulti = 3
        CheckLoop
    End If
    If LastSwitchHit = "Trigger007" Then
        CheckCombo 3
        If bAddaBall AND Light056.State = 2 Then
            AddaBallCount = AddaBallCount + 1
            Light056.State = 0
            CheckAddaBall
        End If
    End If
    If LastSwitchHit = "Trigger013" Then
        CheckCombo 2
        If bAddaBall AND Light055.State = 2 Then
            AddaBallCount = AddaBallCount + 1
            Light055.State = 0
            CheckAddaBall
        End If
        CheckLoop
    End If
    ' check for modes
    Select Case Mode(CurrentPlayer, 0)
        Case 10
            If LastSwitchHit = "Trigger005" AND Light052.State Then
                Light052.State = 0
                AddBRUJALetter 1
            End If
            If LastSwitchHit = "Trigger012" AND Light049.State Then
                Light049.State = 0
                AddBRUJALetter 1
            End If
            If LastSwitchHit = "Trigger007" AND Light056.State Then
                Light056.State = 0
                AddBRUJALetter 1
            End If
            If LastSwitchHit = "Trigger013" AND Light055.State Then
                Light055.State = 0
                AddBRUJALetter 1
            End If
        Case 2
            If LastSwitchHit = "Trigger005" AND Light052.State Then
                AwardJackpot_WitchArrow 7
                Light052.State = 0
                If WitchMBMultiplier(7) <5 Then
                    WitchMBMultiplier(7) = WitchMBMultiplier(7) + 1
                End If
                WitchMBArrowCount = WitchMBArrowCount + 1
                If WitchMBArrowCount> 2 Then
                    light051.State = 2
                    DMD "", "", "superjackpotislit", eNone, eNone, eBlink, 1500, True, "vo_superjackpotislit"  : pupevent 852'enabled SJP
                End If
            End If
            If LastSwitchHit = "Trigger012" AND Light049.State Then
                AwardJackpot_WitchArrow 5
                Light049.State = 0
                If WitchMBMultiplier(5) <5 Then
                    WitchMBMultiplier(5) = WitchMBMultiplier(5) + 1
                End If
                WitchMBArrowCount = WitchMBArrowCount + 1
                If WitchMBArrowCount> 2 Then
                    light051.State = 2
                    DMD "", "", "superjackpotislit", eNone, eNone, eBlink, 1500, True, "vo_superjackpotislit" : pupevent 852'enabled SJP
                End If
            End If
            If LastSwitchHit = "Trigger007" AND Light056.State Then
                AwardJackpot_WitchArrow 3
                Light056.State = 0
                If WitchMBMultiplier(3) <5 Then
                    WitchMBMultiplier(3) = WitchMBMultiplier(3) + 1
                End If
                WitchMBArrowCount = WitchMBArrowCount + 1
                If WitchMBArrowCount> 2 Then
                    light051.State = 2
                    DMD "", "", "superjackpotislit", eNone, eNone, eBlink, 1500, True, "vo_superjackpotislit" : pupevent 852 'enabled SJP
                End If
            End If
            If LastSwitchHit = "Trigger013" AND Light055.State Then
                AwardJackpot_WitchArrow 2
                Light055.State = 0
                If WitchMBMultiplier(2) <5 Then
                    WitchMBMultiplier(2) = WitchMBMultiplier(2) + 1
                End If
                WitchMBArrowCount = WitchMBArrowCount + 1
                If WitchMBArrowCount> 2 Then
                    light051.State = 2
                    DMD "", "", "superjackpotislit", eNone, eNone, eBlink, 1500, True, "vo_superjackpotislit" : pupevent 852 'enabled SJP
                End If
            End if
        Case 3
            'simply lit the super light
            light027.State = 1
            CheckFinisterra
        Case 5
            If LastSwitchHit = "Trigger013" AND Light055.State Then
                HechizoSpinnerValue = 350000
                CheckHechizo
            End If
            If LastSwitchHit = "Trigger012" AND Light049.State Then
                HechizoSpinnerValue = 500000
                CheckHechizo
            End If
        Case 6
            If LastSwitchHit = "Trigger005" AND Light052.State Then
                Light052.State = 0
                CheckFolkCount
            End If
            If LastSwitchHit = "Trigger012" AND Light049.State Then
                Light049.State = 0
                CheckFolkCount
            End If
            If LastSwitchHit = "Trigger007" AND Light056.State Then
                Light056.State = 0
                CheckFolkCount
            End If
            If LastSwitchHit = "Trigger013" AND Light055.State Then
                Light055.State = 0
                CheckFolkCount
            End If
        Case 7
            If LastSwitchHit = "Trigger007" AND Light056.State Then
                Light056.State = 0
                Addscore 3000000
                AtlantiaCount = AtlantiaCount + 1
                CheckAtlantia
            End If
            If LastSwitchHit = "Trigger005" AND Light052.State Then
                Light052.State = 0
                Addscore 3000000
                AtlantiaCount = AtlantiaCount + 1
                CheckAtlantia
            End If
        Case 8
            If LastSwitchHit = "Trigger005" AND Light052.State Then
                Light052.State = 0
                Addscore ArbolesJPValue
                ArbolesCount = ArbolesCount + 1
                CheckArboles
            End If
            If LastSwitchHit = "Trigger013" AND Light055.State Then
                Light055.State = 0
                Addscore ArbolesJPValue
                ArbolesCount = ArbolesCount + 1
                CheckArboles
            End If
            If LastSwitchHit = "Trigger007" AND Light056.State Then
                Light056.State = 0
                Addscore ArbolesJPValue
                ArbolesCount = ArbolesCount + 1
                CheckArboles
            End If
        Case 9
            If LastSwitchHit = "Trigger007" AND Light056.State Then
                Light056.State = 0
                Addscore 1000000
                DMD "", "", "1million", eNone, eNone, eBlink, 1500, True, "vo_1million"  : pupevent 853
                CheckManchaXanandra
            End If
            If LastSwitchHit = "Trigger005" AND Light052.State Then
                Light052.State = 0
                Addscore 1000000
                DMD "", "", "1million", eNone, eNone, eBlink, 1500, True, "vo_1million"  : pupevent 853
                CheckManchaXanandra
            End If
        Case 11
            If LastSwitchHit = "Trigger005" AND Light052.State Then
                If Light052.State = 2 Then 'change blinking red to lit green
                    SetLightColor Light052, Green, 1
                    CheckFNC
                ElseIf Light052.State = 1 Then 'Change from green to blinking red
                    SetLightColor Light052, Red, 2
                End If
            End If
            If LastSwitchHit = "Trigger012" AND Light049.State Then
                If Light049.State = 2 Then 'change blinking red to lit green
                    SetLightColor Light049, Green, 1
                    CheckFNC
                ElseIf Light049.State = 1 Then 'Change from green to blinking red
                    SetLightColor Light049, Red, 2
                End If
            End If
            If LastSwitchHit = "Trigger007" AND Light056.State Then
                If Light056.State = 2 Then 'change blinking red to lit green
                    SetLightColor Light056, Green, 1
                    CheckFNC
                ElseIf Light056.State = 1 Then 'Change from green to blinking red
                    SetLightColor Light056, Red, 2
                End If
            End If
            If LastSwitchHit = "Trigger013" AND Light055.State Then
                If Light055.State = 2 Then 'change blinking red to lit green
                    SetLightColor Light055, Green, 1
                    CheckFNC
                ElseIf Light055.State = 1 Then 'Change from green to blinking red
                    SetLightColor Light055, Red, 2
                End If
            End If
        Case 12
            If LastSwitchHit = "Trigger005" AND Light052.State Then
                Light052.State = 0
                AwardJackpot
                CheckLDDF
            End If
            If LastSwitchHit = "Trigger012" AND Light049.State Then
                Light049.State = 0
                AwardJackpot
                CheckLDDF
            End If
            If LastSwitchHit = "Trigger007" AND Light056.State Then
                Light056.State = 0
                AwardJackpot
                CheckLDDF
            End If
            If LastSwitchHit = "Trigger013" AND Light055.State Then
                Light055.State = 0
                AwardJackpot
                CheckLDDF
            End If
    End Select
    ' active on all modes but Finisterra
    If Mode(CurrentPlayer, 0) <> 3 AND bSuperOrbits(CurrentPlayer) <> 1 Then 'this if it is not finished
        SuperOrbitsCount(CurrentPlayer) = SuperOrbitsCount(CurrentPlayer) + 1
        If SuperOrbitsCount(CurrentPlayer) = 10 * FinisterraDifficulty Then
            bSuperOrbits(CurrentPlayer) = 2 'this means it is activated
            DMD "", "", "superorbitsislit", eNone, eNone, eBlink, 1500, True, "vo_superorbitsarelit"
            UpdateSuperPyramid
            SuperPyramidValue = SuperPyramidValue + 1500000 * FinisterraDifficulty
        ElseIf SuperOrbitsCount(CurrentPlayer)> 10 * FinisterraDifficulty Then 'add more points to the SP jackpot
            SuperPyramidValue = SuperPyramidValue + 125000 * FinisterraDifficulty
        End If
    End If

    ' remember last trigger hit by the ball
    LastSwitchHit = "Trigger006"
End Sub

Sub Trigger007_Hit 'Center Orbit, opto
    If Tilted Then Exit Sub
    Addscore 330
    ' check for modes
    ' remember last trigger hit by the ball
    LastSwitchHit = "Trigger007"
End Sub

Sub Trigger008_Hit 'Left ramp done
    If Tilted Then Exit Sub
    Addscore 125000 : pupevent 755
    SetFlash flasher004, 4, 3000, 60
    DOF 205, DOFPulse
    ' check for modes
    CheckCombo 1
    ' Tomb Treasure
    If bTombTreasureReady = False Then
        LeftTombHits(CurrentPlayer) = (LeftTombHits(CurrentPlayer) + 1)MOD 5
        If LeftTombHits(CurrentPlayer) = 0 Then StartTombTreasure
        Else
            AwardTombTreasure
    End If
    'Modes
    Select Case Mode(CurrentPlayer, 0)
        Case 10
            If light054.State Then
                light054.State = 0
                AddBRUJALetter 1
            End If
            If bLockActive(CurrentPlayer)Then
                DMD "", "", "lockislit", eNone, eNone, eBlink, 1500, True, "vo_lockislit" : pupevent 854
                light008.State = 2
                RampUp
            End If
        Case 1
            If bAddaBall AND Light054.State = 2 Then
                AddaBallCount = AddaBallCount + 1
                Light054.State = 0
                CheckAddaBall
            End If
        Case 2
            If Light054.State Then
                AwardJackpot_WitchArrow 1
                Light054.State = 0
                If WitchMBMultiplier(1) <5 Then
                    WitchMBMultiplier(1) = WitchMBMultiplier(1) + 1
                End If
                WitchMBArrowCount = WitchMBArrowCount + 1
                If WitchMBArrowCount> 2 Then
                    light051.State = 2
                    DMD "", "", "superjackpotislit", eNone, eNone, eBlink, 1500, True, "vo_superjackpotislit" : pupevent 852'enabled SJP
                End If
            End If
        Case 3 'simply lit the super light
            light028.State = 1
            CheckFinisterra
        Case 4
            If Light054.State Then
                DMD "JULIA FRANK COMBO", CL(1, FormatScore(CelticValue) & " X " & CelticMultiplier), "", eNone, eBlink, eNone, 1500, True, "" : pupevent 855
                light054.State = 0
                light053.State = 2
                AddScore CelticValue * CelticMultiplier
                CelticValue = CelticValue + 150000
                CelticMultiplier = CelticMultiplier + 1
                CelticCombo.Enabled = 0
                CelticCombo.Enabled = 1
            Else
                DMD "JULIA FRANK RAMPSHOT", CL(1, FormatScore(CelticValue)), "", eNone, eBlink, eNone, 1500, True, "" : pupevent 856
                AddScore CelticValue
                CelticValue = CelticValue + 150000
            End If
        Case 5
            If Light054.State Then
                HechizoSpinnerValue = 250000
                CheckHechizo
            End If
        Case 6
            If Light054.State Then
                Light054.State = 0
                CheckFolkCount
            End If
        Case 7
            If Light054.State Then
                Light054.State = 0
                Addscore 3000000
                AtlantiaCount = AtlantiaCount + 1
                CheckAtlantia
            End If
        Case 8
            If Light054.State Then
                Light054.State = 0
                Addscore ArbolesJPValue
                ArbolesCount = ArbolesCount + 1
                CheckArboles
            End If
        Case 9
            If Light054.State Then
                Light054.State = 0
                Addscore 1000000
                DMD "", "", "1million", eNone, eNone, eBlink, 1500, True, "vo_1million" : pupevent 853
                CheckManchaXanandra
            End If
        Case 11
            If Light054.State = 2 Then 'change blinking red to lit green
                SetLightColor Light054, Green, 1
                CheckFNC
            ElseIf Light054.State = 1 Then 'Change from green to blinking red
                SetLightColor Light054, Red, 2
            End If
        Case 12
            If Light054.State = 2 Then
                light054.State = 0
                AwardJackpot
                CheckLDDF
            End If
    End Select
    If Mode(CurrentPlayer, 0) <> 3 AND bSuperRamps(CurrentPlayer) <> 1 Then 'this if it is not finished
        SuperRampsCount(CurrentPlayer) = SuperRampsCount(CurrentPlayer) + 1
        If SuperRampsCount(CurrentPlayer) = 10 * FinisterraDifficulty Then
            bSuperRamps(CurrentPlayer) = 2 'this means it is activated
            DMD "", "", "superampsislit", eNone, eNone, eBlink, 1500, True, "vo_superrampsarelit" : pupevent 857
            UpdateSuperPyramid
            SuperPyramidValue = SuperPyramidValue + 1500000 * FinisterraDifficulty
        ElseIf SuperRampsCount(CurrentPlayer)> 10 * FinisterraDifficulty Then 'add more points to the SP jackpot
            SuperPyramidValue = SuperPyramidValue + 125000 * FinisterraDifficulty
        End If
    End If

    ' remember last trigger hit by the ball
    LastSwitchHit = "Trigger008"
End Sub

Sub Trigger009_Hit 'Right ramp done
    If Tilted Then Exit Sub
    SetFlash flasher005, 5, 3000, 60
    DOF 207, DOFPulse
    Addscore 125000 : pupevent 756
    ' check for modes
    CheckCombo 5
    Select Case Mode(CurrentPlayer, 0)
        Case 10:
            If light053.State Then
                light053.State = 0
                AddBRUJALetter 1
            End If
            If bLockActive(CurrentPlayer)Then
                DMD "", "", "lockislit", eNone, eNone, eBlink, 1500, True, "vo_lockislit" : pupevent 854
                light008.State = 2
                RampUp
            End If
        Case 1:
            If bAddaBall AND Light053.State = 2 Then
                AddaBallCount = AddaBallCount + 1
                Light053.State = 0
                CheckAddaBall
            End If
        Case 2:
            If Light053.State Then
                AwardJackpot_WitchArrow 6
                Light053.State = 0
                If WitchMBMultiplier(6) <5 Then
                    WitchMBMultiplier(6) = WitchMBMultiplier(6) + 1
                End If
                WitchMBArrowCount = WitchMBArrowCount + 1
                If WitchMBArrowCount> 2 Then
                    light051.State = 2
                    DMD "", "", "superjackpotislit", eNone, eNone, eBlink, 1500, True, "vo_superjackpotislit"  : pupevent 852'enabled SJP
                End If
            End If
        Case 3: 'simply lit the super light
            light028.State = 1
            CheckFinisterra
        Case 4
            If Light053.State Then
                DMD " JULIA FRANK COMBO", CL(1, FormatScore(CelticValue) & " X " & CelticMultiplier), "", eNone, eBlink, eNone, 1500, True, "" : pupevent 855
                light053.State = 0
                light054.State = 2
                AddScore CelticValue * CelticMultiplier
                CelticValue = CelticValue + 150000
                CelticMultiplier = CelticMultiplier + 1
                CelticCombo.Enabled = 0
                CelticCombo.Enabled = 1
            Else
                DMD "JULIA FRANK RAMPSHOT", CL(1, FormatScore(CelticValue)), "", eNone, eBlink, eNone, 1500, True, "vo_nicerampshot" : pupevent 856
                AddScore CelticValue
                CelticValue = CelticValue + 150000
            End If
        Case 5
            If Light053.State Then
                HechizoSpinnerValue = 250000
                CheckHechizo
            ElseIf light044.State Then
                HechizoSpinnerValue = HechizoSpinnerValue * 2
                DMD CL(0, "SPINNER VALUE"), CL(1, FormatScore(HechizoSpinnerValue)), "", eNone, eNone, eNone, 1500, True, ""
            End If
        Case 6
            If Light053.State Then
                Light053.State = 0
                CheckFolkCount
            End If
        Case 7
            If Light053.State Then
                Light053.State = 0
                Addscore 3000000
                AtlantiaCount = AtlantiaCount + 1
                CheckAtlantia
            End If
        Case 8
            If Light053.State Then
                Light053.State = 0
                Addscore ArbolesJPValue
                ArbolesCount = ArbolesCount + 1
                CheckArboles
            End If
        Case 9
            If Light053.State Then
                Light053.State = 0
                Addscore 1000000
                DMD "", "", "1million", eNone, eNone, eBlink, 1500, True, "vo_1million" : pupevent 853
                CheckManchaXanandra
            End If
        Case 11
            If Light053.State = 2 Then 'change blinking red to lit green
                SetLightColor Light053, Green, 1
                CheckFNC
            ElseIf Light053.State = 1 Then 'Change from green to blinking red
                SetLightColor Light053, Red, 2
            End If
        Case 12
            If Light053.State = 2 Then
                light053.State = 0
                AwardJackpot
                CheckLDDF
            End If
    End Select
    If Mode(CurrentPlayer, 0) <> 3 AND bSuperRamps(CurrentPlayer) <> 1 Then 'this if it is not finished
        SuperRampsCount(CurrentPlayer) = SuperRampsCount(CurrentPlayer) + 1
        If SuperRampsCount(CurrentPlayer) = 10 * FinisterraDifficulty Then
            bSuperRamps(CurrentPlayer) = 2 'this means it is activated
            DMD "", "", "superampsislit", eNone, eNone, eBlink, 1500, True, "vo_superrampsarelit" : pupevent 857
            UpdateSuperPyramid
            SuperPyramidValue = SuperPyramidValue + 1500000 * FinisterraDifficulty
        ElseIf SuperRampsCount(CurrentPlayer)> 10 * FinisterraDifficulty Then 'add more points to the SP jackpot
            SuperPyramidValue = SuperPyramidValue + 125000 * FinisterraDifficulty
        End If
    End If

    ' remember last trigger hit by the ball
    LastSwitchHit = "Trigger007"
End Sub

Sub Trigger013_Hit 'Left Orbit, opto
    If Tilted Then Exit Sub
    Addscore 330
    ' check for modes
    ' remember last trigger hit by the ball
    LastSwitchHit = "Trigger013"
End Sub

'***************
'   Targets
'***************

Sub Target001_hit 'skillshot, X
    PlaySoundAtBall SoundFXDOF("fx_target",107,DOFPulse,DOFTargets)
    If Tilted Then Exit Sub
    CheckDeathblow 1
    Addscore 75000
    If bSkillShotReady Then
        AwardSkillshot
        AddBrujaLetter 1
        BallSaverTime = BallSaverTime + 5
        Exit Sub
    End If
    If light047.State then 'give Extra Ball
        ExtraBallCount(CurrentPLayer) = 0
        light047.State = 0
        AwardExtraBall
    End If
    ' PFx
    If PFxActivated Then PFxSeconds = PFxSeconds + 5
    If light015.State Then
        light015.State = 0
        CheckPFx
    End If
    ' check for modes
    Select Case Mode(CurrentPlayer, 0)
        Case 3
            'simply lit the super light
            light025.State = 1
            CheckFinisterra
    End Select
    If Mode(CurrentPlayer, 0) <> 3 AND bSuperTargets(CurrentPlayer) <> 1 Then 'this if it is not finished
        SuperTargetsCount(CurrentPlayer) = SuperTargetsCount(CurrentPlayer) + 1
        If SuperTargetsCount(CurrentPlayer) = 20 * FinisterraDifficulty Then
            bSuperTargets(CurrentPlayer) = 2 'this means it is activated
            DMD "", "", "supertargetsislit", eNone, eNone, eBlink, 1500, True, "vo_supertargetsarelit" : pupevent 858
            UpdateSuperPyramid
            SuperPyramidValue = SuperPyramidValue + 1500000 * FinisterraDifficulty
        ElseIf SuperTargetsCount(CurrentPlayer)> 20 * FinisterraDifficulty Then 'add more points to the SP jackpot
            SuperPyramidValue = SuperPyramidValue + 75000 * FinisterraDifficulty
        End If
    End If

    ' remember last trigger hit by the ball
    LastSwitchHit = "Target001"
End Sub

Sub Target002_hit 'gravestone
    PlaySoundAtBall SoundFXDOF("fx_target",108,DOFPulse,DOFTargets)
    If Tilted Then Exit Sub
    Addscore 75000
    GiEffect 3
    ' Tomb Treasure
    If bTombTreasureReady = False Then
        LeftTombHits2(CurrentPlayer) = (LeftTombHits2(CurrentPlayer) + 1)MOD 5
        If LeftTombHits2(CurrentPlayer) = 0 Then StartTombTreasure
    End If
    'Spot an X is comming from the left inlane (alley pass)
    If LastSwitchHit = "Trigger002" then
        If light015.State = 2 Then
            light015.State = 0:CheckPFx
        ElseIf light016.State = 2 Then
            light016.State = 0:CheckPFx
        ElseIf light017.State = 2 Then
            light017.State = 0:CheckPFx
        ElseIf light018.State = 2 Then
            light018.State = 0:CheckPFx
        End If
    End If

    ' check for modes
    StopCombo
    Select Case Mode(CurrentPlayer, 0)
        Case 3
            'simply lit the super light
            light025.State = 1
            CheckFinisterra
    End Select
    If Mode(CurrentPlayer, 0) <> 3 AND bSuperTargets(CurrentPlayer) <> 1 Then 'this if it is not finished
        SuperTargetsCount(CurrentPlayer) = SuperTargetsCount(CurrentPlayer) + 1
        If SuperTargetsCount(CurrentPlayer) = 20 * FinisterraDifficulty Then
            bSuperTargets(CurrentPlayer) = 2 'this means it is activated
            DMD "", "", "supertargetsislit", eNone, eNone, eBlink, 1500, True, "vo_supertargetsarelit" : pupevent 858
            UpdateSuperPyramid
            SuperPyramidValue = SuperPyramidValue + 1500000 * FinisterraDifficulty
        ElseIf SuperTargetsCount(CurrentPlayer)> 20 * FinisterraDifficulty Then 'add more points to the SP jackpot
            SuperPyramidValue = SuperPyramidValue + 75000 * FinisterraDifficulty
        End If
    End If

    ' remember last trigger hit by the ball
    LastSwitchHit = "Target002"
End Sub

Sub Target003_hit 'bumpers, X target
    PlaySoundAtBall SoundFXDOF("fx_target",109,DOFPulse,DOFTargets)
    If Tilted Then Exit Sub
    Addscore 75000
    ' PFx
    If PFxActivated Then PFxSeconds = PFxSeconds + 5
    If light016.State Then
        light016.State = 0
        CheckPFx
    End If
    ' check for modes
    StopCombo
    Select Case Mode(CurrentPlayer, 0)
        Case 2
            If Light044.State Then
                AwardJackpot_WitchArrow 0
                Light044.State = 0
                If WitchMBMultiplier(0) <5 Then
                    WitchMBMultiplier(0) = WitchMBMultiplier(0) + 1
                End If
                WitchMBArrowCount = WitchMBArrowCount + 1
                If WitchMBArrowCount> 2 Then
                    light051.State = 2
                    DMD "", "", "superjackpotislit", eNone, eNone, eBlink, 1500, True, "vo_superjackpotislit"  : pupevent 852'enabled SJP
                End If
            End If
        Case 3
            'simply lit the super light
            light025.State = 1
            CheckFinisterra
        Case 6
            If Light044.State Then
                Light044.State = 0
                CheckFolkCount
            End If
    End Select
    If Mode(CurrentPlayer, 0) <> 3 AND bSuperTargets(CurrentPlayer) <> 1 Then 'this if it is not finished
        SuperTargetsCount(CurrentPlayer) = SuperTargetsCount(CurrentPlayer) + 1
        If SuperTargetsCount(CurrentPlayer) = 20 * FinisterraDifficulty Then
            bSuperTargets(CurrentPlayer) = 2 'this means it is activated
            DMD "", "", "supertargetsislit", eNone, eNone, eBlink, 1500, True, "vo_supertargetsarelit" : pupevent 855
            UpdateSuperPyramid
            SuperPyramidValue = SuperPyramidValue + 1500000 * FinisterraDifficulty
        ElseIf SuperTargetsCount(CurrentPlayer)> 20 * FinisterraDifficulty Then 'add more points to the SP jackpot
            SuperPyramidValue = SuperPyramidValue + 75000 * FinisterraDifficulty
        End If
    End If

    ' remember last trigger hit by the ball
    LastSwitchHit = "Target003"
End Sub

Sub Target004_hit 'drop top
    PlaySoundAt SoundFXDOF("fx_droptarget",110,DOFPulse,DOFDropTargets), Target004
    If Tilted Then Exit Sub
    ' check for modes
    StopCombo
    If Mode(CurrentPlayer, 0) = 7 Then
        If Light009.State Then
            Light009.State = 0
            Addscore 3000000
            AtlantiaCount = AtlantiaCount + 1
            CheckAtlantia
        End If
    Else
        Addscore DropValue(CurrentPLayer)
        If DropValue(CurrentPLayer) <100000 Then
            DropValue(CurrentPLayer) = DropValue(CurrentPLayer) + 5000
        End If
        DropCount = DropCount + 1
        CheckDrops
        ' remember last trigger hit by the ball
        LastSwitchHit = "Target004"
    End If
End Sub

Sub Target005_hit 'drop center
    PlaySoundAt SoundFXDOF("fx_droptarget",110,DOFPulse,DOFDropTargets), Target005
    If Tilted Then Exit Sub
    ' check for modes
    StopCombo
    If Mode(CurrentPlayer, 0) = 7 Then
        If Light010.State Then
            Light010.State = 0
            Addscore 3000000
            AtlantiaCount = AtlantiaCount + 1
            CheckAtlantia
        End If
    Else
        Addscore DropValue(CurrentPLayer)
        If DropValue(CurrentPLayer) <100000 Then
            DropValue(CurrentPLayer) = DropValue(CurrentPLayer) + 5000
        End If
        DropCount = DropCount + 1
        CheckDrops
        ' remember last trigger hit by the ball
        LastSwitchHit = "Target005"
    End If
End Sub

Sub Target006_hit 'drop bottom
    PlaySoundAt SoundFXDOF("fx_droptarget",110,DOFPulse,DOFDropTargets), Target006
    If Tilted Then Exit Sub
    ' check for modes
    StopCombo
    If Mode(CurrentPlayer, 0) = 7 Then
        If Light011.State Then
            Light011.State = 0
            Addscore 3000000
            AtlantiaCount = AtlantiaCount + 1
            CheckAtlantia
        End If
    Else
        Addscore DropValue(CurrentPLayer)
        If DropValue(CurrentPLayer) <100000 Then
            DropValue(CurrentPLayer) = DropValue(CurrentPLayer) + 5000
        End If
        DropCount = DropCount + 1
        CheckDrops
        ' remember last trigger hit by the ball
        LastSwitchHit = "Target006"
    End If
End Sub

Sub Target007_hit 'mini loop target, X
    PlaySoundAtBall SoundFXDOF("fx_target",111,DOFPulse,DOFTargets)
    If Tilted Then Exit Sub
    Addscore 75000
    ' PFx
    If PFxActivated Then PFxSeconds = PFxSeconds + 5
    If light017.State Then
        light017.State = 0
        CheckPFx
    End If
    ' check for modes
    StopCombo
    Select Case Mode(CurrentPlayer, 0)
        Case 3
            'simply lit the super light
            light025.State = 1
            CheckFinisterra
    End Select
    If Mode(CurrentPlayer, 0) <> 3 AND bSuperTargets(CurrentPlayer) <> 1 Then 'this if it is not finished
        SuperTargetsCount(CurrentPlayer) = SuperTargetsCount(CurrentPlayer) + 1
        If SuperTargetsCount(CurrentPlayer) = 20 * FinisterraDifficulty Then
            bSuperTargets(CurrentPlayer) = 2 'this means it is activated
            DMD "", "", "supertargetsislit", eNone, eNone, eBlink, 1500, True, "vo_supertargetsarelit" : pupevent 858
            UpdateSuperPyramid
            SuperPyramidValue = SuperPyramidValue + 1500000 * FinisterraDifficulty
        ElseIf SuperTargetsCount(CurrentPlayer)> 20 * FinisterraDifficulty Then 'add more points to the SP jackpot
            SuperPyramidValue = SuperPyramidValue + 75000 * FinisterraDifficulty
        End If
    End If

    ' remember last trigger hit by the ball
    LastSwitchHit = "Target007"
End Sub

Sub Target008_hit 'Superskillshot, X
    PlaySoundAtBall SoundFXDOF("fx_target",111,DOFPulse,DOFTargets)
    If Tilted Then Exit Sub
    Addscore 75000
    SetFlash flasher013, 13, 6000, 50
    DOF 212, DOFPulse
    LightEffect 3
    ' Tomb Treasure
    If bTombTreasureReady = False Then
        RightTombHits(CurrentPlayer) = (RightTombHits(CurrentPlayer) + 1)MOD 5
        If RightTombHits(CurrentPlayer) = 0 Then StartTombTreasure
    End If
    ' PFx
    If PFxActivated Then PFxSeconds = PFxSeconds + 5
    If light018.State Then
        light018.State = 0
        CheckPFx
    End If
    ' check for modes
    CheckDeathblow 5
    If bSkillShotReady Then
        AwardSuperSkillshot
        AddPlayfieldMultiplier 1
        BallSaverTime = BallSaverTime + 10
        Exit Sub
    End If
    Select Case Mode(CurrentPlayer, 0)
        Case 2
            If WitchMBArrowCount> 2 AND Light051.State = 2 Then 'award SJP
                AwardSuperJackpot
                Light051.State = 0
                WitchMBArrowCount = 0
                UpdateArrowColors
            End If
        Case 3
            'simply lit the super light
            light025.State = 1
            CheckFinisterra
        Case 9
            If Light051.State Then
                Light051.State = 0
                AwardSuperJackpot
            End If
    End Select
    If Mode(CurrentPlayer, 0) <> 3 AND bSuperTargets(CurrentPlayer) <> 1 Then 'this if it is not finished
        SuperTargetsCount(CurrentPlayer) = SuperTargetsCount(CurrentPlayer) + 1
        If SuperTargetsCount(CurrentPlayer) = 20 * FinisterraDifficulty Then
            bSuperTargets(CurrentPlayer) = 2 'this means it is activated
            DMD "", "", "supertargetsislit", eNone, eNone, eBlink, 1500, True, "vo_supertargetsarelit" : pupevent 858
            UpdateSuperPyramid
            SuperPyramidValue = SuperPyramidValue + 1500000 * FinisterraDifficulty
        ElseIf SuperTargetsCount(CurrentPlayer)> 20 * FinisterraDifficulty Then 'add more points to the SP jackpot
            SuperPyramidValue = SuperPyramidValue + 75000 * FinisterraDifficulty
        End If
    End If

    ' remember last trigger hit by the ball
    LastSwitchHit = "Target008"
End Sub

Sub Target009_hit 'captive ball target
    PlaySoundAtBall SoundFXDOF("fx_target",112,DOFPulse,DOFTargets)
    If Tilted Then Exit Sub
    SetFlash flasher014, 14, 2000, 60
    DOF 213, DOFPulse
    SetFlash flasher004, 4, 2000, 60
    DOF 206, DOFPulse
    SetFlash flasher005, 5, 2000, 60
    DOF 208, DOFPulse
    GiEffect 3
    ' check for modes
    CheckDeathblow 3
    Addscore 25330
    Select Case Mode(CurrentPlayer, 0)
        Case 10, 1:AddILUSSIAletter
        Case 7
            If Light019.State Then
                Light019.State = 0
                Addscore 5000000
                AtlantiaCount = AtlantiaCount + 1
                CheckAtlantia
            End If
    End Select
    ' remember last trigger hit by the ball
    LastSwitchHit = "Target009"
End Sub

Sub CapWall1_Hit 'Newton ball
    PlaySoundAtBall "fx_collide"
    If Tilted Then Exit Sub
    FlashForms ORBLight, 3000, 60, 0
    CheckDeathblow 2
    Addscore 25000
    ' check for modes
    If bMystery then
        AwardMystery
    ElseIf bAddaBallActivated Then
        AwardAddaBall
    ElseIf bSPJActivated Then
        AwardSPJackpot
    End If
    ' remember last trigger hit by the ball
    LastSwitchHit = "CapWall1"
End Sub

Sub bruja_target_Hit
    PlaySoundAtBall SoundFXDOF("fx_target",124,DOFPulse,DOFShaker)
	pupevent 754
    If Tilted Then Exit Sub
    Dim tmp
    tmp = INT(RND * 15)
    Select Case WitchMultiplier
        Case 0 'weak hit
            Select case tmp
                Case 0, 8, 12:PlaySound "vo_ow"
                Case 1, 9, 13:PlaySound "vo_ow2"
                Case 2, 7, 14:PlaySound "vo_ow4"
                Case 3, 8:PlaySound "vo_terribleaim"
                Case 4, 9:PlaySound "vo_tryscorenow"
                Case 5, 10:PlaySound "vo_youmissedme"
                Case 6, 11:PlaySound "vo_youmissme"
            End Select
        Case 1: 'normal hit
            Select Case tmp
                Case 0, 8, 9:PlaySound "vo_ow3"
                Case 1, 10:PlaySound "vo_blinkinglights"
                Case 2, 11:PlaySound "vo_ohyeah"
                Case 3:PlaySound "vo_sesational"
                Case 4, 12:PlaySound "vo_sweet"
                Case 5:PlaySound "vo_watchwhereyoushoot"
                Case 6, 13:PlaySound "vo_wow2"
                Case 7, 14:PlaySound "vo_younailit"
            End Select
        Case 2: 'Strong hit
            Select Case tmp
                Case 0:PlaySound "vo_blinkinglights2"
                Case 1:PlaySound "vo_breakneck"
                Case 2:PlaySound "vo_rightintheface"
                Case 3:PlaySound "vo_stopdoingthat"
                Case 4:PlaySound "vo_wow"
                Case 5:PlaySound "vo_youaregood"
                Case 6:PlaySound "vo_youareawizard"
                Case 7:PlaySound "vo_youareonfire"
                Case 8:PlaySound "vo_youarethegreatest"
                Case 9:PlaySound "vo_yourule"
                Case 10:PlaySound "vo_dontshootballsatmyface"
                Case 11:PlaySound "vo_dontshootballsatme"
                Case 12:PlaySound "vo_leaveamark"
                Case 13:PlaySound "vo_leaveamark2"
                Case 14:PlaySound "vo_wow"
            End Select
    End Select
    Addscore 25000 * WitchMultiplier
    FlashEffect 1
    'target animation
    bruja_target.IsDropped = 1
    bruja_target1.IsDropped = 0
    bruja_target.TimerEnabled = 1
    ' light show
    Select Case WitchMultiplier
        Case 1:flasher006.Color = RGB(255, 252, 224):SetFlash flasher006, 6, 2000, 100:DOF 209, DOFPulse
        Case 2:flasher006.Color = RGB(255, 128, 0):SetFlash flasher006, 6, 4000, 75:DOF 210, DOFPulse
        Case 3:flasher006.Color = RGB(255, 0, 255):SetFlash flasher006, 6, 6000, 50:DOF 211, DOFPulse
    End Select
    ' check for modes
    CheckDeathblow 4
    Select Case Mode(CurrentPlayer, 0)
        Case 10
            If bSkillShotReady Then
                AwardSecretSkillshot 6000000
                AddPlayfieldMultiplier 2
                BallSaverTime = BallSaverTime + 10
            End If
            If light057.State Then AddBRUJALetter 1
        Case 1
            If bILUSSIASJP Then AwardSuperJackpot_Witch
            If bAddaBall AND Light057.State = 2 Then
                AddaBallCount = AddaBallCount + 1
                Light057.State = 0
                Light058.State = 0
                CheckAddaBall
            End If
        Case 2
            If bWitchMBJackpotReady Then 'droptarget activated jackpot
                AwardJackpot_WitchTarget
                bWitchMBJackpotReady = False
                ' light - flash show
                SetFlash flasher007, 7, 5000, 50
                DOF 214, DOFPulse
                Light058.State = 0
                If bWitchMBFirstHit Then 'if the first hit award add-a-ball
                    bWitchMBFirstHit = False
                    vpmtimer.addtimer 2000, "bruja_AddaBall '"
                End if
            ElseIf Light057.State Then 'arrow jackpot
                AwardJackpot_WitchArrow 4
                Light057.State = 0
                Light058.State = 0
                If WitchMBMultiplier(4) <5 Then
                    WitchMBMultiplier(4) = WitchMBMultiplier(4) + 1
                End If
                WitchMBArrowCount = WitchMBArrowCount + 1
                If WitchMBArrowCount> 2 Then
                    light051.State = 2
                    DMD "", "", "superjackpotislit", eNone, eNone, eBlink, 1500, True, "vo_superjackpotislit" 'enabled SJP
                End If
            End If
        Case 3
            If bFinisterraMBReady Then
                SetFlash flasher007, 7, 6000, 50
                DOF 214, DOFPulse
                Flashforms light058, 6000, 50, 0
                Flashforms light057, 6000, 50, 0
                StartFinisterra
            End If
        Case 6
            If Light057.State Then
                Light057.State = 0
                LastSwitchHit = "bruja_target"
                CheckFolkCount
            End If
        Case 7
            If Light057.State Then
                Light057.State = 0
                WinAtlantia
            End If
        Case 8
            If ArbolesCount = 0 Then
                BrujaFlasher.Enabled = 0
                'stop the counter and lock the value to the Jackpot
                ArbolesTimer1.Enabled = 0
                DMD " JACKPOT VALUE IS", CL(1, FormatScore(ArbolesJPValue)), "", eNone, eBlink, eNone, 1500, True, ""
                ArbolesCount = ArbolesCount + 1
                DMD "_", "  ADD A SOUL IS LIT", "", eNone, eBlink, eNone, 1500, True, "" : pupevent 859
                bAddaBallActivated = True
                Light046.State = 2
                AddMultiball 1
                LightEffect 5
                post001.IsDropped = 0:PlaySoundAt "fx_SolenoidOn", Trigger010
                post002.IsDropped = 0
                vpmtimer.addtimer 2500, "PlaySoundAt""fx_SolenoidOff"", Trigger010: post001.IsDropped = 1:post002.IsDropped = 1 '"
                CheckArboles
            End If
            If ArbolesCount = 6 OR ArbolesCount = 12 Then
                AwardSuperJackpot_Witch
                BrujaFlasher.Enabled = 0
                ArbolesCount = ArbolesCount + 1
                CheckArboles
            End If
        Case 9
            If Light057.State Then
                Light057.State = 0
                Addscore 1000000
                DMD "", "", "1million", eNone, eNone, eBlink, 1500, True, "vo_1million" : pupevent 853
                CheckManchaXanandra
            End If
        Case 11
            If Light057.State = 2 Then 'change blinking red to lit green
                SetLightColor Light057, Green, 1
                CheckFNC
            ElseIf Light057.State = 1 Then 'Change from green to blinking red
                SetLightColor Light057, Red, 2
            End If
        Case 12
            If Light057.State = 2 Then
                light057.State = 0
                AwardJackpot_WitchTarget
                CheckLDDF
            End If
            If bLDDFSJPEnabled Then
                AwardSuperJackpot_Witch
                BrujaFlasher.Enabled = 0
                RestartLDDF
            End If
    End Select

	cubeanim = RndInt(1,3)

    ' remember last trigger hit by the ball
    LastSwitchHit = "bruja_target"
End Sub


Sub Bruja_AddaBall
    DMD "_", CL(1, ("ADD A SOUL")), "", eNone, eBlink, eNone, 1500, True, "vo_addaball" : pupevent 860
    AddMultiball 1
    LightEffect 5
End Sub

Sub bruja_target_Timer
    Me.TimerEnabled = 0
    bruja_target1.IsDropped = 1
    bruja_target.IsDropped = 0
End Sub

Sub Trigger010_Hit 'check the ball speed for Bruja/Witch hit scoring
    Dim tmp
    tmp = ABS(INT(activeball.velY))
    'debug.print tmp
    If tmp <18 Then
        WitchMultiplier = 1
    ElseIf tmp <29 Then
        WitchMultiplier = 2
    Else
        WitchMultiplier = 3
    End If
End Sub

'*****************
'    kickers
'*****************

Sub WitchNest_Hit
    PlaySoundAt "fx_hole_enter", WitchNest
    LightEffect 4
    GiEffect 0
    FlashEffect 4
    If Tilted Then
        vpmtimer.addtimer 1000, "Exit_WitchNest '"
        Exit Sub
    End If
    Addscore 330
    If light050.State Then
        StartBRUJAMode
    Else
        If light008.State Then 'lock is lit
            BallsLocked(CurrentPlayer) = BallsLocked(CurrentPlayer) + 1
            CheckLockedBalls
        End If
    End If
End Sub

Sub Exit_WitchNest
    RampUp 'ensure the ramps is up
    PlaySoundAt "fx_kicker", WitchNest
    WitchNest.kick 179, 18
    vpmtimer.addtimer 800, "RampDown '"
    LightEffect 5
End Sub

'******************************
' MODES: Battles & Multi-balls
'******************************
' Modes(CurrentPlayer), x)
' x being
'0 current running mode number
'values 0: not started, 1 finished, 2 ready to start

'1 Ilussia MB
'2 Witch MB
'3 Finisterra MB - Wizard mode after the Super festures are finished (pops, spinner, ramps...)
'4 Celtic Land
'5 Hechizos Pozimas y Brujerias
'6 Folktergeist
'7 Atlantia
'8 La ciudad de los arboles
'9 Mancha Xanandra - final Wizard mode after Modes 4 to 8 are finished
'10 Bruja letters ' default mode
'11 Feliz Navidad Cabrones - 3rd Tomb Award
'12 La Danza del Fuego - 10th Tomb Award

'********************************
'        Digital clock
'********************************

Dim ClockDigits(4), ClockChars(10)

ClockDigits(0) = Array(a00, a02, a05, a06, a04, a01, a03) 'clock left digit
ClockDigits(1) = Array(a10, a12, a15, a16, a14, a11, a13)
ClockChars(0) = Array(1, 1, 1, 1, 1, 1, 0)                '0
ClockChars(1) = Array(0, 1, 1, 0, 0, 0, 0)                '1
ClockChars(2) = Array(1, 1, 0, 1, 1, 0, 1)                '2
ClockChars(3) = Array(1, 1, 1, 1, 0, 0, 1)                '3
ClockChars(4) = Array(0, 1, 1, 0, 0, 1, 1)                '4
ClockChars(5) = Array(1, 0, 1, 1, 0, 1, 1)                '5
ClockChars(6) = Array(1, 0, 1, 1, 1, 1, 1)                '6
ClockChars(7) = Array(1, 1, 1, 0, 0, 0, 0)                '7
ClockChars(8) = Array(1, 1, 1, 1, 1, 1, 1)                '8
ClockChars(9) = Array(1, 1, 1, 1, 0, 1, 1)                '9

Sub UpdateClock(myTime)
    Dim a, b, i
    a = myTime \ 10
    b = myTime MOD 10
    For i = 0 to 6
        ClockDigits(0)(i).State = ClockChars(a)(i)
        ClockDigits(1)(i).State = ClockChars(b)(i)
    Next
End Sub

Sub TurnOffClock
    Dim i
    For i = 0 to 6
        ClockDigits(0)(i).State = 0
        ClockDigits(1)(i).State = 0
    Next
End Sub
'************************
' Collect BRUJA letters
'************************
' Mode 10, starts as default
' shoot white arrows
' mini loop spots also a letter
' shoot the Witch's Nest to start the battle modes

Sub StartBRUJAletter
    Dim tmp
    Mode(CurrentPlayer, 0) = 10
    SetLightColor light044, White, 1 'spinner
    SetLightColor light054, White, 0 'arrows
    SetLightColor light055, White, 0
    SetLightColor light056, White, 0
    SetLightColor light057, White, 0
    SetLightColor light049, White, 0
    SetLightColor light053, White, 0
    SetLightColor light052, White, 0
    tmp = INT(RND * 7)
    Select Case tmp
        Case 0:light054.State = 2:light052.State = 2
        Case 1:light055.State = 2:light054.State = 2
        Case 2:light056.State = 2:light055.State = 2
        Case 3:light057.State = 2:light056.State = 2:PlaySound "vo_shootflashingarrows"
        Case 4:light049.State = 2:light057.State = 2
        Case 5:light053.State = 2:light049.State = 2
        Case 6:light052.State = 2:light053.State = 2
    End Select
    SelectMode
End Sub

Sub StopBRUJALetter 'turn off the Mode and the arrow lights
    Mode(CurrentPlayer, 0) = 0
    light044.State = 0
    light054.State = 0
    light055.State = 0
    light056.State = 0
    light057.State = 0
    light049.State = 0
    light053.State = 0
    light052.State = 0
End Sub

Sub AddBrujaLetter(n)
    ' if not at the maximum letters
    if(BrujaLetter(CurrentPlayer) + n <= 5)then
        ' then add and set the lights
        BrujaLetter(CurrentPlayer) = BrujaLetter(CurrentPlayer) + n
        DMD "_", "SOULS LETTER AWARD", "", eNone, eBlink, eNone, 1500, True, "Fanfare4"
        StartBRUJAletter ' lit two new lights
    End if
    UpdateBrujaLetter
End Sub

Sub UpdateBrujaLetter
    ' Update the BRUJA lights
    Select Case BrujaLetter(CurrentPlayer)
        Case 0:light064.State = 0:light065.State = 0:light066.State = 0:light067.State = 0:light068.State = 0
        Case 1:light064.State = 1:light065.State = 0:light066.State = 0:light067.State = 0:light068.State = 0
        Case 2:light064.State = 1:light065.State = 1:light066.State = 0:light067.State = 0:light068.State = 0
        Case 3:light064.State = 1:light065.State = 1:light066.State = 1:light067.State = 0:light068.State = 0
        Case 4:light064.State = 1:light065.State = 1:light066.State = 1:light067.State = 1:light068.State = 0
        Case 5:light064.State = 2:light065.State = 2:light066.State = 2:light067.State = 2:light068.State = 2
            Light050.State = 2:Rampup 'ready to start the mode at the Witch's Nest
            ' Stop the Arrows
            light044.State = 0
            light054.State = 0
            light055.State = 0
            light056.State = 0
            light057.State = 0
            light049.State = 0
            light053.State = 0
            light052.State = 0
    End Select
End Sub

Sub ResetBRUJALetter
    BrujaLetter(CurrentPlayer) = 0
    UpdateBrujaLetter
End Sub

Sub SelectMode
    'check if all BRUJA modes are completed
    If Mode(CurrentPLayer, 4) = 1 AND Mode(CurrentPLayer, 5) = 1 AND Mode(CurrentPLayer, 6) = 1 AND Mode(CurrentPLayer, 7) = 1 AND Mode(CurrentPLayer, 8) = 1 Then
        StartManchaXanandra
    Else
        NextMode
    End If
End Sub

Sub NextMode
    'If the last mode was "ready" then release it and go to the next one
    For x = 4 to 8
        If Mode(CurrentPlayer, x) = 2 Then Mode(CurrentPlayer, x) = 0
    Next
    NewMode = ((NewMode -4 + 1)MOD 5) + 4
    'check if the mode is completed and if it is then go to the next mode
    do while Mode(CurrentPlayer, NewMode) <> 0
        NewMode = ((NewMode -4 + 1)MOD 5) + 4
    Loop
    Mode(CurrentPlayer, NewMode) = 2
    UpdateModeLights
End Sub

Sub UpdateModeLights
    light059.State = Mode(CurrentPlayer, 4)
    light060.State = Mode(CurrentPlayer, 5)
    light061.State = Mode(CurrentPlayer, 6)
    light063.State = Mode(CurrentPlayer, 7)
    light062.State = Mode(CurrentPlayer, 8)
End Sub

Sub StartBRUJAMode
    StopBRUJALetter
    Light050.State = 0
    BrujaFlasher.Enabled = 0
    Mode(CurrentPLayer, 0) = NewMode
    Select Case NewMode
        Case 4:StartCelticLand   ' Celtic Land
        Case 5:StartHechizos     ' Hechizos Pozimas y Brujerias
        Case 6:StartFolktergeist ' Folktergeist
        Case 7:StartAtlantia     ' Atlantia
        Case 8:StartArboles      ' La ciudad de los Arboles
    End Select
    vpmtimer.addtimer 2500, "Exit_WitchNest '"
End Sub

Sub BrujaFlasher_Timer
    SetFlash flasher007, 7, 1000, 50
    DOF 215, DOFPulse
    Flashforms light058, 1000, 50, 0
    Flashforms light057, 1000, 50, 0
End Sub

'*******************************
' Mancha Xanandra - wizard mode
'*******************************
' Mode 9
' 60 seconds timed mode, X targets increase time
' complete 5 targets to lit SJP at the witch's pot... and repeat

Sub StartManchaXanandra
    ManchaXBonusCount = ManchaXBonusCount + 1
    DMD "", "", "mancha", eNone, eNone, eBlink, 1500, True, ""
    Mode(CurrentPLayer, 0) = 9
    For X = 0 to 7
        SetLightColor aLightArrows(x), Purple, 0
    Next
    ' 5 arrows
    Light054.State = 2
    Light056.State = 2
    Light057.State = 2
    Light053.State = 2
    Light052.State = 2
    'SJP
    Light051.State = 0
    ManchaXanandraHitCount = 0
    ManchaXanandraTimerCount = 60
    ManchaXanandraTimer.Enabled = 1
    EnableBallSaver 30
    'turn on X lights
    Light016.State = 2
    Light015.State = 2
    Light017.State = 2
    Light018.State = 2
    'Mancha lights
    Light069.State = 1
    Light059.State = 2
    Light060.State = 2
    Light061.State = 2
    Light062.State = 2
    Light063.State = 2
    Light065.State = 2
    Light067.State = 2
    Light066.State = 2
    Light068.State = 2
    Light064.State = 2
End Sub

Sub CheckManchaXanandra
    ManchaXanandraHitCount = ManchaXanandraHitCount + 1
    If ManchaXanandraHitCount MOD 5 = 0 then
        Light051.State = 2                                                                        'SJP
        DMD "", "", "superjackpotislit", eNone, eNone, eBlink, 1500, True, "vo_superjackpotislit"  : pupevent 852'enabled SJP
        'turn on back the arrows
        Light054.State = 2
        Light056.State = 2
        Light057.State = 2
        Light053.State = 2
        Light052.State = 2
    End If
End Sub

Sub StopManchaXanandra 'timer runs out or you lose the ball
    ManchaXanandraTimer.Enabled = 0
    TurnOffClock
    'Mancha lights
    Light069.State = 0
    Light059.State = 0
    Light060.State = 0
    Light061.State = 0
    Light062.State = 0
    Light063.State = 0
    Light065.State = 0
    Light067.State = 0
    Light066.State = 0
    Light068.State = 0
    Light064.State = 0
    'turn on X lights
    Light016.State = 2
    Light015.State = 2
    Light017.State = 2
    Light018.State = 2
    'Reset Modes
    For X = 4 to 9
        Mode(CurrentPLayer, x) = 0
    Next
    ResetBRUJALetter
End Sub

Sub ManchaXanandraTimer_Timer
    ManchaXanandraTimerCount = ManchaXanandraTimerCount - 1
    UpdateClock ManchaXanandraTimerCount
    If ManchaXanandraTimerCount = 10 Then PlaySound "vo_timerunningout" : pupevent 861
    If ManchaXanandraTimerCount = 0 Then
        PlaySound "vo_timeisup" : pupevent 862
        StopManchaXanandra
        ResetBRUJALetter
        StartBRUJALetter
    End If
End Sub

'*******************
'   Celtic Land
'*******************
' Mode 4 - Ramp Combo mode
' shoot as many ramp combos in 40 seconds
' both ramps lit, shoot one to start, shoot as many combos
' each combo add a 1X and 150k to the combo value
' if the combo time runs out you start with 1x, but the value keep increasing with each shot

Sub StartCelticLand
    Dim tmp
    tmp = INT(RND * 4)
    Select Case tmp
        case 0:DMD "", "", "celticland", eNone, eNone, eBlinkFast, 1500, True, "vo_ramps" : pupevent 863
        case 1:DMD "", "", "celticland", eNone, eNone, eBlinkFast, 1500, True, "vo_ramps2" : pupevent 863
        case 2:DMD "", "", "celticland", eNone, eNone, eBlinkFast, 1500, True, "vo_ramps3" : pupevent 863
        case 3:DMD "", "", "celticland", eNone, eNone, eBlinkFast, 1500, True, "vo_ramps4" : pupevent 863
    End Select
    CelticValue = 2000000 '2 Mill
    CelticMultiplier = 1
    CelticTimerCount = 40 'seconds
    CelticTimer.Enabled = 1
    SetLightColor Light054, Red, 2
    SetLightColor Light053, Red, 2
End Sub

Sub StopCelticLand
    Mode(CurrentPLayer, 4) = 1
    TurnOffClock
    CelticTimer.Enabled = 0
    CelticCombo.Enabled = 0
    light053.State = 0
    light054.State = 0
End Sub

Sub CelticCombo_Timer 'reset the combo shots
    light053.State = 2
    light054.State = 2
    CelticMultiplier = 1
End Sub

Sub CelticTimer_Timer '40 seconds
    CelticTimerCount = CelticTimerCount - 1
    UpdateClock CelticTimerCount
    If CelticTimerCount = 0 Then
        StopCelticLand
        ResetBRUJALetter
        StartBRUJALEtter
    End If
End Sub

'*************
'  Atlantia
'*************
' Mode 7 ' hurry up, shoot all orange arrows, the captive ball and the 3 droptargets fisish with a shot to the witch
' 40 seconds, the end score is 1M per second left.

Sub StartAtlantia
    DMD "", "", "atlantia", eNone, eNone, eBlinkFast, 1500, True, "" : pupevent 844
    For X = 0 to 7
        SetLightColor aLightArrows(x), Orange, 0
    Next
    light054.State = 2
    light053.State = 2
    light056.State = 2
    light052.State = 2
    light009.State = 2
    light010.State = 2
    light011.State = 2
    light019.State = 2
    PlaySoundAt "fx_resetdrop", Target005
    Target004.IsDropped = 0
    Target005.IsDropped = 0
    Target006.IsDropped = 0
    AtlantiaCount = 0
    AtlantiaTimerCount = 41 'seconds
    AtlantiaTimer.Enabled = 1
End Sub

Sub CheckAtlantia
    If AtlantiaCount = 8 Then
        BrujaFlasher.Enabled = 1
    End If
End Sub

Sub WinAtlantia
    Dim tmp
    tmp = 10000000 + AtlantiaTimerCount * 1000000
    AtlantiaTimer.Enabled = 0
    DMD "DOCTOR DEFEATED", CL(1, FormatScore(tmp)), "", eNone, eBlink, eNone, 1500, True, "fanfare3" : pupevent 864
    Addscore tmp
    StopAtlantia
    ResetBRUJALetter
    StartBRUJALEtter
End Sub

Sub StopAtlantia
    Mode(CurrentPLayer, 7) = 1
    Light063.State = 1
    AtlantiaTimer.Enabled = 0
    BrujaFlasher.Enabled = 0
    TurnOffClock
    light054.State = 0
    light053.State = 0
    light056.State = 0
    light052.State = 0
    light009.State = 0
    light010.State = 0
    light011.State = 0
    light019.State = 0
    PlaySoundAt "fx_resetdrop", Target005
    Target004.IsDropped = 0
    Target005.IsDropped = 0
    Target006.IsDropped = 0
    DropCount = 0
End Sub

Sub AtlantiaTimer_Timer
    AtlantiaTimerCount = AtlantiaTimerCount - 1
    UpdateClock AtlantiaTimerCount
    If AtlantiaTimerCount = 0 Then
        StopAtlantia
        ResetBRUJALetter
        StartBRUJALEtter
    End If
End Sub
'*******************************
' La ciudad de los Arboles
'*******************************
' Mode 8, 2 ball multiball, one add-a-ball available
' Hurry up, count from 1 Million down, shoot Witch to lock on
' Hit alternate shots until you the witch, each shot increases 500k
' Hit the Witch Nest for a Super Jackpot
' Collect 2 super Jackpots to end the mode

Sub StartArboles
    DMD "", "", "arboles", eNone, eNone, eBlinkFast, 1500, True, "vo_hurryupislit" : pupevent 845
    SetLightColor light054, Green, 0 'arrows
    SetLightColor light055, Green, 0
    SetLightColor light056, Green, 0
    SetLightColor light057, Green, 0
    SetLightColor light049, Green, 0
    SetLightColor light053, Green, 0
    SetLightColor light052, Green, 0
    ArbolesCount = 0
    ArbolesSJPCount = 0
    ArbolesJPValue = 1000000
    ArbolesTimer1.Enabled = 1
    BrujaFlasher.Enabled = 1
End Sub

Sub StopArboles
    Mode(CurrentPLayer, 8) = 1
    ArbolesTimer1.Enabled = 0
    ArbolesTimer2.Enabled = 0
    BrujaFlasher.Enabled = 0
End Sub

Sub CheckArboles
    Select Case ArbolesCount
        Case 0
        Case 1 'left ramp shot
            Light054.State = 2
            light052.State = 0
            ArbolesTimer2.Enabled = 0
            ArbolesTimer2.Enabled = 1
        Case 2 'right orbit
            light052.State = 2
            Light055.State = 0
            ArbolesTimer2.Enabled = 0
            ArbolesTimer2.Enabled = 1
        Case 3 'left orbit
            Light055.State = 2
            Light053.State = 0
            ArbolesTimer2.Enabled = 0
            ArbolesTimer2.Enabled = 1
        Case 4 'right ramp
            Light053.State = 2
            light056.State = 0
            ArbolesTimer2.Enabled = 0
            ArbolesTimer2.Enabled = 1
        Case 5 'left mini loop
            light056.State = 2
            ArbolesTimer2.Enabled = 0
            ArbolesTimer2.Enabled = 1
        Case 6 ' shoot the witch for SJP
            ArbolesTimer2.Enabled = 0
            BrujaFlasher.Enabled = 1
            ArbolesSJPCount = 1
        ' from now on the shots don't go back
        Case 7 'left ramp shot
            Light054.State = 2
            light052.State = 0
        Case 8 'right orbit
            light052.State = 2
            Light055.State = 0
        Case 9 'left orbit
            Light055.State = 2
            Light053.State = 0
        Case 10 'right ramp
            Light053.State = 2
            light056.State = 0
        Case 11 'left mini loop
            light056.State = 2
        Case 12 ' shoot the witch for SJP 2nd time
            BrujaFlasher.Enabled = 1
            ArbolesSJPCount = 2
        Case 13 ' won Arboles
            BrujaFlasher.Enabled = 0
            StopArboles
            ResetBRUJALetter
            StartBRUJALetter
    End Select
End Sub

Sub ArbolesTimer1_Timer 'countdown JP value
    ArbolesJPValue = ArbolesJPValue - 10000
    DMD "  HIT PINHEAD", CL(1, FormatScore(ArbolesJPValue)), "", eNone, eNone, eNone, 200, True, "" : pupevent 865
    If ArbolesJPValue = 50000 Then
        ArbolesCount = 0
        Me.Enabled = 0
        light058.State = 0
        CheckArboles
    End If
End Sub

Sub ArbolesTimer2_Timer 'reduces the count towards the Super Jackpot
    If ArbolesCount> 1 then
        ArbolesCount = ArbolesCount -1
        CheckArboles
    End If
End Sub

'*******************************
' Hechizos, Pozimas y Brujerias
'*******************************
' Mode 5
' spinners :)
' timed mode 40 seconds
' shoot 1 purple light to activate spinners
' shoot spinner and repeat until the 40 seconds run out or you loose the ball.

Sub StartHechizos
    DMD "", "", "hechizos", eNone, eNone, eBlinkFast, 1500, True, "" : pupevent 842
    HechizoCount = 0
    CheckHechizo
    HechizoTimer.Enabled = 1
End Sub

Sub CheckHechizo
    Select Case HechizoCount
        Case 0:
            DMD "_", "SHOOT RAMPS OR LOOPS", "", eNone, eBlink, eNone, 1500, True, "vo_ramps2" : pupevent 866
            SetLightColor light054, purple, 2
            SetLightColor light053, purple, 2
            SetLightColor light055, purple, 2
            SetLightColor light049, purple, 2
            SetLightColor light044, purple, 0
            SetLightColor light056, purple, 0
            HechizoCount = 1
        Case 1:
            DMD "_", "SHOOT THE SPINNERS", "", eNone, eBlink, eNone, 1500, True, "vo_spinner" : pupevent 867
            SetLightColor light054, purple, 0
            SetLightColor light053, purple, 0
            SetLightColor light055, purple, 0
            SetLightColor light049, purple, 0
            SetLightColor light044, purple, 2
            SetLightColor light056, purple, 2
            HechizoCount = 0
    End Select
End Sub

Sub HechizoTimer_Timer '40 seconds
    Me.Enabled = 0
    StopHechizo
    ResetBRUJALetter
    StartBRUJALetter
End Sub

Sub StopHechizo
    HechizoTimer.Enabled = 0
    Trigger011.TimerEnabled = 0
    Trigger014.TimerEnabled = 0
    Mode(CurrentPlayer, 5) = 1
    Light060.State = 1
End Sub

Sub Trigger011_Hit
    StopCombo
    If Mode(CurrentPLayer, 0) = 5 AND light044.State Then
        Me.TimerEnabled = 1
    End If
End Sub

Sub Trigger011_Timer:Me.TimerEnabled = 0:CheckHechizo:End Sub

Sub Trigger014_Hit
    If Mode(CurrentPLayer, 0) = 5 AND light056.State Then
        Me.TimerEnabled = 1
    End If
End Sub

Sub Trigger014_Timer:Me.TimerEnabled = 0:CheckHechizo:End Sub

'*****************
'  Folktergeist
'*****************
' Mode 6
' 2 ball multiball with add-a-ball
' shoot the blue arrows, defeat 4 witches
' ramp + witchtarget - defeat 2 ghosts
' lock on target and shoot the witch

Sub StartFolktergeist
    DMD "", "", "folktegeist", eNone, eNone, eBlinkFast, 1500, True, "" : pupevent 443
    For X = 0 to 7
        SetLightColor aLightArrows(x), DarkBlue, 2
    Next
    FolkCount = 0
    Addmultiball 1
    post001.IsDropped = 0:PlaySoundAt "fx_SolenoidOn", Trigger010
    post002.IsDropped = 0
    vpmtimer.addtimer 2500, "PlaySoundAt""fx_SolenoidOff"", Trigger010: post001.IsDropped = 1:post002.IsDropped = 1 '"
End Sub

Sub CheckFolkCount
    FolkCount = FolkCount + 1
    Select Case FolkCount
        Case 1:DMD "_", "DEFEATED " &FolkCount& "PINHEAD", "", eNone, eBlink, eNone, 1500, True, "" : pupevent 868
        Case 2, 3:DMD "_", "DEFEATED " &FolkCount& "PINHEAD", "", eNone, eBlink, eNone, 1500, True, "" : pupevent 868
        Case 4:DMD "_", "DEFEATED " &FolkCount& " PINHEAD", "", eNone, eBlink, eNone, 1500, True, "" : pupevent 868
            For X = 0 to 7
                aLightArrows(x).State = 0
            Next
            Light054.State = 2
            Light053.State = 2
            DMD "_", "  ADD A SOUL IS LIT", "", eNone, eBlink, eNone, 1500, True, "Fanfare7" : pupevent 859
            bAddaBallActivated = True
            Light046.State = 2
        Case 5:DMD "_", "SHOOT LAMENT BOX", "", eNone, eBlink, eNone, 1500, True, "" : pupevent 869
            Light054.State = 0
            Light053.State = 0
            Light057.State = 2
        Case 6:
            If LastSwitchHit = "bruja_target" Then
                DMD "_", CL(1, "CAPTURED 1 SOUL"), "", eNone, eBlink, eNone, 1500, True, "" : pupevent 870
                Light057.State = 0
                Light054.State = 2
                Light053.State = 2
            Else
                FolkCount = FolkCount -1
                Light054.State = 0
                Light053.State = 0
                Light057.State = 2
            End If
            DMD "_", "  ADD A SOUL IS LIT", "", eNone, eBlink, eNone, 1500, True, "Fanfare7" : pupevent 859
            bAddaBallActivated = True
            Light046.State = 2
        Case 7:DMD "_", "SHOOT LAMENT BOX", "", eNone, eBlink, eNone, 1500, True, "" : pupevent 869
            Light054.State = 0
            Light053.State = 0
            Light057.State = 2
        Case 8:
            If LastSwitchHit = "bruja_target" Then
                DMD "_", CL(1, "CAPTURED 2 SOULS"), "", eNone, eBlink, eNone, 1500, True, "" : pupevent 871
                Light057.State = 0
                DMD "_", "LOCK ON TO PINHEAD", "", eNone, eBlink, eNone, 1500, True, "" : pupevent 872
                FolkTimer.Enabled = 1
            Else
                FolkCount = FolkCount -1
                Light054.State = 2
                Light053.State = 2
                Light057.State = 0
            End If
        Case 9:DMD "_", CL(1, "SHOOT LAMENT BOX"), "", eNone, eBlink, eNone, 1500, True, "" : pupevent 869
            FolkTimer.Enabled = 0
            For X = 0 to 7
                aLightArrows(x).State = 0
            Next
            Light057.State = 2
        Case 10:DMD "_", "PINHEAD DEFEATED", "", eNone, eBlink, eNone, 1500, False, "" : pupevent 873
            DMD "_", "CHATTERER DEFEATED", "", eNone, eBlink, eNone, 1500, True, "" : pupevent 874
            StopFoltergeist
            ResetBRUJALetter
            StartBRUJALetter
    End Select
End Sub

Sub FolkTimer_Timer 'a kind of "follow the lights" changes the lit arrow after 5 seconds
    For X = 0 to 7
        aLightArrows(x).State = 0
    Next
    x = INT(RND * 8)
    aLightArrows(x).State = 2
End Sub

Sub StopFoltergeist       'called at the end of the multiball or when completed
    FolkTimer.Enabled = 0 'if it was on
    For X = 0 to 7
        aLightArrows(x).State = 0
    Next
    Mode(CurrentPLayer, 6) = 1
    Light061.State = 1
End Sub

'********************
'   I-L-U-S-S-I-A
'********************
' Mode 1
' Light the ILUSSIA letters
' variables used:
' ILUSSIATimes(CurrentPlayer) how many times you have started multiball
' ILUSSIACount(CurrentPlayer) used in light status update
' bILUSSIASJP SuperJackpot True or False

Sub AddILUSSIAletter
    IlussiaBonusCount = IlussiaBonusCount + 1
    ILUSSIACount(CurrentPlayer) = ILUSSIACount(CurrentPlayer) + 1
    If ILUSSIACount(CurrentPlayer) <8 Then
        Addscore 10000
    ElseIf ILUSSIACount(CurrentPlayer) <15 Then
        AwardJackpot
    Else
        AwardDoubleJackpot
    End If
    UpdateILUSSIA
End Sub

Sub UpdateILUSSIA
    Select Case ILUSSIACount(CurrentPlayer)
        Case 0:light019.State = 0:light039.State = 0:light038.State = 0:light037.State = 0:light036.State = 0:light035.State = 0:light034.State = 0:light033.State = 0
        Case 1:light019.State = 0:light039.State = 1:light038.State = 0:light037.State = 0:light036.State = 0:light035.State = 0:light034.State = 0:light033.State = 0
        Case 2:light019.State = 0:light039.State = 1:light038.State = 1:light037.State = 0:light036.State = 0:light035.State = 0:light034.State = 0:light033.State = 0
        Case 3:light019.State = 0:light039.State = 1:light038.State = 1:light037.State = 1:light036.State = 0:light035.State = 0:light034.State = 0:light033.State = 0
        Case 4:light019.State = 0:light039.State = 1:light038.State = 1:light037.State = 1:light036.State = 1:light035.State = 0:light034.State = 0:light033.State = 0
        Case 5:light019.State = 0:light039.State = 1:light038.State = 1:light037.State = 1:light036.State = 1:light035.State = 1:light034.State = 0:light033.State = 0
        Case 6:light019.State = 0:light039.State = 1:light038.State = 1:light037.State = 1:light036.State = 1:light035.State = 1:light034.State = 1:light033.State = 0
        'If Mode(CurrentPlayer, 0) = 10 Then PlaySound "vo_multiballisready"
        Case 7:light019.State = 2:light039.State = 2:light038.State = 2:light037.State = 2:light036.State = 2:light035.State = 2:light034.State = 2:light033.State = 2
            If Mode(CurrentPlayer, 0) = 10 Then
                StartIlussiaMUltiball
            Else
                ILUSSIACount(CurrentPlayer) = 6
            End If
        Case 8:light019.State = 2:light039.State = 1:light038.State = 2:light037.State = 2:light036.State = 2:light035.State = 2:light034.State = 2:light033.State = 2
        Case 9:light019.State = 2:light039.State = 1:light038.State = 1:light037.State = 2:light036.State = 2:light035.State = 2:light034.State = 2:light033.State = 2
        Case 10:light019.State = 2:light039.State = 1:light038.State = 1:light037.State = 1:light036.State = 2:light035.State = 2:light034.State = 2:light033.State = 2
        Case 11:light019.State = 2:light039.State = 1:light038.State = 1:light037.State = 1:light036.State = 1:light035.State = 2:light034.State = 2:light033.State = 2
        Case 12:light019.State = 2:light039.State = 1:light038.State = 1:light037.State = 1:light036.State = 1:light035.State = 1:light034.State = 2:light033.State = 2
        Case 13:light019.State = 2:light039.State = 1:light038.State = 1:light037.State = 1:light036.State = 1:light035.State = 1:light034.State = 1:light033.State = 2
        Case 14:light019.State = 1:light039.State = 2:light038.State = 2:light037.State = 2:light036.State = 2:light035.State = 2:light034.State = 2:light033.State = 2:ActivateSJP_Witch
    End Select
End Sub

Sub StartIlussiaMUltiball
    StopBRUJALetter
    DMD CL(0, "PINHEAD"), CL(1, "MAYHEM"), "", eBlink, eBlink, eNone, 1500, True, "vo_multiball2" : pupevent 875
    AddMultiball 1
    post001.IsDropped = 0:PlaySoundAt "fx_SolenoidOn", Trigger010
    post002.IsDropped = 0
    vpmtimer.addtimer 2500, "PlaySoundAt""fx_SolenoidOff"", Trigger010: post001.IsDropped = 1:post002.IsDropped = 1 '"
    ILUSSIATimes(CurrentPlayer) = ILUSSIATimes(CurrentPlayer) + 1
    StartAddaBall
    Mode(CurrentPlayer, 0) = 1
    EnableBallSaver 15
End Sub

Sub ActivateSJP_Witch 'setup for superjackpot at the witch target
    bILUSSIASJP = True
    SetLightColor Light057, red, 0
    BrujaFlasher.Enabled = 1
End Sub

Sub StopILUSSIA                         'only CurrentPlayer when the last multiball is lost
    IF ILUSSIATimes(CurrentPlayer) = 1 Then
        ILUSSIACount(CurrentPlayer) = 2 'two lights are already lit
    Else
        ILUSSIACount(CurrentPlayer) = 0 'after 2 Ilussia MB all 7 lights need to be lit
    End If
    UpdateILUSSIA
    bILUSSIASJP = False
    SetLightColor Light057, white, 0
    BrujaFlasher.Enabled = 0
    StopAddaBall
End Sub

'**************************
'   Add-a-Ball for Ilussia
'**************************
' during ILUSSIA multiball you may get up to 3 add-a-balls by hitting the yellow targets:
' 1. both ramps, 2 targets
' 2. both ramps and orbits, 4 targets
' 3. both ramps, orbits, loops, and bruja target, 7 targets

Sub StartAddaBall
    ' setup for first add-a-ball
    bAddaBall = True
    bAddaBallActivated = False
    AddaBallCount = 0
    AddaBallLevel = 1
    bAddaBallActivated = False
    UpDateAddaBall
End Sub

Sub UpDateAddaBall 'Lights
    Select case AddaBallLevel
        Case 1:    'both ramps
            SetLightColor Light053, yellow, 2
            SetLightColor Light054, yellow, 2
        Case 2: 'both ramps and orbits
            SetLightColor Light053, yellow, 2
            SetLightColor Light054, yellow, 2
            SetLightColor Light052, yellow, 2
            SetLightColor Light055, yellow, 2
        Case 3: 'both ramps, orbits, loops, bruja target and super jackpot target
            SetLightColor Light053, yellow, 2
            SetLightColor Light054, yellow, 2
            SetLightColor Light052, yellow, 2
            SetLightColor Light055, yellow, 2
            SetLightColor Light056, yellow, 2
            SetLightColor Light049, yellow, 2
            SetLightColor Light057, yellow, 2
    End Select
End Sub

Sub CheckAddaBall '3 levels with 2, 4 or 7 hits to qualify
    Select case AddaBallLevel
        Case 1:
            If AddaBallCount = 2 Then
                DMD "_", "  ADD A SOUL IS LIT", "", eNone, eBlink, eNone, 1500, True, "Fanfare7" : pupevent 859
                bAddaBallActivated = True
                Light046.State = 2
            End If
        Case 2
            If AddaBallCount = 4 Then
                DMD "_", "  ADD A SOUL IS LIT", "", eNone, eBlink, eNone, 1500, True, "Fanfare8" : pupevent 859
                bAddaBallActivated = True
                Light046.State = 2
            End If
        Case 3
            If AddaBallCount = 7 Then
                DMD "_", "  ADD A SOUL IS LIT", "", eNone, eBlink, eNone, 1500, True, "Fanfare9" : pupevent 859
                bAddaBallActivated = True
                Light046.State = 2
            End If
    End Select
End Sub

Sub StopAddaBall
    bAddaBall = False
    bAddaBallActivated = False
    Light046.State = 0
    SetLightColor Light053, white, 0
    SetLightColor Light054, white, 0
    SetLightColor Light052, white, 0
    SetLightColor Light055, white, 0
    SetLightColor Light056, white, 0
    SetLightColor Light049, white, 0
    SetLightColor Light057, white, 0
End Sub

Sub AwardAddaBall()
    DMD "_", CL(1, ("ADD A SOUL")), "", eNone, eBlink, eNone, 1500, True, "vo_addaball" : pupevent 860
    AddMultiball 1
    LightEffect 5
    AddaBallLevel = AddaBallLevel + 1
    AddaBallCount = 0
    bAddaBallActivated = False
    Light046.State = 0
    UpdateAddaBall
End Sub

'*********************
'  WITCH Multiball
'*********************

' Witch's Nest Ramp

Sub RampUp
    PlaySoundAt SoundFXDOF("fx_solenoidOn",123,DOFPulse,DOFContactors), WitchNest
    Witchflipper.RotatetoEnd
    Light058.blinkinterval = 125:light058.State = 2
    Ramp007inv.Collidable = False
End Sub

Sub RampDown
    PlaySoundAt SoundFXDOF("fx_solenoidOff",123,DOFPulse,DOFContactors), WitchNest
    Witchflipper.RotatetoStart
    Light058.blinkinterval = 400:light058.State = 0
    Ramp007inv.Collidable = True
    light008.State = 0
    light050.State = 0
End Sub

' Witch's Nest Locked Balls

Sub CheckLockedBalls 'updates also the lights
    Select Case BallsLocked(CurrentPlayer)
        Case 0:light007.State = 0:light006.State = 0:light070.State = 0
        Case 1:light007.State = 1:light006.State = 0:light070.State = 0
            LightEffect 1
            DMD CL(0, "LEVIATHAN"), CL(1, "SOUL 1 LOCKED"), "", eNone, eBlink, eNone, 1500, True, "vo_ball1locked" : pupevent 876
            vpmtimer.addtimer 2500, "Exit_WitchNest '"
        Case 2:light007.State = 1:light006.State = 1:light070.State = 0
            LightEffect 1
            DMD CL(0, "LEVIATHAN"), CL(1, "SOUL 2 LOCKED"), "", eNone, eBlink, eNone, 1500, True, "vo_ball2locked" : pupevent 877
            vpmtimer.addtimer 2500, "Exit_WitchNest '"
        Case 3:
            If Mode(CurrentPlayer, 0) = 10 Then
                DMD CL(0, "LEVIATHAN"), CL(1, "SOUL 3 LOCKED"), "", eNone, eBlink, eNone, 1500, True, "vo_ball3locked" : pupevent 878
                light007.State = 2:light006.State = 2:light070.State = 2
                LightEffect 1
                light058.State = 2
                bLockActive(CurrentPlayer) = False
                bLockActive(CurrentPlayer) = False
                DMD CL(0, "PINHEAD MAYHEM"), CL(1, "IS READY"), "", eNone, eBlink, eNone, 5000, True, "" : pupevent 879
                vpmtimer.addtimer 2500, "PlaySound""vo_multiballstarting321"" '"
                vpmtimer.addtimer 7000, "StartWitchMultiball '"
                vpmtimer.addtimer 9000, "light007.State = 0:light006.State = 0:light070.State = 0 '"
            Else
                vpmtimer.addtimer 2000, "Exit_WitchNest '"
            End If
    End Select
End Sub

Sub StartWitchMultiball
    StopBRUJALetter
    Mode(CurrentPlayer, 0) = 2
    ' flash show
    DMD CL(0, "PINHEAD"), CL(1, "MAYHEM"), "", eNone, eBlink, eNone, 1500, True, "vo_multiball3" : pupevent 880
    Exit_WitchNest
    post001.IsDropped = 0:PlaySoundAt "fx_SolenoidOn", Trigger010
    post002.IsDropped = 0
    vpmtimer.addtimer 5000, "PlaySoundAt""fx_SolenoidOff"", Trigger010: post001.IsDropped = 1:post002.IsDropped = 1 '"
    AddMultiball 2
    LightEffect 5
    BallsLocked(CurrentPlayer) = 0
    Light008.State = 0
    'setup arrow colors
    For X = 0 to 7
        WitchMBMultiplier(x) = 1
    Next
    UpdateArrowColors
    bWitchMBFirstHit = True
    EnableBallSaver 15
End Sub

' turns on all arrows in the color of the multiplier
' aLightsArrows is a collection and must be in the right order
Sub UpdateArrowColors
    For X = 0 to 7
        Select case WitchMBMultiplier(x)
            Case 1:SetLightColor aLightArrows(x), Blue, 1
            Case 2:SetLightColor aLightArrows(x), Green, 1
            Case 3:SetLightColor aLightArrows(x), Yellow, 1
            Case 4:SetLightColor aLightArrows(x), Orange, 1
            Case 5:SetLightColor aLightArrows(x), Red, 1
        End Select
    Next
End Sub

Sub StopWitchMultiball
    bWitchMBJackpotReady = False
    BrujaFlasher.Enabled = 0
    Light051.State = 0
    ' turn off jackpot lights
    For each x in aLightArrows:x.State = 0:Next
End Sub

'**************************
' Droptargets: extra subs
'**************************

Sub CheckDrops
    If DropCount = 3 Then
        LightEffect 1
        Addscore DropBankValue(CurrentPlayer)
        DMD CL(0, "3 BANK VALUE"), CL(1, FormatScore(DropBankValue(CurrentPlayer))), "", eNone, eBlink, eNone, 1500, True, ""
        If DropBankValue(CurrentPlayer) <750000 Then
            DropBankValue(CurrentPlayer) = DropBankValue(CurrentPlayer) + 25000
        End If
        If Mode(CurrentPlayer, 0) = 2 AND Light051.State = 0 Then 'activate the witch for a Jackpot shot only when the SJP light is off
            BrujaFlasher.Enabled = 1
            bWitchMBJackpotReady = True
        Else                                   'do the normal droptarget awards
            Select Case DropPos(CurrentPlayer) 'lit award
                Case 0:AddBonusMultiplier 1
                Case 1:light046.State = 2:bMystery = True:Flashforms ORBLight, 5000, 50, 0
                Case 2:
                    If Mode(CurrentPLayer, 0) = 10 Then
                        light008.State = 2
                        bLockActive(CurrentPlayer) = True
                        RampUp
                        DMD "", "", "lockislit", eNone, eNone, eBlink, 1500, True, "vo_lockislit" : pupevent 854
                    End If
            End Select
            DropPos(CurrentPlayer) = (DropPos(CurrentPlayer) + 1)MOD 3
        End If
        vpmtimer.addtimer 1000, "ResetDrop '"
    End If
End Sub

Sub ResetDrop
    PlaySoundAt "fx_resetdrop", Target005
    Target004.IsDropped = 0
    Target005.IsDropped = 0
    Target006.IsDropped = 0
    DropCount = 0
    UpdateDrop
End Sub

Sub UpdateDrop                                                          'lights
    Select Case DropPos(CurrentPlayer)
        Case 0:light009.State = 0:light010.State = 0:light011.State = 2 'Bonus X
        Case 1:light009.State = 0:light010.State = 2:light011.State = 0 'lit ORB for mystery award
        Case 2:light009.State = 2:light010.State = 0:light011.State = 0 'lit lock
    End Select
End Sub

'********************
' Mystery ORB awards
'********************
' ORG lits up for mystery awards
' the award increases for each time you obtain it

Sub AwardMystery
    Dim tmp
    bMystery = False
    Light046.State = 0
    LightEffect 1
    DMD "", "", "mystery", eNone, eNone, eBlink, 1500, True, "" : pupevent 881
    tmp = INT(RND * 7 + MysteryLevel(CurrentPlayer)) * 150000
    DMD CL(0, "MYSTERY AWARD"), CL(1, FormatScore(tmp)), "", eNone, eBlink, eNone, 1500, True, ""
    Addscore tmp
    MysteryLevel(CurrentPlayer) = MysteryLevel(CurrentPlayer) + 1
End Sub

'*************
'  Spinners
'*************

Sub Spinner001_Spin
    If Tilted Then Exit Sub
    PlaySoundAt "fx_spinner", Spinner001
    SetFlash flasher001, 1, 100, 50
    DOF 201, DOFPulse
    Select Case Mode(CurrentPlayer, 0)
        Case 10
            Addscore 50000
            If BrujaLetter(CurrentPlayer) <5 Then
                NextMode
            End If
        Case 3 'simply lit the super light
            Addscore 50000
            light026.State = 1
            CheckFinisterra
        Case 5
            If light044.State Then
                Addscore HechizoSpinnerValue
            End If
        Case Else
            Addscore 50000
    End Select
    ' run during the whole game
    If bSuperSpinners(CurrentPlayer) <> 1 Then
        SuperSpinnersCount(CurrentPlayer) = SuperSpinnersCount(CurrentPlayer) + 1
        If SuperSpinnersCount(CurrentPlayer) = 60 Then
            bSuperSpinners(CurrentPlayer) = 2
            UpdateSuperPyramid
            SuperPyramidValue = SuperPyramidValue + 1500000
        ElseIf SuperSpinnersCount(CurrentPlayer)> 60 Then
            SuperPyramidValue = SuperPyramidValue + 25000
        End If
    End If
    'Ball Saver
    BallSaveCount = (BallSaveCount + 1)MOD 30
    If BallSaveCount = 29 Then
        EnableSidePosts
    End If
End Sub

Sub Spinner002_Spin
    If Tilted Then Exit Sub
    PlaySoundAt "fx_spinner", Spinner002
    SetFlash flasher003, 3, 100, 50
    DOF 204, DOFPulse
    Select Case Mode(CurrentPlayer, 0)
        Case 3 'simply lit the super light
            Addscore 25000
            light026.State = 1
            CheckFinisterra
        Case 5
            If light056.State Then
                Addscore HechizoSpinnerValue
            End If
        Case Else
            Addscore 25000
    End Select
    ' run during the whole game
    If bSuperSpinners(CurrentPlayer) <> 1 Then 'this if it is not finished
        SuperSpinnersCount(CurrentPlayer) = SuperSpinnersCount(CurrentPlayer) + 1
        If SuperSpinnersCount(CurrentPlayer) = 60 Then
            bSuperSpinners(CurrentPlayer) = 2 'this means it is activated
            UpdateSuperPyramid
            SuperPyramidValue = SuperPyramidValue + 1500000
        ElseIf SuperSpinnersCount(CurrentPlayer)> 60 Then 'add more points to the SP jackpot
            SuperPyramidValue = SuperPyramidValue + 25000
        End If
    End If
End Sub

'***********************
'Ball saver: side Posts
'***********************
' 20 seconds ball saver

Sub EnableSidePosts
    post005.IsDropped = 0:PlaySoundAt "fx_solenoidOn", gi006
    light004.State = 1
    post003.IsDropped = 0:PlaySoundAt "fx_solenoidOn", gi043
    light003.State = 1
    IF Balls = 3 Then post004.IsDropped = 0 'on the last ball you also get the center post
    Post005.TimerEnabled = 1
    Light005.State = 0
End Sub

Sub post005_Timer
    post005.TimerEnabled = 0
    post005.IsDropped = 1:PlaySoundAt "fx_solenoidOff", gi006
    light004.State = 0
    post003.IsDropped = 1:PlaySoundAt "fx_solenoidOff", gi043
    post004.IsDropped = 1
    light003.State = 0
    Light005.State = 2
End Sub

'********************
'   Super Pyramid
'********************
' shoot POPS, SPINNERS, RAMPS, TARGETS and ORBITS to power-up the Pyramid.
' once a super feature is activated it builds the Super Pyramid Jackpot

Sub UpdateSuperPyramid
    'super POPS
    Light024.State = bSuperPops(CurrentPlayer)
    'super SPINNERS
    Light026.State = bSuperSpinners(CurrentPlayer)
    If bSuperSpinners(CurrentPlayer) = 2 Then
        Light023.state = 2
        Light031.State = 2
    Else
        Light023.state = 0
        Light031.State = 0
    End If
    'super RAMPS
    Light028.State = bSuperRamps(CurrentPlayer)
    If bSuperRamps(CurrentPlayer) = 2 Then
        Light029.state = 2
    Else
        Light029.state = 0
    End If
    'super TARGETS
    Light025.State = bSuperTargets(CurrentPlayer)
    'super ORBITS
    Light027.State = bSuperOrbits(CurrentPlayer)
    If bSuperOrbits(CurrentPlayer) = 2 Then
        Light030.state = 2
    Else
        Light030.state = 0
    End If
    'super pyramid jackpot - only the active pyramids count the X
    SuperPyramidMultiplier = 0
    If bSuperPops(CurrentPlayer) = 2 Then
        SuperPyramidMultiplier = SuperPyramidMultiplier + 1
    End If
    If bSuperSpinners(CurrentPlayer) = 2 Then
        SuperPyramidMultiplier = SuperPyramidMultiplier + 1
    End If
    If bSuperRamps(CurrentPlayer) = 2 Then
        SuperPyramidMultiplier = SuperPyramidMultiplier + 1
    End If
    If bSuperTargets(CurrentPlayer) = 2 Then
        SuperPyramidMultiplier = SuperPyramidMultiplier + 1
    End If
    If bSuperOrbits(CurrentPlayer) = 2 Then
        SuperPyramidMultiplier = SuperPyramidMultiplier + 1
    End If
    If SuperPyramidMultiplier> 0 Then                                                             'at least one super feature is activated
        bSPJActivated = True
        DMD "", "", "superjackpotislit", eNone, eNone, eBlink, 1500, True, "vo_superjackpotislit" : pupevent 852 'enabled SJP
        Light045.State = 2
    Else
        bSPJActivated = False
        Light045.State = 0
    End If
End Sub

Sub StopSuperPyramid 'called at the end of the ball or after the SPJ award
    SuperPyramidMultiplier = 0
    SuperPyramidValue = 0
    bSPJActivated = 0
    Light045.State = 0
    'pops
    If bSuperPops(CurrentPlayer) = 2 Then
        PyramidBonusCount = PyramidBonusCount + 1
        bSuperPops(CurrentPlayer) = 1
        Light024.State = 1
    End If
    ' spinners
    If bSuperSpinners(CurrentPlayer) = 2 Then
        PyramidBonusCount = PyramidBonusCount + 1
        bSuperSpinners(CurrentPlayer) = 1
        Light026.State = 1
        Light023.state = 0
        Light031.State = 0
    End If
    'ramps
    If bSuperRamps(CurrentPlayer) = 2 Then
        PyramidBonusCount = PyramidBonusCount + 1
        bSuperRamps(CurrentPlayer) = 1
        Light028.State = 1
        Light029.State = 0
    End If
    'targets
    If bSuperTargets(CurrentPlayer) = 2 Then
        PyramidBonusCount = PyramidBonusCount + 1
        bSuperTargets(CurrentPlayer) = 1
        Light025.State = 1
    End If
    'orbits
    If bSuperOrbits(CurrentPlayer) = 2 Then
        PyramidBonusCount = PyramidBonusCount + 1
        bSuperOrbits(CurrentPlayer) = 1
        Light027.State = 1
        Light030.State = 0
    End If
    If(bSuperPops(CurrentPlayer) = 1)AND(bSuperSpinners(CurrentPlayer) = 1)AND(bSuperRamps(CurrentPlayer) = 1)AND(bSuperTargets(CurrentPlayer) = 1)AND(bSuperOrbits(CurrentPlayer) = 1)Then
        ResetPyramid
    End If
End Sub

Sub ResetPyramid
    for x = 0 to 4
        SuperSpinnersCount(x) = 0
        SuperPopsCount(x) = 0
        SuperRampsCount(x) = 0
        SuperTargetsCount(x) = 0
        SuperOrbitsCount(x) = 0
        bSuperSpinners(x) = 0 '0 not started, 2 started, 1 completed, corresponds to the light states
        bSuperPops(x) = 0
        bSuperRamps(x) = 0
        bSuperTargets(x) = 0
        bSuperOrbits(x) = 0
    Next
    UpdateSuperPyramid
End Sub

Sub AwardSPJackpot
    If bSPJActivated Then
        AddBonusMultiplier 1
        Dim tmp
        tmp = SuperPyramidValue * SuperPyramidMultiplier
        DMD CL(0, FormatScore(tmp)), "HELLBOUND SP JACKPOT", "", eNone, eBlinkFast, eNone, 1500, True, "vo_superjackpot2" : pupevent 752
        DOF 126, DOFPulse
        Addscore tmp
        LightEffect 2
        StopSuperPyramid
        ' only when you collect the SPJackpot you may start Finisterra
        If(bSuperPops(CurrentPlayer) = 1)AND(bSuperSpinners(CurrentPlayer) = 1)AND(bSuperRamps(CurrentPlayer) = 1)AND(bSuperTargets(CurrentPlayer) = 1)AND(bSuperOrbits(CurrentPlayer) = 1)Then
            StartFinisterra
        End If
    End If
End Sub

'***********************************
' Finisterra Multiball - Wizard Mode
'***********************************
'starts after finishing the Super Pyramid
' Mode 3
Sub EnableFinisterra
    DMD "HIT LAMENT BOX", "MAYHEM", "", eBlink, eBlink, eNone, 1500, True, "" : pupevent 882
    bFinisterraMBReady = True
    SetLightColor Light057, red, 2
    BrujaFlasher.Enabled = 1
End Sub

Sub StartFinisterra
    StopBRUJALetter
    DMD CL(0, "SUFFERING"), "MAYHEM", "", eNone, eBlink, eNone, 1500, True, "vo_multiball" : pupevent 883
    light045.State = 0
    light024.State = 0
    light025.State = 0
    light026.State = 0
    light027.State = 0
    light028.State = 0
    light014.State = 2
    light058.State = 2
    Light023.State = 2
    Light030.State = 2
    Light029.State = 2
    Light031.State = 2
    Light032.State = 2
    bFinisterraMBReady = False
    Mode(CurrentPLayer, 0) = 3
    EnableBallSaver 30
    AddMultiball 1
    LightEffect 5
    post001.IsDropped = 0:PlaySoundAt "fx_SolenoidOn", Trigger010
    post002.IsDropped = 0
    vpmtimer.addtimer 2500, "PlaySoundAt""fx_SolenoidOff"", Trigger010: post001.IsDropped = 1:post002.IsDropped = 1 '"
End Sub

Sub CheckFinisterra 'pops, spinners, orbits, ramps and targets must be hit 1 to activate SJP at ORB
    'can just check the lights :)
    FinisterraSJPValue(Currentplayer) = FinisterraSJPValue(Currentplayer) + 250000 * FinisterraDifficulty
    If light024.State = 1 AND light025.State = 1 AND light026.State = 1 AND light027.State = 1 AND light028.State = 1 Then
        light045.State = 2
        bFinisterraSJPActivated = True
        AwardExtraBall
    End If
End Sub

Sub AwardFinisterraSJP
    Dim tmp
    AddBonusMultiplier 1
    tmp = FinisterraSJPValue(Currentplayer) * FinisterraSJPMultiplier
    DMD CL(0, FormatScore(tmp)), "HELLBOUND SP JACKPOT", "", eNone, eBlinkFast, eNone, 1500, True, "vo_superjackpot" : pupevent 752
    bFinisterraSJPActivated = False
    light045.State = 0
    light024.State = 0
    light025.State = 0
    light026.State = 0
    light027.State = 0
    light028.State = 0
    FinisterraSJPMultiplier = FinisterraSJPMultiplier + 1
    FinisterraSJPCount = FinisterraSJPCount + 1
    If FinisterraSJPCount <3 Then Bruja_AddaBall 'just add add a ball
    FinisterraDifficulty = FinisterraDifficulty + 0.2
End Sub

Sub StopFinisterra
    bFinisterraSJPActivated = False
    light014.State = 0
    light058.State = 0
    light057.State = 0
    light045.State = 0
    light024.State = 0
    light025.State = 0
    light026.State = 0
    light027.State = 0
    light028.State = 0
    Light023.State = 0
    Light030.State = 0
    Light029.State = 0
    Light031.State = 0
    Light032.State = 0
    BrujaFlasher.Enabled = 0
End Sub

'*********************
' Playfield Multiplier
'*********************

Sub CheckPFx 'check target hits to activate the playfield multiplier
    PFxCount = PFxCount + 1
    Select Case PfxCount
        Case 4:AddPlayfieldMultiplier 1:ResetPFxTargetLights
        Case 8:AddPlayfieldMultiplier 1:ResetPFxTargetLights:PFxCount = 0
    End Select
End Sub

Sub ResetPFxTargetLights
    PFxCount = 0
    light015.State = 2
    light016.State = 2
    light017.State = 2
    light018.State = 2
End Sub

Sub RotateActivateX
    Dim tmp
    tmp = light001.State
    light001.State = light002.State
    light002.State = tmp
End Sub

'******************
'   LOOP feature
'******************
' available during all modes
' shoot loops with upper flippers
' LoopValue = 250000
' LoopJackpot = 1000000
' LoopCount = 0

Sub CheckLoop 'count the loops, increases LoopValue, increases LoopJackpot
    If MiniLoopMulti = 3 Then
        LoopCount = LoopCount + 2
    Else
        LoopCount = LoopCount + 1
    End If
    ' loop jackpots are lit
    If light021.State Then
        AddScore LoopJackpot(CurrentPlayer) * MiniLoopMulti
        LoopJackpotMulti = LoopJackpotMulti + 1
        If NOT LoopJackpotTimer.Enabled Then
            LoopJackpotTimer.Enabled = 1
        End If
    End If
    IF LoopCount >= 5 Then
        LoopCount = 5
        'enable loop jackpots
        DMD "", "", "superloopsislit", eNone, eNone, eBlink, 1500, True, "vo_superloopsarelit" : pupevent 884
        light021.State = 2
        light022.State = 2
    End If
    ' Add normal Loop score
    If light021.State = 0 Then
        LoopValue = LoopCount * 250000 * MiniLoopMulti + (LoopCount * 250000 * light020.State)
        AddScore LoopValue
    End If
    If LoopJackpot(CurrentPlayer) <25000000 Then
        LoopJackpot(CurrentPlayer) = LoopJackpot(CurrentPlayer) + 250000
    End If
    ExtraBallCount(CurrentPlayer) = ExtraBallCount(CurrentPlayer) + 1
    If ExtraBallCount(CurrentPlayer) >= 30 then 'lit Extra Ball
        light047.State = 1
    End If
    UpdateLoopLights
End Sub

Sub LoopTimer_Timer 'decreases the LoopValue and after 6 seconds is back to 250k
    LoopCount = LoopCount -1
    UpdateLoopLights
    IF LoopCount = 0 Then
        Me.Enabled = 0
    End If
End Sub

Sub LoopJackpotTimer_Timer 'turns off the loop jackpots after 12 seconds
    light021.State = 0
    light022.State = 0
    LoopJackpotMulti = 1
    Me.Enabled = 0
End Sub

Sub UpdateLoopLights
    Select case LoopCount
        Case 0:light040.State = 0:light041.State = 0:light042.State = 0:light043.State = 0:light020.State = 0:LoopTimer.Enabled = 0:LoopTimer.Enabled = 1
        Case 1:light040.State = 1:light041.State = 0:light042.State = 0:light043.State = 0:light020.State = 0:LoopTimer.Enabled = 0:LoopTimer.Enabled = 1
        Case 2:light040.State = 1:light041.State = 1:light042.State = 0:light043.State = 0:light020.State = 0:LoopTimer.Enabled = 0:LoopTimer.Enabled = 1
        Case 3:light040.State = 1:light041.State = 1:light042.State = 1:light043.State = 0:light020.State = 0:LoopTimer.Enabled = 0:LoopTimer.Enabled = 1
        Case 4:light040.State = 1:light041.State = 1:light042.State = 1:light043.State = 1:light020.State = 0:LoopTimer.Enabled = 0:LoopTimer.Enabled = 1
        Case 5:light040.State = 1:light041.State = 1:light042.State = 1:light043.State = 1:light020.State = 1:LoopTimer.Enabled = 0:LoopTimer.Enabled = 1
    End Select
End Sub

'*******************
'      COMBOS
'*******************
' don't time out (unlike in the Celtic Land ramp mode)
' starts at 500K for a 2 way combo and it is doubled on each combo
' shots that count as combos:
'	Left Ramp	1
'	Big Loop	2
'	Left Orbit	3
'	Mini Loop	4
'	Right Ramp	5
'	Right Orbit	6
' 6 targets up to a max of 5 combos

Sub CheckCombo(n)
    If Mode(CurrentPlayer, 0) = 4 then Exit Sub 'no combos during Celtic Land Mode

    If Combo(n) = 1 Then                       'repeated shot so stop the combos
        StopCombo
        Exit Sub
    End If

    Combo(n) = 1
    ComboCount = 0
    For x = 1 to 6
        ComboCount = ComboCount + Combo(x)
    Next
    If ComboCount = 2 AND bSuperCombo Then 'awarded by the 4th Tomb Treasure
        For x = 1 to 6
            Combo(x) = 1
        Next
        ComboCount = 6
    End If
    Select Case ComboCount
        Case 1 'just starting
        Case 2 'first Combo
            bComboActivated = True
            DMD "", "", "combo", eNone, eNone, eBlink, 1500, True, "vo_combo" : pupevent 885
            ComboFlashTimer.Enabled = 1
        Case 3:DMD "", "", "combo2", eNone, eNone, eBlink, 1500, True, "vo_combo2" : pupevent 886
        Case 4:DMD "", "", "combo3", eNone, eNone, eBlink, 1500, True, "vo_combo3" : pupevent 887
        Case 5:DMD "", "", "combo4", eNone, eNone, eBlink, 1500, True, "vo_combo4" : pupevent 888
        Case 6:DMD "", "", "combo5", eNone, eNone, eBlink, 1500, True, "vo_combo5" : pupevent 889
    End Select
    AddScore ComboValue * ComboCount
End Sub

Sub StopCombo
    bComboActivated = False
    ComboCount = 0
    For X = 1 to 6
        Combo(x) = 0
    Next
    ComboFlashTimer.Enabled = 0
End Sub

Sub ComboFlashTimer_Timer
    SetFlash flasher002, 2, 1400, 50
    DOF 202, DOFPulse
End Sub

'*******************
'     Deathblow
'*******************
' end a combo with a special shot to award a deathblow
' posible targets
'	Skillshot Target
'   ORB target
'	Ilussia Captive Ball
'	Witch target (SUPER)
'	SJP Target (SUPER)

Sub CheckDeathblow(n)
    If bComboActivated Then
        DeathblowBonusCount = DeathblowBonusCount + 1
        Select case n
            case 1, 2, 3 'normal deathblow
                DMD "", "", "deathblow", eNone, eNone, eBlink, 1500, True, "Fanfare2"
                DMD "", CL(1, FormatScore(ComboValue * ComboCount)), "", eNone, eBlink, eNone, 1500, True, "" : pupevent 890
                AddScore ComboValue * ComboCount
            case 4, 5 'super deathblow
                DMD "", "", "superdeathblow", eNone, eNone, eBlink, 1500, True, "Fanfare3"
                DMD "", CL(1, FormatScore(ComboValue * ComboCount * 3)), "", eNone, eBlink, eNone, 1500, True, "" : pupevent 891
                AddScore ComboValue * ComboCount * 3
        End Select
        StopCombo
    End If
End Sub

'*******************
'  Extra Bonus Subs
'*******************

Sub aBonusSwitches_Hit(idx)
    SwitchBonusCount = SwitchBonusCount + 1
End Sub

'*********************
'   Tomb Treasures
'*********************
' Collecting Super Jackpot hits, spinner hits and other shots will turn on a Tomb Treasure
' collect at the left ramp
'1.	15 Million
'2.	Super Slings (slingshots worth 250k + 1K increment for rest of ball)
'3.	Adds additional 15M to current Super Pyramid Jackpot and starts !! Feliz Navidad Cabrones !!
'4.	Super Combos (5x combos and deathblows for rest of ball)
'5.	Light Extra Ball
'6.	Light Ball Save.
'7.	Collect 2X Bonus - This 2X is multiplied by the current PF multiplier AND your current bonus multiplier so very large collects are possible here!
'8.	+5x Super Pyramid Jackpot multiplier
'9.	50 Million
'10.Start La danza del Fuego (super-wizard mode)

Sub StartTombTreasure
    SetLamp 12, 1
    bTombTreasureReady = True
    If balls = 1 then
        DMD "", "", "treasure", eNone, eNone, eBlink, 1500, True, "vo_shoottheleftramp" : pupevent 892
    Else
        DMD "", "", "treasure", eNone, eNone, eBlink, 1500, True, "vo_shoottheleftramp2" : pupevent 892
    End if
End Sub

Sub AwardTombTreasure
    SetLamp 12, 0
    LightEffect 2
    Select Case TombTreasureCount
        Case 0:
            DMD CL(0, "HELL AWARD"), CL(1, "15 MILLION"), "", eNone, eBlink, eNone, 1500, True, "" : pupevent 893
            Addscore 15000000
        Case 1:
            DMD CL(0, "HELL AWARD"), CL(1, "SUPER SLINGSHOTS"), "", eNone, eBlink, eNone, 1500, True, "" : pupevent 894
            SlingshotValue = 250000
        Case 2:
            DMD CL(0, "HELL AWARD"), CL(1, "+15 MILL GOD FLESH"), "", eNone, eBlink, eNone, 1500, True, "" : pupevent 895
            SuperPyramidValue = SuperPyramidValue + 15000000
            StartFelizNavidadCabrones
        Case 3:
            DMD CL(0, "HELL AWARD"), CL(1, "SUPER 5X COMBO"), "", eNone, eBlink, eNone, 1500, True, "" : pupevent 896
            bSuperCombo = True
        Case 4:
            DMD CL(0, "HELL AWARD"), CL(1, "EXTRA SOUL IS LIT"), "", eNone, eBlink, eNone, 1500, True, "" : pupevent 897
            Light047.State = 1
        Case 5:
            DMD CL(0, "HELL AWARD"), CL(1, "SOUL SAVE 60 SEC"), "", eNone, eBlink, eNone, 1500, True, "" : pupevent 898
            EnableBallSaver 60
        Case 6:
            DMD CL(0, "HELL AWARD"), CL(1, "COLLECT 2X BONUS"), "", eNone, eBlink, eNone, 1500, True, "" : pupevent 899
            BonusMultiplier(CurrentPlayer) = BonusMultiplier(CurrentPlayer) + 2
        Case 7:
            DMD CL(0, "HELL AWARD"), CL(1, "SUPER GOD FLESH 5X"), "", eNone, eBlink, eNone, 1500, True, "" : pupevent 700
            SuperPyramidMultiplier = SuperPyramidMultiplier + 5
        Case 8:
            DMD CL(0, "HELL AWARD"), CL(1, "50 MILLION"), "", eNone, eBlink, eNone, 1500, True, "" : pupevent 701
            Addscore 50000000
        Case 9:
            DMD CL(0, "HELL AWARD"), CL(1, "EXTRA SOUL IS LIT"), "", eNone, eBlink, eNone, 1500, True, "" : pupevent 702
            StartLaDanzaDelFuego
    End Select
    TombTreasureCount = (TombTreasureCount + 1)MOD 10
    bTombTreasureReady = False
End Sub

'*************************
' Feliz Navidad Cabrones
'*************************
' Mode 11
' 3rd Tomb Award
' 2 multiball mode
' 2 arrows lit red,
' shoot a red one it becomes green,
' shoot a green one it becomes red
' make all arrows green
' shoot the witch for a Super Jackpot (which can be multiplied by 3 according to the strength of the hit)
' start over with more arrows

Sub StartFelizNavidadCabrones
    DMD "", "", "feliznavidad", eNone, eNone, eBlink, 1500, True, "fanfare2" : pupevent 703
    If Mode(CurrentPlayer, 0) <> 0 then StopCurrentMode
    StopBRUJALetter
    Mode(CurrentPlayer, 0) = 11
    'start with 2 lights
    SetLightColor light056, red, 2
    SetLightColor light053, red, 2
    AddMultiball 1
    LightEffect 5
    post001.IsDropped = 0:PlaySoundAt "fx_SolenoidOn", Trigger010
    post002.IsDropped = 0
    vpmtimer.addtimer 2500, "PlaySoundAt""fx_SolenoidOff"", Trigger010: post001.IsDropped = 1:post002.IsDropped = 1 '"
    FNCStep = 0
    EnableBallsaver 20
End Sub

Sub StopFNC
    StopAddaBall
    Mode(CurrentPlayer, 0) = 0
End Sub

Sub CheckFNC
    Select Case FNCStep
        Case 0                                                ' two arrow lits in Red and they both must be green to continue
            If light056.State = 1 AND light053.State = 1 Then 'both lights are green so go to the next step
                DMD "  MADNESS JACKPOT", CL(1, "1.000.000"), "", eNone, eBlink, eNone, 1500, True, "vo_1million" : pupevent 704
                Addscore 1000000
                FNCStep = 1
                SetLightColor light056, red, 2
                SetLightColor light053, red, 2
                SetLightColor light055, red, 2
                EnableBallsaver 15
            End If
        Case 1                                                                       '3 lights
            If light056.State = 1 AND light053.State = 1 AND light055.State = 1 Then 'all 3 lights are green so go to the next step
                DMD "  MADNESS JACKPOT", CL(1, "2.000.000"), "", eNone, eBlink, eNone, 1500, True, "vo_2million" : pupevent 705
                Addscore 2000000
                FNCStep = 2
                SetLightColor light056, red, 2
                SetLightColor light053, red, 2
                SetLightColor light055, red, 2
                SetLightColor light052, red, 2
                EnableBallsaver 15
            End If
        Case 2                                                                                              '4 lights
            If light056.State = 1 AND light053.State = 1 AND light055.State = 1 AND light052.State = 1 Then 'all 4 lights are green so go to the next step
                DMD "  MADNESS JACKPOT", CL(1, "3.000.000"), "", eNone, eBlink, eNone, 1500, True, "vo_3million" : pupevent 706
                Addscore 3000000
                FNCStep = 3
                SetLightColor light056, red, 2
                SetLightColor light053, red, 2
                SetLightColor light055, red, 2
                SetLightColor light052, red, 2
                SetLightColor light054, red, 2
                EnableBallsaver 15
                bAddaBallActivated = True:Light046.State = 2
            End If
        Case 3                                                                                                                     '5 lights
            If light056.State = 1 AND light053.State = 1 AND light055.State = 1 AND light052.State = 1 AND light054.State = 1 Then 'all 5 lights are green so go to the next step
                DMD "  MADNESS JACKPOT", CL(1, "4.000.000"), "", eNone, eBlink, eNone, 1500, True, "vo_4million" : pupevent 707
                Addscore 4000000
                FNCStep = 4
                SetLightColor light056, red, 2
                SetLightColor light053, red, 2
                SetLightColor light055, red, 2
                SetLightColor light052, red, 2
                SetLightColor light054, red, 2
                SetLightColor light049, red, 2
                EnableBallsaver 20
            End If
        Case 4                                                                                                                                            '6 lights
            If light056.State = 1 AND light053.State = 1 AND light055.State = 1 AND light052.State = 1 AND light054.State = 1 AND light049.State = 1 Then 'all 6 lights are green so go to the next step
                DMD "  MADNESS JACKPOT", CL(1, "5.000.000"), "", eNone, eBlink, eNone, 1500, True, "vo_5million" : pupevent 708
                Addscore 5000000
                FNCStep = 5
                SetLightColor light056, red, 2
                SetLightColor light053, red, 2
                SetLightColor light055, red, 2
                SetLightColor light052, red, 2
                SetLightColor light054, red, 2
                SetLightColor light049, red, 2
                SetLightColor light057, red, 2
                EnableBallsaver 20
            End If
        Case 5                                                                                                                                                                   'all 7 lights
            If light056.State = 1 AND light053.State = 1 AND light055.State = 1 AND light052.State = 1 AND light054.State = 1 AND light049.State = 1 AND light057.State = 1 Then 'all 7 lights are green
                DMD "  MADNESS JACKPOT", CL(1, "10.000.000"), "", eNone, eBlink, eNone, 1500, True, "fanfare3" : pupevent 709
                DMD "PAIN AND PLEASURE", CL(1, "COMPLETED"), "", eNone, eBlink, eNone, 1500, True, "" : pupevent 710
                Addscore 10000000
                StopFNC
                StartBRUJALetter
            End If
    End Select
End Sub

'*************************
'   La Danza del Fuego
'*************************
'Mode 12 - Mega Wizard Mode
'10th Tomb Award
'6 ball multiball
'All shots are lit for jackpot

Sub StartLaDanzaDelFuego
    DMD "", "", "danza", eNone, eNone, eBlink, 1500, True, "fanfare1" : pupevent 849
    If Mode(CurrentPlayer, 0) <> 0 then StopCurrentMode
    Mode(CurrentPlayer, 0) = 12
    AddMultiball 6
    LightEffect 5
    post001.IsDropped = 0:PlaySoundAt "fx_SolenoidOn", Trigger010
    post002.IsDropped = 0
    vpmtimer.addtimer 12000, "PlaySoundAt""fx_SolenoidOff"", Trigger010: post001.IsDropped = 1:post002.IsDropped = 1 '"
    EnableBallsaver 30
    SetLightColor light056, red, 2
    SetLightColor light053, red, 2
    SetLightColor light055, red, 2
    SetLightColor light052, red, 2
    SetLightColor light054, red, 2
    SetLightColor light049, red, 2
    SetLightColor light057, red, 2
End Sub

Sub CheckLDDF                                                                                                                                                            'turn on witch SJP
    If light056.State = 0 AND light053.State = 0 AND light055.State = 0 AND light052.State = 0 AND light054.State = 0 AND light049.State = 0 AND light057.State = 0 Then 'all 7 lights are off
        BrujaFlasher.Enabled = 1
        bLDDFSJPEnabled = True
    End If
End Sub

Sub RestartLDDF
    EnableBallsaver 20
    SetLightColor light056, red, 2
    SetLightColor light053, red, 2
    SetLightColor light055, red, 2
    SetLightColor light052, red, 2
    SetLightColor light054, red, 2
    SetLightColor light049, red, 2
    SetLightColor light057, red, 2
End Sub



'*****************************************PUPEVENTS**********************************

' COPY EVERYTHING BELOW TO THE TOP OF YOUR TABLE SCRIPT UNDER OPTION EXPLICIT                             Start Pup Pack

'****** PuP Variables ******

Dim usePUP: Dim cPuPPack: Dim PuPlayer: Dim PUPStatus: PUPStatus=false ' dont edit this line!!!

'*************************** PuP Settings for this table ********************************

usePUP   = true               ' enable Pinup Player functions for this table
cPuPPack = "HellRaiser"    ' name of the PuP-Pack / PuPVideos folder for this table

'//////////////////// PINUP PLAYER: STARTUP & CONTROL SECTION //////////////////////////

' This is used for the startup and control of Pinup Player

Sub PuPStart()
    If PUPStatus=true then Exit Sub
    If usePUP=true then
        Set PuPlayer = CreateObject("PinUpPlayer.PinDisplay")
        If PuPlayer is Nothing Then
            usePUP=false
            PUPStatus=false
        Else
            PuPlayer.B2SInit "",cPuPPack 'start the Pup-Pack
            PUPStatus=true
        End If
    End If
End Sub

Sub pupevent(EventNum)
    if (usePUP=false or PUPStatus=false) then Exit Sub

	Select Case EventNum
		case 820
			' Trigger: 96,1,"GameOver Music",E820,4,GameoverMusic,,100,8,,,,Loop,0
			PlayRandomGameOverSong
		case 826
			' Trigger: 348,1,TiltmusicStop,E826,4,Music14,"14- Hellraiser 2 Suite 7.mp3",0,2,46,,,SplashResume,0
		    	MusicVolume = 0
		case 901
			' Trigger: 97,1,"Stop GameOver Music",E901,4,GameoverMusic,,0,20,1,,,StopPlayer,0
			StopSong
	End Select

    PuPlayer.B2SData "E"&EventNum,1  'send event to Pup-Pack
End Sub

' ******* How to use PUPEvent to trigger / control a PuP-Pack *******

' Usage: pupevent(EventNum)

' EventNum = PuP Exxx trigger from the PuP-Pack

' Example: pupevent 102

' This will trigger E102 from the table's PuP-Pack

' DO NOT use any Exxx triggers already used for DOF (if used) to avoid any possible confusion

'************ PuP-Pack Startup **************

PuPStart() 'Check for PuP - If found, then start Pinup Player / PuP-Pack


'***********************************************LEFT SCREEN***************************************************

Sub ApronLeft_Timer()
		ApronLeft.VideoCapUpdate="PUPSCREEN18"
end Sub		

If PupScreen1 = 1 Then
	ApronLeft.VideoCapWidth=200	
	ApronLeft.VideoCapHeight=200
	ApronLeft.visible=true	
    ApronLeft.TimerEnabled=true
    ApronLeft.TimerInterval=60
    If FPS = 1 Then ApronLeft.timerinterval=40
End If

if PuPScreen1 = 0 Then
    ApronLeft.visible=false	
    ApronLeft.TimerEnabled=false
    'PuPlayer.SendMSG "{ ""mt"":301, ""SN"": 18, ""FN"":12 }" 
End If
'******************************************RIGHT Screen ******************************** 
Sub ApronRight_Timer()
		ApronRight.VideoCapUpdate="PUPSCREEN19"
end Sub		

If PupScreen1 = 1 Then
	ApronRight.VideoCapWidth=200	
	ApronRight.VideoCapHeight=200
	ApronRight.visible=true	
    ApronRight.TimerEnabled=true
    ApronRight.TimerInterval=60
    If FPS = 1 Then ApronRight.timerinterval=40
End If

if PuPScreen1 = 0 Then
    ApronRight.visible=false	
    ApronRight.TimerEnabled=false
    'PuPlayer.SendMSG "{ ""mt"":301, ""SN"": 19, ""FN"":12 }"
End If


'**************************************Glow Balls***********************************

'**********************************************************************************************************
'*********** Glowball Section *****************************************************************************
Dim GlowBall, CustomBulbIntensity(10)
Dim  GBred(10)
Dim GBgreen(10)
Dim GBblue(10)
Dim CustomBallImage(10), CustomBallLogoMode(10), CustomBallDecal(10), CustomBallGlow(10)


' default Ball
CustomBallGlow(0) = 		False
CustomBallImage(0) = 		"ball"
CustomBallLogoMode(0) = 	False
CustomBallDecal(0) = 		""
CustomBulbIntensity(0) = 	0.01
GBred(0) = 0 : GBgreen(0)	= 0 : GBblue(0) = 0

' Purple GlowBall
CustomBallGlow(1) = 		True
CustomBallImage(1) = 		"glowball purple"
CustomBallLogoMode(1) = 	True
CustomBallDecal(1) = 		""
CustomBulbIntensity(1) = 	0
GBred(1) = 255 : GBgreen(1)	= 0 : GBblue(1) = 255


' green GlowBall
CustomBallGlow(2) = 		True
CustomBallImage(6) = 		"glowball green"
CustomBallLogoMode(6) = 	True
CustomBallDecal(6) = 		""
CustomBulbIntensity(6) = 	0
GBred(2) = 100 : GBgreen(2)	= 255 : GBblue(2) = 100

' blue GlowBall
CustomBallGlow(3) = 		True
CustomBallImage(3) = 		"glowball blue"
CustomBallLogoMode(3) = 	True
CustomBallDecal(3) = 		""
CustomBulbIntensity(3) = 	0
GBred(3) = 50 : GBgreen(3)	= 50 : GBblue(3) = 255


' Orange GlowBall
CustomBallGlow(4) = 		True
CustomBallImage(4) = 		"glowball orange"
CustomBallLogoMode(4) = 	True
CustomBallDecal(4) = 		""
CustomBulbIntensity(4) = 	0
GBred(4) = 255 : GBgreen(4)	= 165 : GBblue(4) = 000


' red GlowBall
CustomBallGlow(5) = 		True
CustomBallImage(5) = 		"glowball red"
CustomBallLogoMode(5) = 	True
CustomBallDecal(5) = 		""
CustomBulbIntensity(5) = 	0
GBred(5) = 255 : GBgreen(5)	= 99 : GBblue(5) = 71

' white GlowBall
CustomBallGlow(6) = 		True
CustomBallImage(6) = 		"glowball white"
CustomBallLogoMode(6) = 	True
CustomBallDecal(6) = 		""
CustomBulbIntensity(6) = 	0
GBred(6) = 255 : GBgreen(6)	= 255 : GBblue(6) = 255

' yellow GlowBall
CustomBallGlow(7) = 		True
CustomBallImage(7) = 		"glowball yellow"
CustomBallLogoMode(7) = 	True
CustomBallDecal(7) = 		""
CustomBulbIntensity(7) = 	0
GBred(7) = 255 : GBgreen(7)	= 255 : GBblue(7) = 000

' gold GlowBall
CustomBallGlow(8) = 		True
CustomBallImage(8) = 		"glowball gold"
CustomBallLogoMode(8) = 	True
CustomBallDecal(8) = 		""
CustomBulbIntensity(8) = 	0
GBred(8) = 255 : GBgreen(8)	= 215 : GBblue(8) = 000



' *** prepare the variable with references to three lights for glow ball ***
Dim Glowing(10)
Set Glowing(0) = Glowball1 : Set Glowing(1) = Glowball2 : Set Glowing(2) = Glowball3 : Set Glowing(3) = Glowball4 : Set Glowing(4) = Glowball5 : Set Glowing(5) = Glowball6 : Set Glowing(6) = Glowball7 : Set Glowing(7) = Glowball8 : Set Glowing(8) = Glowball9


'*** change ball appearance ***

Sub ChangeBall(ballnr)
	Dim BOT, ii, col
	table1.BallDecalMode = CustomBallLogoMode(ballnr)
	table1.BallFrontDecal = CustomBallDecal(ballnr)
	table1.DefaultBulbIntensityScale = CustomBulbIntensity(ballnr)
	table1.BallImage = CustomBallImage(ballnr)
	GlowBall = CustomBallGlow(ballnr)
	For ii = 0 to 8
		col = RGB(GBred(ballnr), GBgreen(ballnr), GBblue(ballnr))
		Glowing(ii).color = col : Glowing(ii).colorfull = col 
	Next
End Sub

' *** Ball Shadow code / Glow Ball code / Primitive Flipper Update ***

Dim BallShadowArray
BallShadowArray = Array (BallShadow1, BallShadow2, BallShadow3,BallShadow004,BallShadow005)
Const anglecompensate = 15

Sub GraphicsTimer_Timer()
	Dim BOT, b
    BOT = GetBalls

	' switch off glowlight for removed Balls
	IF GlowBall Then
		For b = UBound(BOT) + 1 to 3
			If GlowBall and Glowing(b).state = 1 Then Glowing(b).state = 0 End If
		Next
	End If

    For b = 0 to UBound(BOT)
		' *** move ball shadow for max 3 balls ***
'		If BallShadow and b < 3 Then
'			If BOT(b).X < table1.Width/2 Then
'				BallShadowArray(b).X = ((BOT(b).X) - (50/6) + ((BOT(b).X - (table1.Width/2))/7)) + 10
'			Else
'				BallShadowArray(b).X = ((BOT(b).X) + (50/6) + ((BOT(b).X - (table1.Width/2))/7)) - 10
'			End If
'			BallShadowArray(b).Y = BOT(b).Y + 20 : BallShadowArray(b).Z = 1
'			If BOT(b).Z > 20 Then BallShadowArray(b).visible = 1 Else BallShadowArray(b).visible = 0 End If
'		End If
		' *** move glowball light for max 3 balls ***
		If GlowBall and b < 9 Then
			If Glowing(b).state = 0 Then Glowing(b).state = 1 end if
			Glowing(b).BulbHaloHeight = BOT(b).z + 25
			Glowing(b).x = BOT(b).x : Glowing(b).y = BOT(b).y + anglecompensate
			Glowing(b).falloff=GlowAura 'GlowBlob Auroa radius
			Glowing(b).intensity=GlowIntensity 'Glowblob intensity
		End If
	Next
End Sub




Sub Glowball_Init
	ChangeBall(ChooseBall)
	If GlowBall Then GraphicsTimer.enabled = True End If
End Sub
 

'*****************************************
'	iaakki's	Blood Trails
'*****************************************
Dim BloodTrails

dim objBlood(9)

for xxx = 0 to 9
'	msgbox xxx
'	Eval("BallShadow" & xxx+1).image = "arrow"
	Set objBlood(xxx) = Eval("BloodTrail0" & xxx)
	objBlood(xxx).image = "blood" & RndInt(1,6)
'	objBlood(xxx).image = "arrow"
	objBlood(xxx).z = 0 + xxx/100
	objBlood(xxx).depthbias = -10 - xxx
	objBlood(xxx).uservalue = 0
next

dim objDummy
for xxx = 10 to 19
'	msgbox xxx
'	Eval("BallShadow" & xxx+1).image = "arrow"
	Set objDummy = Eval("BloodTrail0" & xxx)
	objDummy.image = "blood" & RndInt(1,6)
'	objBlood(xxx).image = "arrow"
    objDummy.z = 0 + 19/100
	objDummy.depthbias = -29
	objDummy.uservalue = 0
next


dim Bcnt : Bcnt = 0
dim prevBcnt, rotateCnt

dim TableSlope
TableSlope = table1.SlopeMin + (table1.SlopeMax - table1.SlopeMin) * table1.GlobalDifficulty

dim resetTrails : resetTrails = 0
Sub BloodTrailUpdate_timer()

	if bMultiBallMode = False then
		if resetTrails = 1 Then
			for xxx = 0 to 9
				objBlood(xxx).x = 685: objBlood(xxx).y = 2234
				objBlood(xxx).visible = false
				objBlood(xxx).z = 0 + xxx/100
				objBlood(xxx).depthbias = -10 - xxx + 100
				objBlood(xxx).uservalue = 0
			next
			resetTrails = 0
'			debug.print "only once okey?"
		end if
		Exit Sub 'make this run only in multiball mode
	end if

	Dim BOT, b, currentBallVelx, currentBallVely, currentBallVel, currentBallZ
	BOT = GetBalls

	resetTrails = 1

	For b = 0 to UBound(BOT)
		currentBallVel = BallVel(BOT(b))
		if currentBallVel > 0 then 
			currentBallZ = BOT(b).z
			'move
			objBlood(Bcnt).X = BOT(b).X
			objBlood(Bcnt).Y = BOT(b).Y

			'make it thinner by time and make them fall unless on ramp. Use uservalue for ramp status
			dim CurrentFallValue
			for xxx = 0 to 9
				if Not xxx = Bcnt then
					CurrentFallValue = objBlood(xxx).uservalue
					objBlood(xxx).size_x = objBlood(xxx).size_x * 0.95
					if CurrentFallValue > 0 Then
						CurrentFallValue = CurrentFallValue - 30
						if CurrentFallValue < 0 then CurrentFallValue = 0

						objBlood(xxx).rotx = objBlood(xxx).rotx / 2
'						objBlood(xxx).rotx = 0
						objBlood(xxx).z = CurrentFallValue + xxx/100

						objBlood(xxx).uservalue = CurrentFallValue
						if CurrentFallValue = 0 then 
							objBlood(xxx).rotx = 0
						end if
					end if
				end if
			next
			

			'resize by speed
			if currentBallVel > 50 then currentBallVel = 50
			objBlood(Bcnt).size_x = 5 - 2*(currentBallVel/50)
			objBlood(Bcnt).size_y = 5 + (currentBallVel/8)
			
			'ball direction
			objBlood(Bcnt).objrotz = Atn2(BOT(b).vely,BOT(b).velx)/(PI/180) - 90

			'ramp
			if currentBallZ > 27 then
				objBlood(Bcnt).z = currentBallZ - 24 + Bcnt/100

				'ramp angle
				objBlood(Bcnt).rotx = (Atn(BOT(b).velz / SQR(BOT(b).velx*BOT(b).velx+BOT(b).vely*BOT(b).vely)))/(PI/180) - 3


				if Not InRect(BOT(b).x, BOT(b).y,275,341,699,432,799,1558,85,1545) Then 'added wireramps here
'					debug.print "ramp!"
					objBlood(Bcnt).uservalue = 0
				Else	'not on a solid ramp
'					debug.print "not solid ramp"
					objBlood(Bcnt).uservalue = objBlood(Bcnt).z	'fall amount
				end if

			else
				objBlood(Bcnt).z = Bcnt/100
				objBlood(Bcnt).rotx = 0
				objBlood(Bcnt).uservalue = 0
			end if

			prevBcnt = Bcnt
			Bcnt = Bcnt + 1
			if Bcnt > 9 Then 
				Bcnt = 0
			end if
		end if
	Next

End Sub


'*****************
' Maths
'*****************
Dim PI: PI = 4*Atn(1)

Function dSin(degrees)
	dsin = sin(degrees * Pi/180)
End Function

Function dCos(degrees)
	dcos = cos(degrees * Pi/180)
End Function

Function Atn2(dy, dx)
	If dx > 0 Then
		Atn2 = Atn(dy / dx)
	ElseIf dx < 0 Then
		If dy = 0 Then 
			Atn2 = pi
		Else
			Atn2 = Sgn(dy) * (pi - Atn(Abs(dy / dx)))
		end if
	ElseIf dx = 0 Then
		if dy = 0 Then
			Atn2 = 0
		else
			Atn2 = Sgn(dy) * pi / 2
		end if
	End If
End Function

Function dAtn(degrees)
	dAtn = atn(degrees * Pi/180)
End Function


Function RndInt(min, max)
    RndInt = Int(Rnd() * (max-min + 1) + min)' Sets a random number integer between min and max
End Function

Function RndNum(min, max)
    RndNum = Rnd() * (max-min) + min' Sets a random number between min and max
End Function

'//  Determines if a Points (px,py) is inside a 4 point polygon A-D
'//  in Clockwise/CCW order
Function InRect(px,py,ax,ay,bx,by,cx,cy,dx,dy)
	Dim AB, BC, CD, DA
	AB = (bx*py) - (by*px) - (ax*py) + (ay*px) + (ax*by) - (ay*bx)
	BC = (cx*py) - (cy*px) - (bx*py) + (by*px) + (bx*cy) - (by*cx)
	CD = (dx*py) - (dy*px) - (cx*py) + (cy*px) + (cx*dy) - (cy*dx)
	DA = (ax*py) - (ay*px) - (dx*py) + (dy*px) + (dx*ay) - (dy*ax)
 
	If (AB <= 0 AND BC <=0 AND CD <= 0 AND DA <= 0) Or (AB >= 0 AND BC >=0 AND CD >= 0 AND DA >= 0) Then
		InRect = True
	Else
		InRect = False       
	End If
End Function


