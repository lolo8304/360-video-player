
package com.lolo.secondscreenfeature;

import android.util.Log;

import org.java_websocket.client.WebSocketClient;
import org.java_websocket.drafts.Draft;
import org.java_websocket.drafts.Draft_17;
import org.java_websocket.handshake.ServerHandshake;

import java.net.URI;

/**
 * Created by Doris on 25.12.2016.
 */

public class SecondScreenClient extends WebSocketClient {
    private static final String TAG = "SecondScreenClient";
    public MessageDelegate delegate;

    public SecondScreenClient(URI serverURI) {
        this(serverURI, new Draft_17());
    }
    public SecondScreenClient( URI serverUri , Draft draft ) {
        super(serverUri, draft);
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
