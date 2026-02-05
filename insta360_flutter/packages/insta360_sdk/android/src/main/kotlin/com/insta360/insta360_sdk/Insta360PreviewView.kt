package com.insta360.insta360_sdk

import android.content.Context
import android.view.View
import android.view.ViewGroup
import androidx.lifecycle.LifecycleOwner
import com.arashivision.sdkcamera.camera.InstaCameraManager
import com.arashivision.sdkmedia.player.capture.InstaCapturePlayerView
import com.arashivision.sdkmedia.player.listener.PlayerViewListener
import io.flutter.plugin.platform.PlatformView

class Insta360PreviewView(private val context: Context) : PlatformView {
    private val playerView: InstaCapturePlayerView = InstaCapturePlayerView(context).apply {
        layoutParams = ViewGroup.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.MATCH_PARENT
        )
        (context as? LifecycleOwner)?.let { setLifecycle(it.lifecycle) }
    }

    init {
        playerView.setPlayerViewListener(object : PlayerViewListener {
            override fun onLoadingFinish() {
                InstaCameraManager.getInstance().setPipeline(playerView.pipeline)
            }

            override fun onReleaseCameraPipeline() {
                InstaCameraManager.getInstance().setPipeline(null)
            }
        })
        PreviewHolder.attach(playerView)
    }

    override fun getView(): View = playerView

    override fun dispose() {
        PreviewHolder.detach(playerView)
        playerView.destroy()
    }
}
