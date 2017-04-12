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

require 'yaml'

require 'chef/mash'
begin
  require 'chef/chef_class'
rescue LoadError
  # ¯\_(ツ)_/¯ Chef < 12.3.
end


module PoiseProfiler
  # Configuration wrapper for poise-profiler to combine input from a number of
  # sources.
  #
  # @since 1.1.0
  # @api private
  # @example
  #   cfg = Config.new
  #   puts cfg[:profile_memory]
  class Config < Mash
    def initialize
      super
      gather_from_env
      gather_from_node
    end

    private

    # Find configuration data in environment variables. This is the only option
    # on Chef 12.0, 12.1, and 12.2.
    #
    # @api private
    def gather_from_env
      ENV.each do |key, value|
        if key.downcase =~ /^poise(_|-)profiler_(.+)$/
          self[$2] = YAML.safe_load(value)
        end
      end
    end

    # Find configuration data in node attributes.
    #
    # @api private
    def gather_from_node
      return unless defined?(Chef.node)
      (Chef.node['poise-profiler'] || {}).each do |key, value|
        self[key] = value
      end
    end

  end
end
