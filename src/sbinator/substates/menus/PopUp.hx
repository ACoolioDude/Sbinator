// Credits for CoreCat of pop up event code

package sbinator.substates.menus;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.addons.effects.chainable.FlxEffectSprite;
import flixel.addons.effects.chainable.FlxOutlineEffect;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;

typedef PopUpButton = {
    var text:String;
    var callback:Void->Void;
    @:optional var defaultOption:Bool;
}
class PopUpEvent extends FlxSubState
{
	var box:FlxSprite;
	var exitButt:FlxSprite;
    var bgBlack:FlxSprite;

    var titleS:FlxSprite;
	var iconS:FlxSprite;
	var titleTextS:FlxText;

    var buttons:Array<PopUpButton> = [];
    var titleT:String = "";
    var bodyT:String = "";

    var _hideBG:Bool = false;
    var _hideCloseButton:Bool = false;
    var lastMouseWasVisible:Bool = false;
	public function new(title:String, body:String, buttons:Array<PopUpButton>, ?hideBG:Bool = false,?hideCloseButton:Bool = false)
	{
		super();
        lastMouseWasVisible = FlxG.mouse.visible;
        FlxG.mouse.visible = true;//nu
        this.buttons = buttons;
        titleT = title;
        bodyT = body;
        _hideBG = hideBG;
        _hideCloseButton = hideCloseButton;
        if (!hideBG){
            bgBlack = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
            bgBlack.alpha = 0.5;
            add(bgBlack);
            bgBlack.scrollFactor.set();
        }

		var tempbodyText = new FlxText(0,0, -1, bodyT, 18);
		tempbodyText.font = Paths.fontPath("bahnschrift.ttf");
        @:privateAccess tempbodyText.regenGraphic();
        tempbodyText.drawFrame(true);
        tempbodyText.fieldWidth = FlxMath.bound(tempbodyText.fieldWidth,0,780);
        tempbodyText.scrollFactor.set();

        var wee:Int = Std.int(tempbodyText.width +70);
        var hee:Int = Std.int(70 + tempbodyText.height+ 50);
		box = FlxSpriteUtil.drawRoundRect(new FlxSprite().makeGraphic(wee,hee, FlxColor.TRANSPARENT), 0, 0, wee,  hee, 15, 15, FlxColor.BLACK);
		box.screenCenter();
        box.scrollFactor.set();
		box.alpha = 0;

        var newEffect = FlxSpriteUtil.drawRoundRect(new FlxSprite().makeGraphic(wee+4,hee+4, FlxColor.TRANSPARENT), 0, 0, wee+4, hee+4, 15, 15, 0xFF5C0000);
        newEffect.setPosition(box.x-2,box.y-2);
        newEffect.antialiasing = FlxG.save.data.antialiasing;
        newEffect.alpha = 0;
        add(newEffect);
        newEffect.scrollFactor.set();
        add(box);

        createBoxUI();

        if (!hideBG){
            bgBlack.alpha = 0;
            FlxTween.tween(bgBlack, {alpha: 0.5},0.15,{ease: FlxEase.linear});
        }

        if (!hideCloseButton){
            exitButt = new FlxSprite().makeGraphic(30, 20, FlxColor.RED);
            exitButt.alpha = 0.7;
            exitButt.x = ((box.x + box.width) - 30) - 10;
            exitButt.y = box.y+9;
            add(exitButt);
            exitButt.scrollFactor.set();
        }

        FlxTween.tween(box, {alpha: 1},0.15,{ease: FlxEase.linear});
		FlxTween.tween(newEffect, {alpha: 0.2},0.15,{ease: FlxEase.linear});
        if (!hideCloseButton){
            exitButt.alpha = 0;
            FlxTween.tween(exitButt, {alpha: 0.7},0.15,{ease: FlxEase.linear});
        }
	}

