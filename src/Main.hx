package;

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

    public function new() {
        super();

        #if linux
        Lib.current.stage.window.setIcon(Image.fromFile("app/icon.png"));
        #end

        SBCrash.init();
        addEventListener(Event.ADDED_TO_STAGE, onAddedStage);
    }

    function onAddedStage(e:Event):Void {
        removeEventListener(Event.ADDED_TO_STAGE, onAddedStage);

        debug = new Debug(null);
        debug.visible = false;

        Main.stateMng = new StateHandler(this, debug);

        stateMng.switchState(new InitState());

        stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDownPressed);
        stage.addEventListener(Event.ENTER_FRAME, onEnterFrame);
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
}