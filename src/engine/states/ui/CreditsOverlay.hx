package engine.states.ui;

import openfl.Lib;
import openfl.display.Bitmap;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;
import openfl.geom.Rectangle;
import openfl.net.URLRequest;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import openfl.ui.Keyboard;

typedef CreditLink = {label:String, url:String}
typedef CreditEntry = {name:String, role:String, ?icon:String, links:Array<CreditLink>}

class CreditsOverlay extends SBSubState {
    private var targetState:Dynamic;

    private static inline var BASE_W:Float = 1280;
    private static inline var BASE_H:Float = 720;
    private static inline var PANEL_W:Float = 700;
    private static inline var PANEL_H:Float = 450;
    private static inline var CONTENT_TOP:Float = 40;
    private static inline var VIEW_H:Float = 360;

    private static inline var DEFAULT_ICON:String = "images/menus/credits/icon.png";

    private var credits:Array<CreditEntry> = [
        {
            name: "ACoolioDude",
            role: "Main programmer of Sbinator",
            icon: "images/menus/credits/acooliodude.jpeg",
            links: [
                { label: "GitHub", url: "https://github.com/ACoolioDude" },
                { label: "Codeberg", url: "https://codeberg.org/ACoolioDude"}
            ]
        },
        {
            name: "Valve",
            role: "Inspiration of me making Source-looking like engine on Haxe",
            icon: "images/menus/credits/valve.png",
            links: [
                { label: "Valve Software", url: "https://www.valvesoftware.com/en/"},
                { label: "GitHub", url: "https://github.com/ValveSoftware" },
            ]
        }
    ];

    private var selected:Int = -1; 
    private var scrollY:Float = 0;
    private var contentHeight:Float = 0;

    private var uiScale:Float = 1.0;

    private var background:Sprite;
    private var panelUI:Sprite;
    private var title:TextField;
    private var content:Sprite;
    private var closeButt:Sprite;
    private var closeTitle:TextField;

    public var onClose:Void -> Void;

    private var closing:Bool = false;

    public function new(newTarget:Dynamic) {
        super();
        this.targetState = newTarget;

        alpha = 0;
        addEventListener(Event.ADDED_TO_STAGE, onAddedStage);
    }

    override function onAddedStage(e:Event):Void {
        removeEventListener(Event.ADDED_TO_STAGE, onAddedStage);

        initUI();
        layoutUI();

        stage.addEventListener(Event.RESIZE, onWindowResize);
        stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
        addEventListener(MouseEvent.MOUSE_WHEEL, onWheel);
        addEventListener(Event.ENTER_FRAME, onEnterFrameFadeIn);
    }

    private function initUI():Void {
        background = new Sprite();
        addChild(background);

        panelUI = new Sprite();
        addChild(panelUI);

        title = new TextField();
        title.defaultTextFormat = new TextFormat("Bahnschrift", 12, 0xFFFFFF, true);
        title.text = "CREDITS";
        title.selectable = false;
        title.mouseEnabled = false;
        addChild(title);

        content = new Sprite();
        addChild(content);

        var buttonFormat:TextFormat = new TextFormat("Bahnschrift", 12, 0xFFFFFF, false);
        buttonFormat.align = TextFormatAlign.CENTER;

        closeButt = new Sprite();
        closeButt.buttonMode = true;
        closeButt.focusRect = false;
        closeButt.addEventListener(MouseEvent.CLICK, onBottomButton);
        addChild(closeButt);

        closeTitle = new TextField();
        closeTitle.defaultTextFormat = buttonFormat;
        closeTitle.mouseEnabled = false;
        closeTitle.selectable = false;
        closeTitle.text = "Close";
        addChild(closeTitle);
    }

    private function layoutUI():Void {
        x = 0;
        y = 0;

        var st = Lib.current.stage;
        var stageW:Float = st.stageWidth;
        var stageH:Float = st.stageHeight;

        uiScale = Math.min(stageW / BASE_W, stageH / BASE_H);
        var s:Float = uiScale;

        var panelW:Float = PANEL_W * s;
        var panelH:Float = PANEL_H * s;

        var buttW:Float = 80 * s;
        var buttH:Float = 30 * s;

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
        title.width = 400 * s;
        title.height = 22 * s;

        content.x = panelUI.x;
        content.y = panelUI.y + CONTENT_TOP * s;

        closeButt.graphics.clear();
        closeButt.graphics.beginFill(0x333333);
        closeButt.graphics.drawRoundRect(0, 0, buttW, buttH, 8 * s, 8 * s);
        closeButt.graphics.endFill();
        closeButt.x = panelUI.x + panelW - buttW - 10 * s;
        closeButt.y = panelUI.y + 410 * s;

        setFontSize(closeTitle, px(12));
        closeTitle.width = buttW;
        closeTitle.height = 20 * s;
        closeTitle.x = closeButt.x;
        closeTitle.y = closeButt.y + 6 * s;

        rebuildContent();
    }

