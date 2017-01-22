package com.lolo.secondscreen.activity;

import com.google.android.exoplayer.ExoPlayer;
import com.lolo.secondscreen.connector.Connector;

import java.util.HashMap;
import java.util.Map;

/**
 * Created by Lolo on 14.01.17.
 */

public class RemotePlayer {

    private final Connector connector;
    private final ExoPlayer player;
    private String mediaName;
    private String name;
    private String language;

    public RemotePlayer(Connector connector, ExoPlayer player) {
        this.connector = connector;
        this.player = player;
    }

    public void playNamedVideo(String name) {
        this.mediaName = name;
        this.name = name;
        this.language = "DE";
        Map<String, Object> data = new HashMap<String, Object>();
        data.put("name", name);
        data.put("language", language);
        data.put("duration", this.player.getDuration());
        this.connector.sendActionMessage("player-prepare", data);
    }

    private void sendActionWithSeek(String action) {
        this.sendActionWithSeek(action, this.player.getCurrentPosition());
    }
    private void sendActionWithSeek(String action, long pos) {
        Map<String, Object> data = new HashMap<String, Object>();
        data.put("name", name);
        data.put("mediaName", mediaName);
        data.put("language", language);
        data.put("seek", pos);
        this.connector.sendActionMessage(action, data);
    }


    public void seekTo(long pos) {
        this.sendActionWithSeek("player-seek", pos);
    }
    public void start() {
        this.sendActionWithSeek("player-start");
    }
    public void pause() {
        this.sendActionWithSeek("player-pause");
    }
    public void loop() {
        this.seekTo(0);
    }
    public void stop() {
        this.sendActionWithSeek("player-stop");
    }
    public void keepAlive(long pos) {
        this.sendActionWithSeek("player-keepAlive");
    }

}
