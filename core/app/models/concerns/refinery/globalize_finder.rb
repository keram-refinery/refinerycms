module Refinery
  module GlobalizeFinder
    extend ActiveSupport::Concern

    # Wrap up the logic of finding the pages based on the translations table.
    def with_globalize(conditions = {})
      conditions = {locale: ::Globalize.locale.to_s}.merge(conditions)
      translations_conditions = {}
      translated_attrs = translated_attribute_names.map(&:to_s) | %w(locale)

      conditions.keys.each do |key|
        if translated_attrs.include? key.to_s
          translations_conditions["#{self.translation_class.table_name}.#{key}"] = conditions.delete(key)
        end
      end

      # A join implies readonly which we don't really want.
      where(conditions).joins(:translations).where(translations_conditions).
                                             readonly(false)
    end
  end
end
