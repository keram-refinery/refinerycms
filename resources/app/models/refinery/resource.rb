require 'dragonfly'

module Refinery
  class Resource < Refinery::Core::BaseModel
    ::Refinery::Resources::Dragonfly.setup!

    include Resources::Validators

    MAX_FILE_MIME_TYPE_LENGTH = 128

    resource_accessor :file

    default_scope { order updated_at: :desc }

    validates :file, presence: true
    validates_with FileNameValidator, on: :create
    validates_with FileSizeValidator
    validates_with FileUpdateValidator, on: :update
    validates :file_mime_type, allow_blank: true, length: { maximum: MAX_FILE_MIME_TYPE_LENGTH }

    delegate :ext, :size, :mime_type, :url, :name, to: :file

    # used for searching
    def type_of_content
      mime_type.split('/').join(' ')
    end

    # Returns a titleized version of the filename
    # my_file.pdf returns My File
    def title
      CGI::unescape(file_name.to_s).gsub(/\.\w+$/, '').titleize
    end

    def to_dialog
      {
        id: id,
        name: file_name,
        size: file_size,
        url: url,
        ext: ext.to_s.downcase,
        mime_type: file_mime_type
      }
    end

  end
end
