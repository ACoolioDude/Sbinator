package engine.debug;

import away3d.containers.View3D;
import haxe.macro.Compiler;
import openfl.Lib;
import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFieldAutoSize;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import openfl.system.System;

class Debug extends Sprite {
    var left:TextField;
    var right:TextField;
    var viewThreeDe:View3D;

    var frameCount:Int = 0;
    var time:Float = 0;
    var framerate:Float = 0;

    public function new(view:View3D) {
        super();
        this.viewThreeDe = view;

        left = onCreationText();
        left.x = 2;
        left.y = 2;
        addChild(left);
        
        right = onCreationText();
        right.autoSize = TextFieldAutoSize.RIGHT;
        right.y = 2;
        addChild(right);
    }

    function onCreationText():TextField {
        var text = new TextField();
        text.selectable = false;
        text.mouseEnabled = false;
        text.autoSize = TextFieldAutoSize.LEFT;

        var format = new TextFormat("Bahnschrift", 14, 0xFFFFFF);
        format.align = TextFormatAlign.RIGHT;
        text.defaultTextFormat = format;
        text.embedFonts = true;
        return text;
    }

    public function update():Void {
        if (!visible) return;

        frameCount++;
        var timeNow = Lib.getTimer();
        if (timeNow - time >= 1000) {
            framerate = frameCount * 1000 / (timeNow - time);
            frameCount = 0;
            time = timeNow;
        }

        var memory = Std.int(System.totalMemory / 1024 / 1024);

        left.text = '${Std.int(framerate)} FPS\n${memory} MB';
        right.text = 'Sbinator ${Main.VERSION}\n\nHaxe: ${Compiler.getDefine("haxe")}\nOS: ${SystemUtils.getOSName()}\nDisplay: ${viewThreeDe.width}x${viewThreeDe.height}';

        if (stage != null) {
            graphics.clear();
            graphics.beginFill(0x000000, 0.4);
            graphics.drawRect(0, 0, stage.stageWidth, stage.stageHeight);
            graphics.endFill();

            right.x = stage.stageWidth - right.width - 2;
        }

        /*var camera = viewThreeDe.camera;
        var positionX = Math.fround(camera.position.x * 100) / 100;
        var positionY = Math.fround(camera.position.y * 100) / 100;
        var positionZ = Math.fround(camera.position.z * 100) / 100;*/
    }
}