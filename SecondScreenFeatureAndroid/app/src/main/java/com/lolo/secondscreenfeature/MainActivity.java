package com.lolo.secondscreenfeature;

import android.app.AlertDialog;
import android.content.DialogInterface;
import android.hardware.SensorManager;
import android.net.nsd.NsdServiceInfo;
import android.os.Bundle;
import android.support.v7.app.AppCompatActivity;
import android.util.Log;
import android.view.View;
import android.widget.CheckBox;
import android.widget.TextView;

import org.hitlabnz.sensor_fusion_demo.HardwareChecker;
import org.hitlabnz.sensor_fusion_demo.SensorChecker;
import org.hitlabnz.sensor_fusion_demo.orientationProvider.CalibratedGyroscopeProvider;
import org.hitlabnz.sensor_fusion_demo.orientationProvider.ImprovedOrientationSensor1Provider;
import org.hitlabnz.sensor_fusion_demo.orientationProvider.OrientationProvider;
import org.hitlabnz.sensor_fusion_demo.orientationProvider.OrientationProviderDelegate;
import org.hitlabnz.sensor_fusion_demo.representation.Quaternion;
import org.java_websocket.framing.CloseFrame;
import org.json.JSONException;
import org.json.JSONObject;

import java.net.URI;
import java.net.URISyntaxException;
import java.text.DecimalFormat;
import java.text.Format;
import java.util.Formatter;
import java.util.HashMap;
import java.util.Map;

import static org.java_websocket.WebSocket.READYSTATE.NOT_YET_CONNECTED;
import static org.java_websocket.WebSocket.READYSTATE.OPEN;

public class MainActivity extends AppCompatActivity implements MessageDelegate, OrientationProviderDelegate, NsdDelegate {

    final static DecimalFormat f = new DecimalFormat("#.000");

    /**
     * The current orientation provider that delivers device orientation.
     */
    private OrientationProvider currentOrientationProvider;

    SecondScreenClient client;
    NsdHelper nsdHelper;

    int count = 0;
    TextView logs;
    TextView endPoint;
    private TextView labelX;
    private TextView labelY;
    private TextView labelZ;
    private TextView labelW;
    private CheckBox isScreenConnected;
    private CheckBox isSensorSending;

    public SecondScreenApplication getMyApplication() {
        return (SecondScreenApplication)this.getApplication();
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        // Check if device has a hardware gyroscope
        SensorChecker checker = new HardwareChecker((SensorManager) getSystemService(SENSOR_SERVICE));
        if(!checker.IsGyroscopeAvailable()) {
            // If a gyroscope is unavailable, display a warning.
            displayWarning("gyroscop missing");
        }

        setContentView(R.layout.activity_main);
        this.logs = (TextView) findViewById(R.id.logs);
        this.endPoint = (TextView) findViewById(R.id.endPoint);
        this.labelX = (TextView) findViewById(R.id.X);
        this.labelY = (TextView) findViewById(R.id.Y);
        this.labelZ = (TextView) findViewById(R.id.Z);
        this.labelW = (TextView) findViewById(R.id.W);
        this.isScreenConnected = (CheckBox)findViewById(R.id.isScreenConnected);
        this.isSensorSending = (CheckBox)findViewById(R.id.isSensorSending);
        this.start();
    }

