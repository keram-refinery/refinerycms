module Refinery
  module Resources
    module Validators
      class FileNameValidator < ActiveModel::Validator

        def validate(record)
          file = record.file

          if file.respond_to?(:name) && Resource.where(file_name: file.name).exists?
            record.errors[:file] << ::I18n.t('file_exists',
                                             :scope => 'activerecord.errors.models.refinery/resource',
                                             :name => file.name)
          end
        end

      end
    end
  end
end
