package com.lolo.secondscreen.connector;

import com.lolo.secondscreen.sensor_fusion.representation.Quaternion;

import java.util.Map;

/**
 * Created by Lolo on 05.01.17.
 */

public class NoConnectorDelegate implements ConnectorDelegate {
    @Override
    public void endpointChanged(String s) {

    }

    @Override
    public void sensorsUp() {

    }

    @Override
    public void sensorsDown() {

    }

    @Override
    public void onServerReady() {

    }

    @Override
    public void onServerConnected() {

    }

    @Override
    public void onServerSelected() {

    }

    @Override
    public void onServerConnectionFailed(String message) {

    }

    @Override
    public void onServerClosed() {

    }

    @Override
    public void statusChanged(boolean started, ConnectorStatus status, ConnectorBonjourStatus bonjourStatus) {

    }

    @Override
    public void positionSent(Quaternion quaternion) {

    }

    @Override
    public void positionNotSent(Quaternion quaternion) {

    }

    @Override
    public void actionMessageSent(String action, Map<String, String> data) {

    }
}
