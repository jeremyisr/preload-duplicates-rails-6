class Post < ApplicationRecord
  has_many :comments
  has_many :likes, through: :comments
  belongs_to :author
end
