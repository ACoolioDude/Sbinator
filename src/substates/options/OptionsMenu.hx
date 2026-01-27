package substates.options;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;
import flixel.text.FlxText;
import flixel.util.FlxColor;

class OptionsMenu extends SubstateHandler
{
    var bg:FlxSprite;
    var checker:FlxBackdrop;

    // Text
    var text:FlxText;
    var textSine:Float = 0;

    override function create()
    {
        #if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In Options Menu", null);
		#end

        bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0.5;
		add(bg);

        text = new FlxText(0, 0, "UNFINISHED (W.I.P)!", 16);
        text.scrollFactor.set();
        text.setFormat(Paths.fontPath("bahnschrift.ttf"), 30, FlxColor.RED, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        text.screenCenter();
        add(text);

        super.create();
    }

    override function update(elapsed:Float)
    {
        // Sine text
        textSine += 180 * elapsed;
        text.alpha = 1 - Math.sin((Math.PI * textSine) / 180);

        if (FlxG.keys.justPressed.ESCAPE) close();

        super.update(elapsed);
    }
}
