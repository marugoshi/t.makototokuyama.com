---
title: "コピーした VMWare の Ubuntu イメージでネットにつながらなくなったら"
date: "2010-08-16T00:00:00+09:00"
draft: false
---
VMWare の Ubuntu イメージはイメージの Identifier と MAC アドレスを組み合わせたものをファイルに記載して保存している。イメージをコピーすると立ち上がるけど、このファイルが違うと判断されてインターネットには繋がらない。

解決方法は簡単で、該当のファイルがなければ起動時に勝手に作ってくるので、ただファイルを消せば良い。

{{< highlight sh >}}
rm /etc/udev/rules.d/70-persistent-net.rules
{{< / highlight >}}
