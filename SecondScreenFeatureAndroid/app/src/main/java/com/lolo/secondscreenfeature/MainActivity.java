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
import org.hitlabnz.sensor_fusion_demo.orientationProvider.ImprovedOrientationSensor1Provider;
import org.hitlabnz.sensor_fusion_demo.orientationProvider.OrientationProvider;
import org.hitlabnz.sensor_fusion_demo.orientationProvider.OrientationProviderDelegate;
import org.hitlabnz.sensor_fusion_demo.representation.Quaternion;

import java.net.URI;
import java.net.URISyntaxException;

import static org.java_websocket.WebSocket.READYSTATE.NOT_YET_CONNECTED;
import static org.java_websocket.WebSocket.READYSTATE.OPEN;

public class MainActivity extends AppCompatActivity implements MessageDelegate, OrientationProviderDelegate, NsdDelegate {

    /**
     * The current orientation provider that delivers device orientation.
     */
    private OrientationProvider currentOrientationProvider;

    SecondScreenClient client;

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
        try {
            NsdHelper nsdHelper = new NsdHelper(this, this);
            nsdHelper.initializeNsd();
            nsdHelper.discoverServices();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    protected void stop() {
        if (this.currentOrientationProvider != null) {
            this.currentOrientationProvider.stop();
            this.sensorsDown();
        }
        if (this.client != null) {
            this.client.close();
            runOnUiThread(new Runnable() {
                public void run(){
                    isSensorSending.setSelected(false);
                }
            });

        }
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
        count++;
        if (count >= 10) {
            runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    textView.setText(newMessage);
                }
            });
            count = 0;
        } else {
            //textView.setText(newMessage + "\n" + textView.getText());
        }
    }

    public void startVideo(View v) {
        try {
            String message = "hello world";
            this.client.send(message);
            this.addAppendLog(this.logs, "sent: "+message);
        } catch (Exception e) {
            Log.e("View", "error while sending", e);
        }
    }
    public void stopVideo(View v) {
        try {
            String message = "hello world";
            this.client.send(message);
            this.addAppendLog(this.logs, "sent: "+message);
        } catch (Exception e) {
            Log.e("View", "error while sending", e);
        }
    }

    @Override
    public void onMessage(final String message) {
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

    @Override
    public void onSensorChanged() {
        this.sensorsUp();
        Quaternion quaternion = new Quaternion();
        this.currentOrientationProvider.getQuaternion(quaternion);
        String message = quaternion.toString();
        if (this.client != null) {
            if (this.client.getReadyState() == OPEN) {
                screenUp();
                this.client.send(message);
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
            this.client = new SecondScreenClient(uri);
            this.client.delegate = this;
            this.client.connectBlocking();

            this.currentOrientationProvider = new ImprovedOrientationSensor1Provider((SensorManager) this.getSystemService(this.SENSOR_SERVICE));
            this.currentOrientationProvider.delegate = this;
            this.currentOrientationProvider.start();
            this.addAppendLog(this.logs, "sensors started");

        } catch (URISyntaxException e) {
        } catch (InterruptedException e) {
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
