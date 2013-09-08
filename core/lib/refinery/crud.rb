# Base methods for CRUD actions
# Simply override any methods in your action controller you want to be customised
# Don't forget to add:
#   resources :plural_model_name_here
# or for scoped:
#   scope(:as => 'module_module', :module => 'module_name') do
#      resources :plural_model_name_here
#    end
# to your routes.rb file.
# Full documentation about CRUD and resources go here:
# -> http://api.rubyonrails.org/classes/ActionDispatch/Routing/Mapper/Resources.html#method-i-resources
# Example (add to your controller):
# crudify :foo, :title_attribute => 'name' for CRUD on Foo model
# crudify :'foo/bar', :title_attribute => 'name' for CRUD on Foo::Bar model
# Note: @singular_name will result in @foo for :foo and @bar for :'foo/bar'

module Refinery
  module Crud

    def self.default_options(model_name)
      class_name = "#{model_name.to_s.camelize.gsub('/', '::')}".gsub('::::', '::')
      this_class = class_name.constantize.base_class
      singular_name = ActiveModel::Naming.param_key(this_class)
      plural_name = singular_name.pluralize
      order = if this_class.column_names.include?('position')
                'position ASC'
              elsif this_class.column_names.include?('updated_at')
                'updated_at DESC'
              end if this_class.table_exists?

      {
        :conditions => '',
        :include => [],
        :order => order,
        :paging => true,
        :per_page => false,
        :redirect_to_url => "refinery.#{Refinery.route_for_model(class_name.constantize, :plural => true)}",
        :sortable => true,
        :class_name => class_name,
        :singular_name => singular_name,
        :plural_name => plural_name
      }
    end

    def self.append_features(base)
      super
      base.extend(ClassMethods)
    end

    module ClassMethods

      def crudify(model_name, options = {})
        options = ::Refinery::Crud.default_options(model_name).merge(options)
        class_name = options[:class_name]
        singular_name = options[:singular_name]
        plural_name = options[:plural_name]

        module_eval %(
          def self.crudify_options
            #{options.inspect}
          end

          prepend_before_action :find_#{singular_name},
                                :only => [:update, :destroy, :edit, :show]

          prepend_before_action :merge_position_into_params!, :only => :create

          def new
            @#{singular_name} = #{class_name}.new
          end

          def create
            if (@#{singular_name} = #{class_name}.create(#{singular_name}_params)).valid?
              flash.notice = t(
                'refinery.crudify.created',
                :kind => t('#{model_name}', scope: 'activerecord.models'),
                :what => "\#{@#{singular_name}.title}"
              )
              create_or_update_successful
            else
              create_or_update_unsuccessful 'new'
            end
          end

          def edit
            # object gets found by find_#{singular_name} function
          end

          def update
            if @#{singular_name}.update_attributes(#{singular_name}_params)
              flash.notice = t(
                'refinery.crudify.updated',
                :kind => t('#{model_name}', scope: 'activerecord.models'),
                :what => "\#{@#{singular_name}.title}"
              )

              create_or_update_successful
            else
              create_or_update_unsuccessful 'edit'
            end
          end

          def destroy
            title = @#{singular_name}.title
            if @#{singular_name}.destroy
              flash.notice = t(
                'refinery.crudify.destroyed',
                :kind => t('#{model_name}', scope: 'activerecord.models'),
                :what => title
              )
            end

            redirect_to redirect_url, status: :see_other # 303 See Other
          end

          # Finds one single result based on the id params.
          def find_#{singular_name} id=nil
            id = (id || params[:id]).to_s
            @#{singular_name} = if id.friendly_id?
                                  #{class_name}.friendly.includes(#{options[:include].map(&:to_sym).inspect}).find(id)
                                else
                                  #{class_name}.includes(#{options[:include].map(&:to_sym).inspect}).find(id)
                                end
          end

          # Find the collection of @#{plural_name} based on the conditions specified into crudify
          # It will be ordered based on the conditions specified into crudify
          # And eager loading is applied as specified into crudify.
          def find_all_#{plural_name}(conditions = #{options[:conditions].inspect})
            @#{plural_name} = #{class_name}.where(conditions).includes(
                                #{options[:include].map(&:to_sym).inspect}
                              ).order("#{options[:order]}")
          end

          def merge_position_into_params!
            # if the position field exists, set this object as last object, given the conditions of this class.
            if #{class_name}.column_names.include?('position') && params[:#{singular_name}][:position].nil?
              params[:#{singular_name}].merge!({
                :position => ((#{class_name}.where(#{options[:conditions].inspect}).maximum(:position)||-1) + 1)
              })
            end
          end

          # Paginate a set of @#{plural_name} that may/may not already exist.
          def paginate_all_#{plural_name}
            # If we have already found a set then we don't need to again
            find_all_#{plural_name} if @#{plural_name}.nil?

            @#{plural_name} = @#{plural_name}.paginate(:page => paginate_page, :per_page => paginate_per_page)
          end

          def paginate_per_page
            if #{options[:per_page].present?.inspect}
              #{options[:per_page].inspect}
            elsif #{class_name}.methods.map(&:to_sym).include?(:per_page)
              #{class_name}.per_page
            end
          end

          def redirect_url
            if paginate_page > 1
              page = [paginate_page, #{class_name}.page(1).total_pages].min
              #{options[:redirect_to_url]}(:page => page)
            else
              #{options[:redirect_to_url]}
            end
          end

          def create_or_update_successful
            redirect_to redirect_url
          end

          def create_or_update_unsuccessful(action)
            flash.now[:alert] = t('refinery.crudify.error')

            render :action => action
          end

          # Ensure all methods are protected so that they should only be called
          # from within the current controller.
          protected :find_#{singular_name},
                    :find_all_#{plural_name},
                    :paginate_all_#{plural_name},
                    :paginate_per_page,
                    :redirect_url,
                    :create_or_update_successful,
                    :create_or_update_unsuccessful,
                    :merge_position_into_params!
        )

        if options[:paging]
          module_eval %(
            def index
              paginate_all_#{plural_name}
            end
          )
        else
          module_eval %(
            def index
              find_all_#{plural_name}
            end
          )
        end

        if options[:sortable]
          module_eval %(

            def update_positions
              item = params.delete(:item)
              updated = false

              if item
                model = #{class_name}
                model.transaction do
                  if (db_item = model.find_by(id: item['id'].to_i) if item['id']).present?
                    case
                    when item['prev_id'].present?
                      prev_item = model.find_by(id: item['prev_id'].to_i) if item['prev_id'].present?
                      if prev_item && move_allowed?(db_item, prev_item.parent)
                        updated = db_item.move_to_right_of(prev_item)
                      end
                    when item['next_id'].present?
                      next_item = model.find_by(id: item['next_id'].to_i) if item['next_id'].present?
                      if next_item && move_allowed?(db_item, next_item.parent)
                        updated = db_item.move_to_left_of(next_item)
                      end
                    when item['parent_id'].present?
                      parent_item = model.find_by(id: item['parent_id'].to_i) if item['parent_id'].present?
                      if parent_item && move_allowed?(db_item, parent_item)
                        updated = db_item.move_to_child_of(parent_item)
                      end
                    end

                    if updated
                      db_item.rebuild! if db_item.respond_to?(:rebuild!)
                      db_item.touch
                    end
                  end
                end
              end

            rescue
              logger.warn "#{$!.class.name} raised while updating positions of #{class_name}"
              logger.warn $!.message
            ensure
              flash.now[:alert] = t('refinery.crudify.update_positions_fail') unless updated || flash.now[:alert].present?
              find_all_#{plural_name}
            end

            def move_allowed?(item, new_parent)
              true
            end
          )
        end

        module_eval %(
          class << self
            def pageable?
              #{options[:paging].to_s}
            end
            alias_method :paging?, :pageable?

            def sortable?
              #{options[:sortable].to_s}
            end

          end
        )

      end

    end

  end
end
