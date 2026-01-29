package sbinator.substates.game;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;

class GameOver extends SubstateHandler
{
    var bg:FlxSprite;
    var controlsEnabler:Bool = false;

    override function create()
    {
        bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
        bg.alpha = 0.7;
        add(bg);

        new FlxTimer().start(0.85, function(timer:FlxTimer)
        {
            FlxTween.angle(PlayState.mainInstance.player, 0, 100, 1, {ease: FlxEase.expoInOut});
        });

        new FlxTimer().start(1.6, function(timer:FlxTimer) {
            PlayState.mainInstance.player.kill();
        });

        new FlxTimer().start(2, function(timer:FlxTimer)
        {
            controlsEnabler = true;
        });

        // This is required to substate works when i added both in-game cameras, so Flixel needs to have something to handle it
        cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];

        super.create();
    }

    override function update(elapsed:Float)
    {
        if (FlxG.keys.justPressed.ENTER || FlxG.keys.justPressed.SPACE && controlsEnabler) FlxG.resetState();
        if (FlxG.keys.justPressed.ESCAPE && controlsEnabler) StateHandler.switchToNewState(new TitleScreen());

        super.update(elapsed);
    }
}
