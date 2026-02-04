# Chrome ブラウザ自動化ガイド

Dockerコンテナからホスト（MacOS）のChromeブラウザを操作するための完全ガイド

---

## 概要

このドキュメントでは、Dockerコンテナ内からホストマシン（MacOS）上で実行中のChromeブラウザを**Chrome DevTools Protocol (CDP)** を使用して自動化・操作する方法を説明します。

### 主な用途

- Webページの自動ナビゲーション
- ブラウザテストの実行
- スクリーンショット取得
- パフォーマンス計測
- デバッグ支援

---

## 前提条件

### 1. ホスト側（MacOS）の設定

Chromeをリモートデバッグモードで起動する必要があります：

```bash
# Chromeをリモートデバッグモードで起動
/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome \
  --remote-debugging-port=9222 \
  --user-data-dir="/tmp/chrome-dev-profile"
```

または、既存のChromeプロファイルを使用する場合：

```bash
# 既存のプロファイルを使用（注意：既存のChromeインスタンスを終了させる必要あり）
/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome \
  --remote-debugging-port=9222
```

### 2. Dockerコンテナ側の設定

`.devcontainer/opencode_config.json` で Chrome DevTools MCP が有効になっていることを確認：

```json
{
  "mcp": {
    "chrome-devtools": {
      "type": "local",
      "command": ["npx", "-y", "chrome-devtools-mcp@latest", "--browser-url=http://host.docker.internal:9222"],
      "enabled": true
    }
  }
}
```

### 3. 接続確認

コンテナ内からChromeへの接続を確認：

```bash
# Chromeのバージョン情報を取得
curl -s -H "Host: localhost" http://host.docker.internal:9222/json/version
```

期待される出力：
```json
{
   "Browser": "Chrome/144.0.7559.133",
   "Protocol-Version": "1.3",
   "User-Agent": "Mozilla/5.0 ...",
   "V8-Version": "...",
   "WebKit-Version": "...",
   "webSocketDebuggerUrl": "ws://localhost/devtools/browser/..."
}
```

---

## クイックスタート

### 方法1: HTTP APIを使用（簡単）

#### 新しいタブを作成してURLを開く

```bash
# 新しいタブを作成し、指定したURLを開く
curl -s -X PUT -H "Host: localhost" \
  'http://host.docker.internal:9222/json/new?url=https://github.com'
```

#### 既存のタブ一覧を取得

```bash
# 開いているタブの一覧を取得
curl -s -H "Host: localhost" http://host.docker.internal:9222/json/list
```

#### タブをアクティブにする

```bash
# タブIDを指定してアクティブにする
curl -s -X PUT -H "Host: localhost" \
  http://host.docker.internal:9222/json/activate/<TAB_ID>
```

#### タブを閉じる

```bash
# タブを閉じる
curl -s -X PUT -H "Host: localhost" \
  http://host.docker.internal:9222/json/close/<TAB_ID>
```

### 方法2: WebSocketを使用（高度な操作）

#### 準備

```bash
# Node.jsプロジェクトの初期化とwsモジュールのインストール
cd /workspace
npm init -y
npm install ws
```

#### ページをナビゲートするスクリプト

```javascript
const WebSocket = require("ws");

// タブのWebSocket URLを指定
const TAB_ID = "<タブID>"; // /json/list で取得
const ws = new WebSocket(`ws://host.docker.internal:9222/devtools/page/${TAB_ID}`);

ws.on("open", () => {
    console.log("Chromeに接続しました");
    
    // Page ドメインを有効化
    ws.send(JSON.stringify({id: 1, method: "Page.enable"}));
    
    // URLにナビゲート
    setTimeout(() => {
        ws.send(JSON.stringify({
            id: 2, 
            method: "Page.navigate", 
            params: {url: "https://github.com"}
        }));
    }, 500);
});

ws.on("message", (data) => {
    const msg = JSON.parse(data);
    console.log("受信:", msg.method || "response");
    
    // ページ読み込み完了イベント
    if (msg.method === "Page.loadEventFired") {
        console.log("ページ読み込み完了!");
        
        // ページタイトルを取得
        ws.send(JSON.stringify({
            id: 3,
            method: "Runtime.evaluate",
            params: {expression: "document.title"}
        }));
    }
    
    // タイトル取得結果
    if (msg.result && msg.result.result && msg.result.result.value) {
        console.log("ページタイトル:", msg.result.result.value);
        ws.close();
    }
});

ws.on("error", (err) => console.error("エラー:", err.message));
ws.on("close", () => console.log("接続終了"));

// タイムアウト設定
setTimeout(() => ws.close(), 20000);
```

実行：
```bash
node navigate.js
```

---

## よく使う操作

### 1. スクリーンショットを取得

```javascript
ws.send(JSON.stringify({
    id: 4,
    method: "Page.captureScreenshot",
    params: {format: "png", fullPage: true}
}));
```

### 2. JavaScriptを実行

```javascript
ws.send(JSON.stringify({
    id: 5,
    method: "Runtime.evaluate",
    params: {
        expression: "document.querySelector('h1').textContent",
        returnByValue: true
    }
}));
```

### 3. コンソールログを取得

```javascript
// Console ドメインを有効化
ws.send(JSON.stringify({id: 6, method: "Console.enable"}));

