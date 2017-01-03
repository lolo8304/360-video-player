/* Copyright 2015 Samsung Electronics Co., LTD
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.lolo.secondscreen;

import android.util.Log;

import org.gearvrf.GVRCameraRig;
import org.gearvrf.GVRContext;
import org.gearvrf.GVRMain;
import org.gearvrf.GVRMesh;
import org.gearvrf.GVRScene;
import org.gearvrf.scene_objects.GVRSphereSceneObject;
import org.gearvrf.scene_objects.GVRVideoSceneObject;
import org.gearvrf.scene_objects.GVRVideoSceneObject.GVRVideoType;
import org.gearvrf.scene_objects.GVRVideoSceneObjectPlayer;

public class Minimal360Video extends GVRMain
{
    public static final float PI = 3.141592653589793f;
    public static final float PI2 = PI / 2.0f;
    public static final float PI4 = PI / 4.0f;

    Minimal360Video(GVRVideoSceneObjectPlayer<?> player) {
        mPlayer = player;
    }

    /** Called when the activity is first created. */
    @Override
    public void onInit(GVRContext gvrContext) {

        GVRScene scene = gvrContext.getNextMainScene();

        // set up camerarig position (default)
        scene.getMainCameraRig().getTransform().setPosition( 0.0f, 0.0f, 0.0f );
        scene.getMainCameraRig().getTransform().rotate(1.0f, 0.0f, PI4, 0.0f);
        //GVRContext.DEBUG_STATS = true;

        // create sphere / mesh
        GVRSphereSceneObject sphere = new GVRSphereSceneObject(gvrContext, 72, 144, false);
        GVRMesh mesh = sphere.getRenderData().getMesh();

        // create video scene
        GVRVideoSceneObject video = new GVRVideoSceneObject( gvrContext, mesh, mPlayer, GVRVideoType.MONO );
        video.setName( "video" );

        // apply video to scene
        scene.addSceneObject( video );
    }

    @Override
    public void onStep() {
        GVRCameraRig cameraRig = this.getGVRContext().getMainScene().getMainCameraRig();
        GVRCameraRig nextCameraRig = this.getGVRContext().getNextMainScene().getMainCameraRig();
        float pitchX = cameraRig.getHeadTransform().getRotationPitch();
        float rollY = cameraRig.getHeadTransform().getRotationRoll();
        float yawZ = cameraRig.getHeadTransform().getRotationYaw();
       Log.d("Video", String.format("Rotation E= Pitch=%.3f, Roll=%.3f, Yaw=%.3f", pitchX, rollY, yawZ));
        float X = cameraRig.getHeadTransform().getRotationX();
        float Y = cameraRig.getHeadTransform().getRotationY();
        float Z = cameraRig.getHeadTransform().getRotationZ();
        float W = cameraRig.getHeadTransform().getRotationW();
        Log.d("Video", String.format("Rotation Q= W=%.4f, X=%.4f, Y=%.4f, Z=%.4f", W, X, Y, Z));

    }

    private final GVRVideoSceneObjectPlayer<?> mPlayer;
}
