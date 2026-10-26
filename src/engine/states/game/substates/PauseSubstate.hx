package engine.states.game.substates;

import openfl.display.Sprite;
import openfl.events.Event;
import openfl.media.SoundTransform;
import openfl.media.SoundMixer;

class PauseSubstate extends SBSubState {
    private var bg:Sprite;
    private var menu:MenuOverlay;

    private var options:OptionsOverlay;
    private var popup:PopupOverlay;

    public var onResume:Void -> Void;

    public function new() {
        super();

        bg = new Sprite();
        addChild(bg);

        menu = new MenuOverlay(MenuOverlay.PAUSE_ITEMS, "S B I N A T O R");
        menu.fadeSpeed = 0.12;
        menu.onOptionSelection = onMenuChoice;
        addChild(menu);

        addEventListener(Event.ADDED_TO_STAGE, setupPause);
    }

    private function setupPause(e:Event):Void {
        removeEventListener(Event.ADDED_TO_STAGE, setupPause);

        layout();
        menu.onOverlayShowing();
    }

    public function handleEscape():Bool {
        if (popup != null) {
            closePopup();
            return true;
        }
        if (options != null) {
            closeOptions();
            return true;
        }
        return false;
    }

    private function onMenuChoice(choice:String):Void {
        switch (choice) {
            case "RESUME":
                resume();
            case "RESTART":
                openConfirm("RESTART", "Restart map?", restart);
            case "OPTIONS":
                openOptions();
            case "QUIT TO MENU":
                openConfirm("QUIT TO MENU", "Leave this map and return to the main menu?", quitToMenu);
            case "EXIT GAME":
                openConfirm("QUIT SBINATOR", "Do you want to end game session?", function() Sys.exit(0));
            case _:
                trace('Pause option selected -> ${choice}');
        }
    }

    private function resume():Void {
        if (onResume != null) onResume() else close();
    }

    private function restart():Void {
        if (Main.stateMng != null) {
            Main.stateMng.switchState(new LoadingState());
        } else {
            SBState.switchState(new LoadingState());
        }
    }

    private function quitToMenu():Void {
        if (Main.stateMng != null) {
            Main.stateMng.switchState(new MenuState());
            SoundMixer.soundTransform = new SoundTransform(1);
        } else {
            SBState.switchState(new MenuState());
            SoundMixer.soundTransform = new SoundTransform(1);
        }
    }

    private function openOptions():Void {
        if (options != null || popup != null) return;

        var opts = new OptionsOverlay(null);
        opts.onClose = function() {
            if (options == opts) options = null;
            opts.destroy();
        }

        options = opts;
        showOnTop(opts);
    }

    private function closeOptions():Void {
        if (options == null) return;

        var opts = options;
        options = null;
        opts.destroy();
    }

    private function openConfirm(title:String, message:String, onConfirm:Void -> Void):Void {
        if (options != null || popup != null) return;

        var pop = new PopupOverlay(title, message, function() {
            popup = null;
            onConfirm();
        }, function() {
            popup = null;
        });

        popup = pop;
        showOnTop(pop);
    }

    private function closePopup():Void {
        if (popup == null) return;

        var pop = popup;
        popup = null;
        pop.close();
        if (pop.parent != null) pop.parent.removeChild(pop);
    }

    private function showOnTop(overlay:Sprite):Void {
        if (stage == null) return;

        stage.addChild(overlay);

        if (Main.stateMng != null && Main.stateMng.debug != null) {
            stage.setChildIndex(Main.stateMng.debug, stage.numChildren - 1);
        }
    }

    private function layout():Void {
        if (stage == null) return;

        bg.graphics.clear();
        bg.graphics.beginFill(0x000000, 0.5);
        bg.graphics.drawRect(0, 0, stage.stageWidth, stage.stageHeight);
        bg.graphics.endFill();
    }

    override function onResize(e:Event) {
        layout();
    }

    override function close():Void {
        closePopup();
        closeOptions();

        if (menu != null) {
            menu.destroy();
            menu = null;
        }

        super.close();
    }
}
