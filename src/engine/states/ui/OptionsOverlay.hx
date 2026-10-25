package engine.states.ui;

import openfl.Lib;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;

class OptionsOverlay extends SBSubState {
    private static inline var BASE_W:Float = 1280;
    private static inline var BASE_H:Float = 720;

    private var targetState:Dynamic;

    private var uiScale:Float = 1.0;
    private var currentCategory:String = "Video";

    // UI elements
    private var background:Sprite;
    private var panelUI:Sprite;
    private var title:TextField;
    private var tabBar:Sprite;
    private var contentArea:Sprite;
    private var applyButt:Sprite;
    private var applyTitle:TextField;
    private var closeButt:Sprite;
    private var closeTitle:TextField;

    private var buttW:Float = 80;
    private var buttH:Float = 30;

    // Options
    private var fpsIndex:Int = 1;
    private var fpsNum:Array<Int> = [30, 60, 120, 144, 160, 180, 200, 220, 240];
    private var fpsText:TextField;

    private var skyboxFovTxt:TextField;
    private var skyboxFovValue:TextField;
    
    private var initFps:Int;
    private var initSkyboxSpeed:Float;
    private var initSkyboxFov:Int;

    private var tempFpsIndex:Int;
    private var tempFov:Int;
    private var tempSkyboxSpeed:Float;

    private var initIntroVideo:Bool;
    private var tempIntroVideo:Bool;
    private var introVideoText:TextField;

    private var isChanged:Bool = false;
    public var onClose:Void -> Void;

    public function new(newTarget:Dynamic) {
        super();
        this.targetState = newTarget;

        alpha = 0;
        addEventListener(Event.ADDED_TO_STAGE, onAddedStage);
    }

    override public function onAddedStage(e:Event):Void {
        removeEventListener(Event.ADDED_TO_STAGE, onAddedStage);
        Lib.current.stage.addEventListener(Event.RESIZE, onWindowResize);
        addEventListener(Event.ENTER_FRAME, onEnterFrameFadeIn);

        initUI();
        layoutUI();

        if (parent != null) parent.setChildIndex(this, parent.numChildren - 1);
    }

    private function onEnterFrameFadeIn(e:Event):Void {
        alpha += 0.15;
        if (alpha >= 1.0) {
            alpha = 1.0;
            removeEventListener(Event.ENTER_FRAME, onEnterFrameFadeIn);
        }
    }

    private function px(base:Float):Int {
        return Std.int(Math.max(1, Math.round(base * uiScale)));
    }

    private function setFontSize(tf:TextField, size:Int):Void {
        var fmt:TextFormat = tf.defaultTextFormat;
        fmt.size = size;
        tf.defaultTextFormat = fmt;
        tf.setTextFormat(new TextFormat(null, size));
    }

    private function initUI():Void {
        fpsIndex = 0;
        for (i in 0...fpsNum.length) {
            if (fpsNum[i] == Options.fps) {
                fpsIndex = i;
                break;
            }
        }

        initFps = fpsNum[fpsIndex];
        tempFpsIndex = fpsIndex;
        
        tempSkyboxSpeed = (targetState != null && Reflect.hasField(targetState, "skyboxSpeed")) ? targetState.skyboxSpeed : Options.skyboxSpeed;
        initSkyboxSpeed = tempSkyboxSpeed;
        
        tempFov = (targetState != null && targetState.camera != null && Reflect.hasField(targetState, "lens")) ? Std.int(targetState.camera.lens.fieldOfView) : Options.skyboxFov;
        initSkyboxFov = tempFov;

        tempIntroVideo = Options.introVideo;
        initIntroVideo = tempIntroVideo;

        background = new Sprite();
        addChild(background);

        panelUI = new Sprite();
        addChild(panelUI);

        tabBar = new Sprite();
        addChild(tabBar);

        contentArea = new Sprite();
        addChild(contentArea);

        title = new TextField();
        title.defaultTextFormat = new TextFormat("Bahnschrift", 12, 0xFFFFFF, true);
        title.text = "OPTIONS";
        title.selectable = false;
        title.mouseEnabled = false;
        addChild(title);

        var buttonFormat:TextFormat = new TextFormat("Bahnschrift", 12, 0xFFFFFF, false);
        buttonFormat.align = TextFormatAlign.CENTER;

        closeButt = new Sprite();
        closeButt.buttonMode = true;
        closeButt.addEventListener(MouseEvent.CLICK, onClosureClick);
        addChild(closeButt);

        closeTitle = new TextField();
        closeTitle.defaultTextFormat = buttonFormat;
        closeTitle.mouseEnabled = false;
        closeTitle.selectable = false;
        closeTitle.text = "Cancel";
        addChild(closeTitle);

        applyButt = new Sprite();
        applyButt.addEventListener(MouseEvent.CLICK, onAcceptionClick);
        addChild(applyButt);

        applyTitle = new TextField();
        applyTitle.defaultTextFormat = buttonFormat;
        applyTitle.mouseEnabled = false;
        applyTitle.selectable = false;
        applyTitle.text = "Apply";
        addChild(applyTitle);

        updateOptions();
    }

