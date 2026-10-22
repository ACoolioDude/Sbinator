package engine.states.ui;

import openfl.ui.Keyboard;
import openfl.events.KeyboardEvent;
import openfl.Lib;
import openfl.display.Sprite;
import openfl.events.Event;

class CreditsOverlay extends SBSubState {
    private var targetState:Dynamic;

    private var background:Sprite;
    public var onClose:Void -> Void;

    private var closing:Bool = false;

    public function new(newTarget:Dynamic) {
        super();
        this.targetState = newTarget;

        alpha = 0;
        addEventListener(Event.ADDED_TO_STAGE, onAddedStage);
    }

    override function onAddedStage(e:Event):Void {
        removeEventListener(Event.ADDED_TO_STAGE, onAddedStage);

        initUI();
        layoutUI();

        // Register once, directly on the stage
        stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
        stage.addEventListener(Event.RESIZE, onWindowResize);
        addEventListener(Event.ENTER_FRAME, onEnterFrameFadeIn);
    }

    private function initUI():Void {
        background = new Sprite();
        addChild(background);
    }

    // Layout only, no listener registration here
    private function layoutUI():Void {
        x = 0;
        y = 0;

        var stageW:Float = stage.stageWidth;
        var stageH:Float = stage.stageHeight;

        background.graphics.clear();
        background.graphics.beginFill(0x000000, 0.6);
        background.graphics.drawRect(-2000, -2000, stageW + 4000, stageH + 4000);
        background.graphics.endFill();
    }

    private function onKeyDown(e:KeyboardEvent):Void {
        if (e.keyCode == Keyboard.ESCAPE) close();
    }

    private function onWindowResize(e:Event):Void {
        layoutUI();
    }

    private function onEnterFrameFadeIn(e:Event):Void {
        alpha += 0.15;
        if (alpha >= 1.0) {
            alpha = 1.0;
            removeEventListener(Event.ENTER_FRAME, onEnterFrameFadeIn);
        }
    }

    override public function close():Void {
        if (closing) return;
        closing = true;

        if (stage != null) stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);

        removeEventListener(Event.ENTER_FRAME, onEnterFrameFadeIn);
        addEventListener(Event.ENTER_FRAME, onEnterFrameFadeOut);
    }

    private function onEnterFrameFadeOut(e:Event):Void {
        alpha -= 0.05;
        if (alpha <= 0.0) {
            alpha = 0.0;
            removeEventListener(Event.ENTER_FRAME, onEnterFrameFadeOut);
            destroy();
            if (onClose != null) onClose();
        }
    }

    public function destroy():Void {
        removeEventListener(Event.ADDED_TO_STAGE, onAddedStage);
        removeEventListener(Event.ENTER_FRAME, onEnterFrameFadeIn);
        removeEventListener(Event.ENTER_FRAME, onEnterFrameFadeOut);

        if (stage != null) {
            stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
            stage.removeEventListener(Event.RESIZE, onWindowResize);
        }

        if (parent != null) parent.removeChild(this);
    }
}