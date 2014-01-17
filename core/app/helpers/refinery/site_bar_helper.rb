module Refinery
  module SiteBarHelper

    # Generates the link to determine where the site bar switch button returns to.
    def site_bar_switch_link
      link_to_if(admin?, t('.website'), refinery.root_path, title: t('.switch_to_your_website')) do
        link_to t('.administration'), refinery.admin_root_path, title: t('.switch_to_your_website_editor')
      end
    end

  end
end
