package com.lolo.secondscreenfeature;

import android.util.Log;

import org.java_websocket.WebSocket;
import org.java_websocket.handshake.ClientHandshake;
import org.java_websocket.server.WebSocketServer;

import java.io.IOException;
import java.net.InetAddress;
import java.net.InetSocketAddress;
import java.net.URI;
import java.net.URISyntaxException;

import de.greenrobot.event.EventBus;

/**
 * Created by Doris on 25.12.2016.
 */

public class SecondScreenServer extends WebSocketServer {
    private static final String TAG = "SecondScreenServer";

    private WebSocket mSocket;
    private InetSocketAddress address;


    public SecondScreenServer(InetSocketAddress address) {
        super(address);
        this.address = address;
        Log.i(TAG, "init "+address);
    }
    public InetSocketAddress getAddress() {
        return this.address;
    }

    public URI getEndPoint() throws URISyntaxException {
        return new URI("ws:/"+this.getAddress());
    }

    @Override
    public void onOpen(WebSocket conn, ClientHandshake handshake) {
        mSocket = conn;
        Log.i(TAG, "opened");
    }

    @Override
    public void onClose(WebSocket conn, int code, String reason, boolean remote) {
        Log.i(TAG, "onClose received (code="+code+", reason="+reason+", remote="+remote+")");
    }

    @Override
    public void onMessage(WebSocket conn, String message) {
        Log.i(TAG, "message="+message);
        EventBus.getDefault().post(new SocketMessageEvent(message));
    }

    @Override
    public void onError(WebSocket conn, Exception ex) {
        Log.e(TAG, "onError received", ex);
    }

    public void sendMessage(String message) {
        mSocket.send(message);
    }


}