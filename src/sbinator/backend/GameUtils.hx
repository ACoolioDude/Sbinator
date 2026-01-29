package sbinator.backend;

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
import lime.graphics.opengl.GL;
import openfl.display.BitmapData;
import openfl.media.Sound;
import openfl.system.Capabilities;
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

    // Credits for CNE (Codename Engine) devs for this working code!
    public static function getDebug():String {
        static var osName:String = "Unknown";
        static var cpuName:String = "Unknown";
        static var cpuArch:String = "Unknown";
        static var gpuName:String = "Unknown";

        if (lime.system.System.platformLabel != null && lime.system.System.platformLabel != "" && lime.system.System.platformVersion != null && lime.system.System.platformVersion != "") {
            #if linux
            var process = new HiddenProcess("cat", ["/etc/os-release"]);
		    if (process.exitCode() != 0) trace('Unable to grab OS Label');
		    else
            {
			    var distroName = "";
			    var osVersion = "";
			    for (line in process.stdout.readAll().toString().split("\n"))
                {
				    if (line.startsWith("PRETTY_NAME="))
                    {
					    var index = line.indexOf('"');
					    if (index != -1) distroName = line.substring(index + 1, line.lastIndexOf('"'));
					else
                    {
						var arr = line.split("=");
						arr.shift();
						distroName = arr.join("=");
					}
				}

				if (line.startsWith("VERSION="))
                {
					var index = line.indexOf('"');
					if (index != -1)
						osVersion = line.substring(index + 1, line.lastIndexOf('"'));
					else
                    {
						var arr = line.split("=");
						arr.shift();
						osVersion = arr.join("=");
					}
				}
			}

			if (distroName != "") osName = '${distroName} ${osVersion}'.trim() + " - " + LinuxHandler.de + " v" + LinuxHandler.version + " (" + LinuxHandler.getWMInfo() + " - " + LinuxHandler.getSessionInfo() + ")";
		    }
            #else
            osName = lime.system.System.platformLabel.replace(lime.system.System.platformVersion, "").trim() + " - " + lime.system.System.platformVersion;
            #end
        } else {
            trace('Unable to grab system label!');
        }

        try
        {
			#if windows
			var process = new HiddenProcess("wmic", ["cpu", "get", "name"]);
			if (process.exitCode() != 0)
			    throw 'Could not fetch CPU information';
			cpuName = process.stdout.readAll().toString().trim().split("\n")[1].trim();
			#elseif mac
			var process = new HiddenProcess("sysctl -a | grep brand_string"); // Somehow this isnt able to use the args but it still works
			if (process.exitCode() != 0)
			    throw 'Could not fetch CPU information';
			cpuName = process.stdout.readAll().toString().trim().split(":")[1].trim();
			#elseif linux
			var process = new HiddenProcess("cat", ["/proc/cpuinfo"]);
			if (process.exitCode() != 0)
			    throw 'Could not fetch CPU information';
			for (line in process.stdout.readAll().toString().split("\n")) {
				if (line.indexOf("model name") == 0) {
					cpuName = line.substring(line.indexOf(":") + 2);
					break;
				}
			}
			#end
		} catch (e) {
			trace('Unable to grab CPU Name: $e');
		}

		try
		{
		    cpuArch = '${Capabilities.cpuArchitecture}_${(Capabilities.supports64BitProcesses ? '64' : '32')}';
		} catch (e) {
            trace('Unable to grab CPU Architecture: $e');
		}

        try
        {
            gpuName = GL.getParameter(GL.RENDERER) + "\nOpenGL " + GL.getParameter(GL.VERSION);
        } catch (e) {
            trace('Unable to grab GPU Name: $e');
        }

        return 'Sbinator v${gameVersion}\nState: ${Type.getClassName(Type.getClass(FlxG.state))}${FlxG.state.subState != null ? ' [Substate: ${Type.getClassName(Type.getClass(FlxG.state.subState))}]' : ''}\nOS: ${osName}\nCPU: ${cpuName} - ${cpuArch}\nGPU: ${gpuName}\nBranch: ${Main.releaseCycle} - (Commit v${GitHub.getGitCommitHash()} - ${GitHub.getGitBranch()})';
    }
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

    inline static public function soundPath(key:String, ?cache:Bool = true):Sound {
        var sound:Sound = returnCurrentSound('sounds/$key', cache);
        return sound;
    }

    inline static public function musicPath(key:String, ?cache:Bool = true):Sound {
        var music:Sound = returnCurrentSound('music/$key', cache);
        return music;
    }

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

// Actual working DE/WM detector!
#if linux
class LinuxHandler {

    public static var de:String;
    public static var version:String;

    public static function init():Void {
        if (de != null) return;

        de = getDEInfo();
        version = getDEVersion(de);
    }

    public static function getDEInfo():String
    {
        var desktopEnvironment = Sys.getEnv("XDG_CURRENT_DESKTOP");
        if (desktopEnvironment != null && desktopEnvironment != "") {
            return desktopEnvironment.split(";")[0];
        }

        desktopEnvironment = Sys.getEnv("DESKTOP_SESSION");
        if (desktopEnvironment != null && desktopEnvironment != "") {
            return desktopEnvironment.split(";")[0];
        }

        return "Unknown";
    }

    public static function getDEVersion(version:String):String {
        switch (version.toUpperCase()) {
            case "GNOME": return parse(run("gnome-shell", ["--version"]));
            case "Cinnamon": return parse(run("cinnamon-session", ["--version"]));
            case "KDE": return parse(run("plasmashell", ["--version"]));
            case "XFCE": return parse(run("xfce4-session", ["--version"]));
            case "LXQT": return parse(run("lxqt-session", ["--version"]));
            default: return "";
        }
    }

    public static function getWMInfo():String {
        var desktop = Sys.getEnv("XDG_CURRENT_DESKTOP");
        if (desktop == null) desktop = "";

        desktop = desktop.toLowerCase();

        if (desktop.indexOf("kde") != -1) return "KWin";
        if (desktop.indexOf("gnome") != -1) return "Mutter";
        if (desktop.indexOf("xfce") != -1) return "Xfwm4";
        if (desktop.indexOf("cinnamon") != -1) return "Muffin";
        if (desktop.indexOf("lxqt") | desktop.indexOf("lxde") != -1) return "Openbox";

        return "Unknown";
    }

    public static function getSessionInfo():String {
        var raw = Sys.getEnv("XDG_SESSION_TYPE");

        var session:String = switch (raw) {
            case "wayland": "Wayland";
            case "x11": "X11";
            case null | "": "";
            default: "";
        };

        return session;
    }

    static function run(command:String, arguments:Array<String>):String {
        try {
            var process = new sys.io.Process(command, arguments);
            var output = process.stdout.readAll().toString();
            process.close();
            return output;
        } catch (e:Dynamic) {
            return "";
        }
    }

    static function parse(s:String):String {
        var clean = s;
        clean = StringTools.replace(clean, "plasmashell", "");
        clean = StringTools.replace(clean, "gnome-shell", "");
        clean = StringTools.replace(clean, "xfce4-session", "");
        clean = StringTools.replace(clean, "cinnamon-session", "");
        clean = StringTools.replace(clean, "lxqt-session", "");
        clean = clean.trim();

        var r = ~/([0-9]+(\.[0-9]+){0,2}([^\s]*)?)/;
        return r.match(clean) ? r.matched(0) : "Unknown";
    }
}
#end
