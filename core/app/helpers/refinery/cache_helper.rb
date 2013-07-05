module Refinery
  module CacheHelper

    def refinery_record_cache_key record, prefix=nil
      klass = record.respond_to?(:klass) ? record.klass : record.class
      key = [Refinery::Core.base_cache_key]
      key << prefix if prefix
      key << record.id
      key << current_refinery_user.id if current_refinery_user
      if klass
        key << Globalize.locale if klass.respond_to?(:translates?) && klass.translates?
        key << klass.order(updated_at: :desc).limit(1).pluck(:updated_at).first.to_s.parameterize
      end
    end

    def refinery_records_cache_key records, prefix=nil
      klass = records.respond_to?(:klass) ? records.klass : records.class
      key = [Refinery::Core.base_cache_key]
      key << prefix if prefix
      key << current_refinery_user.id if current_refinery_user
      paginable_records = paginable_records records, klass
      if paginable_records
        key << [paginable_records.current_page.to_i, paginable_records.total_pages + 1].min
        key << paginable_records.total_entries
      end
      if klass
        key << Globalize.locale if klass.respond_to?(:translates?) && klass.translates?
        key << klass.order(updated_at: :desc).limit(1).pluck(:updated_at).first.to_s.parameterize
      end
    end

    def paginable_records records, klass
      if records.respond_to?(:current_page)
        records
      elsif klass.respond_to?(:current_page)
        klass
      elsif klass.respond_to?(:page) && klass.page(1).respond_to?(:current_page)
        klass.page(1)
      end
    end

  end
end
