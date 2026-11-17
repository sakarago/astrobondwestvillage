// SupabaseCredentials.swift
// Anon/public key only — RLS protects data. Never put service_role here.

import Foundation

enum AuthRedirect {
    /// HTTPS page in the reset email. Mail apps keep this link; the page then opens the app.
    static let reset = URL(string: "https://eseeeljxpjbyizutbmij.supabase.co/functions/v1/reset-redirect")!
    /// Where that page sends the phone after Supabase verifies the email.
    static let appCallback = URL(string: "astrobond://reset-password")!
}

enum SupabaseCredentials {
    static let urlString = "https://eseeeljxpjbyizutbmij.supabase.co"
    static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVzZWVlbGp4cGpieWl6dXRibWlqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODUzMTcxNTAsImV4cCI6MjEwMDg5MzE1MH0.az9Lf6ycaea1jiZ6JXfi6dmWtSN49WQOiBdqI1bwmNI"
}
