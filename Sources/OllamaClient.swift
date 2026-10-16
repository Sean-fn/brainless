import Foundation

/// 跟 Ollama Cloud 講話（潤稿模型由設定決定）。
final class OllamaClient {
    enum Status: Equatable {
        case checking
        case noKey
        case badKey
        case unreachable(String)
        case modelMissing
        case ready
    }
    private let settings = Settings.shared

    private var base: URL { URL(string: settings.ollamaURL)! }
    /// 送給目前模型的 thinking 參數（/api/show 查到的）；nil 代表不送、用模型預設。只在主執行緒讀寫。
    private var think: Any?

    /// 先用 /api/usage 驗 API key（不花 token；/api/tags 和 /api/show 是公開的，key 錯也回 200），
    /// 再用 /api/show 確認模型存在、查它的 thinking 選項。
    func checkStatus(_ cb: @escaping (Status) -> Void) {
        let key = CloudKey.read()
        guard !key.isEmpty else { DispatchQueue.main.async { cb(.noKey) }; return }
        var usage = URLComponents(url: base.appendingPathComponent("api/usage"), resolvingAgainstBaseURL: false)!
        usage.queryItems = [URLQueryItem(name: "range", value: "24h")]
        var req = URLRequest(url: usage.url!)
        req.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        req.timeoutInterval = 5
        URLSession.shared.dataTask(with: req) { _, resp, err in
            let code = (resp as? HTTPURLResponse)?.statusCode ?? 0
            if let err = err {
                DispatchQueue.main.async { cb(.unreachable(err.localizedDescription)) }
            } else if code == 401 || code == 403 {
                DispatchQueue.main.async { cb(.badKey) }
            } else if code != 200 {
                DispatchQueue.main.async { cb(.unreachable("HTTP \(code)")) }
            } else {
                self.checkModel(key: key, cb)
            }
        }.resume()
    }

    private func checkModel(key: String, _ cb: @escaping (Status) -> Void) {
        var req = URLRequest(url: base.appendingPathComponent("api/show"))
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        req.httpBody = try? JSONSerialization.data(withJSONObject: ["model": settings.ollamaModel])
        req.timeoutInterval = 5
        URLSession.shared.dataTask(with: req) { data, resp, err in
            let code = (resp as? HTTPURLResponse)?.statusCode ?? 0
            let info = data.flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] }
            DispatchQueue.main.async {
                if let err = err { cb(.unreachable(err.localizedDescription)); return }
                if code == 404 { cb(.modelMissing); return }
                guard code == 200, let info = info else { cb(.unreachable("HTTP \(code)")); return }
                self.think = OllamaClient.lowestThink(info["thinking"] as? [String: Any])
                cb(.ready)
            }
        }.resume()
    }

    /// thinking 能關就關（false），不能關就用最低等級；模型沒有 thinking 選項就不送
    static func lowestThink(_ thinking: [String: Any]?) -> Any? {
        guard let values = thinking?["values"] as? [Any] else { return nil }
        if values.contains(where: { ($0 as? Bool) == false }) { return false }
        let levels = values.compactMap { $0 as? String }
        if levels.contains("low") { return "low" }
        return levels.first
    }

    func chat(system: String, user: String, completion: @escaping (Swift.Result<String, Error>) -> Void) {
        var req = URLRequest(url: base.appendingPathComponent("api/chat"))
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(CloudKey.read())", forHTTPHeaderField: "Authorization")
        var payload: [String: Any] = [
            "model": settings.ollamaModel,
            "stream": false,
            "messages": [
                ["role": "system", "content": system],
                ["role": "user", "content": user],
            ],
            "options": ["temperature": 0.2, "num_predict": 2048],
        ]
        if let think = think { payload["think"] = think }
        req.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        req.timeoutInterval = 90
        let t0 = Date()
        URLSession.shared.dataTask(with: req) { data, resp, err in
            if let err = err { completion(.failure(err)); return }
            guard let data = data else {
                completion(.failure(NSError(domain: "Whispry", code: 10, userInfo: [NSLocalizedDescriptionKey: "Ollama 沒有回應"])))
                return
            }
            if let http = resp as? HTTPURLResponse, http.statusCode != 200 {
                let msg = String(data: data, encoding: .utf8) ?? ""
                completion(.failure(NSError(domain: "Whispry", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: "Ollama 回傳 \(http.statusCode)：\(msg.prefix(200))"])))
                return
            }
            guard let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let msg = obj["message"] as? [String: Any],
                  var content = msg["content"] as? String else {
                completion(.failure(NSError(domain: "Whispry", code: 11, userInfo: [NSLocalizedDescriptionKey: "Ollama 回傳格式看不懂"])))
                return
            }
            // 萬一模型還是吐出思考段落，去掉
            if let r = content.range(of: "</think>") { content = String(content[r.upperBound...]) }
            content = content.trimmingCharacters(in: .whitespacesAndNewlines)
            for (l, r) in [("「", "」"), ("\"", "\""), ("“", "”"), ("『", "』")] {
                if content.hasPrefix(l) && content.hasSuffix(r) && content.count > 2 {
                    content = String(content.dropFirst().dropLast()).trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
            for prefix in ["整理後：", "潤稿：", "譯文：", "結果："] {
                if content.hasPrefix(prefix) { content = String(content.dropFirst(prefix.count)).trimmingCharacters(in: .whitespacesAndNewlines) }
            }
            Log.w("ollama ok in \(String(format: "%.1f", Date().timeIntervalSince(t0)))s, \(content.count) chars")
            completion(.success(content))
        }.resume()
    }
}