// コンソールメッセージを受信
ws.on("message", (data) => {
    const msg = JSON.parse(data);
    if (msg.method === "Console.messageAdded") {
        console.log("コンソール:", msg.params.message.text);
    }
});
```

### 4. ネットワーク監視

```javascript
// Network ドメインを有効化
ws.send(JSON.stringify({id: 7, method: "Network.enable"}));

// ネットワークリクエストを監視
ws.on("message", (data) => {
    const msg = JSON.parse(data);
    if (msg.method === "Network.requestWillBeSent") {
        console.log("リクエスト:", msg.params.request.url);
    }
});
```

---

## 便利なワンライナー

### タブ一覧を取得（IDとURLのみ表示）

```bash
curl -s -H "Host: localhost" http://host.docker.internal:9222/json/list | \
  node -e "const data = require('fs').readFileSync(0, 'utf8'); JSON.parse(data).forEach(t => console.log(t.id + ' | ' + t.url + ' | ' + t.title));"
```

### 新しいタブを作成してGitHubを開く

```bash
curl -s -X PUT -H "Host: localhost" \
  'http://host.docker.internal:9222/json/new?url=https://github.com' | \
  node -e "const data = require('fs').readFileSync(0, 'utf8'); const j = JSON.parse(data); console.log('タブID:', j.id); console.log('タイトル:', j.title);"
```

### すべてのタブを閉じる

```bash
for id in $(curl -s -H "Host: localhost" http://host.docker.internal:9222/json/list | node -e "const data = require('fs').readFileSync(0, 'utf8'); JSON.parse(data).forEach(t => console.log(t.id));"); do
  curl -s -X PUT -H "Host: localhost" "http://host.docker.internal:9222/json/close/$id" > /dev/null
done
echo "すべてのタブを閉じました"
```

---

## トラブルシューティング

### 接続できない場合

```bash
# エラーチェック
curl -v http://host.docker.internal:9222/json/version 2>&1
```

**解決策:**
1. Chromeがリモートデバッグモードで起動しているか確認
2. ファイアウォール設定を確認
3. Docker Desktopの設定で「host.docker.internal」が有効か確認

### "Host header is specified" エラー

**解決策:**
すべてのcurlコマンドに `-H "Host: localhost"` を追加

```bash
curl -s -H "Host: localhost" http://host.docker.internal:9222/json/list
```

### WebSocket接続エラー

**解決策:**
1. タブIDが正しいか確認
2. Chromeが応答しているか確認
3. ネットワーク設定を確認

---

## CDP メソッド一覧

### Page ドメイン

| メソッド | 説明 |
|---------|------|
| `Page.enable` | Page ドメインを有効化 |
| `Page.navigate` | URLにナビゲート |
| `Page.reload` | ページをリロード |
| `Page.captureScreenshot` | スクリーンショット取得 |
| `Page.printToPDF` | PDFとして保存 |

### Runtime ドメイン

| メソッド | 説明 |
|---------|------|
| `Runtime.enable` | Runtime ドメインを有効化 |
| `Runtime.evaluate` | JavaScriptを実行 |
| `Runtime.callFunctionOn` | オブジェクトのメソッドを呼び出し |

### DOM ドメイン

| メソッド | 説明 |
|---------|------|
| `DOM.enable` | DOM ドメインを有効化 |
| `DOM.getDocument` | ドキュメントルートを取得 |
| `DOM.querySelector` | セレクタで要素を検索 |

### Network ドメイン

| メソッド | 説明 |
|---------|------|
| `Network.enable` | Network ドメインを有効化 |
| `Network.setCacheDisabled` | キャッシュを無効化 |
| `Network.emulateNetworkConditions` | ネットワーク条件をエミュレート |

---

## 参考リンク

- [Chrome DevTools Protocol ドキュメント](https://chromedevtools.github.io/devtools-protocol/)
- [Chrome DevTools Protocol Viewer](https://chromedevtools.github.io/devtools-protocol/tot/Page/)
- [Remote Debugging Protocol](https://developer.chrome.com/docs/devtools/remote-debugging/)

---

## エイリアス（推奨）

`.oh-my-opencode/aliases.zsh` に以下を追加することを推奨：

```bash
# Chrome DevTools エイリアス
alias chrome-list='curl -s -H "Host: localhost" http://host.docker.internal:9222/json/list | node -e "const data = require('\''fs'\'').readFileSync(0, '\''utf8'\''); JSON.parse(data).forEach(t => console.log(t.id + '\'' | '\'' + t.url));"'
alias chrome-new='curl -s -X PUT -H "Host: localhost"'
alias chrome-version='curl -s -H "Host: localhost" http://host.docker.internal:9222/json/version'
alias chrome-close='curl -s -X PUT -H "Host: localhost" http://host.docker.internal:9222/json/close'
```

---

## 更新履歴

| 日付 | 内容 |
|------|------|
| 2025-02-04 | 初版作成 |