    private function rebuildContent():Void {
        while (content.numChildren > 0) content.removeChildAt(0);

        scrollY = 0;

        if (selected < 0) {
            closeTitle.text = "Close";
            buildList();
        } else {
            closeTitle.text = "Back";
            buildDetail(credits[selected]);
        }

        applyScroll();
    }

    private function buildList():Void {
        var s:Float = uiScale;
        var rowH:Float = 84 * s;
        var gap:Float = 6 * s;
        var rowW:Float = (PANEL_W - 40) * s;

        for (i in 0...credits.length) {
            var c:CreditEntry = credits[i];

            var row = new Sprite();
            row.x = 20 * s;
            row.y = i * (rowH + gap);
            row.buttonMode = true;
            row.focusRect = false;
            drawRow(row, rowW, rowH, false);

            var icon = makeIcon(c.icon, 64 * s);
            icon.x = 10 * s;
            icon.y = (rowH - 64 * s) / 2;
            row.addChild(icon);

            var nameTf = makeText(c.name, 22, 0xFFFFFF, true);
            nameTf.x = 90 * s;
            nameTf.y = 12 * s;
            nameTf.width = rowW - 100 * s;
            row.addChild(nameTf);

            var roleTf = makeText(c.role, 13, 0xAAAAAA, false);
            roleTf.x = 90 * s;
            roleTf.y = 46 * s;
            roleTf.width = rowW - 100 * s;
            row.addChild(roleTf);

            var index:Int = i;
            row.addEventListener(MouseEvent.ROLL_OVER, function(_) drawRow(row, rowW, rowH, true));
            row.addEventListener(MouseEvent.ROLL_OUT, function(_) drawRow(row, rowW, rowH, false));
            row.addEventListener(MouseEvent.CLICK, function(_) openDetail(index));
            content.addChild(row);
        }

        contentHeight = credits.length * (rowH + gap);
    }

    private function buildDetail(c:CreditEntry):Void {
        var s:Float = uiScale;
        var top:Float = 10 * s;

        var icon = makeIcon(c.icon, 110 * s);
        icon.x = 30 * s;
        icon.y = top;
        content.addChild(icon);

        var nameTf = makeText(c.name, 30, 0xFFFFFF, true);
        nameTf.x = 170 * s;
        nameTf.y = top + 8 * s;
        nameTf.width = 480 * s;
        content.addChild(nameTf);

        var roleTf = makeText(c.role, 15, 0xAAAAAA, false);
        roleTf.x = 170 * s;
        roleTf.y = top + 56 * s;
        roleTf.width = 480 * s;
        content.addChild(roleTf);

        var heading = makeText("INFO FOR " + c.name.toUpperCase(), 12, 0x00854D, true);
        heading.x = 30 * s;
        heading.y = top + 140 * s;
        heading.width = 600 * s;
        content.addChild(heading);

        var linkY:Float = top + 170 * s;
        var btnW:Float = 340 * s;
        var btnH:Float = 36 * s;
        var gap:Float = 8 * s;

        if (c.links == null || c.links.length == 0) {
            var none = makeText("No links yet.", 13, 0x888888, false);
            none.x = 30 * s;
            none.y = linkY;
            none.width = 400 * s;
            content.addChild(none);

            contentHeight = linkY + 30 * s;
            return;
        }

        for (i in 0...c.links.length) {
            var btn = makeLinkButton(c.links[i], btnW, btnH);
            btn.x = 30 * s;
            btn.y = linkY + i * (btnH + gap);
            content.addChild(btn);
        }

        contentHeight = linkY + c.links.length * (btnH + gap) + 10 * s;
    }

    private function openDetail(index:Int):Void {
        selected = index;
        rebuildContent();
    }

    private function backToList():Void {
        selected = -1;
        rebuildContent();
    }

    private function drawRow(row:Sprite, w:Float, h:Float, hover:Bool):Void {
        row.graphics.clear();
        row.graphics.beginFill(hover ? 0x2d2d2d : 0x242424, hover ? 1.0 : 0.6);
        row.graphics.drawRoundRect(0, 0, w, h, 8 * uiScale, 8 * uiScale);
        row.graphics.endFill();
    }

    private function makeText(text:String, size:Float, color:Int, bold:Bool):TextField {
        var tf = new TextField();
        tf.defaultTextFormat = new TextFormat("Bahnschrift", px(size), color, bold);
        tf.text = text;
        tf.wordWrap = true;
        tf.selectable = false;
        tf.mouseEnabled = false;
        return tf;
    }

