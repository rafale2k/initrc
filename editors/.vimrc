" =============================================================================
" 1. 自動セットアップ (vim-plug の自動インストール)
" =============================================================================
let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
if empty(glob(data_dir . '/autoload/plug.vim'))
    silent execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
    autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

" =============================================================================
" 2. プラグイン構成
" =============================================================================
call plug#begin()
    Plug 'itchyny/lightline.vim'  " 下部のステータスバーをリッチに
    Plug 'preservim/nerdtree'     " 左側にファイルツリーを表示
    Plug 'tpope/vim-commentary'   " `gcc` で行コメントアウト
    Plug 'tomasr/molokai'         " 定番のカラースキーム
call plug#end()

" --- プラグイン設定 ---
" rootユーザー時はステータスバーの色を変える（警告色）
let g:lightline = {'colorscheme': ($USER == 'root' ? 'deus' : 'wombat')}
" Ctrl+n で NERDTree の開閉
nnoremap <C-n> :NERDTreeToggle<CR>

" =============================================================================
" 3. 基本的な見た目と表示
" =============================================================================
syntax on                   " 構文ハイライト
set number                  " 行番号表示
set termguicolors           " 24bitカラー有効化
set t_Co=256                " 256色モード
colorscheme molokai         " カラースキーム適用
set cursorline              " 現在の行を強調
set laststatus=2            " ステータスバーを常に表示
set showmatch               " 括弧入力時に対応する括弧を強調
set helpheight=999          " ヘルプを全画面で開く

" =============================================================================
" 4. 編集・操作性の設定
" =============================================================================
set encoding=utf-8          " 文字コード
set expandtab               " タブをスペースに
set tabstop=4               " タブ幅
set shiftwidth=4            " 自動インデント幅
set smartindent             " 賢いインデント
set incsearch               " 検索中からヒット
set hlsearch                " 検索結果をハイライト
set backspace=indent,eol,start " バックスペースを有効化
set wildmenu                " コマンド補完を視覚的に
set hidden                  " 保存せずにバッファを切り替え可能に

" --- マッピング ---
" Esc2回で検索ハイライトを消す
nnoremap <Esc><Esc> :nohlsearch<CR><Esc>

" --- 自動閉じ括弧 ---
inoremap { {}<Left>
inoremap [ []<Left>
inoremap ( ()<Left>
inoremap " ""<Left>
inoremap ' ''<Left>

" =============================================================================
" 5. ターミナル貼り付け時の暴走防止 (Bracketed Paste Mode)
" =============================================================================
if &term =~ "xterm"
    let &t_SI .= "\e[?2004h"
    let &t_EI .= "\e[?2004l"
    let &pastetoggle = "\e[201~"

    function! XTermPasteBegin(ret)
        set paste
        return a:ret
    endfunction

    inoremap <special> <expr> <Esc>[200~ XTermPasteBegin("")
endif
