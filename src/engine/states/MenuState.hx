package engine.states;

import openfl.media.SoundMixer;
import openfl.ui.Keyboard;
import openfl.events.KeyboardEvent;
import away3d.containers.View3D;
import away3d.primitives.SkyBox;
import away3d.textures.BitmapCubeTexture;
import openfl.events.Event;
import openfl.media.Sound;
import openfl.media.SoundChannel;
import openfl.media.SoundTransform;
import openfl.display.Sprite;
import openfl.utils.Assets;

class MenuState extends Sprite {
    var viewThreeDe:View3D;
    var skybox:SkyBox;

    var jiggle:Sound;
    var soundCh:SoundChannel;
    var soundTrans:SoundTransform;

    var curVolume:Float = 0.0;
    var tarVolume:Float = 1.0;
    var speedFade:Float = 0.01;
    var onMusicPlay:Bool = false;

    public function new () {
        super();

        viewThreeDe = new View3D();
        addChild(viewThreeDe);

        var panoramaBitmaps = new BitmapCubeTexture(
            Assets.getBitmapData("images/menus/backgrounds/panorama_0.png"),
            Assets.getBitmapData("images/menus/backgrounds/panorama_1.png"),
            Assets.getBitmapData("images/menus/backgrounds/panorama_4.png"),
            Assets.getBitmapData("images/menus/backgrounds/panorama_5.png"),
            Assets.getBitmapData("images/menus/backgrounds/panorama_3.png"),
            Assets.getBitmapData("images/menus/backgrounds/panorama_2.png")
        );

        skybox = new SkyBox(panoramaBitmaps);
        viewThreeDe.scene.addChild(skybox);

        viewThreeDe.camera.lens.near = 0.1;
        viewThreeDe.camera.lens.far = 990;
        viewThreeDe.camera.position.setTo(0, 0, 0);

        addEventListener(Event.ADDED_TO_STAGE, onAddedStage);
    }

    public function onGet3DView():View3D {
        return viewThreeDe;
    }

    public function playJiggle():Void {
        soundTrans = new SoundTransform(0.0);
        jiggle = Assets.getMusic("assets/music/jiggle.ogg");
        if (jiggle != null) {
            soundCh = jiggle.play(1, 9999, soundTrans);
            onMusicPlay = true;
        }
    }

    function onAddedStage(e:Event):Void {
        removeEventListener(Event.ADDED_TO_STAGE, onAddedStage);
        stage.addEventListener(Event.RESIZE, onResize);
        stage.addEventListener(Event.ENTER_FRAME, onUpdate);
        stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
        onResize(null);
    }

    function onResize(e:Event):Void {
        if (stage != null && viewThreeDe != null) {
            viewThreeDe.width = stage.stageWidth;
            viewThreeDe.height = stage.stageHeight;
        }
    }

    var enterPress:Bool = false;
    function onKeyDown(e:KeyboardEvent):Void {
        if (e.keyCode == Keyboard.ENTER && !enterPress) {
            e.stopImmediatePropagation();
            enterPress = true;
            onLoadingGame();
        }
    }

    function onUpdate(e:Event):Void {
        if (viewThreeDe == null) return;

        if (onMusicPlay && curVolume < tarVolume && soundCh != null) {
            curVolume += speedFade;
            if (curVolume > tarVolume) curVolume = tarVolume;
            soundTrans.volume = curVolume;
            soundCh.soundTransform = soundTrans;
        }

        viewThreeDe.camera.rotationY += 0.05;
        viewThreeDe.render();
    }

    function onLoadingGame():Void {
        SoundMixer.stopAll();
        if (stage != null) stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
        cleanup();

        var loadState = new LoadingState("dev_stage");

        if (parent != null) {
            parent.addChild(loadState);
            parent.removeChild(this);
        }
    }

    public function cleanup():Void {
        removeEventListener(Event.ENTER_FRAME, onUpdate);
        if (stage != null) {
            stage.removeEventListener(Event.RESIZE, onResize);
            stage.removeEventListener(Event.ENTER_FRAME, onUpdate);
            stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
        }

        if (viewThreeDe != null) {
            if (contains(viewThreeDe)) removeChild(viewThreeDe);

            if (viewThreeDe.scene != null) {
                while (viewThreeDe.scene.numChildren > 0) {
                    viewThreeDe.scene.removeChildAt(0);
                }
            }

            //viewThreeDe.dispose();
            viewThreeDe = null;
        }
    }
}