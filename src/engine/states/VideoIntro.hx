package engine.states;

import hxvlc.openfl.Video;
import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;
import openfl.ui.Keyboard;

class VideoIntro extends SBState {
    var video:Video;
    var finished:Bool = false;

    public function new() {
        super();
        addEventListener(Event.ADDED_TO_STAGE, onAddedStage);
    }

    function onAddedStage(e:Event):Void {
        video = new Video();
        video.smoothing = true;

        video.onFormatSetup.add(function():Void{
            video.width = stage.stageWidth;
            video.height = stage.stageHeight;
            video.x = 0;
            video.y = 0;
        });

        video.onEndReached.add(loadToInit);
        video.onEncounteredError.add(function(message:String):Void {
            trace('Failed to load video $message');
        });
        
        addChild(video);

        stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);

        if (video.load("videos/valve.bik")) video.play(); else loadToInit();
    }

    private function onKeyDown(e:KeyboardEvent):Void if (e.keyCode == Keyboard.ENTER || e.keyCode == Keyboard.SPACE) loadToInit();

    function loadToInit():Void {
        if (finished) return;
        finished = true;

        removeEventListener(Event.ADDED_TO_STAGE, onAddedStage);
        removeChild(video);

        if (Main.stateMng != null) {
            Main.stateMng.switchState(new InitState());
        } else {
            switchState(new InitState());
        }
    }
}