    private function layoutUI():Void {
        this.x = 0;
        this.y = 0;

        var st = Lib.current.stage;
        var stageW:Float = st.stageWidth;
        var stageH:Float = st.stageHeight;

        uiScale = Math.min(stageW / BASE_W, stageH / BASE_H);
        var s:Float = uiScale;

        var panelW:Float = 700 * s;
        var panelH:Float = 450 * s;

        background.graphics.clear();
        background.graphics.beginFill(0x000000, 0.6);
        background.graphics.drawRect(-2000, -2000, stageW + 4000, stageH + 4000);
        background.graphics.endFill();

        panelUI.graphics.clear();
        panelUI.graphics.beginFill(0x1e1e1e, 0.95);
        panelUI.graphics.lineStyle(2 * s, 0x333333, 1.0);
        panelUI.graphics.drawRoundRect(0, 0, panelW, panelH, 12 * s, 12 * s);
        panelUI.graphics.endFill();

        panelUI.x = (stageW - panelW) / 2;
        panelUI.y = (stageH - panelH) / 2;

        setFontSize(title, px(12));
        title.x = panelUI.x + 12 * s;
        title.y = panelUI.y + 10 * s;
        title.width = 200 * s;
        title.height = 22 * s;

        tabBar.x = panelUI.x + 12 * s;
        tabBar.y = panelUI.y + 35 * s;

        contentArea.x = panelUI.x + 12 * s;
        contentArea.y = panelUI.y + 80 * s;

        buildTabs();
        createOptionCategory(currentCategory);

        var bw:Float = buttW * s;
        var bh:Float = buttH * s;

        closeButt.graphics.clear();
        closeButt.graphics.beginFill(0x333333);
        closeButt.graphics.drawRoundRect(0, 0, bw, bh, 8 * s, 8 * s);
        closeButt.graphics.endFill();
        closeButt.x = panelUI.x + panelW - bw - 10 * s;
        closeButt.y = panelUI.y + 410 * s;
        layoutButtonLabel(closeTitle, closeButt, bw, s);

        applyButt.x = panelUI.x + panelW - bw - 102 * s;
        applyButt.y = panelUI.y + 410 * s;
        layoutButtonLabel(applyTitle, applyButt, bw, s);

        updateOptions();
    }

    private function layoutButtonLabel(label:TextField, butt:Sprite, bw:Float, s:Float):Void {
        setFontSize(label, px(12));
        label.width = bw;
        label.height = 20 * s;
        label.x = butt.x;
        label.y = butt.y + 6 * s;
    }

    private function buildTabs():Void {
        while (tabBar.numChildren > 0) tabBar.removeChildAt(0);

        createTab("Video", 0, function() createOptionCategory("Video"));
        createTab("Engine", 95, function() createOptionCategory("Engine"));
        // createTab("Keyboard", 190, function() createOptionCategory("Keyboard"));
        // createTab("Mouse", 285, function() createOptionCategory("Mouse"));
    }

