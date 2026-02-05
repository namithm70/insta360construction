package com.insta360.insta360_sdk

import com.arashivision.sdkmedia.player.capture.InstaCapturePlayerView

object PreviewHolder {
    @Volatile
    private var previewView: InstaCapturePlayerView? = null

    fun attach(view: InstaCapturePlayerView) {
        previewView = view
    }

    fun detach(view: InstaCapturePlayerView) {
        if (previewView === view) {
            previewView = null
        }
    }

    fun current(): InstaCapturePlayerView? = previewView
}
