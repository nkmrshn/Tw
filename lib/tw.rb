require 'yaml'
require 'rubygems'
require 'oauth'
require 'json'

class Tw
  CONFIG_PATH     = "~"
  CONFIG_FILENAME = ".twrc"
  CONFIG_MODE     = 0600
  
  URL  = /(^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?$)/ix
  EXT  = /\.(jpe?g|gif|png)$/i
  CRLF = "\r\n"

  # Twitter API
  CONSUMER_KEY          = 'consumer_key'
  CONSUMER_SECRET       = 'consumer_secret'
  ACCESS_TOKEN          = 'access_token'
  ACCESS_TOKEN_SECRET   = 'access_token_secret'
  MAX_LENGTH            = 140
  TWITTER_API           = 'http://api.twitter.com'
  UPDATE_URL            = 'https://api.twitter.com/1.1/statuses/update.json'
  UPDATE_WITH_MEDIA_URL = 'https://api.twitter.com/1.1/statuses/update_with_media.json'

  # Google URL Shortener API
  GOOGLE_ACCESS_KEY = 'google_access_key'
  GOOGLE_API        = 'www.googleapis.com'
  SHORTENER_PATH    = '/urlshortener/v1/url'

  CONFIG = [CONSUMER_KEY, CONSUMER_SECRET, ACCESS_TOKEN, ACCESS_TOKEN_SECRET, GOOGLE_ACCESS_KEY]
  CONFIG.each {|c| attr_accessor c.to_sym}

  attr_accessor :config_file

  def initialize(config_path = File.expand_path(CONFIG_PATH), config_filename = CONFIG_FILENAME)
    @config_file = File.join(config_path, config_filename)
  end

  def load_config
    begin
      YAML.load(File.read(@config_file)).each {|key, value| instance_variable_set("@#{key}", value) }
    rescue
      raise
    end
  end

  def save_config
    begin
      config = {}
      CONFIG.each {|c| config[c] = instance_variable_get("@#{c.downcase}")}
      File.open(@config_file, 'w') {|f| f.write(config.to_yaml) }
      FileUtils.chmod(CONFIG_MODE, @config_file)
    rescue
      raise
    end
  end

  def post(status, filename = nil)
    return nil if status.nil? || status.empty? || status.split('').length > MAX_LENGTH

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
  end

  def shorten_if_url(string)
    URL =~ string ? shorten_url($1) : string
  end

  def valid_extension?(filename)
    EXT =~ filename
  end

  private

  def shorten_url(long_url)
    return long_url if @google_access_key.nil? || @google_access_key.empty?

    params = {'longUrl' => long_url, 'key' => @google_access_key}
    response = ''

    http = Net::HTTP.new(GOOGLE_API, 443)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    response = http.post(SHORTENER_PATH, params.to_json, {'Content-Type' => 'application/json'})

    Net::HTTPOK === response ? (JSON.parse(response.body))['id'] : long_url
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
    consumer = OAuth::Consumer.new(@consumer_key,
                                   @consumer_secret,
                                   :site => TWITTER_API)
    token_hash = {
      :oauth_token        => @access_token,
      :oauth_token_secret => @access_token_secret
    }

    OAuth::AccessToken.from_hash(consumer, token_hash)
  end
end
