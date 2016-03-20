require 'terminal-table'
require 'paint'

module Rukawa
  class Runner
    DEFAULT_REFRESH_INTERVAL = 3

    def self.run(job_net, batch_mode = false, refresh_interval = DEFAULT_REFRESH_INTERVAL)
      new(job_net).run(batch_mode, refresh_interval)
    end

    def initialize(root_job_net)
      @root_job_net = root_job_net
      @errors = []
    end

    def run(batch_mode = false, refresh_interval = DEFAULT_REFRESH_INTERVAL)
      Rukawa.logger.info("=== Start Rukawa ===")
      futures = @root_job_net.dataflows.each(&:execute)
      until futures.all?(&:complete?)
        display_table unless batch_mode
        sleep refresh_interval
      end
      Rukawa.logger.info("=== Finish Rukawa ===")

      display_table unless batch_mode

      collect_errors(@root_job_net)

      unless @errors.empty?
        @errors.each do |err|
          Rukawa.logger.error(err)
        end
        return false
      end

      true
    end

    private

    def display_table
      table = Terminal::Table.new headings: ["Job", "Status"] do |t|
        @root_job_net.each_with_index do |j|
          table_row(t, j)
        end
      end
      puts table
    end

    def table_row(table, job, level = 0)
      if job.is_a?(JobNet)
        table << [Paint["#{"  " * level}#{job.class}", :bold, :underline], job.state.colored]
        job.each do |inner_j|
          table_row(table, inner_j, level + 1)
        end
      else
        table << [Paint["#{"  " * level}#{job.class}", :bold], job.state.colored]
      end
    end

    def collect_errors(job_net)
      job_net.each do |j|
        if j.is_a?(JobNet)
          collect_errors(j)
        else
          @errors << j.dataflow.reason if j.dataflow.reason
        end
      end
    end
  end
end
