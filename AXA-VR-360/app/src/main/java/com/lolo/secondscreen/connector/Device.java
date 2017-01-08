package com.lolo.secondscreen.connector;

import android.bluetooth.BluetoothAdapter;
import android.util.Log;

import com.jaredrummler.android.device.DeviceName;

import java.net.Inet4Address;
import java.net.InetAddress;
import java.net.NetworkInterface;
import java.net.SocketException;
import java.util.Enumeration;
import java.util.HashMap;
import java.util.Map;

/**
 * Created by Lolo on 03.01.17.
 */

public class Device {

    private static final String TAG = "Device";
    private static int maxId = 0;

    private int id;
    private Connector connector;
    private String uuid;
    private String ip;
    private String name;
    private String marketName;
    private String manufacturer;
    private String model;
    private DeviceStatus status;

    public static Device me() {
        Device device = new Device(Connector.instance());
        device.initMe();
        return device;
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
            Log.e(Device.TAG, "Error getting the network interface information");
        }

        return null;
    }
    public static String getHostAddress() {
        return Device.getInetAddress().getHostAddress();
    }


    private void initMe() {
        DeviceName.DeviceInfo deviceInfo = DeviceName.getDeviceInfo(SecondScreenApplication.instance());
        this.setIp(Device.getHostAddress());
        this.setMarketName(deviceInfo.marketName);
        this.setManufacturer(deviceInfo.manufacturer);
        this.setModel(deviceInfo.model);
        BluetoothAdapter myDevice = BluetoothAdapter.getDefaultAdapter();
        String deviceName = myDevice.getName();
        this.setName(deviceName);
    }

    private Device (Connector connector) {
        super();
        this.connector = connector;
    }
    public Map<String,String> getWebSocketHeaders() {
        Map<String, String> headers = new HashMap<String, String>();
        headers.put("device.ip", this.getIp());
        headers.put("device.marketName", this.getMarketName());
        headers.put("device.manufacturer", this.getManufacturer());
        headers.put("device.model", this.getModel());
        headers.put("device.name", this.getName());
        return headers;
    }

    public String getUuid() {
        return uuid;
    }

    public void setUuid(String uuid) {
        this.uuid = uuid;
    }

    public String getIp() {
        return ip;
    }

    public void setIp(String ip) {
        this.ip = ip;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getMarketName() {
        return marketName;
    }

    public void setMarketName(String marketName) {
        this.marketName = marketName;
    }

    public String getManufacturer() {
        return manufacturer;
    }

    public void setManufacturer(String manufacturer) {
        this.manufacturer = manufacturer;
    }

    public String getModel() {
        return model;
    }

    public void setModel(String model) {
        this.model = model;
    }


    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public Connector getConnector() {
        return connector;
    }

    public void setConnector(Connector connector) {
        this.connector = connector;
    }
}
