package engine.states.ui;

import openfl.Lib;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;

class PopupOverlay extends SBSubState {
    private static inline var BASE_W:Float = 1280;
    private static inline var BASE_H:Float = 720;

    private static inline var BOX_W:Float = 360;
    private static inline var BOX_H:Float = 160;
    private static inline var BUTT_W:Float = 95;
    private static inline var BUTT_H:Float = 28;

    private var background:Sprite;
    private var panelUI:Sprite;
    private var title:TextField;
    private var message:TextField;
    private var firstButt:Sprite;
    private var firstLabel:TextField;
    private var secondButt:Sprite;
    private var secondLabel:TextField;

    public function new(titleString:String, messageString:String, onConfirm:Void -> Void, ?onCancel:Void -> Void) {
        super();
        
        alpha = 0;

        background = new Sprite();
        addChild(background);

        panelUI = new Sprite();
        addChild(panelUI);

        title = new TextField();
        title.defaultTextFormat = new TextFormat("Bahnschrift", 11, 0xAAAAAA, true);
        title.text = titleString.toUpperCase();
        title.selectable = false;
        title.mouseEnabled = false;
        addChild(title);

        message = new TextField();
        var messageFormat = new TextFormat("Bahnschrift", 13, 0xFFFFFF, false);
        messageFormat.align = TextFormatAlign.CENTER;
        message.defaultTextFormat = messageFormat;
        message.text = messageString;
        message.wordWrap = true;
        message.selectable = false;
        message.mouseEnabled = false;
        addChild(message);

        firstLabel = new TextField();
        firstButt = createButtons(firstLabel, "Confirm", function() {
            close();
            onConfirm();
        });
        addChild(firstButt);

        secondLabel = new TextField();
        secondButt = createButtons(secondLabel, "Cancel", function() {
            close();
            if (onCancel != null) onCancel();
        });
        addChild(secondButt);

        layoutUI();

        addEventListener(Event.ADDED_TO_STAGE, onAddedStage);
    }

    override public function onAddedStage(e:Event):Void {
        removeEventListener(Event.ADDED_TO_STAGE, onAddedStage);
        addEventListener(Event.REMOVED_FROM_STAGE, onRemovedStage);
        addEventListener(Event.ENTER_FRAME, onEnterFrameFadeIn);
        Lib.current.stage.addEventListener(Event.RESIZE, onResize);

        layoutUI();

        if (parent != null) parent.setChildIndex(this, parent.numChildren - 1);
    }

    private function onRemovedStage(e:Event):Void {
        removeEventListener(Event.REMOVED_FROM_STAGE, onRemovedStage);
        removeEventListener(Event.ENTER_FRAME, onEnterFrameFadeIn);
        Lib.current.stage.removeEventListener(Event.RESIZE, onResize);
    }

    override public function onResize(e:Event):Void {
        layoutUI();
    }

    private function onEnterFrameFadeIn(e:Event):Void {
        alpha += 0.15;
        if (alpha >= 1.0) {
            alpha = 1.0;
            removeEventListener(Event.ENTER_FRAME, onEnterFrameFadeIn);
        }
    }

    private function layoutUI():Void {
        var st = Lib.current.stage;
        var stageW:Float = st.stageWidth;
        var stageH:Float = st.stageHeight;
        var s:Float = Math.min(stageW / BASE_W, stageH / BASE_H);

        background.graphics.clear();
        background.graphics.beginFill(0x000000, 0.4);
        background.graphics.drawRect(-2000, -2000, stageW + 4000, stageH + 4000);
        background.graphics.endFill();

        var boxW:Float = BOX_W * s;
        var boxH:Float = BOX_H * s;

        panelUI.graphics.clear();
        panelUI.graphics.beginFill(0x1e1e1e, 0.95);
        panelUI.graphics.lineStyle(2 * s, 0x333333, 1.0);
        panelUI.graphics.drawRoundRect(0, 0, boxW, boxH, 10 * s, 10 * s);
        panelUI.graphics.endFill();
        panelUI.x = (stageW - boxW) / 2;
        panelUI.y = (stageH - boxH) / 2;

        setFontSize(title, 11 * s);
        title.x = panelUI.x + 15 * s;
        title.y = panelUI.y + 12 * s;
        title.width = (BOX_W - 30) * s;
        title.height = 20 * s;

        setFontSize(message, 13 * s);
        message.x = panelUI.x + 20 * s;
        message.y = panelUI.y + 50 * s;
        message.width = (BOX_W - 40) * s;
        message.height = 50 * s;

        var pairW:Float = BUTT_W * 2 + 10;
        var pairX:Float = (BOX_W - pairW) / 2;
        layoutButton(firstButt, firstLabel, panelUI.x + pairX * s, panelUI.y + 110 * s, s);
        layoutButton(secondButt, secondLabel, panelUI.x + (pairX + BUTT_W + 10) * s, panelUI.y + 110 * s, s);
    }

    private function setFontSize(tf:TextField, size:Float):Void {
        var px:Int = Std.int(Math.max(1, Math.round(size)));
        var fmt:TextFormat = tf.defaultTextFormat;
        fmt.size = px;
        tf.defaultTextFormat = fmt;
        tf.setTextFormat(new TextFormat(null, px));
    }

    private function layoutButton(butt:Sprite, label:TextField, x:Float, y:Float, s:Float):Void {
        butt.graphics.clear();
        butt.graphics.beginFill(0x333333);
        butt.graphics.drawRoundRect(0, 0, BUTT_W * s, BUTT_H * s, 6 * s, 6 * s);
        butt.graphics.endFill();
        butt.x = x;
        butt.y = y;

        setFontSize(label, 12 * s);
        label.x = 0;
        label.y = 4 * s;
        label.width = BUTT_W * s;
        label.height = (BUTT_H - 4) * s;
    }

    private function createButtons(text:TextField, label:String, onClick:Void -> Void):Sprite {
        var butt = new Sprite();
        butt.buttonMode = true;

        var fmt = new TextFormat("Bahnschrift", 12, 0xFFFFFF, true);
        fmt.align = TextFormatAlign.CENTER;
        text.defaultTextFormat = fmt;
        text.text = label;
        text.selectable = false;
        text.mouseEnabled = false;
        butt.addChild(text);

        butt.addEventListener(MouseEvent.CLICK, function(e:MouseEvent) {
            onClick();
        });
        return butt;
    }
}
