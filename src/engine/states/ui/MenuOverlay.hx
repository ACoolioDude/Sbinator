package engine.states.ui;

import openfl.text.TextFormatAlign;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.media.Sound;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.utils.Assets;

class MenuOverlay extends Sprite {
    private var options:Array<String> = [
        "NEW MAP",
        "LOAD MAP",
        "OPTIONS",
        "EXIT GAME"
    ];

    private var hover:Sound;
    private var selection:Sound;
    private var curSelection:Int = -1;

    private var textField:Array<TextField> = [];
    private var highlight:Sprite;
    private var onFading:Bool = false;
    private var fadeSpeed:Float = 0.0015; 

    public var onOptionSelection:String -> Void;

    public function new() {
        super();

        this.alpha = 0.0;
        this.visible = false;

        hover = Assets.getSound("sounds/menus/buttonrollover.wav");
        selection = Assets.getSound("sounds/menus/buttonclickrelease.wav");

        onTitleCreation();
        onMenuOptionCreation();

        addEventListener(Event.ENTER_FRAME, onUpdate);
    }

    private function onTitleCreation():Void {
        var title:TextField = new TextField();
        var format:TextFormat = new TextFormat("Bahnschrift", 50, 0xFFFFFFFF, true);

        title.defaultTextFormat = format;
        title.text = "S B I N A T O R";
        title.x = 80;
        title.y = 100;
        title.selectable = false;
        title.width = 600;
        addChild(title);

        var version:TextField = new TextField();
        var format2:TextFormat = new TextFormat("Bahnschrift", 18, 0xFFFFFFFF, false);

        version.text = "Sbinator " + Main.VERSION;
        format2.align = TextFormatAlign.LEFT;
        version.defaultTextFormat = format2;
        version.selectable = false;
        version.x = 10;
        version.y = 600;
        addChild(version);
    }

    private function onMenuOptionCreation():Void {
        highlight = new Sprite();
        addChild(highlight);

        var startY:Float = 280;
        var spacing:Float = 32;

        for (i in 0...options.length) {
            var text:TextField = new TextField();
            var format:TextFormat = new TextFormat("Bahnschrift", 20, 0xFFFFFFFF, false);

            text.defaultTextFormat = format;
            text.text = options[i];
            text.x = 80;
            text.y = startY + (i * spacing);
            text.selectable = false;
            text.width = 300;
            text.height = 28;

            var index:Int = i;
            text.addEventListener(MouseEvent.MOUSE_OVER, function(_) onHighlightSelection(index));
            text.addEventListener(MouseEvent.MOUSE_OUT, function(_) onSelectionClear());
            text.addEventListener(MouseEvent.CLICK, function(_) onOptionClicking(index));

            textField.push(text);
            addChild(text);
        }
    }

    private function onHighlightSelection(index:Int):Void {
        if (!this.visible || this.alpha < 0.2) return;

        if (index != curSelection) {
            curSelection = index;

            if (hover != null) hover.play();
        }

        var text:TextField = textField[index];

        highlight.graphics.clear();
        highlight.graphics.beginFill(0x1F1F1F, 0.7);
        highlight.graphics.drawRoundRect(text.x - 10, text.y, 240, text.height, 8, 8);
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
        removeEventListener(Event.ENTER_FRAME, onUpdate);
        highlight.graphics.clear();
        textField = [];
    }
}