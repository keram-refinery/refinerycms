plugin = Refinery::Plugins['pages']

pages = {
  home: {
    title: 'Home',
    deletable: false,
    link_url: '/',
    plugin_page_id: plugin.name
  },
  not_found: {
    title: 'Page not found',
    parent: :home,
    deletable: true,
    show_in_menu: false,
    plugin_page_id: "#{plugin.name}_not_found"
  },
  about: {
    title: 'About Us',
    deletable: true,
    show_in_menu: true,
    plugin_page_id: "#{plugin.name}_about"
  },
  colophon: {
    title: 'Colophon',
    deletable: true,
    show_in_menu: false,
    plugin_page_id: "#{plugin.name}_colophon"
  },
}

Refinery::Pages.seed(plugin, pages)
