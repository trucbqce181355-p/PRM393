package com.example.traicay

import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

class MainActivity : FlutterActivity() {
    private val alias = "fruitopia_auth_session_v1"

    private fun sessionKey(): SecretKey {
        val store = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
        (store.getKey(alias, null) as? SecretKey)?.let { return it }
        return KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore").apply {
            init(KeyGenParameterSpec.Builder(alias,
                KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT)
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setKeySize(256)
                .build())
        }.generateKey()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val preferences = getSharedPreferences("fruitopia_secure_session", MODE_PRIVATE)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "fruitopia/secure_session")
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "write" -> {
                            val token = call.argument<String>("token")
                            require(token != null && token.isNotEmpty() && token.length <= 256)
                            val cipher = Cipher.getInstance("AES/GCM/NoPadding")
                            cipher.init(Cipher.ENCRYPT_MODE, sessionKey())
                            val ciphertext = cipher.doFinal(token.toByteArray(Charsets.UTF_8))
                            val value = Base64.encodeToString(cipher.iv, Base64.NO_WRAP) + ":" +
                                Base64.encodeToString(ciphertext, Base64.NO_WRAP)
                            check(preferences.edit().putString("session", value).commit())
                            result.success(null)
                        }
                        "read" -> {
                            val value = preferences.getString("session", null)
                            if (value == null) {
                                result.success(null)
                            } else {
                                val parts = value.split(":")
                                require(parts.size == 2)
                                val cipher = Cipher.getInstance("AES/GCM/NoPadding")
                                cipher.init(Cipher.DECRYPT_MODE, sessionKey(),
                                    GCMParameterSpec(128, Base64.decode(parts[0], Base64.NO_WRAP)))
                                result.success(String(cipher.doFinal(
                                    Base64.decode(parts[1], Base64.NO_WRAP)), Charsets.UTF_8))
                            }
                        }
                        "delete" -> {
                            check(preferences.edit().remove("session").commit())
                            result.success(null)
                        }
                        else -> result.notImplemented()
                    }
                } catch (error: Exception) {
                    result.error("secure_session", "Cannot access secure session storage.", null)
                }
            }
    }
}