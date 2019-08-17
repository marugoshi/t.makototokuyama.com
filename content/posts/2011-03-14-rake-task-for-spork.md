---
title: "sprok 用の rake タスク"
date: "2011-03-14T00:00:00+09:00"
draft: false
---
たまに言うことを聞かなくなることがあるので再起動したいと思い、愚直に書いてみた。とはいえ、すぐに guard に乗り換えてしまったので出番はあまりないのだった。

{{< highlight ruby "linenos=pre" >}}
namespace :spork do
 desc "start spork in background"
 task :start do
   sh %{spork &}
 end

 desc "stop spork"
 task :stop do
   Process.kill(:TERM, `ps -ef | grep spork | grep -v grep | awk '{ print $2 }'`.to_i)
 end

 desc "restart spork"
 task :restart => [:stop, :start]
end
{{< / highlight >}}
