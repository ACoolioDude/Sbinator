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

class LevelSelectionOverlay extends SBSubState {
    var target:Dynamic;

    private var bg:Sprite;
    private var panelUI:Sprite;
    private var title:TextField;
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

    private function initUI():Void {
        bg = new Sprite();
        addChild(bg);

        panelUI = new Sprite();
        addChild(panelUI);

        title = new TextField();
        title.defaultTextFormat = new TextFormat("_sans", 12, 0xFFFFFF, true);
        title.text = "NEW GAME (Test)";
        title.selectable = false;
        panelUI.addChild(title);

        closeButt = new Sprite();
        closeButt.buttonMode = true;
        closeButt.addEventListener(MouseEvent.CLICK, onClosureClick);
        addChild(closeButt);

        closeTitle = new TextField();
        closeTitle.defaultTextFormat = new TextFormat("_sans", 12, 0xFFFFFF, false);
        closeTitle.mouseEnabled = false;
        closeTitle.selectable = false;
        closeTitle.text = "Cancel";
        addChild(closeTitle);

        createChapterSelection();
    }

    private function layoutUI():Void {
        this.x = 0;
        this.y = 0;

        var stageW:Float = (stage != null) ? stage.stageWidth : Lib.current.stage.stageWidth;
        var stageH:Float = (stage != null) ? stage.stageHeight : Lib.current.stage.stageHeight;

        var panelW:Float = 700;
        var panelH:Float = 450;

        var buttW:Float = 80;
        var buttH:Float = 30;

        bg.graphics.clear();
        bg.graphics.beginFill(0x000000, 0.7);
        bg.graphics.drawRect(-2000, -2000, stageW + 4000, stageH + 4000);
        bg.graphics.endFill();

        panelUI.graphics.clear();
        panelUI.graphics.beginFill(0x1e1e1e, 0.95);
        panelUI.graphics.lineStyle(2, 0x333333, 1.0);
        panelUI.graphics.drawRoundRect(0, 0, panelW, panelH, 12, 12);
        panelUI.graphics.endFill();

        panelUI.x = (stageW - panelW) / 2;
        panelUI.y = (stageH - panelH) / 2;

        title.x = 12;
        title.y = 10;

        closeButt.graphics.clear();
        closeButt.graphics.beginFill(0x333333);
        closeButt.graphics.drawRoundRect(0, 0, buttW, buttH, 8, 8);
        closeButt.graphics.endFill();
        closeButt.x = panelUI.x + panelW - buttW - 10;
        closeButt.y = panelUI.y + 410;

        closeTitle.x = closeButt.x + 18;
        closeTitle.y = closeButt.y + 6;
    }

    private function createChapterSelection():Void {
        var startX:Float = 20;
        var startY:Float = 60;
        var cardW:Float = 175;
        var cardH:Float = 110;
        var spacing:Float = 18;

        for (i in 0...levels.length) {
            var map = levels[i];
            var xPos = startX * (i * (cardW + spacing));
            var yPos = startY;

            var title = new TextField();
            title.defaultTextFormat = new TextFormat("_sans", 11, (i == levelSelection) ? 0x00854D : 0xAAAAAA, true);
            title.text = map.levelTitle;
            title.x = xPos + 20;
            title.y = yPos + 16;
            title.selectable = false;
            panelUI.addChild(title);

            var nameT = new TextField();
            nameT.text = map.name;
            nameT.x = xPos + 20;
            nameT.y = yPos + 35;
            nameT.selectable = false;
            panelUI.addChild(nameT);

            var thumbnail = new Sprite();
            thumbnail.x = xPos + 20;
            thumbnail.y = yPos + 40;
            thumbnail.buttonMode = true;
            thumbnail.doubleClickEnabled = true;

            var bitmap = ResourceLoader.bitmapData(map.image);
            var image = new Bitmap(bitmap);
            image.scaleX = cardW / image.width;
            image.scaleY = cardH / image.height;
            thumbnail.addChild(image);

            panelUI.addChild(thumbnail);

            thumbnail.addEventListener(MouseEvent.DOUBLE_CLICK, function(e:MouseEvent):Void {
                levelSelection = i;

                if (target.soundCh != null) target.soundCh.stop();
                target.cleanup();

                haxe.Timer.delay(function(){
                    if (Main.stateMng != null) Main.stateMng.switchState(new LoadingState(map.fileKey));
                    close();
                }, 2000);
            });
        }
    }

    private function onWindowResize(e:Event) {
        layoutUI();
    }

    private function onClosureClick(e:MouseEvent):Void {
        if (onClose != null) onClose();

        mouseEnabled = false;
        mouseChildren = false;

        removeEventListener(Event.ENTER_FRAME, onEnterFrameFadeIn);
        addEventListener(Event.EXIT_FRAME, onEnterFrameFadeOut);
    }

    private function onEnterFrameFadeOut(e:Event):Void {
        alpha -= 0.05;
        if (alpha <= 0.0) {
            alpha = 0.0;
            removeEventListener(Event.EXIT_FRAME, onEnterFrameFadeOut);
            destroy();
        }
    }

    public function destroy():Void {
        removeEventListener(Event.ADDED_TO_STAGE, onEnterFrameFadeIn);
        Lib.current.removeEventListener(Event.RESIZE, onWindowResize);
        if (closeButt != null) closeButt.removeEventListener(MouseEvent.CLICK, onClosureClick);
        if (parent != null) parent.removeChild(this);
    }
}