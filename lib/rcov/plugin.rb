# frozen_string_literal: false

require 'open-uri'
require 'net/http'
require 'circle_ci_wrapper'

module Danger
  class Coverage
    attr_reader :pr_number, :covered_percent, :files_count, :total_lines, :missed_lines

    def initialize(pr_number, coverage_report)
      coverage = JSON.parse(coverage_report)

      @pr_number = pr_number
      @covered_percent = coverage&.dig('metrics', 'covered_percent')&.round(2)
      @files_count = coverage&.dig('files')&.count
      @total_lines = coverage&.dig('metrics', 'total_lines')
      @missed_lines = @total_lines - coverage&.dig('metrics', 'covered_lines')
    end
  end

  class CoverageReport
    attr_reader :current, :previous

    def initialize(current, previous)
      @current = current
      @previous = previous
    end

    def print
      message = "```diff\n@@           Coverage Diff            @@\n"
      message << "## #{justify_text(previous.pr_number, 16)} #{justify_text('#' + current.pr_number, 8)} #{justify_text('+/-', 7)} #{justify_text('##', 3)}\n"
      message << separator_line
      message << new_line('Coverage', current.covered_percent, previous.covered_percent, '%')
      message << separator_line
      message << new_line('Files', current.files_count, previous.files_count)
      message << new_line('Lines', current.total_lines, previous.total_lines)
      message << separator_line
      message << new_line('Misses', current.missed_lines, previous.missed_lines)
      message << '```'
    end

    private

    def separator_line
      "========================================\n"
    end

    def new_line(title, current, master, symbol = nil)
      formatter = symbol ? '%+.2f' : '%+d'
      currrent_formatted = current.to_s + symbol.to_s
      master_formatted = master ? master.to_s + symbol.to_s : '-'
      prep = calulate_prep(master_formatted, current - master)

      line = data_string(title, master_formatted, currrent_formatted, prep)
      line << justify_text(format(formatter, current - master) + symbol.to_s, 8) if prep != '  '
      line << "\n"
      line
    end

    def justify_text(string, adjust, position = 'right')
      string.send(position == 'right' ? :rjust : :ljust, adjust)
    end

    def data_string(title, master, current, prep)
      "#{prep}#{justify_text(title, 9, 'left')} #{justify_text(master, 7)}#{justify_text(current, 9)}"
    end

    def calulate_prep(master_formatted, diff)
      return '  ' if master_formatted != '-' && diff.zero?

      diff.positive? ? '+ ' : '- '
    end
  end

  class DangerRcov < Plugin
    # report will get the urls from circleCi trough circle_ci_wrapper gem
    def report(branch_name = 'master', build_name = 'build', show_warning = true)
      current_url, master_url = CircleCiWrapper.report_urls_by_branch(branch_name, build_name)

      report_by_urls(current_url, master_url, show_warning)
    end

    def report_by_urls(current_url, master_url, show_warning = true)
      current_report = get_report(url: current_url)
      master_report = get_report(url: master_url)

      report_by_files(current_report, ci_pr_number, master_report, 'master', show_warning)
    end

    def report_by_files(current_file, c_number, previous_file, pr_number, show_warning = true)
      @current_report = Danger::Coverage.new(c_number, current_file)
      @master_report = Danger::Coverage.new(pr_number, previous_file)

      if show_warning && @master_report && @master_report.covered_percent > @current_report.covered_percent
        warn("Code coverage decreased from #{@master_report.covered_percent}% to #{@current_report.covered_percent}%")
      end

      # Output the processed report
      Danger::CoverageReport.new(@current_report, @master_report).print
    end

    private

    def get_report(url:)
      URI.parse(url).read if url
    end

    def ci_pr_number
      ENV['CIRCLE_PULL_REQUEST'].split('/').last if ENV['CIRCLE_PULL_REQUEST']
    end
  end
end
