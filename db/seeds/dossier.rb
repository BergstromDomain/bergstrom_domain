# db/seeds/dossier.rb

# Dossier reference data — the starting Employment Types, Industries,
# Locations, Roles and Skill Categories. Loaded by db/seeds.rb; also safe to
# run on its own (bin/rails runner db/seeds/dossier.rb), since every row is
# find_or_create_by!. The PROD checklist copy of these lists lives in
# docs/reference-data/dossier/.

[
  [ "Permanent Employment", true,  false ],
  [ "Temp",                 false, false ],
  [ "Consultant",           false, false ],
  [ "Contractor",           false, false ],
  [ "Personal Project",     false, true ]
].each do |name, permanent, personal|
  Dossier::EmploymentType.find_or_create_by!(name: name) do |t|
    t.permanent = permanent
    t.personal = personal
  end
end

%w[Telecom Finance Government Hospitality].each do |name|
  Dossier::Industry.find_or_create_by!(name: name)
end

[
  [ "Stockholm", "Sweden" ],
  [ "Falun",     "Sweden" ],
  [ "Brisbane",  "Australia" ]
].each do |city, country|
  Dossier::Location.find_or_create_by!(city: city, country: country)
end

[
  "Project Manager", "System Tester", "Test Manager", "Test Lead", "Test Coordinator",
  "Performance Tester", "Test Analyst", "Senior Test Analyst", "Portfolio Test Manager"
].each do |name|
  Dossier::Role.find_or_create_by!(name: name)
end

# Imported and on-the-fly Skills start here until someone sorts them.
Dossier::SkillCategory.find_or_create_by!(name: "Uncategorised") do |c|
  c.description = "Skills not yet sorted into a category."
end
