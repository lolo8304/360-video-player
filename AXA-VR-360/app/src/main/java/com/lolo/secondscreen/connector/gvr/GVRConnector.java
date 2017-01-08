package com.lolo.secondscreen.connector.gvr;

import android.hardware.SensorManager;

import com.lolo.secondscreen.connector.Connector;
import com.lolo.secondscreen.connector.ConnectorDelegate;
import com.lolo.secondscreen.sensor_fusion.HardwareChecker;
import com.lolo.secondscreen.sensor_fusion.SensorChecker;
import com.lolo.secondscreen.sensor_fusion.orientationProvider.ImprovedOrientationSensor1Provider;
import com.lolo.secondscreen.sensor_fusion.representation.Quaternion;

/**
 * Created by Lolo on 05.01.17.
 */

public class GVRConnector extends Connector  {

    public static Connector activate() {
        Connector.setInstance(new GVRConnector());
        Connector.instance().start();
        return Connector.instance();
    }
    private GVRConnector() {
    }

    public void startSensors() {
    }
    public void stopSensors() {
    }

    @Override
    public void sendPositionMessage(Quaternion quaternion) {
        super.sendPositionMessage(quaternion);
    }
}
