package engine.states.game;

import haxe.Resource;
import haxe.Timer;
import away3d.containers.View3D;
import away3d.entities.Mesh;
import away3d.primitives.CubeGeometry;
import away3d.primitives.PlaneGeometry;
import away3d.primitives.SkyBox;
import away3d.materials.ColorMaterial;
import away3d.materials.TextureMaterial;
import away3d.textures.BitmapTexture;
import away3d.textures.BitmapCubeTexture;
import openfl.events.MouseEvent;
import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.geom.Vector3D;
import openfl.media.Sound;
import openfl.media.SoundMixer;
import openfl.media.SoundTransform;
import openfl.ui.Keyboard;
import openfl.utils.Assets;

typedef PlatformBox = {x:Float, y:Float, z:Float, width:Float, height:Float, depth:Float}

class PlayState extends SBState {
    private var substate:PauseSubstate;

    private var threeDeView:View3D;
    private var skybox:SkyBox;

    private var platforms:Array<Mesh> = [];
    private var platformBounds:Array<PlatformBox> = [];
    private var platformWidth:Float = 3000.0;
    private var platformDepth:Float = 3000.0;
    private var voidY:Float = -5000.0;

    private var player:Mesh;
    private var spawnX:Float = 0.0;
    private var spawnY:Float = 0.0;
    private var spawnZ:Float = 0.0;

    private var isRightMouse:Bool = false;
    private var rawMouseX:Float = 0;
    private var rawMouseY:Float = 0;

    private var cameraYaw:Float = 0;
    private var cameraPitch:Float = 15;
    private var cameraDistance:Float = 800;

    private var firstPerson:Bool = false;
    private var keyPerspective:Bool = false;
    private static inline var EYE_HEIGHT:Float = 30.0;
    private static inline var LOCKED_SENS:Float = 0.15;

    private var keyUp:Bool = false;
    var keyDown:Bool = false;
    var keyLeft:Bool = false;
    var keyRight:Bool = false;

    private var velocity:Float = 0.0;
    private var gravity:Float = -2880.0;
    private var jump:Float = 900.0;
    private var isGround:Bool = false;
    private var ground:Float = 50.0;
    private var keyJump:Bool = false;

    private var movementSpeed:Float = 480.0;
    private var velX:Float = 0.0;
    private var velZ:Float = 0.0;
    private var wantX:Float = 0.0;
    private var wantZ:Float = 0.0;
    private var lastTime:Float = 0.0;
    private var lookTarget:Vector3D = new Vector3D();

    private static inline var PHALF:Float = 50.0;
    private static inline var EPS:Float = 0.001;
    private static inline var STEP_HEIGHT:Float = 30.0;
    private static inline var GROUND_ACCEL:Float = 14.0;
    private static inline var AIR_ACCEL:Float = 4.0;
    private static inline var MAX_FALL:Float = -3000.0;
    private static inline var MAX_STEP_TIME:Float = 1 / 120;
    private var mapData:MapMetadata;

    private var viewBuilt:Bool = false;
    private var platformsBuilt:Bool = false;
    private var playerBuilt:Bool = false;

    private var stepSound:Array<Sound> = [];
    private var lastStep:Int = -1;
    private var stepInst:Float = 0.0;
    private static inline var STEP_COUNT:Int = 4;
    private static inline var STEP_DISTANCE:Float = 160;
    private static inline var STEP_VOLUME:Float = 0.5;

    public function new(?data:MapMetadata) {
        super();
        this.mapData = data;
        addEventListener(Event.ADDED_TO_STAGE, onAddedStage);
    }

    private function onAddedStage(e:Event):Void {
        removeEventListener(Event.ADDED_TO_STAGE, onAddedStage);

        buildView();
        buildPlatforms();
        buildPlayer();

        setupListeners();

        onResize(null);
    }

    public function buildView():Void {
        if (viewBuilt) return;
        viewBuilt = true;
        setupView();
    }

    public function buildPlatforms():Void {
        if (platformsBuilt) return;
        platformsBuilt = true;
        buildView();
        setupPlat();
    }

    public function buildPlayer():Void {
        if (playerBuilt) return;
        playerBuilt = true;
        buildPlatforms();
        setupPlayer();
    }

    public function openSubState(target:PauseSubstate):Void {
        if (substate != null) closeSubstate();
        substate = target;

        keyUp = keyDown = keyLeft = keyRight = keyJump = keyPerspective = false;
        isRightMouse = false;
        SoundMixer.soundTransform = new SoundTransform(0);
        applyMouseLock(false);

        addChild(substate);
    }

    private function onPauseGame():Void {
        if (substate != null) return;

        var pauseState = new PauseSubstate();
        pauseState.onResume = closeSubstate;
        openSubState(pauseState);
    }

