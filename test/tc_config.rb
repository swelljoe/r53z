require "test/unit"
require_relative "../lib/config"

class TestConfig < Test::Unit::TestCase
  def test_creds
    creds = R53z::Config.new('test/data/credentials')
    assert_match('TESTKEY', creds['default']['aws_access_key_id'])
    assert_match('SECRETKEY', creds['default']['aws_secret_access_key'])
    assert_match('REGION', creds['default']['region'])
  end
end

