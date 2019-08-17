---
title: "rails3 のカスタムバリデーション"
date: "2011-03-27T00:00:00+09:00"
draft: false
---
Rails3 のカスタムバリデーションは Rails2 に比べるとだいぶ書きやすくなっている。`ActiveModel::EachValidator` を継承したクラスを用意して必要なメソッドを定義してあげればいい。以下は簡単な URL バリデーションのサンプル。

{{< highlight ruby "linenos=pre" >}}
# -*- coding: utf-8 -*-
class UrlValidator < ::ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    begin
      uri = ::Addressable::URI.parse(value)
      unless ["http", "https", "ftp"].include?(uri.scheme)
        raise ::Addressable::URI::InvalidURIError
      end
    rescue ::Addressable::URI::InvalidURIError
      record.errors[attribute] << "Invalid URL"
    end
  end
end
{{< / highlight >}}

実際に使うときはこんな感じ。

{{< highlight ruby "linenos=pre" >}}
# -*- coding: utf-8 -*-
Class Hoge < ActiveRecord::Base
  validates :external_url, :url => true
end
{{< / highlight >}}

使うのは簡単だけど、このファイルをどこに置いたもんかなあと思う。`app/validators` でいいんじゃない ? みたいな記事を見かけたけど、個人的な好みとしては `lib` の下に置きたいなあというお気持ち。

{{< highlight sh "linenos=pre" >}}
mkdir -p lib/ext/active_model/validations
touch lib/ext/active_model/validations/url.rb
{{< / highlight >}}

Rails3 では `lib` 以下は autoload パスに含まれない。いろいろと異論はあるかと思いますが `config/application.rb` にて追加する。全部読み込みたくない場合は `lib/autoload` とかディレクトリを作ってそこだけ読み込む、とかかね。

{{< highlight ruby >}}
config.autoload_paths += %W(#{config.root}/lib)
{{< / highlight >}}
