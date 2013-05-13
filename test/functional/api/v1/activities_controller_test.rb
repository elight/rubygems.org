require 'test_helper'
require 'pry'

class Api::V1::ActivitiesControllerTest < ActionController::TestCase

  def should_return_latest_gems(gems)
    assert_equal 2, gems.length
    gems.each {|g| assert g.is_a?(Hash) }
    assert_equal @rubygem_2.attributes['name'], gems[0]['name']
    assert_equal @rubygem_3.attributes['name'], gems[1]['name']
  end

  def should_return_just_updated_gems(gems)
    assert_equal 3, gems.length
    gems.each {|g| assert g.is_a?(Hash) }
    assert_equal @rubygem_1.attributes['name'], gems[0]['name']
    assert_equal @rubygem_2.attributes['name'], gems[1]['name']
    assert_equal @rubygem_3.attributes['name'], gems[2]['name']
    assert gems[0]['versions'], "JSON for the first gem should have contained the version"
    assert gems[0]['versions'][0]['prerelease'], "JSON for the first gem should have contained version prerelease"
    assert gems[0]['versions'][0]['built_at'], "JSON for the first gem should have contained version built_at"
  end

  context "No signed in-user" do
    context "On GET to latest" do
      setup do
        @rubygem_1 = create(:rubygem)
        @version_1 = create(:version, :rubygem => @rubygem_1)
        @version_2 = create(:version, :rubygem => @rubygem_1)

        @rubygem_2 = create(:rubygem)
        @version_3 = create(:version, :rubygem => @rubygem_2)

        @rubygem_3 = create(:rubygem)
        @version_4 = create(:version, :rubygem => @rubygem_3)

        stub(Rubygem).latest(50){ [@rubygem_2, @rubygem_3] }
      end

      should "return correct JSON for latest gems" do
        get :latest, :format => :json
        should_return_latest_gems MultiJson.load(@response.body)
      end

      should "return correct YAML for latest gems" do
        get :latest, :format => :yaml
        should_return_latest_gems YAML.load(@response.body)
      end

      should "return correct XML for latest gems" do
        get :latest, :format => :xml
        gems = Hash.from_xml(Nokogiri.parse(@response.body).to_xml)['rubygems']
        should_return_latest_gems(gems)
      end
    end

    context "On GET to just_updated" do
      setup do
        @rubygem_1 = create(:rubygem)
        @version_1 = create(:version, :rubygem => @rubygem_1, :number => '1.0.0', :built_at => Time.now)
        @version_2 = create(:version, :rubygem => @rubygem_1, :number => '1.0.0.pre', :built_at => Time.now)

        @rubygem_2 = create(:rubygem)
        @version_3 = create(:version, :rubygem => @rubygem_2)

        @rubygem_3 = create(:rubygem)
        @version_4 = create(:version, :rubygem => @rubygem_3)

        stub(Version).just_updated(50){ [@version_2, @version_3, @version_4] }
      end

      should "return a 200 status" do
        get :just_updated, :format => :json
        assert_equal 200, @response.status
      end

      should "return correct JSON for just_updated gems" do
        get :just_updated, :format => :json
        should_return_just_updated_gems MultiJson.load(@response.body)
      end

      should "return correct YAML for just_updated gems" do
        get :just_updated, :format => :yaml
        should_return_just_updated_gems YAML.load(@response.body)
      end

      should "return correct XML for just_updated gems" do
        get :just_updated, :format => :xml
        gems = Hash.from_xml(Nokogiri.parse(@response.body).to_xml)['objects']
        should_return_just_updated_gems(gems)
      end
    end
  end
end
