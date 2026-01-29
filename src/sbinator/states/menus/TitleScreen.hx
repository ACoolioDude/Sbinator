package sbinator.states.menus;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import lime.system.System;

class TitleScreen extends StateHandler
{
    var bg:FlxSprite;
    var checker:FlxBackdrop;
    var playButton:FlxSprite;
    var creditsButton:FlxSprite;
    var optionsButton:FlxSprite;
    var exitGameButton:FlxSprite;
    var versionText:FlxText;
    var creatorName:FlxText;
    var gameLogo:FlxSprite;
    var controls:Bool = false;

    override public function create()
    {
        #if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In Title Menu", null);
		#end

		if (FlxG.sound.music == null)
			FlxG.sound.playMusic(Paths.musicPath('mainMenu'));

        bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFFcd5e00);
        bg.scrollFactor.set();
        bg.screenCenter();
        bg.alpha = 0.7;
        add(bg);

        checker = new FlxBackdrop(FlxGridOverlay.createGrid(80, 80, 160, 160, true, FlxColor.BLACK, 0x0));
        checker.velocity.set(28, 28);
        checker.screenCenter();
        checker.alpha = 0.6;
        add(checker);

        playButton = new FlxSprite(190, -150).loadGraphic(Paths.imagePath("mainMenu/play"));
        playButton.scrollFactor.set();
        playButton.scale.set(0.7, 0.7);
        playButton.updateHitbox();
        playButton.screenCenter(X);
        add(playButton);

        optionsButton = new FlxSprite(190, -150).loadGraphic(Paths.imagePath("mainMenu/options"));
        optionsButton.scrollFactor.set();
        optionsButton.scale.set(0.7, 0.7);
        optionsButton.updateHitbox();
        optionsButton.screenCenter(X);
        add(optionsButton);

        creditsButton = new FlxSprite(190, -150).loadGraphic(Paths.imagePath("mainMenu/credits"));
        creditsButton.scrollFactor.set();
        creditsButton.scale.set(0.7, 0.7);
        creditsButton.updateHitbox();
        creditsButton.screenCenter(X);
        add(creditsButton);

        exitGameButton = new FlxSprite(0, -150).loadGraphic(Paths.imagePath("mainMenu/exitGame"));
        exitGameButton.scrollFactor.set();
        exitGameButton.scale.set(0.7, 0.7);
        exitGameButton.updateHitbox();
        exitGameButton.screenCenter(X);
        add(exitGameButton);

        versionText = new FlxText(5, FlxG.height - -28, 0, "Sbinator " + EngineConfiguration.gameVersion + "\n" + FlxG.VERSION, 16);
        versionText.scrollFactor.set();
        versionText.setFormat(Paths.fontPath("bahnschrift.ttf"), 20, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        add(versionText);

        creatorName = new FlxText(1160, FlxG.height - -28, 0, "ACoolioDude", 16);
        creatorName.scrollFactor.set();
        creatorName.setFormat(Paths.fontPath("bahnschrift.ttf"), 20, FlxColor.ORANGE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        add(creatorName);

        gameLogo = new FlxSprite(0, -150).loadGraphic(Paths.imagePath("mainMenu/logo"));
        gameLogo.scrollFactor.set();
        gameLogo.scale.set(0.4, 0.4);
        gameLogo.updateHitbox();
        gameLogo.screenCenter(X);
        add(gameLogo);

        new FlxTimer().start(0.5, function(tmr:FlxTimer) {
            FlxTween.tween(versionText, {y: 670}, 2, {ease: FlxEase.expoInOut});
        });

        new FlxTimer().start(0.7, function(tmr:FlxTimer) {
            FlxTween.tween(creatorName, {y: 690}, 2, {ease: FlxEase.expoInOut});
        });

        new FlxTimer().start(1.1, function(tmr:FlxTimer) {
            FlxTween.tween(playButton, {y: 260}, 2, {ease: FlxEase.expoInOut});
        });

        new FlxTimer().start(1.3, function(tmr:FlxTimer) {
            FlxTween.tween(creditsButton, {y: 360}, 2, {ease: FlxEase.expoInOut});
        });

        new FlxTimer().start(1.5, function(tmr:FlxTimer) {
            FlxTween.tween(optionsButton, {y: 460}, 2, {ease: FlxEase.expoInOut});
        });

        new FlxTimer().start(1.7, function(tmr:FlxTimer) {
            FlxTween.tween(exitGameButton, {y: 560}, 2, {ease: FlxEase.expoInOut});
        });

        new FlxTimer().start(1.9, function(tmr:FlxTimer) {
            FlxTween.tween(gameLogo, {y: 100}, 2, {ease: FlxEase.expoInOut});
        });

        new FlxTimer().start(3, function(tmr:FlxTimer) {
            controls = true;
        });

        super.create();
    }

    override public function update(elapsed:Float)
    {
        if (FlxG.mouse.overlaps(gameLogo) && controls)
        {
            if (FlxG.mouse.justPressed) EngineConfiguration.openWebURL("https://github.com/Stefan2008Git/Sbinator");
        }

        if (FlxG.mouse.overlaps(playButton) && controls)
        {
            if (FlxG.mouse.justPressed)
            {
                StateHandler.switchToNewState(new PlayState());
                trace('Loading the game...');
            }
        }

        if (FlxG.mouse.overlaps(creditsButton) && controls)
        {
            if (FlxG.mouse.justPressed)
            {
                StateHandler.switchToNewState(new CreditsMenu());
            }
        }

        if (FlxG.mouse.overlaps(optionsButton) && controls)
        {
            if (FlxG.mouse.justPressed)
            {
                persistentUpdate = false;
		        persistentDraw = true;
                openSubState(new OptionsMenu());
            }
        }

        if (FlxG.mouse.overlaps(exitGameButton) && controls)
        {
            if (FlxG.mouse.justPressed)
            {
                openSubState(new PopUpEvent("Closing game Confirmation",
				"Are you sure you want to exit the whole game?", [
				{
					text: "Yes",
					callback: function()
					{
						System.exit(1);
					}
				},
                    {
                        text: "No",
                        callback: function()
                        {
                            closeSubState();
                        }
                    }
                ], false, true));
            }
        }

        super.update(elapsed);
    }
}
