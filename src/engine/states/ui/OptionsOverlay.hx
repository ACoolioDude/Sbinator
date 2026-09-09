package engine.states.ui;

import openfl.Lib;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.text.TextField;
import openfl.text.TextFormat;

class OptionsOverlay extends SBSubState {
    private var targetState:Dynamic;

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
        Lib.current.addEventListener(Event.RESIZE, onWindowResize);
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

        background = new Sprite();
        addChild(background);

        panelUI = new Sprite();
        addChild(panelUI);

        tabBar = new Sprite();
        addChild(tabBar);

        contentArea = new Sprite();
        addChild(contentArea);

        createTab("Video", 0, function() createOptionCategory("Video"));
        createTab("Audio", 95, function() createOptionCategory("Audio"));
        createTab("Keyboard", 190, function() createOptionCategory("Keyboard"));
        createTab("Mouse", 285, function() createOptionCategory("Mouse"));

        createOptionCategory("Video");

        title = new TextField();
        title.defaultTextFormat = new TextFormat("Bahnschrift", 12, 0xFFFFFF, true);
        title.text = "OPTIONS";
        title.selectable = false;
        addChild(title);

        closeButt = new Sprite();
        closeButt.buttonMode = true;
        closeButt.addEventListener(MouseEvent.CLICK, onClosureClick);
        addChild(closeButt);

        closeTitle = new TextField();
        closeTitle.defaultTextFormat = new TextFormat("Bahnschrift", 12, 0xFFFFFF, false);
        closeTitle.mouseEnabled = false;
        closeTitle.selectable = false;
        closeTitle.text = "Cancel";
        addChild(closeTitle);

        applyButt = new Sprite();
        applyButt.addEventListener(MouseEvent.CLICK, onAcceptionClick);
        addChild(applyButt);

        applyTitle = new TextField();
        applyTitle.defaultTextFormat = new TextFormat("Bahnschrift", 12, 0xFFFFFF, false);
        applyTitle.mouseEnabled = false;
        applyTitle.selectable = false;
        applyTitle.text = "Apply";
        addChild(applyTitle);

