package engine.states.game.substates;

import openfl.ui.Keyboard;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import openfl.text.TextFieldAutoSize;

class PauseSubstate extends SBSubState {
    private var bg:Sprite;
    private var text:TextField;

    public function new() {
        super();

        bg = new Sprite();
        addChild(bg);
    
        text = new TextField();
        var format2 = new TextFormat("Bahnschrift", 14, 0xFFFFFF, true);
        format2.align = TextFormatAlign.CENTER;
        text.defaultTextFormat = format2;
        text.selectable = false;
        text.autoSize = TextFieldAutoSize.CENTER;
        text.text = "PAUSED";
        addChild(text);

        addEventListener(Event.ADDED_TO_STAGE, setupPause);
    }

    private function setupPause(e:Event):Void {
        removeEventListener(Event.ADDED_TO_STAGE, setupPause);
        if (stage != null) stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
    }

    private function onKeyDown(e:KeyboardEvent):Void {
        if (e.keyCode == Keyboard.ESCAPE) {
            e.stopImmediatePropagation();
            close();
        }
    }

    override function onResize(e:Event) {
        if (stage == null) return;
        
        var w = stage.stageWidth;
        var h = stage.stageHeight;

        if (text != null) {
            text.x = (w - text.width) / 2;
            text.y = (h - text.height) / 2 - 20;
        }
    }

    override function close():Void {
        if (stage != null) stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
        super.close();
    }
}
