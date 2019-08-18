---
title: "Docker で ruby を動かす"
date: "2018-09-09T00:00:00+09:00"
draft: false
---
[近況に書いた通り](/posts/2018-08-13-current-situation/)、次の環境ではいろいろと新しいことをやろうと思っている。そのひとつが Fargate の上で Rails を動かすというもの。これも書いた通りエンジニアが自分ひとりなので、できる限り寄り添わなくていいインフラ構成にしたい。

それについてはいずれ書くとして、まずは基本的な Docker を動かすことについて書く。Docker とはなんぞやとか、コンテナ技術についてとか、座学については一通りざっと読んだ。ただ前職でプロジェクトでゼロから構築して運用したことはないので基本的なところから動かして学んでいく。

で、動かすというからには実際に使うものを書きたい。ちょうど知人の依頼で CSV ファイルの文字コードを変換して必要な列だけを抜き出して別ファイルに書き出す、というお手伝いが発生したのでこれを課題にしてみる。実際にはそこで終わりではなくて、生成されたファイルを元にごにょごにょした処理をする部分もあるけどそこは都合により割愛。

## ファイル構成

{{< highlight plain >}}
.
├── data/
|   └── sample.csv
├── converter.rb
├── Dockerfile
└── Gemfile
{{< / highlight >}}

## Gemfile

{{< highlight ruby "linenos=pre" >}}
source :rubygems
gem "roo"
{{< / highlight >}}

好き嫌いはあるかと思うけえど、そんなに頑張らずにやりたいので CSV のパース処理は roo を使う。

## converter.rb

{{< highlight ruby "linenos=pre" >}}
#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require "rubygems"
require "csv"
require "bundler/setup"
Bundler.require

SRC_PATH = "./data/sample.csv"
DST_PATH = "./data/out.csv"
puts "file does not exist." and exit 1 unless FileTest.exists? SRC_PATH

win31 = Encoding::Windows_31J
utf8 = Encoding::UTF_8
File.write(SRC_PATH, File.read(SRC_PATH, encoding: win31).encode(utf8))

new_lines = []
lines = CSV.read SRC_PATH
lines.each_with_index do |line, i|
  line = line.map { |s| s.strip if s }
  new_line = []
  new_line << line[0]
  new_line << line[10]
  new_line << line[20]
  new_lines << new_line.join(",")
end

File.write(DST_PATH, new_lines.join("\n"))
File.delete(SRC_PATH)
{{< / highlight >}}

エンコードして直接上書きしちゃったりとか、もろもろ雑なのはご愛嬌。

## Dockerfile

{{< highlight docker "linenos=pre" >}}
FROM ruby:2.5
ENV LANG C.UTF-8

WORKDIR /usr/src/app

COPY Gemfile ./
RUN bundle install

COPY . .

CMD  ["./converter.rb"]
{{< / highlight >}}

あまり難しいことは考えず run したらプログラムが走るようにするだけ。


## イメージ操作

### 作る。

{{< highlight sh >}}
docker image build -t marugoshi/csv-converter:latest .
{{< / highlight >}}

### 見る。

{{< highlight sh >}}
docker image ls
{{< / highlight >}}

### 消す。

{{< highlight sh >}}
docker image rm ID
{{< / highlight >}}

### 使われていないイメージを消す。

{{< highlight sh >}}
docker image prune
{{< / highlight >}}

## コンテナ操作

### 立ち上げる。

{{< highlight sh >}}
docker run --rm -it -v $PWD/data:/usr/src/app/data marugoshi/csv-converter
{{< / highlight >}}

今回のように常時起動しないものは -rm オプションを渡すことで実行後に削除されるようだ。  
ホスト側でファイルを取り出したいので -v でデータ用のディレクトリをマウントしている。

### 見る。
{{< highlight sh >}}
docker container ls
{{< / highlight >}}

### 使われていないコンテナを消す。
{{< highlight sh >}}
docker container prune
{{< / highlight >}}

## 余談

自分はとにかく短いエイリアスを作るのが大好きなので (たとえば `alias q='exit'` とか `alias m='make'` とか) このあたりのコマンドもすぐにエリアスを作った。直感的じゃないのでちょっとキモい。 docker 周りはとにかくコマンドが長いのがつらい。いずれ書くけど Makefile が再熱するのよくわかる。

{{< highlight sh "linenos=pre" >}}
alias dok='docker'
alias doki='docker image'
alias dokc='docker container'
{{< / highlight >}}
