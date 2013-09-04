# encoding: utf-8
require 'spec_helper'

module Refinery
  describe Page do

    before do
      Refinery::Page.delete_all
    end

    after do
      Refinery::Page.delete_all
    end

    let(:page_title) { 'RSpec is great for testing too' }
    let(:child_title) { 'The child page' }

    # For when we do not need the page persisted.
    let(:page) { subject.class.new(:title => page_title, :deletable => true)}
    let(:child) { page.children.new(:title => child_title) }

    # For when we need the page persisted.
    let(:created_page) { subject.class.create!(:title => page_title, :deletable => true) }
    let(:created_child) { created_page.children.create!(:title => child_title) }

    def page_cannot_be_destroyed
      page.should_receive(:puts_destroy_help)
      page.destroy.should == false
    end

    def turn_off_marketable_urls
      Pages.stub(:marketable_urls).and_return(false)
    end

    def turn_on_marketable_urls
      Pages.stub(:marketable_urls).and_return(true)
    end

    context 'cannot be deleted under certain rules' do
      it 'if refinery team deems it so' do
        page.deletable = false
        page_cannot_be_destroyed
      end

      it 'unless you really want it to! >:]' do
        page.deletable = false
        page_cannot_be_destroyed
        page.destroy!.should be
      end
    end

    context 'page urls' do
      let(:page_path) { 'rspec-is-great-for-testing-too' }
      let(:child_path) { 'the-child-page' }
      it 'return a full path' do
        page.path.should == page_title
      end

      it 'and all of its parent page titles, reversed' do
        created_child.path.should == [page_title, child_title].join(' - ')
      end

      it 'or normally ;-)' do
        created_child.path(:reversed => true).should == [child_title, page_title].join(' - ')
      end

      it 'returns its url' do
        page.link_url = '/contact'
        page.url.should == '/contact'
      end

      it 'returns its path with marketable urls' do
        created_page.url[:id].should be_nil
        created_page.url[:path].should == [page_path]
      end

      it 'returns its path underneath its parent with marketable urls' do
        created_child.url[:id].should be_nil
        created_child.url[:path].should == [created_page.url[:path].first, child_path]
      end

      it 'no path parameter without marketable urls' do
        turn_off_marketable_urls
        created_page.url[:path].should be_nil
        created_page.url[:id].should == page_path
        turn_on_marketable_urls
      end

      it "doesn't mention its parent without marketable urls" do
        turn_off_marketable_urls
        created_child.url[:id].should == child_path
        created_child.url[:path].should be_nil
        turn_on_marketable_urls
      end

    end

    context 'canonicals' do
      before do
        Refinery::I18n.stub(:default_frontend_locale).and_return(:en)
        Refinery::I18n.stub(:frontend_locales).and_return([I18n.default_frontend_locale, :ru])
        # Globalize.stub(:locale).and_return(I18n.default_frontend_locale)
        page.save
      end
      let(:page_title)  { 'team' }
      let(:child_title) { 'about' }
      let(:ru_page_title) { 'Новости' }

      describe '#canonical' do
        let!(:default_canonical) {
          Globalize.with_locale(Refinery::I18n.default_frontend_locale) {
            page.canonical
          }
        }

        specify 'page returns itself' do
          page.canonical.should == page.url
        end

        specify 'default canonical matches page#canonical' do
          default_canonical.should == page.canonical
        end

        specify 'translated page returns master page' do
          Globalize.with_locale(:ru) do
            page.title = ru_page_title
            page.save

            page.canonical.should == default_canonical
          end
        end
      end

      describe '#canonical_slug' do
        let!(:default_canonical_slug) {
          Globalize.with_locale(Refinery::I18n.default_frontend_locale) {
            page.canonical_slug
          }
        }
        specify 'page returns its own slug' do
          page.canonical_slug.should == page.slug
        end

        specify 'default canonical_slug matches page#canonical' do
          default_canonical_slug.should == page.canonical_slug
        end

        specify "translated page returns master page's slug'" do
          Globalize.with_locale(:ru) do
            page.title = ru_page_title
            page.save

            page.canonical_slug.should == default_canonical_slug
          end
        end
      end
    end

    context 'custom slugs' do
      let(:custom_page_slug) { 'custom-page-slug' }
      let(:custom_child_slug) { 'custom-child-slug' }

      after(:each) do
        Globalize.stub(:locale).and_return(I18n.default_frontend_locale)
      end

      it 'returns its path with custom slug' do
        page = Page.create(:title => page_title, :custom_slug => custom_page_slug)
        page.url[:id].should be_nil
        page.url[:path].should == [custom_page_slug]
      end

      it 'returns its path underneath its parent with custom urls' do
        page = Page.create(:title => page_title, :custom_slug => custom_page_slug)
        child_with_custom_slug = page.children.create(:title => child_title, :custom_slug => custom_child_slug)
        child_with_custom_slug.url[:id].should be_nil
        child_with_custom_slug.url[:path].should == [page.url[:path].first, custom_child_slug]
      end

      it 'returns its path with custom slug when using different locale' do
        page_with_custom_slug = Page.create(:title => page_title, :custom_slug => custom_page_slug)

        Globalize.stub(:locale).and_return(:ru)
        page_with_custom_slug.custom_slug = "#{custom_page_slug}-ru"
        page_with_custom_slug.save
        page_with_custom_slug.reload

        page_with_custom_slug.url[:id].should be_nil
        page_with_custom_slug.url[:path].should == ["#{custom_page_slug}-ru"]
      end

      it 'returns path underneath its parent with custom urls when using different locale' do
        page = Page.create(:title => page_title, :custom_slug => custom_page_slug)
        child_with_custom_slug = page.children.create(:title => child_title, :custom_slug => custom_child_slug)

        Globalize.stub(:locale).and_return(:ru)
        child_with_custom_slug.custom_slug = "#{custom_child_slug}-ru"
        child_with_custom_slug.save
        child_with_custom_slug.reload

        child_with_custom_slug.url[:id].should be_nil
        child_with_custom_slug.url[:path].should == [page.url[:path].first, "#{custom_child_slug}-ru"]
      end

      context 'given a page with a custom_slug exists' do
        before do
          FactoryGirl.create(:page, :custom_slug => custom_page_slug)
        end

        it 'fails validation when a new record uses that custom_slug' do
          new_page = Page.new :custom_slug => custom_page_slug
          new_page.valid?

          new_page.errors[:custom_slug].should_not be_empty
        end
      end
    end

    context 'content sections (page parts)' do
      let(:page) { Page.create(:title => page_title) }

      before do
        page.part(:body).update(body: "I'm the first page part for this page.")
        page.part(:side_body).update(body: 'Closely followed by the second page part.')
      end

      it 'return the content when using content_for' do
        page.content_for(:body).should == "I'm the first page part for this page."
      end
    end

    context 'draft pages' do
      it 'not live when set to draft' do
        page.draft = true
        page.live?.should_not be
      end

      it 'live when not set to draft' do
        page.draft = false
        page.live?.should be
      end
    end

    context 'should add url suffix' do
      let(:reserved_word) { subject.class.friendly_id_config.reserved_words.last }
      let(:page_with_reserved_title) {
        subject.class.create!(:title => reserved_word, :deletable => true)
      }
      let(:child_with_reserved_title_parent) {
        page_with_reserved_title.children.create(:title => 'reserved title child page')
      }

      before { turn_on_marketable_urls }

      it 'when title is set to a reserved word' do
        page_with_reserved_title.url[:path].should == ["#{reserved_word}-page"]
      end

      it 'when parent page title is set to a reserved word' do
        child_with_reserved_title_parent.url[:path].should == ["#{reserved_word}-page", 'reserved-title-child-page']
      end
    end

    context 'meta data' do
      context 'responds to' do
        it 'meta_description' do
          page.respond_to?(:meta_description)
        end

        it 'browser_title' do
          page.respond_to?(:browser_title)
        end
      end

      context 'allows us to assign to' do
        it 'meta_description' do
          page.meta_description = 'This is my description of the page for search results.'
          page.meta_description.should == 'This is my description of the page for search results.'
        end

        it 'browser_title' do
          page.browser_title = 'An awesome browser title for SEO'
          page.browser_title.should == 'An awesome browser title for SEO'
        end
      end

      context 'allows us to update' do
        it 'meta_description' do
          page.meta_description = 'This is my description of the page for search results.'
          page.save

          page.reload
          page.meta_description.should == 'This is my description of the page for search results.'
        end

        it 'browser_title' do
          page.browser_title = 'An awesome browser title for SEO'
          page.save

          page.reload
          page.browser_title.should == 'An awesome browser title for SEO'
        end
      end

    end

    describe '#to_refinery_menu_item' do
      let(:page) do
        Page.new(
          :id => 5,
          :parent_id => 8

        # Page does not allow setting lft and rgt, so stub them.
        ).tap do |p|
          p[:lft] = 6
          p[:rgt] = 7
        end
      end

      subject { page.to_refinery_menu_item }

      shared_examples_for('Refinery menu item hash') do
        [ [:id, 5],
          [:lft, 6],
          [:rgt, 7],
          [:parent_id, 8]
        ].each do |attr, value|
          it "returns the correct :#{attr}" do
            subject[attr].should eq(value)
          end
        end

        # todo rewrite return correct slug instead url
        #it 'returns the correct :url' do
        ##  subject[:url].should be_a(Hash) # guard against nil
        ##  subject[:url].should eq(page.url)
        #end
      end

      context 'with #title' do
        before do
          page[:title] = 'Title'
        end

        it_should_behave_like 'Refinery menu item hash'

        it 'returns the title for :title' do
          subject[:title].should eq('Title')
        end
      end
    end

    describe '#in_menu?' do
      context 'when live? and show_in_menu? returns true' do
        it 'returns true' do
          page.stub(:live?).and_return(true)
          page.stub(:show_in_menu?).and_return(true)
          page.in_menu?.should be_true
        end
      end

      context "when live? or show_in_menu? doesn't return true" do
        it 'returns false' do
          page.stub(:live?).and_return(true)
          page.stub(:show_in_menu?).and_return(false)
          page.in_menu?.should be_false

          page.stub(:live?).and_return(false)
          page.stub(:show_in_menu?).and_return(true)
          page.in_menu?.should be_false
        end
      end
    end

    describe '#not_in_menu?' do
      context 'when in_menu? returns true' do
        it 'returns false' do
          page.stub(:in_menu?).and_return(true)
          page.not_in_menu?.should be_false
        end
      end

      context 'when in_menu? returns false' do
        it 'returns true' do
          page.stub(:in_menu?).and_return(false)
          page.not_in_menu?.should be_true
        end
      end
    end

    describe '.find_by_path' do
      let(:page_title)  { 'team' }
      let(:child_title) { 'about' }
      let(:created_root_about) { subject.class.create!(:title => child_title, :deletable => true) }

      before do
        # Ensure pages are created.
        Page.delete_all
        created_child
        created_root_about
      end

      it "should return (root) about page when looking for '/about'" do

        Page.find_by_path('about').should == created_root_about
      end

      it "should return child about page when looking for '/team/about'" do
        Page.find_by_path('team/about').should == created_child
      end
    end

    describe '.find_by_path_or_id' do
      let!(:market) { FactoryGirl.create(:page, :title => 'market') }
      let(:path) { 'market' }
      let(:id) { market.id }

      context 'when marketable urls are true and path is present' do
        before do
          Page.stub(:marketable_urls).and_return(true)
        end

        context 'when path is friendly_id' do
          it 'finds page using path' do
            Page.find_by_path_or_id(path, '').should eq(market)
          end
        end

        context 'when path is not friendly_id' do
          it 'finds page using id' do
            Page.find_by_path_or_id(id, '').should eq(market)
          end
        end
      end

      context 'when id is present' do
        before do
          Page.stub(:marketable_urls).and_return(false)
        end

        it 'finds page using id' do
          Page.find_by_path_or_id('', id).should eq(market)
        end
      end
    end

    describe '#deletable?' do
      let(:deletable_page) do
        page.deletable  = true
        page.link_url   = ''
        page.stub(:puts_destroy_help).and_return('')
        page
      end

      context 'when deletable is true' do
        it 'returns true' do
          deletable_page.deletable?.should be_true
        end
      end

      context 'when deletable is false' do
        it 'returns false' do
          deletable_page.deletable = false
          deletable_page.deletable?.should be_false
        end
      end
    end

    describe '#destroy' do
      before do
        page.deletable  = false
        page.save!
      end

      it 'shows message' do
        page.should_receive(:puts_destroy_help)

        page.destroy
      end
    end
  end
end
