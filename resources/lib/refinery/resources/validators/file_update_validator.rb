module Refinery
  module Resources
    module Validators
      class FileUpdateValidator < ActiveModel::Validator

        def validate(record)
          if record.file_name_changed?
            record.errors.add :file_name,
              ::I18n.t('different_file_name',
                       :scope => 'activerecord.errors.models.refinery/resource')
          end
        end

      end
    end
  end
end
