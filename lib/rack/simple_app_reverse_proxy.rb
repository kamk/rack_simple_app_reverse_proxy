module Rack
  class SimpleAppReverseProxy
    
    def initialize(app, options = {})
      @app = app
      raise "Please specify :uri of remote application." unless options[:uri]
      options[:uri].chop! if options[:uri][-1] == "/"
      @remote_uri = URI(options[:uri])
      if @remote_uri.scheme != "http"
        raise "Only http:// scheme is supported."
      end
      @expand_paths = Array(options[:expand_paths])
    end


    def call(env)
      if env["PATH_INFO"] =~ %r{^#{@remote_uri.path}}
        result = nil
        Net::HTTP.start(@remote_uri.host) do |http|
          req_headers = Rack::Utils::HeaderHash.new
          env.each do |h, v|
            next if h == "HTTP_HOST"
            next unless h =~ /^HTTP_/
            req_headers[h.sub(/^HTTP_/, "")] = v
          end
          req_headers["Content-Type"] = env["CONTENT_TYPE"] if env["CONTENT_TYPE"]
          req_headers["Content-Length"] = env["CONTENT_LENGTH"] if env["CONTENT_LENGTH"]
          req_headers["X-Forwarded-For"] = %w(REMOTE_ADDR SERVER_ADDR).map{ |v| env[v] } \
                                                                      .join(", ")

          begin
            if env["REQUEST_METHOD"] == "POST"
              raw_post = env["rack.input"].read
              env["rack.input"].rewind
              result = http.post(env["REQUEST_URI"], raw_post, req_headers)
            else
              result = http.get(env["REQUEST_URI"], req_headers)
            end
          rescue
            return [ 502,
                     { "Content-Type" => "text/plain; charset=utf-8" },
                     ["Request cannot be completed"]
                   ]
          end
        end

        return @app.call(env) unless result
        if result["location"]
          return [result.code, { "Location" => result["location"] }, [result.body]]
        end
        if result.is_a?(Net::HTTPOK) && result["content-type"] =~ %r{^text/html}
          doc = Nokogiri::HTML(result.body)
          header = doc / 'head'
          header.search("title").remove
          env["app_proxy.head"] = expand_rel_paths(header.inner_html)
          env["app_proxy.body"] = expand_rel_paths((doc / 'body').inner_html)
        else
          res_headers = { "Content-Type" => result["content-type"] }
          res_headers["Set-Cookie"] = result["Set-Cookie"] if result["set-cookie"]
          return [result.code, res_headers, [result.body]]
        end
      end
      @app.call(env)
    end
  
  
    private
    def expand_rel_paths(data)
      @expand_paths.each do |p|
        data.gsub!("./#{p}", "#{@remote_uri}/#{p}")
      end
      return data
    end
    
  end
end