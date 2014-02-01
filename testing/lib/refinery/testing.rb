require 'refinerycms-core'
require 'rspec-rails'
require 'factory_girl_rails'

module Refinery
  autoload :TestingGenerator, 'generators/refinery/testing/testing_generator'

  module Testing
    class << self
      def root
        @root ||= Pathname.new(File.expand_path('../../../', __FILE__))
      end

      # Load the factories of all currently loaded extensions
      def load_factories
        Refinery.extensions.each do |extension_const|
          path = "#{extension_const.root}/spec/factories"
          FactoryGirl.definition_file_paths << path if File.exist?(path)
        end

        FactoryGirl.find_definitions
      end
    end

    require 'refinery/testing/railtie'

    autoload :ControllerMacros, 'refinery/testing/controller_macros'
    autoload :FeatureMacros, 'refinery/testing/feature_macros'
  end
end
