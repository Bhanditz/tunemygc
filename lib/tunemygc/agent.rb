# encoding: utf-8

require "tunemygc/tunemygc_ext"
require "tunemygc/version" unless defined? TuneMyGc::VERSION
require "tunemygc/interposer"
require "tunemygc/snapshotter"
require "logger"

module TuneMyGc
  MUTEX = Mutex.new

  attr_accessor :logger, :interposer, :snapshotter

  def snapshot(stage, meta = nil)
    snapshotter.take(stage, meta)
  end

  def raw_snapshot(snapshot)
    snapshotter.take_raw(snapshot)
  end

  def log(message)
    logger.info "[TuneMyGC] #{message}"
  end

  def reccommendations
    MUTEX.synchronize do
      require "tunemygc/syncer"
      syncer = TuneMyGc::Syncer.new
      config = syncer.sync(snapshotter)
      require "tunemygc/tuner"
      TuneMyGc::Tuner.new(config).configure
    end
  rescue Exception => e
    log "Config reccommendation error (#{e.message})"
  end

  extend self

  MUTEX.synchronize do
    self.logger = Logger.new($stdout)
    self.interposer = TuneMyGc::Interposer.new
    self.snapshotter = TuneMyGc::Snapshotter.new
  end
end