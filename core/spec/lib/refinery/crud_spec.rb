require 'spec_helper'

ActiveRecord::Schema.define do
  create_table :refinery_crud_dummies, :force => true do |t|
    t.integer :parent_id
    t.integer :lft
    t.integer :rgt
    t.integer :depth
  end
end

module Refinery
  class CrudDummy < ActiveRecord::Base
    acts_as_nested_set
  end

  class CrudDummyController < ::ApplicationController
    crudify :'refinery/crud_dummy'
  end
end

module Refinery
  describe CrudDummyController, :type => :controller do

    describe '#update_positions' do
      let!(:crud_dummy_one) { Refinery::CrudDummy.create! }
      let!(:crud_dummy_two) { Refinery::CrudDummy.create! }
      let!(:crud_dummy_three) { Refinery::CrudDummy.create! }

      before do
        CrudDummyController.any_instance.stub(:render).and_return(nil)
      end

      after do
        CrudDummyController.any_instance.unstub(:render)
      end

      it 'orders dummies' do
        post :update_positions, { 'item' => {
            id: crud_dummy_three.id,
            next_id: crud_dummy_two.id
        }}

        post :update_positions, { 'item' => {
            id: crud_dummy_one.id,
            prev_id: crud_dummy_two.id
        }}

        dummy_three = crud_dummy_three.reload
        dummy_three.lft.should eq(1)
        dummy_three.rgt.should eq(2)

        dummy_two = crud_dummy_two.reload
        dummy_two.lft.should eq(3)
        dummy_two.rgt.should eq(4)

        dummy_one = crud_dummy_one.reload
        dummy_one.lft.should eq(5)
        dummy_one.rgt.should eq(6)
      end

      it 'orders nested dummies' do
        nested_crud_dummy_one = Refinery::CrudDummy.create! :parent_id => crud_dummy_one.id
        nested_crud_dummy_two = Refinery::CrudDummy.create! :parent_id => crud_dummy_one.id

        post :update_positions, { 'item' => {
            id: crud_dummy_three.id,
            next_id: crud_dummy_two.id
        }}

        post :update_positions, { 'item' => {
            id: crud_dummy_one.id,
            prev_id: crud_dummy_two.id
        }}

        post :update_positions, { 'item' => {
            id: nested_crud_dummy_one.id,
            parent_id: crud_dummy_three.id
        }}

        post :update_positions, { 'item' => {
            id: nested_crud_dummy_two.id,
            parent_id: crud_dummy_three.id
        }}

        dummy = crud_dummy_three.reload
        dummy.lft.should eq(1)
        dummy.rgt.should eq(6)

        dummy = nested_crud_dummy_one.reload
        dummy.lft.should eq(2)
        dummy.rgt.should eq(3)
        dummy.parent_id.should eq(crud_dummy_three.id)

        dummy = nested_crud_dummy_two.reload
        dummy.lft.should eq(4)
        dummy.rgt.should eq(5)
        dummy.parent_id.should eq(crud_dummy_three.id)

        dummy = crud_dummy_two.reload
        dummy.lft.should eq(7)
        dummy.rgt.should eq(8)

        dummy = crud_dummy_one.reload
        dummy.lft.should eq(9)
        dummy.rgt.should eq(10)
      end
    end

    describe 'update_positions  regression' do

      # Regression test for https://github.com/refinery/refinerycms/issues/1585
      # mla: probably out of date
      it 'sorts numerically rather than by string key' do
        dummy, dummy_params = [], []

        # When we have 11 entries, the 11th index will be #10, which will be
        # sorted above #2 if we are sorting by strings.
        11.times do |n|
          dummy << Refinery::CrudDummy.create!
          dummy_params.push({id: dummy[n].id})
        end

        dummy = dummy.last.reload
        dummy.lft.should eq(21)
      end
    end

  end
end
