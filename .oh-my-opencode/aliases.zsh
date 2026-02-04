# ============================================
# oh-my-opencode エイリアス定義
# ============================================
# 使用方法: source ~/.oh-my-opencode/aliases.zsh
# ============================================

# シェル検出と互換性チェック
if [ -n "$ZSH_VERSION" ]; then
  export OH_MY_OPCODE_SHELL="zsh"
elif [ -n "$BASH_VERSION" ]; then
  export OH_MY_OPCODE_SHELL="bash"
else
  export OH_MY_OPCODE_SHELL="unknown"
fi

# 基本コマンド
alias oc='opencode'

# エージェント別エイリアス
alias ocs='opencode run --agent sisyphus'  # メイン窓口（タスク分析・振り分け）
alias ocb='opencode run --agent build'     # 実装・修正・CLI操作
alias oce='opencode run --agent explore'   # Web調査・情報収集
alias ocg='opencode run --agent general'   # 要約・雑談・文章整形
alias oco='opencode run --agent oracle'    # 設計判断・トレードオフ整理

# ヘルプ関数
oc-help() {
  echo "========================================"
  echo "  oh-my-opencode エイリアス一覧"
  echo "========================================"
  echo ""
  echo "基本コマンド:"
  echo "  oc              - opencode 直接実行"
  echo ""
  echo "エージェントエイリアス:"
  echo "  ocs <prompt>    - Sisyphus (メイン窓口・タスク分析)"
  echo "  ocb <prompt>    - Build (実装・修正・CLI)"
  echo "  oce <prompt>    - Explore (Web調査)"
  echo "  ocg <prompt>    - General (要約・雑談)"
  echo "  oco <prompt>    - Oracle (設計判断)"
  echo ""
  echo "使い方例:"
  echo "  ocs \"このコードをレビューして\""
  echo "  ocb \"バグを修正して\""
  echo "  oce \"React 19の新機能を調査\""
  echo ""
  echo "エージェント選択の目安:"
  echo "  - 何から始めればいいか迷ったら → ocs"
  echo "  - コードを書く・修正する → ocb"
  echo "  - 調査が必要 → oce"
  echo "  - 要約・整理 → ocg"
  echo "  - 設計判断 → oco"
  echo "========================================"
}

# スニペット一覧表示
oc-snippets() {
  local snippets_dir="${HOME}/.oh-my-opencode/snippets"
  if [ -d "$snippets_dir" ]; then
    echo "利用可能なスニペット:"
    echo ""
    local i=1
    for file in "$snippets_dir"/*.md; do
      if [ -f "$file" ]; then
        local name=$(basename "$file" .md)
        printf "  %2d. %s\n" "$i" "$name"
        i=$((i + 1))
      fi
    done
    echo ""
    echo "使用方法: oc-snippet <スニペット名>"
  else
    echo "エラー: スニペットディレクトリが見つかりません: $snippets_dir"
    return 1
  fi
}

# スニペット名の補完設定（zsh用）
if [ "$OH_MY_OPCODE_SHELL" = "zsh" ] && type compdef &>/dev/null; then
  _oc_snippet_completion() {
    local snippets_dir="${HOME}/.oh-my-opencode/snippets"
    local -a snippets
    for file in "$snippets_dir"/*.md(N); do
      snippets+=($(basename "$file" .md))
    done
    compadd -a snippets
  }
  compdef _oc_snippet_completion oc-snippet
fi

# スニペット表示
oc-snippet() {
  local snippet_name="$1"
  local snippets_dir="${HOME}/.oh-my-opencode/snippets"
  
  if [ -z "$snippet_name" ]; then
    echo "使用方法: oc-snippet <スニペット名>"
    echo ""
    oc-snippets
    return 1
  fi
  
  local snippet_file="${snippets_dir}/${snippet_name}.md"
  if [ -f "$snippet_file" ]; then
    cat "$snippet_file"
  else
    echo "エラー: スニペットが見つかりません: $snippet_name"
    echo ""
    oc-snippets
    return 1
  fi
}

# エージェント設定の検証
oc-doctor() {
  echo "========================================"
  echo "  oh-my-opencode 診断"
  echo "========================================"
  echo ""
  
  # opencode インストール確認
  if command -v opencode &> /dev/null; then
    echo "✓ opencode がインストールされています"
    opencode --version 2>/dev/null || echo "  バージョン情報を取得できません"
  else
    echo "✗ opencode が見つかりません"
    echo "  インストール方法: https://opencode.ai"
  fi
  echo ""
  
  # ディレクトリ構造確認
  local base_dir="${HOME}/.oh-my-opencode"
  if [ -d "$base_dir" ]; then
    echo "✓ ベースディレクトリが存在します: $base_dir"
  else
    echo "✗ ベースディレクトリが見つかりません: $base_dir"
  fi
  
  if [ -d "$base_dir/agents" ]; then
    echo "✓ agents ディレクトリが存在します"
    local agent_count=$(ls -1 "$base_dir/agents"/*.md 2>/dev/null | wc -l)
    echo "  登録エージェント: $agent_count 個"
  else
    echo "✗ agents ディレクトリが見つかりません"
  fi
  
  if [ -d "$base_dir/snippets" ]; then
    echo "✓ snippets ディレクトリが存在します"
    local snippet_count=$(ls -1 "$base_dir/snippets"/*.md 2>/dev/null | wc -l)
    echo "  登録スニペット: $snippet_count 個"
  else
    echo "✗ snippets ディレクトリが見つかりません"
  fi
  
  echo ""
  echo "シェル情報:"
  echo "  種別: $OH_MY_OPCODE_SHELL"
  echo "  バージョン: ${ZSH_VERSION:-${BASH_VERSION:-unknown}}"
  echo "========================================"
}