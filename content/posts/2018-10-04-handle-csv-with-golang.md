---
title: "Golang で CSV を扱う"
date: "2018-10-04T00:00:00+09:00"
draft: false
---
[前回は Golang のローカル開発環境について](/posts/2018-10-02-setup-golang/)書いた。今回はコードを書いてみる。[Docker を触ったときにも書いた通り](posts/2018-09-09-docker-with-ruby/)、書くからには動くものを書きたい。ということで、そのときに書いた ruby のコードを go で書きなおしてみようと思う。ファイルの入出力、文字コード周りは実用的でよい演習になりそうだ。

## ファイル構成

{{< highlight plain >}}
.
├── data/
|   ├── src.csv
|   └── dst.csv
├── vendor/ # (dep が生成)
├── converter.go
├── converter_test.go
├── Gopkg.lock
├── Gopkg.toml # (dep が生成)
└── main.go
{{< / highlight >}}

## dep

go のパッケージングマネージャー。以前は別パッケージだったらしいけど、現在は本家に取り込まれている。ということで、こいつを使っておけばいいんだろうな。

{{< highlight bash >}}
go get -u github.com/golang/dep/cmd/dep
{{< / highlight >}}

### 初期化

{{< highlight bash >}}
dep init
{{< / highlight >}}

プロジェクトルートで打つと `Gopkg.toml` `Gopkg.lock` `vendor/` を生成してくれる。

### 必要な外部ライブラリのインストール

{{< highlight bash >}}
dep ensure
{{< / highlight >}}

コードの中にある import を解析してダウンロードして `vendor` ディレクトリに保存してくれる。ライブラリ同士のバージョン依存性も解決してくれるようだ。便利すぎる。

## ソース

ruby のときはだーっと書いたけど、今回は go の機能に触れる意味をこめて interface を使ってみる。といっても今回のサンプルではあまり意味のない使い方だけど。

### main.go

{{< highlight go "linenos=pre" >}}
package main

import (
	"fmt"
	"os"
)

const SRC_PATH = "./data/src.csv"
const DST_PATH = "./data/dst.csv"

func main() {
	converter := NewConverter(SRC_PATH, DST_PATH, false)
	if err := converter.Execute(); err != nil {
		fmt.Print(err.Error())
		os.Exit(2)
	}
	os.Exit(0)
}
{{< / highlight >}}

同じ階層にある converter を生成して処理結果を判別して終了している。

### converter.go

{{< highlight go "linenos=pre" >}}
package main

import (
	"encoding/csv"
	"github.com/pkg/errors"
	"golang.org/x/text/encoding/japanese"
	"golang.org/x/text/transform"
	"io"
	"os"
	"strings"
)

type Converter interface {
	Execute() error
}

type converter struct {
	srcPath  string
	dstPath  string
	hasIndex bool
}

func NewConverter(srcPath string, dstPath string, hasIndex bool) Converter {
	return &converter{srcPath: srcPath, dstPath: dstPath, hasIndex: hasIndex}
}

func (c *converter) Execute() error {
	reader, readerClose, err := c.getReader()
	if err != nil {
		return err
	}
	readerClose()

	writer, writerClose, err := c.getWriter()
	if err != nil {
		return err
	}
	writerClose()

	i := 0
	for {
		record, err := reader.Read()
		if err == io.EOF {
			break
		}
		if c.hasIndex && i == 0 {
			continue
		}
		writer.Write(c.createNewRecord(record))
		i++
	}
	writer.Flush()

	return nil
}

func (c *converter) getReader() (*csv.Reader, func(), error) {
	srcFile, err := os.Open(c.srcPath)
	if err != nil {
		return nil, nil, errors.Wrapf(err, "can not open %s", c.srcPath)
	}
	reader := csv.NewReader(transform.NewReader(srcFile, japanese.ShiftJIS.NewDecoder()))
	reader.LazyQuotes = true
	return reader, func() { defer srcFile.Close() }, nil
}

