package com.lolo.secondscreenfeature;

import android.app.Application;
import android.bluetooth.BluetoothAdapter;
import android.util.Log;

import com.jaredrummler.android.device.DeviceName;

import java.net.Inet4Address;
import java.net.InetAddress;
import java.net.InetSocketAddress;
import java.net.NetworkInterface;
import java.net.SocketException;
import java.net.URI;
import java.net.URISyntaxException;
import java.util.Date;
import java.util.Enumeration;
import java.util.HashMap;
import java.util.Map;

import de.greenrobot.event.EventBus;

/**
 * Created by Doris on 25.12.2016.
 */

public class SecondScreenApplication extends Application {
    private static final String TAG = "MyApplication";
    private static final int SERVER_PORT = 12345;

    private static SecondScreenApplication singleton;
    public static SecondScreenApplication getInstance(){
        return singleton;
    }


    private SecondScreenServer mServer;
    private NsdHelper nsdHelper;

    @Override
    public void onCreate() {
        super.onCreate();
        singleton = this;
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

    public static InetAddress getInetAddress() {
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

    public Map<String, String> getDeviceId() {
        DeviceName.DeviceInfo deviceInfo = DeviceName.getDeviceInfo(SecondScreenApplication.getInstance());
        Map<String, String> headers = new HashMap<String, String>();
        headers.put("device.ip", this.getInetAddress().getHostAddress());
        headers.put("device.marketName", deviceInfo.marketName);
        headers.put("device.manufacturer", deviceInfo.manufacturer);
        headers.put("device.model", deviceInfo.model);
        BluetoothAdapter myDevice = BluetoothAdapter.getDefaultAdapter();
        String deviceName = myDevice.getName();
        headers.put("device.name", deviceName);
        return headers;
    }

    @SuppressWarnings("UnusedDeclaration")
    public void onEvent(SocketMessageEvent event) {
        String message = event.getMessage();
        Log.i(TAG, "message arrived ("+message+")");
        mServer.sendMessage("echo: " + message + ", "+ new Date());
    }

    public SecondScreenServer getServer() {
        return this.mServer;
    }

    public URI getEndPoint() throws URISyntaxException {
        return this.getServer().getEndPoint();
    }

}