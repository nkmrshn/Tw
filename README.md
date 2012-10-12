Tw
==

コマンドラインでツイートするRubyスクリプトです。

設定
----

アプリを["Twitter Developers"](http://dev.twitter.com/)の["My applications"](https://dev.twitter.com/apps)で登録し、Consumer Key、Consumer Secret、Access Token、Access Token Secretを取得してください。

URLは、Google URL Shortener APIを使って短縮しています。GoogleはAccess Keyの取得を推奨し、設定するとAnonymous状態と比べて制限が拡大されます。Access Keyは、["Google APIs Console"](https://code.google.com/apis/console/)で取得できます。

ホームディレクトリに.twrcファイルを作成し、設定値を保存します。引数なしで起動し、取得した値をぞれぞれ入力してください。Access Keyを省略する場合は、単にエンターキーを入力してください。

例：

    $ ./tw.rb
    Consumer key:*************
    Consumer secret:***************
    Access token:***********
    Access token secret:***********
    Google api access key:***********
    saved to /Users/nkmrshn/.twrc
    $

使い方
-----

投稿したいメッセージを引数として、起動してください。複数の引数は、半角の空白で連結します。ただし、半角括弧が文中にある場合は、文章全体をダブルクォーテーションで囲ってください。URLが文中にある場合、その前後に半角空白がないと短縮化されません。最後の引数に画像ファイルを指定すると、画像も投稿します。

例：

    $ ./tw.rb こんにちは http://nkmrshn.com
    posted.

短縮化されて以下のようにURLは短縮化され投稿されます。

    こんにちは。 http://goo.gl/mMyfx

備考
----

* これは、2011年2月11日付け『[コマンドラインでツイートするRubyスクリプト（つづき）](http://d.hatena.ne.jp/nkmrshn/20110211/1297356809)』をベースに修正したものです。

* tw.rbに「chmod a+x tw.rb」などと、実行属性を付与するのをお忘れずに。

* ライセンスについては、LICENSE.mdをご覧下さい。
