package com.lolo.secondscreenfeature;

import org.hitlabnz.sensor_fusion_demo.representation.Quaternion;

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
    public void sendPosition(Quaternion quaternion) {

    }
}
