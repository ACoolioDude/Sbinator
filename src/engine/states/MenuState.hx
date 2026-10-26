package engine.states;

import haxe.Timer;
import openfl.Lib;
import openfl.display.StageAlign;
import openfl.display.StageScaleMode;
import openfl.display.BitmapData;
import openfl.display.Bitmap;
import openfl.events.KeyboardEvent;
import openfl.events.Event;
import openfl.media.Sound;
import openfl.media.SoundChannel;
import openfl.media.SoundMixer;
import openfl.media.SoundTransform;
import openfl.ui.Keyboard;
import openfl.utils.Assets;

class MenuState extends SBState {
    var background:Bitmap;
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

        var bitmapData = ResourceLoader.bitmapData("images/menus/backgrounds/menu_1.png");
        background = new Bitmap(bitmapData);
        addChild(background);

        overlay = new MenuOverlay();
        overlay.alpha = 0.0;
        overlay.onOptionSelection = onMenuHandling;

        startOverlay();
        layout();

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

    function layout():Void {
        if (stage == null) return;

        stage.scaleMode = StageScaleMode.NO_SCALE;
        stage.align = StageAlign.TOP_LEFT;

        var w:Float = stage.stageWidth;
        var h:Float = stage.stageHeight;

        if (background != null && background.bitmapData != null) {
            background.width = w;
            background.height = h;
        }
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

    function onResize(e:Event):Void layout();
    
    function onUpdate(e:Event):Void {
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

        if (overlay != null) {
            if (overlay.parent != null) {
                overlay.parent.removeChild(overlay);
            }
            overlay.destroy();
            overlay = null;
        }
    }
}
