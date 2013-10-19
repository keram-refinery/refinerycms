module Refinery
  class PagePart < Refinery::Core::BaseModel

    belongs_to :page

    validates :title, uniqueness: { scope: :page_id }, inclusion: { in: Pages.parts }
    alias_attribute :content, :body

    translates :body
    default_scope { order(position: :asc ) }

    scope :active, -> { where active: true }
    scope :inactive, -> { where active: false }

    def to_param
      "page_part_#{title}"
    end

    def title
      self[:title].to_sym if self[:title]
    end

    def inactive
      !active
    end

  end
end
