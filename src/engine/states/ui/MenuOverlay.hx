package engine.states.ui;

import openfl.Lib;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.media.Sound;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.utils.Assets;

class MenuOverlay extends SBSubState {
    private static inline var BASE_W:Float = 1280;
    private static inline var BASE_H:Float = 720;

    private var centerVertically:Bool = false;

    public static var MAIN_ITEMS:Array<String> = ["NEW MAP", "LOAD MAP", "CREDITS", "OPTIONS", "EXIT GAME"];
    public static var PAUSE_ITEMS:Array<String> = ["RESUME", "RESTART", "OPTIONS", "QUIT TO MENU", "EXIT GAME"];

    private var options:Array<String>;

    private var hover:Sound;
    private var selection:Sound;
    private var curSelection:Int = -1;

    private var title:TextField;
    private var textField:Array<TextField> = [];
    private var highlight:Sprite;
    private var onFading:Bool = false;
    public var fadeSpeed:Float = 0.0015; 

    public var onOptionSelection:String -> Void;

    public function new(?items:Array<String>, ?titleText:String) {
        super();

        options = (items != null) ? items.copy() : MAIN_ITEMS.copy();

        this.alpha = 0.0;
        this.visible = false;

        hover = Assets.getSound("sounds/menus/buttonrollover.wav");
        selection = Assets.getSound("sounds/menus/buttonclickrelease.wav");

        onTitleCreation(titleText);
        onMenuOptionCreation();

        addEventListener(Event.ADDED_TO_STAGE, onAddedStage);
        addEventListener(Event.ENTER_FRAME, onUpdate);
    }

    override public function onAddedStage(e:Event):Void {
        removeEventListener(Event.ADDED_TO_STAGE, onAddedStage);
        Lib.current.stage.addEventListener(Event.RESIZE, onResize);
        layoutUI();
    }

    override public function onResize(e:Event):Void {
        layoutUI();
    }

    private function onTitleCreation(?titleText:String):Void {
        title = new TextField();
        var format:TextFormat = new TextFormat("Bahnschrift", 50, 0xFFFFFFFF, true);

        title.defaultTextFormat = format;
        title.text = (titleText != null) ? titleText : "S B I N A T O R";
        title.mouseEnabled = false;
        title.selectable = false;
        addChild(title);
    }

    private function onMenuOptionCreation():Void {
        highlight = new Sprite();
        addChild(highlight);

        for (i in 0...options.length) {
            var text:TextField = new TextField();
            var format:TextFormat = new TextFormat("Bahnschrift", 20, 0xFFFFFFFF, false);

            text.defaultTextFormat = format;
            text.text = options[i];
            text.selectable = false;

            var index:Int = i;
            text.addEventListener(MouseEvent.MOUSE_OVER, function(_) onHighlightSelection(index));
            text.addEventListener(MouseEvent.MOUSE_OUT, function(_) onSelectionClear());
            text.addEventListener(MouseEvent.CLICK, function(_) onOptionClicking(index));

            textField.push(text);
            addChild(text);
        }
    }

    private function layoutUI():Void {
        var st = Lib.current.stage;
        var s:Float = Math.min(st.stageWidth / BASE_W, st.stageHeight / BASE_H);

        var titleY:Float = 100;
        var startY:Float = 280;
        var spacing:Float = 32;
        var itemH:Float = 28;
        var leftX:Float = 80;

        var blockTop:Float = titleY;
        var blockBottom:Float = startY + (options.length - 1) * spacing + itemH;
        var blockCenter:Float = (blockTop + blockBottom) / 2;

        var shiftY:Float = centerVertically ? (st.stageHeight / 2 - blockCenter * s) : 0;

        setFontSize(title, Math.round(50 * s));
        title.x = leftX * s;
        title.y = titleY * s + shiftY;
        title.width = 600 * s;
        title.height = 80 * s;

        for (i in 0...textField.length) {
            var tf:TextField = textField[i];
            setFontSize(tf, Math.round(20 * s));
            tf.x = leftX * s;
            tf.y = (startY + i * spacing) * s + shiftY;
            tf.width = 300 * s;
            tf.height = itemH * s;
        }

        if (curSelection >= 0) onHighlightSelection(curSelection);
    }

    private function setFontSize(tf:TextField, size:Float):Void {
        var fmt:TextFormat = tf.defaultTextFormat;
        fmt.size = Std.int(size);
        tf.defaultTextFormat = fmt;
        tf.setTextFormat(new TextFormat(null, Std.int(size)));
    }

    private function currentScale():Float {
        var st = Lib.current.stage;
        return Math.min(st.stageWidth / BASE_W, st.stageHeight / BASE_H);
    }

    private function onHighlightSelection(index:Int):Void {
        if (!this.visible || this.alpha < 0.2) return;

        if (index != curSelection) {
            curSelection = index;

            if (hover != null) hover.play();
        }

        var s:Float = currentScale();
        var text:TextField = textField[index];

        highlight.graphics.clear();
        highlight.graphics.beginFill(0x1F1F1F, 0.7);
        highlight.graphics.drawRoundRect(text.x - 10 * s, text.y, 240 * s, text.height, 8 * s, 8 * s);
        highlight.graphics.endFill();

        for (i in 0...textField.length) {
            var fmt:TextFormat = textField[i].defaultTextFormat;
            fmt.color = (i == index) ? 0xFFFFFF : 0xCCCCCC;
            textField[i].setTextFormat(fmt);
        }
    }

    private function onOptionClicking(index:Int):Void {
        if (!this.visible || this.alpha < 0.8) return;

        if (selection != null) selection.play();

        var option:String = options[index];
        if (onOptionSelection != null) onOptionSelection(option);
    }

    private function onSelectionClear():Void {
        curSelection = -1;
        highlight.graphics.clear();

        for (i in 0...textField.length) {
            var tf:TextField = textField[i];
            var fmt:TextFormat = tf.defaultTextFormat;
            fmt.color = 0xCCCCCC;
            tf.defaultTextFormat = fmt;
            tf.setTextFormat(fmt);
        }
    }

    public function onOverlayShowing():Void {
        this.visible = true;
        this.alpha = 0.0;
        this.onFading = true;
    }

    private function onUpdate(e:Event):Void {
        if (onFading) {
            this.alpha += fadeSpeed;
            if (this.alpha >= 1.0) {
                this.alpha = 1.0;
                onFading = false;
            }
        }
    }

    public function destroy():Void {
        removeEventListener(Event.ADDED_TO_STAGE, onAddedStage);
        removeEventListener(Event.ENTER_FRAME, onUpdate);
        Lib.current.stage.removeEventListener(Event.RESIZE, onResize);
        highlight.graphics.clear();
        textField = [];
    }
}
