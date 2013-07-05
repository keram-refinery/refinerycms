module Refinery
  class Role < Refinery::Core::BaseModel

    has_and_belongs_to_many :users, :join_table => :refinery_roles_users

    TITLE_MAX_LENGTH = 32

    before_validation :camelize_title
    validates :title, presence: true, :uniqueness => true, length: { maximum: TITLE_MAX_LENGTH }

    def camelize_title(role_title = self.title)
      self.title = role_title.to_s.camelize
    end

    def self.[](title)
      find_or_create_by(title: title.to_s.camelize)
    end

  end
end
