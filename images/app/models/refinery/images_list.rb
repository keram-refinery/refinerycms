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

      restore_record_file_if_file_validation_fails

      @errors.empty?
    end

    def id
      @images.map(&:id).join('-')
    end

    def title
      @images.map(&:title).join("', '")
    end

    def restore_record_file_if_file_validation_fails
      @images = @images.map do |image|
        if image.invalid? && image.errors.include?(:image_name)
          errors = image.errors
          new_alt = image.alt
          new_caption = image.caption
          image = Refinery::Image.find(image.id)
          image.alt = new_alt
          image.caption = new_caption
          errors.each { |k,v| image.errors.add(k, v) }
        end

        image
      end
    end
  end
end
