/*	Documents\StarCraft II\Accounts\<numbers>\Variables.txt 
	The Account Folder has the Variables.txt file
	and Hotkeys folder


	Within Variables.txt file is a hotkeyprofile= key
	Values For standard (non-modfied SC2 profiles):

	hotkeyprofile=0_Default  		; Standard
	hotkeyprofile=1_NameRightSide	; Standard for Lefties
	hotkeyprofile=2_GridLeftSide	; Grid
	hotkeyprofile=3_GridRightSide	; Grid for Lefties
	hotkeyprofile=4_Classic			; Classic

	If using a user hotkey profiles, it will contain the active hotkey file which is stored in ..\Hotkeys folder
	eg
	hotkeyprofile=Good 				; using the good Hotkey profile


	Default=[nothing] (that would be the Normal Left Side)
	Suffix=_NRS = Normal Right Side (standard for lefties)
	Suffix=_GLS = Grid Left Side
	Suffix=_GRS = Grid Right Side (for lefties)
	Suffix=_SC1 = Classic

	Hotkey file eg Documents\StarCraft II\Accounts\<numbers>\Hotkeys\
	This is pretty much just an ini file containing the altered hotkeys
	
	-	Has a [Settings] section
		If based on grid profile will contian a 
		Grid=1 (this is missing in the other profiles)

	- A "Suffix=" line 
		indicating the standard hotkey profile the active settings are based on 
		(if there's no Suffix line then it's based on "Standard")

		_USDL ...not sure universal? This appears in the mpq extracted hotkeys


	obviously for grid layout commands (command card) 00-14 corresond to the keyboard letters

*/

; aSendKeys stores the keys which can be sent to SC to invoke abilities
; aAHKHotkeys stores AHK compatible hotkeys which can be used to create hotkeys for abilities e.g. when the user presses the select army hotkey

