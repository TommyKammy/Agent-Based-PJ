# Template-Agent-Based-Project

opencode CLIツール用のカスタムエージェント設定リポジトリ

## 概要

このリポジトリは、opencode CLIツール用のカスタムエージェント定義、便利なエイリアス、再利用可能なスニペット、および開発環境を管理しています。
Windows/Mac/Linux間の環境差異を吸収するため、Docker Composeの代わりに **Dev Container** (VS Code用) および **Task** (CLI操作用) を採用しています。

### 主な機能

- **5つのカスタムエージェント**: Sisyphus（メイン窓口）、Build（実装）、Explore（Web調査）、General（要約）、Oracle（設計判断）
- **堅牢な開発環境**: OS依存の問題を排除したDev Container環境
- **Taskランナー**: `task` コマンドによるシンプルなコンテナ操作
- **ローカルLLM対応**: LM Studioなどのローカルモデルのサポート

## 目次

1. [要件](#要件)
2. [セットアップ](#セットアップ)
   - [Mac](#mac)
   - [Ubuntu/Linux](#ubuntulinux)
   - [Windows](#windows)
3. [開発環境の使い方](#開発環境の使い方)
4. [opencodeの使い方](#opencodeの使い方)
5. [エージェント一覧](#エージェント一覧)

## 要件

### 必須ソフトウェア

- **Docker Desktop** (Mac/Windows) または **Docker Engine** (Linux)
- **VSCode**: 最新版 + [Dev Containers拡張機能](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
- **Task (go-task)**: クロスプラットフォームなタスクランナー

### リポジトリのクローン

```bash
git clone <repository-url> ~/.oh-my-opencode
cd ~/.oh-my-opencode
```

## セットアップ

OSごとの `Task` コマンドのインストール手順です。

### Mac

Homebrewを使用してインストールします。

```bash
# Taskのインストール
brew install go-task/tap/go-task

# （オプション）Colimaを使用する場合
brew install colima
colima start --cpu 4 --memory 8 --disk 60
```

### Ubuntu/Linux

npm または snap を使用してインストールします。

```bash
# npm経由の場合（Node.jsがインストール済みの場合）
npm install -g @go-task/cli

# または Snap経由の場合
sudo snap install task --classic
```

### Windows

PowerShell (管理者権限) または npm でインストールします。

```bash
# npm経由の場合
npm install -g @go-task/cli

# または Winget経由の場合
winget install Task.Task
```

## 開発環境の使い方

このプロジェクトは2つの方法で起動できます。推奨は **VS Code Dev Containers** です。

### 方法A: VS Code Dev Containers (推奨)

VS Codeの統合環境を使用する方法です。OSの差異を完全に無視できます。

1. VS Codeでこのフォルダを開く。
2. 左下の「><」アイコン、またはコマンドパレット(F1)から **"Dev Containers: Reopen in Container"** を選択。
3. 自動的にビルドが始まり、環境が立ち上がります（初回は数分かかります）。

### 方法B: Task CLI (手動実行)

ターミナルからコンテナを操作したい場合に使用します。

```bash
# コンテナのビルドと起動（バックグラウンド）
task up

# コンテナ内のシェルに入る
task shell

# コンテナの停止と削除
task down

# ログの確認
task logs
```

### 利用可能なタスク一覧

```bash
task list
```

## opencodeの使い方

コンテナ内（`task shell` または VS Codeのターミナル）で実行してください。

### 基本的な使い方

```bash
opencode run
```

### エイリアスを使用したクイック実行

`.oh-my-opencode/aliases.zsh` で定義された以下のエイリアスが利用可能です。

| エイリアス | ターゲット | 用途 | 例 |
| :--- | :--- | :--- | :--- |
| `ocs` | **Sisyphus** | 総合窓口、タスク分解 | `ocs "このプロジェクトの構造を解析して"` |
| `ocb` | **Build** | 実装、コード書き換え | `ocb "src/index.tsのエラー処理を修正"` |
| `oce` | **Explore** | Web検索、ドキュメント調査 | `oce "React 19の新機能を調べて"` |
| `ocg` | **General** | 一般会話、要約、翻訳 | `ocg "このメールの下書きを敬語に直して"` |
| `oco` | **Oracle** | 設計判断、セキュリティ | `oco "JWTとSession認証のどちらがいい？"` |

エイリアス一覧の確認:
```bash
oc-aliases
```

## エージェント一覧

詳細なプロンプト設計や役割については [AGENTS.md](./AGENTS.md) を参照してください。

- **Sisyphus**: ユーザーの曖昧な要求を明確化し、他のエージェントに指示を振り分けるPM的な役割。
- **Build**: コードの品質と機能実装に集中するエンジニア。
- **Explore**: 外部情報の収集とファクトチェックを行うリサーチャー。
- **General**: コンテキストに依存しない一般的なタスクを処理するアシスタント。
- **Oracle**: アーキテクチャ、セキュリティ、ベストプラクティスを提示するテックリード。

┌─────────────┐
│  ユーザー    │
└──────┬──────┘
       │
       ▼
┌─────────────┐     ┌──────────────┐     ┌─────────────┐
│  Sisyphus   │────▶│  Sub-agent   │────▶│   結果統合   │
│  (窓口)     │     │ (build/etc)  │     │   & 回答     │
└─────────────┘     └──────────────┘     └──────┬──────┘
       │                                         │
       │                                        │
       │         ┌──────────────┐               │
       └────────▶│   Explore    │◀──────────────┘
                 │ (Web調査)    │
                 └──────────────┘

```

***

### 2. 新規作成: AGENTS.md

各エージェントのキャラクター（Persona）やシステムプロンプトの設計指針をまとめたドキュメントです。

```markdown
# Agent Definitions & Guidelines

このドキュメントでは、opencode環境で稼働する5つのカスタムエージェントの役割、振る舞い、および利用シーンについて説明します。

## エージェント構成図

```mermaid
graph TD
    User((User)) --> Sisyphus[Sisyphus<br/>(Manager/Router)]
    
    Sisyphus -->|実装依頼| Build[Build<br/>(Engineer)]
    Sisyphus -->|調査依頼| Explore[Explore<br/>(Researcher)]
    Sisyphus -->|設計相談| Oracle[Oracle<br/>(Architect)]
    Sisyphus -->|雑務| General[General<br/>(Assistant)]
    
    subgraph Specialty Agents
        Build
        Explore
        Oracle
        General
    end
```

## 1. Sisyphus (The Manager)
**エイリアス:** `ocs`

### 概要
Sisyphus（シシュフォス）は、ユーザーとの主要なインターフェースです。複雑または曖昧なタスクを受け取り、それを実行可能な小さなステップに分解し、適切な専門エージェントに委任するか、自分で解決策を導きます。

### ペルソナ設定
- **役割**: プロジェクトマネージャー、タスクオーケストレーター
- **トーン**: 冷静、分析的、忍耐強い
- **特技**: 曖昧さの排除、ゴール設定、コンテキスト管理

### 利用シーン
- 「何から手をつければいいかわからない」とき
- 複数のファイルにまたがる修正を行いたいとき
- 要件定義が終わっていない段階での相談

### サンプルプロンプト
> 「既存のPythonスクリプトをRustに書き換えたいんだけど、パフォーマンスへの影響と必要なライブラリの選定を含めて進めて。」

---

## 2. Build (The Engineer)
**エイリアス:** `ocb`

### 概要
純粋なコーディング能力に特化したエージェントです。コードの構文、デザインパターン、型安全性に厳格で、動くコードを提供することを最優先します。

### ペルソナ設定
- **役割**: シニアソフトウェアエンジニア
- **トーン**: 簡潔、技術的、実用的
- **行動指針**: `Dry Run`（検証）なしにファイルを破壊しない、既存のスタイルガイドを遵守する

### 利用シーン
- 具体的な機能実装
- バグフィックス
- リファクタリング
- テストコードの作成

### サンプルプロンプト
> 「`src/utils/parser.ts` の `parseJSON` 関数にエラーハンドリングを追加して、不正なJSONが来た場合はnullを返すように修正してください。」

---

## 3. Explore (The Researcher)
**エイリアス:** `oce`

### 概要
Web検索ツールやドキュメント参照ツールを駆使し、外部情報の取得に特化しています。最新のライブラリ情報やAPI仕様、トラブルシューティング情報を収集します。

### ペルソナ設定
- **役割**: リサーチャー、テクニカルライター
- **トーン**: 客観的、情報豊富、出典を明記する
- **特技**: Google検索、公式ドキュメントの読解、比較検討

### 利用シーン
- 最新のフレームワークのバージョン間の違いを調べるとき
- エラーログの原因が特定できないとき
- ライブラリの選定理由となる根拠が欲しいとき

### サンプルプロンプト
> 「Next.js 14のServer Actionsにおけるバリデーションのベストプラクティスを調べて、zodを使ったサンプルコードを見つけて。」

---

## 4. Oracle (The Architect)
**エイリアス:** `oco`

### 概要
コードを書くことよりも、「どう書くべきか」「なぜそうするのか」という意思決定を支援します。セキュリティ、スケーラビリティ、保守性の観点からアドバイスを行います。

### ペルソナ設定
- **役割**: ソフトウェアアーキテクト、セキュリティスペシャリスト
- **トーン**: 洞察深い、慎重、長期的視点
- **口癖**: 「それは短期的には機能しますが、長期的には技術的負債になります」

### 利用シーン
- データベースのスキーマ設計
- 認証方式の選定（JWT vs Sessionなど）
- AWS/Azureのインフラ構成レビュー
- セキュリティ脆弱性の診断

### サンプルプロンプト
> 「現在モノリスで構築しているこのシステムをマイクロサービス化すべきか悩んでいます。チーム規模は5名です。メリットとデメリットを比較してください。」

---

## 5. General (The Assistant)
**エイリアス:** `ocg`

### 概要
特定の専門知識を必要としない、一般的な言語タスクや事務的な作業を行います。コードに関係のないメール作成や、議事録の要約なども担当します。

### ペルソナ設定
- **役割**: 有能な秘書、翻訳家
- **トーン**: 丁寧、柔軟、親しみやすい

### 利用シーン
- コミットメッセージの生成
- ドキュメントの翻訳（日英/英日）
- メールの下書き作成
- 長いテキストの要約

### サンプルプロンプト
> 「これまでの変更内容を元に、Release Note用の親しみやすい紹介文を日本語で作成して。」
