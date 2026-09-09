package engine.states.ui;

import openfl.events.Event;
import openfl.Lib;
import openfl.display.Sprite;
import openfl.events.MouseEvent;
import openfl.text.TextField;
import openfl.text.TextFormat;

class PopupOverlay extends SBSubState {
    public function new(titleString:String, messageString:String, onConfirm:Void -> Void, ?onCancel:Void -> Void) {
        super();
        
        alpha = 0;

        var stageW:Float = Lib.current.stage.stageWidth;
        var stageH:Float = Lib.current.stage.stageHeight;

        var background = new Sprite();
        background.graphics.beginFill(0x000000, 0.4);
        background.graphics.drawRect(-2000, -2000, stageW + 4000, stageH + 4000);
        background.graphics.endFill();
        addChild(background);

        var boxW:Float = 360;
        var boxH:Float = 160;
        var panelUI = new Sprite();
        panelUI.graphics.beginFill(0x1e1e1e, 0.95);
        panelUI.graphics.lineStyle(2, 0x333333, 1.0);
        panelUI.graphics.drawRoundRect(0, 0, boxW, boxH, 10, 10);
        panelUI.graphics.endFill();
        panelUI.x = (stageW - boxW) / 2;
        panelUI.y = (stageH - boxH) / 2;
        addChild(panelUI);

        var title = new TextField();
        title.defaultTextFormat = new TextFormat("Bahnschrift", 11, 0xAAAAAA, true);
        title.text = titleString.toUpperCase();
        title.x = panelUI.x + 15;
        title.y = panelUI.y + 12;
        title.selectable = false;
        title.mouseEnabled = false;
        addChild(title);

        var message = new TextField();
        message.defaultTextFormat = new TextFormat("Bahnschrift", 13, 0xFFFFFF, false);
        message.text = messageString;
        message.x = panelUI.x + 70;
        message.y = panelUI.y + 50;
        message.width = boxW - 40;
        message.selectable = false;
        message.mouseEnabled = false;
        addChild(message);

        var firstButt = createButtons("Confirm", panelUI.x + 80, panelUI.y + 110, 95, 28, function() {
            close();
            onConfirm();
        });
        addChild(firstButt);

        var secondButt = createButtons("Cancel", panelUI.x + 185, panelUI.y + 110, 95, 28, function() {
            close();
            if (onCancel != null) onCancel();
        });
        addChild(secondButt);

        addEventListener(Event.ADDED_TO_STAGE, onAddedStage);
    }

    override public function onAddedStage(e:Event):Void {
        removeEventListener(Event.ADDED_TO_STAGE, onAddedStage);
        addEventListener(Event.ENTER_FRAME, onEnterFrameFadeIn);

        if (parent != null) parent.setChildIndex(this, parent.numChildren - 1);
    }

    private function onEnterFrameFadeIn(e:Event):Void {
        alpha += 0.15;
        if (alpha >= 1.0) {
            alpha = 1.0;
            removeEventListener(Event.ENTER_FRAME, onEnterFrameFadeIn);
        }
    }

    private function createButtons(label:String, x:Float, y:Float, w:Float, h:Float, onClick:Void -> Void):Sprite {
        var butt = new Sprite();
        butt.graphics.beginFill(0x333333);
        butt.graphics.drawRoundRect(0, 0, w, h, 6, 6);
        butt.graphics.endFill();
        butt.x = x;
        butt.y = y;
        butt.buttonMode = true;

        var text = new TextField();
        text.defaultTextFormat = new TextFormat("Bahnschrift", 12, 0xFFFFFF, true);
        text.text = label;
        text.x = (w - 50) / 2;
        text.y = 4;
        text.selectable = false;
        text.mouseEnabled = false;
        butt.addChild(text);

        butt.addEventListener(MouseEvent.CLICK, function(e:MouseEvent) {
            onClick();
        });
        return butt;
    }
}