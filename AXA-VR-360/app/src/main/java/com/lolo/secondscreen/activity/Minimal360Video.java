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

package com.lolo.secondscreen.activity;

import android.util.Log;

import com.lolo.secondscreen.connector.Connector;
import com.lolo.secondscreen.connector.ConnectorBonjourStatus;
import com.lolo.secondscreen.connector.ConnectorDelegate;
import com.lolo.secondscreen.connector.ConnectorStatus;
import com.lolo.secondscreen.connector.SecondScreenApplication;
import com.lolo.secondscreen.connector.gvr.GVRConnector;
import com.lolo.secondscreen.sensor_fusion.representation.Quaternion;
import com.lolo.secondscreen.sensor_fusion.representation.Vector3f;
import com.lolo.secondscreen.sensor_fusion.representation.Vector4f;

import org.gearvrf.GVRCameraRig;
import org.gearvrf.GVRContext;
import org.gearvrf.GVRMain;
import org.gearvrf.GVRMesh;
import org.gearvrf.GVRScene;
import org.gearvrf.scene_objects.GVRSphereSceneObject;
import org.gearvrf.scene_objects.GVRVideoSceneObject;
import org.gearvrf.scene_objects.GVRVideoSceneObject.GVRVideoType;
import org.gearvrf.scene_objects.GVRVideoSceneObjectPlayer;

public class Minimal360Video extends GVRMain {

    public Minimal360Video(GVRVideoSceneObjectPlayer<?> player) {
        mPlayer = player;
    }

    /** Called when the activity is first created. */
    @Override
    public void onInit(GVRContext gvrContext) {

        GVRScene scene = gvrContext.getNextMainScene();

        // set up camerarig position (default)
        scene.getMainCameraRig().getTransform().setPosition( 0.0f, 0.0f, 0.0f );
        scene.getMainCameraRig().getTransform().rotate(1.0f, 0.0f, Quaternion.PI4, 0.0f);
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
       //Log.d("Video", String.format("Pitch / Roll / Yaw =   %3.3f  %3.3f  %3.3f", pitchX, rollY, yawZ));
        float X = cameraRig.getHeadTransform().getRotationX();
        float Y = cameraRig.getHeadTransform().getRotationY();
        float Z = cameraRig.getHeadTransform().getRotationZ();
        float W = cameraRig.getHeadTransform().getRotationW();
        //Log.d("Video", String.format("Rotation Q= W=%.4f, X=%.4f, Y=%.4f, Z=%.4f", W, X, Y, Z));

        Quaternion quaternion = new Quaternion();
        quaternion.setX(X);
        quaternion.setY(Y);
        quaternion.setZ(Z);
        quaternion.setW(W);

        float[] eulerAngles = quaternion.toEulerAngles().toArray();

        /* int screenRotation = app.getCurrentActivity().getWindowManager().getDefaultDisplay().getRotation(); */
        /* switch Roll and Pitch for iOS */
        float yawEuler = eulerAngles[1]; // pitch is turning here for yaw
        if (yawZ >= 0.0f) {
            if (yawEuler < Quaternion.PI2) {
                // pitch and roll are OK
                //no action
            } else {
                yawZ = 180 - yawZ;
                //switch pitch and roll
            }
        } else {
                if (yawEuler < -Quaternion.PI2) {
                    yawZ = -180 - yawZ;
                    //switch pitch and roll
                }
                else  {
                    // no action
                    // pitch and roll are OK
                }
        }

        quaternion.setEulerAnglesDegree(new Vector3f(rollY, pitchX, yawZ));
        Log.d("Video", String.format("Rotation Q= Pitch=%.4f (%3.0f), Roll=%.4f (%3.0f), Yaw=%.4f (%3.0f)", quaternion.getPitchX(), rollY, quaternion.getRollY(), pitchX, quaternion.getYawZ(), yawZ));
        //Log.d("Video", String.format("Rotation Q= W=%.4f, X=%.4f, Y=%.4f, Z=%.4f", W, X, Y, Z));
        //Log.d("Video", String.format("Debug Rotation %.4f %3.0f %3.4f     ---    %3.4f  %3.4f  %3.4f", quaternion.getYawZ(), yawZ, Y, eulerAngles[0], eulerAngles[1], eulerAngles[2]));
        Connector.instance().sendPositionMessage(quaternion);

    }

    private final GVRVideoSceneObjectPlayer<?> mPlayer;

}
