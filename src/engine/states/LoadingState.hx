package engine.states;

import haxe.Json;
import haxe.Timer;
import openfl.display.StageAlign;
import openfl.display.StageScaleMode;
import openfl.utils.Assets;
import openfl.display.Bitmap;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFieldAutoSize;

class LoadingState extends SBState {
    private var bg:Bitmap;
    private var progressBar:Sprite;
    private var statusBg:Sprite;
    private var status:TextField;

    private var playstateInst:PlayState;
    private var curStep:Int = 0;
    private var totalStep:Int = 4;
    private var mapData:MapMetadata;
    private var mapName:String;

    public function new(mapName:String = "dev_stage") {
        super();
        this.mapName = mapName;

        var bgBitmap = ResourceLoader.bitmapData("images/menus/loading/loading.jpg");
        bg = new Bitmap(bgBitmap);
        addChild(bg);

        progressBar = new Sprite();
        addChild(progressBar);

        statusBg = new Sprite();
        addChild(statusBg);

        status = new TextField();
        var format2 = new TextFormat("Bahnschrift", 14, 0xFFFFFF, true);
        format2.align = openfl.text.TextFormatAlign.CENTER;
        status.defaultTextFormat = format2;
        status.selectable = false;
        status.autoSize = TextFieldAutoSize.CENTER;
        status.text = "Loading...";
        addChild(status);

        addEventListener(Event.ADDED_TO_STAGE, onAddedStage);
    }

    private function onAddedStage(e:Event):Void {
        removeEventListener(Event.ADDED_TO_STAGE, onAddedStage);
        stage.addEventListener(Event.RESIZE, onResize);
        layout();

        addEventListener(Event.ENTER_FRAME, onLoadingProcess);
    }

    private function layout():Void {
        if (stage == null) return;

        stage.scaleMode = StageScaleMode.NO_SCALE;
        stage.align = StageAlign.TOP_LEFT;

        var w:Float = stage.stageWidth;
        var h:Float = stage.stageHeight;

        if (bg != null && bg.bitmapData != null) {
            bg.width = stage.stageWidth;
            bg.height = stage.stageHeight;
        }

        if (status != null && statusBg != null && progressBar != null) {
            var margin:Float = 20;
            var padding:Float = 10;
            var barHeight:Float = 6;
            var boxWidth:Float = 260;

            var boxX:Float = w - boxWidth - margin;
            var boxHeight:Float = status.height + barHeight + (padding * 2) + 4;

            var boxY:Float = h - boxHeight - margin;

            status.x = boxX + padding;
            status.y = boxY + padding;

            statusBg.graphics.clear();
            statusBg.graphics.beginFill(0x000000, 0.9);
            statusBg.graphics.lineStyle(1, 0x444444, 0.8);
            statusBg.graphics.drawRoundRect(boxX, boxY, boxWidth, boxHeight, 6, 6);
            statusBg.graphics.endFill();

            var barX:Float = boxX + padding;
            var barY:Float = status.y + status.height + 4;
            var maxBarWidth:Float = boxWidth - (padding * 2);
            var progressRation:Float = curStep / totalStep;
            var currentBarWidth:Float = maxBarWidth * progressRation;

            progressBar.graphics.clear();
            progressBar.graphics.beginFill(0x222222, 1.0);
            progressBar.graphics.drawRect(barX, barY, maxBarWidth, barHeight);
            progressBar.graphics.endFill();

            if (currentBarWidth > 0) {
                progressBar.graphics.beginFill(0xFFFFFF, 1.0);
                progressBar.graphics.drawRect(barX, barY, currentBarWidth, barHeight);
                progressBar.graphics.endFill();
            }
        }
    }

    private function onResize(e:Event):Void layout();

    private function updateStatus(message:String):Void {
        trace(message);
        layout();
    } 

    private function onLoadingProcess(e:Event):Void {
        switch (curStep) {
            case 0:
                var jsonPath = 'data/maps/${mapName}.json';
                if (Assets.exists(jsonPath)) {
                    var raw:String = Assets.getText(jsonPath);
                    mapData = Json.parse(raw);
                    updateStatus("Loading map level from " + jsonPath);
                } else {
                    updateStatus("Map failed to load!");
                }
                curStep++;

            case 1:
                updateStatus("Switching to new state instance");
                playstateInst = new PlayState(mapData);
                curStep++;
            
            case 2:
                updateStatus("Load stage");
                curStep++;

            case 3:
                updateStatus("Completed loading!");
                curStep++;
                layout();

                removeEventListener(Event.ENTER_FRAME, onLoadingProcess);

                Timer.delay(function() {
                    trace('Loading last stage of ${stage != null}, PlayState instance ${playstateInst != null}');
                    if (playstateInst != null) {
                        if (Main.stateMng != null) {
                            Main.stateMng.switchState(playstateInst);
                        } else {
                            switchState(playstateInst);
                        }
                    } 
                }, 1500);
        }
    }

    override public function cleanup():Void {
        super.cleanup();

        stage.removeEventListener(Event.RESIZE, onResize);

        if (bg != null && contains(bg)) removeChild(bg);
        if (statusBg != null && contains(statusBg)) removeChild(statusBg);
        if (status != null && contains(status)) removeChild(status);
        if (progressBar != null && contains(progressBar)) removeChild(progressBar);

        graphics.clear();
    }
}