    private function createTab(label:String, xPos:Float, onClick:Void -> Void):Void {
        var s:Float = uiScale;

        var tab = new Sprite();
        tab.graphics.beginFill(0x2a2a2a, 1.0);
        tab.graphics.lineStyle(1, 0x3d3d3d, 1.0);
        tab.graphics.drawRoundRect(xPos * s, 0, 90 * s, 26 * s, 4 * s, 4 * s);
        tab.graphics.endFill();

        var text = new TextField();
        text.defaultTextFormat = new TextFormat("_sans", px(11), 0xCCCCCC);
        text.text = label;
        text.x = (xPos + 15) * s;
        text.y = 5 * s;
        text.width = 70 * s;
        text.mouseEnabled = false;
        tab.addChild(text);

        tab.buttonMode = true;
        tab.addEventListener(MouseEvent.CLICK, function(e:MouseEvent) {
            onClick();
        });
        tabBar.addChild(tab);
    }

    private function updateOptions():Void {
        isChanged = (tempFpsIndex != fpsIndex) || (tempSkyboxSpeed != initSkyboxSpeed) || (tempFov != initSkyboxFov) || (tempIntroVideo != initIntroVideo);

        applyButt.graphics.clear();
        applyButt.graphics.beginFill(isChanged ? 0x00833b : 0x333333, 1.0);
        applyButt.graphics.drawRoundRect(0, 0, buttW * uiScale, buttH * uiScale, 8 * uiScale, 8 * uiScale);
        applyButt.graphics.endFill();

        applyButt.buttonMode = isChanged;
        applyTitle.textColor = isChanged ? 0xFFFFFF : 0x777777;
    }

    private function createOptionCategory(category:String):Void {
        currentCategory = category;

        while (contentArea.numChildren > 0) contentArea.removeChildAt(0);

        fpsText = null;
        skyboxFovValue = null;
        introVideoText = null;

        if (category == "Video") {
            var currentFps = fpsNum[tempFpsIndex];
            var curFpsTxt = (currentFps == 0) ? "Unlimited" : Std.string(currentFps);
            createOptionRow("FPS Limit", 0, function() {
                tempFpsIndex = (tempFpsIndex + 1) % fpsNum.length;
                var variable = fpsNum[tempFpsIndex];
                fpsText.text = (variable == 0) ? "Unlimited" : Std.string(variable);
                updateOptions();
            }, fpsText = createOptionValue(curFpsTxt, 0));

            var fallbackFov = tempFov;
            if (targetState != null && targetState.camera != null) {
                try {
                    var lens:Dynamic = targetState.camera.lens;
                    if (lens != null) fallbackFov = Std.int(lens.fieldOfView); 
                } catch (e:Dynamic) {}
            }

            var curFovStr = Std.string(fallbackFov);
            createOptionRow("Camera FOV", 30, function() {
                tempFov += 5;
                if (tempFov > 90) tempFov = 45;
                skyboxFovValue.text = Std.string(tempFov);

                if (targetState != null && targetState.camera != null) {
                    try {
                        var lens:Dynamic = targetState.camera.lens;
                        if (lens != null) lens.fieldOfView = tempFov;
                    } catch (e:Dynamic) {}
                }
                updateOptions();
            }, skyboxFovValue = createOptionValue(curFovStr, 30));
        } else if (category == "Engine") {
            createOptionRow("Intro Video", 0, function() {
                tempIntroVideo = !tempIntroVideo;
                introVideoText.text = tempIntroVideo ? "Enabled" : "Disabled";
                updateOptions();
            }, introVideoText = createOptionValue(tempIntroVideo ? "Enabled" : "Disabled", 0));
        }
        else {
            var placeholder = new TextField();
            placeholder.defaultTextFormat = new TextFormat("Bahnschrift", px(14), 0x888888);
            placeholder.text = category + " coming...";
            placeholder.x = 10 * uiScale;
            placeholder.y = 10 * uiScale;
            contentArea.addChild(placeholder);
        }
    }

