#!/bin/bash
# rlogin / xterm 互換のパレット変更シーケンス

# 背景色をMonokaiのグレー(#272822)に設定
echo -ne "\033]11;#272822\007"
# 0番(Black)を背景と同じか少し暗い色に
echo -ne "\033]4;0;#1b1c18\007"
# 1番(Red) -> Monokai Pink (#f92672)
echo -ne "\033]4;1;#f92672\007"
# 2番(Green) -> Monokai Green (#a6e22e)
echo -ne "\033]4;2;#a6e22e\007"
# 3番(Yellow) -> Monokai Yellow (#e6db74)
echo -ne "\033]4;3;#e6db74\007"
# 4番(Blue) -> Monokai Blue (#66d9ef)
echo -ne "\033]4;4;#66d9ef\007"
# 5番(Magenta) -> Monokai Purple (#ae81ff)
echo -ne "\033]4;5;#ae81ff\007"
# 6番(Cyan) -> Monokai Aqua (#a1efe4)
echo -ne "\033]4;6;#a1efe4\007"
