package engine.states.game;

import openfl.events.MouseEvent;
import openfl.geom.Vector3D;
import away3d.containers.View3D;
import away3d.entities.Mesh;
import away3d.primitives.CubeGeometry;
import away3d.primitives.PlaneGeometry;
import away3d.primitives.SkyBox;
import away3d.materials.ColorMaterial;
import away3d.materials.TextureMaterial;
import away3d.textures.BitmapTexture;
import away3d.textures.BitmapCubeTexture;
import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.ui.Keyboard;
import openfl.utils.Assets;

class PlayState extends SBState {
    private var substate:PauseSubstate;

    private var threeDeView:View3D;
    private var skybox:SkyBox;

    private var platforms:Array<Mesh> = [];
    private var platformBounds:Array<{x:Float, y:Float, z:Float, width:Float, height:Float, depth:Float}> = [];
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

    private var keyUp:Bool = false;
    var keyDown:Bool = false;
    var keyLeft:Bool = false;
    var keyRight:Bool = false;

    private var velocity:Float = 0.0;
    private var gravity:Float = -0.8;
    private var jump:Float = 15.0;
    private var isGround:Bool = false;
    private var ground:Float = 50.0;
    private var keyJump:Bool = false;

    private var movementSpeed:Float = 8.0;
    private var mapData:MapMetadata;

    public function new(?data:MapMetadata) {
        super();
        this.mapData = data;
        addEventListener(Event.ADDED_TO_STAGE, onAddedStage);
    }

    private function onAddedStage(e:Event):Void {
        removeEventListener(Event.ADDED_TO_STAGE, onAddedStage);

        setupView();
        setupPlat();
        setupPlayer();
        setupListeners();

        onResize(null);
    }

    public function openSubState(target:PauseSubstate):Void {
        if (substate != null) closeSubstate();
        substate = target;

        keyUp = keyDown = keyLeft = keyRight = keyJump = false;
        isRightMouse = false;

        addChild(substate);
    }

    public function closeSubstate():Void {
        if (substate != null) {
            substate.close();
            if (contains(substate)) removeChild(substate);
            substate = null;
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

        onResize(null);
    }

    private function onEnterFrame(e:Event):Void {
        if (substate != null) {
            if (threeDeView != null) threeDeView.render();
            return;
        }
        var moveX:Float = 0;
        var moveZ:Float = 0;

        if (keyUp) moveZ += 1;
        if (keyDown) moveZ -= 1;
        if (keyLeft) moveX -= 1;
        if (keyRight) moveX += 1;

        var yawRad = cameraYaw * (Math.PI / 180);
        if (moveX != 0 || moveZ != 0) {
            var forwardX = Math.sin(yawRad);
            var forwardZ = Math.cos(yawRad);
            var rightX = Math.cos(yawRad);
            var rightZ = -Math.sin(yawRad);

            var directionX = (forwardX * moveZ) + (rightX * moveX);
            var directionZ = (forwardZ * moveZ) + (rightZ * moveX);

            var len = Math.sqrt(directionX * directionX + directionZ * directionZ);
            if (len > 0) {
                directionX /= len;
                directionZ /= len;
            }

            player.x += directionX * movementSpeed;
            player.z += directionZ * movementSpeed;

            var angleMove = Math.atan2(directionX, directionZ) * (180 / Math.PI);
            player.rotationY = angleMove;
        }

        if (keyJump && isGround) {
            velocity = jump;
            isGround = false;
        }

        velocity += gravity;
        player.y += velocity;

        isGround = false;

        var pHalfW:Float = 50.0;
        var pHalfH:Float = 50.0;
        var pHalfD:Float = 50.0;

        for (platform in platformBounds) {
            var platformHalfW:Float = platform.width / 2.0;
            var platformHalfH:Float = platform.height / 2.0;
            var platformHalfD:Float = platform.depth / 2.0;

            var xOver:Bool = Math.abs(player.x - platform.x) < (pHalfW + platformHalfW);
            var zOver:Bool = Math.abs(player.z - platform.z) < (pHalfD + platformHalfD);

            if (xOver && zOver) {
                var topPlatform:Float = platform.y + platformHalfH;
                var bottomPlayer:Float = player.y - pHalfH;

                if (bottomPlayer <= topPlatform && (bottomPlayer - velocity) >= (topPlatform - 30.00)) {
                    player.y = topPlatform + pHalfH;
                    velocity = 0.0;
                    isGround = true;
                    break;
                }
            }
        }

        if (player.y < voidY) respawnPlayer();

        if (threeDeView != null && player != null) {
            player.rotationY = -cameraYaw;

            var yaw = cameraYaw * (Math.PI / 180);
            var pitch = cameraPitch * (Math.PI / 180);

            var horizontalDistance:Float = cameraDistance * Math.cos(pitch);
            var verticalDistance:Float = cameraDistance * Math.sin(pitch);

            var offsetX:Float = horizontalDistance * Math.sin(yaw);
            var offsetZ:Float = -horizontalDistance * Math.cos(yaw);

            threeDeView.camera.x = player.x + offsetX;
            threeDeView.camera.y = player.y + verticalDistance;
            threeDeView.camera.z = player.z + offsetZ;

            threeDeView.camera.lookAt(new Vector3D(player.x, player.y + 50, player.z));
            threeDeView.render();
        } 
    }

    private function onKeyDown(e:KeyboardEvent):Void {
        if (e.keyCode == Keyboard.ESCAPE) {
            if (substate == null) {
                openSubState(new PauseSubstate());
            } else {
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
        }
    }

    private function onKeyUp(e:KeyboardEvent):Void {
        switch (e.keyCode) {
            case Keyboard.W | Keyboard.UP:      keyUp = false;
            case Keyboard.S | Keyboard.DOWN:    keyDown = false;
            case Keyboard.A | Keyboard.LEFT:    keyLeft = false;
            case Keyboard.D | Keyboard.RIGHT:   keyRight = false;
            case Keyboard.SPACE:                keyJump  = false;
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
        if (!isRightMouse || substate != null) return;

        var deltaX:Float = e.stageX - rawMouseX;
        var deltaY:Float = e.stageY - rawMouseY;

        rawMouseX = e.stageX;
        rawMouseY = e.stageY;

        cameraYaw += deltaX * 0.3;
        cameraPitch -= deltaY * 0.3;

        if (cameraPitch > 85) cameraPitch = 85;
        if (cameraPitch < -30.0) cameraPitch = -30.0;
    }

    private function respawnPlayer():Void {
            player.x = spawnX;
            player.y = spawnY;
            player.z = spawnZ;
            velocity = 0.0;
            isGround = true;
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
            stage.removeEventListener(Event.RESIZE, onResize);
            stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
            stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyUp);

            stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onRightMouseDown);
            stage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP, onRightMouseUp);
            stage.removeEventListener(MouseEvent.MOUSE_UP, onReleaseMouseUp);
            stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
        }

        if (threeDeView != null) {
            if (contains(threeDeView)) removeChild(threeDeView);

            if (threeDeView.scene != null) {
                while (threeDeView.scene.numChildren > 0) threeDeView.scene.removeChildAt(0);
            }

            threeDeView = null;
        }
    }
}