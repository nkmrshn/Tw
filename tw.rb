#!/usr/bin/env ruby
#
# Tw 
# Copyright (c) 2012 nkmrshn
# MIT License Applies
#
require 'fileutils'
require 'yaml'
require 'rubygems'
require 'oauth'
require 'json'

class Tw
  CONFIG_FILE   = ".twrc"
  URL = /(^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?$)/ix
  EXT = /\.(jpe?g|gif|png)$/i
  CRLF = "\r\n"

  # Twitter API
  KEY                   = 'consumer_key'
  SECRET                = 'consumer_secret'
  TOKEN                 = 'access_token'
  TOKEN_SECRET          = 'access_token_secret'
  MAX_LENGTH            = 140
  TWITTER_API           = 'http://api.twitter.com'
  UPDATE_URL            = 'https://api.twitter.com/1.1/statuses/update.json'
  UPDATE_WITH_MEDIA_URL = 'https://api.twitter.com/1.1/statuses/update_with_media.json'

  # Google URL Shortener API
  ACCESS_KEY     = 'google_api_access_key'
  GOOGLE_API     = 'www.googleapis.com'
  SHORTENER_PATH = '/urlshortener/v1/url'

  def initialize
    config_file = File.join(File.expand_path('~'), CONFIG_FILE)

    begin
      @config = YAML.load(File.read(config_file))
    rescue
      @config = {
        KEY          => prompt(KEY),
        SECRET       => prompt(SECRET),
        TOKEN        => prompt(TOKEN),
        TOKEN_SECRET => prompt(TOKEN_SECRET),
        ACCESS_KEY   => prompt(ACCESS_KEY)
      }

      File.open(config_file, 'w') {|f| f.write(@config.to_yaml)}
      FileUtils.chmod(0600, config_file)
      puts "saved to #{config_file}"
    end
  end

  def post(status, filename = nil)
    unless status.empty? && status.split('').length > MAX_LENGTH
      url = UPDATE_URL
      headers = nil
      body = {:status => status}

      if !filename.nil? && File.exists?(filename) && valid_extension?(filename) 
        filename = File.expand_path(filename)
        url = UPDATE_WITH_MEDIA_URL
        boundary = make_boundary
        headers = {"Content-Type" => "multipart/form-data; boundary=" + boundary}
        body = make_multipart_body(status, filename, boundary)
      end

      get_token.post(url, body, headers) unless body.nil?
    else
      nil
    end
  end

  def shorten_if_url(string)
    URL =~ string ? shorten_url($1) : string
  end

  def valid_extension?(filename)
    EXT =~ filename
  end

  private

  def prompt(string)
    print string.gsub('_', ' ').capitalize + ":"
    gets.strip
  end

  def shorten_url(long_url)
    params = {'longUrl' => long_url}
    params.store('key', @config[ACCESS_KEY]) if @config[ACCESS_KEY] && !@config[ACCESS_KEY].empty?
    response = ''

    http = Net::HTTP.new(GOOGLE_API, 443)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    response = http.post(SHORTENER_PATH, params.to_json, {'Content-Type' => 'application/json'})

    return Net::HTTPOK === response ? (JSON.parse(response.body))['id'] : long_url
  end

  def make_multipart_body(status, filename, boundary)
    begin
      body = ""
      body << "--" + boundary + CRLF
      body << "Content-Disposition: form-data; name=\"status\"" + CRLF * 2
      body << status + CRLF
      body << "--" + boundary + CRLF
      body << "Content-Type: application/octet-stream" + CRLF
      body << "Content-Disposition: form-data; name=\"media[]\"; filename=\"" + File.basename(filename) + "\"" + CRLF * 2
      File::open(filename){|f| body << f.read  + CRLF}
      body << "--" + boundary + "--" + CRLF
    rescue
      nil
    end
  end

  def make_boundary
    (('a'..'z').to_a + ('A'..'Z').to_a + (0..9).to_a).shuffle[0..69].join
  end

  def get_token
    consumer = OAuth::Consumer.new(@config[KEY],
                                   @config[SECRET],
                                   :site => TWITTER_API)
    token_hash = {
      :oauth_token        => @config[TOKEN],
      :oauth_token_secret => @config[TOKEN_SECRET]
    }

    OAuth::AccessToken.from_hash(consumer, token_hash)
  end
end


tw = Tw.new
status = ''
filename = nil

ARGV.each_with_index do |argv, idx|
  if tw.valid_extension?(argv) && idx == ARGV.length - 1
    filename = argv
    break
  end

  status += ' ' unless status.empty?
  status += tw.shorten_if_url(argv)
end

puts Net::HTTPOK === tw.post(status, filename) ? 'posted.' : 'failed.' unless status.empty?
