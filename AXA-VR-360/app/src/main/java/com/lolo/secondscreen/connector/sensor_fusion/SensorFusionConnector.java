package com.lolo.secondscreen.connector.sensor_fusion;

import android.app.AlertDialog;
import android.content.Context;
import android.content.DialogInterface;
import android.hardware.SensorManager;
import android.util.Log;

import com.lolo.secondscreen.connector.Connector;
import com.lolo.secondscreen.sensor_fusion.HardwareChecker;
import com.lolo.secondscreen.sensor_fusion.SensorChecker;
import com.lolo.secondscreen.sensor_fusion.orientationProvider.ImprovedOrientationSensor1Provider;
import com.lolo.secondscreen.sensor_fusion.orientationProvider.OrientationProvider;
import com.lolo.secondscreen.sensor_fusion.orientationProvider.OrientationProviderDelegate;
import com.lolo.secondscreen.sensor_fusion.representation.Quaternion;

/**
 * Created by Lolo on 05.01.17.
 */

public class SensorFusionConnector extends Connector implements OrientationProviderDelegate {
    private static final String TAG = "SensorConnector";

    private OrientationProvider currentOrientationProvider;

    public static Connector activate() {
        Connector.setInstance(new SensorFusionConnector());
        Connector.instance().start();
        return Connector.instance();
    }
    private SensorFusionConnector() {
    }

    private void displayWarning(String text) {
        AlertDialog ad = new AlertDialog.Builder(this.getContext()).create();
        ad.setCancelable(false); // This blocks the 'BACK' button
        ad.setMessage(text);
        ad.setButton(DialogInterface.BUTTON_NEUTRAL, "OK", new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialog, int which) {
                dialog.dismiss();
            }
        });
        ad.show();
    }

    public void startSensors() {
        // Check if device has a hardware gyroscope
        SensorChecker checker = new HardwareChecker(this.getSystemService());
        if(!checker.IsGyroscopeAvailable()) {
            // If a gyroscope is unavailable, display a warning.
            displayWarning("gyroscop missing");
        }
//            this.currentOrientationProvider = new GravityCompassProvider((SensorManager) this.getSystemService());
        this.currentOrientationProvider = new ImprovedOrientationSensor1Provider((SensorManager) this.getSystemService());
//        this.currentOrientationProvider = new CalibratedGyroscopeProvider((SensorManager) this.getSystemService());

        this.currentOrientationProvider.delegate = this;
        this.currentOrientationProvider.start();

    }
    public void stopSensors() {
        if (this.currentOrientationProvider != null) {
            this.currentOrientationProvider.stop();
            this.currentOrientationProvider = null;
        }
        this.delegate.sensorsDown();
    }

    private SensorManager getSystemService() {
        return (SensorManager) this.getContext().getSystemService(Context.SENSOR_SERVICE);
    }

    @Override
    public void onSensorChanged() {
        this.delegate.sensorsUp();
        final Quaternion quaternion = new Quaternion();
        this.currentOrientationProvider.getQuaternion(quaternion);
        this.sendPositionMessage(quaternion);
    }

}
