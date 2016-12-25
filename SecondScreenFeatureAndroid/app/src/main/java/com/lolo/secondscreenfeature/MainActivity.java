package com.lolo.secondscreenfeature;

import android.app.AlertDialog;
import android.content.DialogInterface;
import android.hardware.SensorManager;
import android.os.Bundle;
import android.support.v7.app.AppCompatActivity;
import android.util.Log;
import android.view.View;
import android.widget.TextView;

import org.hitlabnz.sensor_fusion_demo.HardwareChecker;
import org.hitlabnz.sensor_fusion_demo.SensorChecker;
import org.hitlabnz.sensor_fusion_demo.orientationProvider.ImprovedOrientationSensor1Provider;
import org.hitlabnz.sensor_fusion_demo.orientationProvider.OrientationProvider;
import org.hitlabnz.sensor_fusion_demo.orientationProvider.OrientationProviderDelegate;
import org.hitlabnz.sensor_fusion_demo.representation.Quaternion;

import java.net.URISyntaxException;

public class MainActivity extends AppCompatActivity implements MessageDelegate, OrientationProviderDelegate {

    /**
     * The current orientation provider that delivers device orientation.
     */
    private OrientationProvider currentOrientationProvider;

    SecondScreenClient client;
    int count = 0;
    TextView logs;
    TextView endPoint;

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
        this.logs = (TextView) findViewById(R.id.sent);
        this.endPoint = (TextView) findViewById(R.id.endPoint);
        try {
            this.endPoint.setText(this.getMyApplication().getEndPoint().toString());
            this.client = new SecondScreenClient(this.getMyApplication().getEndPoint());
            this.client.delegate = this;
            this.client.connect();

            this.currentOrientationProvider = new ImprovedOrientationSensor1Provider((SensorManager) this.getSystemService(this.SENSOR_SERVICE));
            this.currentOrientationProvider.delegate = this;
            this.currentOrientationProvider.start();
            this.addAppendLog(this.logs, "sensors started");
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        if (this.currentOrientationProvider != null) {
            this.currentOrientationProvider.stop();
        }
        if (this.client != null) {
            this.client.close();
        }
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

    private void addAppendLog(TextView textView, String newMessage) {
        count++;
        if (count >= 30) {
            textView.setText(newMessage);
            count = 0;
        } else {
            textView.setText(newMessage + "\n" + textView.getText());
        }
    }

    public void onClickTest(View v) {
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

    @Override
    public void onSensorChanged() {
        Quaternion quaternion = new Quaternion();
        this.currentOrientationProvider.getQuaternion(quaternion);
        String message = quaternion.toString();
        this.client.send(message);
        this.addAppendLog(this.logs, "sent: "+message);
    }
}
