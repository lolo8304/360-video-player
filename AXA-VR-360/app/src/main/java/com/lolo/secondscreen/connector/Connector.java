package com.lolo.secondscreen.connector;

import android.content.Context;
import android.net.nsd.NsdServiceInfo;
import android.util.Log;

import com.lolo.secondscreen.sensor_fusion.representation.Quaternion;

import org.json.JSONException;
import org.json.JSONObject;

import java.net.URI;
import java.net.URISyntaxException;
import java.util.HashMap;
import java.util.LinkedList;
import java.util.Map;
import java.util.Queue;

import static android.R.attr.data;

/**
 * Created by Lolo on 03.01.17.
 */

public abstract class Connector implements NsdServiceDelegate, SecondsScreenClientDelegate {
    private static final String TAG = "Connector";

    private static Connector singleton;

    protected Connector () {
        this.delegate = new NoConnectorDelegate();
    }
    public static Connector instance(){
        return singleton;
    }
    public static void setInstance(Connector connector) {
        singleton = connector;
    }

    public ConnectorStatus status = ConnectorStatus.Stopped;
    public ConnectorBonjourStatus bonjourStatus = ConnectorBonjourStatus.Stopped;

    private SecondScreenClient client;
    private Queue<String> messageQueue = new LinkedList<String>();

    private NsdService nsdService;
    protected ConnectorDelegate delegate;
    protected Context getContext() {
        return SecondScreenApplication.instance();
    }

    // Servers

    public void start() {
        this.startBonjour();
    }

    public void stop() {
        this.stopBonjour();
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
                this.nsdService = new NsdService(this.getContext(), this);
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


    @Override
    public void onServiceResolved(NsdServiceInfo serviceInfo) {
        if (!this.isStarted()) {
            this.connectWebSocketWith(serviceInfo.getServiceName());
        }
    }


    @Override
    public void onServiceLost(NsdServiceInfo serviceInfo) {
        if (this.client != null) {
            if (this.client.getEndPoint().equals(serviceInfo.getServiceName())) {
                this.client.close();
            }
        }
    }



    // WebSocket Services

    public boolean isStarted() {
        if (this.client != null) {
            return (this.client.isReady()
                    && (this.status == ConnectorStatus.Ready || this.status == ConnectorStatus.Connected || this.status == ConnectorStatus.Selected)
                    && this.bonjourStatus == ConnectorBonjourStatus.Ready);
        } else {
            return false;
        }
    }
    public boolean isConnected() {
        return (this.isStarted() && this.status == ConnectorStatus.Connected);
    }
    public boolean isSelected() {
        return (this.isStarted() && this.status == ConnectorStatus.Selected);
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

    public String getEndPoint() {
        return this.client != null ? this.client.getEndPoint() : "none";
    }


    protected void bufferedSendMessage(String message, boolean direct) {
        if (direct || this.isStarted()) {
            this.client.send(message);
        } else {
            this.messageQueue.add(message);
        }
    }

    @Override
    public void onMessage(final String message) {
        try {
            JSONObject messageJson = new JSONObject(message);
            String action = messageJson.getString("action");
            if (action != null) {
                Log.i(TAG, "Action received from Server: " + action);
                if (action.equals("request-connection-data")) {
                    Map<String, String> device = new HashMap<String, String>();
                    device.put("action", action);
                    device.put("ip", Device.getHostAddress());
                    String messageBack = new JSONObject(device).toString();
                    this.client.send(messageBack);
                    Log.i(TAG, "send device information on request: " + messageBack);
                }
                if (action.equals("selected")) {
                    this.changeState(ConnectorStatus.Selected);
                    this.delegate.onServerSelected();
                }
                if (action.equals("deselected")) {
                    this.changeState(ConnectorStatus.Connected);
                    this.delegate.onServerDeselected();
                }
                if (action.equals("connected")) {
                    this.changeState(ConnectorStatus.Connected);
                    this.delegate.onServerConnected();
                }
                if (action.equals("not-connected")) {
                    this.changeState(ConnectorStatus.Ready);
                }
                if (action.equals("disconnected")) {
                    this.changeState(ConnectorStatus.Ready);
                }
                if (action.equals("connection-failed")) {
                    this.delegate.onServerConnectionFailed(messageJson.getString("message"));
                    this.changeState(ConnectorStatus.Stopping);
                    this.client.close();
                }
            }
        } catch (JSONException e) {
            Log.e(TAG, "error while parsing JSON request from server", e);
        }
    }

    @Override
    public void onOpen() {
        this.startSensors();
    }

    @Override
    public void onClose(int code, String reason, boolean remote) {
        this.changeState(ConnectorStatus.Stopped);
        this.delegate.onServerClosed();
        this.client = null;
        this.stopSensors();
    }


    // Sensor Services

    public void sendMessage(String message) {
        this.client.send(message);
    }

    public void sendActionMessage(String action, Map<String, Object> data) {
        this.sendActionMessage(action, new JSONObject(data));
    }
    public void sendActionMessage(String action, JSONObject json) {
        this.sendActionMessage(action, json, false);
    }

    public void sendActionMessage(String action, JSONObject json, boolean direct) {
        try {
            json.put("action", action);
            json.put("ip", Device.getHostAddress());
            String messageBack = json.toString();
            this.bufferedSendMessage(messageBack, direct);
            this.delegate.actionMessageSent(action, json);
        } catch (JSONException e) {
            throw new RuntimeException("error while modifying JSON", e);
        }
    }
    public void sendAttributeMessage(String action, String name, String value) {
        Map<String, Object> data = new HashMap<String, Object>();
        data.put(name, value);
        this.sendActionMessage(action, data);
    }
    public void sendAction(String action) {
        Map<String, Object> data = new HashMap<String, Object>();
        this.sendActionMessage(action, data);
    }
    public void sendAttributeMessage(String action, String name, int value) {
        this.sendAttributeMessage(action, name, ""+value);
    }
    public void sendAttributeMessage(String action, String name, long value) {
        this.sendAttributeMessage(action, name, ""+value);
    }

    public void sendPositionMessage(Quaternion quaternion) {
        if (this.isSelected()) {
            if (quaternion.isValid()) {
                JSONObject message = quaternion.toJSON();
                this.sendActionMessage("position", message);
                this.delegate.positionSent(quaternion);
            }
        } else {
            this.delegate.positionNotSent(quaternion);
            //Log.d(TAG, "sensor is running, but server is in status "+this.status + " bonjourstatus "+this.bonjourStatus);
        }
    }
    public abstract void startSensors();
    public abstract  void stopSensors();




}
