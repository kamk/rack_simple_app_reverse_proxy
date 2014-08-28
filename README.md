# RackSimpleAppReverseProxy

This is a simple reverse proxy that fetches an html page from remote resource and splits it in terms of header and body. Two environment variables are created:

* app_proxy.head - contains inner part of `<head>`...`</head>`
* app_proxy.body - similiary it's of the `<body>`...`</body>`

This is useful for embedding a foreign app into our own. In production, you can see as it serves merging phpBB forum with the Rails application [right here](http://www.cestadreva.cz/diskuze/).

## Installation

Add this line to your application's Gemfile:

    gem 'rack_simple_app_reverse_proxy'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rack_simple_app_reverse_proxy

## Usage

When used in Rails environment, include it as middleware. Add to your `application.rb` the following:

    config.middleware.use "Rack::SimpleAppReverseProxy",
                          :uri => "http://remote.host.name/remote/path",
                          :expand_paths => %w(styles)

The `expand_paths` options is an array of relative paths that should be expanded. For the example above it means rewriting as following:

    ./styles/x/y/z  ->  http://remote.host.name/remote/path/styles/x/y/z

Next, you need to enhance your layout by including header part. In the layout in `<head>`...`</head>` section you will want to add:

    <%= request.env["app_proxy.head"] %>

And into the view that renders remote app's body you simply add: 

    <%= request.env["app_proxy.body"] %>


## Todo

* write tests
