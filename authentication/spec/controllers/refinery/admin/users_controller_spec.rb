require 'spec_helper'

describe Refinery::Admin::UsersController, type: :controller do
  refinery_login_with_factory :refinery_superuser

  shared_examples_for 'new, create, update, edit and update actions' do
    #it 'loads roles' do
    #  Refinery::Role.should_receive(:all).once{ [] }
    #  get :new
    #end

    it 'loads plugins' do
      user_plugin = Refinery::Plugins['users']

      plugins = Refinery::Plugins.new
      plugins << user_plugin

      #Refinery::Plugins.should_receive(:in_menu).once{ [user_plugin] }
      Refinery::Plugins.should_receive(:registered).at_least(1).times{ plugins }
      get :new
    end
  end

  describe '#new' do
    it 'renders the new template' do
      get :new
      response.should be_success
      response.should render_template('refinery/admin/users/new')
    end

    it_should_behave_like 'new, create, update, edit and update actions'
  end

  describe '#create' do
    let(:user_params) { {
      username: 'bob',
      email: 'bob@bob.com',
      password: 'password',
      password_confirmation: 'password',
      locale: 'en' }}
    let(:user) { Refinery::User.new(user_params)}

    before do
      ::Refinery::Admin::UsersController.any_instance.stub(:authenticated_current_user_with_password?).and_return(true)
    end

    after do
      ::Refinery::Admin::UsersController.any_instance.unstub(:authenticated_current_user_with_password?)
    end

    it 'redirect when new user is created' do
      post :create, user: user_params
      response.should be_redirect
    end

    it_should_behave_like 'new, create, update, edit and update actions'

    it 're-renders #new if there are errors' do
      user.save
      post :create, user: user_params
      response.should be_success
      response.should render_template('refinery/admin/users/new')
    end
  end

  describe '#edit' do
    it 'renders the edit template' do
      get :edit, id: logged_in_user.id
      response.should be_success
      response.should render_template('refinery/admin/users/edit')
    end

    it_should_behave_like 'new, create, update, edit and update actions'
  end

  describe '#update' do
    before do
      ::Refinery::Admin::UsersController.any_instance.stub(:authenticated_current_user_with_password?).and_return(true)
    end

    let(:additional_user) { FactoryGirl.create :refinery_user }
    it 'updates a user' do
      put 'update', id: additional_user.id.to_s, user: { username: additional_user.username, email: additional_user.email }
      response.should be_redirect
    end

    context 'when specifying plugins' do
      it "won't allow to remove 'Users' plugin from self" do
        # Refinery::User.should_receive(:find).at_least(1).times{ logged_in_user }
        # Refinery::Admin::UsersController.any_instance.should_receive(:find_user).at_least(1).times{ logged_in_user }
        put 'update', id: logged_in_user.id.to_s, user: { username: additional_user.username, email: additional_user.email, plugins: ['dashboard']}
        logged_in_user.plugins.collect(&:name).should include('users', 'dashboard')
      end

      it "will update to the plugins supplied" do
        plugins = %w(users dashboard)
        put 'update', id: logged_in_user.id.to_s, user: {plugins: plugins}

        logged_in_user.reload.plugins.collect(&:name).should == plugins
      end
    end

    it_should_behave_like 'new, create, update, edit and update actions'
  end
end
