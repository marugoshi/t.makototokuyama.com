---
title: "rails3-generator を使う"
date: "2010-10-20T00:00:00+09:00"
draft: false
---
rails には generator がありファイルを作ってくれる。


{% highlight bash linenos %} rails g model hoge rails g controller hoge rails g scaffold hoge rails g rspec_model hoge {% endhighlight %}

But how do I generate plug-in files?

rails3-generator

The rails3-generator gem extends Rails3 generator in the smart way. It can generate files about remarkable add-on which we must use like RSpec, authlogic, jQuery, haml and many others with rails generate command.

If you want to know how rails generate works, check railties-3.0.0/lib/rails/generators.rb. There is a instance value named hidden_namespaces and rails3-generators uses it.

This is examples to use RSpec and jQuery.

{% highlight bash linenos %} rails g rspec:install create .rspec create spec create spec/spec_helper.rb create autotest create autotest/discover.rb rails g jquery:install remove public/javascripts/controls.js remove public/javascripts/dragdrop.js remove public/javascripts/effects.js remove public/javascripts/prototype.js create public/javascripts/jquery.min.js create public/javascripts/jquery.js create public/javascripts/rails.js {% endhighlight %}

If you want to use FactoryGirl, you have to change #{Rails.root}/config/appplication.rb like this. Default fixture replacement is fixtures, so it needs override the setting.

{% highlight ruby linenos %} config.generators do |g| g.test_framework :rspec, :fixture => true, :views => false g.fixture_replacement :factory_girl, :dir => "spec/factories" end {% endhighlight %}

Then try to generate model file.

{% highlight bash linenos %} rails g model hoge invoke active_record create db/migrate/20100920095812_create_hoges.rb create app/models/hoge.rb invoke rspec create spec/models/hoge_spec.rb invoke factory_girl create spec/factories/hoges.rb {% endhighlight %}

Great.
