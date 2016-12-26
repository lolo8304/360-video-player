package com.lolo.secondscreenfeature;

import android.app.Application;
import android.util.Log;

import java.net.Inet4Address;
import java.net.InetAddress;
import java.net.InetSocketAddress;
import java.net.NetworkInterface;
import java.net.SocketException;
import java.net.URI;
import java.net.URISyntaxException;
import java.util.Date;
import java.util.Enumeration;

import de.greenrobot.event.EventBus;

/**
 * Created by Doris on 25.12.2016.
 */

public class SecondScreenApplication extends Application {
    private static final String TAG = "MyApplication";
    private static final int SERVER_PORT = 12345;

    private SecondScreenServer mServer;
    private NsdHelper nsdHelper;

    @Override
    public void onCreate() {
        super.onCreate();
    }

    private void startServer() {
        InetAddress inetAddress = getInetAddress();
        if (inetAddress == null) {
            Log.e(TAG, "Unable to lookup IP address");
            return;
        }

        EventBus.getDefault().register(this);
        mServer = new SecondScreenServer(new InetSocketAddress(inetAddress.getHostAddress(), SERVER_PORT));
        mServer.start();
    }

    private static InetAddress getInetAddress() {
        try {
            for (Enumeration en = NetworkInterface.getNetworkInterfaces(); en.hasMoreElements();) {
                NetworkInterface networkInterface = (NetworkInterface) en.nextElement();

                for (Enumeration enumIpAddr = networkInterface.getInetAddresses(); enumIpAddr.hasMoreElements();) {
                    InetAddress inetAddress = (InetAddress) enumIpAddr.nextElement();

                    if (!inetAddress.isLoopbackAddress() && inetAddress instanceof Inet4Address) {
                        return inetAddress;
                    }
                }
            }
        } catch (SocketException e) {
            e.printStackTrace();
            Log.e(TAG, "Error getting the network interface information");
        }

        return null;
    }

    @SuppressWarnings("UnusedDeclaration")
    public void onEvent(SocketMessageEvent event) {
        String message = event.getMessage();
        Log.i(TAG, "message arrived ("+message+")");
//        mServer.sendMessage("echo: " + message + ", "+ new Date());
    }

    public SecondScreenServer getServer() {
        return this.mServer;
    }

    public URI getEndPoint() throws URISyntaxException {
        return this.getServer().getEndPoint();
    }
    public URI getClientEndPoint() throws URISyntaxException {
        return new URI("ws://192.168.0.243:12345");
    }
}