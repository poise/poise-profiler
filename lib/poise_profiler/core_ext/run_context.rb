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

require 'chef/run_context'
require 'chef/version'


module PoiseProfiler
  module CoreExt
    # Monkeypatch extensions for Chef::RunContext to add support for the
    # recipe_file_loaded event on older Chef.
    #
    # @since 1.1.0
    # @api private
    module RunContext
      PRE_MAGIC_EVENTS = Gem::Version.create(Chef::VERSION) < Gem::Version.create('12.5.1')

      def load_recipe(recipe_name, current_cookbook: nil)
        super.tap do |ret|
          cookbook_name, recipe_short_name = Chef::Recipe.parse_recipe_name(recipe_name, current_cookbook: current_cookbook)
          cookbook = cookbook_collection[cookbook_name]
          recipe_path = cookbook.recipe_filenames_by_name[recipe_short_name]
          if PRE_MAGIC_EVENTS
            events.recipe_file_loaded(recipe_path)
          else
            events.recipe_file_loaded(recipe_path, recipe_name)
          end
        end
      end

      # Monkeypatch us in for <12.14.53, which was the first build after
      # https://github.com/chef/chef/commit/1c990a11ebe360f5e85ac13626ce1e09e295f919.
      if Gem::Version.create(Chef::VERSION) < Gem::Version.create('12.14.53')
        Chef::RunContext.prepend(self)
      end

    end
  end
end

