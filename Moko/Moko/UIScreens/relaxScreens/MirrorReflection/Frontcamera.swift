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
import Combine // ObservableObject and @Published live here
import AVFoundation
import UIKit

// MARK: - Capture session (runs off the main thread)
nonisolated final class FrontCameraSession: @unchecked Sendable {
    let session = AVCaptureSession()
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
@MainActor
final class FrontCameraModel: ObservableObject {
    enum Status {
        case checking      // asking for permission / starting up
        case running       // preview is live
        case denied        // user said no (or it's restricted)
        case unavailable   // no front camera, e.g. the simulator
    }

    @Published var status: Status = .checking

    let camera = FrontCameraSession()

    func start() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            launch()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                Task { @MainActor in
                    if granted {
                        self.launch()
                    } else {
                        self.status = .denied
                    }
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
struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        view.backgroundColor = .black
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {}
}

final class CameraPreviewUIView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }

    var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
}

/// Opens this app's page in the Settings app (for when camera access was denied).
func mokoOpenAppSettingsURL() -> URL? {
    URL(string: UIApplication.openSettingsURLString)
}