    private function createOptionRow(label:String, yPos:Float, onClickAction:Void -> Void, variable:TextField):Void {
        var s:Float = uiScale;

        var labelTxt = new TextField();
        labelTxt.defaultTextFormat = new TextFormat("Bahnschrift", px(11), 0xCCCCCC);
        labelTxt.text = label;
        labelTxt.x = 10 * s;
        labelTxt.y = (yPos + 6) * s;
        labelTxt.width = 200 * s;
        labelTxt.mouseEnabled = false;
        contentArea.addChild(labelTxt);

        var hitArea = new Sprite();
        hitArea.graphics.beginFill(0x2d2d2d, 1.0);
        hitArea.graphics.drawRoundRect(220 * s, yPos * s, 220 * s, 28 * s, 4 * s, 4 * s);
        hitArea.graphics.endFill();
        hitArea.buttonMode = true;
        hitArea.addEventListener(MouseEvent.CLICK, function(e:MouseEvent) {
            onClickAction();
        });
        contentArea.addChild(hitArea);
        contentArea.addChild(variable);
    }

    private function createOptionValue(defaultTxt:String, yPos:Float):TextField {
        var s:Float = uiScale;

        var text = new TextField();
        text.defaultTextFormat = new TextFormat("Bahnschrift", px(11), 0xFFFFFF);
        text.text = defaultTxt;
        text.x = 235 * s;
        text.y = (yPos + 6) * s;
        text.width = 190 * s;
        text.mouseEnabled = false;
        return text;
    }

    private function onAcceptionClick(e:MouseEvent):Void {
        if (!isChanged) return;

        fpsIndex = tempFpsIndex;
        Options.fps = fpsNum[fpsIndex];
        Options.skyboxFov = tempFov;
        Options.skyboxSpeed = tempSkyboxSpeed;
        Options.introVideo = tempIntroVideo;

        Lib.current.stage.frameRate = (Options.fps == 0) ? 0 : Options.fps;

        if (targetState != null) {
            if (Reflect.hasField(targetState, "skyboxSpeed")) targetState.skyboxSpeed = tempSkyboxSpeed;
            if (targetState.camera != null && Reflect.hasField(targetState.camera, "lens")) {
                targetState.camera.lens.fieldOfView = tempFov;
            }
        }
        Options.save();

        initFps = Options.fps;
        initSkyboxSpeed = tempSkyboxSpeed;
        initSkyboxFov = tempFov;
        initIntroVideo = tempIntroVideo;

        updateOptions();
    }

    private function onWindowResize(e:Event):Void {
        layoutUI();
    }

    private function onClosureClick(e:MouseEvent):Void {
        if (onClose != null) onClose();

        mouseEnabled = false;
        mouseChildren = false;

        removeEventListener(Event.ENTER_FRAME, onEnterFrameFadeIn);
        addEventListener(Event.ENTER_FRAME, onEnterFrameFadeOut);
    }

    private function onEnterFrameFadeOut(e:Event):Void {
        alpha -= 0.05;
        if (alpha <= 0.0) {
            alpha = 0.0;
            removeEventListener(Event.ENTER_FRAME, onEnterFrameFadeOut);
            destroy();
        }
    }

    public function destroy():Void {
        removeEventListener(Event.ADDED_TO_STAGE, onAddedStage);
        removeEventListener(Event.ENTER_FRAME, onEnterFrameFadeIn);
        removeEventListener(Event.ENTER_FRAME, onEnterFrameFadeOut);
        Lib.current.stage.removeEventListener(Event.RESIZE, onWindowResize);
        if (closeButt != null) closeButt.removeEventListener(MouseEvent.CLICK, onClosureClick);
        if (applyButt != null) applyButt.removeEventListener(MouseEvent.CLICK, onAcceptionClick);
        if (parent != null) parent.removeChild(this);
    }
}
