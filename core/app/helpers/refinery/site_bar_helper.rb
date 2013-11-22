module Refinery
  module SiteBarHelper

    # Generates the link to determine where the site bar switch button returns to.
    def site_bar_switch_link
      link_to_if(admin?, t('.switch_to_your_website'), refinery.root_path) do
        link_to t('.switch_to_your_website_editor'), refinery.admin_root_path
      end
    end

  end
end
