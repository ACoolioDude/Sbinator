package;

import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.ui.Keyboard;

class Main extends Sprite {
    var splash:InitState;
    var menu:MenuState;
    var debug:Debug;
    public static var VERSION:String = "0.0.1";

    public function new() {
        super();
        addEventListener(Event.ADDED_TO_STAGE, onAddedStage);
    }

    function onAddedStage(e:Event):Void {
        removeEventListener(Event.ADDED_TO_STAGE, onAddedStage);
   
        menu = new MenuState();
        addChild(menu);

        splash = new InitState(function() {
            if (splash != null && contains(splash)) {
                removeChild(splash);
                splash = null;
            }
            menu.playJiggle();
        });
        addChild(splash);

        debug = new Debug(menu.onGet3DView());
        debug.visible = false;
        addChild(debug);

        stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDownPressed);
        stage.addEventListener(Event.ENTER_FRAME, onEnterFrame);
    }

    function onKeyDownPressed(e:KeyboardEvent):Void {
        if (e.keyCode == Keyboard.F3) {
            debug.visible = !debug.visible;
        }
    }

    function onEnterFrame(e:Event):Void {
        if (debug != null && debug.visible) {
            debug.update();
        }
    }
}