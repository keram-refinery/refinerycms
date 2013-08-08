plugin = Refinery::Plugins['refinery_pages']
if plugin && plugin.page.blank?
  home_page = Refinery::Page.create({:title => 'Home',
              :deletable => false,
              :link_url => '/',
              :view_template => 'home',
              :plugin_page_id => plugin.name
  })

  body = home_page.part(:body)
  body.content = '<p>Welcome to our site. This is just a place holder page while we gather our content.</p>'
  body.save

  side_body = home_page.part(:side_body)
  side_body.content = '<p>This is another block of content over here.</p>'
  side_body.save

  if plugin.not_found_page.blank?
    page_not_found_page = home_page.children.create(:title => 'Page not found',
                :plugin_page_id => "#{plugin.name}_not_found",
                :show_in_menu => false,
                :deletable => false)

    body = page_not_found_page.part(:body)
    body.content = '<h2>Sorry, there was a problem...</h2><p>The page you requested was not found.</p><p><a href="/">Return to the home page</a></p>'
    body.save

    side_body = page_not_found_page.part(:side_body)
    side_body.active = false
    side_body.save
  end

  about_us_page = Refinery::Page.by_title('About')
  unless about_us_page
    about_us_page = ::Refinery::Page.create(:title => 'About')

    body = about_us_page.part(:body)
    body.content = '<p>This is just a standard text page example. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Proin metus dolor, hendrerit sit amet, aliquet nec, posuere sed, purus. Nullam et velit iaculis odio sagittis placerat. Duis metus tellus, pellentesque ut, luctus id, egestas a, lorem. Praesent vitae mauris. Aliquam sed nulla. Sed id nunc vitae leo suscipit viverra. Proin at leo ut lacus consequat rhoncus. In hac habitasse platea dictumst. Nunc quis tortor sed libero hendrerit dapibus.\n\nInteger interdum purus id erat. Duis nec velit vitae dolor mattis euismod. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. Suspendisse pellentesque dignissim lacus. Nulla semper euismod arcu. Suspendisse egestas, erat a consectetur dapibus, felis orci cursus eros, et sollicitudin purus urna et metus. Integer eget est sed nunc euismod vestibulum. Integer nulla dui, tristique in, euismod et, interdum imperdiet, enim. Mauris at lectus. Sed egestas tortor nec mi.</p>'
    body.save

    side_body = about_us_page.part(:side_body)
    side_body.content = '<p>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vivamus fringilla nisi a elit. Duis ultricies orci ut arcu. Ut ac nibh. Duis blandit rhoncus magna. Pellentesque semper risus ut magna. Etiam pulvinar tellus eget diam. Morbi blandit. Donec pulvinar mauris at ligula. Sed pellentesque, ipsum id congue molestie, lectus risus egestas pede, ac viverra diam lacus ac urna. Aenean elit.</p>'
    side_body.save

  end
end
