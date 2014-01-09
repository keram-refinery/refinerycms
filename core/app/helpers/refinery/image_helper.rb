module Refinery
  module ImageHelper

    # image_fu is a helper for inserting an image that has been uploaded into a template.
    # Say for example that we had a @model.image (@model having a belongs_to :image relationship)
    # and we wanted to display a thumbnail cropped to 200x200 then we can use image_fu like this:
    # <%= image_fu @model.image, '200x200' %> or with no thumbnail: <%= image_fu @model.image %>
    def image_fu(image, geometry = nil, options={})
      if image.present?
        dimensions = (image.thumbnail_dimensions(geometry) rescue {})

        image_tag(image.thumbnail(geometry: geometry).url, {
          alt: image.respond_to?(:title) ? image.title : image.image_name,
        }.merge(dimensions).merge(options))
      end
    end
  end
end
