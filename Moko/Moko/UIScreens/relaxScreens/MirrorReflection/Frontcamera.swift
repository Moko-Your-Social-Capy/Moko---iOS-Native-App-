//
//  FrontCamera.swift
//  Moko
//
//  Live front-camera preview for the camera version of Mirror Reflection.
//  SwiftUI has no built-in camera view, so this is the one place that needs
//  AVFoundation and a small UIKit wrapper. Nothing is recorded or saved.
//
//  IMPORTANT: add "Privacy - Camera Usage Description" (NSCameraUsageDescription)
//  to your target's Info tab, or the app will crash when it asks for the camera.
//

import SwiftUI
import Observation
import AVFoundation
import UIKit

// MARK: - Capture session (runs off the main thread)

/// Talks to the real camera. Starting a camera is slow, so all the work happens
/// on its own background queue and the screen never freezes.
nonisolated final class FrontCameraSession: @unchecked Sendable {
    // AVCaptureSession is Apple's object that connects the camera to the screen.
    let session = AVCaptureSession()
    // A private background "line" of work. Apple asks us to use one for camera setup.
    private let queue = DispatchQueue(label: "moko.front-camera")
    private var isConfigured = false

    /// Starts the session. `completion(false)` means no usable front camera (e.g. the simulator).
    func start(completion: @escaping @Sendable (Bool) -> Void) {
        queue.async { [self] in
            if !isConfigured {
                session.beginConfiguration()
                session.sessionPreset = .high

                guard
                    let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
                    let input = try? AVCaptureDeviceInput(device: device),
                    session.canAddInput(input)
                else {
                    session.commitConfiguration()
                    completion(false)
                    return
                }

                session.addInput(input)
                session.commitConfiguration()
                isConfigured = true
            }

            if !session.isRunning {
                session.startRunning()
            }
            completion(true)
        }
    }

    func stop() {
        queue.async { [self] in
            if session.isRunning {
                session.stopRunning()
            }
        }
    }
}

// MARK: - Permission + state for the UI

/// Asks for camera permission and tells the screen what to show.
/// `@Observable` makes the screen redraw by itself when `status` changes.
@MainActor
@Observable
final class FrontCameraModel {
    enum Status {
        case checking      // asking for permission / starting up
        case running       // preview is live
        case denied        // user said no (or it's restricted)
        case unavailable   // no front camera, e.g. the simulator
    }

    /// What the screen should show right now.
    var status: Status = .checking

    let camera = FrontCameraSession()

    func start() {
        // Has the user already said yes or no to the camera?
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            launch()
        case .notDetermined:
            Task {
                // Shows Apple's "Allow camera?" popup and waits for the answer.
                let granted = await AVCaptureDevice.requestAccess(for: .video)
                if granted {
                    launch()
                } else {
                    status = .denied
                }
            }
        default:
            status = .denied
        }
    }

    func stop() {
        camera.stop()
    }

    private func launch() {
        camera.start { success in
            Task { @MainActor in
                self.status = success ? .running : .unavailable
            }
        }
    }
}

// MARK: - Preview view

/// SwiftUI has no live camera view, so we wrap a small UIKit view.
/// `UIViewRepresentable` is the bridge that lets a UIKit view sit inside SwiftUI.
struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        view.backgroundColor = .black
        view.previewLayer?.session = session
        view.previewLayer?.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {}
}

final class CameraPreviewUIView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }

    /// The view's layer, seen as a camera layer. `layerClass` above makes this always succeed,
    /// but `as?` keeps us safe without a force cast.
    var previewLayer: AVCaptureVideoPreviewLayer? {
        layer as? AVCaptureVideoPreviewLayer
    }
}

/// Opens this app's page in the Settings app (for when camera access was denied).
func mokoOpenAppSettingsURL() -> URL? {
    URL(string: UIApplication.openSettingsURLString)
}