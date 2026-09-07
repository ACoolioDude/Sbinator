package engine.states;

import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import openfl.text.TextFieldAutoSize;
import openfl.events.Event;
import openfl.events.TimerEvent;
import openfl.utils.Timer;
import openfl.utils.Assets;

class InitState extends SBState {

    var bg:Sprite;
    var bg2:Sprite;
    var title:TextField;
    var status:TextField;
    var spTime:Timer;

    var onFadeOut:Bool = false;
    var fadeSpeed:Float = 0.03;

    var assetsArray:Array<String> = [
        "data/maps/dev_stage.json",
        "fonts/bahnschrift.ttf",
        "images/menus/backgrounds/panorama_0.png",
        "images/menus/backgrounds/panorama_1.png",
        "images/menus/backgrounds/panorama_2.png",
        "images/menus/backgrounds/panorama_3.png",
        "images/menus/backgrounds/panorama_4.png",
        "images/menus/backgrounds/panorama_5.png",
        "images/menus/loading/loading.jpg",
        "sounds/menus/buttonrollover.wav",
        "sounds/menus/buttonclickrelease.wav",
        "assets/music/jiggle.ogg"
    ];

    var loaderCount:Int = 0;
    var totalAssets:Int = 0;

    var isTimerComplete:Bool = false;
    var isAssetComplete:Bool = false;

    public function new() {
        super();

        bg = new Sprite();
        addChild(bg);

        bg2 = new Sprite();
        addChild(bg2);

        title = new TextField();
        title.selectable = false;
        title.autoSize = TextFieldAutoSize.CENTER;
        
        var format = new TextFormat("Bahnschrift", 32, 0xFFFFFF, true);
        format.align = TextFormatAlign.CENTER;
        title.defaultTextFormat = format;
        title.text = "SBinator";
        title.embedFonts = false;
        addChild(title);

        status = new TextField();
        status.selectable = false;
        status.autoSize = TextFieldAutoSize.RIGHT;

        var format2 = new TextFormat("_sans", 14, 0xFFFFFF, true);
        format2.align = TextFormatAlign.RIGHT;
        status.defaultTextFormat = format2;
        status.text = "Loading...";
        status.embedFonts = false;
        addChild(status);

        addEventListener(Event.ADDED_TO_STAGE, onAddedStage);
    }

    function onAddedStage(e:Event):Void {
        removeEventListener(Event.ADDED_TO_STAGE, onAddedStage);
        stage.addEventListener(Event.RESIZE, onResize);

        layout();
        onPreloadingStart();
    }

    function onResize(e:Event):Void {
        layout();
    }

    function layout():Void {
        if (stage == null) return;

        var w:Float = stage.stageWidth;
        var h:Float = stage.stageHeight;

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

            status.x = w - status.width - margin;
            status.y = h - status.height - margin;

            bg2.graphics.clear();
            bg2.graphics.beginFill(0x000000, 0.9);
            bg2.graphics.drawRoundRect(
                status.x - padding,
                status.y - padding,
                status.width + (padding * 2),
                status.height + (padding * 2),
                8, 8
            );
            bg2.graphics.endFill();
        }
    }

    function onPreloadingStart():Void {
        totalAssets = assetsArray.length;
        loaderCount = 0;

        trace('Starting preload for ${totalAssets} assets...');

        spTime = new Timer(3000, 1);
        spTime.addEventListener(TimerEvent.TIMER_COMPLETE, onTimerCompletion);
        spTime.start();

        if (totalAssets == 0) {
            isAssetComplete = true;
            onFadeReady();
            return;
        }

        for (path in assetsArray) {
            var low = path.toLowerCase();
            //trace('Loading: ${path}');

            if (StringTools.endsWith(low, ".ogg") || StringTools.endsWith(low, ".wav") || StringTools.endsWith(low, ".mp3")) {
                Assets.loadSound(path).onComplete(function(_) onAssetsLoaded(path)).onError(function(err) onAssetError(path, err));
            } else if (StringTools.endsWith(low, ".png") || StringTools.endsWith(low, ".jpg") || StringTools.endsWith(low, ".jpeg")) {
                Assets.loadBitmapData(path).onComplete(function(_) onAssetsLoaded(path)).onError(function(err) onAssetError(path, err));
            } else if (StringTools.endsWith(low, ".ttf") || StringTools.endsWith(low, ".otf")) {
                Assets.loadFont(path).onComplete(function(_) onAssetsLoaded(path)).onError(function(err) onAssetError(path, err));
            } else if (StringTools.endsWith(low, ".json")) {
                Assets.loadText(path).onComplete(function(_) onAssetsLoaded(path)).onError(function(err) onAssetError(path, err));
            } else {
                onAssetsLoaded(path);
            }
        }
    }

    function onAssetsLoaded(path:String):Void {
        loaderCount++;
        trace('Loaded [${loaderCount}/${totalAssets}]: ${path}');
        trace('Loading ${loaderCount} / ${totalAssets}...');

        if (loaderCount >= totalAssets) {
            isAssetComplete = true;
            trace('All assets completed loading!');
            onFadeReady();
        }
    }

    function onAssetError(path:String, err:Dynamic):Void {
        trace('ERROR loading ${path}: ${err}');
        onAssetsLoaded(path);
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
        this.alpha -= fadeSpeed;

        if (this.alpha <= 0.0) {
            this.alpha = 0.0;
            onFadeOut = false;
            removeEventListener(Event.ENTER_FRAME, onFadeCompletion);
            finish();
        }
    }

    function finish():Void {
        this.alpha = 1.0;

        if (Main.stateMng != null) {
            Main.stateMng.switchState(new MenuState());
        } else {
            switchState(new MenuState());
        }
    }

    override public function cleanup():Void {
        super.cleanup();

        removeEventListener(Event.ENTER_FRAME, onFadeCompletion);

        if (stage != null) {
            stage.removeEventListener(Event.RESIZE, onResize);
        }

        if (spTime != null) {
            spTime.stop();
            spTime = null;
        }
    }
}