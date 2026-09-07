package engine.backend.loader;

import away3d.containers.View3D;
import haxe.Json;
import openfl.utils.Assets;

typedef PlatformMetadata = {
    id:String,
    x:Float, y:Float, z:Float,
    width:Float, height:Float, depth:Float,
    color:String
}

typedef MapMetadata = {
    var ?name:String;
    var ?spawn:{ x:Float, y:Float, z:Float };
    var ?voidY:Float;
    var ?platforms:Array<PlatformMetadata>;
}

class LevelLoader {
    public var platforms:Array<Platform> = [];
    public var spawnX:Float = 0;
    public var spawnY:Float = 50;
    public var spawnZ:Float = 0;
    public var voidY:Float = -500;

    public function new() {}

    public function loadMap(jsonPath:String, view:View3D):Bool {
        if (!Assets.exists(jsonPath)) {
            trace('Level failed to load ${jsonPath}');
            return false;
        }

        var rawJSON:String = Assets.getText(jsonPath);
        var metadata:MapMetadata = Json.parse(rawJSON);

        if (metadata.spawn != null) {
            spawnX = metadata.spawn.x;
            spawnY = metadata.spawn.y;
            spawnZ = metadata.spawn.z;
        }

        if (metadata.voidY != 0) voidY = metadata.voidY;

        for (platformData in metadata.platforms) {
            var colorHex:Int = Std.parseInt(platformData.color);
            var platform = new Platform(platformData.id, platformData.x, platformData.y, platformData.z, platformData.width, platformData.height, platformData.depth, colorHex);

            platforms.push(platform);
            view.scene.addChild(platform.mesh);
        }
        return true;
    }
}