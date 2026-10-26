package engine.states.ui;

import openfl.utils.Timer;
import openfl.display.Bitmap;
import openfl.Assets;
import openfl.events.MouseEvent;
import openfl.Lib;
import openfl.events.Event;
import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;

class LevelSelectionOverlay extends SBSubState {
    private static inline var BASE_W:Float = 1280;
    private static inline var BASE_H:Float = 720;

    var target:Dynamic;

    private var uiScale:Float = 1.0;

    private var bg:Sprite;
    private var panelUI:Sprite;
    private var title:TextField;
    private var cards:Sprite;
    private var closeButt:Sprite;
    private var closeTitle:TextField;

    private var levelSelection:Int = 0;
    private var levels:Array<Dynamic> = [
        {
            levelTitle: "DEV STAGE",
            name: "TEST STAGE",
            fileKey: "dev_stage",
            image: "images/menus/level_selection/dev_stage.png"
        }
    ];
    public var onClose:Void -> Void;

    public function new(state:Dynamic):Void {
        super();

        this.target = state;
        alpha = 0;

        addEventListener(Event.ADDED_TO_STAGE, onAddedStage);
    }

    override public function onAddedStage(e:Event):Void {
        removeEventListener(Event.ADDED_TO_STAGE, onAddedStage);
        Lib.current.stage.addEventListener(Event.RESIZE, onWindowResize);
        addEventListener(Event.ENTER_FRAME, onEnterFrameFadeIn);

        initUI();
        layoutUI();

        if (parent != null) parent.setChildIndex(this, parent.numChildren -1);
    }

    private function onEnterFrameFadeIn(e:Event):Void {
        alpha += 0.15;
        if (alpha >= 1.0) {
            alpha = 1.0;
            removeEventListener(Event.ENTER_FRAME, onEnterFrameFadeIn);
        }
    }

    private function px(base:Float):Int {
        return Std.int(Math.max(1, Math.round(base * uiScale)));
    }

    private function setFontSize(tf:TextField, size:Int):Void {
        var fmt:TextFormat = tf.defaultTextFormat;
        fmt.size = size;
        tf.defaultTextFormat = fmt;
        tf.setTextFormat(new TextFormat(null, size));
    }

    private function initUI():Void {
        bg = new Sprite();
        addChild(bg);

        panelUI = new Sprite();
        addChild(panelUI);

        title = new TextField();
        title.defaultTextFormat = new TextFormat("Bahnschrift", 12, 0xFFFFFF, true);
        title.text = "NEW GAME (Test)";
        title.selectable = false;
        title.mouseEnabled = false;
        panelUI.addChild(title);

        cards = new Sprite();
        panelUI.addChild(cards);

        var buttonFormat:TextFormat = new TextFormat("Bahnschrift", 12, 0xFFFFFF, false);
        buttonFormat.align = TextFormatAlign.CENTER;

        closeButt = new Sprite();
        closeButt.buttonMode = true;
        closeButt.addEventListener(MouseEvent.CLICK, onClosureClick);
        addChild(closeButt);

        closeTitle = new TextField();
        closeTitle.defaultTextFormat = buttonFormat;
        closeTitle.mouseEnabled = false;
        closeTitle.selectable = false;
        closeTitle.text = "Cancel";
        addChild(closeTitle);
    }

