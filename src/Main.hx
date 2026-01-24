package;

import flixel.FlxGame;
import flixel.FlxG;
import flixel.FlxState;
import lime.app.Application;
import openfl.Lib;
import openfl.events.Event;
import openfl.display.Sprite;
import openfl.display.StageAlign;
import openfl.display.StageScaleMode;

#if linux
import lime.graphics.Image;
#end

#if CRASH_HANDLER
import haxe.CallStack;
import haxe.io.Path;
import openfl.events.UncaughtErrorEvent;
#end

// Required for Date string to class call replace!
using StringTools;

class Main extends Sprite
{
	var mainGame = {
		width: 1280,
		height: 720,
		initialMenu: InitState,
		fps: 60,
		skipFlixelSplash: true
	};

	public static var fpsVar:FramePerSecond;

	public static var randomErrorMessages:Array<String> = [
        "SBINATOR OCCURRED A CRASH!!", // Suggested by ???
        "Uncaught Error", // Suggested by MaysLastPlays
        "null object reference", // Suggested by riirai_luna (Luna)
        "Null What the...", // Suggested by Rafi
        "Sbinator might not be gaming", // Suggested by riirai_luna (Luna)
        '"An error occurred."', // Suggested by core5570r (CoreCat)
        "An excpetion occurred", // Sonic CD lookin crash screen
        "Object retreival error", // FNAF 2 Deluxe Edition error code
        "Null Acess", // This is impossible to get into Flixel!
        "NullReferenceException", // C#, Unity, Java, Rust error

        // Here are some funnies
        "Sbinator must be thinks he is wind or some shit - ACoolioDude", // ACoolioDude
        "Sbinator isn't for brain rot. It is for 67 - ACoolioDude", //ACoolioDude
        "Sbinator must be so skidibi and sigma - ACoolioDude", //ACoolioDude
        "Sbinator challenges ninjamuffin99- - ACoolioDude", //ACoolioDude
        "Sbinator thinks 2026 will be the best year - ACoolioDude", //ACoolioDude
        "Sbinator thinks meme reset will happen :skull: - ACoolioDude", //ACoolioDude
        "Have you know that the creator uses Arch Linux btw? Haven't you? - ACoolioDude" //ACoolioDude
    ];
	public static final releaseCycle:String = #if debug "Debugger"; #else "Releaser"; #end
	static var previousState:FlxState;

	public function new()
	{
		super();

		trace('You are in ${releaseCycle} branch!');

		#if CRASH_HANDLER
		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onUncaughtError);
		#end
		Lib.current.stage.addEventListener(Event.RESIZE, onResize);
		onResize(null);

		addChild(new FlxGame(mainGame.width, mainGame.height, mainGame.initialMenu, mainGame.fps, mainGame.fps, mainGame.skipFlixelSplash));

		#if linux
		var icon = Image.fromFile("icon.png");
		Lib.current.stage.window.setIcon(icon);
		#end

		fpsVar = new FramePerSecond();
		Lib.current.stage.align = StageAlign.TOP_LEFT;
		Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;
		if (fpsVar != null) fpsVar.visible = true;
		addChild(fpsVar);

		#if DISCORD_ALLOWED
		DiscordClient.prepare();
		#end

		FlxG.signals.preStateSwitch.add(() -> {
			previousState = FlxG.state;
		});

		FlxG.signals.preStateCreate.add((stateCreaton) -> {
			Paths.clearStoredGameMemory();
			Paths.clearUnusedGameMemory();
		});

		FlxG.updateFramerate = 240;
		FlxG.drawFramerate = 120;
		FlxG.fixedTimestep = true;

		Application.current.window.onClose.add(function() {
			DataHandler.saveData();

 	        #if DISCORD_ALLOWED
            DiscordClient.shutdown();
            #end
		});
	}

	private function onResize(e:Event):Void {
        var stageWidth = Lib.current.stage.stageWidth;
        var stageHeight = Lib.current.stage.stageHeight;

        mainGame.width = stageWidth;
        mainGame.height = stageHeight;
    }

	#if sys
	function onUncaughtError(e:UncaughtErrorEvent):Void
	{
		e.preventDefault();
		e.stopImmediatePropagation();

		var path:String;
		var exception:String = 'Exception: ${e.error}\n';
		var stackTraceString = exception + StringTools.trim(CallStack.toString(CallStack.exceptionStack(true)));
		var dateNow:String = Date.now().toString().replace(" ", "_").replace("'", ":");

		path = 'crash/Sbinator_${dateNow}.log';

		#if sys
		if (!FileSystem.exists("crash/"))
			FileSystem.createDirectory("crash/");
		File.saveContent(path, '${randomErrorMessages[FlxG.random.int(0, randomErrorMessages.length)]}\n==============\n${FramePerSecond.getDebug()}\n==============\n${stackTraceString}');
		#end

		var normalPath:String = Path.normalize(path);
		Sys.println(stackTraceString + "\n" + 'Crash dump saved in $normalPath');

		// Requires because of latest Flixel!
		#if (flixel < "6.0.0")
		FlxG.bitmap.dumpCache();
		#end

		FlxG.bitmap.clearCache();

		// It seems like "UncaughtErrorEvent" works only on release branch instead of debug since on debug it is disabled by default after many OpenFL changes
		#if (linux || mac)
		StateHandler.switchToNewState(new CrashState(stackTraceString + '\n\nCrash log created at: "${normalPath}"!'));
		#else
		Application.current.window.alert(stackTraceString + "\n\nPress OK to reset game!" + randomErrorMessages[FlxG.random.int(0, randomErrorMessages.length)] + " - Sbinator v" + EngineConfiguration.gameVersion);
		FlxG.resetGame();
		#end
	}
	#end
}