func (c *converter) getWriter() (*csv.Writer, func(), error) {
	dstFile, err := os.Create(c.dstPath)
	if err != nil {
		return nil, nil, errors.Wrapf(err, "can not create %s", c.dstPath)
	}
	return csv.NewWriter(dstFile), func() { defer dstFile.Close() }, nil
}

func (c *converter) createNewRecord(src []string) []string {
	var dst []string
	dst = append(dst, c.normalizeCompanyName(src[0]))
	dst = append(dst, src[1])
	dst = append(dst, src[2])
	return dst
}

func (c *converter) normalizeCompanyName(s string) string {
	s = strings.Replace(s, "㈱", "株式会社", -1)
	s = strings.Replace(s, "㈲", "有限会社", -1)
	s = strings.Replace(s, "（", "(", -1)
	s = strings.Replace(s, "）", ")", -1)
	s = strings.Replace(s, "(株)", "株式会社", -1)
	s = strings.Replace(s, "(有)", "有限会社", -1)
	return s
}
{{< / highlight >}}

* import
  * 日本語変換にはふたつ公式の外部パッケージを使っている。
  * また標準エラーの薄いラッパー pkg/errors も使っている。シンプルで使い勝手良い。
* interface
  * 公開メソッドのインターフェースのみを定義してあり、そのメソッドを定義することでその intarface の型として振舞うことができる。
* struct
  * 引数を持つだけの構造体。
	* メソッドも変数も、小文字始まりにすると private になる。
* Execute()
  * Converter interface の実装。
	* このメソッドのみを公開していて、それ以外は private メソッドになる。テストはホワイトテストをたくさん書く感じで後ほど。
	* 処理の流れは以下の通り。
	  1. 元になるファイルの reader を取得する
		1. 書き出し先のファイルの writer を取得する
		1. ファイルの終端まで reader から 1 行ずつ読み込む
		1. writer のバッファに 1 行ずつ書き込む
		1. flush してファイルに書き込む
	* それぞれの処理でエラーが発生した場合はメッセージを付与してエラーを返す。
* getReader()
  * io.Reader インターフェースを使った csv.Reader を生成する。読み込むだけで csv をパースしてくれる。
	* transform.Reader を使うことで文字コードの変換をしつつ読み込んでくれる。
	* 返り値でメソッドを返しているのは、このメソッドの中で close してしまうとそこでファイルが閉じて読み込みができなくなってしまうため。converter struct の中にファイルポインタを指定するのでもいいんだろうけど、暗黙的にどこかで値がセットされるよりは明示的な方がいいかなと思ってこうしている。どうなんだろうね。
	* defer はメソッドの最後で実行される。どこかで panic が起きても実行されるけど、exit が起きると実行しないらしい。
* getWriter()
  * 書き込むファイルを生成。
	* io.Writer インターフェースを使った csv.Writer を生成する。ここは普通の writer でもいいような気もするけど試していない。わざわざ実装があるってことは使った方がいいんだろうな、くらい。必要があったら勝手にクオートしてくれたりするのかな？
* createNewRecord(src []string)
  * CSV の 1 行を作って返す。
* normalizeCompanyName(s string)
  * 文字列の置換を試す。会社名に略語などが入っていた場合、揺らぎを統一するような処理を入れてみる。機種依存文字が問題なく読み込めているかも試す。

ざっとこんな感じかな。シンプルに書けるけど error はやはり面倒だと感じる。次はテストも書いてみるか。

## 参考

* [Go言語でCSVの読み書き(sjis、euc、utf8対応](https://qiita.com/kesuzuki/items/202cc58db3fd1763c095)
* [Go言語 - Shift_JISファイルの読み書き - hakeの日記](https://hake.hatenablog.com/entry/20150817/p1)
* [Gos.Exit()とdefer](https://qiita.com/umisama/items/7be04949d670d8cdb99c)
* [src/cmd/gofmt/gofmt.go - The Go Programming Language](https://golang.org/src/cmd/gofmt/gofmt.go)
