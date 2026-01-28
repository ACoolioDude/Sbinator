package states.game;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.effects.FlxTrail;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.FlxCollision;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;

class PlayState extends StateHandler
{
    // In-game stuff
    var bg:FlxSprite;
    var bg2:FlxSprite;
    public var player:Player;
    public var playerTrail:FlxTrail;
    var healthTypeGraphic:FlxSprite;
    var icon:FlxSprite;
    var iconY:Float;
    var shaking:Bool = false;
    var shakeIntensity:Int = 5;
    var uiText:FlxText;
    public var score:Int = 0;
    var healthBarSprite:FlxSprite;
    var healthBar:FlxBar;
    var health:Float = 1;
    var maxHealth:Float = 1;

    // Backend
    var levelBound:FlxGroup;
    public var cameraGame:FlxCamera;
    public var gameGroup:FlxSpriteGroup;
    public var cameraUi:FlxCamera;
    public var uiGameGroup:FlxSpriteGroup;
    static public var mainInstance:PlayState;
    var cameraMode:FlxCameraFollowStyle = FlxCameraFollowStyle.TOPDOWN_TIGHT;
    public var cameraFollow:FlxObject;

    override public function create():Void
    {
        // Required for Player class file to call for player trail
        mainInstance = this;

        // Camera related stuff
        cameraGame = new FlxCamera();
        FlxG.cameras.add(cameraGame, false);
        gameGroup = new FlxSpriteGroup();
        add(gameGroup);
        cameraGame.bgColor.alpha = 0;

        // In-game UI related stuff
        cameraUi = new FlxCamera();
        FlxG.cameras.add(cameraUi, false);
        uiGameGroup = new FlxSpriteGroup();
        add(uiGameGroup);
        cameraUi.bgColor.alpha = 0;

        bg = new FlxSprite(Paths.imagePath("game/in-game/world/skybox"));
        bg.screenCenter();
        gameGroup.add(bg);

        bg2 = new FlxSprite(Paths.imagePath("game/in-game/world/grass"));
        bg2.screenCenter(X);
        gameGroup.add(bg2);

        player = new Player(5, 70, 0.8, 0.8);
        player.updateHitbox();
        gameGroup.add(player);

        playerTrail = new FlxTrail(player, 6, 0, 0.4, 0.02);
        playerTrail.visible = false;
        gameGroup.add(playerTrail);

        initInGameUI();

        FlxG.camera.setScrollBoundsRect(1000, 1000, true);
        cameraFollow = new FlxObject(player.x, player.y - 100, 1, 1);
		add(cameraFollow);
		FlxG.camera.follow(cameraFollow, cameraMode);

        // Without this, the player will fall from camera wall, so keeping this for now
        levelBound = FlxCollision.createCameraWall(cameraGame, false, 20);

        gameGroup.cameras = [cameraGame];
        uiGameGroup.cameras = [cameraUi];

        super.create();
    }

    inline public function initInGameUI()
    {
        healthTypeGraphic = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, FlxColor.WHITE);
        healthTypeGraphic.alpha = 0;
        uiGameGroup.add(healthTypeGraphic);

        healthBarSprite = new FlxSprite(0, FlxG.height * 0.9).loadGraphic(Paths.imagePath("game/in-game/health"));
        healthBarSprite.scrollFactor.set();
        healthBarSprite.scale.set(1.2, 1);
        healthBarSprite.updateHitbox();
        healthBarSprite.screenCenter(X);
        uiGameGroup.add(healthBarSprite);

        healthBar = new FlxBar(healthBarSprite.x + 4, healthBarSprite.y + 4, LEFT_TO_RIGHT, Std.int(healthBarSprite.width - 8), Std.int(healthBarSprite.height - 8), this, 'health', 0, maxHealth);
        healthBar.createFilledBar(FlxColor.RED, FlxColor.GREEN);
        healthBar.updateHitbox();
        healthBar.screenCenter(X);
        uiGameGroup.add(healthBar);

        icon = new FlxSprite(0, FlxG.height * 0.9 -45).loadGraphic(Paths.imagePath("game/in-game/icon-stefan"));
        icon.scale.set(0.3, 0.3);
        icon.updateHitbox();
        iconY = icon.y;
        icon.screenCenter(X);
        uiGameGroup.add(icon);

        uiText = new FlxText(0, FlxG.height * 0.95, FlxG.width, "", 12);
        uiText.setFormat(Paths.fontPath("bahnschrift.ttf"), 18, FlxColor.WHITE, FlxTextAlign.CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        uiText.text = "Score: 0 / Health: 100%";
        uiText.borderSize = 2;
        uiText.borderQuality = 2;
        uiText.updateHitbox();
        uiText.screenCenter(X);
        uiGameGroup.add(uiText);
    }

    override public function update(elapsed:Float):Void
    {
        final justPressed = FlxG.keys.justPressed;

		FlxG.collide(player, levelBound);

		if (justPressed.ESCAPE) pauseTheGame();

        if (justPressed.X) damageTaken(0.1) else if (justPressed.P) healthGain(0.1);

		uiText.text = 'Score: ${score} / Health: ${Std.int(health * 100)}%';
		healthBar.value = health;

		if (shaking) {
		    icon.y = 610 + (FlxG.random.float(-shakeIntensity, shakeIntensity));
		} else {
		    icon.y = iconY;
		}

        updateDiscordRPC();

        super.update(elapsed);
    }

    function damageTaken(amount:Float)
    {
        health -= amount;
        if (health <= 0) gameOver();
        score -= 10;

        shaking = true;
        new FlxTimer().start(0.3, function(tmr:FlxTimer) {
            shaking = false;
        });

        healthTypeGraphic.alpha = 0.5;
        healthTypeGraphic.color = FlxColor.RED;
        FlxTween.tween(healthTypeGraphic, {alpha: 0}, 0.2);
        FlxTween.tween(healthBar, {value: health}, 0.3);
    }

    function healthGain(amount:Float)
    {
        health = Math.min(health + amount, maxHealth);
        if (health >= maxHealth) return;
        shaking = false;
        score += 10;

        healthTypeGraphic.alpha = 0.5;
        healthTypeGraphic.color = FlxColor.LIME;
        FlxTween.tween(healthTypeGraphic, {alpha: 0}, 0.2);
        FlxTween.tween(healthBar, {value: health}, 0.3);
    }

    function pauseTheGame()
    {
        FlxG.camera.followLerp = 0;
		persistentUpdate = false;
		persistentDraw = true;

        openSubState(new PauseMenu());
    }

    function gameOver()
    {
        FlxG.camera.followLerp = 0;
        persistentUpdate = false;
		persistentDraw = true;
        score = 0;

        openSubState(new GameOver());
    }

    #if DISCORD_ALLOWED
    function updateDiscordRPC()
    {
        if (score == 0) DiscordClient.changePresence("In Game", null) else DiscordClient.changePresence("In Game. Current earned score: " + score, null);
    }
    #end
}
