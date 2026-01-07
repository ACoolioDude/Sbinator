package data.backend;

#if cpp
import cpp.vm.Gc;
#end

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.system.FlxAssets;
import flixel.util.FlxColor;
import flixel.util.FlxSave;
import openfl.display.BitmapData;
import openfl.media.Sound;
import openfl.system.System;
import openfl.utils.Assets;

#if sys
import sys.FileSystem;
import sys.io.File;
#end

using StringTools;

@:keep
@:access(BitmapData)
class EngineConfiguration
{
    // Game version
    public static var gameVersion:String = "1.0.0a";

    // Color tween for background in states/substates
    inline public static function colorFromString(color:String):FlxColor
	{
		var hideCharacters = ~/[\t\n\r]/;
		var color:String = hideCharacters.split(color).join('').trim();
		if(color.startsWith('0x')) color = color.substring(color.length - 6);

		var colorNum:Null<FlxColor> = FlxColor.fromString(color);
		if(colorNum == null) colorNum = FlxColor.fromString('#$color');
		return colorNum != null ? colorNum : FlxColor.WHITE;
	}

    // Code from CoreCat's FNF CDev Engine to fix text and button position! Cheers dude, but i am sad that your engine got discontinued :(..
    /**
	 * Moving the `obj1` to `obj2`'s center position
	 * @param obj1
	 * @param obj2
	 * @param useFrameSize
	 */
	public static function moveSpritesToCenter(obj1:FlxSprite, obj2:FlxSprite, ?useFrameSize:Bool)
	{
		if (useFrameSize)
		{
			obj1.setPosition((obj2.x + (obj2.frameWidth / 2) - (obj1.frameWidth / 2)), (obj2.y + (obj2.frameHeight / 2) - (obj1.frameHeight / 2)));
		}
		else
		{
			obj1.setPosition((obj2.x + (obj2.width / 2) - (obj1.width / 2)), (obj2.y + (obj2.height / 2) - (obj1.height / 2)));
		}
	}

    // URL handler
    public static inline function openWebURL(url:String)
    {
        #if linux
        var xdgCommand = Sys.command("xdg-open", [url]);
        if (xdgCommand != 0) xdgCommand = Sys.command("/usr/bin/xdg-open", [url]);
        #else
        FlxG.openURL(url);
        #end

        // trace("URL: " + url);
    }

    // Actual working DE/WM detector!
    #if linux
    public static function getDEInfo():String
    {
        var desktopEnvironment = Sys.getEnv("XDG_CURRENT_DESKTOP");
        if (desktopEnvironment != null) return desktopEnvironment;

        desktopEnvironment = Sys.getEnv("DESKTOP_SESSION");
        if (desktopEnvironment != null) return desktopEnvironment;

        if (Sys.getEnv("GNOME_DESKTOP_SESSION_ID") != null) return "GNOME " + Sys.command("gnome-shell", ["--version"]);
        return "Unknown";
    }
    #end
}

// Paths system
class Paths
{
    inline public static final ROOT_FOLDER:String = "assets";
    public static var EXISTING_SOUND:Array<String> = ['.ogg', '.wav'];
    public static var currentTrackedAssets:Map<String, FlxGraphic> = [];
    public static var currentTrackedSounds:Map<String, Sound> = [];
    public static var currentTrackedLocalAssets:Array<String> = [];

    static public function getCurrentPath(folder:Null<String>, file:String)
    {
        if (folder == null) folder = ROOT_FOLDER;
        return folder + '/' + file;
    }

    static public function file(file:String, folder:String = ROOT_FOLDER)
    {
        if (#if sys FileSystem.exists(folder) && #end (folder != null && folder != ROOT_FOLDER)) return getCurrentPath(folder, file);
        return getCurrentPath(null, file);
    }

    inline static public function dataPath(key:String)
        return file('data/$key');

    inline static public function soundPath(key:String, ?cache:Bool = true):Sound
        return returnCurrentSound('sounds/$key', cache);

    // This seems like a broken function because it tries to load a sound only
    inline static public function musicPath(key:String, ?cache:Bool = true):Sound
        return returnCurrentSound('music/$key', cache);

    inline static public function imagePath(key:String, ?cache:Bool = true):FlxGraphic
        return returnCurrentSprite('images/$key', cache);

    inline static public function fontPath(key:String)
        return file('fonts/$key');

    public static function returnCurrentSprite(key:String, ?cache:Bool = true):FlxGraphic
    {
        var spritePath:String = file('$key.png');
        if (Assets.exists(spritePath, IMAGE))
        {
            if (!currentTrackedAssets.exists(spritePath))
            {
                var spriteGraphic:FlxGraphic = FlxGraphic.fromBitmapData(Assets.getBitmapData(spritePath), false, spritePath, cache);
                spriteGraphic.persist = true;
                currentTrackedAssets.set(spritePath, spriteGraphic);
            }

            currentTrackedLocalAssets.push(spritePath);
            return currentTrackedAssets.get(spritePath);
        }

        // trace(spritePath);

        trace('Missing $key sprite from "images" folder of root directory! Attempting to do not crash the game..');
        return null;
    }

    public static function returnCurrentSound(key:String, ?cacheSound:Bool = true, ?beepNoSound:Bool = true):Sound
    {
        for (i in EXISTING_SOUND)
        {
            // trace(file(key + i));
            if (Assets.exists(file(key + i), SOUND))
            {
                var soundPath:String = file(key + i);
                if (!currentTrackedSounds.exists(soundPath)) currentTrackedSounds.set(soundPath, Assets.getSound(soundPath, cacheSound));

                currentTrackedLocalAssets.push(soundPath);
                return currentTrackedSounds.get(soundPath);
            }
            else if (beepNoSound)
            {
                trace('Missing $key sound from "sounds" folder of root directory! Playing default Flixel beep sound instead..');
                return FlxAssets.getSound("flixel/sounds/beep");
            }
        }

        trace('Missing $key sound from "sounds" folder of root directory! Playing default Flixel beep sound instead..');
        return null;
    }

    public static function clearUnusedGameMemory()
    {
        for (memoryKey in currentTrackedAssets.keys())
        {
            if (!currentTrackedLocalAssets.contains(memoryKey))
            {
                destroySpriteGraphics(currentTrackedAssets.get(memoryKey));
                currentTrackedAssets.remove(memoryKey);
            }
        }

        #if sys
        System.gc();
        #elseif cpp
        Gc.compact();
        #end
    }

    @:access(flixel.system.frontEnds.BitmapFrontEnd._cache)
    public static function clearStoredGameMemory()
    {
        for (storedMemoryKey in FlxG.bitmap._cache.keys())
        {
            if (!currentTrackedAssets.exists(storedMemoryKey)) destroySpriteGraphics(FlxG.bitmap.get(storedMemoryKey));
        }

        currentTrackedLocalAssets = [];
    }

    inline static function destroySpriteGraphics(graphic:FlxGraphic)
	{
		if (graphic != null)
        {
            FlxG.bitmap.remove(graphic);
            graphic.destroy();
            graphic.bitmap = null;
        }
	}
}

// Saver data handler (Currently W.I.P!!!)
@:structInit class DataVariable
{
    public var uiElements:Bool = true;
}

class DataHandler
{
    public static var data:DataVariable = {};

    public static function saveData()
    {
        for (dataKey in Reflect.fields(data)) Reflect.setField(FlxG.save.data, dataKey, Reflect.field(data, dataKey));
        FlxG.save.flush();

        var dataSaver:FlxSave = new FlxSave();
        dataSaver.flush();
        FlxG.log.add("Options successfully saved!");
    }
}
