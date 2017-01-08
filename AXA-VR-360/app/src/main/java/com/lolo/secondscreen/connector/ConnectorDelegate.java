package com.lolo.secondscreen.connector;

import com.lolo.secondscreen.sensor_fusion.representation.Quaternion;

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

    void positionSent(Quaternion quaternion);
    void positionNotSent(Quaternion quaternion);
}
