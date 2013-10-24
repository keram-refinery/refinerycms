module Refinery
  module TagHelper

    # Remember to wrap your block with <div class="label_with_help"></div> if you're using a label next to the help tag.
    def refinery_help_tag(text='', attributes={})
      text = h(text) unless text.html_safe?
      tag_attributes = {class: 'help'}
      tag_attributes.merge!(attributes)
      content_tag(:a, content_tag(:span, text, class: 'text'), tag_attributes)
    end

    # This is just a quick wrapper to render an image tag that lives inside refinery/icons.
    # They are all 16x16 so this is the default but is able to be overriden with supplied options.
    def refinery_icon_tag(filename, options = {})
      filename = "#{filename}.png" unless filename.split('.').many?
      image_tag "refinery/icons/#{filename}", { width: 16, height: 16 }.merge(options)
    end

    def label_with_help(form, field_name, options={})
      field_name_to_s = sanitize_for_key(field_name)
      id = "#{form.object_name}_#{field_name_to_s}"
      options[:help] = t(".#{field_name_to_s}_help") unless options[:help]
      content_tag :div, class: 'label_with_help' do
        buffer = ActiveSupport::SafeBuffer.new
        buffer << form.label(field_name, options[:label], id: "label_for_#{id}")
        buffer << ' '
        buffer << refinery_help_tag(options[:help], id: "help_for_#{id}")
      end
    end

    def sanitize_for_key str
      str.to_s.downcase.gsub('-', '_').gsub(/[^a-z0-9\_]/, '')
    end

    def refinery_form_field form, field_type, field_name, options={}
      buffer = ActiveSupport::SafeBuffer.new
      field_options = {}.merge!(options.fetch(:html){{}})
      # id = #{dom_id form.object}_#{sanitize_for_key(field_name)}
      if options[:label]
        label_options = {}
        label_options[:label] = options[:label] if options[:label].is_a?(String)
        # doesn't work properly for nested attributes
        # field_options[:'aria-labelledby'] = "label_for_#{id}"
        if options[:help]
          label_options[:help] = options[:help] if options[:help].is_a?(String)
          #field_options[:'aria-describedby'] = "help_for_#{id}"
          buffer << label_with_help(form, field_name, label_options)
        else
          buffer << form.label(field_name, label_options)
        end
      end

      if field_type === :select
        buffer << form.send(field_type, field_name, options.delete(:options), options, field_options)
      else
        buffer << form.send(field_type, field_name, field_options)
      end

      buffer
    end

    def checkboxes(options={}, &block)
      content_tag :div, class: 'checkboxes',
                  role: 'group',
                  data: { :'no-turbolink' => true } do
        buffer = ActiveSupport::SafeBuffer.new
        buffer << capture(&block)
        buffer << link_to(t('select_all', scope: 'refinery.admin'), '#', class: 'checkboxes-cmd all hide')
        buffer << link_to(t('disable_all', scope: 'refinery.admin'), '#', class: 'checkboxes-cmd none hide')
       end
    end

  end
end
