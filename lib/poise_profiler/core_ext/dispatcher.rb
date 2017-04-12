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

require 'chef/event_dispatch/dispatcher'
require 'chef/version'


module PoiseProfiler
  module CoreExt
    # Monkeypatch extensions for Chef::EventDispatch::Dispatcher to support the
    # new recipe_loaded event.
    #
    # @since 1.1.0
    # @api private
    module Dispatcher
      def recipe_loaded(*args)
        if defined?(call_subscribers)
          call_subscribers(:recipe_loaded, *args)
        else
          @subscribers.each { |s| s.recipe_loaded(*args) }
        end
      end

      # Monkeypatch us in for ?. TODO THIS
      if Gem::Version.create(Chef::VERSION) < Gem::Version.create('14')
        Chef::EventDispatch::Dispatcher.include(self)
      end

    end
  end
end

