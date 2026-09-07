package engine.backend.system.substates;

import openfl.events.Event;
import openfl.display.Sprite;

class SBSubState extends Sprite {
    public var closedCallback:Void -> Void;

    public function new() {
        super();
        addEventListener(Event.ADDED_TO_STAGE, onAddedStage);
    }

    private function onAddedStage(e:Event):Void {
        removeEventListener(Event.ADDED_TO_STAGE, onAddedStage);
        if (stage != null) {
            stage.addEventListener(Event.RESIZE, onResize);
        }
    }

    public function update(elapsed:Float):Void {

    }

    public function onResize(e:Event):Void {

    }
    
    public function close():Void {
        if (stage != null) stage.removeEventListener(Event.RESIZE, onResize);
        if (parent != null) parent.removeChild(this);
        if (closedCallback != null) closedCallback();
    }
}