    private function layoutUI():Void {
        this.x = 0;
        this.y = 0;

        var st = Lib.current.stage;
        var stageW:Float = st.stageWidth;
        var stageH:Float = st.stageHeight;

        uiScale = Math.min(stageW / BASE_W, stageH / BASE_H);
        var s:Float = uiScale;

        var panelW:Float = 700 * s;
        var panelH:Float = 450 * s;

        var buttW:Float = 80 * s;
        var buttH:Float = 30 * s;

        bg.graphics.clear();
        bg.graphics.beginFill(0x000000, 0.7);
        bg.graphics.drawRect(-2000, -2000, stageW + 4000, stageH + 4000);
        bg.graphics.endFill();

        panelUI.graphics.clear();
        panelUI.graphics.beginFill(0x1e1e1e, 0.95);
        panelUI.graphics.lineStyle(2 * s, 0x333333, 1.0);
        panelUI.graphics.drawRoundRect(0, 0, panelW, panelH, 12 * s, 12 * s);
        panelUI.graphics.endFill();

        panelUI.x = (stageW - panelW) / 2;
        panelUI.y = (stageH - panelH) / 2;

        setFontSize(title, px(12));
        title.x = 12 * s;
        title.y = 10 * s;
        title.width = 400 * s;

        closeButt.graphics.clear();
        closeButt.graphics.beginFill(0x333333);
        closeButt.graphics.drawRoundRect(0, 0, buttW, buttH, 8 * s, 8 * s);
        closeButt.graphics.endFill();
        closeButt.x = panelUI.x + panelW - buttW - 10 * s;
        closeButt.y = panelUI.y + 410 * s;

        setFontSize(closeTitle, px(12));
        closeTitle.width = buttW;
        closeTitle.height = 20 * s;
        closeTitle.x = closeButt.x;
        closeTitle.y = closeButt.y + 6 * s;

        createChapterSelection();
    }

    private function createChapterSelection():Void {
        while (cards.numChildren > 0) cards.removeChildAt(0);

        var s:Float = uiScale;

        var startX:Float = 20;
        var startY:Float = 60;
        var cardW:Float = 175;
        var cardH:Float = 110;
        var spacing:Float = 18;

        for (i in 0...levels.length) {
            var map = levels[i];
            var xPos:Float = (startX + i * (cardW + spacing)) * s;
            var yPos:Float = startY * s;

            var levelTitle = new TextField();
            levelTitle.defaultTextFormat = new TextFormat("Bahnschrift", px(11), (i == levelSelection) ? 0x00854D : 0xAAAAAA, true);
            levelTitle.text = map.levelTitle;
            levelTitle.x = xPos;
            levelTitle.y = yPos + 16 * s;
            levelTitle.width = cardW * s;
            levelTitle.selectable = false;
            cards.addChild(levelTitle);

            var nameT = new TextField();
            nameT.text = map.name;
            nameT.x = xPos;
            nameT.y = yPos + 35 * s;
            nameT.selectable = false;
            cards.addChild(nameT);

            var thumbnail = new Sprite();
            thumbnail.x = xPos;
            thumbnail.y = yPos + 40 * s;
            thumbnail.buttonMode = true;
            thumbnail.doubleClickEnabled = true;

            var bitmap = ResourceLoader.bitmapData(map.image);
            var image = new Bitmap(bitmap);
            var nativeW:Float = image.width;
            var nativeH:Float = image.height;
            image.scaleX = (cardW * s) / nativeW;
            image.scaleY = (cardH * s) / nativeH;
            thumbnail.addChild(image);

            cards.addChild(thumbnail);

            thumbnail.addEventListener(MouseEvent.DOUBLE_CLICK, function(e:MouseEvent):Void {
                levelSelection = i;

                target.cleanup();

                haxe.Timer.delay(function(){
                    if (Main.stateMng != null) Main.stateMng.switchState(new LoadingState(map.fileKey));
                    close();
                }, 2000);
            });
        }
    }

    private function onWindowResize(e:Event):Void {
        layoutUI();
    }

    private function onClosureClick(e:MouseEvent):Void {
        if (onClose != null) onClose();

        mouseEnabled = false;
        mouseChildren = false;

        removeEventListener(Event.ENTER_FRAME, onEnterFrameFadeIn);
        addEventListener(Event.ENTER_FRAME, onEnterFrameFadeOut);
    }

    private function onEnterFrameFadeOut(e:Event):Void {
        alpha -= 0.05;
        if (alpha <= 0.0) {
            alpha = 0.0;
            removeEventListener(Event.ENTER_FRAME, onEnterFrameFadeOut);
            destroy();
        }
    }

    public function destroy():Void {
        removeEventListener(Event.ADDED_TO_STAGE, onAddedStage);
        removeEventListener(Event.ENTER_FRAME, onEnterFrameFadeIn);
        removeEventListener(Event.ENTER_FRAME, onEnterFrameFadeOut);
        Lib.current.stage.removeEventListener(Event.RESIZE, onWindowResize);
        if (closeButt != null) closeButt.removeEventListener(MouseEvent.CLICK, onClosureClick);
        if (parent != null) parent.removeChild(this);
    }
}
