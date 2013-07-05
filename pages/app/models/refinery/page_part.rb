module Refinery
  class PagePart < Refinery::Core::BaseModel

    belongs_to :page

    validates :title, presence: true, uniqueness: { scope: :page_id }
    alias_attribute :content, :body

    translates :body

    def to_param
      "page_part_#{title.downcase.gsub(/\W/, '_')}"
    end

  end
end
