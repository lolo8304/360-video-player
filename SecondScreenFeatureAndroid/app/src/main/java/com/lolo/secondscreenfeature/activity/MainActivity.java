package com.lolo.secondscreenfeature.activity;

import android.os.Bundle;
import android.support.v7.app.AppCompatActivity;
import android.util.Log;
import android.view.View;
import android.widget.CheckBox;
import android.widget.TextView;

import com.lolo.secondscreenfeature.Connector;
import com.lolo.secondscreenfeature.ConnectorBonjourStatus;
import com.lolo.secondscreenfeature.ConnectorDelegate;
import com.lolo.secondscreenfeature.ConnectorStatus;
import com.lolo.secondscreenfeature.R;
import com.lolo.secondscreenfeature.SecondScreenApplication;

import org.hitlabnz.sensor_fusion_demo.representation.Quaternion;

import java.text.DecimalFormat;

public class MainActivity extends AppCompatActivity implements ConnectorDelegate {

    final static String TAG = "View";
    final static DecimalFormat f = new DecimalFormat("0.000");

    int count = 0;
    TextView logs;
    TextView endPoint;
    private TextView labelX;
    private TextView labelY;
    private TextView labelZ;
    private TextView labelW;
    private TextView labelRoll;
    private TextView labelYaw;
    private TextView labelPitch;
    private CheckBox isScreenConnected;
    private CheckBox isSensorSending;
    private CheckBox isDiscovering;

    public SecondScreenApplication getMyApplication() {
        return (SecondScreenApplication)this.getApplication();
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        this.logs = (TextView) findViewById(R.id.logs);
        this.endPoint = (TextView) findViewById(R.id.endPoint);
        this.labelX = (TextView) findViewById(R.id.X);
        this.labelY = (TextView) findViewById(R.id.Y);
        this.labelZ = (TextView) findViewById(R.id.Z);
        this.labelW = (TextView) findViewById(R.id.W);
        this.labelRoll = (TextView) findViewById(R.id.Roll);
        this.labelYaw = (TextView) findViewById(R.id.Yaw);
        this.labelPitch = (TextView) findViewById(R.id.Pitch);
        this.isScreenConnected = (CheckBox)findViewById(R.id.isScreenConnected);
        this.isSensorSending = (CheckBox)findViewById(R.id.isSensorSending);
        this.isDiscovering = (CheckBox)findViewById(R.id.isDiscovering);
        this.start();
    }

    protected void start() {
        Connector.instance().setDelegated(this);
        Connector.instance().start();
    }

    protected void stop() {
        Connector.instance().stop();
        runOnUiThread(new Runnable() {
                public void run(){
                    isScreenConnected.setSelected(false);
                }
            });
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        Connector.instance().setDelegated(null);
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
        this.start();
    }
    public void stopVideo(View v) {
        this.stop();
    }

    private String Float2String(float pos) {
        return f.format(pos);
    }
    private String Double2String(double pos) {
        return f.format(pos);
    }


    @Override
    public void endpointChanged(final String s) {
        runOnUiThread(new Runnable() {
            public void run(){
                endPoint.setText(s);
            }
        });
    }

    @Override
    public void sensorsUp() {
        if (!isSensorSending.isChecked()) {
            runOnUiThread(new Runnable() {
                public void run() {
                    isSensorSending.setChecked(true);
                }
            });
        }
    }

    @Override
    public void sensorsDown() {
        if (isSensorSending.isChecked()) {
            runOnUiThread(new Runnable() {
                public void run() {
                    isSensorSending.setChecked(false);
                }
            });
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
    public void onServerReady() {
        this.screenDown();
    }

    @Override
    public void onServerConnected() {
        this.screenUp();
    }

    @Override
    public void onServerSelected() {
        this.screenUp();
    }

    @Override
    public void onServerConnectionFailed(String message) {
        this.screenDown();
    }

    @Override
    public void onServerClosed() {
        this.screenDown();
    }

    @Override
    public void statusChanged(boolean started, final ConnectorStatus status, final ConnectorBonjourStatus bonjourStatus) {
        Log.i(TAG, "status changed now: "+status+" / "+bonjourStatus);
        this.addAppendLog(this.logs, "status changed: started="+started +", status="+status+", bonjourStatus="+bonjourStatus);
        runOnUiThread(new Runnable() {
            public void run(){
                if (bonjourStatus == ConnectorBonjourStatus.Ready) {
                    if (!isDiscovering.isChecked()) { isDiscovering.setChecked(true); }
                } else {
                    if (isDiscovering.isChecked()) { isDiscovering.setChecked(false); }
                }
            }
        });
    }

    @Override
    public void sendPosition(final Quaternion quaternion) {
        runOnUiThread(new Runnable() {
            public void run() {
                labelX.setText(Float2String(quaternion.getX()));
                labelY.setText(Float2String(quaternion.getY()));
                labelZ.setText(Float2String(quaternion.getZ()));
                labelW.setText(Float2String(quaternion.getW()));

                labelRoll.setText(Float2String(quaternion.getRollY()));
                labelPitch.setText(Float2String(quaternion.getPitchX()));
                labelYaw.setText(Float2String(quaternion.getYawZ()));
            }
        });

    }
}
