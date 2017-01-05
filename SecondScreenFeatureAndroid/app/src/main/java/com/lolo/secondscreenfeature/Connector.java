package com.lolo.secondscreenfeature;

import android.app.AlertDialog;
import android.content.Context;
import android.content.DialogInterface;
import android.hardware.SensorManager;
import android.net.nsd.NsdServiceInfo;
import android.util.Log;

import org.hitlabnz.sensor_fusion_demo.HardwareChecker;
import org.hitlabnz.sensor_fusion_demo.SensorChecker;
import org.hitlabnz.sensor_fusion_demo.orientationProvider.CalibratedGyroscopeProvider;
import org.hitlabnz.sensor_fusion_demo.orientationProvider.ImprovedOrientationSensor1Provider;
import org.hitlabnz.sensor_fusion_demo.orientationProvider.OrientationProvider;
import org.hitlabnz.sensor_fusion_demo.orientationProvider.OrientationProviderDelegate;
import org.hitlabnz.sensor_fusion_demo.representation.Quaternion;
import org.hitlabnz.sensor_fusion_demo.representation.Vector3f;
import org.json.JSONException;
import org.json.JSONObject;

import java.net.URI;
import java.net.URISyntaxException;
import java.util.HashMap;
import java.util.Map;

import static org.java_websocket.WebSocket.READYSTATE.OPEN;

/**
 * Created by Lolo on 03.01.17.
 */

public class Connector implements NsdDelegate, OrientationProviderDelegate, SecondsScreenClientDelegate {
    private static final String TAG = "Connector";

    private static Connector singleton = new Connector();
    private Connector () {
        this.delegate = new NoConnectorDelegate();
    }
    public static Connector instance(){
        return singleton;
    }

    public ConnectorStatus status = ConnectorStatus.Stopped;
    public ConnectorBonjourStatus bonjourStatus = ConnectorBonjourStatus.Stopped;

    private OrientationProvider currentOrientationProvider;
    private SecondScreenClient client;
    private NsdHelper nsdService;

    protected ConnectorDelegate delegate;

    private Context getContext() {
        return SecondScreenApplication.instance();
    }

    // Servers

    public void start() {
        this.startSensors();
        this.startBonjour();
    }

    public void stop() {
        this.stopBonjour();
        this.stopSensors();
        if (this.client != null) {
            this.client.close();
        }
    }

    public void setDelegated(ConnectorDelegate delegate) {
        if (delegate == null) {
            this.delegate = new NoConnectorDelegate();
        } else {
            this.delegate = delegate;
        }
    }

    // Bonjour Services

    protected void startBonjour() {
        try {
            if (this.nsdService == null) {
                this.bonjourStatus = ConnectorBonjourStatus.Starting;
                this.nsdService = new NsdHelper(this.getContext(), this);
                this.nsdService.initializeNsd();
                this.nsdService.discoverServices();
            }
        } catch (Exception e) {
            Log.e(TAG, "Error while starting NSD Service", e);
            this.stopBonjour();
        }
    }
    protected void stopBonjour() {
        this.bonjourStatus = ConnectorBonjourStatus.Stopping;
        if (this.nsdService != null) {
            this.nsdService.stopDiscovery();
            this.nsdService = null;
        } else {
            this.bonjourStatus = ConnectorBonjourStatus.Stopped;
        }
    }

    @Override
    public void onDiscoveryStarted() {
        this.bonjourStatus = ConnectorBonjourStatus.Ready;
    }

    @Override
    public void onDiscoveryStopped() {
        this.bonjourStatus = ConnectorBonjourStatus.Stopped;
    }

    // WebSocket Services

    public boolean isStarted() {
        return (this.status == ConnectorStatus.Ready || this.status == ConnectorStatus.Connected) && this.bonjourStatus == ConnectorBonjourStatus.Ready;
    }
    public boolean isConnected() {
        return (this.status == ConnectorStatus.Connected) && this.bonjourStatus == ConnectorBonjourStatus.Ready;
    }

    private void statusChanged() {
        this.delegate.statusChanged(this.isStarted(), this.status, this.bonjourStatus);
    }
    private void changeState(ConnectorStatus status) {
        this.status = status;
        this.statusChanged();
    }
    private void changeState(ConnectorBonjourStatus bonjourStatus) {
        this.bonjourStatus = bonjourStatus;
        this.statusChanged();
    }

    @Override
    public void onServiceResolved(NsdServiceInfo serviceInfo) {
        this.connectWebSocketWith(serviceInfo.getServiceName());
    }

    protected void connectWebSocketWith(String endPoint) {
        try {
            this.changeState(ConnectorStatus.Starting);
            URI uri = new URI(endPoint);
            this.client = SecondScreenClient.create(this, uri);
            this.client.connect();
            this.delegate.endpointChanged(uri.toString());
        } catch (URISyntaxException e) {
            e.printStackTrace();
        }

    }

    @Override
    public void onServiceLost(NsdServiceInfo serviceInfo) {
    }


    @Override
    public void onMessage(final String message) {
        try {
            JSONObject messageJson = new JSONObject(message);
            String action = messageJson.getString("action");
            if (action != null && action.equals("request-connection-data")) {
                Map<String, String> device = new HashMap<String, String>();
                device.put("action", action);
                device.put("ip", Device.getHostAddress());
                String messageBack = new JSONObject(device).toString();
                this.client.send(messageBack);
                Log.i(TAG, "send device information on request: "+messageBack);
            }
            if (action != null && action.equals("selected")) {
                this.changeState(ConnectorStatus.Selected);
                this.delegate.onServerSelected();
            }
            if (action != null && action.equals("connected")) {
                this.changeState(ConnectorStatus.Connected);
                this.delegate.onServerConnected();
            }
            if (action != null && action.equals("not-connected")) {
                this.changeState(ConnectorStatus.Ready);
            }
            if (action != null && action.equals("connection-failed")) {
                this.delegate.onServerConnectionFailed(messageJson.getString("message"));
                this.changeState(ConnectorStatus.Stopping);
                this.client.close();
            }
        } catch (JSONException e) {
            Log.e(TAG, "error while parsing JSON request from server", e);
        }
    }

    @Override
    public void onClose(int code, String reason, boolean remote) {
        this.changeState(ConnectorStatus.Stopped);
        this.delegate.onServerClosed();
        this.client = null;
    }


    // Sensor Services

    private SensorManager getSystemService() {
        return (SensorManager) this.getContext().getSystemService(Context.SENSOR_SERVICE);
    }

    protected void startSensors() {
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
    protected  void stopSensors() {
        if (this.currentOrientationProvider != null) {
            this.currentOrientationProvider.stop();
            this.currentOrientationProvider = null;
            this.delegate.sensorsDown();
        }
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

    @Override
    public void onSensorChanged() {
        this.delegate.sensorsUp();
        if (this.isStarted() && this.isConnected()) {
            final Quaternion quaternion = new Quaternion();
            this.currentOrientationProvider.getQuaternion(quaternion);
            String message = quaternion.toJSONString();
            if (quaternion.isValid()) {
                this.client.send(message);
                this.delegate.sendPosition(quaternion);
            }
            //this.addAppendLog(this.logs, "sent: " + message);
        }
    }


}
