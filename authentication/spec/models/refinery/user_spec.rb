require 'spec_helper'

module Refinery
  describe User do

    let(:user) { FactoryGirl.create(:user) }
    let(:refinery_user) { FactoryGirl.create(:refinery_user) }

    context 'Roles' do
      context 'add_role' do
        it 'raises Exception when Role object is passed' do
          proc {user.add_role(Refinery::Role.new)}.should raise_exception
        end

        it 'adds a Role to the User when role not yet assigned to User' do
          proc {
            user.add_role(:new_role)
          }.should change(user.roles, :count).by(1)
          user.roles.collect(&:title).should include('new_role')
        end

        it 'does not add a Role to the User when this Role is already assigned to User' do
          proc {
            refinery_user.add_role(:refinery)
          }.should_not change(refinery_user.roles, :count).by(1)
          refinery_user.roles.collect(&:title).should include('refinery')
        end
      end

      context 'has_role' do
        it 'raises Exception when Role object is passed' do
          proc{ user.has_role?(Refinery::Role.new)}.should raise_exception
        end

        it 'returns the true if user has Role' do
          refinery_user.has_role?(:refinery).should be_truthy
        end

        it 'returns false if user hasn\'t the Role' do
          refinery_user.has_role?(:refinery_fail).should be_falsey
        end
      end

      describe 'role association' do
        it 'have a roles attribute' do
          user.should respond_to(:roles)
        end
      end
    end

    context 'validations' do
      # email and password validations are done by including devises validatable
      # module so those validations are not tested here
      let(:attributes) do
        {
          :username => 'Refinery CMS',
          :email => 'refinery@cms.com',
          :password => '123456',
          :password_confirmation => '123456',
          :locale => 'en'
        }
      end

      it 'requires username' do
        User.new(attributes.merge(:username => '')).should_not be_valid
      end

      it 'rejects duplicate usernames' do
        User.create!(attributes)
        User.new(attributes.merge(:email => 'another@email.com')).should_not be_valid
      end

      it "rejects duplicate usernames regardless of case" do
        User.create!(attributes)
        User.new(attributes.merge(
          :username => attributes[:username].upcase,
          :email => "another@email.com")
        ).should_not be_valid
      end

      it "rejects duplicate usernames regardless of whitespace" do
        User.create!(attributes)
        new_user = User.new(attributes.merge(:username => " Refinery   CMS "))
        new_user.valid?
        new_user.username.should == 'refinery cms'
        new_user.should_not be_valid
      end
    end

    describe '.find_for_database_authentication' do
      it 'finds user either by username or email' do
        User.find_for_database_authentication(:login => user.username).should == user
        User.find_for_database_authentication(:login => user.email).should == user
      end
    end

    describe '#can_delete?' do
      let(:user_not_persisted) { FactoryGirl.build(:refinery_user) }
      let(:super_user) do
        super_user = FactoryGirl.create(:refinery_user)
        super_user.add_role(:superuser)
        super_user
      end

      context 'won\'t allow to delete' do
        it 'not persisted user record' do
          refinery_user.can_delete?(user_not_persisted).should be_falsey
        end

        it 'user with superuser role' do
          refinery_user.can_delete?(super_user).should be_falsey
        end

        it 'user himself' do
          refinery_user.can_delete?(refinery_user).should be_falsey
        end

        context 'none user with role refinery' do

          before do
            super_user.roles = [::Refinery::Role[:superuser]]
            refinery_user.roles = []
          end

          # for some reason delete users here not affect application counts
          # todo
          it 'if user count with refinery role < 1' do
            super_user.can_delete?(refinery_user).should be_falsey
          end

        end
      end

      context 'allow to delete' do
        it 'if user count with refinery role = 1' do
          ::Refinery::Role[:refinery].users.delete(refinery_user)
          super_user.can_delete?(refinery_user).should be_truthy
        end

        it 'if all conditions return true' do
          super_user.can_delete?(refinery_user).should be_truthy
        end
      end
    end

    describe '#can_edit?' do
      let(:user_not_persisted) { FactoryGirl.build(:refinery_user) }
      let(:super_user) do
        super_user = FactoryGirl.create(:refinery_user)
        super_user.add_role(:superuser)
        super_user
      end
      let(:user_persisted) { FactoryGirl.create(:refinery_user)}

      context 'won\'t allow to edit' do
        it 'non-persisted user record' do
          refinery_user.can_edit?(user_not_persisted).should be_falsey
        end

        it 'user is not a super user' do
          refinery_user.can_edit?(user_persisted).should be_falsey
        end
      end

      context 'allows to edit' do
        it 'when I am a user super' do
          super_user.can_edit?(user_persisted).should be_truthy
        end

        it 'if all conditions return true' do
          super_user.can_edit?(refinery_user).should be_truthy
        end
      end
    end

    describe '#plugins=' do
      it 'assigns plugins to user' do
        plugin_list = ['refinery_one', 'refinery_two', 'refinery_three']
        user.plugins = plugin_list
        user.plugins.collect { |p| p.name }.should == plugin_list
      end
    end

    describe '#authorized_plugins' do
      it 'returns array of user and always allowd plugins' do
        ['refinery_one', 'refinery_two', 'refinery_three'].each_with_index do |name, index|
          user.plugins.create!(:name => name, :position => index)
        end
        user.authorized_plugins.should == user.plugins.collect { |p| p.name } | ::Refinery::Plugins.always_allowed.names
      end
    end

    describe 'plugins association' do
      let(:plugin_list) { ['refinery_one', 'refinery_two', 'refinery_three'] }
      before { user.plugins = plugin_list }

      it 'have a plugins attribute' do
        user.should respond_to(:plugins)
      end

      it 'returns plugins in ASC order' do
        user.plugins[0].name.should == plugin_list[0]
        user.plugins[1].name.should == plugin_list[1]
        user.plugins[2].name.should == plugin_list[2]
      end

      it 'deletes associated plugins' do
        user.destroy
        UserPlugin.find_by(user_id: user.id).should be_nil
      end
    end

    describe '#create_first' do

      before do
        ::Refinery::User.delete_all
      end

      let(:first_user) do
        first = FactoryGirl.build(:user)
        first.create_first
        first
      end

      it 'adds refinery role' do
        first_user.roles.collect(&:title).should include('refinery')
      end

      it 'adds superuser role' do
        first_user.roles.collect(&:title).should include('superuser')
      end

      it 'adds registered plugins' do
        first_user.plugins.collect(&:name).should eq([
          'dashboard', 'pages', 'resources', 'images', 'users'
        ])
      end

      it 'returns true on success' do
        first_user.stub(:valid?).and_return(true)
        first_user.create_first.should == true
      end

      it 'returns false on failure' do
        first_user.stub(:valid?).and_return(false)
        first_user.create_first.should == false
      end
    end

  end
end
