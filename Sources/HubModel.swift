import Foundation
import Combine

/// 主視窗用的狀態，由 AppController 餵資料
final class HubModel: ObservableObject {
    enum Page: String, CaseIterable { case home, history, dictionary, settings
        var title: String { switch self { case .home: return "首頁"; case .history: return "歷史紀錄"; case .dictionary: return "詞典"; case .settings: return "設定" } }
        var icon: String { switch self { case .home: return "house"; case .history: return "clock"; case .dictionary: return "book"; case .settings: return "gearshape" } }
    }
    @Published var page: Page = .home
    @Published var hotkey: HotkeyChoice = .rightOption
    @Published var mode: Mode = .dictate
    @Published var translateTarget: String = "英文"
    @Published var language: SpeechLanguage = .auto
    @Published var refine: Bool = true
    @Published var sounds: Bool = true
    @Published var loginEnabled: Bool = false
    @Published var whisperOK = false
    @Published var whisperStatus = "未啟動"
    @Published var ollamaOK = false
    @Published var ollamaStatus = "檢查中…"
    @Published var ollamaModel = "deepseek-v4.1-flash"
    @Published var apiKeyNeeded = false
    @Published var whisperModelName = "large-v3-q5_0"
    @Published var volumeMounted = false
    @Published var appState = "待命中"
    @Published var learningHotkey = false
    @Published var micKeepAlive: MicKeepAlive = .always
    @Published var fastWhisper = false
    @Published var allowedLanguages: [String] = ["chinese", "english"]
    @Published var micStandby = false
    @Published var micName = ""
    @Published var whisperModelPresent = true
    @Published var whisperServerPresent = true
    @Published var usesImage = false
    let downloader = ModelDownloader()
    var setupNeeded: Bool { !(whisperModelPresent && whisperServerPresent && ollamaOK) }

    // 由 AppController 設定的動作
    var onSetHotkey: ((HotkeyChoice) -> Void)?
    var onLearnHotkey: (() -> Void)?
    var onSetMode: ((Mode) -> Void)?
    var onSetTarget: ((String) -> Void)?
    var onSetLanguage: ((SpeechLanguage) -> Void)?
    var onSetRefine: ((Bool) -> Void)?
    var onSetSounds: ((Bool) -> Void)?
    var onSetMicKeepAlive: ((MicKeepAlive) -> Void)?
    var onSetFastWhisper: ((Bool) -> Void)?
    var onToggleAllowedLanguage: ((String) -> Void)?
    var onToggleLogin: (() -> Void)?
    var onRestartEngines: (() -> Void)?
    var onOpenLogs: (() -> Void)?
    var onRetry: ((HistoryItem) -> Void)?
    var onDownloadWhisper: (() -> Void)?
    var onSetAPIKey: ((String) -> Void)?
    var onSetOllamaModel: ((String) -> Void)?
}
