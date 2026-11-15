//
//  SignOutConfirmation.swift
//  Moko
//
//  The "Sign out of Moko?" alert, as a reusable modifier.
//
//  Use it on any screen:
//      .signOutAlert(isPresented: $showSignOut) { /* sign out here */ }
//

import SwiftUI

extension View {
    /// Shows the sign-out alert while `isPresented` is true. `onConfirm` runs when the user taps "Sign out".
    func signOutAlert(isPresented: Binding<Bool>, onConfirm: @escaping () -> Void) -> some View {
        alert("Sign out of Moko?", isPresented: isPresented) {
            Button("Cancel", role: .cancel) { }
            Button("Sign out", action: onConfirm)
        } message: {
            Text("Your data stays saved. You can sign back in any time.")
        }
    }
}

#Preview {
    struct Demo: View {
        @State private var show = true
        var body: some View {
            Button("Sign out") { show = true }
                .signOutAlert(isPresented: $show) { }
        }
    }
    return Demo()
}
