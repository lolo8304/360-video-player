package com.lolo.secondscreen.connector;

import com.lolo.secondscreen.sensor_fusion.representation.Quaternion;

import org.json.JSONObject;

import java.util.Map;

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
    void onServerDeselected();

    void statusChanged(boolean started, ConnectorStatus status, ConnectorBonjourStatus bonjourStatus);

    void positionSent(Quaternion quaternion);
    void positionNotSent(Quaternion quaternion);

    void actionMessageSent(String action, Map<String, Object> data);
    void actionMessageSent(String action, JSONObject data);

}