    protected void start() {
        try {
            if (this.nsdHelper == null) {
                this.nsdHelper = new NsdHelper(this, this);
                this.nsdHelper.initializeNsd();
                this.nsdHelper.discoverServices();
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    protected void stop() {
        if (this.currentOrientationProvider != null) {
            this.currentOrientationProvider.stop();
            this.currentOrientationProvider = null;
            this.sensorsDown();
        }
        if (this.client != null) {
            this.client.close();
            this.client = null;
            runOnUiThread(new Runnable() {
                public void run(){
                    isScreenConnected.setSelected(false);
                }
            });
        }
        /*
        if (this.nsdHelper != null) {
            this.nsdHelper.stopDiscovery();
            this.nsdHelper = null;
        }
        */
        this.updateEndPoint("none");

    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        this.stop();
    }

    private void displayWarning(String text) {
        AlertDialog ad = new AlertDialog.Builder(this).create();
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

    private void addAppendLog(final TextView textView, final String newMessage) {
        runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    textView.setText(newMessage);
                }
            });
    }

    public void startVideo(View v) {
        if (this.client == null) {
            this.start();
        }
    }
    public void stopVideo(View v) {
        if (this.client != null) {
            this.stop();
        }
    }

    @Override
    public void onClose(int code, String reason, boolean remote) {
        Log.e("View", "close webSocket");
        this.screenDown();

    }

    @Override
    public void onMessage(final String message) {
        try {
            JSONObject messageJson = new JSONObject(message);
            String action = messageJson.getString("action");
            if (action != null && action.equals("request-connection-data")) {
                Map<String, String> device = new HashMap<String, String>();
                device.put("action", action);
                device.put("ip", SecondScreenApplication.getInetAddress().getHostAddress());
                String messageBack = new JSONObject(device).toString();
                this.client.send(messageBack);
                Log.e("View", "send device information on request: "+messageBack);
            }
        } catch (JSONException e) {
            Log.e("View", "error while parsing JSON request from server", e);
        }

        runOnUiThread(new Runnable() {
            public void run(){
                addAppendLog(logs, message);
            }
        });
    }

    private void updateEndPoint(final String uri) {
        runOnUiThread(new Runnable() {
            public void run(){
                endPoint.setText(uri);
            }
        });
    }

    private void sensorsUp() {
        if (!isSensorSending.isChecked()) {
            runOnUiThread(new Runnable() {
                public void run() {
                    isSensorSending.setChecked(true);
                }
            });
        }
    }
    private void sensorsDown() {
        if (isSensorSending.isChecked()) {
            runOnUiThread(new Runnable() {
                public void run() {
                    isSensorSending.setChecked(false);
                }
            });
        }
    }
    private void updateRotationStatus(String message) {
    }

    private String Float2String(float pos) {
        return f.format(pos);
    }

    @Override
    public void onSensorChanged() {
        this.sensorsUp();
        final Quaternion quaternion = new Quaternion();
        this.currentOrientationProvider.getQuaternion(quaternion);
        String message = quaternion.toJSONString();
        if (this.client != null) {
            if (this.client.getReadyState() == OPEN) {
                screenUp();
                this.client.send(message);
                runOnUiThread(new Runnable() {
                    public void run() {
                        /*
                        labelX.setText(Float2String(quaternion.getX()));
                        labelY.setText(Float2String(quaternion.getY()));
                        labelZ.setText(Float2String(quaternion.getZ()));
                        labelW.setText(Float2String(quaternion.getW()));
                        */
                        double[] rollPitchYaw = quaternion.toEulerAngles();

                        labelX.setText(Float2String(quaternion.));
                        labelY.setText(Float2String(quaternion.getY()));
                        labelZ.setText(Float2String(quaternion.getZ()));
                    }
                });

                //this.addAppendLog(this.logs, "sent: " + message);
            } else {
                this.addAppendLog(this.logs, "not open yet / "+this.client.getReadyState()+": "+message);
                screenDown();
            }
        } else {
            screenDown();
        }
    }

    private void screenDown() {
        if (isScreenConnected.isChecked()) {
            runOnUiThread(new Runnable() {
                public void run() {
                    isScreenConnected.setChecked(false);
                }
            });
        }
    }

    private void screenUp() {
        if (!isScreenConnected.isChecked()) {
            runOnUiThread(new Runnable() {
                public void run() {
                    isScreenConnected.setChecked(true);
                }
            });
        }
    }

    @Override
    public void onServiceResolved(NsdServiceInfo serviceInfo) {
        try {
            this.addAppendLog(this.logs, "service resolved and connect to "+serviceInfo.getServiceName());
            URI uri = new URI(serviceInfo.getServiceName());
            this.updateEndPoint(uri.toString());
            this.client = SecondScreenClient.create(uri);
            this.client.delegate = this;
            this.client.connect();

            this.currentOrientationProvider = new ImprovedOrientationSensor1Provider((SensorManager) this.getSystemService(this.SENSOR_SERVICE));
//            this.currentOrientationProvider = new CalibratedGyroscopeProvider((SensorManager) this.getSystemService(this.SENSOR_SERVICE));
            this.currentOrientationProvider.delegate = this;
            this.currentOrientationProvider.start();
            this.addAppendLog(this.logs, "sensors started");
        } catch (URISyntaxException e) {
            e.printStackTrace();
        }

    }

    @Override
    public void onServiceLost(NsdServiceInfo serviceInfo) {
        this.addAppendLog(this.logs, "service lost from "+serviceInfo.getServiceName());
        Log.i("View", "service lost from "+serviceInfo.getServiceName());
        this.stop();
    }

}
