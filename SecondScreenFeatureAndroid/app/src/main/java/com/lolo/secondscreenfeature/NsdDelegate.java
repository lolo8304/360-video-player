package com.lolo.secondscreenfeature;

import android.net.nsd.NsdServiceInfo;

/**
 * Created by Lolo on 26.12.16.
 */

public interface NsdDelegate {
    public void onServiceResolved(NsdServiceInfo serviceInfo);
    public void onServiceLost(NsdServiceInfo serviceInfo);

}
