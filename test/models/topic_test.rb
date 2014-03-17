require 'test_helper'

class TopicTest < ActiveSupport::TestCase
  test "should update hot after create" do
    topic = create(:topic)
    assert topic.calculate_hot > 0
  end

  test "should update counter cache" do
    category = create(:category)
    topic = create(:topic, category: category)
    assert_equal 1, category.reload.topics_count
    topic.trash
    assert_equal 0, category.reload.topics_count
    topic.restore
    assert_equal 1, category.reload.topics_count
    topic.destroy
    assert_equal 0, category.reload.topics_count
  end

  test "should update counter after category change" do
    c1, c2 = create(:category), create(:category)
    topic = create(:topic, category: c1)
    topic.category = c2
    topic.save
    assert_equal 0, c1.reload.topics_count
    assert_equal 1, c2.reload.topics_count
  end

  test "should update hot after comment change" do
    topic = create(:topic, comments_count: 1)
    hot = topic.hot
    comment = create(:comment, commentable: topic)
    assert topic.reload.hot > hot
    comment.destroy
    assert_equal hot, topic.hot
  end

  test "should trash" do
    topic = create(:topic)

    assert_difference "Topic.trashed.count" do
      assert_difference "Topic.count", -1 do
        topic.trash
        assert_equal true, topic.trashed?
      end
    end

    assert_difference "Topic.trashed.count", -1 do
      assert_difference "Topic.count" do
        topic.restore
        assert_equal false, topic.trashed?
      end
    end
  end

  test "should add user to subscribers" do
    topic = create(:topic)
    assert topic.subscribed_by?(topic.user)
  end

  test "should subscribe_by user" do
    topic = create(:topic)
    user = create(:user)
    topic.subscribe_by user
    assert topic.subscribed_by? user
  end

  test "should ignore_by user" do
    topic = create(:topic)
    user = create(:user)
    topic.ignore_by user
    assert topic.ignored_by? user
  end

  test "should delete_all likes after trash" do
    topic = create(:topic)
    create :like, likeable: topic
    assert_difference "Like.count", -1 do
      topic.trash
    end
  end
end
