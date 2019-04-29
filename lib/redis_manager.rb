# frozen_string_literal: true
require 'redis'

class RedisManager
  TTL = (60 * 10).freeze # 10 minutes

  attr_reader :instance

  def initialize
    @instance = Redis.new(host: '127.0.0.1', port: 6379, db: 1)
  end

  # @param [String] key
  # since Redis is single-threaded, the result of setnx provides a mechanism
  # for locking
  def lock_on_key?(key)
    instance.setnx(key, 'STARTING')
  end

  def update_expiration(key)
    instance.expire(key, TTL)
  end
end
