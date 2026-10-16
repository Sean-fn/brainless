# Brainless Cloud

**說話，不要打字。** 這是 [Brainless](https://github.com/austin17022/brainless) 的雲端潤稿版本：按一下快捷鍵說話，再按一下，整理好的文字就出現在游標那裡。語音辨識在這台 Mac 上跑（Whisper large-v3 Q5，whisper.cpp，Metal）；潤稿用 Ollama Cloud。錄音不會離開你的電腦，只有辨識出來的文字會送去潤稿。

可以和原版 Brainless 同時安裝：設定、權限、歷史紀錄、詞典都分開。

[English below](#english)

![Brainless 主視窗](docs/hub.png)

## 和原版的差別

| | Brainless（原版） | Brainless Cloud |
|---|---|---|
| 語音辨識 | Whisper large-v3（3.1 GB） | Whisper large-v3 Q5（1.1 GB） |
| 潤稿 | 本機 Ollama + qwen3.5:9b（約 7.6 GB） | Ollama Cloud，預設 `deepseek-v4.1-flash` |
| 記憶體 | 16 GB 以上 | 8 GB 以上 |
| 網路 | 不需要 | 潤稿時需要 |
| Bundle ID | `app.whispry.mac` | `app.whispry.mac.cloud` |
| 資料夾 | `Whispry` | `BrainlessCloud` |
| whisper-server 埠 | 8178 | 8179 |

## 它會做什麼

- **聽寫**：口語變成乾淨的文字，去掉「嗯」「那個」，補標點，簡體自動轉繁體。
- **翻譯**：說中文，貼出英文、日文或韓文。
- **問任何事**：先選一段文字，再用說的下指令（改客氣一點、縮短、翻成英文），結果直接取代選取的文字。
- **詞典**：把常講的專有名詞、人名、公司名放進去，辨識和潤稿會優先用這些寫法。
- **歷史紀錄**：每次聽寫的結果都在本機，可複製、重新潤稿、刪除。
- 任何 App 都能用（透過剪貼簿貼上，貼完會把原本的剪貼簿還原）。

## 需求

- Apple Silicon Mac，macOS 14 以上，記憶體 8 GB 以上。
- 一個麥克風（Mac mini 沒有內建）。
- 硬碟空間約 1.1 GB（Whisper large-v3 Q5 模型）。
- 網路和一個 Ollama 帳號，到 [ollama.com/settings/keys](https://ollama.com/settings/keys) 建立 API key。Free 方案只能用部分入門模型（例如 `gemma4:31b`）；預設的 `deepseek-v4.1-flash` 可能要先儲值 credits 或訂閱，見 [ollama.com/pricing](https://ollama.com/pricing)。

## 安裝

1. 自己編譯（見下方「自己編譯」）；或到這個 repo 的 Actions 頁面，從最新一次成功的 Build 下載 `BrainlessCloud` artifact，解壓縮兩次。把 `Brainless Cloud.app` 拖進「應用程式」。
2. 第一次打開：在 Finder 對 Brainless Cloud.app **按右鍵 › 打開**（這個版本沒有 Apple 開發者簽章，直接雙擊會被擋）。從 Actions 下載的版本如果還是打不開，在終端機執行 `xattr -dr com.apple.quarantine "/Applications/Brainless Cloud.app"`。
3. 依照系統提示允許**麥克風**，並到 系統設定 › 隱私權與安全性 › **輔助使用** 打開 Brainless Cloud。權限和原版分開，要再授權一次。
4. 主視窗會列出還缺什麼：
   - 安裝 whisper.cpp：在終端機執行 `brew install whisper-cpp`（需要 [Homebrew](https://brew.sh)）。
   - 按「下載 Whisper 模型」（1.1 GB）。
   - 在「Ollama Cloud」那一列貼上 API key，按「儲存」。API key 存在 macOS 鑰匙圈。
5. 三個燈都綠了，游標點到任何可以打字的地方，按一下快捷鍵（預設右 Option），說話，再按一下。

## 快捷鍵

預設右 Option（Windows 鍵盤上是右邊的 Alt）。設定頁可以改成右 Command、右 Control、Fn、F18、F19，或按「自訂」然後按下任何你想用的鍵。按一下開始、再按一下結束；按住說完放開也可以；說話中按 Esc 取消。

和原版 Brainless 同時開著時，兩個 App 會同時反應同一個快捷鍵。請把其中一個改成別的鍵。

## 麥克風保持喚醒

USB 麥克風閒置幾分鐘就會被 macOS 休眠，醒來的前兩三秒是靜音。設定頁的「麥克風保持喚醒」預設「一直開著」，隨按隨有聲音；代價是選單列會有橘色麥克風點（沒按快捷鍵時不存、不送任何聲音）。可以改成「用完後再撐 10 分鐘」或「用完就關」。

## 潤稿模型（Ollama Cloud）

- 預設 `deepseek-v4.1-flash`。設定頁 › 模型 可以改成 [ollama.com/search?c=cloud](https://ollama.com/search?c=cloud) 列出的其他模型。
- thinking 會拖慢潤稿。App 會用 `/api/show` 查模型的 thinking 選項：能關就關；關不掉的就用最低等級（例如 `glm-5.3-flash` 最低只能到 `low`）。
- 費用按 token 計算，價格見 [ollama.com/pricing](https://ollama.com/pricing)。
- 沒有網路、API key 無效或額度用完時：聽寫模式直接貼上未潤稿的原文，並顯示原因；翻譯和問任何事會失敗。

## 模型放哪裡

預設在 `~/Library/Application Support/BrainlessCloud/models/`。硬碟不夠的話，可以把模型放在外接硬碟上的 APFS 磁碟映像裡（exFAT 硬碟直接放會很不穩），在終端機設定：

```
defaults write app.whispry.mac.cloud modelImagePath -string "/Volumes/你的硬碟/BrainlessModels.sparsebundle"
```

App 啟動時會自動掛載。

## 自己編譯

只需要 Xcode Command Line Tools（`xcode-select --install`），不需要 Xcode。

```
./build.sh
cp -R "build/Brainless Cloud.app" /Applications/
```

每次 push 到 GitHub，Actions 會在 macOS 上跑 `./build.sh`，並把 App 上傳成 artifact。

程式結構：`Sources/` 下 `AppController`（狀態機與選單）、`HotkeyMonitor`（CGEventTap）、`AudioRecorder`（AVAudioEngine → 16 kHz WAV）、`WhisperServer`（whisper-server 子程序 + HTTP）、`OllamaClient`（Ollama Cloud）、`CloudKey`（API key 存鑰匙圈）、`TextInserter`（剪貼簿 + ⌘V）、`OverlayPanel`（浮條）、`HubView` / `SetupViews`（SwiftUI 主視窗）、`Stores`（歷史、詞典）、`ModelSetup`（下載）、`VolumeManager`。

內部識別碼是 `app.whispry.mac.cloud`。簽章是 ad-hoc 加固定的 designated requirement，重新編譯不會讓輔助使用權限失效。

## 隱私

- 錄音只送到本機的 `127.0.0.1:8179`（whisper-server），它只聽本機。
- 辨識出來的文字（加上詞典裡相關的詞）會用 HTTPS 送到 `ollama.com` 潤稿。Ollama 的[隱私政策](https://ollama.com/privacy)寫明：雲端請求只在處理時暫存，不保存，也不拿去訓練模型。
- App 在啟動、改設定、潤稿失敗時，會向 `ollama.com` 檢查 API key 和模型狀態（連不上時每 15 秒重試一次），不含任何文字內容。
- API key 存在 macOS 鑰匙圈，不寫進設定檔。
- 歷史紀錄與詞典存在 `~/Library/Application Support/BrainlessCloud/`，檔案權限 600。
- 記錄檔不存逐字稿內容，只記字數與耗時。
- 除了上面這些送到 Ollama Cloud 的請求，沒有任何網路回報。

## 已知限制

- 單次最長 10 分鐘。
- 不吃 ⌘V 的 App（例如某些終端機）貼不上，可從選單「複製上一次的結果」手動貼。
- 沒有 Apple 開發者簽章，第一次要右鍵打開。
- 潤稿需要網路；離線時聽寫只會貼上未潤稿的原文。
- 和原版同時開著時，快捷鍵要錯開。

---

## English

**Speak, don't type.** A cloud-refinement variant of [Brainless](https://github.com/austin17022/brainless). Press a hotkey, talk, press again, and polished text lands at your cursor. Speech recognition runs on this Mac (Whisper large-v3 Q5, whisper.cpp, Metal); cleanup, translation and "ask anything" run on Ollama Cloud. Audio never leaves your Mac; only the recognized text is sent for refinement. It installs side by side with the original Brainless: separate bundle ID (`app.whispry.mac.cloud`), permissions, settings, history, dictionary and whisper-server port (8179).

**Features**: dictation with filler-word removal and punctuation, translation (zh → en/ja/ko), "ask anything" on selected text, a personal dictionary that steers both Whisper and the LLM, local history, a menu-bar app plus a dashboard window (insights, history, dictionary, settings), configurable hotkey (including "press any key to learn"), Esc to cancel, keep-mic-awake option for USB mics.

**Requirements**: Apple Silicon, macOS 14+, 8 GB RAM, a microphone, ~1.1 GB disk, internet, and an Ollama account with an API key ([ollama.com/settings/keys](https://ollama.com/settings/keys)). The Free plan covers only some starter models (such as `gemma4:31b`); the default `deepseek-v4.1-flash` may need credits or a subscription ([pricing](https://ollama.com/pricing)).

**Install**: build it (below), or download the `BrainlessCloud` artifact from the latest successful Actions run and unzip it twice. Drag `Brainless Cloud.app` to Applications and right-click › Open the first time (ad-hoc signed; if a downloaded build still won't open, run `xattr -dr com.apple.quarantine "/Applications/Brainless Cloud.app"`). Grant Microphone and Accessibility again (they are separate from the original app), then follow the setup card: `brew install whisper-cpp`, download the Whisper model (1.1 GB), paste your Ollama API key (stored in the macOS Keychain).

**Refinement model**: default `deepseek-v4.1-flash`; change it under Settings › 模型 to any name from [ollama.com/search?c=cloud](https://ollama.com/search?c=cloud). The app reads the model's thinking options from `/api/show` and turns thinking off, or uses the lowest level when it can't be turned off. Without network, with a bad key or with no credits left, dictation pastes the raw transcript and shows why; translation and "ask anything" fail.

**Build**: `./build.sh` with Xcode Command Line Tools only, then `cp -R "build/Brainless Cloud.app" /Applications/`. GitHub Actions builds the app on macOS for every push and uploads it as an artifact.

**Privacy**: audio goes only to the local whisper-server (127.0.0.1:8179). The recognized text (plus related dictionary terms) goes to `ollama.com` over HTTPS; Ollama's [privacy policy](https://ollama.com/privacy) says cloud prompts are processed transiently, not stored and not used for training. The app checks the API key and model status with ollama.com at launch, after settings changes and after a failed request (every 15 seconds while it can't connect); these checks carry no text content. The API key lives in the Keychain; history and dictionary stay in `~/Library/Application Support/BrainlessCloud/` with 600 permissions; logs never contain transcripts.

**Running both apps**: both react to the same hotkey if both are running, so give one of them a different key.

MIT License.
