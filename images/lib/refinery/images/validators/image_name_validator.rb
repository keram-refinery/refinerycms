module Refinery
  module Images
    module Validators
      class ImageNameValidator < ActiveModel::Validator

        def validate(record)
          image = record.image

          if image.respond_to?(:name) && Image.where(image_name: image.name).exists?
            record.errors[:image_name] << ::I18n.t('image_exists',
                                             :scope => 'activerecord.errors.models.refinery/image',
                                             :name => image.name)
          end
        end

      end
    end
  end
end
