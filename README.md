mt-plugin-entrytree
=======================

ブログ記事が木構造の親子関係を持てるようになり、テンプレートで親、子、兄弟記事を取得したりできるようになります。（MT5.1～）

## 機能

*   ブログ記事に親記事IDを追加
*   ブログ記事一覧に親記事、子記事列を追加
    一覧画面から直接子記事を作成可能
*   各記事を取得するためのテンプレートタグ（PHPダイナミックパブリッシング未対応）

## テンプレートタグ（ブロックタグ）

### MTEntryParent

親記事を取得

### MTEntryChildren

子記事を取得

### MTEntrySiblings

兄弟記事を取得

### MTEntryAncestors

祖先記事を取得

### MTEntryDescendants

子孫記事を取得

## 例

    <mt:EntryChildren>
        <mt:EntriesHeader><ul></mt:EntriesHeader>
        <li><$MTEntryTitle$></li>
        <mt:EntriesFooter></ul></mt:EntriesFooter>
    </mt:EntryChildren>

各テンプレートタグは MTEntries と同じモディファイアを利用できます。（内部的に MTEntries の処理を流用しています）

## Contributing to mt-plugin-entrytree

Fork, fix, then send me a pull request.

## Copyright

Copyright(c) 2013 Yuichi Takeuchi, released under the MIT license
