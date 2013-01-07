package EntryTree::L10N::ja;

use strict;
use base 'EntryTree::L10N::en_us';
use utf8;

use vars qw( %Lexicon );

%Lexicon = (
    # config.yaml
    '_PLUGIN_DESCRIPTION' => 'ブログ記事が木構造の親子関係を持てるようになり、テンプレートで親、子、兄弟記事を取得したりできるようになります。 ',
    # lib/EntryTree/Plugin.pm
    'Entry Parent' => '親記事',
    'Entry Parent ID' => '親記事ID',
    'Entry Children' => '子記事',
    "Add a child of '[_1]'" => '「[_1]」の子記事を作成する',
);

1;