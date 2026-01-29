package sbinator.backend.transition;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

class Transition extends FlxSubState
{
    var fadeOut:Bool = false;
    public var callbackFinished:Void -> Void;
    var switcherBg:FlxSprite;

    public function new(fadeOut:Bool = true)
    {
        super();
        this.fadeOut = fadeOut;

        switcherBg = new FlxSprite().makeGraphic(FlxG.width * 2, FlxG.height * 2, 0xFF000000);
		switcherBg.screenCenter();
		add(switcherBg);

		switcherBg.alpha = (fadeOut ? 1 : 0);
		FlxTween.tween(switcherBg, {alpha: fadeOut ? 0 : 1}, 0.32, {ease: FlxEase.sineIn,
		onComplete: function(twn:FlxTween)
			{
				endTransition();
			}
		});
    }

    function endTransition()
    {
        if(callbackFinished != null) callbackFinished(); else close();
    }
}
