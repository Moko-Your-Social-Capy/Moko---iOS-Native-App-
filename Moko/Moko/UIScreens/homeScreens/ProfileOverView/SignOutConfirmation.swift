//
//  ProfileOverViewSignOutConfirmation.swift
//  Moko
//
//  Sign out confirmation. In the prototype this is a small alert over the
//  Settings screen (not a full screen), so it is a native SwiftUI alert.
//
//  Use it on Settings:
//      .signOutAlert(isPresented: $showSignOut) { /* sign out here */ }
//

import SwiftUI

extension View {
    func signOutAlert(isPresented: Binding<Bool>, onConfirm: @escaping () -> Void) -> some View {
        alert("Sign out of MOKO?", isPresented: isPresented) {
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
