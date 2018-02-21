require 'test_helper'

class DashboardControllerTest < ActionController::TestCase

  def setup
    SysRouter.stubs(:base_path).returns(Rails.root.join("test/fixtures/sys"))
    OodFilesApp.any_instance.stubs(:favorite_paths).returns([Pathname.new("/fs/scratch/efranz")])
  end

  def teardown
    SysRouter.unstub(:base_path)
    OodFilesApp.any_instance.unstub(:favorite_paths)
  end

  def dropdown_list(title)
    css_select("li.dropdown[title='#{title}'] ul")
  end

  # given a dropdown list, return the list items as an array of strings
  # with symbols for header or divider
  def dropdown_list_items(list)
    css_select(list, "li").map do |item|
      if item['class'] && item['class'].include?("divider")
        :divider
      elsif item['class'] && item['class'].include?("dropdown-header")
        { :header => item.text.strip }
      else
        item.text.strip
      end
    end
  end

  test "should create Jobs dropdown" do
    get :index

    dditems = dropdown_list_items(dropdown_list('Jobs'))
    assert dditems.any?, "dropdown list items not found"
    assert_equal ["Active Jobs", "My Jobs"], dditems
  end

  test "should create Files dropdown" do
    get :index

    dditems = dropdown_list_items(dropdown_list('Files'))
    assert dditems.any?, "dropdown list items not found"
    assert_equal [
      "Home Directory",
      "/fs/scratch/efranz"], dditems
  end

  test "should create Clusters dropdown" do
    get :index

    dd = dropdown_list('Clusters')
    dditems = dropdown_list_items(dd)

    assert dditems.any?, "dropdown list items not found"

    #FIXME: reorder so this is alphabetical, then fix code
    assert_equal [
      "Oakley Shell Access",
      "Owens Shell Access",
      "Ruby Shell Access",
      "System Status"], dditems

    assert_select dd, "li a", "System Status" do |link|
      assert_equal "/apps/show/systemstatus", link.first['href'], "System Status link is incorrect"
    end
  end

  test "should create Interactive Apps dropdown" do
    SysRouter.stubs(:base_path).returns(Rails.root.join("test/fixtures/sys_with_interactive_apps"))

    get :index

    dd = dropdown_list('Interactive Apps')
    dditems = dropdown_list_items(dd)
    assert dditems.any?, "dropdown list items not found"
    assert_equal [
      {header: "Apps"},
      "Jupyter Notebook",
      "Paraview",
      :divider,
      {header: "Desktops"},
      "Oakley Desktop"], dditems

    assert_select dd, "li a", "Oakley Desktop" do |link|
      assert_equal "/batch_connect/sys/bc_desktop/oakley/session_contexts/new", link.first['href'], "Desktops link is incorrect"
    end

    SysRouter.unstub(:base_path)
  end

  test "should create My Interactive Apps link" do
    SysRouter.stubs(:base_path).returns(Rails.root.join("test/fixtures/sys_with_interactive_apps"))

    get :index
    assert_select "li[title='My Interactive Sessions'] a", "My Interactive Sessions"

    # assert_select doesn't have a refute_select, so the best we can do is a
    # css_select on the title - since we can't do contains - and assert above
    # that the link has both title and text set to the same thing.
    #
    # Then for our refutation test we can just assert an item with the title
    # does not exist.
    assert css_select("li[title='My Interactive Sessions']").any?

    SysRouter.unstub(:base_path)
  end

  test "should not create My Interactive Apps link" do
    SysRouter.stubs(:base_path).returns(Rails.root.join("test/fixtures/sys"))

    get :index
    assert css_select("li[title='My Interactive Sessions']").empty?

    SysRouter.unstub(:base_path)
  end

  test "should not create any empty links" do
    get :index

    assert_response :success
    assert_select "a[href='']", count: 0
  end
end
