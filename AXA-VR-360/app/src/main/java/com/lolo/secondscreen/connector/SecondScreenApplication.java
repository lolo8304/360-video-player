package com.lolo.secondscreen.connector;

import android.app.Application;

/**
 * Created by Doris on 25.12.2016.
 */

public class SecondScreenApplication extends Application {
    private static final String TAG = "MyApplication";

    private static SecondScreenApplication singleton;
    public static SecondScreenApplication instance(){
        return singleton;
    }

    @Override
    public void onCreate() {
        super.onCreate();
        singleton = this;
    }

}