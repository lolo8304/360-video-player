package com.lolo.secondscreen.connector;

/**
 * Created by Lolo on 05.01.17.
 */

public interface SecondsScreenClientDelegate {

    public void onOpen();
    public void onClose(int code, String reason, boolean remote);
    public void onMessage( String message );
}
