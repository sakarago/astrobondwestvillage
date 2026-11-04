package com.astrobond.app.ui.welcome

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.Email
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import com.astrobond.app.R
import com.astrobond.app.session.SessionViewModel
import com.astrobond.app.ui.components.*
import com.astrobond.app.ui.theme.*

private enum class WelcomeStep { LANDING, LOGIN, EMAIL, PASSWORD }

private fun validEmail(e: String) = e.trim().let { it.contains("@") && it.contains(".") && it.length >= 6 }

/** Port of Features/Welcome (landing, sign-in sheet, 2-step sign-up). Google/Apple/phone are stubs as on iOS. */
@Composable
fun WelcomeFlow(session: SessionViewModel) {
    var step by rememberSaveable { mutableStateOf(WelcomeStep.LANDING) }
    var email by rememberSaveable { mutableStateOf("") }
    var password by rememberSaveable { mutableStateOf("") }
    var working by remember { mutableStateOf(false) }
    var local by remember { mutableStateOf<String?>(null) }
    var accepted by rememberSaveable { mutableStateOf(false) }
    val error by session.error.collectAsState()

    CosmicBackdrop {
        Column(
            Modifier.fillMaxSize().statusBarsPadding().navigationBarsPadding().imePadding()
                .verticalScroll(rememberScrollState()).padding(horizontal = 28.dp, vertical = 16.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            if (step != WelcomeStep.LANDING) {
                Row(Modifier.fillMaxWidth()) {
                    IconButton(onClick = {
                        session.clearError(); local = null
                        step = when (step) { WelcomeStep.PASSWORD -> WelcomeStep.EMAIL; else -> WelcomeStep.LANDING }
                    }) { Icon(Icons.Filled.ArrowBack, null, tint = Color.White) }
                }
            }
            Spacer(Modifier.height(if (step == WelcomeStep.LANDING) 80.dp else 24.dp))
            LogoBlock()
            Spacer(Modifier.height(16.dp))
            when (step) {
                WelcomeStep.LANDING -> {
                    Text(stringResource(R.string.tagline), style = ABFont.body(12f), color = Color.White.copy(0.6f), letterSpacing = 3.sp2)
                    Spacer(Modifier.height(200.dp))
                    GlowButton(stringResource(R.string.signup), { if (accepted) step = WelcomeStep.EMAIL else local = "legal" })
                    Spacer(Modifier.height(14.dp))
                    GlowButton(stringResource(R.string.already_member), { step = WelcomeStep.LOGIN }, showSparkle = false)
                    Spacer(Modifier.height(18.dp))
                    Row(Modifier.clickable { accepted = !accepted; local = null }, verticalAlignment = Alignment.CenterVertically) {
                        CheckBadge(accepted)
                        Spacer(Modifier.width(10.dp))
                        Text(stringResource(R.string.legal_agree), style = ABFont.body(12f), color = Color.White.copy(0.6f))
                    }
                    if (local == "legal") Text(stringResource(R.string.legal_required), style = ABFont.body(12.5f), color = hex("#E8A0A0"), modifier = Modifier.padding(top = 8.dp))
                }
                WelcomeStep.LOGIN -> {
                    Text(stringResource(R.string.login_title), style = ABFont.display(24f), color = Color.White)
                    Spacer(Modifier.height(8.dp))
                    Text(stringResource(R.string.login_sub), style = ABFont.body(14f), color = Color.White.copy(0.62f))
                    Spacer(Modifier.height(24.dp))
                    GlowTextField(email, { email = it }, stringResource(R.string.email_hint), leading = Icons.Filled.Email, keyboardType = KeyboardType.Email)
                    Spacer(Modifier.height(12.dp))
                    GlowTextField(password, { password = it }, stringResource(R.string.password_hint), leading = Icons.Filled.Lock, password = true)
                    (local ?: error)?.takeIf { it != "legal" }?.let { Text(it, style = ABFont.body(13f), color = hex("#9AA0AB"), modifier = Modifier.padding(top = 10.dp)) }
                    Spacer(Modifier.height(20.dp))
                    val invalid = stringResource(R.string.invalid_login_input)
                    GlowButton(stringResource(if (working) R.string.logging_in else R.string.login), {
                        val e = email.trim().lowercase()
                        if (!(e.contains("@") && e.contains(".") && password.length >= 6)) { local = invalid } else {
                            local = null; working = true
                            session.signIn(e, password) { working = false }
                        }
                    }, enabled = !working)
                }
                WelcomeStep.EMAIL -> {
                    Text(stringResource(R.string.email_title), style = ABFont.display(24f), color = Color.White)
                    Spacer(Modifier.height(8.dp))
                    Text(stringResource(R.string.contact_sub), style = ABFont.body(14f), color = Color.White.copy(0.62f), textAlign = TextAlign.Center)
                    Spacer(Modifier.height(24.dp))
                    GlowTextField(email, { email = it }, stringResource(R.string.email_hint), leading = Icons.Filled.Email, keyboardType = KeyboardType.Email)
                    if (email.isNotEmpty()) {
                        val ok = validEmail(email)
                        Text(stringResource(if (ok) R.string.email_valid else R.string.email_invalid), style = ABFont.body(13f),
                            color = if (ok) hex("#8FD3A8") else hex("#E8A0A0"), modifier = Modifier.padding(top = 10.dp).align(Alignment.Start))
                    }
                    Spacer(Modifier.height(20.dp))
                    GlowButton(stringResource(R.string.continue_btn), { step = WelcomeStep.PASSWORD }, enabled = validEmail(email))
                }
                WelcomeStep.PASSWORD -> {
                    Text(stringResource(R.string.set_password), style = ABFont.display(24f), color = Color.White)
                    Spacer(Modifier.height(8.dp))
                    Text(stringResource(R.string.set_password_sub), style = ABFont.body(14f), color = Color.White.copy(0.62f))
                    Spacer(Modifier.height(24.dp))
                    GlowTextField(password, { password = it }, stringResource(R.string.password_hint), leading = Icons.Filled.Lock, password = true)
                    Text(stringResource(R.string.password_tip), style = ABFont.body(12.5f), color = Color.White.copy(0.5f), modifier = Modifier.padding(top = 10.dp).align(Alignment.Start))
                    error?.let { Text(it, style = ABFont.body(13f), color = hex("#E8A0A0"), modifier = Modifier.padding(top = 10.dp)) }
                    Spacer(Modifier.height(20.dp))
                    GlowButton(stringResource(R.string.signup), {
                        working = true
                        session.signUp(email.trim().lowercase(), password) { working = false }
                    }, enabled = password.length >= 6 && !working)
                }
            }
        }
    }
}

private val Int.sp2 get() = androidx.compose.ui.unit.TextUnit(this.toFloat(), androidx.compose.ui.unit.TextUnitType.Sp)
