package sbinator.states;

#if cpp
import cpp.vm.Thread;
import cpp.vm.Lock;
#end

import haxe.ds.StringMap;

import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.graphics.FlxGraphic;
import flixel.math.FlxMath;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import openfl.display.BitmapData;
import openfl.utils.Assets;

#if sys
import sys.thread.Mutex;
#end

using StringTools;

class InitState extends FlxState
{
    var sbinator:FlxSprite;
    var pop:FlxSound;

    // Caching system
    public static var spriteCache:StringMap<Array<FlxGraphic>> = new StringMap();

	var foldersToCache:Array<String> = [
		"creditsMenu",
		"game",
        "mainMenu",
		"pauseMenu"
	];

	var statusText:FlxText;
	var loadingBar:FlxSprite;
	var loadingBarBG:FlxSprite;
    var barWidth:Int = 0;

	var totalAssets:Int = 0;
	var loadedAssets:Int = 0;
	var done:Bool = false;
	var lock:Lock = new Lock();
    var mutex:Mutex = new Mutex();

    override function create()
    {
        #if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In Initialization", null);
		#end

        pop = FlxG.sound.load(Paths.soundPath("pop"));

		sbinator = new FlxSprite().loadGraphic(Paths.imagePath('mainMenu/logo'));
		sbinator.scrollFactor.set();
		sbinator.screenCenter();
		sbinator.alpha = 0;
		sbinator.scale.set(0.3, 0.3);
		sbinator.active = false;
		add(sbinator);

        statusText = new FlxText(0, FlxG.height * 0.7, "");
        statusText.setFormat(Paths.fontPath("bahnschrift.ttf"), 20, FlxColor.WHITE, CENTER, OUTLINE_FAST, FlxColor.BLACK);
		statusText.borderSize = 2;
        statusText.alpha = 0;
        statusText.active = false;
		statusText.screenCenter(X);
		add(statusText);

        loadingBarBG = new FlxSprite(0, 660).makeGraphic(1, 1, FlxColor.WHITE);
		loadingBarBG.scale.set(FlxG.width - 250, 25);
		loadingBarBG.updateHitbox();
		loadingBarBG.screenCenter(X);
        loadingBarBG.alpha = 0;
        loadingBarBG.active = false;
        add(loadingBarBG);

        loadingBar = new FlxSprite(loadingBarBG.x + 5, loadingBarBG.y + 5).makeGraphic(1, 1, 0xFFcd5e00);
		loadingBar.scale.set(0, 15);
		loadingBar.updateHitbox();
        loadingBar.alpha = 0;
        loadingBar.active = false;
        add(loadingBar);
        barWidth = Std.int(loadingBarBG.width - 10);

        new FlxTimer().start(0.1, function(tmr:FlxTimer)
        {
            doAThing();
        });

        super.create();
    }

    public function doAThing()
    {
        new FlxTimer().start(2, function(tmr:FlxTimer)
        {
            sbinator.alpha = 0.2;
            sbinator.active = true;
        });

        new FlxTimer().start(4.5, function(tmr:FlxTimer)
        {
            statusText.alpha = 1;
            statusText.active = true;

            loadingBarBG.alpha = 1;
            loadingBarBG.active = true;

            loadingBar.alpha = 1;
            loadingBar.active = true;

            FlxTween.tween(sbinator, {alpha: 1, "scale.x": 0.4, "scale.y": 0.4}, 2, {ease: FlxEase.expoInOut, onComplete: _ -> onCachingInit()});
        });
    }

    public function onCachingInit()
    {
		for (folder in foldersToCache)
		{
			var folderPath = 'assets/images/' + folder;
			if (FileSystem.exists(folderPath) && FileSystem.isDirectory(folderPath))
			{
				for (file in FileSystem.readDirectory(folderPath))
				{
					if (StringTools.endsWith(file, ".png")) totalAssets++;
				}
			}
		}

		#if cpp
		Thread.create(() -> {
			cacheAssets();
			mutex.acquire(); done = true; lock.release();
		});
        #else
		cacheAssets();
		done = true;
        #end
	}

    override function update(elapsed:Float)
    {
        // Update text
		statusText.text = 'Caching assets: $loadedAssets / $totalAssets';

        if (loadedAssets != totalAssets)
		{
			loadingBar.scale.x = barWidth * loadedAssets;
			loadingBar.updateHitbox();
		}

        if (done && loadedAssets >= totalAssets)
		{
            statusText.text = "Done!";
            new FlxTimer().start(2.5, function(tmr:FlxTimer)
            {
                onInitDone();
            });
		}

        super.update(elapsed);
    }

    function cacheAssets():Void
	{
		for (folderName in foldersToCache)
		{
			var folderPath = 'assets/images/' + folderName;

			if (!FileSystem.exists(folderPath) || !FileSystem.isDirectory(folderPath))
			{
				trace('Folder not found: ' + folderPath);
				continue;
			}

			var files = FileSystem.readDirectory(folderPath);
			var graphics:Array<FlxGraphic> = [];

			for (file in files)
			{
				if (!StringTools.endsWith(file, ".png")) continue;

				var fullPath = folderPath + '/' + file;

				try {
					var bmp:BitmapData = Assets.getBitmapData(fullPath);
					var graphic = FlxGraphic.fromBitmapData(bmp, false, fullPath);
					graphics.push(graphic);
				} catch (e:Dynamic) {
					trace('Failed to load: $fullPath');
				}

				mutex.acquire(); loadedAssets++; lock.release();
			}

			if (graphics.length > 0) spriteCache.set(folderName, graphics);
		}
	}

	public static function getFrames(name:String):Array<FlxGraphic>
	{
		return spriteCache.get(name);
	}

    public function onInitDone()
    {
        sbinator.active = false;
        sbinator.alpha = 0;

        sbinator.alpha = 0;
        sbinator.active = false;

        statusText.alpha = 0;
        statusText.active = false;

        loadingBarBG.alpha = 0;
        loadingBarBG.active = false;

        loadingBar.alpha = 0;
        loadingBar.active = false;

        pop.play();
        pop.onComplete = function()
        {
            StateHandler.switchToNewState(new TitleScreen());
        }
    }
}
