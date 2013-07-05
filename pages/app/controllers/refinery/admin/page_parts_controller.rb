module Refinery
  module Admin
    class PagePartsController < ::Refinery::AdminController

      def new
        render :json => json_response(
          :html => render_html_to_json_string('/refinery/admin/pages/page_part_field',
              :locals => {
                 :part => ::Refinery::PagePart.new(:title => params[:title].to_s, :body => params[:body].to_s),
                 :new_part => true,
                 :part_index => params[:part_index].to_i}))
      end

      def destroy
        part = ::Refinery::PagePart.find(params[:id].to_s)
        if part.destroy
          part.page.reposition_parts!
          flash.now[:notice] = t('.page_part_was_deleted', part.title)
        else
          flash.now[:notice] = t('.page_part_was_not_deleted', part.title)
        end
      end

      protected

      def refinery_plugin
        @refinery_plugin ||= Refinery::Plugins['refinery_pages']
      end

    end
  end
end
