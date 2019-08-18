---
title: "Golang で CSV を扱う"
date: "2018-10-04T00:00:00+09:00"
draft: true
---
[前回は Golang のローカル開発環境について](/posts/2018-10-02-setup-golang/)書いた。今回はコードを書いてみる。[Docker を触ったときにも書いた通り](posts/2018-09-09-docker-with-ruby/)、書くからには動くものを書きたい。ということで、そのときに書いた ruby のコードを go で書きなおしてみようと思う。ファイルの入出力、文字コード周りは実用的でよい演習になりそうだ。

## ファイル構成

{{< highlight plain >}}
.
├── data/
|   └── sample.csv
└── main.go
{{< / highlight >}}


## main.go

コード内コメントは書きながらメモったこと。

{{< highlight go "linenos=pre" >}}
// パッケージ宣言。名前空間をわけるための仕組み。
// mainパッケージとその中のmain関数だけは特殊でエントリーポイントになる模様。
// 通常はディレクトリ単位でパッケージを切るようだ。
package main

// インポート文。ほとんどのIDEやエディタでは自動で入力してくれる。
// importしてるのに使ってないパッケージがあるとコンパイルできない。
//
// 日本語変換にはふたつ公式の外部パッケージを使っているので別途ダウンロードした。
// go get golang.org/x/text/transform
// go golang.org/x/text/transform
// $HOME/go/srcにソース、$HOME/go/pkgに静的ライブラリが配置された。
import (
	"encoding/csv"
	"fmt"
	"golang.org/x/text/encoding/japanese"
	"golang.org/x/text/transform"
	"io"
	"os"
	"strings"
)

// エントリポイント。
// 取得と書き出しで元のCSV行が2回ループしていて少し冗長だけど、
// * ファイル操作をメソッド内で完結させたい
// * どちらかがファイルではなくDBになるなどの差し替え可能性(ないけど)
// * 上記含めてテストを書きやすくしたい
// と思ってこんな形に。もっといい設計がありそうな気する。
func main() {
  // :=で代入と型の省略を行える。
  // rubyのような言語からくるとキモく感じる。
  // C#をからくると導入してくれないかなという気持ちになる。
	records := readCsv("./data/in.csv")
	if records == nil {
		fmt.Print("records not found.")
		os.Exit(2)
	}
	writeCsv("./data/out.csv", records)
	os.Exit(0)
}

func readCsv(path string) [][]string {
  // ファイルのオープン。
  // エラーについてはいろいろありそうだけど今回は受け取って表示して抜けるだけ。
	f, err := os.Open(path)
	if err != nil {
		fmt.Printf("error occured in read file:\n  %s", err)
		os.Exit(2)
	}

  // rubyで言うensureみたいなものという認識。
  // ただpanicでは実行されるけどexitでは実行されないとかいろいろあるらしい。
	defer f.Close()

  // CSVを読み組む構造体を作る。SJISでデコードするように。
	reader := csv.NewReader(transform.NewReader(f, japanese.ShiftJIS.NewDecoder()))
	reader.LazyQuotes = true

  // 多重配列の定義。mallocみたいなもの？と思ったけどサイズは固定じゃないからちょっと違うな。
  // 要素数を可変にしたい場合、第2引数のサイズは0を指定。
  // appendで増やしていく。
	records := make([][]string, 0)

	i := 0
	for {
		record, err := reader.Read()
    // ファイルの終わりなら抜ける。
    // データ量によってはストリームで読み込む必要がないためreader.ReadAll()でまとめて。
		if err == io.EOF {
			break
		}
		if i > 0 {
			records = append(records, record)
		}
		i++
	}
	return records
}

func writeCsv(path string, records [][]string) {
  // ファイル作成。
	f, err := os.Create(path)
	if err != nil {
		fmt.Printf("error occured in create file:\n  %s", err)
		os.Exit(2)
	}
	defer f.Close()

	writer := csv.NewWriter(f)

  // 1行ずつ元のレコードを加工したものを書き込み。
  // ここではバッファに貯めるだけで、Flushで実際に書き込まれる。
	for _, v := range records {
		writer.Write(createNewRecord(v))
	}
	writer.Flush()
}

func createNewRecord(old []string) []string {
	var new []string
	new = append(new, normalizeCompanyName(old[0]))
	new = append(new, old[1])
	new = append(new, old[2])
	return new
}

func normalizeCompanyName(s string) string {
	s = strings.Replace(s, "㈱", "株式会社", -1)
	s = strings.Replace(s, "㈲", "有限会社", -1)
	s = strings.Replace(s, "（", "(", -1)
	s = strings.Replace(s, "）", ")", -1)
	s = strings.Replace(s, "(株)", "株式会社", -1)
	s = strings.Replace(s, "(有)", "有限会社", -1)
	return s
}
{{< / highlight >}}
