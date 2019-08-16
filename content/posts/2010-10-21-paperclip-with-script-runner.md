---
title: "script/runner で paperclip を使う"
date: "2010-10-21T00:00:00+09:00"
draft: false
---
paperclip は Rails でファイルを扱うのにめっちゃ便利なのでよく使っている。ちょっとした要件で runner の中でも使いたかったんだけど、どうやってモデルにファイルを assign すればいいのかよくわからなかった。ソースを読んだところ、どうやらファイルオブジェクトにして渡してあげればいいようだ。

{{< highlight ruby "linenos=pre" >}}
class Photo < ActiveRecord::Base
  has_attached_file :image
end
{{< / highlight >}}

こんなモデルだったとしたら、

{{< highlight ruby "linenos=pre" >}}
file = "tmp/foo.jpg"
photo = Photo.new
photo.image = File.new(file)
photo.save!
{{< / highlight >}}

こんな風に書けば代入できる。
