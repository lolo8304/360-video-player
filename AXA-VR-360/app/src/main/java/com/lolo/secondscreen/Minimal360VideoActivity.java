/* Copyright 2015 Samsung Electronics Co., LTD
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.lolo.secondscreen;

import android.content.res.AssetFileDescriptor;
import android.media.MediaCodec;
import android.media.MediaPlayer;
import android.net.Uri;
import android.os.Bundle;
import android.os.Environment;
import android.view.Surface;

import com.google.android.exoplayer.ExoPlaybackException;
import com.google.android.exoplayer.ExoPlayer;
import com.google.android.exoplayer.MediaCodecAudioTrackRenderer;
import com.google.android.exoplayer.MediaCodecSelector;
import com.google.android.exoplayer.MediaCodecVideoTrackRenderer;
import com.google.android.exoplayer.extractor.ExtractorSampleSource;
import com.google.android.exoplayer.upstream.AssetDataSource;
import com.google.android.exoplayer.upstream.DefaultAllocator;
import com.google.android.exoplayer.upstream.FileDataSource;

import org.gearvrf.GVRActivity;
import org.gearvrf.scene_objects.GVRVideoSceneObject;
import org.gearvrf.scene_objects.GVRVideoSceneObjectPlayer;

import java.io.FileInputStream;
import java.io.IOException;

public class Minimal360VideoActivity extends GVRActivity {

    /**
     * Called when the activity is first created.
     */
    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

            videoSceneObjectPlayer = makeExoPlayer();

        if (null != videoSceneObjectPlayer) {
            final Minimal360Video main = new Minimal360Video(videoSceneObjectPlayer);
            setMain(main, "gvr.xml");
        }
    }

    @Override
    protected void onPause() {
        super.onPause();
        if (null != videoSceneObjectPlayer) {
            final Object player = videoSceneObjectPlayer.getPlayer();
            ExoPlayer exoPlayer = (ExoPlayer) player;
            exoPlayer.setPlayWhenReady(false);
        }
    }

    @Override
    protected void onResume() {
        super.onResume();
        if (null != videoSceneObjectPlayer) {
            final Object player = videoSceneObjectPlayer.getPlayer();
            ExoPlayer exoPlayer = (ExoPlayer) player;
            exoPlayer.setPlayWhenReady(true);
        }
    }

    private GVRVideoSceneObjectPlayer<ExoPlayer> makeExoPlayer() {
        final ExoPlayer player = ExoPlayer.Factory.newInstance(2);

        final AssetDataSource dataSource = new AssetDataSource(this);
        final FileDataSource fileSource = new FileDataSource();
/*        final ExtractorSampleSource sampleSource = new ExtractorSampleSource(Uri.parse("asset:///videos_s_3.mp4"),
                fileSource, new DefaultAllocator(64 * 1024), 64 * 1024 * 256); */

        String movie = "videos_s_3_test.mp4";
        movie = "DE-AXA-One_second_away-Final_v3_long_360.mp4";
        String moviePath = Environment.getExternalStorageDirectory().getPath()+"/Movies/"+movie;
        Uri uri = Uri.parse(moviePath);
        final ExtractorSampleSource sampleSource = new ExtractorSampleSource(uri,
                fileSource, new DefaultAllocator(64 * 1024), 64 * 1024 * 256);

        final MediaCodecVideoTrackRenderer videoRenderer = new MediaCodecVideoTrackRenderer(this, sampleSource,
                MediaCodecSelector.DEFAULT, MediaCodec.VIDEO_SCALING_MODE_SCALE_TO_FIT);
        final MediaCodecAudioTrackRenderer audioRenderer = new MediaCodecAudioTrackRenderer(sampleSource,
                MediaCodecSelector.DEFAULT);
        player.prepare(videoRenderer, audioRenderer);

        return new GVRVideoSceneObjectPlayer<ExoPlayer>() {
            @Override
            public ExoPlayer getPlayer() {
                return player;
            }

            @Override
            public void setSurface(final Surface surface) {
                player.addListener(new ExoPlayer.Listener() {
                    @Override
                    public void onPlayerStateChanged(boolean playWhenReady, int playbackState) {
                        switch (playbackState) {
                            case ExoPlayer.STATE_BUFFERING:
                                break;
                            case ExoPlayer.STATE_ENDED:
                                player.seekTo(0);
                                break;
                            case ExoPlayer.STATE_IDLE:
                                break;
                            case ExoPlayer.STATE_PREPARING:
                                break;
                            case ExoPlayer.STATE_READY:
                                break;
                            default:
                                break;
                        }
                    }

                    @Override
                    public void onPlayWhenReadyCommitted() {
                        surface.release();
                    }

                    @Override
                    public void onPlayerError(ExoPlaybackException error) {
                    }
                });

                player.sendMessage(videoRenderer, MediaCodecVideoTrackRenderer.MSG_SET_SURFACE, surface);
            }

            @Override
            public void release() {
                player.release();
            }

            @Override
            public boolean canReleaseSurfaceImmediately() {
                return false;
            }

            @Override
            public void pause() {
                player.setPlayWhenReady(false);
            }

            @Override
            public void start() {
                player.setPlayWhenReady(true);
            }
        };
    }


    private GVRVideoSceneObjectPlayer<?> videoSceneObjectPlayer;
}