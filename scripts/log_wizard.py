#!/usr/bin/env python3
import sys
import subprocess
from collections import Counter

# ANSIカラー（視認性向上）
C_RED = '\033[91m'
C_CYAN = '\033[96m'
C_YELLOW = '\033[93m'
C_END = '\033[0m'

def analyze_with_llm(raw_log):
    # Gemini 3.0 Preview への「ズバッと」プロンプト
    prompt = f"以下の1行のログから、何が起きているか、攻撃の予兆か、具体的な対策を30文字以内でズバッと指摘せよ。余計な挨拶は不要。\n\n{raw_log}"
    
    try:
        # llm コマンドを実行
        result = subprocess.run(
            ['llm', prompt],
            capture_output=True,
            text=True,
            encoding='utf-8',
            check=True
        )
        return result.stdout.strip().replace('\n', ' ')
    except Exception as e:
        return f"LLM Error: {str(e)[:30]}"

def analyze_logs():
    if sys.stdin.isatty():
        print("Usage: docker logs <id> 2>&1 | lz")
        return

    # キーワード：これらが含まれる行を「異常」とみなす
    KEYWORDS = ['error', 'failed', 'warning', 'critical', '404', '500', 'denied']
    
    counts = Counter()
    samples = {}

    for line in sys.stdin:
        line_strip = line.strip()
        if not line_strip:
            continue
            
        line_lower = line_strip.lower()
        if any(kw in line_lower for kw in KEYWORDS):
            # ログ行をそのままキーにして集計（重複排除はLLM側でもできる）
            counts[line_strip] += 1
            if line_strip not in samples:
                samples[line_strip] = line_strip

    if not counts:
        print(f"{C_CYAN}✨ 異常ログは見つかりませんでした。{C_END}")
        return

    print(f"\n{C_YELLOW}🚀 Gemini 3.0 Preview Analysis (Top 3 Errors){C_END}")
    print("-" * 70)

    for i, (msg, count) in enumerate(counts.most_common(3), 1):
        print(f"{C_CYAN}Rank {i} ({count}回発生):{C_END}")
        print(f"  Log: {msg[:100]}...") # 長すぎる場合はカット
        
        # ここで LLM 呼び出し
        analysis = analyze_with_llm(msg)
        print(f"  {C_RED}💡 解析結果: {analysis}{C_END}\n")

if __name__ == "__main__":
    analyze_logs()
