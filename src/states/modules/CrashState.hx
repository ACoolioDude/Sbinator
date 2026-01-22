package states.modules;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import lime.app.Application;

enum Action {
    RESET;
    EXIT;
}

class CrashState extends StateHandler
{
    var errorMessage:String = '';
    var bg:FlxSprite;
    var checker:FlxBackdrop;
    var title:FlxText;
    var crashText:FlxText;
    var infoText:FlxText;
    var controlsCheck:Bool = false;
    public static var randomErrorMessages:Array<String> = [
        "SBINATOR OCCURRED A CRASH!!",
        "Uncaught Error", // Suggested by MaysLastPlays
        "null object reference", // Suggested by riirai_luna (Luna)
        "Null What the...", // Suggested by Rafi
        "Sbinator might not be gaming", // Suggested by riirai_luna (Luna)
        '"An error occurred."', // Suggested by core5570r (CoreCat)
        "An excpetion occurred", // Sonic CD lookin crash screen
        "Object retreival error", // FNAF 2 Deluxe Edition error code
        "Null Acess", // This is impossible to get into Flixel!
        "NullReferenceException" // C#, Unity, Java, Rust error
    ];

    public function new(errorMessage:String)
    {
        super();
        this.errorMessage = errorMessage;
    }

    override public function create()
    {
        #if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("GAME CRASHED UNFORTUNATELY", null);
		#end

        #if desktop Application.current.window.title = "Sbinator " + EngineConfiguration.gameVersion + " main crash handler"; #end

        bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFFcd5e00);
        bg.alpha = 0.6;
        add(bg);

        checker = new FlxBackdrop(FlxGridOverlay.createGrid(80, 80, 160, 160, true, FlxColor.BLACK, 0x0));
        checker.velocity.set(18, 18);
        checker.screenCenter();
        checker.alpha = 0.4;
        add(checker);

        title = new FlxText(0, 16, 0, randomErrorMessages[FlxG.random.int(0, randomErrorMessages.length)]);
        title.setFormat(Paths.fontPath("bahnschrift.ttf"), 55, FlxColor.RED, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        title.screenCenter(X);
        title.alpha = 0;
        add(title);

        crashText = new FlxText(24, title.y + title.height + 16, FlxG.width - 24, errorMessage);
        crashText.setFormat(Paths.fontPath("bahnschrift.ttf"), 24, FlxColor.ORANGE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        crashText.alpha = 0;
        crashText.screenCenter(X);
        add(crashText);

        infoText = new FlxText(5, FlxG.height - -28, 0, "Press ESC to reset a game! / Press ENTER to open GitHub issue tab! / Press BACKSPACE to exit!", 16);
        infoText.scrollFactor.set();
        infoText.setFormat(Paths.fontPath("bahnschrift.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        infoText.screenCenter(X);
        infoText.alpha = 0;
        add(infoText);

        new FlxTimer().start(1, function(tmr:FlxTimer) {
            FlxTween.tween(title, {alpha: 1, "y": 88}, 1.5, {ease: FlxEase.expoOut});
        });

        new FlxTimer().start(2, function(tmr:FlxTimer) {
            FlxTween.tween(crashText, {alpha: 1, "y": 180}, 1.5, {ease: FlxEase.expoOut});
        });

        new FlxTimer().start(3, function(tmr:FlxTimer) {
            FlxTween.tween(infoText, {alpha: 1, "y": 690}, 2.5, {ease: FlxEase.expoInOut});
        });

        new FlxTimer().start(4, function(tmr:FlxTimer) {
            checker.velocity.set(0, 0);
        });

        new FlxTimer().start(5.7, function(tmr:FlxTimer) {
            controlsCheck = true; // The moment when you are allowed to press ESC or ENTER
        });

        super.create();
    }

    override public function update(elapsed:Float)
    {
        if (FlxG.keys.justPressed.ESCAPE && controlsCheck) tweenOut(RESET) else if (FlxG.keys.justPressed.BACKSPACE && controlsCheck) tweenOut(EXIT);
        if (FlxG.keys.justPressed.ENTER && controlsCheck) EngineConfiguration.openURL("https://github.com/Stefan2008Git/Sbinator/issues");

        super.update(elapsed);
    }

    public function tweenOut(action:Action)
    {
        controlsCheck = false; // After you press ESC or ENTER, the controls are disabled again!
        new FlxTimer().start(1, function(tmr:FlxTimer) {
            FlxTween.tween(title, {alpha: 0, "y": -88}, 1.5, {ease: FlxEase.expoOut});
        });

        new FlxTimer().start(1.5, function(tmr:FlxTimer) {
            FlxTween.tween(crashText, {alpha: 0, "y": -180}, 1.5, {ease: FlxEase.expoOut});
        });

        new FlxTimer().start(2, function(tmr:FlxTimer) {
            FlxTween.tween(bg, {alpha: 0}, 1.5, {ease: FlxEase.expoOut});
            FlxTween.tween(checker, {alpha: 0}, 1.5, {ease: FlxEase.expoOut});
            FlxTween.tween(infoText, {y: 800}, 1.5, {ease: FlxEase.expoInOut});
        });

        new FlxTimer().start(2.7, function(tmr:FlxTimer) {
            switch (action) {
                case RESET:
                    Application.current.window.title = "Sbinator";
                    FlxG.resetGame();
                case EXIT:
                    lime.system.System.exit(0);
            }
        });
    }
}
