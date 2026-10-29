//
//  ProfileOverViewDeleteAccountFinalConfirm.swift
//  Moko
//
//  Final confirmation for deleting an account. In the prototype this is a
//  small alert over the Delete account screen (not a full screen), so it is
//  a native SwiftUI alert.
//
//  Use it with:
//      .deleteAccountAlert(isPresented: $show) { /* delete here */ }
//

import SwiftUI

extension View {
    func deleteAccountAlert(isPresented: Binding<Bool>, onConfirm: @escaping () -> Void) -> some View {
        alert("Delete your account?", isPresented: isPresented) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive, action: onConfirm)
        } message: {
            Text("This permanently deletes your profile and history. This can’t be undone.")
        }
    }
}

#Preview {
    struct Demo: View {
        @State private var show = true
        var body: some View {
            Button("Delete") { show = true }
                .deleteAccountAlert(isPresented: $show) { }
        }
    }
    return Demo()
}
