---
title: "rails3-generator を使う"
date: "2010-10-20T00:00:00+09:00"
draft: false
---
rails には generator がありファイルを作ってくれるけど gem で入れたものについては作る仕組みが用意されていない。毎度手で作るのも面倒なので新しいプロジェクトを始めるときは rails3-generator の gem を使う。RSpec や authlogic / jQUery / haml などなど、いろんなライブラリのファイルを作ってくれる。

Rails の generator は `railties-3.0.0/lib/rails/generators.rb` の実装を見るとわかる通り、hidden_namespaces というインスタンス変数に値をセットすることで利用することができ、rails3-generators もそれを使うような実装になっている。

この gem をインストールすることで、`rails g` で使えるコマンドが増えているのがわかる。

`#{Rails.root}/config/appplication.rb` に以下のように書くことで、モデルの作成時に RSpec のファイルや FactoryGirl のファイルを作ってくれるようになる。

{{< highlight ruby "linenos=pre" >}}
config.generators do |g|
  g.test_framework :rspec, :fixture => true, :views => false
  g.fixture_replacement :factory_girl, :dir => "spec/factories"
end
{{< / highlight >}}

すばらしい。
