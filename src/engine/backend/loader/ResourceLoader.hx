package engine.backend.loader;

import openfl.display.BitmapData;
import openfl.geom.Rectangle;
import openfl.utils.Assets;

class ResourceLoader {
    private static var checkerCache:BitmapData = null;
    private static var textureCache:Map<String, BitmapData> = new Map();

    public static function resolveId(id:String):String {
        if (Assets.exists(id)) return id;

        if (StringTools.startsWith(id, "assets/")) {
            var stripped = id.substr("assets/".length);
            if (Assets.exists(stripped)) return stripped;
        } else {
            var prefixed = "assets/" + id;
            if (Assets.exists(prefixed)) return prefixed;
        }

        return null;
    }

    private static function keyFor(path:String):String {
        var id = resolveId(path);
        return (id != null) ? id : path;
    }

    public static function bitmapData(path:String):BitmapData {
        var id = resolveId(path);
        var key = (id != null) ? id : path;

        if (textureCache.exists(key)) return textureCache.get(key);

        var data:BitmapData = null;
        if (id != null) {
            data = Assets.getBitmapData(id);
            if (data != null) trace('Found BITMAP data ${id}!');
        }

        if (data == null) {
            data = checkerboard();
            trace('Could not find BITMAP data ${path}!');
        }

        textureCache.set(key, data);
        return data;
    }

    public static function checkerboard(size:Int = 64, tile:Int = 32):BitmapData {
        if (checkerCache != null) return checkerCache;

        checkerCache = new BitmapData(size, size, false, 0xFF000000);
        var purple:Int = 0xFFFF00FF;

        for (x in 0...Std.int(size / tile)) {
            for (y in 0...Std.int(size / tile)) {
                if ((x + y) % 2 == 0) checkerCache.fillRect(new Rectangle(x * tile, y * tile, tile, tile), purple);
            }
        }
        return checkerCache;
    }

    public static function disposeTexture(path:String):Void {
        var key = keyFor(path);
        if (!textureCache.exists(key)) return;

        var bitmapDt = textureCache.get(key);
        textureCache.remove(key);

        if (bitmapDt != null && bitmapDt != checkerCache) {
            bitmapDt.dispose();
            Assets.cache.removeBitmapData(key);
        }
    }

    public static function cleanBitmapCache():Void {
        var keys:Array<String> = [for (k in textureCache.keys()) k];
        for (k in keys) disposeTexture(k);
        textureCache.clear();
    }
}
