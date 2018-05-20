require "spec_helper"

describe 'User admin page', type: :feature do
  refinery_login_with :refinery_superuser

  describe "new/create" do
    def visit_and_fill_form
      visit refinery.admin_users_path
      click_link "Add new user"

      fill_in 'user[username]', :with => 'test'
      fill_in 'user[email]', :with => 'test@refinerycms.com'
      fill_in 'user[password]', :with => '123456'
      fill_in 'user[password_confirmation]', :with => '123456'
    end

    it 'can create a user' do
      ::Refinery::Admin::UsersController.any_instance.stub(:authenticated_current_user_with_password?).and_return(true)
      visit_and_fill_form

      click_button "Save"

      page.should have_content("User 'test' was successfully added.")
      page.should have_content("test (test@refinerycms.com)")
      ::Refinery::Admin::UsersController.any_instance.unstub(:authenticated_current_user_with_password?)
    end

    context 'when assigning roles config is enabled' do
      before do
        Refinery::Authentication.stub(:superuser_can_assign_roles).and_return(true)
      end

      it 'disable superuser to assign roles if current user password is wrong or missing' do
        visit_and_fill_form

        within "#roles" do
          check "roles_#{Refinery::Role.first.title.downcase}"
        end
        click_button "Save"

        page.should have_content('Your password is wrong or missing, please try again.')
      end

      context 'authenticated' do
        before do
          ::Refinery::Admin::UsersController.any_instance.stub(:authenticated_current_user_with_password?).and_return(true)
        end

        after do
          ::Refinery::Admin::UsersController.any_instance.unstub(:authenticated_current_user_with_password?)
        end

        it 'allows superuser to assign roles' do
          visit_and_fill_form

          within "#roles" do
            check "roles_#{Refinery::Role.first.title.downcase}"
          end
          click_button "Save"

          page.should have_content("User 'test' was successfully added.")
          page.should have_content("test (test@refinerycms.com)")
        end
      end
    end
  end

  describe "edit/update" do
     it "can't update a user without authentication" do
      visit refinery.admin_users_path

      click_link "Edit this user"

      fill_in "Username", :with => 'cmsrefinery'
      fill_in "Email", :with => 'cms@refinerycms.com'
      click_button "Save"

      page.should have_content("Your password is wrong or missing, please try again.")
    end

    describe 'with authenticated user' do
      before do
        ::Refinery::Admin::UsersController.any_instance.stub(:authenticated_current_user_with_password?).and_return(true)
      end

      after do
        ::Refinery::Admin::UsersController.any_instance.unstub(:authenticated_current_user_with_password?)
      end

      it 'can update a user' do
        visit refinery.admin_users_path

        click_link "Edit this user"

        fill_in "Username", :with => 'cmsrefinery'
        fill_in "Email", :with => 'cms@refinerycms.com'
        click_button "Save"

        page.should have_content("User 'cmsrefinery' was successfully updated.")
        page.should have_content("cmsrefinery (cms@refinerycms.com)")
      end

      let(:dotty_user) { FactoryGirl.create(:refinery_user, :username => 'user.name.with.lots.of.dots') }
      it "accepts a username with a '.' in it" do
        dotty_user # create the user

        visit refinery.edit_admin_user_path(dotty_user)

        page.should have_css("form#edit_user_#{dotty_user.id}")
      end
    end

  end

  describe 'destroy' do
    let!(:user) { FactoryGirl.create(:user, :username => 'ugisozols') }

    it 'can only destroy regular users' do
      visit refinery.admin_users_path
      page.should have_selector("a[href='/#{Refinery::Core.backend_route}/users/#{user.username}']")
      page.should have_no_selector("a[href='/#{Refinery::Core.backend_route}/users/#{logged_in_user.username}']")
      page.should have_content(user.username)
      click_link "Remove this user"
      Refinery::User.count.should eq(1)
      page.should have_content("User 'ugisozols' was successfully removed.")

      within "#content" do
        page.should_not have_content(user.username)
      end
      page.should have_content("#{logged_in_user.username} (#{logged_in_user.email})")
    end
  end
end