    private function onFocusLost(e:Event):Void {
        keyUp = keyDown = keyLeft = keyRight = keyJump = keyPerspective = false;
        isRightMouse = false;
        applyMouseLock(false);

        if (Options.autoPause) onPauseGame();
    }

    public function closeSubstate():Void {
        if (substate != null) {
            substate.close();
            if (contains(substate)) removeChild(substate);
            substate = null;
            SoundMixer.soundTransform = new SoundTransform(1);
            applyMouseLock(firstPerson);
        }
    }

    private function setupView():Void {
        threeDeView = new View3D();
        addChild(threeDeView);

        if (stage != null) {
            threeDeView.width = stage.stageWidth;
            threeDeView.height = stage.stageHeight;
        } else {
            threeDeView.width = 1280;
            threeDeView.height = 720;
        }

        threeDeView.camera.x = 0;
        threeDeView.camera.y = 400;
        threeDeView.camera.z = -800;
        threeDeView.camera.lookAt(new Vector3D(0, 0, 0));
    }

    private function setupPlat():Void {
        if (mapData != null) {
            if (mapData.voidY != null) voidY = mapData.voidY;
            if (mapData.spawn != null) {
                spawnX = mapData.spawn.x;
                spawnY = mapData.spawn.y;
                spawnZ = mapData.spawn.z;
            }

            if (mapData.platforms != null) {
                for (platformDefintion in mapData.platforms) {
                    var geom = new CubeGeometry(
                        platformDefintion.width, 
                        platformDefintion.height, 
                        platformDefintion.depth
                    );
    
                    var matCol = 0x919191;
                    if (platformDefintion.color != null) {
                        var parsed = Std.parseInt(platformDefintion.color);
                        if (parsed != null) matCol = parsed;
                    }

                    var mat = new ColorMaterial(matCol);
                    var pMesh = new Mesh(geom, mat);

                    pMesh.x = platformDefintion.x;
                    pMesh.y = platformDefintion.y;
                    pMesh.z = platformDefintion.z;

                    threeDeView.scene.addChild(pMesh);
                    platforms.push(pMesh);

                    platformBounds.push({
                        x: platformDefintion.x,
                        y: platformDefintion.y,
                        z: platformDefintion.z,
                        width: platformDefintion.width,
                        height: platformDefintion.height,
                        depth: platformDefintion.depth
                    });
                }
                return;
            }
        } else {
            trace('Attempting to load JSON is NULL. Platform will fail to generate!');
        }
    }

    private function setupPlayer():Void {
        var cubeGeometry = new CubeGeometry(100, 100, 100);
        var cubeMaterial = new ColorMaterial(0x9900AD17);

        player = new Mesh(cubeGeometry, cubeMaterial);
        player.x = spawnX;
        player.y = spawnY + 50;
        player.z = spawnZ;
        threeDeView.scene.addChild(player);

        loadSteps();
    }

    private function loadSteps():Void {
        for (steps in 1...STEP_COUNT + 1) {
            var id = ResourceLoader.resolveId('sounds/player/footsteps/duct${steps}.wav');
            if (id != null) stepSound.push(Assets.getSound(id));
        }
    }

    private function playSteps():Void {
        if (stepSound.length == 0) return;

        var i = Std.random(stepSound.length);
        if (stepSound.length > 1 && i == lastStep) i = (i + 1) % stepSound.length;
        lastStep = i;

        stepSound[i].play(0, 0, new SoundTransform(STEP_VOLUME));
    }

    private function setupListeners():Void {
        if (stage == null) return;

        stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
        stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);

        stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onRightMouseDown);
        stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP, onRightMouseUp);
        stage.addEventListener(MouseEvent.MOUSE_UP, onReleaseMouseUp);
        stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);

        stage.addEventListener(Event.RESIZE, onResize);
        stage.addEventListener(Event.ENTER_FRAME, onEnterFrame);

        stage.addEventListener(Event.DEACTIVATE, onFocusLost);
        stage.addEventListener(Event.ACTIVATE, onFocusGained);
        if (stage.window != null) stage.window.onMouseMoveRelative.add(onMouseRelative);

        onResize(null);
    }

    private function onEnterFrame(e:Event):Void {
        if (substate != null) {
            lastTime = Timer.stamp();
            if (threeDeView != null) threeDeView.render();
            return;
        }

        var now:Float = Timer.stamp();
        var dt:Float = Math.min(now - lastTime, 0.05);
        lastTime = now;

        var moveX:Float = 0;
        var moveZ:Float = 0;

        if (keyUp) moveZ += 1;
        if (keyDown) moveZ -= 1;
        if (keyLeft) moveX -= 1;
        if (keyRight) moveX += 1;

        wantX = 0;
        wantZ = 0;

        if (moveX != 0 || moveZ != 0) {
            var yawRad = cameraYaw * (Math.PI / 180);
            var forwardX = Math.sin(yawRad);
            var forwardZ = Math.cos(yawRad);
            var rightX = Math.cos(yawRad);
            var rightZ = -Math.sin(yawRad);

            var directionX = (forwardX * moveZ) + (rightX * moveX);
            var directionZ = (forwardZ * moveZ) + (rightZ * moveX);

            var len = Math.sqrt(directionX * directionX + directionZ * directionZ);
            if (len > 0) {
                wantX = directionX / len;
                wantZ = directionZ / len;
            }
        }

        if (keyJump && isGround) {
            velocity = jump;
            isGround = false;
        }

        var steps:Int = Math.ceil(dt / MAX_STEP_TIME);
        if (steps < 1) steps = 1;
        var h:Float = dt / steps;
        for (i in 0...steps) stepPhysics(h);

        if (player.y < voidY) respawnPlayer();

        if (threeDeView != null && player != null) {
            player.rotationY = -cameraYaw;

            updateCamera();
            threeDeView.render();
        }
    }

    private function stepPhysics(h:Float):Void {
        var wasOnGround:Bool = isGround;

        var k:Float = Math.min(1.0, (isGround ? GROUND_ACCEL : AIR_ACCEL) * h);
        velX += (wantX * movementSpeed - velX) * k;
        velZ += (wantZ * movementSpeed - velZ) * k;
        moveHorizontal(velX * h, velZ * h);

        velocity += gravity * h;
        if (velocity < MAX_FALL) velocity = MAX_FALL;

        var fallSpeed:Float = velocity;
        var movingUp:Bool = velocity > 0;

        player.y += velocity * h;
        isGround = false;

        for (p in platformBounds) {
            if (!overlaps(p)) continue;

            if (movingUp) {
                player.y = p.y - p.height / 2 - PHALF;
            } else {
                player.y = p.y + p.height / 2 + PHALF;
                isGround = true;
            }
            velocity = 0.0;
        }

        if (isGround) {
            var speed:Float = Math.sqrt(velX * velX + velZ * velZ);
            if (speed > 40) {
                stepInst += speed * h;
                if (stepInst >= STEP_DISTANCE) {
                    stepInst -= STEP_DISTANCE;
                    playSteps();
                }
            } else {
                stepInst = STEP_DISTANCE * 0.5;
            }

            if (!wasOnGround && fallSpeed < -350) playSteps();
        }
    }

    private function moveHorizontal(dx:Float, dz:Float):Void {
        player.x += dx;
        for (p in platformBounds) {
            if (!overlaps(p) || tryStepUp(p)) continue;

            if (dx > 0) player.x = p.x - p.width / 2 - PHALF;
            else if (dx < 0) player.x = p.x + p.width / 2 + PHALF;
            velX = 0.0;
        }

        player.z += dz;
        for (p in platformBounds) {
            if (!overlaps(p) || tryStepUp(p)) continue;

            if (dz > 0) player.z = p.z - p.depth / 2 - PHALF;
            else if (dz < 0) player.z = p.z + p.depth / 2 + PHALF;
            velZ = 0.0;
        }
    }

    private function tryStepUp(p:PlatformBox):Bool {
        if (!isGround) return false;

        var rise:Float = (p.y + p.height / 2) - (player.y - PHALF);
        if (rise > 0 && rise <= STEP_HEIGHT) {
            player.y += rise;
            return true;
        }
        return false;
    }

    private function overlaps(p:PlatformBox):Bool {
        return Math.abs(player.x - p.x) < PHALF + p.width / 2 - EPS
            && Math.abs(player.y - p.y) < PHALF + p.height / 2 - EPS
            && Math.abs(player.z - p.z) < PHALF + p.depth / 2 - EPS;
    }

    private function applyMouseLock(on:Bool):Void {
        if (stage == null || stage.window == null) return;
        stage.window.mouseLock = on;
    }

    private function onMouseRelative(dx:Float, dy:Float):Void {
        if (!firstPerson || substate != null) return;

        cameraYaw += dx * LOCKED_SENS;
        cameraPitch += dy * LOCKED_SENS;
        cameraPitch = Math.max(-85.0, Math.min(85.0, cameraPitch));
    }

    private function onFocusGained(e:Event):Void if (firstPerson && substate == null) applyMouseLock(true);

    private function updateCamera():Void {
        var yaw = cameraYaw * (Math.PI / 180);
        var pitch = cameraPitch * (Math.PI / 180);

        var dirX = Math.sin(yaw) * Math.cos(pitch);
        var dirY = -Math.sin(pitch);
        var dirZ = Math.cos(yaw) * Math.cos(pitch);

        if (firstPerson) {
            var eyeY:Float = player.y + EYE_HEIGHT;

            threeDeView.camera.x = player.x;
            threeDeView.camera.y = eyeY;
            threeDeView.camera.z = player.z;

            lookTarget.setTo(player.x + dirX * 100, eyeY + dirY * 100, player.z + dirZ * 100);
        } else {
            threeDeView.camera.x = player.x - dirX * cameraDistance;
            threeDeView.camera.y = player.y - dirY * cameraDistance;
            threeDeView.camera.z = player.z - dirZ * cameraDistance;

            lookTarget.setTo(player.x, player.y + 50, player.z);
        }

        threeDeView.camera.lookAt(lookTarget);
    }

    private function togglePerspective():Void {
        firstPerson = !firstPerson;

        if (player != null) player.visible = !firstPerson;

        var minPitch:Float = firstPerson ? -85.0 : -30.0;
        cameraPitch = Math.max(minPitch, Math.min(85.0, cameraPitch));

        applyMouseLock(firstPerson);
    }

    private function onKeyDown(e:KeyboardEvent):Void {
        if (e.keyCode == Keyboard.ESCAPE) {
            if (substate == null) {
                var pauseSub = new PauseSubstate();
                pauseSub.onResume = closeSubstate;
                openSubState(pauseSub);
            } else if (!substate.handleEscape()) {
                closeSubstate();
            }
            return;
        }
        switch (e.keyCode) {
            case Keyboard.W | Keyboard.UP:      keyUp = true;
            case Keyboard.S | Keyboard.DOWN:    keyDown = true;
            case Keyboard.A | Keyboard.LEFT:    keyLeft = true;
            case Keyboard.D | Keyboard.RIGHT:   keyRight = true;
            case Keyboard.SPACE:                keyJump  = true;
            case Keyboard.F5:
                if (!keyPerspective && substate == null) togglePerspective();
                keyPerspective = true;
        }
    }

    private function onKeyUp(e:KeyboardEvent):Void {
        switch (e.keyCode) {
            case Keyboard.W | Keyboard.UP:      keyUp = false;
            case Keyboard.S | Keyboard.DOWN:    keyDown = false;
            case Keyboard.A | Keyboard.LEFT:    keyLeft = false;
            case Keyboard.D | Keyboard.RIGHT:   keyRight = false;
            case Keyboard.SPACE:                keyJump  = false;
            case Keyboard.F5:                    keyPerspective = false;
        }
    }

    private function onRightMouseDown(e:MouseEvent):Void {
        isRightMouse = true;
        rawMouseX = e.stageX;
        rawMouseY = e.stageY;
    }

    private function onRightMouseUp(e:MouseEvent):Void isRightMouse = false;

    private function onReleaseMouseUp(e:MouseEvent):Void isRightMouse = false;

    private function onMouseMove(e:MouseEvent):Void {
        if (!isRightMouse || substate != null || firstPerson) return;

        var deltaX:Float = e.stageX - rawMouseX;
        var deltaY:Float = e.stageY - rawMouseY;

        rawMouseX = e.stageX;
        rawMouseY = e.stageY;

        cameraYaw += deltaX * 0.3;  
        cameraPitch += deltaY * 0.3;

        var minPitch:Float = firstPerson ? -85.0 : -30.0;
        if (cameraPitch > 85) cameraPitch = 85;
        if (cameraPitch < minPitch) cameraPitch = minPitch;
    }

    private function respawnPlayer():Void {
        player.x = spawnX;
        player.y = spawnY + 50;
        player.z = spawnZ;
        velX = velZ = velocity = 0.0;
        isGround = false;
    }

    private function onResize(e:Event):Void {
        if (stage != null && threeDeView != null) {
            threeDeView.width = stage.stageWidth;
            threeDeView.height = stage.stageHeight;
        }
    }

    override public function cleanup():Void {
        super.cleanup();

        removeEventListener(Event.ENTER_FRAME, onEnterFrame);
        if (stage != null) {
            stage.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
            stage.removeEventListener(Event.RESIZE, onResize);
            stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
            stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyUp);

            stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onRightMouseDown);
            stage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP, onRightMouseUp);
            stage.removeEventListener(MouseEvent.MOUSE_UP, onReleaseMouseUp);
            stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
            
            stage.removeEventListener(Event.DEACTIVATE, onFocusLost);
            stage.removeEventListener(Event.ACTIVATE, onFocusGained);
            if (stage.window != null) {
                stage.window.onMouseMoveRelative.remove(onMouseRelative);
                stage.window.mouseLock = false;
            }
        }

        if (threeDeView != null) {
            if (contains(threeDeView)) removeChild(threeDeView);

            if (threeDeView.scene != null) {
                while (threeDeView.scene.numChildren > 0) threeDeView.scene.removeChildAt(0);
            }

            threeDeView.dispose();
            threeDeView = null;
        }
    }
}