# frozen_string_literal: true

module Rack
  # Simple rack based appliction proxy
  # TODO: add documentation
  class SimpleAppReverseProxy
    CONTENT_HEADERS = {

    }

    def initialize(app, options = {})
      @app = app
      raise 'Please specify :uri of remote application.' unless options[:uri]

      options[:uri].chop! if options[:uri][-1] == '/'
      @remote_uri = URI(options[:uri])
      raise 'Only http:// scheme is supported.' if @remote_uri.scheme != 'http'

      @expand_paths = Array(options[:expand_paths])
    end


    def call(env)
      if env['PATH_INFO'] =~ /^#{@remote_uri.path}/
        result = fetch_from_target(env)
        return [result.code, { 'Location' => result['location'] }, [result.body]] if result['location']

        if result.is_a?(Net::HTTPOK) && result['content-type'] =~ %r{^text/html}
          doc = Nokogiri::HTML(result.body)
          header = doc / 'head'
          header.search('title').remove
          env['app_proxy.head'] = expand_rel_paths(header.inner_html)
          env['app_proxy.body'] = expand_rel_paths((doc / 'body').inner_html)
        else
          res_headers = { 'Content-Type' => result['content-type'] }
          res_headers['Set-Cookie'] = result['Set-Cookie'] if result['set-cookie']
          return [result.code, res_headers, [result.body]]
        end
      end
      @app.call(env)
    rescue StandardError
      [
        502,
        { 'Content-Type' => 'text/plain; charset=utf-8' },
        ['Request cannot be completed']
      ]
    end

    private

    def fetch_from_target(env)
      Net::HTTP.start(@remote_uri.host) do |http|
        if env['REQUEST_METHOD'] == 'POST'
          raw_post = env['rack.input'].read
          env['rack.input'].rewind
          http.post(env['REQUEST_URI'], raw_post, req_headers)
        else
          http.get(env['REQUEST_URI'], req_headers)
        end
      end
    end


    def prepare_req_headers(env)
      req_headers = Rack::Utils::HeaderHash.new
      env.each do |h, v|
        req_headers[h.sub(/^HTTP_/, '')] = v if h != 'HTTP_POST' && h =~ /^HTTP_/
      end
      {
        'Content-Type' => 'CONTENT_TYPE',
        'Content-Length' => 'CONTENT_LENGTH'
      }.each do |header_attr, env_attr|
        req_headers[header_attr] = env[env_attr] if env[env_attr]
      end
      req_headers['X-Forwarded-For'] = %w[REMOTE_ADDR SERVER_ADDR].map { |v| env[v] } \
                                                                  .join(', ')
      req_headers
    end


    def expand_rel_paths(data)
      @expand_paths.each do |p|
        data.gsub!("./#{p}", "#{@remote_uri}/#{p}")
      end
      data
    end
  end
end
