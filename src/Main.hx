package;

import openfl.media.SoundTransform;
import openfl.media.SoundMixer;
import lime.graphics.Image;
import openfl.Lib;
import openfl.display.Sprite;
import openfl.display.StageDisplayState;
import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.ui.Keyboard;

class Main extends Sprite {
    public static var debug:Debug;
    public static var stateMng:StateHandler;
    public static var VERSION:String = "0.0.1";
    private static var lostFocus:Bool = false;

    public function new() {
        super();

        #if linux
        Lib.current.stage.window.setIcon(Image.fromFile("app/icon.png"));
        #end
        addEventListener(Event.ADDED_TO_STAGE, onAddedStage);
    }

    function onAddedStage(e:Event):Void {
        removeEventListener(Event.ADDED_TO_STAGE, onAddedStage);

        SBCrash.init();
        Options.load();

        Lib.current.stage.frameRate = (Options.fps == 0) ? 0 : Options.fps;

        debug = new Debug(null);
        debug.visible = false;

        Main.stateMng = new StateHandler(this, debug);

        if (Options.introVideo) 
            stateMng.switchState(new VideoIntro());
        else 
            stateMng.switchState(new InitState());

        stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDownPressed);
        stage.addEventListener(Event.ENTER_FRAME, onEnterFrame);

        stage.addEventListener(Event.ACTIVATE, onFocusGain);
        stage.addEventListener(Event.DEACTIVATE, onFocusLost);
    }

    function onKeyDownPressed(e:KeyboardEvent):Void {
        if (e.keyCode == Keyboard.F3) {
            debug.visible = !debug.visible;
        }

        if (e.keyCode == Keyboard.F11) {
            if (stage.displayState == StageDisplayState.FULL_SCREEN) {
                stage.displayState = StageDisplayState.NORMAL;
            } else {
                stage.displayState = StageDisplayState.FULL_SCREEN;
            }
            e.stopPropagation();
        }
    }

    function onEnterFrame(e:Event):Void {
        if (debug != null && debug.visible) {
            debug.update();
        }
    }

    function onFocusLost(e:Event):Void {
        if (!Options.autoPause) return;

        lostFocus = true;
        SoundMixer.soundTransform = new SoundTransform(0);
        stage.frameRate = 10;
    }

    function onFocusGain(e:Event):Void {
        if (!lostFocus) return;

        lostFocus = false;
        SoundMixer.soundTransform = new SoundTransform(1);
        stage.frameRate = (Options.fps == 0) ? 0 : Options.fps;
    }
}