        updateOptions();
    }

    private function layoutUI():Void {
        this.x = 0;
        this.y = 0;

        var stageW:Float = (stage != null) ? stage.stageWidth : Lib.current.stage.stageWidth;
        var stageH:Float = (stage != null) ? stage.stageHeight : Lib.current.stage.stageHeight;
        
        var panelW:Float = 700;
        var panelH:Float = 450;

        background.graphics.clear();
        background.graphics.beginFill(0x000000, 0.6);
        background.graphics.drawRect(-2000, -2000, stageW + 4000, stageH + 4000);
        background.graphics.endFill();

        panelUI.graphics.clear();
        panelUI.graphics.beginFill(0x1e1e1e, 0.95);
        panelUI.graphics.lineStyle(2, 0x333333, 1.0);
        panelUI.graphics.drawRoundRect(0, 0, panelW, panelH, 12, 12);
        panelUI.graphics.endFill();

        panelUI.x = (stageW - panelW) / 2;
        panelUI.y = (stageH - panelH) / 2;

        title.x = panelUI.x + 12;
        title.y = panelUI.y + 10;

        tabBar.x = panelUI.x + 12;
        tabBar.y = panelUI.y + 35;

        contentArea.x = panelUI.x + 12;
        contentArea.y = panelUI.y + 80;

        closeButt.graphics.clear();
        closeButt.graphics.beginFill(0x333333);
        closeButt.graphics.drawRoundRect(0, 0, buttW, buttH, 8, 8);
        closeButt.graphics.endFill();
        closeButt.x = panelUI.x + panelW - buttW - 10;
        closeButt.y = panelUI.y + 410;

        closeTitle.x = closeButt.x + 18;
        closeTitle.y = closeButt.y + 6;

        applyButt.x = panelUI.x + panelW - buttW - 102;
        applyButt.y = panelUI.y + 410;

        applyTitle.x = applyButt.x + 20;
        applyTitle.y = applyButt.y + 6;

        updateOptions();
    }

    private function createTab(label:String, xPos:Float, onClick:Void -> Void):Void {
        var tab = new Sprite();
        tab.graphics.beginFill(0x2a2a2a, 1.0);
        tab.graphics.lineStyle(1, 0x3d3d3d, 1.0);
        tab.graphics.drawRoundRect(xPos, 0, 90, 26, 4, 4);
        tab.graphics.endFill();

        var text = new TextField();
        text.defaultTextFormat = new TextFormat("_sans", 11, 0xCCCCCC);
        text.text = label;
        text.x = xPos + 15;
        text.y = 5;
        text.width = 70;
        text.mouseEnabled = false;
        tab.addChild(text);

        tab.buttonMode = true;
        tab.addEventListener(MouseEvent.CLICK, function(e:MouseEvent) {
            onClick();
        });
        tabBar.addChild(tab);
    }

    private function updateOptions():Void {
        isChanged = (tempFpsIndex != fpsIndex) || (tempSkyboxSpeed != initSkyboxSpeed) || (tempFov != initSkyboxFov);

        applyButt.graphics.clear();
        applyButt.graphics.beginFill(isChanged ? 0x00833b : 0x333333, 1.0);
        applyButt.graphics.drawRoundRect(0, 0, buttW, buttH, 8, 8);
        applyButt.graphics.endFill();

        applyButt.buttonMode = isChanged;
        applyTitle.textColor = isChanged ? 0xFFFFFF : 0x777777;
    }

    private function createOptionCategory(category:String):Void {
        while (contentArea.numChildren > 0) contentArea.removeChildAt(0);

        fpsText = null;
        skyboxFovValue = null;

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
        }
        else {
            var placeholder = new TextField();
            placeholder.defaultTextFormat = new TextFormat("Bahnschrift", 14, 0x888888);
            placeholder.text = category + " coming...";
            placeholder.x = 10;
            placeholder.y = 10;
            contentArea.addChild(placeholder);
        }
    }

    private function createOptionRow(label:String, yPos:Float, onClickAction:Void -> Void, variable:TextField):Void {
        var labelTxt = new TextField();
        labelTxt.defaultTextFormat = new TextFormat("Bahnschrift", 11, 0xCCCCCC);
        labelTxt.text = label;
        labelTxt.x = 10;
        labelTxt.y = yPos + 6;
        labelTxt.width = 200;
        labelTxt.mouseEnabled = false;
        contentArea.addChild(labelTxt);

        var hitArea = new Sprite();
        hitArea.graphics.beginFill(0x2d2d2d, 1.0);
        hitArea.graphics.drawRoundRect(220, yPos, 220, 28, 4, 4);
        hitArea.graphics.endFill();
        hitArea.buttonMode = true;
        hitArea.addEventListener(MouseEvent.CLICK, function(e:MouseEvent) {
            onClickAction();
        });
        contentArea.addChild(hitArea);
        contentArea.addChild(variable);
    }

    private function createOptionValue(defaultTxt:String, yPos:Float):TextField {
        var text = new TextField();
        text.defaultTextFormat = new TextFormat("Bahnschrift", 11, 0xFFFFFF);
        text.text = defaultTxt;
        text.x = 235;
        text.y = yPos + 6;
        text.width = 190;
        text.mouseEnabled = false;
        return text;
    }

    private function onAcceptionClick(e:MouseEvent):Void {
        if (!isChanged) return;

        fpsIndex = tempFpsIndex;
        Options.fps = fpsNum[fpsIndex];
        Options.skyboxFov = tempFov;
        Options.skyboxSpeed = tempSkyboxSpeed;

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

        updateOptions();
    }

    private function onWindowResize(e:Event) {
        layoutUI();
    }

    private function onClosureClick(e:MouseEvent):Void {
        if (onClose != null) onClose();

        mouseEnabled = false;
        mouseChildren = false;

        removeEventListener(Event.ENTER_FRAME, onEnterFrameFadeIn);
        addEventListener(Event.EXIT_FRAME, onEnterFrameFadeOut);
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
        removeEventListener(Event.ADDED_TO_STAGE, onEnterFrameFadeIn);
        Lib.current.removeEventListener(Event.RESIZE, onWindowResize);
        if (closeButt != null) closeButt.removeEventListener(MouseEvent.CLICK, onClosureClick);
        if (parent != null) parent.removeChild(this);
    }
}