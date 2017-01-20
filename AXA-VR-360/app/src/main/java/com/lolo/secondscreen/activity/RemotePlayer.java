package com.lolo.secondscreen.activity;

import com.google.android.exoplayer.ExoPlayer;
import com.lolo.secondscreen.connector.Connector;

/**
 * Created by Lolo on 14.01.17.
 */

public class RemotePlayer {

    private final Connector connector;
    private final ExoPlayer player;

    public RemotePlayer(Connector connector, ExoPlayer player) {
        this.connector = connector;
        this.player = player;
    }

    public void playNamedVideo(String name) {
        this.connector.sendAttributeMessage("video-prepare", "name", name);
    }
    public void seekTo(long pos) {
        this.connector.sendAttributeMessage("video-seek", "seek", pos);
    }
    public void start() {
        this.connector.sendAttributeMessage("video-start", "seek", this.player.getCurrentPosition());
    }
    public void pause() {
        this.connector.sendAction("video-pause");
    }
    public void loop() {
        this.seekTo(0);
    }
    public void stop() {
        this.connector.sendAction("video-stop");
    }
    public void keepAlive(long pos) {
        this.connector.sendAttributeMessage("video-keepAlive", "seek", pos);
    }

}
