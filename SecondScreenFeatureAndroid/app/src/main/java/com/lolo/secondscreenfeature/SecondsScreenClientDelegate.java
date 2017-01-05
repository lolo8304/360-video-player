package com.lolo.secondscreenfeature;

/**
 * Created by Lolo on 05.01.17.
 */

public interface SecondsScreenClientDelegate {
    public void onMessage( String message );
    public void onClose(int code, String reason, boolean remote);

}
