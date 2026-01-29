// A main game state handler with transition included, so free to edit this if you want to improve my class file :D

package sbinator.backend.transition;

import flixel.FlxG;
import flixel.FlxState;
import flixel.addons.ui.FlxUIState;
import flixel.util.typeLimit.NextState;

class StateHandler extends FlxUIState
{
    override public function create()
    {
        super.create();

        openSubState(new Transition(true));
    }

    public static var activeState:FlxState;
    public static function switchToNewState(?target:NextState):Void
    {
        var trans = new Transition(false);

        trans.callbackFinished = function()
        {
            if(target != null) FlxG.switchState(target); else FlxG.resetState();
        };

        if (activeState != null) activeState.openSubState(trans);
    }

    public function beatTheHit():Void
    {
        // Just a base beat hitter
    }
}
