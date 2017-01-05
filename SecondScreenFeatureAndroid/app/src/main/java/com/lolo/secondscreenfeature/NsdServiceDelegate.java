package com.lolo.secondscreenfeature;

import android.net.nsd.NsdServiceInfo;

/**
 * Created by Lolo on 26.12.16.
 */

public interface NsdServiceDelegate {
    public void onDiscoveryStarted();
    public void onDiscoveryStopped();

    public void onServiceResolved(NsdServiceInfo serviceInfo);
    public void onServiceLost(NsdServiceInfo serviceInfo);

}