class SC2Keys
{
	static aSendKeys, aAHKHotkeys, debug := []
	; stores the keys as well for individual key lookup
	; and sets the AHK hotkey object too
	getAllKeys() 
	{
		this.getHotkeyProfile(file, suffix)
		if (suffix = "_GLS" || suffix = "_GRS")
			obj := this.readProfileGrid(file, suffix)
		else obj := this.readProfileNonGrid(file, suffix)
		this.aAHKHotkeys := []
		for hotkeyReference, sentKey in this.aSendKeys := obj	
			this.aAHKHotkeys[hotkeyReference] := this.convertSendKeysToAHKHotkey(sentKey)
		return this.aSendKeys
	}
	key(hotkeyReference)
	{
		if !isobject(this.aSendKeys) ; haven't set the keys yet
			this.getAllKeys()
		return this.aSendKeys[hotkeyReference]
	}
	AHKHotkey(hotkeyReference)
	{
		if !isobject(this.aSendKeys) ; haven't set the keys yet
			this.getAllKeys()
		return this.aAHKHotkeys[hotkeyReference]
	}	
	getHotkeyProfile(byRef file := "", byRef suffix := "")
	{
		file := suffix := ""
		accountFolder := getAccountFolder()
		variablesFilePath := accountFolder "Variables.txt"
		Loop, Read, %variablesFilePath%
		{
			if instr(A_LoopReadLine, "hotkeyprofile=")
				hotkeyProfile := SubStr(A_LoopReadLine, 15)
		} until hotkeyProfile
		file := accountFolder "Hotkeys\" hotkeyProfile ".SC2Hotkeys"

		if hotkeyProfile in 0_Default,1_NameRightSide,2_GridLeftSide,3_GridRightSide,4_Classic
		{
			if !FileExist(file) ; Although extremely unlikely, you can save a hotkeyProfile with these names i.e. 0_Default.SC2Hotkeys
			{
				if (hotkeyProfile = "1_NameRightSide")
					suffix := "_NRS"
				else if (hotkeyProfile = "2_GridLeftSide")
					suffix := "_GLS"
				else if (hotkeyProfile = "3_GridRightSide")
					suffix := "_GRS"
				else if (hotkeyProfile = "4_Classic")
					suffix := "_SC1"
				else suffix := "Standard" ; 0_Default
			}
		}
		if !suffix
			IniRead, suffix, %file%, Settings, Suffix, Standard		

		; used by the debugging GUI
		this.debug.accountFolder := accountFolder
		this.debug.variablesFilePath := variablesFilePath
		this.debug.hotkeyProfile := file
		this.debug.hotkeySuffix := suffix

		if FileExist(variablesFilePath) && getTime()
		{
			settimer, _SC2KeysFileModificationCheck, 2000
			FileGetTime, modifiedTime, %variablesFilePath%
			this.debug.VariablesModifiedTime := modifiedTime
		}
		else settimer, _SC2KeysFileModificationCheck, Off
		return 
		
		; Monitor modification date and update keys. 
		; This changes every time 'accept' is pressed in the options menu, as well as 'accept' in the hotkey menu. (even if nothing changes)
		_SC2KeysFileModificationCheck:
		if !getTime()
			settimer, _SC2KeysFileModificationCheck, Off 
		FileGetTime, modifiedTime, % SC2Keys.debug.variablesFilePath
		if SC2Keys.debug.VariablesModifiedTime != modifiedTime
			SC2Keys.getAllKeys()
		return
	}
	; sc ability hotkeys can only be 1 key
	getDefaultKeys(suffix)
	{
		; Section and key columns are not used by grid layout!
		static keys := "
		( LTrim c 					
			;myLookupReference					Standard 			_NRS 				_SC1 				grid							section 				key
			ReturnCargo 						|c 					|c					|c 					|CommandButton06				|Commands 				|ReturnCargo
			Marine/Barracks						|a 					|m					|m 					|CommandButton00				|Commands 				|Marine/Barracks
			Reaper/Barracks						|r 					|p					|e 					|CommandButton01				|Commands 				|Reaper/Barracks
			Marauder/Barracks		 			|d					|u					|f					|CommandButton02				|Commands 				|Marauder/Barracks
			Ghost/Barracks						|g  				|g					|g 					|CommandButton03				|Commands 				|Ghost/Barracks
			Hellion/Factory						|e 					|h					|v 					|CommandButton00				|Commands 				|Hellion/Factory
			WidowMine/Factory					|d 					|u					|d 					|CommandButton01				|Commands 				|WidowMine/Factory
			SiegeTank/Factory					|s 					|i					|t 					|CommandButton02				|Commands 				|SiegeTank/Factory
			HellionTank/Factory					|r 					|p					|h	 				|CommandButton03				|Commands 				|HellionTank/Factory
			Thor/Factory						|t 					|d					|g 					|CommandButton04				|Commands 				|Thor/Factory
			VikingFighter/Starport				|v	 				|k					|w 					|CommandButton00				|Commands 				|VikingFighter/Starport
			Medivac/Starport					|d 					|m					|d 					|CommandButton01				|Commands 				|Medivac/Starport
			Raven/Starport						|r 					|v					|v 					|CommandButton02				|Commands 				|Raven/Starport
			Banshee/Starport					|e 					|n					|e 					|CommandButton03				|Commands 				|Banshee/Starport
			Battlecruiser/Starport 				|b 					|b					|b 					|CommandButton04				|Commands 				|Battlecruiser/Starport
			Zealot		  						|z 					|o					|z 					|CommandButton00				|Commands 				|Zealot 				; Gateway units lack the /structure
			Sentry 		  						|e 					|n					|e 					|CommandButton01				|Commands 				|Sentry 				; SC has a menu for both gateway & warpgate
			Stalker 	  						|s 					|l					|d 					|CommandButton02				|Commands 				|Stalker 				; But it doesn't seem like you can change them individually
			HighTemplar 						|t 					|h					|t 					|CommandButton05				|Commands 				|HighTemplar
			DarkTemplar 						|d 					|k					|k 					|CommandButton06				|Commands 				|DarkTemplar
			Phoenix/Stargate					|x 					|p					|e 					|CommandButton00				|Commands 				|Phoenix/Stargate
			Oracle/Stargate						|e 					|b					|l 					|CommandButton01				|Commands 				|Oracle/Stargate
			VoidRay/Stargate					|v 					|d					|o 					|CommandButton02				|Commands 				|VoidRay/Stargate
			Tempest/Stargate					|t 					|u					|t 					|CommandButton03				|Commands 				|Tempest/Stargate
			Carrier/Stargate					|c 					|i					|c 					|CommandButton04				|Commands 				|Carrier/Stargate
			Observer/RoboticsFacility			|b 					|o					|o 					|CommandButton00				|Commands 				|Observer/RoboticsFacility
			WarpPrism/RoboticsFacility			|a 					|p					|s 					|CommandButton01				|Commands 				|WarpPrism/RoboticsFacility
			Immortal/RoboticsFacility			|i 					|i					|i 					|CommandButton02				|Commands 				|Immortal/RoboticsFacility
			Colossus/RoboticsFacility			|c 					|l					|v 					|CommandButton03				|Commands 				|Colossus/RoboticsFacility
			Queen 								|q 					|u					|e 					|CommandButton01				|Commands 				|Queen 		; SC only allows same key for hatch/lair/hive
			UpgradeToWarpGate/Gateway 			|g 					|g					|g 					|CommandButton10				|Commands 				|UpgradeToWarpGate/Gateway 		
			; The key 'BunkerUnloadAll' is shared between bunkers, medivacs, warp prisms, and overlords.
			; **Note  the command button is 13 for medivacs, warp prisms, and overlords but 14 for bunkers! 
			; This would cause issues with grid layouts if I ever did anything with bunkers, would need a separate lookup reference for bunkers (with the correct command button)
			TransportUnloadAll					|d 					|d					|u 					|CommandButton13				|Commands 				|BunkerUnloadAll		
			QueenSpawnLarva						|v 					|l					|v 					|CommandButton11				|Commands 				|MorphMorphalisk/Queen		
		)"

		if suffix not in Standard,_NRS,_SC1,_GLS,_GRS
			suffix :=  "Standard" ; lets just try to use standard - should shrow and error somewhere to alert user
		obj := []
		arrayPos := suffix = "_NRS" ? 3 : suffix = "_SC1" ? 4 : suffix = "_GLS" || suffix = "_GRS" ? 5 : 2
		loop, parse, keys, `n, %A_Tab%
		{
			a := StrSplit(A_LoopField, "|", A_Tab A_Space)
			obj.insert(a.1, {"hotkey": a[arrayPos], "section": a[6], "inikey": a[7]})
		}
		return obj
	}

	readProfileHotkeysSection(file)
	{
		; Add all new hotkey section SC hotkeys here (excluding grid keys)
		keys := "
		( LTrim c 					
			;myLookupReference 				Default 					iniKey
			SubgroupNext 					|Tab 						|SubgroupNext
			SubgroupPrev 					|Shift+Tab 					|SubgroupPrev
			ArmySelect 	 					|F2 	 					|ArmySelect
			TownCamera 	 					|Backspace 					|TownCamera
			PauseGame 	 					|Pause 						|PauseGame
			SelectionCancelDrag 			|Escape						|SelectionCancelDrag
			CameraSave1 					|Control+F5 				|CameraSave0
			CameraSave2 					|Control+F6 				|CameraSave1
			CameraSave3 					|Control+F7 				|CameraSave2
			CameraSave4 					|Control+F8 				|CameraSave3
			CameraSave5 					|Control+Shift+F5 			|CameraSave4
			CameraSave6 					|Control+Shift+F6 			|CameraSave5
			CameraSave7 					|Control+Shift+F7 			|CameraSave6
			CameraSave8 					|Control+Shift+F8 			|CameraSave7
			CameraView1 					|F5 			 			|CameraView0
			CameraView2 					|F6 			 			|CameraView1
			CameraView3 					|F7 			 			|CameraView2
			CameraView4 					|F8 			 			|CameraView3
			CameraView5 					|Shift+F5		 			|CameraView4
			CameraView6 					|Shift+F6		 			|CameraView5
			CameraView7 					|Shift+F7		 			|CameraView6
			CameraView8 					|Shift+F8		 			|CameraView7
		)"
		loop, 10 ; Set default control group keys
		{
			group := A_Index - 1
			keys .= "`n" "ControlGroupRecall" group 	"|" group 				"|" "ControlGroupRecall" group
				. 	"`n" "ControlGroupAppend" group 	"|" "Shift+" group 		"|" "ControlGroupAppend" group
				. 	"`n" "ControlGroupAssign" group 	"|" "Control+" group 	"|" "ControlGroupAssign" group
		}		

