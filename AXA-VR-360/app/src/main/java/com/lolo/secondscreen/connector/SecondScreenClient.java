
package com.lolo.secondscreen.connector;

import android.util.Log;

import org.java_websocket.WebSocket;
import org.java_websocket.client.WebSocketClient;
import org.java_websocket.drafts.Draft;
import org.java_websocket.drafts.Draft_17;
import org.java_websocket.handshake.ServerHandshake;

import java.net.URI;
import java.util.Map;

/**
 * Created by Doris on 25.12.2016.
 */

public class SecondScreenClient extends WebSocketClient {
    private static final String TAG = "SecondScreenClient";

    private SecondsScreenClientDelegate delegate;

    public static SecondScreenClient create(SecondsScreenClientDelegate delegate, URI serverURI) {
        SecondScreenClient client = new SecondScreenClient(serverURI, new Draft_17(), Device.me().getWebSocketHeaders(), 0);
        client.delegate = delegate;
        return client;
    }

    protected SecondScreenClient(URI serverUri , Draft draft , Map<String,String> headers , int connecttimeout ) {
        super(serverUri, draft, headers, connecttimeout);
    }

    @Override
    public void close() {
        this.send("{\"action\":\"disconnect\"}");
        super.close();
    }

    public boolean isReady() {
        return this.getConnection().getReadyState() == WebSocket.READYSTATE.OPEN;
    }

    @Override
    public void onMessage( String message ) {
        this.delegate.onMessage(message);
    }

    @Override
    public void onOpen( ServerHandshake handshake ) {
        Log.i(TAG, "onOpen");
        this.delegate.onOpen();
    }

    @Override
    public void onClose( int code, String reason, boolean remote ) {
        Log.i(TAG, "onClose");
        this.delegate.onClose(code, reason, remote);
    }

    @Override
    public void onError( Exception ex ) {
        Log.e(TAG, "onError", ex);
    }

    public String getEndPoint() {
        return this.getURI().toString();
    }
}
