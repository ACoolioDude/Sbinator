package engine.backend.ui;

class LoadingLayout {
    public static var CORNER_NAMES:Array<String> = ["Top Left", "Top Right", "Bottom Left", "Bottom Right", "Center"];

    public static function boxPosition(corner:Int, stageW:Float, stageH:Float, boxW:Float, boxH:Float, margin:Float):{x:Float, y:Float} {
        if (corner < 0 || corner >= CORNER_NAMES.length) corner = 3;

        if (corner == 4) {
            return { x: (stageW - boxW) / 2, y: (stageH - boxH) / 2 };
        }

        var left:Bool = (corner == 0 || corner == 2);
        var top:Bool = (corner == 0 || corner == 1);

        return {
            x: left ? margin : stageW - boxW - margin,
            y: top ? margin : stageH - boxH - margin
        };
    }
}
