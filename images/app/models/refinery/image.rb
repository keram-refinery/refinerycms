require 'dragonfly'

module Refinery
  class Image < Refinery::Core::BaseModel
    include Images::Validators
    extend Dragonfly::Model
    extend Dragonfly::Model::Validations
    extend GlobalizeFinder

    RESIZE_GEOMETRY = Dragonfly::ImageMagick::Processors::Thumb::RESIZE_GEOMETRY
    THUMB_GEOMETRY = Regexp.union(
                Dragonfly::ImageMagick::Processors::Thumb::RESIZE_GEOMETRY,
                Dragonfly::ImageMagick::Processors::Thumb::CROPPED_RESIZE_GEOMETRY,
                Dragonfly::ImageMagick::Processors::Thumb::CROP_GEOMETRY )

    dragonfly_accessor :image, app: :refinery_images

    translates :alt, :caption

    validates :image, presence: true
    validates :alt, length: { maximum: Refinery::STRING_MAX_LENGTH, message: :too_long }
    validates :caption, length: { maximum: Refinery::STRING_MAX_LENGTH, message: :too_long }

    validates_with ImageNameValidator, on: :create
    validates_with ImageSizeValidator
    validates_with ImageUpdateValidator, on: :update
    validates_property :mime_type,
                       of: :image,
                       in: ::Refinery::Images.whitelisted_mime_types,
                       message: :incorrect_format

    delegate :size, :mime_type, :url, :width, :height, :name, to: :image

    default_scope -> { order(id: :desc) }

    # Get a thumbnail job object given a geometry and whether to strip image profiles and comments.
    def thumbnail(options = {})
      options = { geometry: nil, strip: true }.merge(options)
      geometry = convert_to_geometry(options[:geometry])
      thumbnail = image
      thumbnail = thumbnail.thumb(geometry) if geometry
      thumbnail
    end

    # Intelligently works out dimensions for a thumbnail of this image based on the Dragonfly geometry string.
    def thumbnail_dimensions(geometry)
      dimensions = ThumbnailDimensions.new(geometry, image.width, image.height)
      { width: dimensions.width, height: dimensions.height }
    end

    # Returns a titleized version of the filename
    # my_file.jpg returns My File
    def title
      alt.presence || CGI::unescape(image_name.to_s).gsub(/\.\w+$/, '').titleize
    end

    def to_images_dialog
      {
        id: id,
        thumbnail: thumbnail(geometry: :medium).url,
        alt: title,
        caption: caption.to_s
      }
    end

    private

    def convert_to_geometry(geometry)
      if geometry.is_a?(Symbol) && Refinery::Images.user_image_sizes.keys.include?(geometry)
        Refinery::Images.user_image_sizes[geometry]
      else
        geometry
      end
    end

  end
end
