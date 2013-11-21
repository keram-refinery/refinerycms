
ActionDispatch::Routing::RoutesProxy.class_eval do
  def method_missing_with_globalize(method, *args)
    method.to_s.match(/_(url|path)\z/)
    ext = $1
    if routes.url_helpers.respond_to?(method.to_s.gsub(/_#{ext}\z/, "_#{Globalize.locale}_#{ext}"))
      self.class.class_eval <<-RUBY, __FILE__, __LINE__ + 1
        def #{method}(*args)
          locale = args.extract_options![:locale] || Globalize.locale
          args << { locale: locale }
          send '#{method.to_s.gsub(/_(url|path)\z/, '')}_' + locale.to_s + "_#{$1}", *args
        end
      RUBY

      send(method, *args)
    else
      method_missing_without_globalize(method, *args)
    end
  end

  alias_method_chain :method_missing, :globalize
end