		aLookUp := []
		loop, parse, keys, `n, %A_Tab%
		{
			a := StrSplit(A_LoopField, "|", A_Tab A_Space)
			aLookUp.insert(a.1, {"MyReference": a.1,  "hotkey": a[2], "inikey": a[3]})
		}

		obj := []
		fileExists := FileExist(file) ; This isn't required due to inireads default value, but theres little point if the file doesn't exist
		for myReference, item in aLookUp 
		{
			if fileExists
			{
				IniRead, hotkey, %file%, Hotkeys, % item.inikey, % item.hotkey
				obj[myReference] := this.convertHotkey(hotkey)
			}
			else obj[myReference] := this.convertHotkey(item.hotkey)
		}
		; This hotkey doesn't seem to exist in the hotkey editor, so I assume it must always be escape 
		; although there are other hotkeys (TargetCancel) which cancels the targeting mode
		obj.GlobalTargetCancel := "Escape" 

		return obj
	}
	
	readProfileNonGrid(file, suffix)
	{
		obj := this.getDefaultKeys(suffix)
		if FileExist(file) ; This isn't required due to inireads default value, but theres little point if the file doesn't exist
		{
			for k, item in obj 
			{
				IniRead, hotkey, %file%, % item.section, % item.inikey, % item.hotkey
				obj[k].hotkey := hotkey
			}
		}
	 ; I need to think carefully about how this obj is constructed. But can always improve it after writing the auto production functions
	 ; Should most likely use a unitID or unitName lookup 
		for k, item in obj
			obj[k] := this.convertHotkey(item.hotkey)
		return this.combineSimpleObjects(obj, this.readProfileHotkeysSection(file))
	}
	readProfileGrid(file, suffix)
	{
		
		obj := this.getDefaultKeys(suffix)
		keys := suffix = "_GRS" ? "uiop[jkl;'nm,./" : "qwertasdfgzxcvp"
		aLookup := []
		loop, parse, keys
		{
			IniRead, key, %file%, Hotkeys, % "CommandButton" (id := (A_Index-1 < 10 ? "0" : "") A_Index-1), %A_LoopField%
			aLookup["CommandButton" id] := key	
		}
		for i, item in obj 
			obj[i] := this.convertHotkey(aLookup[item.hotkey])
		return this.combineSimpleObjects(obj, this.readProfileHotkeysSection(file))					
	}
	; No multiLevel objects!
	combineSimpleObjects(objects*)
	{
		nObj := []
		for i, obj in objects
		{
			for k, v in obj 
				nObj[k] := v
		}
		return nObj
	}
	; I forgot to include a way to map SC hotkeys to AHK hotkeys (not sent keys).
	; It's easiest just to convert the AHK send key string back to a hotkey and store it in another object rather than playing around with the way this class already works
	convertSendKeysToAHKHotkey(sendString)
	{
		RegExMatch(sendString, "i)\{(.+)}", suffix) ; gets the suffix if it's inside brackets
		hotkey := RegExReplace(sendString, "i)\{.+}") suffix1 ; gets the hotkey prefix if it has one. Leaves the suffix if its not inside brackets
		return hotkey
	}

	; Wrote this a few years ago, but lets roll with it
	; I really need to spend some time checking that it covers all cases correctly
	convertHotkey(String)
	{
							;	"SC2Key": "AhkKey"
		static aTranslate := {	"PageUp": "PgUp"
							,	"PageDown": "PgDn"
							,	"NumPadMultiply": "NumpadMult"
							,  	"NumPadDivide": "NumpadDiv"
							,	"NumPadPlus": "NumpadAdd"				
							,	"NumPadMinus": "NumpadSub"

							, 	"Grave": "``" ;note needs escape character!
							, 	"Minus": "-"
							, 	"Equals": "="
							, 	"BracketOpen": "["
							, 	"BracketClose": "]"
							,	"BackSlash": "\"						
							, 	"SemiColon": ";"
							, 	"Apostrophe": "'"
							, 	"Comma": ","
							, 	"Period": "."
							,	"Slash": "/"

							, 	"LeftMouseButton": "LButton"
							, 	"RightMouseButton": "RButton"
							,	"MiddleMouseButton": "MButton"
							, 	"ForwardMouseButton": "XButton1"
							, 	"BackMouseButton": "XButton2" }
							; apparently nothing can be bound to the wheel (i thought you COULD do that in sc2....)

		; NumpadDel maps to real delete key, same for NumpadIns, Home, End and num-UP,Down,Left,Right, and Num-PageUp/Down and enter
		; {NumpadClear} (num5 with numlock off) doesnt map to anything
		; nothing can be mapped to windows keys or app keys

	; when two hotkeys are present "hotkey,alternateHokey" - note SC stores literal , keys as comma so this is safe 
	if p := instr(String, ",")
		String := SubStr(String, 1, p-1)

	; Easier to use string replace here and have the modifiers separate and outside of the
	; aTranslate associative array. As AHK Associative arrays are indexed alphabetically (not in order in which keys were added)
	; so this would result in modifier strings being incorrectly converted
	; SC2 Hotkeys are done in this Order Control+Alt+Shift+Keyname
	StringReplace, String, String, Control+, ^, All ;use modifier+ so if user actually has something bound to it wont cause issue
	StringReplace, String, String, Alt+, !, All 
	StringReplace, String, String, Shift+, +, All 	;this will also act to remove SC2's joining '+'


		; string replace accounts for differences between AHK send Syntax and SC2 hotkey storage

		for SC2Key, AhkKey in aTranslate
			StringReplace, String, String, %SC2Key%, %AhkKey%, All 

		; I don't think this is required as you can't bind those characters
		; At least, they're not written to the hotkey file like that
		;if String in !,#,+,^,{,} ; string must be 1 character length to match
		;	return "{" String "}"

		aModifiers := ["+", "^", "!"]
		;lets remove the modifiers so can see command length
		for index, modifier in 	aModifiers
			if inStr(string, modifier)
			{
				StringReplace, String, String, %modifier%,, All
				StringModifiers .= modifier
			}

		; lets correct for any difference in the command names
		; CapsLock ScrollLock NumLock
		; cant bind anything to windows key or appskey in game

		if (StrLen(string) > 1)
			string := StringModifiers "{" string "}" ; as AHK commands > 1 are enclosed in brackets
		else string := StringModifiers string

		if (string = "+=") 		; AHK cant send this correctly != and +- work fine
			string := "+{=}" 	; +!= works fine too as does !+= and ^+=

		; lower-case, if want to use with AHKs sendinput a 'H' is equivalent to '+H'
		StringLower, string, string
		return string
	}

}
/*
Preset Type: None
No Custom Keybinds Found

*** Keybinds ***
Move: None
MoveHoldPosition: None
Attack: None
Stop: None
Patrol: None
Lift: None
Land: None
CalldownMULE/OrbitalCommand: None
ReturnCargo: None
Snipe/Ghost: None
SiegeMode: None
Unsiege: None
AutoTurret/Raven: None
HunterSeekerMissile/Raven: None
TimeWarp/Nexus: None
Blink/Stalker: None
GravitonBeam/Phoenix: None
InfestedTerrans/Infestor: None
MorphMorphalisk/Queen: None
BurrowDown: None
BurrowUp: None
WidowMineBurrow/WidowMine: None
WidowMineUnburrow/WidowMine: None
Larva: None
Cancel: None
ArmySelect: None
SCV: None
Marine/Barracks: None
Marauder/Barracks: None
Reaper/Barracks: None
Ghost/Barracks: None
Hellion/Factory: None
HellionTank/Factory: None
WidowMine/Factory: None
SiegeTank/Factory: None
Thor/Factory: None
VikingFighter/Starport: None
Medivac/Starport: None
Raven/Starport: None
Banshee/Starport: None
Battlecruiser/Starport: None
Probe/Nexus: None
Zealot: None
Sentry: None
Stalker: None
HighTemplar: None
DarkTemplar: None
Observer/RoboticsFacility: None
WarpPrism: None
Immortal/RoboticsFacility: None
Colossus/RoboticsFacility: None
Phoenix/Stargate: None
Oracle/Stargate: None
VoidRay/Stargate: None
Tempest/Stargate: None
Carrier/Stargate: None
MothershipCore/Nexus: None
Queen: None
Drone/Larva: None
Overlord/Larva: None
Zergling/Larva: None
Roach/Larva: None
Hydralisk/Larva: None
Infestor/Larva: None
Mutalisk/Larva: None
Corruptor/Larva: None
Ultralisk/Larva: None
SwarmHostMP/Larva: None
Viper/Larva: None
TerranInfantryWeaponsLevel1/EngineeringBay: None
TerranInfantryArmorLevel1/EngineeringBay: None
TerranShipWeaponsLevel1/Armory: None
TerranShipPlatingLevel1: None
TerranVehicleWeaponsLevel1: None
TerranVehiclePlatingLevel1: None
: None
: None
SubgroupNext: None
SubgroupPrev: None
CameraSave0: None
CameraSave1: None
CameraSave2: None
CameraSave3: None
CameraSave4: None
CameraSave5: None
CameraSave6: None
CameraSave7: None
CameraView0: None
CameraView1: None
CameraView2: None
CameraView3: None
CameraView4: None
CameraView5: None
CameraView6: None
CameraView7: None
ControlGroupAssign0: None
ControlGroupAssign1: None
ControlGroupAssign2: None
ControlGroupAssign3: None
ControlGroupAssign4: None
ControlGroupAssign5: None
ControlGroupAssign6: None
ControlGroupAssign7: None
ControlGroupAssign8: None
ControlGroupAssign9: None
ControlGroupRecall0: None
ControlGroupRecall1: None
ControlGroupRecall2: None
ControlGroupRecall3: None
ControlGroupRecall4: None
ControlGroupRecall5: None
ControlGroupRecall6: None
ControlGroupRecall7: None
ControlGroupRecall8: None
ControlGroupRecall9: None
ControlGroupAppend0: None
ControlGroupAppend1: None
ControlGroupAppend2: None
ControlGroupAppend3: None
ControlGroupAppend4: None
ControlGroupAppend5: None
ControlGroupAppend6: None
ControlGroupAppend7: None
ControlGroupAppend8: None
ControlGroupAppend9: None