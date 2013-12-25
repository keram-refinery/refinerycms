module Refinery
  class ImagesList

    extend ActiveModel::Naming
    include ActiveModel::Conversion
    include ActiveModel::Validations

    attr_accessor :images
    attr_accessor :errors

    def initialize(images=[])
      @images = Array(images)
      @errors = ActiveModel::Errors.new(self)
    end

    def persisted?
      true
    end

    def create
    end

    def update attributes={}
      @images.each do |img|
        img.update_attributes(attributes[:image][img.id.to_s])
        @errors.messages.merge!(img.errors.messages)
      end

      @errors.empty?
    end

    def id
      @images.map(&:id).join('-')
    end

    def title
      @images.map(&:title).join("', '")
    end

  end
end
