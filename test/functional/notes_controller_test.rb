require File.dirname(__FILE__) + '/../test_helper'

class NotesControllerTest < ActionController::TestCase
  fixtures :users, :notes, :note_comments

  ##
  # test all routes which lead to this controller
  def test_routes
    assert_routing(
      { :path => "/api/0.6/notes", :method => :post },
      { :controller => "notes", :action => "create", :format => "xml" }
    )
    assert_routing(
      { :path => "/api/0.6/notes/1", :method => :get },
      { :controller => "notes", :action => "show", :id => "1", :format => "xml" }
    )
    assert_recognizes(
      { :controller => "notes", :action => "show", :id => "1", :format => "xml" },
      { :path => "/api/0.6/notes/1.xml", :method => :get }
    )
    assert_routing(
      { :path => "/api/0.6/notes/1.rss", :method => :get },
      { :controller => "notes", :action => "show", :id => "1", :format => "rss" }
    )
    assert_routing(
      { :path => "/api/0.6/notes/1.json", :method => :get },
      { :controller => "notes", :action => "show", :id => "1", :format => "json" }
    )
    assert_routing(
      { :path => "/api/0.6/notes/1.gpx", :method => :get },
      { :controller => "notes", :action => "show", :id => "1", :format => "gpx" }
    )
    assert_routing(
      { :path => "/api/0.6/notes/1/comment", :method => :post },
      { :controller => "notes", :action => "comment", :id => "1", :format => "xml" }
    )
    assert_routing(
      { :path => "/api/0.6/notes/1/close", :method => :post },
      { :controller => "notes", :action => "close", :id => "1", :format => "xml" }
    )
    assert_routing(
      { :path => "/api/0.6/notes/1", :method => :delete },
      { :controller => "notes", :action => "destroy", :id => "1", :format => "xml" }
    )

    assert_routing(
      { :path => "/api/0.6/notes", :method => :get },
      { :controller => "notes", :action => "index", :format => "xml" }
    )
    assert_recognizes(
      { :controller => "notes", :action => "index", :format => "xml" },
      { :path => "/api/0.6/notes.xml", :method => :get }
    )
    assert_routing(
      { :path => "/api/0.6/notes.rss", :method => :get },
      { :controller => "notes", :action => "index", :format => "rss" }
    )
    assert_routing(
      { :path => "/api/0.6/notes.json", :method => :get },
      { :controller => "notes", :action => "index", :format => "json" }
    )
    assert_routing(
      { :path => "/api/0.6/notes.gpx", :method => :get },
      { :controller => "notes", :action => "index", :format => "gpx" }
    )

    assert_routing(
      { :path => "/api/0.6/notes/search", :method => :get },
      { :controller => "notes", :action => "search", :format => "xml" }
    )
    assert_recognizes(
      { :controller => "notes", :action => "search", :format => "xml" },
      { :path => "/api/0.6/notes/search.xml", :method => :get }
    )
    assert_routing(
      { :path => "/api/0.6/notes/search.rss", :method => :get },
      { :controller => "notes", :action => "search", :format => "rss" }
    )
    assert_routing(
      { :path => "/api/0.6/notes/search.json", :method => :get },
      { :controller => "notes", :action => "search", :format => "json" }
    )
    assert_routing(
      { :path => "/api/0.6/notes/search.gpx", :method => :get },
      { :controller => "notes", :action => "search", :format => "gpx" }
    )

    assert_routing(
      { :path => "/api/0.6/notes/feed", :method => :get },
      { :controller => "notes", :action => "feed", :format => "rss" }
    )

    assert_recognizes(
      { :controller => "notes", :action => "create" },
      { :path => "/api/0.6/notes/addPOIexec", :method => :post }
    )
    assert_recognizes(
      { :controller => "notes", :action => "close" },
      { :path => "/api/0.6/notes/closePOIexec", :method => :post }
    )
    assert_recognizes(
      { :controller => "notes", :action => "comment" },
      { :path => "/api/0.6/notes/editPOIexec", :method => :post }
    )
    assert_recognizes(
      { :controller => "notes", :action => "index", :format => "gpx" },
      { :path => "/api/0.6/notes/getGPX", :method => :get }
    )
    assert_recognizes(
      { :controller => "notes", :action => "feed", :format => "rss" },
      { :path => "/api/0.6/notes/getRSSfeed", :method => :get }
    )

    assert_routing(
      { :path => "/user/username/notes", :method => :get },
      { :controller => "notes", :action => "mine", :display_name => "username" }
    )
  end

  def test_note_create_success
    assert_difference('Note.count') do
      assert_difference('NoteComment.count') do
        post :create, {:lat => -1.0, :lon => -1.0, :text => "This is a comment", :format => "json"}
      end
    end
    assert_response :success
    js = ActiveSupport::JSON.decode(@response.body)
    assert_not_nil js
    assert_equal "Feature", js["type"]
    assert_equal "Point", js["geometry"]["type"]
    assert_equal [-1.0, -1.0], js["geometry"]["coordinates"]
    assert_equal "open", js["properties"]["status"]
    assert_equal 1, js["properties"]["comments"].count
    assert_equal "opened", js["properties"]["comments"].last["action"]
    assert_equal "This is a comment", js["properties"]["comments"].last["text"]
    assert_nil js["properties"]["comments"].last["user"]
    id = js["properties"]["id"]

    get :show, {:id => id, :format => "json"}
    assert_response :success
    js = ActiveSupport::JSON.decode(@response.body)
    assert_not_nil js
    assert_equal "Feature", js["type"]
    assert_equal "Point", js["geometry"]["type"]
    assert_equal [-1.0, -1.0], js["geometry"]["coordinates"]
    assert_equal id, js["properties"]["id"]
    assert_equal "open", js["properties"]["status"]
    assert_equal 1, js["properties"]["comments"].count
    assert_equal "opened", js["properties"]["comments"].last["action"]
    assert_equal "This is a comment", js["properties"]["comments"].last["text"]
    assert_nil js["properties"]["comments"].last["user"]
  end

  def test_note_create_fail
    assert_no_difference('Note.count') do
      assert_no_difference('NoteComment.count') do
        post :create, {:lon => -1.0, :text => "This is a comment"}
      end
    end
    assert_response :bad_request

    assert_no_difference('Note.count') do
      assert_no_difference('NoteComment.count') do
        post :create, {:lat => -1.0, :text => "This is a comment"}
      end
    end
    assert_response :bad_request

    assert_no_difference('Note.count') do
      assert_no_difference('NoteComment.count') do
        post :create, {:lat => -1.0, :lon => -1.0}
      end
    end
    assert_response :bad_request

    assert_no_difference('Note.count') do
      assert_no_difference('NoteComment.count') do
        post :create, {:lat => -1.0, :lon => -1.0, :text => ""}
      end
    end
    assert_response :bad_request

    assert_no_difference('Note.count') do
      assert_no_difference('NoteComment.count') do
        post :create, {:lat => -100.0, :lon => -1.0, :text => "This is a comment"}
      end
    end
    assert_response :bad_request

    assert_no_difference('Note.count') do
      assert_no_difference('NoteComment.count') do
        post :create, {:lat => -1.0, :lon => -200.0, :text => "This is a comment"}
      end
    end
    assert_response :bad_request
  end

  def test_note_comment_create_success
    assert_difference('NoteComment.count') do
      post :comment, {:id => notes(:open_note_with_comment).id, :text => "This is an additional comment", :format => "json"}
    end
    assert_response :success
    js = ActiveSupport::JSON.decode(@response.body)
    assert_not_nil js
    assert_equal "Feature", js["type"]
    assert_equal notes(:open_note_with_comment).id, js["properties"]["id"]
    assert_equal "open", js["properties"]["status"]
    assert_equal 3, js["properties"]["comments"].count
    assert_equal "commented", js["properties"]["comments"].last["action"]
    assert_equal "This is an additional comment", js["properties"]["comments"].last["text"]
    assert_nil js["properties"]["comments"].last["user"]

    get :show, {:id => notes(:open_note_with_comment).id, :format => "json"}
    assert_response :success
    js = ActiveSupport::JSON.decode(@response.body)
    assert_not_nil js
    assert_equal "Feature", js["type"]
    assert_equal notes(:open_note_with_comment).id, js["properties"]["id"]
    assert_equal "open", js["properties"]["status"]
    assert_equal 3, js["properties"]["comments"].count
    assert_equal "commented", js["properties"]["comments"].last["action"]
    assert_equal "This is an additional comment", js["properties"]["comments"].last["text"]
    assert_nil js["properties"]["comments"].last["user"]
  end

  def test_note_comment_create_fail
    assert_no_difference('NoteComment.count') do
      post :comment, {:text => "This is an additional comment"}
    end
    assert_response :bad_request

    assert_no_difference('NoteComment.count') do
      post :comment, {:id => notes(:open_note_with_comment).id}
    end
    assert_response :bad_request

    assert_no_difference('NoteComment.count') do
      post :comment, {:id => notes(:open_note_with_comment).id, :text => ""}
    end
    assert_response :bad_request

    assert_no_difference('NoteComment.count') do
      post :comment, {:id => 12345, :text => "This is an additional comment"}
    end
    assert_response :not_found

    assert_no_difference('NoteComment.count') do
      post :comment, {:id => notes(:hidden_note_with_comment).id, :text => "This is an additional comment"}
    end
    assert_response :gone

    assert_no_difference('NoteComment.count') do
      post :comment, {:id => notes(:closed_note_with_comment).id, :text => "This is an additional comment"}
    end
    assert_response :conflict
  end

  def test_note_close_success
    post :close, {:id => notes(:open_note_with_comment).id, :text => "This is a close comment", :format => "json"}
    assert_response :success
    js = ActiveSupport::JSON.decode(@response.body)
    assert_not_nil js
    assert_equal "Feature", js["type"]
    assert_equal notes(:open_note_with_comment).id, js["properties"]["id"]
    assert_equal "closed", js["properties"]["status"]
    assert_equal 3, js["properties"]["comments"].count
    assert_equal "closed", js["properties"]["comments"].last["action"]
    assert_equal "This is a close comment", js["properties"]["comments"].last["text"]
    assert_nil js["properties"]["comments"].last["user"]

    get :show, {:id => notes(:open_note_with_comment).id, :format => "json"}
    assert_response :success
    js = ActiveSupport::JSON.decode(@response.body)
    assert_not_nil js
    assert_equal "Feature", js["type"]
    assert_equal notes(:open_note_with_comment).id, js["properties"]["id"]
    assert_equal "closed", js["properties"]["status"]
    assert_equal 3, js["properties"]["comments"].count
    assert_equal "closed", js["properties"]["comments"].last["action"]
    assert_equal "This is a close comment", js["properties"]["comments"].last["text"]
    assert_nil js["properties"]["comments"].last["user"]
  end

  def test_note_close_fail
    post :close
    assert_response :bad_request

    post :close, {:id => 12345}
    assert_response :not_found

    post :close, {:id => notes(:hidden_note_with_comment).id}
    assert_response :gone

    post :close, {:id => notes(:closed_note_with_comment).id}
    assert_response :conflict
  end

  def test_note_read_success
    get :show, {:id => notes(:open_note).id, :format => "xml"}
    assert_response :success
    assert_equal "application/xml", @response.content_type

    get :show, {:id => notes(:open_note).id, :format => "rss"}
    assert_response :success
    assert_equal "application/rss+xml", @response.content_type

    get :show, {:id => notes(:open_note).id, :format => "json"}
    assert_response :success
    assert_equal "application/json", @response.content_type

    get :show, {:id => notes(:open_note).id, :format => "gpx"}
    assert_response :success
    assert_equal "application/gpx+xml", @response.content_type
  end

  def test_note_read_hidden_comment
    get :show, {:id => notes(:note_with_hidden_comment).id, :format => "json"}
    assert_response :success
    js = ActiveSupport::JSON.decode(@response.body)
    assert_not_nil js
    assert_equal notes(:note_with_hidden_comment).id, js["properties"]["id"]
    assert_equal 2, js["properties"]["comments"].count
    assert_equal "Valid comment for note 5", js["properties"]["comments"][0]["text"]
    assert_equal "Another valid comment for note 5", js["properties"]["comments"][1]["text"]
  end

  def test_note_read_fail
    get :show, {:id => 12345}
    assert_response :not_found

    get :show, {:id => notes(:hidden_note_with_comment).id}
    assert_response :gone
  end

  def test_note_delete_success
    delete :destroy, {:id => notes(:open_note_with_comment).id}
    assert_response :success

    get :show, {:id => notes(:open_note_with_comment).id, :format => 'json'}
    assert_response :gone
  end

  def test_note_delete_fail
    delete :destroy, {:id => 12345}
    assert_response :not_found

    delete :destroy, {:id => notes(:hidden_note_with_comment).id}
    assert_response :gone
  end

  def test_get_notes_success
