# spec/support/guide_story_world.rb

# The one fixed world the User Guide's story is told in (docs/user-guide/
# story). Every story screenshot spec builds it, so the same people, posts,
# events and recipes appear from chapter to chapter, and each persona really
# sees what their chapter says they see: Charlie owns content at all three
# classifications, so Gary (a guest) sees only the Unrestricted part of it.
#
# Names, dates and images are fixed; call it inside travel_to(STORY_TIME) so
# "created" dates and Events By Day come out the same on every run.
module GuideStoryWorld
  STORY_TIME = Time.zone.local(2026, 11, 2, 10, 0)
  # Only files committed to git: CI checks out nothing else.
  PORTRAITS  = {
    "Charlie" => "docs/user-guide/story/images/charlie_content_creator_portrait.png",
    "Ulrika"  => "docs/user-guide/story/images/ulrika_user_portrait.png",
    "Adam"    => "docs/user-guide/story/images/adam_admin_portrait.png",
    "Sam"     => "docs/user-guide/system_admin/images/sam_system_admin_portrait.png",
    "Gary"    => "docs/user-guide/story/images/gary_guest_portrait.png"
  }.transform_values { |path| Rails.root.join(path) }.freeze
  HEROES     = Rails.root.join("spec/fixtures/files/guide_story")
  IMAGES     = Rails.root.join("docs/test-data/images")

  World = Struct.new(:charlie, :ulrika, :adam, :sam, :posts, :people, :events, :recipes, :engagements,
    keyword_init: true)

  def build_story_world
    charlie = story_user("Charlie", "Content Creator", :content_creator)
    ulrika  = story_user("Ulrika", "User", :app_user)
    adam    = story_user("Adam", "Admin", :admin)
    sam     = story_user("Sam", "SysAdmin", :system_admin)

    World.new(charlie: charlie, ulrika: ulrika, adam: adam, sam: sam,
      posts:   story_posts(charlie, ulrika, adam),
      people:  people = story_people(charlie),
      events:  story_events(charlie, people),
      recipes: story_recipes(charlie, ulrika),
      engagements: story_engagements(charlie))
  end

  # Gary's sign-up request (chapter 2), waiting for Sam to review it.
  def gary_signs_up
    user = create(:user, first_name: "Gary", last_name: "Guest", status: :pending,
      email_address: "gary@example.com", message_to_admin: "Hi! Ulrika and Charlie told me about the site.")
    user.profile_image.attach(io: File.open(PORTRAITS["Gary"]), filename: PORTRAITS["Gary"].basename.to_s)
    user
  end

  # The Optics post Charlie wrote and then deleted (chapter 4).
  def charlie_deletes_optics(world)
    create(:blog_post, :contacts, :published, user: world.charlie, blog_category: BlogCategory.find_by!(name: "Science"),
      title: "Optics", subject: "Physics", topic: "Isaac Newton", body: "Light, colour and the prism.",
      deleted_at: Time.current)
  end

  private

  def story_user(first_name, last_name, role)
    user = create(:user, first_name: first_name, last_name: last_name, role: role,
      email_address: "#{first_name.downcase}@example.com")
    portrait = PORTRAITS.fetch(first_name)
    user.profile_image.attach(io: File.open(portrait), filename: portrait.basename.to_s)
    user
  end

  # ── Chronicle ── one Science post at each classification ─────────────────
  def story_posts(charlie, ulrika, adam)
    science = create(:blog_category, name: "Science", icon: "atom",
      description: "Discoveries, experiments and the people behind them.")
    posts = {
      newton:      story_post(charlie, science, "Isaac Newton", :unrestricted, "isaac_newton_hero.png",
                     "The life of the man who explained why the apple falls."),
      motion:      story_post(charlie, science, "Laws of Motion", :contacts, "laws_of_motion_hero.png",
                     "Three laws that describe how everything moves."),
      gravitation: story_post(charlie, science, "Universal Gravitation", :restricted, "universal_gravitation_hero.png",
                     "My notes on the law that holds the planets in their orbits.")
    }
    question = create(:comment, commentable: posts[:newton], user: ulrika,
      body: "Did the apple really fall on his head, or is that just a story?")
    create(:comment, commentable: posts[:newton], user: charlie, parent: question,
      body: "Just a story, I'm afraid. He saw one fall in the orchard, which got him thinking.")
    create(:like, likeable: posts[:newton], user: ulrika, face: "grinning")
    create(:like, likeable: posts[:newton], user: adam, face: "slightly_smiling")
    posts
  end

  def story_post(charlie, category, title, classification, hero, summary)
    post = build(:blog_post, classification, :published, user: charlie, blog_category: category,
      title: title, subject: "Physics", topic: "Isaac Newton", body: summary)
    post.blog_image.attach(io: File.open(HEROES.join(hero)), filename: hero)
    post.save!
    post
  end

  # ── Occasions ── Charlie's friends, one at each classification ───────────
  def story_people(charlie)
    {
      ulrika: create(:person, :unrestricted, user: charlie, first_name: "Ulrika", last_name: "User",
                description: "A friend from university."),
      erik:   create(:person, :contacts, user: charlie, first_name: "Erik", last_name: "Lind",
                description: "Charlie's climbing partner."),
      maja:   create(:person, :restricted, user: charlie, first_name: "Maja", last_name: "Lind",
                description: "Erik's wife.")
    }
  end

  def story_events(charlie, people)
    birthday = create(:event_type, name: "Birthday", icon: "cake", description: "The day someone was born.")
    wedding  = create(:event_type, name: "Wedding", icon: "heart", description: "The day two people married.")
    {
      ulrikas_birthday: story_event(charlie, birthday, "Ulrika's Birthday", :unrestricted, 14, 1990, [ people[:ulrika] ]),
      wedding:          story_event(charlie, wedding, "Erik and Maja's Wedding", :contacts, 22, 2018, [ people[:erik], people[:maja] ]),
      majas_birthday:   story_event(charlie, birthday, "Maja's Birthday", :restricted, 5, 1988, [ people[:maja] ])
    }
  end

  def story_event(charlie, type, title, classification, day, year, people)
    create(:event, classification, user: charlie, event_type: type, title: title, day: day, month: 11,
      year: year, description: "#{title}.", people: people)
  end

  # ── Cookbook ── a public lasagna and a Contacts-only bun recipe ──────────
  def story_recipes(charlie, ulrika)
    english = create(:language, name: "English", code: "en", flag: "🇬🇧")
    italian = create(:cuisine, name: "Italian", flag: "🇮🇹")
    swedish = create(:cuisine, name: "Swedish", flag: "🇸🇪")
    mince   = create(:food_type, name: "Mince", icon: "hamburger")
    bread   = create(:food_type, name: "Bread", icon: "wheat")

    lasagna = story_recipe(charlie, "Charlie's Lasagna", :unrestricted, english, italian, mince,
      "cookbook/recipes/lasagna.jpeg")
    create(:comment, commentable: lasagna, user: ulrika, body: "Can I make the meat sauce the day before?")
    create(:like, likeable: lasagna, user: ulrika, face: "grinning")

    { lasagna: lasagna,
      buns:    story_recipe(charlie, "Kanelbullar", :contacts, english, swedish, bread) }
  end

  # ── Dossier ── Charlie's own career, private to Charlie ───────────────────
  def story_engagements(charlie)
    create(:dossier_profile, user: charlie, display_name: "Charlie Content Creator")
    permanent = create(:dossier_employment_type, :permanent, name: "Permanent")
    {
      observatory: story_engagement(charlie, permanent, "Research Assistant", "Greenwich Observatory",
                     "Star Catalogue", Date.new(2016, 9, 1), Date.new(2019, 6, 1)),
      school:      story_engagement(charlie, permanent, "Physics Teacher", "Woolsthorpe School",
                     "Year 12 Physics", Date.new(2019, 8, 1), nil)
    }
  end

  def story_engagement(charlie, employment_type, title, employer, project, start_on, end_on)
    organisation = create(:dossier_organisation, name: employer)
    engagement = create(:dossier_engagement, user: charlie, employment_type: employment_type,
      position_title: title, employer: organisation, start_on: start_on, end_on: end_on)
    # A permanent Engagement creates its own Assignment; give it a project
    # and one Tech Stack list, so the Timeline isn't flagged incomplete.
    engagement.assignments.first.update!(project: project, methodologies_na: false,
      methodologies_text: "Inquiry-Based Learning")
    engagement
  end

  def story_recipe(charlie, title, classification, language, cuisine, food_type, image = nil)
    recipe = build(:recipe, classification, title: title, user: charlie, language: language,
      cuisines: [ cuisine ], food_types: [ food_type ], serves: 6, cook_time: "2 hours",
      description: "#{title}, the way Charlie makes it.", published_at: Time.current,
      body: "1. Prepare the ingredients.\n2. Cook.\n3. Serve.")
    section = recipe.ingredient_sections.build(heading: nil, position: 0)
    section.ingredients.build(quantity: "1", name: "egg", position: 0)
    recipe.recipe_image.attach(io: File.open(IMAGES.join(image)), filename: File.basename(image)) if image
    recipe.save!
    recipe
  end
end

RSpec.configure do |config|
  config.include GuideStoryWorld, type: :feature
end