    private function makeIcon(path:String, size:Float):Sprite {
        var holder = new Sprite();
        holder.mouseEnabled = false;
        holder.mouseChildren = false;

        var bmp = new Bitmap(ResourceLoader.bitmapData(path != null ? path : DEFAULT_ICON));
        bmp.smoothing = true;

        var sc:Float = size / Math.max(bmp.bitmapData.width, bmp.bitmapData.height);
        bmp.scaleX = bmp.scaleY = sc;
        bmp.x = (size - bmp.bitmapData.width * sc) / 2;
        bmp.y = (size - bmp.bitmapData.height * sc) / 2;

        holder.addChild(bmp);
        return holder;
    }

    private function makeLinkButton(link:CreditLink, w:Float, h:Float):Sprite {
        var s:Float = uiScale;

        var btn = new Sprite();
        btn.buttonMode = true;
        btn.focusRect = false;

        var draw = function(hover:Bool) {
            btn.graphics.clear();
            btn.graphics.beginFill(hover ? 0x00833b : 0x2d2d2d, 1.0);
            btn.graphics.drawRoundRect(0, 0, w, h, 6 * s, 6 * s);
            btn.graphics.endFill();
        };
        draw(false);

        var label = makeText(link.label, 13, 0xFFFFFF, true);
        label.x = 14 * s;
        label.y = (h - px(13) * 1.3) / 2;
        label.width = w * 0.55;
        btn.addChild(label);

        var hostFormat:TextFormat = new TextFormat("Bahnschrift", px(11), 0xAAAAAA);
        hostFormat.align = TextFormatAlign.RIGHT;
        var hostTf = makeText(hostOf(link.url), 11, 0xAAAAAA, false);
        hostTf.setTextFormat(hostFormat);
        hostTf.defaultTextFormat = hostFormat;
        hostTf.x = w * 0.55;
        hostTf.y = (h - px(11) * 1.3) / 2;
        hostTf.width = w * 0.45 - 14 * s;
        btn.addChild(hostTf);

        btn.addEventListener(MouseEvent.ROLL_OVER, function(_) draw(true));
        btn.addEventListener(MouseEvent.ROLL_OUT, function(_) draw(false));
        btn.addEventListener(MouseEvent.CLICK, function(_) openLink(link.url));
        return btn;
    }

    private function hostOf(url:String):String {
        var u:String = url;
        var i:Int = u.indexOf("://");
        if (i >= 0) u = u.substr(i + 3);
        var j:Int = u.indexOf("/");
        if (j >= 0) u = u.substr(0, j);
        return u;
    }

    private function openLink(url:String):Void {
        if (!StringTools.startsWith(url, "https://") && !StringTools.startsWith(url, "http://")) {
            trace('Blocked credits link (not http/https): ${url}');
            return;
        }

        try {
            Lib.getURL(new URLRequest(url));
        } catch (e:Dynamic) {
            trace('Could not open ${url}: ${e}');
        }
    }

    private function applyScroll():Void {
        var viewH:Float = VIEW_H * uiScale;
        var maxScroll:Float = Math.max(0, contentHeight - viewH);
        scrollY = Math.max(0, Math.min(maxScroll, scrollY));

        content.scrollRect = new Rectangle(0, scrollY, PANEL_W * uiScale, viewH);
    }

    private function onWheel(e:MouseEvent):Void {
        scrollY -= e.delta * 30 * uiScale;
        applyScroll();
    }

    private function onKeyDown(e:KeyboardEvent):Void {
        if (e.keyCode != Keyboard.ESCAPE) return;

        if (selected >= 0) backToList();
        else startClose();
    }

    private function onBottomButton(e:MouseEvent):Void {
        if (selected >= 0) backToList();
        else startClose();
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

    private function onWindowResize(e:Event):Void {
        layoutUI();
    }


    private function onEnterFrameFadeIn(e:Event):Void {
        alpha += 0.15;
        if (alpha >= 1.0) {
            alpha = 1.0;
            removeEventListener(Event.ENTER_FRAME, onEnterFrameFadeIn);
        }
    }

    private function startClose():Void {
        if (closing) return;
        closing = true;

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
            if (onClose != null) onClose();
        }
    }

    override public function close():Void {
        startClose();
    }

    public function destroy():Void {
        removeEventListener(Event.ADDED_TO_STAGE, onAddedStage);
        removeEventListener(Event.ENTER_FRAME, onEnterFrameFadeIn);
        removeEventListener(Event.ENTER_FRAME, onEnterFrameFadeOut);
        removeEventListener(MouseEvent.MOUSE_WHEEL, onWheel);

        Lib.current.stage.removeEventListener(Event.RESIZE, onWindowResize);
        Lib.current.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);

        if (parent != null) parent.removeChild(this);
    }
}
