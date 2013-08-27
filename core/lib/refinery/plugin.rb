module Refinery
  class Plugin

    attr_accessor :name, :class_name, :controller, :directory, :url,
                  :dashboard, :always_allow_access,
                  :hide_from_menu, :pathname, :plugin_activity, :position,
                  :javascript, :stylesheet, :admin_javascript, :admin_stylesheet

    def self.register(&block)
      yield(plugin = self.new)

      raise "A plugin MUST have a name!: #{plugin.inspect}" if plugin.name.blank?

      # Set defaults.
      plugin.always_allow_access ||= false
      plugin.dashboard ||= false
      plugin.class_name ||= plugin.name.camelize

      plugin.position ||= 100

      # add the new plugin to the collection of registered plugins
      ::Refinery::Plugins.registered << plugin
    end

    # Returns the internationalized version of the title
    def title
      ::I18n.translate(['refinery', 'plugins', name, 'title'].join('.'))
    end

    # Returns the internationalized version of the description
    def description
      ::I18n.translate(['refinery', 'plugins', name, 'description'].join('.'))
    end

    # Retrieve information about how to access the latest activities of this plugin.
    def activity
      self.plugin_activity ||= []
    end

    # Stores information that can be used to retrieve the latest activities of this plugin
    def activity=(activities)
      [activities].flatten.each { |activity| add_activity(activity) }
    end

    # Given a record's class name, find the related activity object.
    def activity_by_class_name(class_name)
      self.activity.select{ |a| a.class_name == class_name.to_s.camelize }
    end

    def pathname=(value)
      value = Pathname.new(value) if value.is_a? String
      @pathname = value
    end

    # Returns a hash that can be used to create a url that points to the administration part of the plugin.
    def url
      @url ||= if controller.present?
        { :controller => "refinery/admin/#{controller}" }
      elsif directory.present?
        { :controller => "refinery/admin/#{directory.split('/').pop}" }
      else
        { :controller => "refinery/admin/#{name}" }
      end

      if @url.is_a?(Hash)
        {:only_path => true}.merge(@url)
      elsif @url.respond_to?(:call)
        @url.call
      else
        @url
      end
    end

    PAGE_METHOD_RE = /(^page$|(^[a-z_]+)_page$)/

    def method_missing(method_name, *args, &block)
      if method_name.match(PAGE_METHOD_RE)
        if Refinery::Page.table_exists?
          self.class.send(:define_method, method_name) do
            Refinery::Page.find_by(plugin_page_id: "#{self.name}#{'_' << $2 if $2}")
          end

          return send method_name
        else
          return nil
        end
      end

      super
    end

   def respond_to?(method_name, include_private = false)
     !!(method_name =~ PAGE_METHOD_RE) || super
   end

  # Make this protected, so that only Plugin.register can use it.
  protected

    def add_activity(options)
      (self.plugin_activity ||= []) << Activity::new(options)
    end

    def initialize
      # provide a default pathname to where this plugin is using its lib directory.
      depth = 4
      self.pathname ||= Pathname.new(caller(depth).first.match("(.*)#{File::SEPARATOR}lib")[1])
    end
  end
end
