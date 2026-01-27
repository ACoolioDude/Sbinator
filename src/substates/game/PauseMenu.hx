package substates.game;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;

class PauseMenu extends SubstateHandler
{
    var bg:FlxSprite;
    var checker:FlxBackdrop;
    var bg2:FlxSprite;
    var resumeButton:FlxSprite;
    var resetButton:FlxSprite;
    var exitButton:FlxSprite;
    var confirmed:Bool = false;

    override public function create()
    {
        #if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In Pause Menu", null);
		#end

        bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
        bg.alpha = 0;
        add(bg);

        checker = new FlxBackdrop(FlxGridOverlay.createGrid(80, 80, 160, 160, true, FlxColor.GRAY, 0x0));
        checker.velocity.set(15, 15);
        checker.screenCenter();
        checker.alpha = 0;
        add(checker);

        bg2 = new FlxSprite(720, -800).makeGraphic(FlxG.width - 720, FlxG.height, FlxColor.BLACK);
		bg2.alpha = 0.25;
		add(bg2);

		resumeButton = new FlxSprite().loadGraphic(Paths.imagePath("pauseMenu/resume"));
        resumeButton.scrollFactor.set();
        resumeButton.x = 190;
        resumeButton.y = -150;
        resumeButton.scale.set(0.7, 0.7);
        resumeButton.updateHitbox();
        add(resumeButton);

        resetButton = new FlxSprite().loadGraphic(Paths.imagePath("pauseMenu/reset"));
        resetButton.scrollFactor.set();
        resetButton.x = 190;
        resetButton.y = -150;
        resetButton.scale.set(0.7, 0.7);
        resetButton.updateHitbox();
        add(resetButton);

        exitButton = new FlxSprite().loadGraphic(Paths.imagePath("pauseMenu/exit"));
        exitButton.scrollFactor.set();
        exitButton.x = 190;
        exitButton.y = -150;
        exitButton.scale.set(0.7, 0.7);
        exitButton.updateHitbox();
        add(exitButton);

		new FlxTimer().start(0.6, function(tmr:FlxTimer) {
            FlxTween.tween(bg, {alpha: 0.6}, 0.7, {ease: FlxEase.quartInOut});
        });

        new FlxTimer().start(0.6, function(tmr:FlxTimer) {
            FlxTween.tween(checker, {alpha: 0.6}, 0.7, {ease: FlxEase.quartInOut});
        });

        new FlxTimer().start(0.7, function(tmr:FlxTimer) {
            checker.velocity.set(28, 28);
        });

		new FlxTimer().start(0.85, function(tmr:FlxTimer) {
            FlxTween.tween(bg2, {y: -3}, 2, {ease: FlxEase.expoInOut});
        });

        new FlxTimer().start(0.95, function(tmr:FlxTimer) {
            FlxTween.tween(resumeButton, {y: 300}, 2, {ease: FlxEase.expoInOut});
        });

        new FlxTimer().start(1.2, function(tmr:FlxTimer) {
            FlxTween.tween(resetButton, {y: 400}, 2, {ease: FlxEase.expoInOut});
        });

        new FlxTimer().start(1.4, function(tmr:FlxTimer) {
            FlxTween.tween(exitButton, {y: 500}, 2, {ease: FlxEase.expoInOut});
        });

        new FlxTimer().start(1.6, function(tmr:FlxTimer) {
            confirmed = true;
        });

        // This is required to substate works when i added both in-game cameras, so Flixel needs to have something to handle it
        cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];

        super.create();
    }

    override function update(elapsed:Float)
    {
        if (FlxG.mouse.overlaps(resumeButton, PlayState.mainInstance.uiGameGroup.camera) && confirmed)
        {
            if (FlxG.mouse.justPressed) close();
        }
        else if (FlxG.keys.justPressed.ESCAPE)
        {
            close();
        }

        if (FlxG.mouse.overlaps(resetButton, PlayState.mainInstance.uiGameGroup.camera) && confirmed)
        {
            if (FlxG.mouse.justPressed) FlxG.resetState();
        }

        if (FlxG.mouse.overlaps(exitButton, PlayState.mainInstance.uiGameGroup.camera) && confirmed)
        {
            if (FlxG.mouse.justPressed) StateHandler.switchToNewState(new TitleScreen());
        }

        super.update(elapsed);
    }
}
