package data;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.tweens.FlxTween;

class Player extends FlxSprite
{
    final speedValue:Int = 180;
    final gravityValue:Int = 280;
    final jumpHeight:Int = 180;

    public function new (xPosition:Int = 0, yPosition:Int = 0, scaleX:Float = 0, scaleY:Float = 0)
    {
        super(xPosition, yPosition, Paths.imagePath("game/in-game/stefan"));
        // frames = FlxAtlasFrames.fromSparrow("assets/images/game/in-game/stefan.png", "assets/images/game/in-game/stefan.xml");

        drag.x = speedValue + 8;

        acceleration.y = gravityValue;

        this.scale.x = scaleX;
        this.scale.y = scaleY;

        // animation.addByPrefix('mainIdle', "idle", 25, false);
        // animation.addByPrefix('mainWalking', "walking", 25, false);

        // animation.play('mainIdle');
    }

    override function update(elapsed:Float)
    {
        playerMovement();
        FlxG.collide(this, PlayState.mainInstance.bg2);
        super.update(elapsed);
    }

    public function playerMovement()
    {
        final left = FlxG.keys.pressed.LEFT || FlxG.keys.pressed.A;
        final right = FlxG.keys.pressed.RIGHT || FlxG.keys.pressed.D;
        final shift = FlxG.keys.pressed.SHIFT;
        final space = FlxG.keys.pressed.SPACE;

        // Walking function
        if (left && right)
        {
            PlayState.mainInstance.playerTrail.visible = false;
            velocity.x = 0;
            // animation.play("mainIdle");
        }
        else if (left)
        {
            PlayState.mainInstance.playerTrail.visible = false;
            velocity.x = -speedValue / 1.7;
            facing = RIGHT;
            setFacingFlip(RIGHT, false, false);
            // animation.play("mainWalking");
        }
        else if (right)
        {
            PlayState.mainInstance.playerTrail.visible = false;
            velocity.x = speedValue / 1.7;
            facing = LEFT;
            setFacingFlip(LEFT, true, false);
            // animation.play("mainWalking");
        }

        // Sprinting function
        if (shift && left && right)
        {
            velocity.x = 0;
            PlayState.mainInstance.playerTrail.visible = false;
            // animation.play("mainIdle");
        }
        else if (shift && left)
        {
            velocity.x = -speedValue;
            facing = RIGHT;
            setFacingFlip(LEFT, false, false);
            PlayState.mainInstance.playerTrail.visible = true;
            // animation.play("mainWalking");
        }
        else if (shift && right)
        {
            velocity.x = speedValue;
            facing = LEFT;
            setFacingFlip(RIGHT, true, false);
            PlayState.mainInstance.playerTrail.visible = true;
            // animation.play("mainWalking");
        }

        // Jumping function
        if (space && touching == DOWN)
		{
            velocity.y = -jumpHeight;
            // FlxTween.tween(PlayState.mainInstance.gameGroup, {y: FlxG.camera.scroll.y - 50}, 0.2, {type: PINGPONG}); Maybe we should disable this for now. --ACoolioDude (Stefan)
            FlxG.sound.play("assets/sounds/jump.ogg");
            PlayState.mainInstance.score += 10;
        }
    }
}
