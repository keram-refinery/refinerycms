require 'spec_helper'

module Refinery
  describe 'AdminImages' do
    refinery_login_with :refinery_user

    before do
      Refinery::Image.delete_all
    end

    after do
      Refinery::Image.delete_all
    end

    context 'when no images' do
      it 'invites to add one' do
        visit refinery.admin_images_path
        page.should have_content(::I18n.t('no_images_yet', :scope => 'refinery.admin.images.records'))
      end
    end

    it 'shows add new image link' do
      visit refinery.admin_images_path
      page.should have_content(::I18n.t('create_new_image', :scope => 'refinery.admin.images.actions'))
      page.should have_selector("a[href*='#{refinery.new_admin_image_path}']")
    end

    context 'new/create' do
      it 'uploads image' do
        visit refinery.admin_images_path

        click_link ::I18n.t('create_new_image', :scope => 'refinery.admin.images.actions')

        page.should have_selector 'form#new_image'

        within 'form#new_image' do
          attach_file 'image_image', Refinery.roots(:'refinery/images').
                                              join('spec/fixtures/image-with-dashes.jpg')

          click_button ::I18n.t('save', :scope => 'refinery.admin.form_actions')
        end

        Refinery::Image.count.should == 1
      end

      it 'cannot upload a pdf', :js => true do
        visit refinery.admin_images_path

        click_link ::I18n.t('create_new_image', :scope => 'refinery.admin.images.actions')

        page.should have_selector 'form#new_image'

        within 'form#new_image' do
          attach_file 'image_image', Refinery.roots(:'refinery/images').
                                              join('spec/fixtures/cape-town-tide-table.pdf')
          click_button ::I18n.t('save', :scope => 'refinery.admin.form_actions')
        end

        within 'form#new_image' do
          page.should have_content(::I18n.t('incorrect_format', :scope => 'activerecord.errors.models.refinery/image'))
        end
        Refinery::Image.count.should == 0
      end

      it 'is accessible via url' do
        image = Refinery::Image.create(:image => Refinery.roots(:'refinery/images').join('spec/fixtures/image-with-dashes.jpg'))
        lambda { visit image.url }.should_not raise_error
      end
    end

#    context 'new/create - insert mode' do
#      it 'uploads image', :js => true do
#        visit refinery.admin_insert_images_path
#
#        attach_file 'image_image', Refinery.roots(:'refinery/images').join('spec/fixtures/image-with-dashes.jpg')
#        click_button ::I18n.t('save', :scope => 'refinery.admin.form_actions')
#
#        page.should have_selector('#existing-image-area', :visible => true)
#        Refinery::Image.count.should == 1
#      end
#
#      it 'gets error message when uploading non-image', :js => true do
#        visit refinery.admin_insert_images_path
#
#        attach_file 'image_image', Refinery.roots(:'refinery/images').join('spec/fixtures/cape-town-tide-table.pdf')
#        click_button ::I18n.t('save', :scope => 'refinery.admin.form_actions')
#
#        page.should have_selector('#upload_image_area', :visible => true)
#        page.should have_content(::I18n.t('incorrect_format', :scope => 'activerecord.errors.models.refinery/image'))
#        Refinery::Image.count.should == 0
#      end
#
#      it 'gets error message when uploading non-image (when an image already exists)', :js => true do
#        FactoryGirl.create(:image)
#        visit refinery.admin_insert_images_path
#
#        choose 'Upload'
#        attach_file 'image_image', Refinery.roots(:'refinery/images').join('spec/fixtures/cape-town-tide-table.pdf')
#        click_button ::I18n.t('save', :scope => 'refinery.admin.form_actions')
#
#        page.should have_selector('#upload_image_area', :visible => true)
#        page.should have_content(::I18n.t('incorrect_format', :scope => 'activerecord.errors.models.refinery/image'))
#        Refinery::Image.count.should == 1
#      end
#    end

    context 'when an image exists' do
      let!(:image) { FactoryGirl.create(:image) }

      context 'edit/update' do
        it 'updates image' do
          visit refinery.admin_images_path
          page.should have_selector("a[href='#{refinery.edit_admin_image_path(image)}']")

          click_link ::I18n.t('edit', :scope => 'refinery.admin.images')

          page.should have_content('Edit image')
          page.should have_selector("a[href*='#{refinery.admin_images_path}']")

          attach_file 'image_image', Refinery.roots(:'refinery/images').join('spec/fixtures/beach.jpeg')
          click_button ::I18n.t('save', :scope => 'refinery.admin.form_actions')

          page.should have_content(::I18n.t('updated', :scope => 'refinery.crudify', :kind => 'Image', :what => 'Beach'))
          Refinery::Image.count.should == 1

          lambda { click_link 'View this image' }.should_not raise_error
        end

        it "doesn't allow updating if image has different file name" do
          visit refinery.edit_admin_image_path(image)

          attach_file 'image_image', Refinery.roots(:'refinery/images').join('spec/fixtures/fathead.png')
          click_button ::I18n.t('save', :scope => 'refinery.admin.form_actions')

          page.should have_content(::I18n.t('different_file_name',
                                            :scope => 'activerecord.errors.models.refinery/image'))
        end
      end

      context 'destroy' do
        it 'removes image' do
          visit refinery.admin_images_path
          page.should have_selector("a[href='#{refinery.admin_image_path(image)}']")

          click_link ::I18n.t('delete', :scope => 'refinery.admin.images')

          Refinery::Image.count.should == 0
        end
      end

      context 'download' do
        it 'succeeds' do
          visit refinery.admin_images_path

          lambda { click_link 'View this image' }.should_not raise_error
        end
      end

      describe 'switch view' do
        it 'shows images in grid' do
          visit refinery.admin_images_path
          page.should have_content(::I18n.t('switch_to', :view_name => 'list', :scope => 'refinery.admin.images.index.view'))
          page.should have_selector("a[href='#{refinery.admin_images_path(:page => 1, :view => 'list')}']")

          click_link 'Switch to list view'

          page.should have_content(::I18n.t('switch_to', :view_name => 'grid', :scope => 'refinery.admin.images.index.view'))
          page.should have_selector("a[href='#{refinery.admin_images_path(:page => 1, :view => 'grid')}']")
        end
      end

    end
  end
end
