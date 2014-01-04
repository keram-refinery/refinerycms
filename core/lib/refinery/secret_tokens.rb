require 'securerandom'

module Refinery

  def self.secret token_name, fallback=SecureRandom.hex(64)
    if Rails.application &&
      Rails.application.respond_to?(:secrets) && Rails.application.secrets[token_name]

      Rails.application.secrets[token_name]
    else
      ENV[token_name.upcase] || fallback
    end
  end

end
