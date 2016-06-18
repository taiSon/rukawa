require "concurrent"

module Rukawa
  class << self
    def init
      unless @initialized
        @store = Concurrent::Hash.new
        @executor = Concurrent::FixedThreadPool.new(config.concurrency)
        @semaphore = Concurrent::Semaphore.new(config.concurrency)
        @initialized = true
      end
    end
    attr_reader :store, :executor, :semaphore

    def logger
      config.logger
    end

    def configure
      yield config
    end

    def config
      Configuration.instance
    end

    def load_jobs
      job_dirs = config.job_dirs.map { |d| File.expand_path(d) }.uniq
      job_dirs.each do |dir|
        Dir.glob(File.join(dir, "**/*.rb")) { |f| load f }
      end
    end
  end
end

require 'active_support'
require "rukawa/version"
require 'rukawa/errors'
require 'rukawa/state'
require 'rukawa/dependency'
require 'rukawa/configuration'
require 'rukawa/job_net'
require 'rukawa/job'
require 'rukawa/dag'
