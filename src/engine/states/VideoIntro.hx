package engine.states;

import hxvlc.openfl.Video;
import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.ui.Keyboard;

class VideoIntro extends SBState {
    var video:Video;
    var finished:Bool = false;

    public function new() {
        super();
        addEventListener(Event.ADDED_TO_STAGE, onAddedStage);
    }

    function onAddedStage(e:Event):Void {
        removeEventListener(Event.ADDED_TO_STAGE, onAddedStage);

        video = new Video();
        video.smoothing = true;

        video.onFormatSetup.add(function():Void {
            video.width = stage.stageWidth;
            video.height = stage.stageHeight;
            video.x = 0;
            video.y = 0;
        });

        video.onEndReached.add(loadToInit);
        video.onEncounteredError.add(function(message:String):Void {
            trace('Failed to load video: $message');
            loadToInit();
        });

        addChild(video);

        stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
        stage.addEventListener(Event.RESIZE, onResize);

        if (video.load("videos/valve.bik")) video.play(); else loadToInit();
    }

    function onResize(e:Event):Void {
        fitVideo();
    }

    function fitVideo():Void {
        if (video == null || stage == null) return;

        var sw:Float = stage.stageWidth;
        var sh:Float = stage.stageHeight;

        if (video.bitmapData == null) return;

        var vw:Float = video.bitmapData.width;
        var vh:Float = video.bitmapData.height;
        if (vw <= 0 || vh <= 0) return;

        var scale:Float = Math.min(sw / vw, sh / vh);
        video.scaleX = scale;
        video.scaleY = scale;

        video.x = (sw - vw * scale) / 2;
        video.y = (sh - vh * scale) / 2;
    }

    function onKeyDown(e:KeyboardEvent):Void {
        if (e.keyCode == Keyboard.ENTER || e.keyCode == Keyboard.SPACE) loadToInit();
    }

    function loadToInit():Void {
        if (finished) return;
        finished = true;

        if (stage != null) {
            stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
            stage.removeEventListener(Event.RESIZE, onResize);
        }

        cleanupVideo();

        if (Main.stateMng != null) {
            Main.stateMng.switchState(new InitState());
        } else {
            SBState.switchState(new InitState());
        }
    }

    function cleanupVideo():Void {
        if (video == null) return;

        video.onEndReached.removeAll();
        video.onFormatSetup.removeAll();
        video.onEncounteredError.removeAll();

        video.stop();
        video.dispose();

        if (video.parent != null) video.parent.removeChild(video);
        video = null;
    }
}