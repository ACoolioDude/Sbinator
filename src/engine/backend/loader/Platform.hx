package engine.backend.loader;

import away3d.entities.Mesh;
import away3d.materials.ColorMaterial;
import away3d.primitives.CubeGeometry;

class Platform {
    public var id:String;
    public var mesh:Mesh;
    public var x:Float;
    public var y:Float;
    public var z:Float;
    public var width:Float;
    public var height:Float;
    public var depth:Float;

    public var topY:Float;

    public function new(id:String, x:Float, y:Float, z:Float, width:Float, height:Float, depth:Float, colorHex:Int) {
        this.id = id;
        this.x = x;
        this.y = y;
        this.z = z;
        this.width = width;
        this.height = height;
        this.depth = depth;

        this.topY = y + (height / 2);

        var geom = new CubeGeometry(width, height, depth);
        var mat = new ColorMaterial(colorHex);

        this.mesh = new Mesh(geom, mat);
        this.mesh.x = x;
        this.mesh.y = y;
        this.mesh.z = z;
    }

    public function isPoint(px:Float, pz:Float):Bool {
        var halfW = width / 2;
        var halfD = depth / 2;

        return (px >= (x - halfW) && px <= (x + halfW)) && (pz >= (z - halfD) && pz <= (z +  halfD));
    }
}