package com.lolo.secondscreenfeature;

/**
 * Created by Doris on 25.12.2016.
 */

public class SocketMessageEvent {
    private String mMessage;

    public SocketMessageEvent(String message) {
        mMessage = message;
    }

    public String getMessage() {
        return mMessage;
    }
}
