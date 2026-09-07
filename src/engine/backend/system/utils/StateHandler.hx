package engine.backend.system.utils;

import openfl.display.Sprite;
import Type;

class StateHandler {
    private var container:Sprite;
    private var state:SBState;
    public var debug:Debug;

    public function new(root:Sprite, debug:Debug = null) {
        this.container = root;
        this.debug = debug;
    }

    public function switchState(newState:SBState):Void {
        if (state != null) {
            state.cleanup();
            if (container.contains(state)) {
                container.removeChild(state);
            }
        }

        state = newState;
        if (state != null) {
            container.addChild(state);
        }

        if (debug != null && state != null) {
            var path:String = Type.getClassName(Type.getClass(state));
            var className:String = path.split(".").pop();

            if (container.stage != null) {
                if (!container.stage.contains(debug)) {
                    container.stage.addChild(debug);
                } else {
                    container.stage.setChildIndex(debug, container.stage.numChildren - 1);
                }
            } else {
                if (container.contains(debug)) {
                    container.removeChild(debug);
                }
                container.addChild(debug);
            }
        }
    }
}