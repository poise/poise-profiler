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

require 'chef/handler'


module PoiseProfiler
  class Handler < Chef::Handler
    include Singleton

    def report
      cookbooks = Hash.new(0)
      recipes = Hash.new(0)
      resources = Hash.new(0)

      # collect all profiled timings and group by type
      all_resources.each do |r|
        cookbooks[r.cookbook_name] += r.elapsed_time
        recipes["#{r.cookbook_name}::#{r.recipe_name}"] += r.elapsed_time
        resources["#{r.resource_name}[#{r.name}]"] = r.elapsed_time
      end

      set_log_level(:info) do
        # print each timing by group, sorting with highest elapsed time first
        puts "Elapsed_time  Cookbook"
        puts "------------  -------------"
        cookbooks.sort_by{ |k,v| -v }.each do |cookbook, run_time|
          puts "%12f  %s" % [run_time, cookbook]
        end
        puts ""

        puts "Elapsed_time  Recipe"
        puts "------------  -------------"
        recipes.sort_by{ |k,v| -v }.each do |recipe, run_time|
          puts "%12f  %s" % [run_time, recipe]
        end
        puts ""

        puts "Elapsed_time  Resource"
        puts "------------  -------------"
        resources.sort_by{ |k,v| -v }.each do |resource, run_time|
          puts "%12f  %s" % [run_time, resource]
        end
        puts ""
      end
    end

    private

    def puts(*args)
      Chef::Log.info(*args)
    end

    def set_log_level(level, &block)
      old_level = Chef::Log.level
      Chef::Log.level = level
      block.call
    ensure
      Chef::Log.level = old_level
    end

  end
end
