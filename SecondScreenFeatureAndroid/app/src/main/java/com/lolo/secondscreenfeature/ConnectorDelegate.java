package com.lolo.secondscreenfeature;

import org.hitlabnz.sensor_fusion_demo.representation.Quaternion;

/**
 * Created by Doris on 25.12.2016.
 */

public interface ConnectorDelegate {
    void endpointChanged(String s);

    void sensorsUp();
    void sensorsDown();

    void onServerConnectionFailed(String message);
    void onServerClosed();
    void onServerReady();
    void onServerConnected();
    void onServerSelected();

    void statusChanged(boolean started, ConnectorStatus status, ConnectorBonjourStatus bonjourStatus);

    void sendPosition(Quaternion quaternion);

}
