require 'refinery/extension_generation'
require 'rails/generators/migration'

module Refinery
  class FormGenerator < Rails::Generators::NamedBase
    source_root Pathname.new(File.expand_path('../templates', __FILE__))

    include Refinery::ExtensionGeneration

    class_option :spam,
                 desc: 'Generate extension with spam field',
                 type: :boolean,
                 default: false,
                 required: false

    def includes_spam?
      options[:spam]
    end

    def description
      "Generates an extension which is set up for frontend form submissions like a contact page."
    end

    def generate
      default_generate!
    end

    protected

    def generator_command
      'rails generate refinery:form'
    end

    def reject_file_with_exclude_spam?(file)
      (!includes_spam? && file.to_s.include?('spam')) || reject_file_without_exclude_spam?(file)
    end
    alias_method_chain :reject_file?, :exclude_spam
  end
end
