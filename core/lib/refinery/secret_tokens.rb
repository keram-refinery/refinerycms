require 'securerandom'

module Refinery

  def self.secret token_name
    if Rails.application &&
      Rails.application.secrets && Rails.application.secrets[token_name]

      Rails.application.secrets[token_name]
    else
      # this part here is only for making happy application when Rails.application is not present
      ENV[token_name.upcase] || SecureRandom.hex(64)
    end
  end

end
