require 'dragonfly'

module Refinery
  class Image < Refinery::Core::BaseModel
    include Images::Validators
    extend Dragonfly::Model
    extend Dragonfly::Model::Validations

    RESIZE_GEOMETRY = Dragonfly::ImageMagick::Processors::Thumb::RESIZE_GEOMETRY
    THUMB_GEOMETRY = Regexp.union(
                Dragonfly::ImageMagick::Processors::Thumb::RESIZE_GEOMETRY,
                Dragonfly::ImageMagick::Processors::Thumb::CROPPED_RESIZE_GEOMETRY,
                Dragonfly::ImageMagick::Processors::Thumb::CROP_GEOMETRY )

    dragonfly_accessor :image, app: :refinery_images

    translates :alt, :caption

    validates :image, presence: true
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
      geometry = if geometry.is_a?(Symbol) && Refinery::Images.user_image_sizes.keys.include?(geometry)
        Refinery::Images.user_image_sizes[geometry]
      else
        geometry.to_s
      end

      width = original_width = self.image_width.to_f
      height = original_height = self.image_height.to_f
      geometry_width, geometry_height = geometry.split(%r{\#{1,2}|\+|>|!|x}im)[0..1].map(&:to_f)

      # Geometry string patterns

      if (original_width * original_height > 0) && THUMB_GEOMETRY === geometry
        if RESIZE_GEOMETRY === geometry
          if geometry !~ %r{\d+x\d+>} || (%r{\d+x\d+>} === geometry && (width > geometry_width.to_f || height > geometry_height.to_f))
            # Try scaling with width factor first. (wf = width factor)
            wf_width = (original_width * geometry_width / width).round
            wf_height = (original_height * geometry_width / width).round

            # Scale with height factor (hf = height factor)
            hf_width = (original_width * geometry_height / height).round
            hf_height = (original_height * geometry_height / height).round

            # Take the highest value that doesn't exceed either axis limit.
            use_wf = wf_width <= geometry_width && wf_height <= geometry_height
            if use_wf && hf_width <= geometry_width && hf_height <= geometry_height
              use_wf = wf_width * wf_height > hf_width * hf_height
            end

            if use_wf
              width = wf_width
              height = wf_height
            else
              width = hf_width
              height = hf_height
            end
          end
        else
          # cropping
          width = geometry_width
          height = geometry_height
        end
      end

      { width: width.to_i, height: height.to_i }
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
