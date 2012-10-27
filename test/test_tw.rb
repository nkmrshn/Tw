require 'test/unit'
require 'tempfile'
require 'rubygems'
require 'webmock'
require 'json'
require 'tw'

class TC_Tw < Test::Unit::TestCase
  T_CONSUMER_KEY        = "test_consumer_key"
  T_CONSUMER_SECRET     = "test_consumer_secret"
  T_ACCESS_TOKEN        = "test_access_token"
  T_ACCESS_TOKEN_SECRET = "test_access_token_secret"
  T_GOOGLE_ACCESS_KEY   = "test_google_access_key"

  def setup
    @tw = Tw.new
    @tw.consumer_key = T_CONSUMER_KEY
    @tw.consumer_secret = T_CONSUMER_SECRET
    @tw.access_token = T_ACCESS_TOKEN
    @tw.access_token_secret = T_ACCESS_TOKEN_SECRET
    @tw.google_access_key = T_GOOGLE_ACCESS_KEY

    @tmp_config_file = Tempfile.new("tw")
    @tw.config_file = @tmp_config_file.path
  end

  def teardown
    @tmp_config_file.close(true)
  end

  def test_config_file
    tw = Tw.new
    config_path = File.expand_path(Tw::CONFIG_PATH)
    assert_equal(File.join(config_path, Tw::CONFIG_FILENAME), tw.config_file)
  end

  def test_save_config
    assert_nothing_raised do
      @tw.save_config
    end

    mode = "%o" % File::stat(@tw.config_file).mode
    assert_equal("%o" % Tw::CONFIG_MODE, mode[-3, 3])
  end

  def test_load_config
    @tw.save_config

    assert_nothing_raised do
      @tw.load_config
    end

    assert_not_nil(@tw.consumer_key)
    assert_not_nil(@tw.consumer_secret)
    assert_not_nil(@tw.access_token)
    assert_not_nil(@tw.access_token_secret)
    assert_not_nil(@tw.google_access_key)

    assert(!@tw.consumer_key.empty?)
    assert(!@tw.consumer_secret.empty?)
    assert(!@tw.access_token.empty?)
    assert(!@tw.access_token_secret.empty?)
    assert(!@tw.google_access_key.empty?)

    assert_equal(T_CONSUMER_KEY, @tw.consumer_key)
    assert_equal(T_CONSUMER_SECRET, @tw.consumer_secret) 
    assert_equal(T_ACCESS_TOKEN, @tw.access_token)
    assert_equal(T_ACCESS_TOKEN_SECRET, @tw.access_token_secret)
    assert_equal(T_GOOGLE_ACCESS_KEY, @tw.google_access_key)
  end

  def test_valid_extensions
    files = ["example.jpg", "example.jpeg", "example.gif", "example.png", "example.PNG"]
    files.each {|file| assert_match(Tw::EXT, file)}
  end

  def test_invalid_extentions
    files = ["example.bmp", "example.tiff"]
    files.each {|file| assert_no_match(Tw::EXT, file)}
  end

  def test_not_shorten_url
    url = "http://www.example.com/"
    @tw.google_access_key = ""
    assert_equal(url, @tw.shorten_if_url(url))
  end

  def test_shorten_url
    longUrl = "http://www.example.com/"
    shortUrl = "http://goo.gl/U98s"
    @tw.google_access_key = T_GOOGLE_ACCESS_KEY
    uri = 'https://' + Tw::GOOGLE_API + Tw::SHORTENER_PATH
    body = ({"kind" => "urlshortener#url", "id" => shortUrl, "longUrl" => longUrl}).to_json
    headers = {'Content-Type' => 'application/json'}
    WebMock.stub_request(:post, uri).to_return(:body => body, :headers => headers)

    assert_equal(shortUrl, @tw.shorten_if_url(longUrl))
  end

  def test_make_boundary
    actual = @tw.__send__(:make_boundary)
    assert_not_nil(actual)
    assert_match(/[a-zA-Z0-9]{62}/i, actual)
  end

  def test_make_multipart_body
    status = "test"
    filename = @tw.config_file
    boundary = @tw.__send__(:make_boundary)
    body = ""
    body << "--" + boundary + Tw::CRLF
    body << "Content-Disposition: form-data; name=\"status\"" + Tw::CRLF * 2
    body << status + Tw::CRLF
    body << "--" + boundary + Tw::CRLF
    body << "Content-Type: application/octet-stream" + Tw::CRLF
    body << "Content-Disposition: form-data; name=\"media[]\"; filename=\"" + File.basename(filename) + "\"" + Tw::CRLF * 2
    body << Tw::CRLF
    body << "--" + boundary + "--" + Tw::CRLF

    assert_equal(body, @tw.__send__(:make_multipart_body, status, filename, boundary))
  end
end
