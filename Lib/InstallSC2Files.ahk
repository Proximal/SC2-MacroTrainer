; Takes 13 ms if don't overwrite
; Takes 66 ms on my SSD to overwrite all the files
; Takes 86 ms if the unitpanel folder was deleted 
; I guess it could take much longer 100s ms of ms on slow HDDs

; 27/05
; I'm going to keep the current method of overwriting all of them
; as some of these have generic names e.g. on/off.wav and map32.png etc
; So some other application could have put them here
; It was fucking stupid of me not to put them in a A_Temp\MacroTrainerFolder in the first place!!
; For the next version I might look at putting everything in its own folder (shouldn't be too hard). 
; I've made enough changes for this version.

InstallSC2Files()
{ 	global
	FileCreateDir, %A_Temp%\UnitPanelMacroTrainer
	FileCreateDir, %A_Temp%\MacroTrainerFiles\GUI
	FileCreateDir, %A_Temp%\MacroTrainerFiles\OverlaysMisc

	FileInstall, Included Files\GUI\Add Plus Green.ico, %A_Temp%\MacroTrainerFiles\GUI\Add Plus Green.ico, 1 
	FileInstall, Included Files\GUI\Remove Minus Red.ico, %A_Temp%\MacroTrainerFiles\GUI\Remove Minus Red.ico, 1 
	FileInstall, Included Files\GUI\Down Arrow Blue.ico, %A_Temp%\MacroTrainerFiles\GUI\Down Arrow Blue.ico, 1 
	FileInstall, Included Files\GUI\Up Arrow Blue.ico, %A_Temp%\MacroTrainerFiles\GUI\Up Arrow Blue.ico, 1 
	FileInstall, Included Files\Used_Icons\greenTick.png, %A_Temp%\MacroTrainerFiles\OverlaysMisc\greenTick.png, 1   ; AutoBuild in-game GUI
	FileInstall, Included Files\Used_Icons\GreenPause.png, %A_Temp%\MacroTrainerFiles\OverlaysMisc\GreenPause.png, 1 ; AutoBuild in-game GUI
	FileInstall, Included Files\Used_Icons\redClose72.png, %A_Temp%\MacroTrainerFiles\OverlaysMisc\redClose72.png, 1 ; AutoBuild in-game GUI

	FileInstall, Included Files\On.wav, %A_Temp%\On.wav, 1 
	FileInstall, Included Files\Off.wav, %A_Temp%\Off.wav, 1 
	FileInstall, Included Files\gentleBeep.wav, %A_Temp%\gentleBeep.wav, 1 
	FileInstall, Included Files\Windows Ding.wav, %A_Temp%\Windows Ding.wav, 1 
	FileInstall, Included Files\Windows Ding2.wav, %A_Temp%\Windows Ding2.wav, 1 
	FileInstall, Included Files\Windows Ding3.wav, %A_Temp%\Windows Ding3.wav, 1 
	FileInstall, Included Files\ModifierDown.wav, %A_Temp%\ModifierDown.wav, 1 
	FileInstall, Included Files\Used_Icons\home32.png, %A_Temp%\home32.png, 1
	FileInstall, Included Files\Used_Icons\radarB32.png, %A_Temp%\radarB32.png, 1
	FileInstall, Included Files\Used_Icons\Inject32.png, %A_Temp%\Inject32.png, 1
	FileInstall, Included Files\Used_Icons\Group32.png, %A_Temp%\Group32.png, 1
	FileInstall, Included Files\Used_Icons\QuickGroup32.png, %A_Temp%\QuickGroup32.png, 1
	FileInstall, Included Files\Used_Icons\autoBuild32.png, %A_Temp%\autoBuild32.png, 1
	FileInstall, Included Files\Used_Icons\mine.png, %A_Temp%\mine.png, 1
	FileInstall, Included Files\Used_Icons\reticule32.png, %A_Temp%\reticule32.png, 1
	FileInstall, Included Files\Used_Icons\key.png, %A_Temp%\key.png, 1
	FileInstall, Included Files\Used_Icons\warning32.ico, %A_Temp%\warning32.ico, 1
	FileInstall, Included Files\Used_Icons\miscB32.png, %A_Temp%\miscB32.png, 1
	FileInstall, Included Files\Used_Icons\speakerB32.png, %A_Temp%\speakerB32.png, 1
	FileInstall, Included Files\Used_Icons\bug32.png, %A_Temp%\bug32.png, 1
	FileInstall, Included Files\Used_Icons\Robot32.png, %A_Temp%\Robot32.png, 1
	FileInstall, Included Files\Used_Icons\map32.png, %A_Temp%\map32.png, 1
	FileInstall, Included Files\Used_Icons\settings.ico, %A_Temp%\settings.ico, 1
	FileInstall, Included Files\Used_Icons\Terran90.png, %A_Temp%\Terran90.png, 1
	FileInstall, Included Files\Used_Icons\Protoss90.png, %A_Temp%\Protoss90.png, 1
	FileInstall, Included Files\Used_Icons\Zerg90.png, %A_Temp%\Zerg90.png, 1
	FileInstall, Included Files\Used_Icons\RedX16.png, %A_Temp%\RedX16.png, 1
	FileInstall, Included Files\Used_Icons\BlueX16.png, %A_Temp%\BlueX16.png, 1
	FileInstall, Included Files\Used_Icons\GreenX16.png, %A_Temp%\GreenX16.png, 1
	FileInstall, Included Files\Used_Icons\PurpleX16.png, %A_Temp%\PurpleX16.png, 1
	FileInstall, Included Files\Used_Icons\Gas_0Protoss.png, %A_Temp%\Gas_0Protoss.png, 1
	FileInstall, Included Files\Used_Icons\Gas_0Terran.png, %A_Temp%\Gas_0Terran.png, 1
	FileInstall, Included Files\Used_Icons\Gas_0Zerg.png, %A_Temp%\Gas_0Zerg.png, 1
	FileInstall, Included Files\Used_Icons\Mineral_0Protoss.png, %A_Temp%\Mineral_0Protoss.png, 1
	FileInstall, Included Files\Used_Icons\Mineral_0Terran.png, %A_Temp%\Mineral_0Terran.png, 1
	FileInstall, Included Files\Used_Icons\Mineral_0Zerg.png, %A_Temp%\Mineral_0Zerg.png, 1
	FileInstall, Included Files\Used_Icons\Supply_0Protoss.png, %A_Temp%\Supply_0Protoss.png, 1
	FileInstall, Included Files\Used_Icons\Supply_0Terran.png, %A_Temp%\Supply_0Terran.png, 1
	FileInstall, Included Files\Used_Icons\Supply_0Zerg.png, %A_Temp%\Supply_0Zerg.png, 1
	FileInstall, Included Files\Used_Icons\Gas_1Protoss.png, %A_Temp%\Gas_1Protoss.png, 1
	FileInstall, Included Files\Used_Icons\Gas_1Terran.png, %A_Temp%\Gas_1Terran.png, 1
	FileInstall, Included Files\Used_Icons\Gas_1Zerg.png, %A_Temp%\Gas_1Zerg.png, 1
	FileInstall, Included Files\Used_Icons\Mineral_1Protoss.png, %A_Temp%\Mineral_1Protoss.png, 1
	FileInstall, Included Files\Used_Icons\Mineral_1Terran.png, %A_Temp%\Mineral_1Terran.png, 1
	FileInstall, Included Files\Used_Icons\Mineral_1Zerg.png, %A_Temp%\Mineral_1Zerg.png, 1
	FileInstall, Included Files\Used_Icons\Supply_1Protoss.png, %A_Temp%\Supply_1Protoss.png, 1
	FileInstall, Included Files\Used_Icons\Supply_1Terran.png, %A_Temp%\Supply_1Terran.png, 1
	FileInstall, Included Files\Used_Icons\Supply_1Zerg.png, %A_Temp%\Supply_1Zerg.png, 1
	FileInstall, Included Files\Used_Icons\Starcraft-2.ico, %A_Temp%\Starcraft-2.ico, 1
	FileInstall, Included Files\Used_Icons\Worker_0Protoss.png, %A_Temp%\Worker_0Protoss.png, 1
	FileInstall, Included Files\Used_Icons\Worker_0Terran.png, %A_Temp%\Worker_0Terran.png, 1
	FileInstall, Included Files\Used_Icons\Worker_0Zerg.png, %A_Temp%\Worker_0Zerg.png, 1
	FileInstall, Included Files\Used_Icons\Worker32.png, %A_Temp%\Worker32.png, 1
	FileInstall, Included Files\Used_Icons\Army_Protoss.png, %A_Temp%\Army_Protoss.png, 1
	FileInstall, Included Files\Used_Icons\Army_Terran.png, %A_Temp%\Army_Terran.png, 1
	FileInstall, Included Files\Used_Icons\Army_Zerg.png, %A_Temp%\Army_Zerg.png, 1
	FileInstall, Included Files\Used_Icons\Race_ProtossFlat.png, %A_Temp%\Race_ProtossFlat.png, 1
	FileInstall, Included Files\Used_Icons\Race_TerranFlat.png, %A_Temp%\Race_TerranFlat.png, 1
	FileInstall, Included Files\Used_Icons\Race_ZergFlat.png, %A_Temp%\Race_ZergFlat.png, 1
	FileInstall, Included Files\Used_Icons\SCBare128.png, %A_Temp%\SCBare128.png, 1

	FileInstall, Included Files\Used_Icons\pingNuke.png, %A_Temp%\UnitPanelMacroTrainer\pingNuke.png, 1 ; not really a unit panel icon
	FileInstall, Included Files\Used_Icons\Buildings\Terran\armory.png,  %A_Temp%\UnitPanelMacroTrainer\armory.png, 1
	FileInstall, Included Files\Used_Icons\Buildings\Terran\autoturret.png,  %A_Temp%\UnitPanelMacroTrainer\autoturret.png, 1
	FileInstall, Included Files\Used_Icons\Buildings\Terran\barracks.png,  %A_Temp%\UnitPanelMacroTrainer\barracks.png, 1
	FileInstall, Included Files\Used_Icons\Buildings\Terran\bunker.png,  %A_Temp%\UnitPanelMacroTrainer\bunker.png, 1
	FileInstall, Included Files\Used_Icons\Buildings\Terran\bunkerfortified.png,  %A_Temp%\UnitPanelMacroTrainer\bunkerfortified.png, 1
	FileInstall, Included Files\Used_Icons\Buildings\Terran\commandcenter.png,  %A_Temp%\UnitPanelMacroTrainer\commandcenter.png, 1
	FileInstall, Included Files\Used_Icons\Buildings\Terran\engineeringbay.png,  %A_Temp%\UnitPanelMacroTrainer\engineeringbay.png, 1
	FileInstall, Included Files\Used_Icons\Buildings\Terran\factory.png,  %A_Temp%\UnitPanelMacroTrainer\factory.png, 1
	FileInstall, Included Files\Used_Icons\Buildings\Terran\fusioncore.png,  %A_Temp%\UnitPanelMacroTrainer\fusioncore.png, 1
	FileInstall, Included Files\Used_Icons\Buildings\Terran\ghostacademy.png,  %A_Temp%\UnitPanelMacroTrainer\ghostacademy.png, 1
	FileInstall, Included Files\Used_Icons\Buildings\Terran\missileturret.png,  %A_Temp%\UnitPanelMacroTrainer\missileturret.png, 1
	FileInstall, Included Files\Used_Icons\Buildings\Terran\OrbitalCommand.png,  %A_Temp%\UnitPanelMacroTrainer\OrbitalCommand.png, 1
	FileInstall, Included Files\Used_Icons\Buildings\Terran\planetaryfortress.png,  %A_Temp%\UnitPanelMacroTrainer\planetaryfortress.png, 1
	FileInstall, Included Files\Used_Icons\Buildings\Terran\reactor.png,  %A_Temp%\UnitPanelMacroTrainer\reactor.png, 1
	FileInstall, Included Files\Used_Icons\Buildings\Terran\refinery.png,  %A_Temp%\UnitPanelMacroTrainer\refinery.png, 1
	FileInstall, Included Files\Used_Icons\Buildings\Terran\SensorTower.png,  %A_Temp%\UnitPanelMacroTrainer\SensorTower.png, 1
	FileInstall, Included Files\Used_Icons\Buildings\Terran\starport.png,  %A_Temp%\UnitPanelMacroTrainer\starport.png, 1
	FileInstall, Included Files\Used_Icons\Buildings\Terran\supplydepot.png,  %A_Temp%\UnitPanelMacroTrainer\supplydepot.png, 1
	FileInstall, Included Files\Used_Icons\Buildings\Terran\supplydepotlowered.png,  %A_Temp%\UnitPanelMacroTrainer\supplydepotlowered.png, 1
	FileInstall, Included Files\Used_Icons\Buildings\Terran\techlab.png,  %A_Temp%\UnitPanelMacroTrainer\techlab.png, 1
	FileInstall, Included Files\Used_Icons\Units\Terran\banshee.png, %A_Temp%\UnitPanelMacroTrainer\banshee.png, 1
	FileInstall, Included Files\Used_Icons\Units\Terran\battlecruiser.png, %A_Temp%\UnitPanelMacroTrainer\battlecruiser.png, 1
	FileInstall, Included Files\Used_Icons\Units\Terran\ghost.png, %A_Temp%\UnitPanelMacroTrainer\ghost.png, 1
	FileInstall, Included Files\Used_Icons\Units\Terran\hellion.png, %A_Temp%\UnitPanelMacroTrainer\hellion.png, 1
	FileInstall, Included Files\Used_Icons\Units\Terran\HellionTank.png, %A_Temp%\UnitPanelMacroTrainer\HellionTank.png, 1
	FileInstall, Included Files\Used_Icons\Units\Terran\marauder.png, %A_Temp%\UnitPanelMacroTrainer\marauder.png, 1
	FileInstall, Included Files\Used_Icons\Units\Terran\marine.png, %A_Temp%\UnitPanelMacroTrainer\marine.png, 1
	FileInstall, Included Files\Used_Icons\Units\Terran\medivac.png, %A_Temp%\UnitPanelMacroTrainer\medivac.png, 1
	FileInstall, Included Files\Used_Icons\Units\Terran\mule.png, %A_Temp%\UnitPanelMacroTrainer\mule.png, 1
	FileInstall, Included Files\Used_Icons\Units\Terran\Nuke.png, %A_Temp%\UnitPanelMacroTrainer\Nuke.png, 1
	FileInstall, Included Files\Used_Icons\Units\Terran\PointDefenseDrone.png, %A_Temp%\UnitPanelMacroTrainer\PointDefenseDrone.png, 1
	FileInstall, Included Files\Used_Icons\Units\Terran\raven.png, %A_Temp%\UnitPanelMacroTrainer\raven.png, 1
	FileInstall, Included Files\Used_Icons\Units\Terran\reaper.png, %A_Temp%\UnitPanelMacroTrainer\reaper.png, 1
	FileInstall, Included Files\Used_Icons\Units\Terran\scv.png, %A_Temp%\UnitPanelMacroTrainer\scv.png, 1
	FileInstall, Included Files\Used_Icons\Units\Terran\siegetank.png, %A_Temp%\UnitPanelMacroTrainer\siegetank.png, 1
	FileInstall, Included Files\Used_Icons\Units\Terran\SiegeTankSieged.png, %A_Temp%\UnitPanelMacroTrainer\SiegeTankSieged.png, 1
	FileInstall, Included Files\Used_Icons\Units\Terran\thor.png, %A_Temp%\UnitPanelMacroTrainer\thor.png, 1
	FileInstall, Included Files\Used_Icons\Units\Terran\thorsiegemode.png, %A_Temp%\UnitPanelMacroTrainer\thorsiegemode.png, 1
	FileInstall, Included Files\Used_Icons\Units\Terran\vikingassault.png, %A_Temp%\UnitPanelMacroTrainer\vikingassault.png, 1
	FileInstall, Included Files\Used_Icons\Units\Terran\vikingfighter.png, %A_Temp%\UnitPanelMacroTrainer\vikingfighter.png, 1
	FileInstall, Included Files\Used_Icons\Units\Terran\widowmine.png, %A_Temp%\UnitPanelMacroTrainer\widowmine.png, 1
	FileInstall, Included Files\Used_Icons\Abilities\Protoss\MothershipCoreApplyPurifyAB.png,  %A_Temp%\UnitPanelMacroTrainer\MothershipCoreApplyPurifyAB.png, 1	
	FileInstall, Included Files\Used_Icons\Buildings\Protoss\assimilator.png,  %A_Temp%\UnitPanelMacroTrainer\assimilator.png, 1
	FileInstall, Included Files\Used_Icons\Buildings\Protoss\cyberneticscore.png,  %A_Temp%\UnitPanelMacroTrainer\cyberneticscore.png, 1
	FileInstall, Included Files\Used_Icons\Buildings\Protoss\darkshrine.png,  %A_Temp%\UnitPanelMacroTrainer\darkshrine.png, 1
	FileInstall, Included Files\Used_Icons\Buildings\Protoss\fleetbeacon.png,  %A_Temp%\UnitPanelMacroTrainer\fleetbeacon.png, 1
	FileInstall, Included Files\Used_Icons\Buildings\Protoss\forge.png,  %A_Temp%\UnitPanelMacroTrainer\forge.png, 1
	FileInstall, Included Files\Used_Icons\Buildings\Protoss\gateway.png,  %A_Temp%\UnitPanelMacroTrainer\gateway.png, 1
	FileInstall, Included Files\Used_Icons\Buildings\Protoss\nexus.png,  %A_Temp%\UnitPanelMacroTrainer\nexus.png, 1
	FileInstall, Included Files\Used_Icons\Buildings\Protoss\photoncannon.png,  %A_Temp%\UnitPanelMacroTrainer\photoncannon.png, 1
	FileInstall, Included Files\Used_Icons\Buildings\Protoss\pylon.png,  %A_Temp%\UnitPanelMacroTrainer\pylon.png, 1
	FileInstall, Included Files\Used_Icons\Buildings\Protoss\RoboticsBay.png,  %A_Temp%\UnitPanelMacroTrainer\RoboticsBay.png, 1
	FileInstall, Included Files\Used_Icons\Buildings\Protoss\roboticsfacility.png,  %A_Temp%\UnitPanelMacroTrainer\roboticsfacility.png, 1
	FileInstall, Included Files\Used_Icons\Buildings\Protoss\stargate.png,  %A_Temp%\UnitPanelMacroTrainer\stargate.png, 1
	FileInstall, Included Files\Used_Icons\Buildings\Protoss\TemplarArchive.png,  %A_Temp%\UnitPanelMacroTrainer\TemplarArchive.png, 1
	FileInstall, Included Files\Used_Icons\Buildings\Protoss\twilightcouncil.png,  %A_Temp%\UnitPanelMacroTrainer\twilightcouncil.png, 1
	FileInstall, Included Files\Used_Icons\Buildings\Protoss\warpgate.png,  %A_Temp%\UnitPanelMacroTrainer\warpgate.png, 1
	FileInstall, Included Files\Used_Icons\Units\Protoss\archon.png, %A_Temp%\UnitPanelMacroTrainer\archon.png, 1
	FileInstall, Included Files\Used_Icons\Units\Protoss\carrier.png, %A_Temp%\UnitPanelMacroTrainer\carrier.png, 1
	FileInstall, Included Files\Used_Icons\Units\Protoss\colossus.png, %A_Temp%\UnitPanelMacroTrainer\colossus.png, 1
	FileInstall, Included Files\Used_Icons\Units\Protoss\darktemplar.png, %A_Temp%\UnitPanelMacroTrainer\darktemplar.png, 1
	FileInstall, Included Files\Used_Icons\Units\Protoss\hightemplar.png, %A_Temp%\UnitPanelMacroTrainer\hightemplar.png, 1
	FileInstall, Included Files\Used_Icons\Units\Protoss\immortal.png, %A_Temp%\UnitPanelMacroTrainer\immortal.png, 1
	FileInstall, Included Files\Used_Icons\Units\Protoss\interceptor.png, %A_Temp%\UnitPanelMacroTrainer\interceptor.png, 1
	FileInstall, Included Files\Used_Icons\Units\Protoss\mothership.png, %A_Temp%\UnitPanelMacroTrainer\mothership.png, 1
	FileInstall, Included Files\Used_Icons\Units\Protoss\mothershipcore.png, %A_Temp%\UnitPanelMacroTrainer\mothershipcore.png, 1
	FileInstall, Included Files\Used_Icons\Units\Protoss\observer.png, %A_Temp%\UnitPanelMacroTrainer\observer.png, 1
	FileInstall, Included Files\Used_Icons\Units\Protoss\oracle.png, %A_Temp%\UnitPanelMacroTrainer\oracle.png, 1
	FileInstall, Included Files\Used_Icons\Units\Protoss\phoenix.png, %A_Temp%\UnitPanelMacroTrainer\phoenix.png, 1
	FileInstall, Included Files\Used_Icons\Units\Protoss\probe.png, %A_Temp%\UnitPanelMacroTrainer\probe.png, 1
	FileInstall, Included Files\Used_Icons\Units\Protoss\sentry.png, %A_Temp%\UnitPanelMacroTrainer\sentry.png, 1
	FileInstall, Included Files\Used_Icons\Units\Protoss\stalker.png, %A_Temp%\UnitPanelMacroTrainer\stalker.png, 1
	FileInstall, Included Files\Used_Icons\Units\Protoss\tempest.png, %A_Temp%\UnitPanelMacroTrainer\tempest.png, 1
	FileInstall, Included Files\Used_Icons\Units\Protoss\VoidRay.png, %A_Temp%\UnitPanelMacroTrainer\VoidRay.png, 1
	FileInstall, Included Files\Used_Icons\Units\Protoss\warpprism.png, %A_Temp%\UnitPanelMacroTrainer\warpprism.png, 1
	FileInstall, Included Files\Used_Icons\Units\Protoss\WarpPrismPhasing.png, %A_Temp%\UnitPanelMacroTrainer\WarpPrismPhasing.png, 1
	FileInstall, Included Files\Used_Icons\Units\Protoss\zealot.png, %A_Temp%\UnitPanelMacroTrainer\zealot.png, 1
	FileInstall, Included Files\Used_Icons\Buildings\Zerg\banelingnest.png,  %A_Temp%\UnitPanelMacroTrainer\banelingnest.png, 1
	FileInstall, Included Files\Used_Icons\Buildings\Zerg\creeptumor.png,  %A_Temp%\UnitPanelMacroTrainer\creeptumor.png, 1
	FileInstall, Included Files\Used_Icons\Buildings\Zerg\evolutionchamber.png,  %A_Temp%\UnitPanelMacroTrainer\evolutionchamber.png, 1
	FileInstall, Included Files\Used_Icons\Buildings\Zerg\extractor.png,  %A_Temp%\UnitPanelMacroTrainer\extractor.png, 1
	FileInstall, Included Files\Used_Icons\Buildings\Zerg\greaterspire.png,  %A_Temp%\UnitPanelMacroTrainer\greaterspire.png, 1
	FileInstall, Included Files\Used_Icons\Buildings\Zerg\hatchery.png,  %A_Temp%\UnitPanelMacroTrainer\hatchery.png, 1
	FileInstall, Included Files\Used_Icons\Buildings\Zerg\hive.png,  %A_Temp%\UnitPanelMacroTrainer\hive.png, 1
	FileInstall, Included Files\Used_Icons\Buildings\Zerg\hydraliskden.png,  %A_Temp%\UnitPanelMacroTrainer\hydraliskden.png, 1
	FileInstall, Included Files\Used_Icons\Buildings\Zerg\infestationpit.png,  %A_Temp%\UnitPanelMacroTrainer\infestationpit.png, 1
	FileInstall, Included Files\Used_Icons\Buildings\Zerg\lair.png,  %A_Temp%\UnitPanelMacroTrainer\lair.png, 1
	FileInstall, Included Files\Used_Icons\Buildings\Zerg\NydusCanal.png,  %A_Temp%\UnitPanelMacroTrainer\NydusCanal.png, 1
	FileInstall, Included Files\Used_Icons\Buildings\Zerg\nydusnetwork.png,  %A_Temp%\UnitPanelMacroTrainer\nydusnetwork.png, 1
	FileInstall, Included Files\Used_Icons\Buildings\Zerg\roachwarren.png,  %A_Temp%\UnitPanelMacroTrainer\roachwarren.png, 1
	FileInstall, Included Files\Used_Icons\Buildings\Zerg\spawningpool.png,  %A_Temp%\UnitPanelMacroTrainer\spawningpool.png, 1
	FileInstall, Included Files\Used_Icons\Buildings\Zerg\spinecrawler.png,  %A_Temp%\UnitPanelMacroTrainer\spinecrawler.png, 1
	FileInstall, Included Files\Used_Icons\Buildings\Zerg\spire.png,  %A_Temp%\UnitPanelMacroTrainer\spire.png, 1
	FileInstall, Included Files\Used_Icons\Buildings\Zerg\sporecrawler.png,  %A_Temp%\UnitPanelMacroTrainer\sporecrawler.png, 1
	FileInstall, Included Files\Used_Icons\Buildings\Zerg\ultraliskcavern.png,  %A_Temp%\UnitPanelMacroTrainer\ultraliskcavern.png, 1
	FileInstall, Included Files\Used_Icons\Units\Zerg\baneling.png, %A_Temp%\UnitPanelMacroTrainer\baneling.png, 1
	FileInstall, Included Files\Used_Icons\Units\Zerg\BanelingCocoon.png, %A_Temp%\UnitPanelMacroTrainer\BanelingCocoon.png, 1
	FileInstall, Included Files\Used_Icons\Units\Zerg\broodlord.png, %A_Temp%\UnitPanelMacroTrainer\broodlord.png, 1
	FileInstall, Included Files\Used_Icons\Units\Zerg\BroodLordCocoon.png, %A_Temp%\UnitPanelMacroTrainer\BroodLordCocoon.png, 1
	FileInstall, Included Files\Used_Icons\Units\Zerg\changeling.png, %A_Temp%\UnitPanelMacroTrainer\changeling.png, 1
	FileInstall, Included Files\Used_Icons\Units\Zerg\corruptor.png, %A_Temp%\UnitPanelMacroTrainer\corruptor.png, 1
	FileInstall, Included Files\Used_Icons\Units\Zerg\drone.png, %A_Temp%\UnitPanelMacroTrainer\drone.png, 1
	FileInstall, Included Files\Used_Icons\Units\Zerg\egg.png, %A_Temp%\UnitPanelMacroTrainer\egg.png, 1
	FileInstall, Included Files\Used_Icons\Units\Zerg\hydralisk.png, %A_Temp%\UnitPanelMacroTrainer\hydralisk.png, 1
	FileInstall, Included Files\Used_Icons\Units\Zerg\InfestedTerran.png, %A_Temp%\UnitPanelMacroTrainer\InfestedTerran.png, 1
	FileInstall, Included Files\Used_Icons\Units\Zerg\InfestedTerransEgg.png, %A_Temp%\UnitPanelMacroTrainer\InfestedTerransEgg.png, 1
	FileInstall, Included Files\Used_Icons\Units\Zerg\infestor.png, %A_Temp%\UnitPanelMacroTrainer\infestor.png, 1
	FileInstall, Included Files\Used_Icons\Units\Zerg\larva.png, %A_Temp%\UnitPanelMacroTrainer\larva.png, 1
	FileInstall, Included Files\Used_Icons\Units\Zerg\locust.png, %A_Temp%\UnitPanelMacroTrainer\locust.png, 1
	FileInstall, Included Files\Used_Icons\Units\Zerg\mutalisk.png, %A_Temp%\UnitPanelMacroTrainer\mutalisk.png, 1
	FileInstall, Included Files\Used_Icons\Units\Zerg\overlord.png, %A_Temp%\UnitPanelMacroTrainer\overlord.png, 1
	FileInstall, Included Files\Used_Icons\Units\Zerg\OverlordCocoon.png, %A_Temp%\UnitPanelMacroTrainer\OverlordCocoon.png, 1
	FileInstall, Included Files\Used_Icons\Units\Zerg\overseer.png, %A_Temp%\UnitPanelMacroTrainer\overseer.png, 1
	FileInstall, Included Files\Used_Icons\Units\Zerg\queen.png, %A_Temp%\UnitPanelMacroTrainer\queen.png, 1
	FileInstall, Included Files\Used_Icons\Units\Zerg\roach.png, %A_Temp%\UnitPanelMacroTrainer\roach.png, 1
	FileInstall, Included Files\Used_Icons\Units\Zerg\swarmhost.png, %A_Temp%\UnitPanelMacroTrainer\swarmhost.png, 1
	FileInstall, Included Files\Used_Icons\Units\Zerg\ultralisk.png, %A_Temp%\UnitPanelMacroTrainer\ultralisk.png, 1
	FileInstall, Included Files\Used_Icons\Units\Zerg\viper.png, %A_Temp%\UnitPanelMacroTrainer\viper.png, 1
	FileInstall, Included Files\Used_Icons\Units\Zerg\zergling.png, %A_Temp%\UnitPanelMacroTrainer\zergling.png, 1
	
	FileInstall, Included Files\Used_Icons\Upgrades\Protoss\ResearchWarpGate.png, %A_Temp%\UnitPanelMacroTrainer\ResearchWarpGate.png, 1
	FileInstall, Included Files\Used_Icons\Upgrades\Protoss\ResearchCharge.png, %A_Temp%\UnitPanelMacroTrainer\ResearchCharge.png, 1
	FileInstall, Included Files\Used_Icons\Upgrades\Protoss\ResearchPsiStorm.png, %A_Temp%\UnitPanelMacroTrainer\ResearchPsiStorm.png, 1
	FileInstall, Included Files\Used_Icons\Upgrades\Protoss\ResearchStalkerTeleport.png, %A_Temp%\UnitPanelMacroTrainer\ResearchStalkerTeleport.png, 1
	FileInstall, Included Files\Used_Icons\Upgrades\Protoss\PhoenixRangeUpgrade.png, %A_Temp%\UnitPanelMacroTrainer\PhoenixRangeUpgrade.png, 1
	FileInstall, Included Files\Used_Icons\Upgrades\Protoss\ProtossAirArmorLevel1.png, %A_Temp%\UnitPanelMacroTrainer\ProtossAirArmorLevel1.png, 1
	FileInstall, Included Files\Used_Icons\Upgrades\Protoss\ProtossAirArmorLevel2.png, %A_Temp%\UnitPanelMacroTrainer\ProtossAirArmorLevel2.png, 1
	FileInstall, Included Files\Used_Icons\Upgrades\Protoss\ProtossAirArmorLevel3.png, %A_Temp%\UnitPanelMacroTrainer\ProtossAirArmorLevel3.png, 1
	FileInstall, Included Files\Used_Icons\Upgrades\Protoss\ProtossAirWeaponsLevel1.png, %A_Temp%\UnitPanelMacroTrainer\ProtossAirWeaponsLevel1.png, 1
	FileInstall, Included Files\Used_Icons\Upgrades\Protoss\ProtossAirWeaponsLevel2.png, %A_Temp%\UnitPanelMacroTrainer\ProtossAirWeaponsLevel2.png, 1
	FileInstall, Included Files\Used_Icons\Upgrades\Protoss\ProtossAirWeaponsLevel3.png, %A_Temp%\UnitPanelMacroTrainer\ProtossAirWeaponsLevel3.png, 1
	FileInstall, Included Files\Used_Icons\Upgrades\Protoss\ProtossGroundArmorLevel1.png, %A_Temp%\UnitPanelMacroTrainer\ProtossGroundArmorLevel1.png, 1
	FileInstall, Included Files\Used_Icons\Upgrades\Protoss\ProtossGroundArmorLevel2.png, %A_Temp%\UnitPanelMacroTrainer\ProtossGroundArmorLevel2.png, 1
	FileInstall, Included Files\Used_Icons\Upgrades\Protoss\ProtossGroundArmorLevel3.png, %A_Temp%\UnitPanelMacroTrainer\ProtossGroundArmorLevel3.png, 1
	FileInstall, Included Files\Used_Icons\Upgrades\Protoss\ProtossGroundWeaponsLevel1.png, %A_Temp%\UnitPanelMacroTrainer\ProtossGroundWeaponsLevel1.png, 1
	FileInstall, Included Files\Used_Icons\Upgrades\Protoss\ProtossGroundWeaponsLevel2.png, %A_Temp%\UnitPanelMacroTrainer\ProtossGroundWeaponsLevel2.png, 1
	FileInstall, Included Files\Used_Icons\Upgrades\Protoss\ProtossGroundWeaponsLevel3.png, %A_Temp%\UnitPanelMacroTrainer\ProtossGroundWeaponsLevel3.png, 1
	FileInstall, Included Files\Used_Icons\Upgrades\Protoss\ProtossShieldsLevel1.png, %A_Temp%\UnitPanelMacroTrainer\ProtossShieldsLevel1.png, 1
	FileInstall, Included Files\Used_Icons\Upgrades\Protoss\ProtossShieldsLevel2.png, %A_Temp%\UnitPanelMacroTrainer\ProtossShieldsLevel2.png, 1
	FileInstall, Included Files\Used_Icons\Upgrades\Protoss\ProtossShieldsLevel3.png, %A_Temp%\UnitPanelMacroTrainer\ProtossShieldsLevel3.png, 1
	FileInstall, Included Files\Used_Icons\Upgrades\Protoss\ResearchExtendedThermalLance.png, %A_Temp%\UnitPanelMacroTrainer\ResearchExtendedThermalLance.png, 1
	FileInstall, Included Files\Used_Icons\Upgrades\Protoss\ResearchGraviticBooster.png, %A_Temp%\UnitPanelMacroTrainer\ResearchGraviticBooster.png, 1
	FileInstall, Included Files\Used_Icons\Upgrades\Protoss\ResearchGraviticDrive.png, %A_Temp%\UnitPanelMacroTrainer\ResearchGraviticDrive.png, 1
	FileInstall, Included Files\Used_Icons\Upgrades\Protoss\ResearchInterceptorLaunchSpeedUpgrade.png, %A_Temp%\UnitPanelMacroTrainer\ResearchInterceptorLaunchSpeedUpgrade.png, 1
	
	FileInstall, Included Files\Used_Icons\Upgrades\Terran\ResearchTransformationServos.png, %A_Temp%\UnitPanelMacroTrainer\ResearchTransformationServos.png, 1
	FileInstall, Included Files\Used_Icons\Upgrades\Terran\ResearchDrillClaws.png, %A_Temp%\UnitPanelMacroTrainer\ResearchDrillClaws.png, 1
	FileInstall, Included Files\Used_Icons\Upgrades\Terran\ResearchBattlecruiserEnergyUpgrade.png, %A_Temp%\UnitPanelMacroTrainer\ResearchBattlecruiserEnergyUpgrade.png, 1
	FileInstall, Included Files\Used_Icons\Upgrades\Terran\ResearchBansheeCloak.png, %A_Temp%\UnitPanelMacroTrainer\ResearchBansheeCloak.png, 1
	FileInstall, Included Files\Used_Icons\Upgrades\Terran\ResearchPersonalCloaking.png, %A_Temp%\UnitPanelMacroTrainer\ResearchPersonalCloaking.png, 1
	FileInstall, Included Files\Used_Icons\Upgrades\Terran\ResearchPunisherGrenades.png, %A_Temp%\UnitPanelMacroTrainer\ResearchPunisherGrenades.png, 1
	FileInstall, Included Files\Used_Icons\Upgrades\Terran\ResearchShieldWall.png, %A_Temp%\UnitPanelMacroTrainer\ResearchShieldWall.png, 1
	FileInstall, Included Files\Used_Icons\Upgrades\Terran\Stimpack.png, %A_Temp%\UnitPanelMacroTrainer\Stimpack.png, 1
	FileInstall, Included Files\Used_Icons\Upgrades\Terran\ResearchBattlecruiserSpecializations.png, %A_Temp%\UnitPanelMacroTrainer\ResearchBattlecruiserSpecializations.png, 1
	FileInstall, Included Files\Used_Icons\Upgrades\Terran\ResearchDurableMaterials.png, %A_Temp%\UnitPanelMacroTrainer\ResearchDurableMaterials.png, 1
	FileInstall, Included Files\Used_Icons\Upgrades\Terran\ResearchGhostEnergyUpgrade.png, %A_Temp%\UnitPanelMacroTrainer\ResearchGhostEnergyUpgrade.png, 1
	FileInstall, Included Files\Used_Icons\Upgrades\Terran\ResearchHighCapacityBarrels.png, %A_Temp%\UnitPanelMacroTrainer\ResearchHighCapacityBarrels.png, 1
	FileInstall, Included Files\Used_Icons\Upgrades\Terran\ResearchHiSecAutoTracking.png, %A_Temp%\UnitPanelMacroTrainer\ResearchHiSecAutoTracking.png, 1
	FileInstall, Included Files\Used_Icons\Upgrades\Terran\ResearchMedivacEnergyUpgrade.png, %A_Temp%\UnitPanelMacroTrainer\ResearchMedivacEnergyUpgrade.png, 1
	FileInstall, Included Files\Used_Icons\Upgrades\Terran\ResearchNeosteelFrame.png, %A_Temp%\UnitPanelMacroTrainer\ResearchNeosteelFrame.png, 1
	FileInstall, Included Files\Used_Icons\Upgrades\Terran\ResearchRavenEnergyUpgrade.png, %A_Temp%\UnitPanelMacroTrainer\ResearchRavenEnergyUpgrade.png, 1
	FileInstall, Included Files\Used_Icons\Upgrades\Terran\TerranInfantryArmorLevel1.png, %A_Temp%\UnitPanelMacroTrainer\TerranInfantryArmorLevel1.png, 1
	FileInstall, Included Files\Used_Icons\Upgrades\Terran\TerranInfantryArmorLevel2.png, %A_Temp%\UnitPanelMacroTrainer\TerranInfantryArmorLevel2.png, 1
	FileInstall, Included Files\Used_Icons\Upgrades\Terran\TerranInfantryArmorLevel3.png, %A_Temp%\UnitPanelMacroTrainer\TerranInfantryArmorLevel3.png, 1
	FileInstall, Included Files\Used_Icons\Upgrades\Terran\TerranInfantryWeaponsLevel1.png, %A_Temp%\UnitPanelMacroTrainer\TerranInfantryWeaponsLevel1.png, 1
	FileInstall, Included Files\Used_Icons\Upgrades\Terran\TerranInfantryWeaponsLevel2.png, %A_Temp%\UnitPanelMacroTrainer\TerranInfantryWeaponsLevel2.png, 1
	FileInstall, Included Files\Used_Icons\Upgrades\Terran\TerranInfantryWeaponsLevel3.png, %A_Temp%\UnitPanelMacroTrainer\TerranInfantryWeaponsLevel3.png, 1
	FileInstall, Included Files\Used_Icons\Upgrades\Terran\TerranShipWeaponsLevel1.png, %A_Temp%\UnitPanelMacroTrainer\TerranShipWeaponsLevel1.png, 1
	FileInstall, Included Files\Used_Icons\Upgrades\Terran\TerranShipWeaponsLevel2.png, %A_Temp%\UnitPanelMacroTrainer\TerranShipWeaponsLevel2.png, 1
	FileInstall, Included Files\Used_Icons\Upgrades\Terran\TerranShipWeaponsLevel3.png, %A_Temp%\UnitPanelMacroTrainer\TerranShipWeaponsLevel3.png, 1
	FileInstall, Included Files\Used_Icons\Upgrades\Terran\TerranVehicleAndShipPlatingLevel1.png, %A_Temp%\UnitPanelMacroTrainer\TerranVehicleAndShipPlatingLevel1.png, 1
	FileInstall, Included Files\Used_Icons\Upgrades\Terran\TerranVehicleAndShipPlatingLevel2.png, %A_Temp%\UnitPanelMacroTrainer\TerranVehicleAndShipPlatingLevel2.png, 1
	FileInstall, Included Files\Used_Icons\Upgrades\Terran\TerranVehicleAndShipPlatingLevel3.png, %A_Temp%\UnitPanelMacroTrainer\TerranVehicleAndShipPlatingLevel3.png, 1
	FileInstall, Included Files\Used_Icons\Upgrades\Terran\TerranVehicleWeaponsLevel1.png, %A_Temp%\UnitPanelMacroTrainer\TerranVehicleWeaponsLevel1.png, 1
	FileInstall, Included Files\Used_Icons\Upgrades\Terran\TerranVehicleWeaponsLevel2.png, %A_Temp%\UnitPanelMacroTrainer\TerranVehicleWeaponsLevel2.png, 1
	FileInstall, Included Files\Used_Icons\Upgrades\Terran\TerranVehicleWeaponsLevel3.png, %A_Temp%\UnitPanelMacroTrainer\TerranVehicleWeaponsLevel3.png, 1
	FileInstall, Included Files\Used_Icons\Upgrades\Terran\TerranVehicleAndShipWeaponsLevel1.png, %A_Temp%\UnitPanelMacroTrainer\TerranVehicleAndShipWeaponsLevel1.png, 1
	FileInstall, Included Files\Used_Icons\Upgrades\Terran\TerranVehicleAndShipWeaponsLevel2.png, %A_Temp%\UnitPanelMacroTrainer\TerranVehicleAndShipWeaponsLevel2.png, 1
	FileInstall, Included Files\Used_Icons\Upgrades\Terran\TerranVehicleAndShipWeaponsLevel3.png, %A_Temp%\UnitPanelMacroTrainer\TerranVehicleAndShipWeaponsLevel3.png, 1

	FileInstall, Included Files\Used_Icons\Upgrades\Terran\UpgradeBuildingArmorLevel1.png, %A_Temp%\UnitPanelMacroTrainer\UpgradeBuildingArmorLevel1.png, 1

	FileInstall, Included Files\Used_Icons\Upgrades\Zerg\EvolveFlyingLocusts.png, %A_Temp%\UnitPanelMacroTrainer\EvolveFlyingLocusts.png, 1
	FileInstall, Included Files\Used_Icons\Upgrades\Zerg\ResearchLocustLifetimeIncrease.png, %A_Temp%\UnitPanelMacroTrainer\ResearchLocustLifetimeIncrease.png, 1
	FileInstall, Included Files\Used_Icons\Upgrades\Zerg\ResearchBurrow.png, %A_Temp%\UnitPanelMacroTrainer\ResearchBurrow.png, 1
	FileInstall, Included Files\Used_Icons\Upgrades\Zerg\ResearchNeuralParasite.png, %A_Temp%\UnitPanelMacroTrainer\ResearchNeuralParasite.png, 1
	FileInstall, Included Files\Used_Icons\Upgrades\Zerg\EvolveCentrificalHooks.png, %A_Temp%\UnitPanelMacroTrainer\EvolveCentrificalHooks.png, 1
	FileInstall, Included Files\Used_Icons\Upgrades\Zerg\EvolveChitinousPlating.png, %A_Temp%\UnitPanelMacroTrainer\EvolveChitinousPlating.png, 1
	FileInstall, Included Files\Used_Icons\Upgrades\Zerg\EvolveGlialRegeneration.png, %A_Temp%\UnitPanelMacroTrainer\EvolveGlialRegeneration.png, 1
	FileInstall, Included Files\Used_Icons\Upgrades\Zerg\EvolveInfestorEnergyUpgrade.png, %A_Temp%\UnitPanelMacroTrainer\EvolveInfestorEnergyUpgrade.png, 1
	FileInstall, Included Files\Used_Icons\Upgrades\Zerg\EvolveTunnelingClaws.png, %A_Temp%\UnitPanelMacroTrainer\EvolveTunnelingClaws.png, 1
	FileInstall, Included Files\Used_Icons\Upgrades\Zerg\EvolveVentralSacks.png, %A_Temp%\UnitPanelMacroTrainer\EvolveVentralSacks.png, 1
	FileInstall, Included Files\Used_Icons\Upgrades\Zerg\hydraliskspeed.png, %A_Temp%\UnitPanelMacroTrainer\hydraliskspeed.png, 1
	FileInstall, Included Files\Used_Icons\Upgrades\Zerg\MuscularAugments.png, %A_Temp%\UnitPanelMacroTrainer\MuscularAugments.png, 1
	FileInstall, Included Files\Used_Icons\Upgrades\Zerg\overlordspeed.png, %A_Temp%\UnitPanelMacroTrainer\overlordspeed.png, 1
	FileInstall, Included Files\Used_Icons\Upgrades\Zerg\zergflyerarmor1.png, %A_Temp%\UnitPanelMacroTrainer\zergflyerarmor1.png, 1
	FileInstall, Included Files\Used_Icons\Upgrades\Zerg\zergflyerarmor2.png, %A_Temp%\UnitPanelMacroTrainer\zergflyerarmor2.png, 1
	FileInstall, Included Files\Used_Icons\Upgrades\Zerg\zergflyerarmor3.png, %A_Temp%\UnitPanelMacroTrainer\zergflyerarmor3.png, 1
	FileInstall, Included Files\Used_Icons\Upgrades\Zerg\zergflyerattack1.png, %A_Temp%\UnitPanelMacroTrainer\zergflyerattack1.png, 1
	FileInstall, Included Files\Used_Icons\Upgrades\Zerg\zergflyerattack2.png, %A_Temp%\UnitPanelMacroTrainer\zergflyerattack2.png, 1
	FileInstall, Included Files\Used_Icons\Upgrades\Zerg\zergflyerattack3.png, %A_Temp%\UnitPanelMacroTrainer\zergflyerattack3.png, 1
	FileInstall, Included Files\Used_Icons\Upgrades\Zerg\zerggroundarmor1.png, %A_Temp%\UnitPanelMacroTrainer\zerggroundarmor1.png, 1
	FileInstall, Included Files\Used_Icons\Upgrades\Zerg\zerggroundarmor2.png, %A_Temp%\UnitPanelMacroTrainer\zerggroundarmor2.png, 1
	FileInstall, Included Files\Used_Icons\Upgrades\Zerg\zerggroundarmor3.png, %A_Temp%\UnitPanelMacroTrainer\zerggroundarmor3.png, 1
	FileInstall, Included Files\Used_Icons\Upgrades\Zerg\zerglingattackspeed.png, %A_Temp%\UnitPanelMacroTrainer\zerglingattackspeed.png, 1
	FileInstall, Included Files\Used_Icons\Upgrades\Zerg\zerglingmovementspeed.png, %A_Temp%\UnitPanelMacroTrainer\zerglingmovementspeed.png, 1
	FileInstall, Included Files\Used_Icons\Upgrades\Zerg\zergmeleeweapons1.png, %A_Temp%\UnitPanelMacroTrainer\zergmeleeweapons1.png, 1
	FileInstall, Included Files\Used_Icons\Upgrades\Zerg\zergmeleeweapons2.png, %A_Temp%\UnitPanelMacroTrainer\zergmeleeweapons2.png, 1
	FileInstall, Included Files\Used_Icons\Upgrades\Zerg\zergmeleeweapons3.png, %A_Temp%\UnitPanelMacroTrainer\zergmeleeweapons3.png, 1
	FileInstall, Included Files\Used_Icons\Upgrades\Zerg\zergmissileweapons1.png, %A_Temp%\UnitPanelMacroTrainer\zergmissileweapons1.png, 1
	FileInstall, Included Files\Used_Icons\Upgrades\Zerg\zergmissileweapons2.png, %A_Temp%\UnitPanelMacroTrainer\zergmissileweapons2.png, 1
	FileInstall, Included Files\Used_Icons\Upgrades\Zerg\zergmissileweapons3.png, %A_Temp%\UnitPanelMacroTrainer\zergmissileweapons3.png, 1

	; This was previously used by dSpeak() - This function isn't called any more
	; This is still used by ResourHackIcons() 
	; Use the Non-MD version so don't need to worry about msvcr100.dll
	FileInstall, Included Files\ahkH\nonMD\AutoHotkey.exe, %A_Temp%\AHK.exe, 1
}
