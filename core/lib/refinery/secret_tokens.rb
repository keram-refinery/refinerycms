require 'securerandom'

module Refinery

  def self.find_or_set_secret_token(token_name = nil)
    return ENV[token_name.upcase] if !token_name.nil? && ENV[token_name.upcase].present?

    token_file = '.secret'
    token_file << "-#{token_name.downcase}" if token_name
    token_file_path = Rails.root.join('config', token_file)

    if File.exist? token_file_path
      # Use the existing token.
      File.read(token_file_path).chomp
    else
      # Generate a new token of 64 random hexadecimal characters and store it in token_file.
      token = SecureRandom.hex(64)
      File.write(token_file_path, token)
      token
    end
  end

end
