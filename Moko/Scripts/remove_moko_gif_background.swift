import AppKit
import CoreImage
import CoreVideo
import Foundation
import ImageIO
import Vision
import UniformTypeIdentifiers

let args = CommandLine.arguments
 guard args.count == 3 else {
    fputs("Usage: swift remove_moko_gif_background.swift input.gif output-directory\n", stderr)
    exit(2)
}
let inputURL = URL(fileURLWithPath: args[1])
let outputURL = URL(fileURLWithPath: args[2], isDirectory: true)
try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true)
guard let source = CGImageSourceCreateWithURL(inputURL as CFURL, nil) else {
    fatalError("Could not open \(inputURL.path)")
}
let count = CGImageSourceGetCount(source)
let context = CIContext(options: [.cacheIntermediates: false])
var completed = 0

for index in 0..<count {
    guard let image = CGImageSourceCreateImageAtIndex(source, index, nil) else {
        fputs("Skipping unreadable frame \(index)\n", stderr)
        continue
    }
    let handler = VNImageRequestHandler(cgImage: image, orientation: .up)
    let request = VNGenerateForegroundInstanceMaskRequest()
    try handler.perform([request])
    guard let observation = request.results?.first,
          !observation.allInstances.isEmpty else {
        fputs("No foreground instances found in frame \(index)\n", stderr)
        continue
    }
    let maskBuffer = try observation.generateScaledMaskForImage(
        forInstances: observation.allInstances,
        from: handler
    )
    let inputImage = CIImage(cgImage: image)
    let mask = CIImage(cvPixelBuffer: maskBuffer)
    let transparent = CIImage(color: .clear).cropped(to: inputImage.extent)
    guard let blend = CIFilter(name: "CIBlendWithMask") else { fatalError("Missing Core Image mask filter") }
    blend.setValue(inputImage, forKey: kCIInputImageKey)
    blend.setValue(transparent, forKey: kCIInputBackgroundImageKey)
    blend.setValue(mask, forKey: kCIInputMaskImageKey)
    guard let output = blend.outputImage?.cropped(to: inputImage.extent),
          let rendered = context.createCGImage(output, from: inputImage.extent) else {
        fputs("Could not composite frame \(index)\n", stderr)
        continue
    }
    let frameURL = outputURL.appendingPathComponent(String(format: "frame-%02d.png", index))
    guard let destination = CGImageDestinationCreateWithURL(frameURL as CFURL, UTType.png.identifier as CFString, 1, nil) else {
        fatalError("Could not write \(frameURL.path)")
    }
    CGImageDestinationAddImage(destination, rendered, nil)
    guard CGImageDestinationFinalize(destination) else { fatalError("Could not finalize frame \(index)") }
    completed += 1
}
print("Wrote \(completed)/\(count) transparent frames to \(outputURL.path)")
