class Author < ApplicationRecord
  has_many :posts
  has_many :computers
end
