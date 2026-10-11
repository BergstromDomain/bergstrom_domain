# spec/factories/languages.rb
FactoryBot.define do
  factory :language do
    sequence(:name) { |n| "Language #{n}" }
    # Two lowercase letters, unique per record: "aa", "ab", ... "zz".
    sequence(:code) { |n| [ ("a".."z").to_a[(n / 26) % 26], ("a".."z").to_a[n % 26] ].join }
    flag            { "🇬🇧" }
  end
end
