package engine.backend.loader;

import openfl.display.BitmapData;
import openfl.geom.Rectangle;
import openfl.utils.Assets;

class ResourceLoader {
    private static var checkerCache:BitmapData = null;
    private static var textureCache:Map<String, BitmapData> = new Map();

    public static function bitmapData(path:String):BitmapData {
        if (textureCache.exists(path)) return textureCache.get(path);

        var data:BitmapData = null;
        if (Assets.exists(path)) {
            data = Assets.getBitmapData(path);
            trace('Found BITMAP data ${path}!');
        } else if (data == null) {
            data = checkerboard();
            trace('Could not find BITMAP data ${path}!');
        }

        textureCache.set(path, data);
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
        if (textureCache.exists(path)) {
            var bitmapDt = textureCache.get(path);
            if (bitmapDt != checkerCache) bitmapDt.dispose();
            textureCache.remove(path);
        }
    }

    public static function cleanBitmapCache():Void {
        for (path in textureCache.keys()) disposeTexture(path);
        textureCache.clear();
    }
}