package com.lolo.secondscreenfeature;

/**
 * Created by Doris on 25.12.2016.
 */

public interface MessageDelegate {
    public void onMessage( String message );
    public void onClose(int code, String reason, boolean remote);
}
