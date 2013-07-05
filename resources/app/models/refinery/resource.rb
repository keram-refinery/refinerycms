require 'dragonfly'

module Refinery
  class Resource < Refinery::Core::BaseModel
    ::Refinery::Resources::Dragonfly.setup!

    include Resources::Validators

    resource_accessor :file

    validates :file, :presence => true
    validates_with FileNameValidator, :on => :create
    validates_with FileSizeValidator
    validates_with FileUpdateValidator, :on => :update

    delegate :ext, :size, :mime_type, :url, :name, :to => :file

    # used for searching
    def type_of_content
      mime_type.split('/').join(' ')
    end

    # Returns a titleized version of the filename
    # my_file.pdf returns My File
    def title
      CGI::unescape(file_name.to_s).gsub(/\.\w+$/, '').titleize
    end

  end
end
