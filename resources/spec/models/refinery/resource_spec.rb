require 'spec_helper'

module Refinery
  describe Resource do

    before do
      Refinery::Resource.delete_all
    end

    after do
      Refinery::Resource.delete_all
    end

    let(:resource) { FactoryGirl.create(:resource) }

    context 'with valid attributes' do
      it 'should create successfully' do
        resource.errors.should be_empty
      end
    end

    context 'resource url' do
      it 'should respond to .url' do
        resource.should respond_to(:url)
      end

      it 'should not support thumbnailing like images do' do
        resource.should_not respond_to(:thumbnail)
      end

      it 'should contain its filename at the end' do
        resource.url.split('/').last.should =~ /\A#{resource.file_name}/
      end
    end

    describe '#type_of_content' do
      it 'returns formated mime type' do
        resource.type_of_content.should == 'text plain'
      end
    end

    describe '#title' do
      it 'returns a titleized version of the filename' do
        resource.title.should == 'Refinery Is Awesome'
      end
    end

    describe '.create_resources' do
      before do
        Resource.delete_all
      end

      let(:file) { Refinery.roots(:'refinery/resources').join('spec/fixtures/refinery_is_awesome.txt') }
      let(:file2) { Refinery.roots(:'refinery/resources').join('spec/fixtures/refinery_is_awesome2.txt') }

      context 'only one resource uploaded' do
        it 'returns an array containing one resource' do
          Resource.create(:file => file)
          Resource.count.should eq(1)
        end
      end

      context 'many resources uploaded at once' do
        it 'returns an array containing all those resources' do
          [file, file2].map {|f| Resource.create(:file => f )}
          Resource.count.should eq(2)
        end
      end
    end

    describe 'validations' do
      describe 'valid #file' do
        before do
          @file = Refinery.roots(:'refinery/resources').join('spec/fixtures/refinery_is_awesome.txt')
          Resources.max_file_size = (File.read(@file).size + 10)
        end

        it 'should be valid when size does not exceed .max_file_size' do
          Resource.new(:file => @file).should be_valid
        end
      end

      describe 'too large #file' do
        before do
          @file = Refinery.roots(:'refinery/resources').join('spec/fixtures/refinery_is_awesome.txt')
          Resources.max_file_size = (File.read(@file).size - 10)
          @resource = Resource.new(:file => @file)
        end

        it 'should not be valid when size exceeds .max_file_size' do
          @resource.should_not be_valid
        end

        it 'should contain an error message' do
          @resource.valid?
          @resource.errors.should_not be_empty
          @resource.errors[:file].should == Array(::I18n.t(
            'too_big', :scope => 'activerecord.errors.models.refinery/resource',
                       :size => Resources.max_file_size
          ))
        end
      end

      describe 'invalid argument for #file' do
        before do
          @resource = Resource.new
        end

        it 'has an error message' do
          @resource.valid?
          @resource.errors.should_not be_empty
          @resource.errors[:file].should == Array(::I18n.t(
            'blank', :scope => 'activerecord.errors.models.refinery/resource'
          ))
        end
      end
    end
  end
end
