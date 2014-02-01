module Refinery
  class << self
    # Usage Refinery.secret(:really_big_secret)
    # We use this because we need secrets in initializers, configurations etc
    # before is Rails.application loaded
    def secret token_name
      if secrets.present? && secrets[token_name.to_sym].present?
        secrets[token_name.to_sym]
      else
        require 'securerandom'
        ENV[token_name.to_s.upcase] || (!installed? && SecureRandom.hex(64))
      end
    end

    def secrets
      @secrets ||= if Rails.application && Rails.application.respond_to?(:secrets)
        Rails.application.secrets
      elsif File.exist?(yaml = 'config/secrets.yml')
        require 'erb'
        YAML.load(ERB.new(IO.read(yaml)).result)[Rails.env].symbolize_keys
      end
    end

    # file tmp/refinery_installed is created on refinery installation
    # so in other situations we should have secrets presents
    # and throwing exception is ok
    def installed?
      File.exist? 'config/refinerycms_installed'
    end
  end

end
