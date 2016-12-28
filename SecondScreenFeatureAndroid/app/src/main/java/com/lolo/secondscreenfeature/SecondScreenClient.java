
package com.lolo.secondscreenfeature;

import android.bluetooth.BluetoothAdapter;
import android.provider.Settings;
import android.util.Log;

import com.jaredrummler.android.device.DeviceName;

import org.java_websocket.client.WebSocketClient;
import org.java_websocket.drafts.Draft;
import org.java_websocket.drafts.Draft_17;
import org.java_websocket.handshake.ServerHandshake;

import java.net.URI;
import java.util.HashMap;
import java.util.Map;

/**
 * Created by Doris on 25.12.2016.
 */

public class SecondScreenClient extends WebSocketClient {
    private static final String TAG = "SecondScreenClient";
    public MessageDelegate delegate;

    public static SecondScreenClient create(URI serverURI) {
        return new SecondScreenClient(serverURI, new Draft_17(), SecondScreenApplication.getInstance().getDeviceId(), 0);
    }

    protected SecondScreenClient(URI serverUri , Draft draft , Map<String,String> headers , int connecttimeout ) {
        super(serverUri, draft, headers, connecttimeout);
    }


        @Override
    public void onMessage( String message ) {
        if (this.delegate != null) {
            this.delegate.onMessage(message);
        }
    }

    @Override
    public void onOpen( ServerHandshake handshake ) {
        Log.i(TAG, "onOpen");
    }

    @Override
    public void onClose( int code, String reason, boolean remote ) {
        Log.i(TAG, "onClose code="+code+", reason="+reason+", remote="+remote);
    }

    @Override
    public void onError( Exception ex ) {
        Log.e(TAG, "onError", ex);
    }
}
