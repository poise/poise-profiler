#
# Copyright 2016, Noah Kantrowitz
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'chef/json_compat'

require 'poise_profiler/base'


module PoiseProfiler
  class Timing < PoiseProfiler::Base
    def resource_completed(resource)
      key = resource.resource_name.to_s.end_with?('_test') ? :test_resources : :resources
      timers[key]["#{resource.resource_name}[#{resource.name}]"] += resource.elapsed_time
      timers[:classes][resource.class.name] += resource.elapsed_time
    end

    def run_completed(node)
      Chef::Log.debug('Processing poise-profiler timing data')
      puts('Poise Profiler Timing:')
      puts_timer(:resources, 'Resource')
      puts_timer(:test_resources, 'Test Resource') unless timers[:test_resources].empty?
      puts_timer(:classes, 'Class')
      puts("Profiler JSON: #{Chef::JSONCompat.to_json(timers)}") if config.fetch('timing_json', ENV['CI'] || node['CI'])
      puts('')
    end

    def run_failed(_run_error)
      run_completed(nil)
    end

    def reset!
      timers.clear
      super
    end

    private

    def timers
      @timers ||= Hash.new {|hash, key| hash[key] = Hash.new(0) }
    end

    def puts_timer(key, label)
      puts "Time          #{label}"
      puts "------------  -------------"
      timers[key].sort_by{ |k,v| -v }.each do |val, run_time|
        puts "%12f  %s" % [run_time, val]
      end
      puts ""
    end

  end
end
