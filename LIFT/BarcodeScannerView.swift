//
//  BarcodeScannerView.swift
//  LIFT
//
//  Created for LIFT.
//

import SwiftUI
import AVFoundation

struct BarcodeScannerView: View {
    @Environment(\.presentationMode) private var presentationMode
    var onBarcodeScanned: (String) -> Void
    
    @State private var isCameraAvailable = true
    @State private var cameraPermissionStatus: AVAuthorizationStatus = .notDetermined
    @State private var simulationQuery = ""
    
    // Preset barcodes for simulator testing
    private let testBarcodes = [
        ("Saffron Road Chicken Nuggets", "857063002201"),
        ("Tasty Brands Nuggets", "10852777007136"),
        ("Meijer Chicken Nuggets", "713733572064"),
        ("Coca Cola 12oz", "012000000133")
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.backgroundGradient.ignoresSafeArea()
                
                #if targetEnvironment(simulator)
                simulatorFallbackView
                #else
                if !isCameraAvailable {
                    simulatorFallbackView
                } else {
                    switch cameraPermissionStatus {
                    case .authorized:
                        scannerActiveView
                    case .denied, .restricted:
                        permissionDeniedView
                    case .notDetermined:
                        Color.black.ignoresSafeArea()
                            .onAppear {
                                requestCameraPermission()
                            }
                    @unknown default:
                        permissionDeniedView
                    }
                }
                #endif
            }
            .navigationTitle("Scan Barcode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.gray)
                }
            }
            .onAppear {
                checkCameraAvailability()
            }
        }
    }
    
    private var scannerActiveView: some View {
        ZStack {
            CameraScannerRepresentable(onBarcodeScanned: { barcode in
                handleBarcodeFound(barcode)
            })
            .ignoresSafeArea()
            
            // Scanner Overlay
            VStack {
                Spacer()
                
                // Scanning Box
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Theme.neonCyan, lineWidth: 3)
                        .frame(width: 280, height: 160)
                        .shadow(color: Theme.neonCyan.opacity(0.5), radius: 10)
                    
                    // Scanning line animation
                    ScanningLineView()
                }
                
                Spacer()
                
                Text("Align barcode inside the box to scan")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(20)
                    .padding(.bottom, 40)
            }
        }
    }
    
    private var permissionDeniedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.badge.ellipsis")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("Camera Access Required")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("LIFT needs camera permission to scan product barcodes. Please enable camera access in iOS Settings.")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
            
            Button(action: {
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            }) {
                Text("OPEN SETTINGS")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 24)
                    .background(Theme.neonCyan)
                    .cornerRadius(10)
            }
        }
        .padding()
    }
    
    private var simulatorFallbackView: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Image(systemName: "camera.fill.badge.gearshape")
                        .font(.system(size: 50))
                        .foregroundColor(Theme.neonCyan)
                        .padding(.top, 20)
                    
                    Text("Simulator / Camera Unavailable")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("Test barcode lookup by entering a UPC/EAN below, or tap one of our pre-configured simulator test products.")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                
                // Manual simulator input
                VStack(alignment: .leading, spacing: 8) {
                    Text("SIMULATED BARCODE INPUT")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.gray)
                    
                    HStack {
                        TextField("", text: $simulationQuery, prompt: Text("e.g. 857063002201").foregroundColor(.white.opacity(0.4)))
                            .keyboardType(.numberPad)
                            .padding()
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(10)
                            .foregroundColor(.white)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.1), lineWidth: 1))
                        
                        Button(action: {
                            let clean = simulationQuery.trimmingCharacters(in: .whitespacesAndNewlines)
                            if !clean.isEmpty {
                                handleBarcodeFound(clean)
                            }
                        }) {
                            Text("SIMULATE")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                                .padding()
                                .background(Theme.neonCyan)
                                .cornerRadius(10)
                        }
                        .disabled(simulationQuery.isEmpty)
                    }
                }
                .padding(.horizontal)
                
                // Presets
                VStack(alignment: .leading, spacing: 12) {
                    Text("TAP A PRODUCT TO SIMULATE SCAN")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                    
                    ForEach(testBarcodes, id: \.1) { name, code in
                        Button(action: {
                            handleBarcodeFound(code)
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(name)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                    Text("UPC: \(code)")
                                        .font(.system(size: 10))
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                                Image(systemName: "barcode")
                                    .foregroundColor(Theme.neonCyan)
                            }
                            .padding()
                            .background(Color.white.opacity(0.03))
                            .cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.05), lineWidth: 1))
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
    }
    
    private func checkCameraAvailability() {
        cameraPermissionStatus = AVCaptureDevice.authorizationStatus(for: .video)
        
        #if targetEnvironment(simulator)
        isCameraAvailable = false
        #else
        if AVCaptureDevice.default(for: .video) == nil {
            isCameraAvailable = false
        }
        #endif
    }
    
    private func requestCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                self.cameraPermissionStatus = granted ? .authorized : .denied
            }
        }
    }
    
    private func handleBarcodeFound(_ barcode: String) {
        onBarcodeScanned(barcode)
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Scanning Line Animation
struct ScanningLineView: View {
    @State private var moveDown = false
    
    var body: some View {
        Rectangle()
            .fill(Theme.neonCyan)
            .frame(width: 260, height: 2)
            .shadow(color: Theme.neonCyan, radius: 4)
            .offset(y: moveDown ? 70 : -70)
            .animation(
                .easeInOut(duration: 2.0)
                .repeatForever(autoreverses: true),
                value: moveDown
            )
            .onAppear {
                moveDown = true
            }
    }
}

// MARK: - Camera Representable
struct CameraScannerRepresentable: UIViewControllerRepresentable {
    var onBarcodeScanned: (String) -> Void
    
    func makeUIViewController(context: Context) -> CameraScannerViewController {
        let controller = CameraScannerViewController()
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: CameraScannerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, CameraScannerDelegate {
        let parent: CameraScannerRepresentable
        
        init(_ parent: CameraScannerRepresentable) {
            self.parent = parent
        }
        
        func cameraScanner(_ scanner: CameraScannerViewController, didDetectBarcode barcode: String) {
            parent.onBarcodeScanned(barcode)
        }
    }
}

protocol CameraScannerDelegate: AnyObject {
    func cameraScanner(_ scanner: CameraScannerViewController, didDetectBarcode barcode: String)
}

class CameraScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    weak var delegate: CameraScannerDelegate?
    var captureSession: AVCaptureSession?
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupCaptureSession()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if captureSession?.isRunning == false {
            DispatchQueue.global(qos: .background).async {
                self.captureSession?.startRunning()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if captureSession?.isRunning == true {
            captureSession?.stopRunning()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.layer.bounds
    }
    
    private func setupCaptureSession() {
        let session = AVCaptureSession()
        self.captureSession = session
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        
        let videoInput: AVCaptureDeviceInput
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }
        
        if session.canAddInput(videoInput) {
            session.addInput(videoInput)
        } else {
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            // Support standard barcode metadata types
            metadataOutput.metadataObjectTypes = [
                .ean8,
                .ean13,
                .pdf417,
                .upce,
                .code128,
                .code39,
                .code93,
                .aztec,
                .qr
            ]
        } else {
            return
        }
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        self.previewLayer = previewLayer
        
        DispatchQueue.global(qos: .background).async {
            session.startRunning()
        }
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            
            // Provide gentle haptic feedback on successful scan
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            captureSession?.stopRunning()
            delegate?.cameraScanner(self, didDetectBarcode: stringValue)
        }
    }
}
