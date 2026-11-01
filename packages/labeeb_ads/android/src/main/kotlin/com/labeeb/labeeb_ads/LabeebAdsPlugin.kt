package com.labeeb.labeeb_ads

import android.app.Activity
import android.os.Bundle
import com.google.ads.mediation.admob.AdMobAdapter
import com.google.android.gms.ads.AdError
import com.google.android.gms.ads.AdRequest
import com.google.android.gms.ads.FullScreenContentCallback
import com.google.android.gms.ads.LoadAdError
import com.google.android.gms.ads.MobileAds
import com.google.android.gms.ads.RequestConfiguration
import com.google.android.gms.ads.interstitial.InterstitialAd
import com.google.android.gms.ads.interstitial.InterstitialAdLoadCallback
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Interstitial ads for a children's app, using Google's AdMob SDK directly.
 *
 * Every request is child-directed (COPPA / Google Play Families): tagged for
 * child-directed treatment and under-age-of-consent, limited to G-rated ads,
 * and non-personalised. Nothing else from the SDK is used.
 */
class LabeebAdsPlugin : FlutterPlugin, MethodChannel.MethodCallHandler, ActivityAware {
    private lateinit var channel: MethodChannel
    private var activity: Activity? = null
    private var interstitial: InterstitialAd? = null
    private var initialized = false

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "labeeb_ads")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "initialize" -> initialize(result)
            "load" -> load(call.argument<String>("adUnitId")!!, result)
            "isLoaded" -> result.success(interstitial != null)
            "show" -> show(result)
            else -> result.notImplemented()
        }
    }

    private fun initialize(result: MethodChannel.Result) {
        val act = activity ?: return result.success(false)
        if (initialized) return result.success(true)
        MobileAds.setRequestConfiguration(
            RequestConfiguration.Builder()
                .setTagForChildDirectedTreatment(RequestConfiguration.TAG_FOR_CHILD_DIRECTED_TREATMENT_TRUE)
                .setTagForUnderAgeOfConsent(RequestConfiguration.TAG_FOR_UNDER_AGE_OF_CONSENT_TRUE)
                .setMaxAdContentRating(RequestConfiguration.MAX_AD_CONTENT_RATING_G)
                .build()
        )
        MobileAds.initialize(act) {
            initialized = true
            act.runOnUiThread { result.success(true) }
        }
    }

    private fun request(): AdRequest {
        // "npa=1": never personalised, even where the child-directed tag alone would allow less.
        val extras = Bundle().apply { putString("npa", "1") }
        return AdRequest.Builder().addNetworkExtrasBundle(AdMobAdapter::class.java, extras).build()
    }

    private fun load(adUnitId: String, result: MethodChannel.Result) {
        val act = activity ?: return result.success(false)
        if (!initialized) return result.success(false)
        InterstitialAd.load(act, adUnitId, request(), object : InterstitialAdLoadCallback() {
            override fun onAdLoaded(ad: InterstitialAd) {
                interstitial = ad
                result.success(true)
            }

            override fun onAdFailedToLoad(error: LoadAdError) {
                interstitial = null
                result.success(false)
            }
        })
    }

    /** Shows the loaded ad; completes when it is closed (true) or could not show (false). */
    private fun show(result: MethodChannel.Result) {
        val act = activity
        val ad = interstitial
        if (act == null || ad == null) return result.success(false)
        interstitial = null
        ad.fullScreenContentCallback = object : FullScreenContentCallback() {
            override fun onAdDismissedFullScreenContent() = result.success(true)
            override fun onAdFailedToShowFullScreenContent(error: AdError) = result.success(false)
        }
        ad.show(act)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }
}
