package engine.states;

import haxe.Json;
import haxe.Timer;
import openfl.display.Bitmap;
import openfl.display.Sprite;
import openfl.display.StageAlign;
import openfl.display.StageScaleMode;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import openfl.utils.Assets;

class LoadingState extends SBState {
    private var bg:Bitmap;
    private var progressBar:Sprite;
    private var statusBg:Sprite;
    private var status:TextField;
    private var closeBg:Sprite;
    private var closeTxt:TextField;
    private var closed:Bool = false;

    private var playstateInst:PlayState;
    private var mapData:MapMetadata;
    private var mapName:String;

    private var steps:Array<{label:String, run:Void -> Void}>;
    private var curStep:Int = 0;
    private var stepAnnounced:Bool = false;
    private var failed:Bool = false;
    private var finished:Bool = false;
    private var cleaned:Bool = false;

    private var shownProgress:Float = 0.0;
    private var targetProgress:Float = 0.0;
    private static inline var BAR_SPEED:Float = 0.25;

    private var barX:Float = 0;
    private var barY:Float = 0;
    private var maxBarWidth:Float = 0;
    private var barHeight:Float = 6;

    public function new(mapName:String = "dev_stage") {
        super();
        this.mapName = mapName;

        steps = [
            { label: "Reading map data", run: loadMapData },
            { label: "Creating game state", run: createPlayState },
            { label: "Building 3D view", run: buildView },
            { label: "Building platforms", run: buildPlatforms },
            { label: "Spawning player", run: buildPlayer }
        ];

        var bgBitmap = ResourceLoader.bitmapData("images/menus/loading/loading.jpg");
        bg = new Bitmap(bgBitmap);
        addChild(bg);

        statusBg = new Sprite();
        addChild(statusBg);

        status = new TextField();
        var format2 = new TextFormat("Bahnschrift", 14, 0xFFFFFF, true);
        format2.align = TextFormatAlign.LEFT;
        status.defaultTextFormat = format2;
        status.selectable = false;
        status.mouseEnabled = false;
        status.text = "Loading...";
        addChild(status);

        closeBg = new Sprite();
        closeBg.buttonMode = true;
        closeBg.addEventListener(MouseEvent.CLICK, onCancelClick);
        closeBg.addEventListener(MouseEvent.MOUSE_OVER, function(_) closeTxt.textColor = 0xFFFFFF);
        closeBg.addEventListener(MouseEvent.MOUSE_OUT, function(_) closeTxt.textColor = 0xAAAAAA);
        addChild(closeBg);

        closeTxt = new TextField();
        var formatX = new TextFormat("Bahnschrift", 14, 0xAAAAAA, true);
        formatX.align = TextFormatAlign.CENTER;
        closeTxt.defaultTextFormat = formatX;
        closeTxt.selectable = false;
        closeTxt.mouseEnabled = false;
        closeTxt.text = "X";
        closeBg.addChild(closeTxt);

        progressBar = new Sprite();
        addChild(progressBar);

        addEventListener(Event.ADDED_TO_STAGE, onAddedStage);
    }

    private function onAddedStage(e:Event):Void {
        removeEventListener(Event.ADDED_TO_STAGE, onAddedStage);
        stage.addEventListener(Event.RESIZE, onResize);
        layout();

        addEventListener(Event.ENTER_FRAME, onFrame);
    }

    private function loadMapData():Void {
        var jsonPath = 'data/maps/${mapName}.json';
        if (Assets.exists(jsonPath)) {
            mapData = Json.parse(Assets.getText(jsonPath));
        } else {
            failed = true;
        }
    }

    private function createPlayState():Void {
        playstateInst = new PlayState(mapData);
    }

    private function buildView():Void {
        if (playstateInst != null) playstateInst.buildView();
    }

    private function buildPlatforms():Void {
        if (playstateInst != null) playstateInst.buildPlatforms();
    }

    private function buildPlayer():Void {
        if (playstateInst != null) playstateInst.buildPlayer();
    }

