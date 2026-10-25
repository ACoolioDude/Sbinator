package engine.states;

import away3d.cameras.lenses.PerspectiveLens;
import haxe.Timer;
import openfl.Lib;
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
import openfl.utils.Assets;

class MenuState extends SBState {
    var viewThreeDe:View3D;
    var skybox:SkyBox;
    var overlay:MenuOverlay;

    var overlayFading:Bool = false;
    var overlayFadeSpeed:Float = 0.03;

    var soundCh:SoundChannel;
    var soundTrans:SoundTransform;

    var curVolume:Float = 0.0;
    var tarVolume:Float = 1.0;
    var speedFade:Float = 0.01;
    var onMusicPlay:Bool = false;

    static inline var MUSIC_GAP:Float = 60;
    static var playlist:Array<String> = [
        "music/jiggle.ogg",
        "music/atlantis.ogg",
        "music/extras-menu.ogg",
        "music/innocence.ogg",
        "music/regular-show.ogg"
    ];
    static var trackIndex:Int = 0;
    static var nextPlayAt:Float = 0;

    public function new() {
        super();
        addEventListener(Event.ADDED_TO_STAGE, onAddedStage);
    }

    function onAddedStage(e:Event):Void {
        removeEventListener(Event.ADDED_TO_STAGE, onAddedStage);

        viewThreeDe = new View3D();
        addChild(viewThreeDe);

        if (stage != null) {
            viewThreeDe.width = stage.stageWidth;
            viewThreeDe.height = stage.stageHeight;
        }

        var panoramaBitmaps = new BitmapCubeTexture(
            ResourceLoader.bitmapData("images/menus/backgrounds/panorama_0.png"),
            ResourceLoader.bitmapData("images/menus/backgrounds/panorama_2.png"),
            ResourceLoader.bitmapData("images/menus/backgrounds/panorama_5.png"),
            ResourceLoader.bitmapData("images/menus/backgrounds/panorama_4.png"),
            ResourceLoader.bitmapData("images/menus/backgrounds/panorama_3.png"),
            ResourceLoader.bitmapData("images/menus/backgrounds/panorama_1.png")
        );

        skybox = new SkyBox(panoramaBitmaps);
        viewThreeDe.scene.addChild(skybox);

        viewThreeDe.camera.lens.near = 0.1;
        viewThreeDe.camera.lens.far = 990;
        var lens = cast(viewThreeDe.camera.lens, PerspectiveLens);
        if (lens != null) lens.fieldOfView = Options.skyboxFov;
        viewThreeDe.camera.position.setTo(0, 0, 0);

        overlay = new MenuOverlay();
        overlay.alpha = 0.0;
        overlay.onOptionSelection = onMenuHandling;

        startOverlay();

        stage.addEventListener(Event.RESIZE, onResize);
        stage.addEventListener(Event.ENTER_FRAME, onUpdate);
    }

    public function startOverlay():Void {
        if (overlay != null) {
            if (stage != null && !stage.contains(overlay)) {
                stage.addChild(overlay);

                if (Main.stateMng != null && Main.stateMng.debug != null) {
                    stage.setChildIndex(Main.stateMng.debug, stage.numChildren - 1);
                }
            }

            overlay.alpha = 0.0;
            overlayFading = true;

            overlay.onOverlayShowing();
        }
    }

    public function onGet3DView():View3D {
        return viewThreeDe;
    }

    function playNextTrack():Void {
        var id = ResourceLoader.resolveId(playlist[trackIndex]);
        var snd:Sound = (id != null) ? Assets.getMusic(id) : null;
        if (snd == null) {
            scheduleNext();
            return;
        }

        curVolume = 0.0;
        soundTrans = new SoundTransform(0.0);
        soundCh = snd.play(0, 0, soundTrans);

        if (soundCh == null) {
            scheduleNext();
            return;
        }

        soundCh.addEventListener(Event.SOUND_COMPLETE, onTrackComplete);
        onMusicPlay = true;
    }

    function onTrackComplete(e:Event):Void {
        stopMusic();
    }

    function scheduleNext():Void {
        trackIndex = (trackIndex + 1) % playlist.length;
        nextPlayAt = Timer.stamp() + MUSIC_GAP;
    }