#    get :index, {:bbox => '1,1,1.2,1.2'}
#    assert_response :success
#    assert_equal "text/javascript", @response.content_type

    get :index, {:bbox => '1,1,1.2,1.2', :format => 'rss'}
    assert_response :success
    assert_equal "application/rss+xml", @response.content_type

    get :index, {:bbox => '1,1,1.2,1.2', :format => 'json'}
    assert_response :success
    assert_equal "application/json", @response.content_type

    get :index, {:bbox => '1,1,1.2,1.2', :format => 'xml'}
    assert_response :success
    assert_equal "application/xml", @response.content_type

    get :index, {:bbox => '1,1,1.2,1.2', :format => 'gpx'}
    assert_response :success
    assert_equal "application/gpx+xml", @response.content_type
  end

  def test_get_notes_large_area
#    get :index, {:bbox => '-2.5,-2.5,2.5,2.5'}
#    assert_response :success

#    get :index, {:l => '-2.5', :b => '-2.5', :r => '2.5', :t => '2.5'}
#    assert_response :success

    get :index, {:bbox => '-10,-10,12,12'}
    assert_response :bad_request

    get :index, {:l => '-10', :b => '-10', :r => '12', :t => '12'}
    assert_response :bad_request
  end

  def test_get_notes_closed
    get :index, {:bbox => '1,1,1.7,1.7', :closed => '7', :format => 'json'}
    assert_response :success
    assert_equal "application/json", @response.content_type
    js = ActiveSupport::JSON.decode(@response.body)
    assert_not_nil js
    assert_equal "FeatureCollection", js["type"]
    assert_equal 4, js["features"].count

    get :index, {:bbox => '1,1,1.7,1.7', :closed => '0', :format => 'json'}
    assert_response :success
    assert_equal "application/json", @response.content_type
    js = ActiveSupport::JSON.decode(@response.body)
    assert_not_nil js
    assert_equal "FeatureCollection", js["type"]
    assert_equal 4, js["features"].count

    get :index, {:bbox => '1,1,1.7,1.7', :closed => '-1', :format => 'json'}
    assert_response :success
    assert_equal "application/json", @response.content_type
    js = ActiveSupport::JSON.decode(@response.body)
    assert_not_nil js
    assert_equal "FeatureCollection", js["type"]
    assert_equal 6, js["features"].count
  end

  def test_get_notes_bad_params
    get :index, {:bbox => '-2.5,-2.5,2.5'}
    assert_response :bad_request

    get :index, {:bbox => '-2.5,-2.5,2.5,2.5,2.5'}
    assert_response :bad_request

    get :index, {:b => '-2.5', :r => '2.5', :t => '2.5'}
    assert_response :bad_request

    get :index, {:l => '-2.5', :r => '2.5', :t => '2.5'}
    assert_response :bad_request

    get :index, {:l => '-2.5', :b => '-2.5', :t => '2.5'}
    assert_response :bad_request

    get :index, {:l => '-2.5', :b => '-2.5', :r => '2.5'}
    assert_response :bad_request
  end

  def test_search_success
    get :search, {:q => 'note 1', :format => 'xml'}
    assert_response :success
    assert_equal "application/xml", @response.content_type

    get :search, {:q => 'note 1', :format => 'json'}
    assert_response :success
    assert_equal "application/json", @response.content_type

    get :search, {:q => 'note 1', :format => 'rss'}
    assert_response :success
    assert_equal "application/rss+xml", @response.content_type

    get :search, {:q => 'note 1', :format => 'gpx'}
    assert_response :success
    assert_equal "application/gpx+xml", @response.content_type
  end

  def test_search_bad_params
    get :search
    assert_response :bad_request
  end

  def test_rss_success
    get :feed, {:format => "rss"}
    assert_response :success
    assert_equal "application/rss+xml", @response.content_type

    get :feed, {:bbox => "1,1,1.2,1.2", :format => "rss"}
    assert_response :success	
    assert_equal "application/rss+xml", @response.content_type
  end

  def test_rss_fail
    get :feed, {:bbox => "1,1,1.2"}
    assert_response :bad_request

    get :feed, {:bbox => "1,1,1.2,1.2,1.2"}
    assert_response :bad_request
  end

  def test_user_notes_success
    get :mine, {:display_name => "test"}
    assert_response :success

    get :mine, {:display_name => "pulibc_test2"}
    assert_response :success

    get :mine, {:display_name => "non-existent"}
    assert_response :not_found	
  end
end