    private function layout():Void {
        if (stage == null) return;

        stage.scaleMode = StageScaleMode.NO_SCALE;
        stage.align = StageAlign.TOP_LEFT;

        var w:Float = stage.stageWidth;
        var h:Float = stage.stageHeight;

        if (bg != null && bg.bitmapData != null) {
            bg.width = w;
            bg.height = h;
        }

        if (status != null && statusBg != null && progressBar != null) {
            var margin:Float = 20;
            var padding:Float = 10;
            var boxWidth:Float = 260;
            var textHeight:Float = 22;
            var xSize:Float = textHeight;

            var boxHeight:Float = textHeight + barHeight + (padding * 2) + 4;

            var pos = LoadingLayout.boxPosition(Options.loadingUI, w, h, boxWidth, boxHeight, margin);
            var boxX:Float = pos.x;
            var boxY:Float = pos.y;

            status.width = boxWidth - (padding * 2) - xSize;
            status.height = textHeight;
            status.x = boxX + padding;
            status.y = boxY + padding;

            closeBg.graphics.clear();
            closeBg.graphics.beginFill(0x333333, 1.0);
            closeBg.graphics.drawRoundRect(0, 0, xSize, xSize, 6, 6);
            closeBg.graphics.endFill();
            closeBg.x = boxX + boxWidth - padding - xSize;
            closeBg.y = boxY + padding;

            closeTxt.width = xSize;
            closeTxt.height = xSize;
            closeTxt.y = 2;

            statusBg.graphics.clear();
            statusBg.graphics.beginFill(0x000000, 0.9);
            statusBg.graphics.lineStyle(1, 0x444444, 0.8);
            statusBg.graphics.drawRoundRect(boxX, boxY, boxWidth, boxHeight, 8, 8);
            statusBg.graphics.endFill();

            barX = boxX + padding;
            barY = status.y + textHeight + 4;
            maxBarWidth = boxWidth - (padding * 2);

            drawBar();
        }
    }

    private function drawBar():Void {
        progressBar.graphics.clear();
        progressBar.graphics.beginFill(0x222222, 1.0);
        progressBar.graphics.drawRect(barX, barY, maxBarWidth, barHeight);
        progressBar.graphics.endFill();

        var currentBarWidth:Float = maxBarWidth * shownProgress;
        if (currentBarWidth > 0) {
            progressBar.graphics.beginFill(0x008150, 1.0);
            progressBar.graphics.drawRect(barX, barY, currentBarWidth, barHeight);
            progressBar.graphics.endFill();
        }
    }

    private function onResize(e:Event):Void layout();

    private function setStatus(message:String):Void {
        trace(message);
    }

    private function onFrame(e:Event):Void {
        if (shownProgress < targetProgress) {
            shownProgress += (targetProgress - shownProgress) * BAR_SPEED;
            if (targetProgress - shownProgress < 0.002) shownProgress = targetProgress;
            drawBar();
        }

        if (failed || finished || closed) return;

        if (shownProgress < targetProgress) return;

        if (curStep >= steps.length) {
            onAllStepsDone();
            return;
        }

        if (!stepAnnounced) {
            setStatus(steps[curStep].label);
            stepAnnounced = true;
            return;
        }

        steps[curStep].run();
        curStep++;
        stepAnnounced = false;
        targetProgress = curStep / steps.length;

        if (failed) onFailed();
    }

    private function onAllStepsDone():Void {
        finished = true;
        setStatus("Completed loading!");

        Timer.delay(function() {
            if (cleaned || closed) return;
            if (playstateInst != null) {
                if (Main.stateMng != null) {
                    Main.stateMng.switchState(playstateInst);
                } else {
                    SBState.switchState(playstateInst);
                }
            }
        }, 1500);
    }

    private function onCancelClick(e:MouseEvent):Void {
        if (closed || finished) return;
        closed = true;

        playstateInst = null;

        var menu = new MenuState();
        if (Main.stateMng != null) {
            Main.stateMng.switchState(menu);
        } else {
            SBState.switchState(menu);
        }
    }

    private function onFailed():Void {
        setStatus("Map failed to load!");

        Timer.delay(function() {
            if (cleaned) return;
            var menu = new MenuState();
            if (Main.stateMng != null) {
                Main.stateMng.switchState(menu);
            } else {
                SBState.switchState(menu);
            }
        }, 2000);
    }

    override public function cleanup():Void {
        cleaned = true;

        removeEventListener(Event.ENTER_FRAME, onFrame);
        if (stage != null) stage.removeEventListener(Event.RESIZE, onResize);

        super.cleanup();

        if (bg != null && contains(bg)) removeChild(bg);
        if (statusBg != null && contains(statusBg)) removeChild(statusBg);
        if (status != null && contains(status)) removeChild(status);
        if (progressBar != null && contains(progressBar)) removeChild(progressBar);
        if (closeBg != null) {
            closeBg.removeEventListener(MouseEvent.CLICK, onCancelClick);
            if (contains(closeBg)) removeChild(closeBg);
        }

        graphics.clear();
    }
}