    function stopMusic():Void {
        if (soundCh != null) {
            soundCh.removeEventListener(Event.SOUND_COMPLETE, onTrackComplete);
            soundCh.stop();
            soundCh = null;
        }
        if (onMusicPlay) {
            onMusicPlay = false;
            scheduleNext();
        }
    }

    private function onMenuHandling(choice:String):Void {
        switch (choice) {
            case "NEW MAP": onLevelSelection();
            case "LOAD MAP": onLoadingGame();
            case "CREDITS": onCreditsMenu();
            case "OPTIONS": onOptionsMenu();
            case "EXIT GAME": onExitGame();
            case _: trace('Option selected -> ${choice}');
        }
    }

    function onResize(e:Event):Void {
        if (stage != null && viewThreeDe != null) {
            viewThreeDe.width = stage.stageWidth;
            viewThreeDe.height = stage.stageHeight;
        }
    }

    function onUpdate(e:Event):Void {
        if (viewThreeDe == null) return;

        if (!onMusicPlay && Timer.stamp() >= nextPlayAt) playNextTrack();

        if (onMusicPlay && curVolume < tarVolume && soundCh != null) {
            curVolume += speedFade;
            if (curVolume > tarVolume) curVolume = tarVolume;
            soundTrans.volume = curVolume;
            soundCh.soundTransform = soundTrans;
        }

        if (overlayFading && overlay != null) {
            overlay.alpha += overlayFadeSpeed;
            if (overlay.alpha >= 1.0) {
                overlay.alpha = 1.0;
                overlayFading = false;
            }
        }

        viewThreeDe.camera.rotationY += 0.05;
        viewThreeDe.render();
    }

    function onLevelSelection():Void {
        var levelSelection = new LevelSelectionOverlay(this);
        levelSelection.onClose = function() {
            levelSelection.destroy();
        }
        
        if (stage != null && !stage.contains(levelSelection)) {
            stage.addChild(levelSelection);

            if (Main.stateMng != null && Main.stateMng.debug != null) {
                stage.setChildIndex(Main.stateMng.debug, stage.numChildren - 1);
            }
        }
    }

    function onLoadingGame():Void {
        cleanup();

        Timer.delay(function() {
            if (Main.stateMng != null) {
                Main.stateMng.switchState(new LoadingState("dev_stage"));
            } else {
                SBState.switchState(new LoadingState("dev_stage"));
            }
        }, 700);
    }

    function onCreditsMenu():Void {
        var credits = new CreditsOverlay(this);
        credits.onClose = function() {
            credits.destroy();
        }
        
        if (stage != null && !stage.contains(credits)) {
            stage.addChild(credits);

            if (Main.stateMng != null && Main.stateMng.debug != null) {
                stage.setChildIndex(Main.stateMng.debug, stage.numChildren - 1);
            }
        }
    }

    function onOptionsMenu():Void {
        var options = new OptionsOverlay(this);
        options.onClose = function() {
            options.destroy();
        }
        
        if (stage != null && !stage.contains(options)) {
            stage.addChild(options);

            if (Main.stateMng != null && Main.stateMng.debug != null) {
                stage.setChildIndex(Main.stateMng.debug, stage.numChildren - 1);
            }
        }
    }

    function onExitGame():Void {
        var popup = new PopupOverlay(
            "QUIT SBINATOR",
            "Do you want to end game session?",
            function () {
                cleanup();
                haxe.Timer.delay(function(){
                    Sys.exit(0);
                }, 1000);
            }
        );

        if (stage != null && !stage.contains(popup)) {
            stage.addChild(popup);

            if (Main.stateMng != null && Main.stateMng.debug != null) {
                stage.setChildIndex(Main.stateMng.debug, stage.numChildren - 1);
            }
        }
    }

    override public function cleanup():Void {
        super.cleanup();

        stopMusic();

        if (stage != null) {
            stage.removeEventListener(Event.RESIZE, onResize);
            stage.removeEventListener(Event.ENTER_FRAME, onUpdate);
        }

        if (viewThreeDe != null) {
            if (contains(viewThreeDe)) removeChild(viewThreeDe);

            if (viewThreeDe.scene != null) {
                while (viewThreeDe.scene.numChildren > 0) {
                    viewThreeDe.scene.removeChildAt(0);
                }
            }
            viewThreeDe = null;
        }

        if (overlay != null) {
            if (overlay.parent != null) {
                overlay.parent.removeChild(overlay);
            }
            overlay.destroy();
            overlay = null;
        }
    }
}