    var bodyText:FlxText;
    var buttonsCrap:Array<PopUpButtons> = [];
	function createBoxUI()
	{
        titleS = FlxSpriteUtil.drawRoundRectComplex(new FlxSprite().makeGraphic(Std.int(box.width), 32, FlxColor.TRANSPARENT), 0, 0, Std.int(box.width), 32, 5,
            5, 0, 0, 0xFFcd5e00);
        titleS.setPosition(box.x, box.y);
        titleS.alpha = 0.9;
        add(titleS);

        iconS = new FlxSprite().loadGraphic(Paths.imagePath("game/info"));
        iconS.setPosition(titleS.x + 9, titleS.y + 9);
        add(iconS);

        titleTextS = new FlxText(iconS.x + iconS.width + 8, 0, -1, titleT, 14);
        titleTextS.setFormat(Paths.fontPath("bahnschrift.ttf"), 14, FlxColor.WHITE);
        titleTextS.y = iconS.y + ((iconS.width / 2) - (titleTextS.height / 2));
        add(titleTextS);

        titleS.scrollFactor.set();
        iconS.scrollFactor.set();
        titleTextS.scrollFactor.set();

		bodyText = new FlxText(box.x+30, box.y + 50, -1, bodyT, 18);
		bodyText.font = Paths.fontPath("bahnschrift.ttf");
        bodyText.fieldWidth = FlxMath.bound(bodyText.fieldWidth,0,780);
		add(bodyText);
        bodyText.scrollFactor.set();

        for (i in 0...buttons.length){
            var button:PopUpButtons = new PopUpButtons(0,0,buttons[i].text, buttons[i].callback);
            button.x = box.x + 20 + (button.bWidth * i);
            button.y = (box.y - button.bHeight) - 20;
            add(button);
            button.scrollFactor.set();
            buttonsCrap.push(button);
        }

        for (i in 0...buttonsCrap.length){
            var oldButtWidth = (buttonsCrap[i-1] == null ? 0 : buttonsCrap[i-1].bWidth);
            buttonsCrap[i].x = box.x + ((box.width-(buttonsCrap[i].bWidth + (oldButtWidth + 20))));
            buttonsCrap[i].y = (box.y+box.height - buttonsCrap[i].bHeight) - 20;
        }
        FlxTween.tween(titleS, {alpha: 0.9},0.15,{ease: FlxEase.linear});
        for (tw in [iconS, titleTextS, bodyText]){
            tw.alpha = 0;
            FlxTween.tween(tw, {alpha:1}, 0.15, {ease: FlxEase.linear});
        }
	}

	override function update(elapsed:Float) {

        if (!_hideCloseButton){
            if (FlxG.mouse.overlaps(exitButt))
                {
                    exitButt.alpha = 1;
                    if (FlxG.mouse.justPressed)
                        close();
                }
                else
                {
                    exitButt.alpha = 0.7;
                }

        }
		super.update(elapsed);
	}

    public static function open(cur:FlxState, title:String, body:String, buttons:Array<PopUpButton>, ?hideBG:Bool = false,?hideCloseButton:Bool = false){
        cur.openSubState(new PopUpEvent(title, body, buttons, hideBG, hideCloseButton));
    }
}

class PopUpButtons extends FlxSpriteGroup {
    var buttBG:FlxSprite;
    var txt:FlxText;

    var callb:Void->Void;
    public var bWidth:Int = 150;
    public var bHeight:Int = 32;
    public function new(x:Float,y:Float,text:String, callback:Void->Void){
        super(x,y);
        this.callb = callback;
        buttBG = new FlxSprite().makeGraphic(150, 32, FlxColor.fromRGB(70, 70, 70));
		add(buttBG);

		txt = new FlxText(20,20, 0, text, 18);
		txt.font = Paths.fontPath("bahnschrift.ttf");
		txt.alignment = CENTER;
		add(txt);
        buttBG.setGraphicSize(Std.int(txt.width+20), Std.int(txt.height+12));
        bWidth = Std.int(buttBG.width);
        bHeight = Std.int(buttBG.height);

        EngineConfiguration.moveSpritesToCenter(txt, buttBG);
        txt.scrollFactor.set();
        buttBG.scrollFactor.set();
    }

    override function update(elapsed:Float){
        super.update(elapsed);
        if (FlxG.mouse.overlaps(this))
        {
            this.alpha = 1;

            if (FlxG.mouse.justPressed){
                callb();
            }
		}
		else
		{
            this.alpha = 0.7;
       }
    }
}
