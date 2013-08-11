require 'securerandom'

module Refinery

  def self.find_or_set_secret_token(suffix = nil)
    token_name = '.secret'
    token_name << "-#{suffix}" if suffix

    return ENV[token_name.upcase] if ENV[token_name.upcase].present?

    token_file = Rails.root.join('config', token_name)
    if File.exist? token_file
      # Use the existing token.
      File.read(token_file).chomp
    else
      # Generate a new token of 64 random hexadecimal characters and store it in token_file.
      token = SecureRandom.hex(64)
      File.write(token_file, token)
      token
    end
  end

end
