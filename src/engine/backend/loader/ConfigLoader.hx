package engine.backend.loader;

import sys.io.File;
import sys.FileSystem;

class Options {
    public static var fps:Int = 60;
    public static var skyboxSpeed:Float = 0.1;
    public static var skyboxFov:Int = 60;

    private static inline var CONFIG_DIRECTORY:String = "assets/data/conf";
    private static inline var CONFIG_PATH:String = "assets/data/conf/settings.cfg";

    public static function save():Void {
        var data = haxe.Json.stringify({
            fps: fps,
            skyboxSpeed: skyboxSpeed,
            skyboxFov: skyboxFov
        });
    
        try {
            if (!FileSystem.exists(CONFIG_DIRECTORY)) FileSystem.createDirectory(CONFIG_DIRECTORY);
            File.saveContent(CONFIG_PATH, data);
            trace('Configuration saved!');
        } catch (e:Dynamic) {
            trace('Configuration failed to save: ${e}');
        }
    }

    public static function load():Void {
        try {
            if (FileSystem.exists(CONFIG_PATH)) {
                var content = File.getContent(CONFIG_PATH);
                var parsed = haxe.Json.parse(content);
            
                if (Reflect.hasField(parsed, "fps")) fps = parsed.fps;
                if (Reflect.hasField(parsed, "skyboxSpeed")) skyboxSpeed = parsed.skyboxSpeed;
                if (Reflect.hasField(parsed, "skyboxFov")) skyboxFov = parsed.skyboxFov;
            
                trace('Configuration loaded successfully!');
            }
        } catch (e:Dynamic) {
            trace('Configuration failed to load: ${e}');
        }
    }

    public static function resetOptions():Void {
        fps = 60;
        skyboxSpeed = 0.1;
        skyboxFov = 60;

        try {
            if (FileSystem.exists(CONFIG_PATH)) FileSystem.deleteFile(CONFIG_PATH);
        } catch (e:Dynamic) {
            trace('Configuration deletion failed: ${e}');
        }
    }
}