package engine.states;

import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.TimerEvent;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import openfl.text.TextFieldAutoSize;
import openfl.utils.Assets;
import openfl.utils.Timer;

class InitState extends Sprite {
    var bg:Sprite;
    var title:TextField;
    var bg2:Sprite;
    var status:TextField;
    var spTime:Timer;
    var onCompletion:Void -> Void;

    var onFadeOut:Bool = false;
    var fadeSpeed:Float = 0.03;

    var assetsArray:Array<String> = [];
    var loaderCount:Int = 0;
    var totalAssets:Int = 0;
    
    var isTimerComplete:Bool = false;
    var isAssetComplete:Bool = false;

    public function new(onCompletionCallback:Void -> Void) {
        super();
        this.onCompletion = onCompletionCallback;

        bg = new Sprite();
        addChild(bg);

        title = new TextField();
        title.selectable = false;
        title.autoSize = TextFieldAutoSize.CENTER;

        var format = new TextFormat("Bahnschrift", 32, 0xFFFFFF, true);
        format.align = TextFormatAlign.CENTER;
        title.defaultTextFormat = format;
        title.text = "SBinator";
        title.embedFonts = true;
        addChild(title);

        bg2 = new Sprite();
        addChild(bg2);

        status = new TextField();
        var format2 = new TextFormat("_sans", 14, 0xFFFFFF, true);
        format2.align = TextFormatAlign.CENTER;
        status.defaultTextFormat = format2;
        status.selectable = false;
        status.autoSize = TextFieldAutoSize.CENTER;
        status.text = "Loading...";
        addChild(status);

        spTime = new Timer(5000, 1);
        spTime.addEventListener(TimerEvent.TIMER_COMPLETE, onTimerCompletion);
        spTime.start();

        addEventListener(Event.ADDED_TO_STAGE, onAddedStage);
    }

    function onAddedStage(e:Event):Void {
        removeEventListener(Event.ADDED_TO_STAGE, onAddedStage);
        stage.addEventListener(Event.RESIZE, onResize);
        layout();

        onPreloadingStart();
    }

    function layout():Void {
        if (stage == null) return;

        var w = stage.stageWidth;
        var h = stage.stageHeight;

        bg.graphics.clear();
        bg.graphics.beginFill(0x11009159, 1.0);
        bg.graphics.drawRect(0, 0, w, h);
        bg.graphics.endFill();

        if (title != null) {
            title.x = (w - title.width) / 2;
            title.y = (h - title.height) / 2 - 20;
        }

        if (status != null && bg2 != null) {
            var margin:Float = 15;
            var padding:Float = 8;

            bg2.graphics.clear();
            bg2.graphics.beginFill(0xFF000000, 0.9);
            bg2.graphics.drawRoundRect(
                status.x - padding,
                status.y - padding,
                status.width + (padding * 2),
                status.height + (padding * 2),
                8, 8
            );
            bg2.graphics.endFill();

            status.x = w - status.width - 15;
            status.y = h - status.height - 15;
        }
    }

    function onResize(e:Event):Void {
        layout();
    }

    function onPreloadingStart():Void {
        assetsArray = Assets.list().filter(function(path:String):Bool {
            return StringTools.startsWith(path, "assets/");
        });

        totalAssets = assetsArray.length;

        if (totalAssets == 0) {
            status.text = "Loading 0 / 0";
            isAssetComplete = true;
            onFadeReady();
            return;
        }

        updateStatus();

        for (path in assetsArray) {
            var low = path.toLowerCase();

            if (StringTools.endsWith(low, ".ogg") || StringTools.endsWith(low, ".wav") || StringTools.endsWith(low, ".mp3")) {
                Assets.loadSound(path).onComplete(onAssetsLoaded);
            } else if (StringTools.endsWith(low, ".png") || StringTools.endsWith(low, ".jpg") || StringTools.endsWith(low, ".jpeg")) {
                Assets.loadBitmapData(path).onComplete(onAssetsLoaded);
            } else if (StringTools.endsWith(low, ".ttf") || StringTools.endsWith(low, ".otf")) {
                Assets.loadFont(path).onComplete(onAssetsLoaded);
            } else if (StringTools.endsWith(low, ".json")) {
                Assets.loadText(path).onComplete(onAssetsLoaded);
            } else {
                onAssetsLoaded(null);
            }
        }
    }

    function onAssetsLoaded(outcome:Dynamic):Void {
        loaderCount++;
        updateStatus();

        if (loaderCount >= totalAssets) {
            isAssetComplete = true;
            onFadeReady();
        }
    }

    function updateStatus():Void {
        if (status != null) {
            trace('Loading ${loaderCount} / ${totalAssets}...');
            layout();
        }
    }

    function onTimerCompletion(e:TimerEvent):Void {
        if (spTime != null) {
            spTime.stop();
            spTime = null;
        }

        isTimerComplete = true;
        onFadeReady();
    }

    function onFadeReady():Void {
        if (isTimerComplete && isAssetComplete && !onFadeOut) {
            onFadeOut = true;
            addEventListener(Event.ENTER_FRAME, onFadeCompletion);
        }
    }

    function onFadeCompletion(e:Event):Void {
        if (!onFadeOut) return;

        this.alpha -= fadeSpeed;

        if (this.alpha <= 0.0) {
            this.alpha = 0.0;
            onFadeOut = false;
            removeEventListener(Event.ENTER_FRAME, onFadeCompletion);
            finish();
        }
    }

    function finish():Void {
        cleanup();
        if (onCompletion != null) onCompletion();
    }

    public function cleanup():Void {
        removeEventListener(Event.ENTER_FRAME, onFadeCompletion);

        if (stage != null) stage.removeEventListener(Event.RESIZE, onResize);

        if (spTime != null) {
            spTime.stop();
            spTime = null;
        }
    }
}