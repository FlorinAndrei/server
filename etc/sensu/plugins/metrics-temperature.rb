#! /usr/bin/env ruby
# frozen_string_literal: true

#   <script name>
#
# DESCRIPTION:
#   This plugin uses sensors to collect basic system metrics, produces
#   Graphite formated output.

#
# OUTPUT:
#   metric data
#
# PLATFORMS:
#   Linux
#
# DEPENDENCIES:
#   gem: sensu-plugin
#   gem: socket
#   lm-sensors
#
# USAGE:
#
# NOTES:
#
# LICENSE:
#   Copyright 2012 Wantudu SL <dsuarez@wantudu.com>
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require 'sensu-plugin/metric/cli'
require 'socket'

#
# Sensors
#
class Sensors < Sensu::Plugin::Metric::CLI::Graphite
  option :scheme,
         description: 'Metric naming scheme, text to prepend to .$parent.$child',
         long: '--scheme SCHEME',
         default: "#{Socket.gethostname}.sensors"

  def run
    raw = `sensors -A`
    sections = raw.split("\n\n")
    metrics = {}

    # split into sections for each chip
    sections.each do |section|
      lines = section.split("\n")

      # the first line is the chip name
      chip =  lines[0]

      # all other lines are metrics
      lines[1..-1].each do |line|
        begin
          if line.include? ":"
            key, value = line.split(':')
            key = key.downcase.gsub(/\s/, '')
          else
            next
          end

          value.strip =~ /[\+\-]?(\d+(\.\d)?)/
          value = Regexp.last_match[1]
          key = [chip, key].join('.')
          metrics[key] = value
        rescue StandardError
          print "malformed section from sensors: #{line}" + "\n"
        end
      end
    end
    timestamp = Time.now.to_i
    metrics.each do |key, value|
      output [config[:scheme], key].join('.'), value, timestamp
    end
    ok
  end
end
