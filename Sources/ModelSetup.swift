import Foundation
import Combine

/// 找引擎、下載模型：讓別人第一次打開就能把東西備齊
enum ModelSetup {
    static let whisperModelURL = URL(string: "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3-q5_0.bin")!
    static let whisperModelFileName = "ggml-large-v3-q5_0.bin"
    static let brewCommand = "brew install whisper-cpp"
    static let ollamaKeysURL = URL(string: "https://ollama.com/settings/keys")!

    static func findWhisperServer() -> String? {
        let fm = FileManager.default
        var candidates = [Settings.shared.whisperServerPath]
        if let bundled = Bundle.main.resourceURL?.appendingPathComponent("bin/whisper-server").path { candidates.append(bundled) }
        candidates += ["/opt/homebrew/bin/whisper-server", "/usr/local/bin/whisper-server"]
        return candidates.first { !$0.isEmpty && fm.isExecutableFile(atPath: $0) }
    }

    static var whisperModelPresent: Bool {
        let p = Settings.shared.whisperModelPath
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: p), let size = attrs[.size] as? NSNumber else { return false }
        return size.int64Value > 1_000_000_000
    }
}

/// 下載 Whisper 模型（3.1 GB），有進度
final class ModelDownloader: NSObject, ObservableObject, URLSessionDownloadDelegate {
    @Published var progress: Double = 0
    @Published var running = false
    @Published var error: String?
    var onDone: (() -> Void)?
    private var session: URLSession?
    private var destination: URL?

    func start(url: URL, to dest: URL) {
        guard !running else { return }
        destination = dest
        running = true; progress = 0; error = nil
        let s = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        session = s
        s.downloadTask(with: url).resume()
        Log.w("model download started: \(url)")
    }

    func cancel() { session?.invalidateAndCancel(); running = false }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let p = totalBytesExpectedToWrite > 0 ? Double(totalBytesWritten) / Double(totalBytesExpectedToWrite) : 0
        DispatchQueue.main.async { self.progress = p }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let dest = destination else { return }
        do {
            try FileManager.default.createDirectory(at: dest.deletingLastPathComponent(), withIntermediateDirectories: true)
            try? FileManager.default.removeItem(at: dest)
            try FileManager.default.moveItem(at: location, to: dest)
            Log.w("model download finished: \(dest.path)")
            DispatchQueue.main.async { self.running = false; self.progress = 1; self.onDone?() }
        } catch {
            DispatchQueue.main.async { self.running = false; self.error = error.localizedDescription }
        }
        session.finishTasksAndInvalidate()
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let e = error {
            Log.w("model download failed: \(e.localizedDescription)")
            DispatchQueue.main.async { self.running = false; self.error = e.localizedDescription }
        }
    }
}
